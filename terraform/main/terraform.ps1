#!/usr/bin/env pwsh
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Command,

    [Parameter(Mandatory = $true)]
    [string]$Env,

    [Parameter(Mandatory = $false)]
    [string]$AwsProfile,

    [Parameter(Mandatory = $false)]
    [switch]$Auto
)

Push-Location "$PSScriptRoot"
[Console]::ResetColor()

try {
    # tfvars 파일 체크 (validate 제외)
    if ($Command -ne "validate") {
        if (-not (Test-Path "${Env}.tfvars")) {
            Write-Host "오류: 'main/${Env}.tfvars' 파일이 존재하지 않습니다." -ForegroundColor Red
            return
        }
    }

    if ($AwsProfile) {
        Write-Host "AWS Profile 설정: $AwsProfile" -ForegroundColor Cyan
        $env:AWS_PROFILE = $AwsProfile
    }

    Write-Host "Terraform 초기화 중..." -ForegroundColor Cyan
    terraform init

    Write-Host "Terraform 워크스페이스 확인 중 ($Env)..." -ForegroundColor Cyan
    terraform workspace select $Env
    if ($LASTEXITCODE -ne 0) {
        Write-Host "'$Env' 워크스페이스가 존재하지 않습니다. 생성 중..." -ForegroundColor Yellow
        terraform workspace new $Env
    }

    switch ($Command) {
        "plan" {
            Write-Host "Terraform plan 실행 중 ($Env)..." -ForegroundColor Cyan
            terraform plan -var-file="${Env}.tfvars"
        }
        "apply" {
            Write-Host "Terraform apply 실행 중 ($Env)..." -ForegroundColor Green
            if ($Auto) {
                terraform apply -var-file="${Env}.tfvars" -auto-approve
            }
            else {
                terraform apply -var-file="${Env}.tfvars"
            }
        }
        "destroy" {
            Write-Host "Terraform destroy 실행 중 ($Env)..." -ForegroundColor Red
            if ($Auto) {
                terraform destroy -var-file="${Env}.tfvars" -auto-approve
            }
            else {
                terraform destroy -var-file="${Env}.tfvars"
            }
        }
        default {
            Write-Host "지원하지 않는 명령어입니다: $Command" -ForegroundColor Red
        }
    }
}
finally {
    Pop-Location
    [Console]::ResetColor()
}
