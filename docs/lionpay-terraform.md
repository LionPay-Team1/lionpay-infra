# Lionpay Terraform (IaC) 설계 문서

## 1. 개요 (Overview)

본 문서는 Lionpay 서비스의 AWS 인프라를 Terraform으로 구축하기 위한 설계 명세서이다. 관리 효율성을 위해 **환경별 단일 계층 구조(Single Layer per Environment)**를 채택하며, Terraform Cloud를 통해 상태를 관리한다.

### 주요 아키텍처 특징

- **Hub-and-Spoke Cluster**: 서울 리전 클러스터가 Hub(ArgoCD) 역할을 겸임하며, 도쿄 리전 클러스터(Spoke)를 통합 관리한다.
- **EKS Auto Mode**: 모든 워크로드는 ARM(Graviton) 기반의 EKS Auto Mode 클러스터에서 구동된다.
- **Global Gateway**: Route 53 지연 시간 기반 라우팅(Latency Routing)과 CloudFront를 결합하여 전역 트래픽 가속 및 최적 경로 접속을 보장한다.
- **SaaS Monitoring**: Grafana Cloud를 도입하여 별도의 모니터링 서버 구축 없이 에이전트 기반으로 데이터를 전송한다.

## 2. 저장소 구조 (Repository Structure)

단일 실행으로 멀티 리전 리소스를 프로비저닝하기 위해 `environments` 하위 파일에서 복수의 프로바이더를 호출한다.

```text
lionpay-infra/
├── .github/workflows/             # GitHub Actions (Terraform Plan/Apply)
├── k8s/                           # ArgoCD Apps & Helm Charts
└── terraform/
    ├── modules/                   # [Resource Modules]
    │   ├── vpc/                   # VPC, Subnet, Flow Logs
    │   ├── eks/                   # EKS Cluster, Karpenter, NodePools
    │   ├── dynamodb/              # DynamoDB Tables (Multi-Region)
    │   ├── dsql/                  # Amazon Aurora DSQL (Seoul, Tokyo, Osaka)
    │   ├── ecr/                   # ECR Repositories
    │   └── s3/                    # S3 Buckets
    │
    └── environments/              # [Deployable Units]
        ├── dev/                   # TFC Workspace: lionpay-dev
        │   ├── main.tf            # 전역 로직 및 데이터 소스
        │   ├── vpc.tf             # 서울 & 도쿄 VPC 정의
        │   ├── eks.tf             # 서울 & 도쿄 EKS 정의
        │   ├── dsql.tf            # Aurora DSQL 멀티 리전 클러스터
        │   ├── dynamodb.tf        # DynamoDB 글로벌 테이블
        │   ├── s3.tf              # 공통 S3 버킷
        │   ├── providers.tf       # 서울/도쿄/오사카/ECR-Public 프로바이더
        │   ├── variables.tf
        │   ├── terraform.tfvars
        │   └── outputs.tf
        ├── prod/                  # TFC Workspace: lionpay-prod (추후 구성)
        └── ecr/                   # TFC Workspace: lionpay-common-ecr
            ├── main.tf            # 전역 서비스용 ECR 리포지토리 정의
            ├── providers.tf       # 멀티 리전(서울/도쿄) 프로바이더
            └── versions.tf
```

## 3. 리소스 격리 및 상태 관리 (Isolation Strategy)

### 3.1. ECR 독립 관리 (Shared Infrastructure)

서비스 컨테이너 이미지를 저장하는 **ECR(Elastic Container Registry)**은 특정 환경(`dev`, `prod`)의 생명주기에 종속되지 않도록 별도의 워크스페이스에서 관리한다.

- **이유**: 환경 파괴 및 재구축 시에도 이미지는 보존되어야 하며, `dev`에서 빌드된 이미지를 `prod`에서 즉시 참조할 수 있는 구조를 확보하기 위함이다.
- **범위**: 서울 및 도쿄 리전의 모든 마이크로서비스(`auth`, `wallet` 등) 리포지토리.

### 3.2. 프로바이더 구성 (Multi-Region Providers)

