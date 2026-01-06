#!/usr/bin/env pwsh
<#
.SYNOPSIS
    LionPay 인프라의 모든 리소스를 완전히 삭제하는 스크립트

.DESCRIPTION
    이 스크립트는 다음 순서로 리소스를 정리합니다:
    1. Terraform output에서 클러스터 정보 조회
    2. Seoul/Tokyo 클러스터의 Karpenter 리소스 정리
    3. LoadBalancer 서비스 삭제
    4. Orphaned EC2 인스턴스 종료
    5. Terraform destroy 실행

.PARAMETER Env
    삭제할 환경 이름 (예: dev, prod)

.PARAMETER AwsProfile
    사용할 AWS 프로필 이름 (선택사항)

.PARAMETER Auto
    모든 확인 프롬프트를 건너뛰고 자동 실행 (-auto-approve 포함)

.EXAMPLE
    ./destroy-all.ps1 -Env dev -Auto
    dev 환경의 모든 리소스를 자동으로 삭제합니다.

.NOTES
    AI 에이전트 실행 시: -Auto 플래그를 사용하세요.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Env,

    [Parameter(Mandatory = $false)]
    [string]$AwsProfile,

    [Parameter(Mandatory = $false)]
    [switch]$Auto
)

$ErrorActionPreference = "Stop"

# 리전 정의
$SeoulRegion = "ap-northeast-2"
$TokyoRegion = "ap-northeast-1"

# 로그 함수 - AI 에이전트가 파싱하기 쉬운 형식
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "PHASE")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

# Terraform output에서 클러스터 이름 가져오기
function Get-TerraformOutputs {
    Push-Location "$PSScriptRoot/main"
    try {
        Write-Log "Terraform 초기화 및 워크스페이스 선택 중..." "INFO"
        terraform init -input=false 2>&1 | Out-Null
        terraform workspace select $Env 2>&1 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "'$Env' 워크스페이스가 존재하지 않습니다." "ERROR"
            return $null
        }

        $outputs = @{}
        $outputs.SeoulCluster = (terraform output -raw seoul_cluster_name 2>$null)
        $outputs.TokyoCluster = (terraform output -raw tokyo_cluster_name 2>$null)
        
        return $outputs
    }
    finally {
        Pop-Location
    }
}

function Test-ClusterExists {
    param([string]$ClusterName, [string]$Region)
    if ([string]::IsNullOrWhiteSpace($ClusterName)) { return $false }
    $null = aws eks describe-cluster --name $ClusterName --region $Region --no-cli-pager 2>&1
    return $LASTEXITCODE -eq 0
}

function Remove-KarpenterResources {
    param([string]$ClusterName, [string]$Region)
    
    Write-Log "Kubeconfig 업데이트: $ClusterName ($Region)" "INFO"
    aws eks update-kubeconfig --name $ClusterName --region $Region --no-cli-pager 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Kubeconfig 업데이트 실패" "ERROR"
        return $false
    }

    Write-Log "Karpenter NodePool 삭제 중..." "INFO"
    kubectl delete nodepools --all --ignore-not-found=true 2>&1 | Out-Null

    Write-Log "Karpenter EC2NodeClass 삭제 요청 중..." "INFO"
    kubectl delete ec2nodeclasses --all --ignore-not-found=true --wait=false 2>&1 | Out-Null

    # EC2NodeClass finalizer 강제 제거 (삭제가 막힌 경우)
    Write-Log "EC2NodeClass finalizer 정리 중..." "INFO"
    $ec2NodeClasses = kubectl get ec2nodeclasses -o name 2>&1
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($ec2NodeClasses) -and $ec2NodeClasses -notmatch "No resources found") {
        $ec2NodeClasses -split "`n" | ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace($_)) {
                kubectl patch $_ --type merge -p '{"metadata":{"finalizers":null}}' 2>&1 | Out-Null
            }
        }
        Write-Log "EC2NodeClass finalizer 제거 완료" "SUCCESS"
    }

    # NodeClaim finalizer 강제 제거
    Write-Log "NodeClaim finalizer 정리 중..." "INFO"
    $nodeclaims = kubectl get nodeclaims -o name 2>&1
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($nodeclaims) -and $nodeclaims -notmatch "No resources found") {
        $nodeclaims -split "`n" | ForEach-Object {
            if (-not [string]::IsNullOrWhiteSpace($_)) {
                kubectl patch $_ --type merge -p '{"metadata":{"finalizers":null}}' 2>&1 | Out-Null
            }
        }
        Write-Log "NodeClaim finalizer 제거 완료" "SUCCESS"
    }

    Write-Log "NodeClaim 정리 대기 중 (최대 60초)..." "INFO"
    $timeout = 60
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $remainingNodeclaims = kubectl get nodeclaims --no-headers 2>&1
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remainingNodeclaims) -or $remainingNodeclaims -match "No resources found") {
            Write-Log "모든 NodeClaim 삭제 완료" "SUCCESS"
            return $true
        }
        Start-Sleep -Seconds 10
        $elapsed += 10
        Write-Log "NodeClaim 삭제 대기 중... ($elapsed/$timeout 초)" "INFO"
    }
    Write-Log "NodeClaim 삭제 타임아웃 - 일부 리소스가 남아있을 수 있음" "WARN"
    return $true
}

