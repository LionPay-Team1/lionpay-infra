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

### 2. ECR 배포 (환경 공통)

ECR 리포지토리는 dev/prod 환경에서 공유됩니다. 다른 인프라보다 먼저 한 번만 배포하면 됩니다.

```powershell
cd terraform/ecr
terraform init
terraform apply
```

### 3. 메인 인프라 배포 및 삭제 자동화 스크립트

`terraform` 디렉토리 내에 있는 `terraform.ps1` 스크립트를 사용하여 환경별(`dev`, `prod`) 배포, 삭제, 계획 확인을 간편하게 수행할 수 있습니다.

### 스크립트 위치로 이동

```bash
cd terraform
```

### 사용법 (Usage)

`terraform.ps1` 스크립트는 `apply`, `destroy`, `plan` 명령어를 지원합니다. `Env` 파라미터는 필수입니다.

```powershell
# 기본 실행
./terraform.ps1 <Command> -Env <env_name>

# 자동 승인 (apply, destroy만 해당)
./terraform.ps1 <Command> -Env <env_name> -Auto

# AWS 프로필 지정 (선택)
./terraform.ps1 <Command> -Env <env_name> -AwsProfile <profile_name>
```

#### 예시

**배포 (Apply)**

`terraform init`, `workspace` 선택, `terraform apply` 과정이 자동으로 진행됩니다.

```powershell
./terraform.ps1 apply -Env dev
./terraform.ps1 apply -Env dev -Auto
./terraform.ps1 apply -Env dev -AwsProfile likelion-cloud
```

**삭제 (Destroy)**

해당 환경의 리소스를 삭제합니다.

```powershell
./terraform.ps1 destroy -Env dev
```

**계획 (Plan)**

변경 사항을 미리 확인합니다.

```powershell
./terraform.ps1 plan -Env dev
```

## 4. Karpenter NodePool 적용

Terraform 배포 시 Karpenter `NodePool` 및 `EC2NodeClass` 설정이 **자동으로 적용**됩니다.

### 수동으로 업데이트가 필요한 경우

Karpenter 설정(`dev-karpenter.yaml` 또는 `prod-karpenter.yaml`)을 수정한 후:

```powershell
# Terraform을 통해 자동으로 적용 (권장)
./terraform.ps1 apply -Env dev -Auto
```

**주의:** `main/config/dev-karpenter.yaml`을 직접 `kubectl apply`하면 템플릿 변수(`${cluster_name}` 등)가 치환되지 않아 오류가 발생합니다. 반드시 Terraform을 통해 생성된 `.terraform/karpenter_*.yaml` 파일을 사용하거나, `terraform.ps1`을 다시 실행하세요.
