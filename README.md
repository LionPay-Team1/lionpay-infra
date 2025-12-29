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