function Remove-LoadBalancers {
    param([string]$ClusterName, [string]$Region)

    Write-Log "LoadBalancer 서비스 삭제 중..." "INFO"
    
    $servicesJson = kubectl get svc --all-namespaces -o json 2>&1
    if ($LASTEXITCODE -eq 0) {
        $services = $servicesJson | ConvertFrom-Json
        if ($services -and $services.items) {
            foreach ($svc in $services.items) {
                if ($svc.spec.type -eq "LoadBalancer") {
                    $ns = $svc.metadata.namespace
                    $name = $svc.metadata.name
                    Write-Log "LoadBalancer 삭제: $ns/$name" "INFO"
                    kubectl delete svc $name -n $ns --ignore-not-found=true 2>&1 | Out-Null
                }
            }
        }
    }

    Write-Log "AWS LoadBalancer 정리 대기 (20초)..." "INFO"
    Start-Sleep -Seconds 20
}

function Remove-OrphanedResources {
    param([string]$Region)

    Write-Log "Orphaned EC2 인스턴스 확인 ($Region)..." "INFO"
    
    $instances = aws ec2 describe-instances `
        --region $Region `
        --filters "Name=tag:karpenter.sh/nodepool,Values=*" "Name=instance-state-name,Values=running,pending" `
        --query "Reservations[].Instances[].InstanceId" `
        --output text `
        --no-cli-pager 2>&1

    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($instances) -and $instances -ne "None") {
        $instanceIds = ($instances -split "\s+") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        if ($instanceIds.Count -gt 0) {
            Write-Log "Orphaned 인스턴스 $($instanceIds.Count)개 종료 중..." "WARN"
            foreach ($id in $instanceIds) {
                Write-Log "인스턴스 종료: $id" "INFO"
                aws ec2 terminate-instances --instance-ids $id --region $Region --no-cli-pager 2>&1 | Out-Null
            }
            Write-Log "인스턴스 종료 대기 (30초)..." "INFO"
            Start-Sleep -Seconds 30
        }
    }
    else {
        Write-Log "Orphaned 인스턴스 없음" "SUCCESS"
    }
}

# ============================================================
# 메인 실행 로직
# ============================================================

Write-Log "========================================" "PHASE"
Write-Log "LionPay Infrastructure Destroy Script" "PHASE"
Write-Log "환경: $Env" "PHASE"
Write-Log "========================================" "PHASE"

# 확인 프롬프트 (Auto가 아닌 경우)
if (-not $Auto) {
    Write-Host ""
    Write-Host "경고: 이 스크립트는 $Env 환경의 모든 인프라를 삭제합니다!" -ForegroundColor Red
    Write-Host ""
    $confirm = Read-Host "정말로 진행하시겠습니까? (yes를 입력하세요)"
    if ($confirm -ne "yes") {
        Write-Log "사용자에 의해 취소됨" "INFO"
        exit 0
    }
}

# AWS Profile 설정
if ($AwsProfile) {
    Write-Log "AWS Profile 설정: $AwsProfile" "INFO"
    $env:AWS_PROFILE = $AwsProfile
}

# Terraform output에서 클러스터 정보 가져오기
Write-Log "Terraform output에서 리소스 정보 조회 중..." "INFO"
$TfOutputs = Get-TerraformOutputs

if ($null -eq $TfOutputs) {
    Write-Log "Terraform output 조회 실패. Terraform destroy만 실행합니다." "WARN"
    $SeoulCluster = $null
    $TokyoCluster = $null
}
else {
    $SeoulCluster = $TfOutputs.SeoulCluster
    $TokyoCluster = $TfOutputs.TokyoCluster
    Write-Log "Seoul 클러스터: $SeoulCluster" "INFO"
    Write-Log "Tokyo 클러스터: $TokyoCluster" "INFO"
}

# ============================================================
# Phase 1: Seoul 클러스터 정리
# ============================================================

Write-Log "Phase 1: Seoul 클러스터 Kubernetes 리소스 정리" "PHASE"

if (Test-ClusterExists -ClusterName $SeoulCluster -Region $SeoulRegion) {
    Remove-KarpenterResources -ClusterName $SeoulCluster -Region $SeoulRegion
    Remove-LoadBalancers -ClusterName $SeoulCluster -Region $SeoulRegion
}
else {
    Write-Log "Seoul 클러스터가 존재하지 않음. 스킵." "INFO"
}

# ============================================================
# Phase 2: Tokyo 클러스터 정리
# ============================================================

Write-Log "Phase 2: Tokyo 클러스터 Kubernetes 리소스 정리" "PHASE"

if (Test-ClusterExists -ClusterName $TokyoCluster -Region $TokyoRegion) {
    Remove-KarpenterResources -ClusterName $TokyoCluster -Region $TokyoRegion
    Remove-LoadBalancers -ClusterName $TokyoCluster -Region $TokyoRegion
}
else {
    Write-Log "Tokyo 클러스터가 존재하지 않음. 스킵." "INFO"
}

# ============================================================
# Phase 3: Orphaned AWS 리소스 정리
# ============================================================

Write-Log "Phase 3: Orphaned AWS 리소스 정리" "PHASE"

Remove-OrphanedResources -Region $SeoulRegion
Remove-OrphanedResources -Region $TokyoRegion

# ============================================================
# Phase 4: Terraform Destroy
# ============================================================

Write-Log "Phase 4: Terraform Destroy 실행" "PHASE"

Push-Location "$PSScriptRoot/main"

try {
    # tfvars 파일 체크
    if (-not (Test-Path "${Env}.tfvars")) {
        Write-Log "'main/${Env}.tfvars' 파일이 존재하지 않습니다." "ERROR"
        exit 1
    }

    Write-Log "Terraform 초기화 중..." "INFO"
    terraform init -input=false

    Write-Log "Terraform 워크스페이스 선택: $Env" "INFO"
    terraform workspace select $Env
    if ($LASTEXITCODE -ne 0) {
        Write-Log "'$Env' 워크스페이스가 존재하지 않습니다." "ERROR"
        exit 1
    }

    Write-Log "Terraform destroy 실행 중..." "INFO"
    if ($Auto) {
        terraform destroy -var-file="${Env}.tfvars" -auto-approve -input=false
    }
    else {
        terraform destroy -var-file="${Env}.tfvars" -input=false
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Log "모든 리소스가 성공적으로 삭제되었습니다!" "SUCCESS"
        exit 0
    }
    else {
        Write-Log "Terraform destroy 중 오류 발생" "ERROR"
        exit 1
    }
}
finally {
    Pop-Location
}
