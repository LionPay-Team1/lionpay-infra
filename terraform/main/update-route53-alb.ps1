#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates Route53 origin-api latency routing records with ALB DNS names.

.DESCRIPTION
    This script queries ALB DNS names from EKS Ingress and updates Route53 
    latency-based routing records for origin-api.lionpay.shop.
    Run this after ArgoCD deploys the Ingress resources.

.PARAMETER ZoneName
    Route53 hosted zone name. Default: lionpay.shop

.PARAMETER SeoulClusterName  
    EKS cluster name for Seoul. Default: lionpay-dev-seoul

.PARAMETER TokyoClusterName
    EKS cluster name for Tokyo. Default: lionpay-dev-tokyo

.EXAMPLE
    ./update-route53-alb.ps1
    ./update-route53-alb.ps1 -ZoneName "lionpay.shop"
#>

param(
    [string]$ZoneName = "lionpay.shop",
    [string]$SeoulClusterName = "lionpay-dev-seoul",
    [string]$TokyoClusterName = "lionpay-dev-tokyo",
    [string]$IngressName = "lionpay-ingress",
    [string]$Namespace = "lionpay",
    [string]$RecordName
)

$ErrorActionPreference = "Stop"

# ELB Hosted Zone IDs (AWS-managed, fixed per region)
$ELB_ZONE_IDS = @{
    "ap-northeast-2" = "ZWKZPGTI48KDX"   # Seoul
    "ap-northeast-1" = "Z14GRHDCWA56QT"  # Tokyo
}

function Get-ALBDnsFromIngress {
    param(
        [string]$ClusterName,
        [string]$Region,
        [string]$IngressName,
        [string]$Namespace
    )
    
    Write-Host "Getting ALB DNS from $ClusterName in $Region..." -ForegroundColor Cyan
    
    # Update kubeconfig
    aws eks update-kubeconfig --name $ClusterName --region $Region --no-cli-pager > $null
    
    # Get Ingress and extract ALB hostname
    $ingress = kubectl get ingress $IngressName -n $Namespace -o json 2>$null | ConvertFrom-Json
    
    if (-not $ingress.status.loadBalancer.ingress) {
        throw "Ingress $IngressName in $ClusterName has no load balancer assigned yet"
    }
    
    $albDns = $ingress.status.loadBalancer.ingress[0].hostname
    Write-Host "  Found ALB: $albDns" -ForegroundColor Green
    
    return $albDns
}

function Update-Route53LatencyRecord {
    param(
        [string]$ZoneId,
        [string]$RecordName,
        [string]$AlbDns,
        [string]$AlbZoneId,
        [string]$Region,
        [string]$SetIdentifier
    )
    
    Write-Host "Updating Route53 record: $RecordName ($SetIdentifier)..." -ForegroundColor Cyan
    
    $changeBatch = @{
        Changes = @(
            @{
                Action            = "UPSERT"
                ResourceRecordSet = @{
                    Name          = $RecordName
                    Type          = "A"
                    SetIdentifier = $SetIdentifier
                    Region        = $Region
                    AliasTarget   = @{
                        HostedZoneId         = $AlbZoneId
                        DNSName              = "dualstack.$AlbDns"
                        EvaluateTargetHealth = $true
                    }
                }
            }
        )
    } | ConvertTo-Json -Depth 10
    
    $changeBatch | aws route53 change-resource-record-sets --hosted-zone-id $ZoneId --change-batch file:///dev/stdin --no-cli-pager
    
    Write-Host "  Updated successfully" -ForegroundColor Green
}

# Main execution
Write-Host "`n=== Route53 ALB Record Updater ===" -ForegroundColor Yellow
Write-Host "Zone: $ZoneName"
Write-Host ""

# Get Route53 Zone ID
Write-Host "Looking up Zone ID for $ZoneName..." -ForegroundColor Cyan
$zoneId = (aws route53 list-hosted-zones-by-name --dns-name $ZoneName --max-items 1 --no-cli-pager | ConvertFrom-Json).HostedZones[0].Id
$zoneId = $zoneId -replace "/hostedzone/", ""
Write-Host "  Zone ID: $zoneId" -ForegroundColor Green

# Get ALB DNS from Seoul
$seoulAlbDns = Get-ALBDnsFromIngress `
    -ClusterName $SeoulClusterName `
    -Region "ap-northeast-2" `
    -IngressName $IngressName `
    -Namespace $Namespace

# Get ALB DNS from Tokyo
$tokyoAlbDns = Get-ALBDnsFromIngress `
    -ClusterName $TokyoClusterName `
    -Region "ap-northeast-1" `
    -IngressName $IngressName `
    -Namespace $Namespace

# Update Route53 records
Write-Host "`nUpdating Route53 latency routing records..." -ForegroundColor Yellow

# Determine RecordName
if (-not $RecordName) {
    $RecordName = "origin-api.$ZoneName"
}

Write-Host "Target Record: $RecordName" -ForegroundColor Cyan

Update-Route53LatencyRecord `
    -ZoneId $zoneId `
    -RecordName $RecordName `
    -AlbDns $seoulAlbDns `
    -AlbZoneId $ELB_ZONE_IDS["ap-northeast-2"] `
    -Region "ap-northeast-2" `
    -SetIdentifier "lionpay-latency-seoul"

Update-Route53LatencyRecord `
    -ZoneId $zoneId `
    -RecordName $RecordName `
    -AlbDns $tokyoAlbDns `
    -AlbZoneId $ELB_ZONE_IDS["ap-northeast-1"] `
    -Region "ap-northeast-1" `
    -SetIdentifier "lionpay-latency-tokyo"

Write-Host "`n=== Complete ===" -ForegroundColor Green
Write-Host "origin-api.$ZoneName is now pointing to:"
Write-Host "  Seoul: $seoulAlbDns"
Write-Host "  Tokyo: $tokyoAlbDns"