`providers.tf` 파일에 서울, 도쿄, 오사카(Witness), ECR Public 리전의 프로바이더를 정의한다.

```hcl
provider "aws" {
  alias  = "seoul"
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "osaka" # DSQL 멀티-리전 Witness 용
  region = "ap-northeast-3"
}

provider "aws" {
  alias  = "ecrpublic" # Karpenter 인증 전용
  region = "us-east-1"
}
```

### 3.3. 멀티 리전 클러스터 배치

단일 환경 구성 내에서 2개의 EKS 클러스터를 통합 관리한다.

```hcl
# 1. Seoul Cluster (Seoul) - ArgoCD Hub & Service
module "eks_seoul" {
  source       = "../modules/eks"
  cluster_name = "lionpay-dev-seoul"
  vpc_id       = module.vpc_seoul.vpc_id
  subnet_ids   = module.vpc_seoul.private_subnets
  # ...
}

# 2. Tokyo Cluster (Tokyo) - Spoke Service
module "eks_service_tokyo" {
  source       = "../modules/eks"
  providers    = { aws = aws.tokyo }
  cluster_name = "lionpay-dev-tokyo"
  vpc_id       = module.vpc_tokyo.vpc_id
  subnet_ids   = module.vpc_tokyo.private_subnets
  # ...
}
```

## 4. 핵심 코드 구현 예시 (Core Implementation)

### A. Aurora DSQL 멀티 리전 클러스터 (dsql.tf)

DSQL은 서울과 도쿄 리전에 클러스터를 배치하고 오사카 리전을 Witness로 사용하여 멀티 리전 페어링을 구성한다.

```hcl
module "dsql_multi_region" {
  source = "../modules/dsql"
  
  # Seoul (Primary)
  seoul_vpc_id = module.vpc_service_seoul.vpc_id
  
  # Tokyo (Secondary)
  tokyo_vpc_id = module.vpc_service_tokyo.vpc_id
  
  # Multi-Region Pairing with Osaka Witness
  enable_multi_region = true
  witness_region      = "ap-northeast-3"
}
```

## 5. VPC 피어링 및 라우팅 (VPC Peering)

서울 클러스터(ArgoCD)가 도쿄 클러스터를 제어하기 위해 서울 VPC ↔ 도쿄 VPC 간 직접 피어링을 연결한다.

- **Peering**: VPC Seoul (Hub) ↔ VPC Tokyo (Spoke)
- **Route Table**: 각 VPC의 Private Subnet 라우팅 테이블에 상대 리전 CIDR 경로 추가.

## 6. 클러스터 역할 및 지역 배치 전략

| 구분 | 지역 (Region) | 역할 | 주요 실행 요소 |
| :--- | :--- | :--- | :--- |
| **Seoul Cluster** | 서울 (ap-northeast-2) | Hub (Admin + Service) | **ArgoCD (EKS Capability)**, Lionpay API, Monitoring Agent |
| **Tokyo Cluster** | 도쿄 (ap-northeast-1) | Spoke (Service) | Lionpay API, Monitoring Agent |

## 7. 환경별 구성 전략 (Environment Strategy)

`dev`와 `prod` 환경은 아키텍처 구조는 동일하나, 비용 효율성과 운영 안정성을 위해 리소스 스펙 및 설정 값을 차별화한다.

| 카테고리 | 설정 항목 | Dev (개발/QA) | Prod (운영) |
| :--- | :--- | :--- | :--- |
| **Compute (EKS)** | Service Nodes | t4g.medium (ARM) | m7g.large (ARM) |
| | Capacity Type | SPOT (비용 최적화) | ON_DEMAND (안정성 보장) |
| **Gateway** | CloudFront Price | PriceClass_100 | PriceClass_All |
| **Common** | TFC Workspace | lionpay-dev | lionpay-prod |

## 8. 배포 워크플로우 (Deployment Workflow)

서울과 도쿄 리전의 모든 리소스가 단일 `plan`으로 관리되어 일관성을 보장한다.
