<#
.SYNOPSIS
    Peers two existing Amazon Aurora DSQL clusters in different regions using their ARNs.

.DESCRIPTION
    This script takes the ARNs of two existing Aurora DSQL clusters, parses their IDs and regions,
    and update each cluster's multi-region properties to peer with the other.

.PARAMETER Cluster1Arn
    The ARN of the first Aurora DSQL cluster (e.g., arn:aws:dsql:us-east-1:123456789012:cluster/abc...).

.PARAMETER Cluster2Arn
    The ARN of the second Aurora DSQL cluster (e.g., arn:aws:dsql:us-east-2:123456789012:cluster/xyz...).

.PARAMETER WitnessRegion
    The AWS Region to be used as the witness region (e.g., us-west-2).

.PARAMETER AwsProfile
    (Optional) The AWS CLI profile to use.

.EXAMPLE
    .\Peer-AuroraDSQLClusters.ps1 -Cluster1Arn "arn:aws:dsql:us-east-1:1111:cluster/abc" -Cluster2Arn "arn:aws:dsql:us-east-2:1111:cluster/xyz" -WitnessRegion "us-west-2"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Cluster1Arn,

    [Parameter(Mandatory=$true)]
    [string]$Cluster2Arn,

    [Parameter(Mandatory=$true)]
    [string]$WitnessRegion,

    [Parameter(Mandatory=$false)]
    [string]$AwsProfile
)

# Function to run AWS CLI commands
function Invoke-AwsCli {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    $cliArgs = @($Command) + $Arguments
    if (-not [string]::IsNullOrEmpty($AwsProfile)) {
        $cliArgs += "--profile", $AwsProfile
    }

    Write-Host "Running: aws $cliArgs" -ForegroundColor Gray
    
    try {
        $process = Start-Process -FilePath "aws" -ArgumentList $cliArgs -NoNewWindow -PassThru -Wait -RedirectStandardOutput "stdout.tmp" -RedirectStandardError "stderr.tmp"
        
        $stdout = Get-Content "stdout.tmp" -Raw -ErrorAction SilentlyContinue
        $stderr = Get-Content "stderr.tmp" -Raw -ErrorAction SilentlyContinue
        
        Remove-Item "stdout.tmp" -ErrorAction SilentlyContinue
        Remove-Item "stderr.tmp" -ErrorAction SilentlyContinue

        if ($process.ExitCode -ne 0) {
            Write-Error "AWS CLI Error: $stderr"
            exit $process.ExitCode
        }

        return $stdout
    }
    catch {
        Write-Error "Failed to execute AWS CLI command: $_"
        exit 1
    }
}

# Function to parse ARN
function Get-ClusterDetailsFromArn {
    param(
        [string]$Arn
    )
    
    # ARN format: arn:aws:dsql:<region>:<account>:cluster/<id>
    $parts = $Arn -split ":"
    if ($parts.Count -ne 6 -or $parts[2] -ne "dsql") {
        Throw "Invalid Aurora DSQL Cluster ARN format: $Arn"
    }

    $region = $parts[3]
    $resourceParts = $parts[5] -split "/"
    if ($resourceParts.Count -ne 2 -or $resourceParts[0] -ne "cluster") {
        Throw "Invalid Aurora DSQL Cluster ARN resource format: $Arn"
    }
    $id = $resourceParts[1]

    return @{
        Region = $region
        Id = $id
    }
}

try {
    # 1. Parse Cluster 1 ARN
    Write-Host "`n[Step 1] Parsing Cluster 1 ARN..." -ForegroundColor Cyan
    $c1 = Get-ClusterDetailsFromArn -Arn $Cluster1Arn
    Write-Host "Cluster 1 -> Region: $($c1.Region), ID: $($c1.Id)" -ForegroundColor Green

    # 2. Parse Cluster 2 ARN
    Write-Host "`n[Step 2] Parsing Cluster 2 ARN..." -ForegroundColor Cyan
    $c2 = Get-ClusterDetailsFromArn -Arn $Cluster2Arn
    Write-Host "Cluster 2 -> Region: $($c2.Region), ID: $($c2.Id)" -ForegroundColor Green

    # 3. Update Cluster 1 to peer with Cluster 2
    Write-Host "`n[Step 3] Updating Cluster 1 ($($c1.Id)) to peer with Cluster 2..." -ForegroundColor Cyan
    $prop1 = @{
        witnessRegion = $WitnessRegion
        clusters = @($Cluster2Arn)
    } | ConvertTo-Json -Compress
    
    # Escape double quotes for AWS CLI when passed via PowerShell's argument list
    $prop1Escaped = $prop1.Replace('"', '\"')
    
    $update1Json = Invoke-AwsCli -Command "dsql" -Arguments "update-cluster", "--identifier", $c1.Id, "--region", $c1.Region, "--multi-region-properties", "`"$prop1Escaped`""
    $update1 = $update1Json | ConvertFrom-Json
    Write-Host "Cluster 1 status: $($update1.status)" -ForegroundColor Yellow

    # 4. Update Cluster 2 to peer with Cluster 1
    Write-Host "`n[Step 4] Updating Cluster 2 ($($c2.Id)) to peer with Cluster 1..." -ForegroundColor Cyan
    $prop2 = @{
        witnessRegion = $WitnessRegion
        clusters = @($Cluster1Arn)
    } | ConvertTo-Json -Compress

    # Escape double quotes for AWS CLI when passed via PowerShell's argument list
    $prop2Escaped = $prop2.Replace('"', '\"')

    $update2Json = Invoke-AwsCli -Command "dsql" -Arguments "update-cluster", "--identifier", $c2.Id, "--region", $c2.Region, "--multi-region-properties", "`"$prop2Escaped`""
    $update2 = $update2Json | ConvertFrom-Json
    Write-Host "Cluster 2 status: $($update2.status)" -ForegroundColor Yellow

    Write-Host "`n--------------------------------------------------"
    Write-Host "Peering initiation complete."
    Write-Host "Both clusters should transition to CREATING and then ACTIVE status."
    Write-Host "You can verify status using:"
    Write-Host "aws dsql get-cluster --identifier $($c1.Id) --region $($c1.Region)"
    Write-Host "aws dsql get-cluster --identifier $($c2.Id) --region $($c2.Region)"
    Write-Host "--------------------------------------------------"

}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
