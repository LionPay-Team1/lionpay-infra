# lionpay-infra

## Terraform 백엔드 설정

이 프로젝트는 Terraform 상태 저장 및 잠금을 위해 AWS S3와 DynamoDB를 사용합니다.

### 1. 백엔드 리소스 프로비저닝 (Bootstrap)

인프라를 프로비저닝하기 전에 S3 버킷과 DynamoDB 테이블을 생성해야 합니다.

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

### 2. 인프라 초기화

부트스트래핑 완료 후, 메인 인프라 프로젝트를 초기화할 수 있습니다.

**메인 인프라 (Main Infrastructure):**

```bash
cd terraform/main
terraform init
```

## 3. 배포 및 삭제 자동화 스크립트

`terraform` 디렉토리 내에 있는 `apply.ps1`, `destroy.ps1` 스크립트를 사용하여 환경별(`dev`, `prod`) 배포 및 삭제를 간편하게 수행할 수 있습니다.

### 스크립트 위치로 이동

```bash
cd terraform
```

### 배포 (Apply)

`apply.ps1`을 실행하면 `terraform init`, `workspace` 선택, `terraform apply` 과정이 자동으로 진행됩니다.

```powershell
# 기본 (확인 필요)
./apply.ps1 -Env <env_name>

# 자동 승인 (확인 생략)
./apply.ps1 -Env <env_name> -Auto

# 예시:
./apply.ps1 -Env dev
./apply.ps1 -Env dev -Auto
```

### 삭제 (Destroy)

`destroy.ps1`을 실행하면 해당 환경의 리소스를 삭제합니다.

```powershell
# 기본 (확인 필요)
./destroy.ps1 -Env <env_name>

# 자동 승인 (확인 생략)
./destroy.ps1 -Env <env_name> -Auto

# 예시:
./destroy.ps1 -Env dev
./destroy.ps1 -Env dev -Auto
```

## 4. Karpenter NodePool 적용

Terraform 배포 시 Karpenter `NodePool` 및 `EC2NodeClass` 설정이 **자동으로 적용**됩니다.

### 수동으로 업데이트가 필요한 경우

Karpenter 설정(`dev-karpenter.yaml` 또는 `prod-karpenter.yaml`)을 수정한 후:

```powershell
# Terraform을 통해 자동으로 적용 (권장)
./apply.ps1 -Env dev -Auto
```

**주의:** `main/config/dev-karpenter.yaml`을 직접 `kubectl apply`하면 템플릿 변수(`${cluster_name}` 등)가 치환되지 않아 오류가 발생합니다. 반드시 Terraform을 통해 생성된 `.terraform/karpenter_*.yaml` 파일을 사용하거나, `apply.ps1`을 다시 실행하세요.
