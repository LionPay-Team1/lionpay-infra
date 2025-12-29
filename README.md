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
./apply.ps1 -Env <env_name>
# 예시:
./apply.ps1 -Env dev
```

### 삭제 (Destroy)

`destroy.ps1`을 실행하면 해당 환경의 리소스를 삭제합니다.

```powershell
./destroy.ps1 -Env <env_name>
# 예시:
./destroy.ps1 -Env dev
```

## 4. Karpenter NodePool 적용

Terraform 배포가 완료된 후, Karpenter가 실제로 노드를 생성할 수 있도록 `NodePool` 및 `EC2NodeClass` 리소스를 수동으로 적용해야 합니다.

```bash
# terraform 디렉토리 기준
kubectl apply -f main/config/dev-karpenter.yaml

# 또는 루트 디렉토리 기준
kubectl apply -f terraform/main/config/dev-karpenter.yaml
```
