param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("dev", "prod")]
    [string]$Env
)

Set-Location "$PSScriptRoot\main"
[Console]::ResetColor()

Write-Host "Terraform 워크스페이스 확인 중 ($Env)..." -ForegroundColor Cyan
terraform workspace select $Env
if ($LASTEXITCODE -ne 0) {
    Write-Host "'$Env' 워크스페이스가 존재하지 않습니다. 생성 중..." -ForegroundColor Yellow
    terraform workspace new $Env
}

if (-not (Test-Path "${Env}.tfvars")) {
    Write-Host "오류: '${Env}.tfvars' 파일이 존재하지 않습니다." -ForegroundColor Red
    exit 1
}

Write-Host "Terraform apply 실행 중 ($Env)..." -ForegroundColor Green
terraform apply -var-file="${Env}.tfvars"
[Console]::ResetColor()
