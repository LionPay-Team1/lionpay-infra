# Lionpay Terraform (IaC) 설계 문서

## 1. 개요 (Overview)

본 문서는 Lionpay 서비스의 AWS 인프라를 **Terragrunt**로 관리하기 위한 설계 명세서이다. DRY(Don't Repeat Yourself) 원칙을 적용하여 환경별(dev/prod) 코드 중복을 최소화하고, 스택별 독립 배포가 가능한 구조를 채택한다.

### 주요 아키텍처 특징

- **Hub-and-Spoke Cluster**: 서울 리전 클러스터가 Hub(ArgoCD) 역할을 겸임하며, 도쿄 리전 클러스터(Spoke)를 통합 관리한다.
- **EKS Auto Mode**: 모든 워크로드는 ARM(Graviton) 기반의 EKS Auto Mode 클러스터에서 구동된다.
- **Multi-Region**: 서울과 도쿄 리전에 VPC, EKS, DSQL을 배포하여 고가용성 확보
- **Terragrunt**: 환경별 변수 분리, 의존성 관리, DRY 원칙 적용

## 2. 저장소 구조 (Repository Structure)

```text
terraform/
├── terragrunt.hcl                    # 루트 설정 (providers, backend)
├── _envcommon/                        # 공통 Terraform 코드
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   ├── dsql/
│   ├── dynamodb/
│   └── s3/
├── shared/                            # 환경 공유 리소스
│   └── ecr/
│       ├── terragrunt.hcl
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
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
        └── ...
```

## 3. Terragrunt 구조 설명

### 3.1. 루트 설정 (terragrunt.hcl)

프로젝트 전역 설정을 정의한다:

- AWS Provider 생성 (서울, 도쿄, ECR Public)
- Terraform 버전 요구사항
- 공통 inputs (project_name, regions)

### 3.2. 공통 코드 (_envcommon/)

실제 Terraform 리소스가 정의된 코드:

- `vpc/`: VPC, Subnet, NAT Gateway, DynamoDB VPC Endpoint
- `eks/`: EKS 클러스터, Karpenter, ArgoCD Capability, Blueprints Addons
- `dsql/`: Aurora DSQL 멀티 리전 클러스터, VPC Endpoint, IRSA
- `dynamodb/`: DynamoDB Global Table
- `s3/`: S3 버킷

### 3.3. 환경별 설정 (environments/)

각 환경의 `env.hcl`에서 변수를 정의하고, 각 스택의 `terragrunt.hcl`에서 `_envcommon/`의 코드를 참조한다.

```hcl
# environments/dev/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = "${dirname(find_in_parent_folders())}/environments/dev/env.hcl"
  expose = true
}

terraform {
  source = "${dirname(find_in_parent_folders())}/_envcommon/vpc"
}

inputs = {
  seoul_vpc_cidr = include.env.locals.seoul_vpc_cidr
  # ...
}
```

### 3.4. 의존성 관리

Terragrunt의 `dependency` 블록으로 스택 간 의존성을 명시한다:

```hcl
# environments/dev/eks/terragrunt.hcl
dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  seoul_vpc_id          = dependency.vpc.outputs.seoul_vpc_id
  seoul_private_subnets = dependency.vpc.outputs.seoul_private_subnets
}
```

## 4. 리소스 의존성 그래프

```
vpc ─┬─> eks ─┬─> dsql
     │        │
     │        └─> (karpenter, argocd)
     │
     └─> dynamodb, s3

ecr (shared, 독립)
```

## 5. 환경별 차이점

| 카테고리 | 설정 항목 | Dev | Prod |
|:---------|:----------|:----|:-----|
| **VPC** | Seoul CIDR | 10.0.0.0/16 | 10.10.0.0/16 |
|         | Tokyo CIDR | 10.1.0.0/16 | 10.11.0.0/16 |
|         | NAT Gateway | Single | Multiple (HA) |
| **EKS** | Karpenter CPU Limit | 1000 | 2000 |
| **DSQL** | Deletion Protection | Disabled | Enabled |
| **DynamoDB** | PITR | Disabled | Enabled |
|              | Deletion Protection | Disabled | Enabled |

## 6. 사용법

### 환경 배포

```bash
# Dev 환경 전체 배포
cd terraform/environments/dev
terragrunt run-all apply

# 개별 스택만 배포
cd terraform/environments/dev/vpc
terragrunt apply
```

### 공유 ECR 배포

```bash
cd terraform/shared/ecr
terragrunt apply
```

### Plan 확인

```bash
cd terraform/environments/dev
terragrunt run-all plan

# 의존성 그래프
terragrunt graph-dependencies
```

## 7. 클러스터 역할 및 지역 배치 전략

| 구분 | 지역 (Region) | 역할 | 주요 실행 요소 |
|:-----|:--------------|:-----|:---------------|
| **Seoul Cluster** | 서울 (ap-northeast-2) | Hub (Admin + Service) | ArgoCD (EKS Capability), Lionpay API, Monitoring Agent |
| **Tokyo Cluster** | 도쿄 (ap-northeast-1) | Spoke (Service) | Lionpay API, Monitoring Agent |
