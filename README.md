# LionPay Infrastructure

LionPay 프로젝트의 AWS 인프라를 Terragrunt로 관리합니다.

## 사전 요구사항

### Terraform & Terragrunt 설치 (Windows)

```powershell
# Windows Package Manager (winget) 사용
winget install Hashicorp.Terraform
winget install Gruntwork.Terragrunt

# 설치 확인
terraform --version
terragrunt --version
```

### AWS CLI

```powershell
winget install Amazon.AWSCLI

# 설정
aws configure
```

## 디렉토리 구조

```
terraform/
├── terragrunt.hcl                    # 루트 설정 (providers, backend)
├── _envcommon/                        # 공통 Terraform 코드
│   ├── vpc/
│   ├── eks/
│   ├── dsql/
│   ├── dynamodb/
│   └── s3/
├── shared/                            # 환경 공유 리소스
│   └── ecr/                          # dev/prod 공용 ECR
└── environments/
    ├── dev/
    │   ├── env.hcl                   # dev 환경 변수
    │   ├── vpc/terragrunt.hcl
    │   ├── eks/terragrunt.hcl
    │   ├── dsql/terragrunt.hcl
    │   ├── dynamodb/terragrunt.hcl
    │   └── s3/terragrunt.hcl
    └── prod/
        ├── env.hcl                   # prod 환경 변수
        └── ...                       # (dev와 동일한 구조)
```

## 사용법

### 환경 설정

배포 전에 `environments/{env}/env.hcl`에서 다음 값을 설정하세요:

```hcl
# ArgoCD / IAM Identity Center (필수)
idc_instance_arn      = "arn:aws:sso:::instance/ssoins-xxxxx"
argocd_admin_group_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### 전체 환경 배포

```bash
# Dev 환경 전체 배포
cd terraform/environments/dev
terragrunt run-all apply

# Prod 환경 전체 배포
cd terraform/environments/prod
terragrunt run-all apply
```

### 개별 스택 배포

```bash
# VPC만 배포
cd terraform/environments/dev/vpc
terragrunt apply

# EKS만 배포 (VPC 의존성 자동 처리)
cd terraform/environments/dev/eks
terragrunt apply
```

### 공유 ECR 배포

```bash
cd terraform/shared/ecr
terragrunt apply
```

### Plan 확인

```bash
# 전체 plan
cd terraform/environments/dev
terragrunt run-all plan

# 의존성 그래프 확인
terragrunt graph-dependencies
```

### 삭제

```bash
# 전체 환경 삭제
cd terraform/environments/dev
terragrunt run-all destroy
```

## 리소스 의존성

```
vpc ─┬─> eks ─┬─> dsql
     │        │
     │        └─> (karpenter, argocd)
     │
     └─> dynamodb, s3
```

## 환경별 차이점

| 설정 | Dev | Prod |
|------|-----|------|
| VPC CIDR (Seoul) | 10.0.0.0/16 | 10.10.0.0/16 |
| VPC CIDR (Tokyo) | 10.1.0.0/16 | 10.11.0.0/16 |
| NAT Gateway | Single | Multiple (HA) |
| Deletion Protection | Disabled | Enabled |
| Point-in-Time Recovery | Disabled | Enabled |
| Karpenter CPU Limit | 1000 | 2000 |

## 문서

- [Terraform 가이드](docs/lionpay-terraform.md)
- [CI/CD 파이프라인](docs/lionpay-cicd.md)
- [Kubernetes 설정](docs/lionpay-k8s.md)
- [모니터링](docs/lionpay-monitoring.md)
