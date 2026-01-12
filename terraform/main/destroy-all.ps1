#!/usr/bin/env pwsh
<#
.SYNOPSIS
    LionPay 인프라의 모든 리소스를 완전히 삭제하는 스크립트

.DESCRIPTION
    이 스크립트는 다음 순서로 리소스를 정리합니다:
    1. Terraform output에서 클러스터 정보 조회
    2. Seoul/Tokyo 클러스터의 Ingress 리소스 삭제 (ALB 정리)
    3. Orphaned ALB/Target Group/Security Group 정리
    4. Terraform destroy 실행

    참고: Karpenter, ArgoCD 리소스는 Terraform의 null_resource destroy
    provisioner에서 자동으로 정리됩니다.

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
    Push-Location "$PSScriptRoot"
    try {
        Write-Log "Terraform 초기화 및 워크스페이스 선택 중..." "INFO"
        terraform init -input=false 2>&1 | Out-Null
        terraform workspace select $Env 2>&1 | Out-Null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "'$Env' 워크스페이스가 존재하지 않습니다." "ERROR"
            return $null
        }

        $outJson = (terraform output -json 2>$null)
        if ($null -eq $outJson -or [string]::IsNullOrWhiteSpace($outJson) -or $outJson -match "No outputs found") {
            return $null
        }

        $out = $outJson | ConvertFrom-Json
        $outputs = @{}
        
        if ($out.seoul_cluster_name) { $outputs.SeoulCluster = $out.seoul_cluster_name.value }
        if ($out.tokyo_cluster_name) { $outputs.TokyoCluster = $out.tokyo_cluster_name.value }
        
        return $outputs
    }
    catch {
        return $null
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

function Remove-Ingresses {
    param([string]$ClusterName, [string]$Region)

    Write-Log "Kubeconfig 업데이트: $ClusterName ($Region)" "INFO"
    aws eks update-kubeconfig --name $ClusterName --region $Region --no-cli-pager 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Kubeconfig 업데이트 실패" "ERROR"
        return $false
    }

    Write-Log "Ingress 리소스 삭제 중 (ALB 정리를 위해)..." "INFO"
    
    # 모든 Ingress 조회 및 삭제
    $ingressesJson = kubectl get ingress --all-namespaces -o json 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ingresses = $ingressesJson | ConvertFrom-Json
        if ($ingresses -and $ingresses.items -and $ingresses.items.Count -gt 0) {
            foreach ($ing in $ingresses.items) {
                $ns = $ing.metadata.namespace
                $name = $ing.metadata.name
                Write-Log "Ingress 삭제: $ns/$name" "INFO"
                kubectl delete ingress $name -n $ns --ignore-not-found=true 2>&1 | Out-Null
            }
            
            Write-Log "AWS Load Balancer Controller가 ALB를 정리하도록 대기 (60초)..." "INFO"
            Start-Sleep -Seconds 60
        }
        else {
            Write-Log "삭제할 Ingress가 없습니다." "INFO"
        }
    }
    return $true
}

function Remove-OrphanedALB {
    param([string]$Region)
    
    Write-Log "Orphaned ALB (k8s-lionpay-*) 확인 및 삭제 ($Region)..." "INFO"

    # 1. Load Balancer 삭제
    $lbs = aws elbv2 describe-load-balancers --region $Region --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-lionpay')].LoadBalancerArn" --output text --no-cli-pager 2>&1
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($lbs) -and $lbs -ne "None") {
        $lbArns = $lbs -split "\s+"
        foreach ($arn in $lbArns) {
            Write-Log "ALB 삭제: $arn" "INFO"
            aws elbv2 delete-load-balancer --load-balancer-arn $arn --region $Region --no-cli-pager 2>&1 | Out-Null
        }
        Write-Log "ALB 삭제 완료 대기 (10초)..." "INFO"
        Start-Sleep -Seconds 10
    }
    else {
        Write-Log "Orphaned ALB 없음" "SUCCESS"
    }

    # 2. Target Group 삭제
    Write-Log "Orphaned Target Group (k8s-lionpay-*) 확인 및 삭제..." "INFO"
    $tgs = aws elbv2 describe-target-groups --region $Region --query "TargetGroups[?contains(TargetGroupName, 'k8s-lionpay')].TargetGroupArn" --output text --no-cli-pager 2>&1
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($tgs) -and $tgs -ne "None") {
        $tgArns = $tgs -split "\s+"
        foreach ($arn in $tgArns) {
            Write-Log "Target Group 삭제: $arn" "INFO"
            aws elbv2 delete-target-group --target-group-arn $arn --region $Region --no-cli-pager 2>&1 | Out-Null
        }
    }
    else {
        Write-Log "Orphaned Target Group 없음" "SUCCESS"
    }

    # 3. Security Group 삭제 (Load Balancer 관련)
    Write-Log "Ingress 관련 Security Group 확인 및 삭제..." "INFO"
    $sgs = aws ec2 describe-security-groups --region $Region --filters "Name=tag-key,Values=elbv2.k8s.aws/cluster" --query "SecurityGroups[].GroupId" --output text --no-cli-pager 2>&1
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($sgs) -and $sgs -ne "None") {
        $sgIds = $sgs -split "\s+"
        foreach ($id in $sgIds) {
            Write-Log "Security Group 삭제 시도: $id" "INFO"
            aws ec2 delete-security-group --group-id $id --region $Region --no-cli-pager 2>&1 | Out-Null
        }
    }
    else {
        Write-Log "Orphaned Security Group 없음" "SUCCESS"
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
# Phase 1: Ingress 삭제 (ALB 정리를 위해)
# ============================================================

Write-Log "Phase 1: Ingress 리소스 삭제 (ALB 정리)" "PHASE"

if (Test-ClusterExists -ClusterName $SeoulCluster -Region $SeoulRegion) {
    Remove-Ingresses -ClusterName $SeoulCluster -Region $SeoulRegion
}
else {
    Write-Log "Seoul 클러스터가 존재하지 않음. 스킵." "INFO"
}

if (Test-ClusterExists -ClusterName $TokyoCluster -Region $TokyoRegion) {
    Remove-Ingresses -ClusterName $TokyoCluster -Region $TokyoRegion
}
else {
    Write-Log "Tokyo 클러스터가 존재하지 않음. 스킵." "INFO"
}

# ============================================================
# Phase 2: Orphaned AWS 리소스 정리
# ============================================================

Write-Log "Phase 2: Orphaned AWS 리소스 정리" "PHASE"

Remove-OrphanedALB -Region $SeoulRegion
Remove-OrphanedALB -Region $TokyoRegion

# ============================================================
# Phase 3: Terraform Destroy
# ============================================================

Write-Log "Phase 3: Terraform Destroy 실행" "PHASE"

Push-Location "$PSScriptRoot"

try {
    # tfvars 파일 체크
    if (-not (Test-Path "${Env}.tfvars")) {
        Write-Log "'${Env}.tfvars' 파일이 존재하지 않습니다." "ERROR"
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
