# Lionpay Terraform (IaC) 설계 문서 (1)

## 1. 개요 (Overview)

본 문서는 `Lionpay` 서비스의 AWS 인프라를 Terraform으로 구축하기 위한 설계 명세서이다. 관리 효율성을 위해 환경별 단일 계층 구조(Single Layer per Environment)를 채택하며, Terraform Cloud를 통해 상태를 관리한다.

**주요 아키텍처 특징:**

- **Multi-Region & Multi-VPC:** 서울 리전의 **Admin VPC**를 허브로, 서울/도쿄 리전의 **Service VPC**를 스포크로 연결하여 관리와 서비스를 물리적으로 격리한다.
- **EKS Auto Mode:** 모든 워크로드는 ARM(Graviton) 기반의 EKS Auto Mode 클러스터에서 구동된다.
- **Global Gateway:** Route 53 지연 시간 기반 라우팅(Latency Routing)과 CloudFront를 결합하여 전역 트래픽 가속 및 최적 경로 접속을 보장한다.
- **SaaS Monitoring:** Grafana Cloud를 도입함에 따라 Admin 클러스터는 모니터링 서버 호스팅 부담 없이 **GitOps(ArgoCD)** 컨트롤 플레인 역할에 집중한다.

## 2. 저장소 구조 (Repository Structure)

단일 실행으로 멀티 리전 리소스를 프로비저닝하기 위해 `environments` 하위 파일에서 복수의 프로바이더를 호출한다.

```
lionpay-infra/
├── .github/workflows/             # GitHub Actions (Terraform Plan/Apply)
├── k8s/                           # ArgoCD Apps & Helm Charts
└── terraform/
    ├── modules/                   # [Resource Modules] - 재사용 가능한 리소스 정의
    │   ├── network/               # VPC, Subnet, Peering, NAT Gateway
    │   ├── database/              # DynamoDB(Global), Aurora DSQL
    │   ├── eks/                   # EKS (Auto Mode & Custom NodePool)
    │   ├── iam/
    │   ├── ecr/
    │   ├── security-group/
    │   └── gateway/               # [Global Resources] CloudFront, Route53, ACM, WAF
    │       ├── main.tf            # Route 53 Latency Record & CloudFront 정의
    │       ├── variables.tf       # 도메인 및 리전별 ALB DNS 변수
    │       └── outputs.tf         # CloudFront Domain, DNS 정보 출력
    │
    └── environments/              # [Deployable Units] - 실제 환경별 실행 디렉토리
        ├── dev/                   # TFC Workspace: lionpay-dev
        │   ├── main.tf            # Admin(Seoul) & Service(Seoul/Tokyo) 통합 호출
        │   ├── providers.tf       # Seoul/Tokyo/Virginia(ACM용) 프로바이더 정의
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── terraform.tfvars
        └── prod/                  # TFC Workspace: lionpay-prod
            ├── main.tf
            ├── providers.tf
            ├── variables.tf
            ├── outputs.tf
            └── terraform.tfvars

```

## 3. 상태 관리 및 멀티 리전 연동 (State & Region Wiring)

### 3.1. 프로바이더 구성 (Multi-Region Providers)

`providers.tf` 파일에 서울, 도쿄, 버지니아(ACM 인증서용) 리전의 프로바이더를 정의한다.

```
terraform {
  cloud {
    organization = "lionpay-org"
    workspaces {
      name = "lionpay-dev"
    }
  }
}

provider "aws" {
  alias  = "seoul"
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "virginia" # CloudFront ACM 전용
  region = "us-east-1"
}

```

### 3.2. 멀티 VPC 및 클러스터 배치

단일 환경 구성(`main.tf`) 내에서 3개의 VPC와 3개의 EKS 클러스터를 통합 관리한다.

```
# 1. Admin VPC & Cluster (Seoul)
module "vpc_admin_seoul" {
  source    = "../modules/network"
  providers = { aws = aws.seoul }
  name      = "lionpay-${var.env}-admin-vpc-seoul"
}

module "eks_admin_seoul" {
  source       = "../modules/eks"
  providers    = { aws = aws.seoul }
  cluster_name = "lionpay-${var.env}-admin-seoul"
  vpc_id       = module.vpc_admin_seoul.vpc_id
  subnet_ids   = module.vpc_admin_seoul.private_subnets
  # Admin은 관리 도구용이므로 안정적인 On-Demand 노드 사용
  node_instance_types = ["t4g.medium"]
  node_capacity_type  = "ON_DEMAND"
}

# 2. Service VPC & Cluster (Seoul)
module "vpc_service_seoul" {
  source    = "../modules/network"
  providers = { aws = aws.seoul }
  name      = "lionpay-${var.env}-service-vpc-seoul"
}

module "eks_service_seoul" {
  source       = "../modules/eks"
  providers    = { aws = aws.seoul }
  cluster_name = "lionpay-${var.env}-service-seoul"
  vpc_id       = module.vpc_service_seoul.vpc_id
  subnet_ids   = module.vpc_service_seoul.private_subnets
}

# 3. Service VPC & Cluster (Tokyo)
module "vpc_service_tokyo" {
  source    = "../modules/network"
  providers = { aws = aws.tokyo }
  name      = "lionpay-${var.env}-service-vpc-tokyo"
}

module "eks_service_tokyo" {
  source       = "../modules/eks"
  providers    = { aws = aws.tokyo }
  cluster_name = "lionpay-${var.env}-service-tokyo"
  vpc_id       = module.vpc_service_tokyo.vpc_id
  subnet_ids   = module.vpc_service_tokyo.private_subnets
}

```

## 4. 핵심 코드 구현 예시 (Core Implementation)

### A. Gateway 모듈 (`modules/gateway/main.tf`)

Route 53 지연 시간 레코드를 생성하여 CloudFront가 가장 가까운 리전의 ALB를 오리진으로 선택하게 한다.

```
# 1. Route 53 Latency Records (Origin Endpoint)
resource "aws_route53_record" "origin_latency_seoul" {
  zone_id = var.hosted_zone_id
  name    = "origin-api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 60

  latency_routing_policy { region = "ap-northeast-2" }
  set_identifier = "seoul"
  records        = [var.alb_seoul_dns]
}

resource "aws_route53_record" "origin_latency_tokyo" {
  zone_id = var.hosted_zone_id
  name    = "origin-api.${var.domain_name}"
  type    = "CNAME"
  ttl     = 60

  latency_routing_policy { region = "ap-northeast-1" }
  set_identifier = "tokyo"
  records        = [var.alb_tokyo_dns]
}

# 2. CloudFront Distribution
resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = "origin-api.${var.domain_name}"
    origin_id   = "MultiRegion-Backend"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
    }
  }

  # API Path Behavior (Cache Disabled)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "MultiRegion-Backend"
    # Host 헤더 전달을 통한 ALB 라우팅 보장
    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization"]
      cookies { forward = "all" }
    }
    min_ttl = 0; default_ttl = 0; max_ttl = 0
  }
}

```

## 5. VPC 피어링 및 라우팅 (VPC Peering)

Admin VPC(Seoul)의 ArgoCD가 각 Service Cluster에 접근할 수 있도록 피어링을 구성한다.

- **Peering 1:** Admin VPC (Seoul) ↔ Service VPC (Seoul)
- **Peering 2:** Admin VPC (Seoul) ↔ Service VPC (Tokyo) - *Inter-Region Peering*

## 6. 클러스터 역할 및 지역 배치 전략

| **구분** | **지역 (Region)** | **VPC 구분** | **주요 실행 요소** |
| --- | --- | --- | --- |
| **Gateway Layer** | **Global** | **N/A** | **CloudFront, Route 53 (Latency)** |
| **Admin Cluster** | 서울 (ap-northeast-2) | Admin VPC | **ArgoCD (GitOps Hub)** |
| **Service Cluster** | 서울 / 도쿄 | Service VPC | Lionpay API (Auth, Wallet) |

- *참고: 모니터링은 Grafana Cloud(SaaS)를 사용하므로 Admin 클러스터는 별도의 Prometheus/Loki 서버를 호스팅하지 않고 ArgoCD 운영에 집중한다.*

## 7. 환경별 구성 전략 (Environment Strategy)

`dev`와 `prod` 환경은 아키텍처 구조는 동일하나, 비용 효율성과 운영 안정성을 위해 리소스 스펙 및 설정 값을 차별화한다.

| **카테고리** | **설정 항목** | **Dev (개발/QA)** | **Prod (운영)** |
| --- | --- | --- | --- |
|  |  |  |  |
|  | **NAT Gateway** | 1 per VPC (비용 절감) | 1 per AZ (고가용성) |
| **Compute (EKS)** | **Node Instance** | `t4g.medium` (ARM) | `m7g.large` (ARM) |
|  | **Capacity Type** | **SPOT** (비용 최적화) | **ON_DEMAND** (안정성 보장) |
|  | **Cluster Logging** | 비활성화 또는 최소화 | 활성화 (Audit, Authenticator 등) |
|  | **Node Scaling** | Min 1 / Max 3 | Min 3 / Max 10 (AZ 분산) |
| **Database** | **Billing Mode** | On-Demand (Pay-per-request) | Provisioned (Auto Scaling 적용) |
|  | **Backup (PITR)** | 비활성화 | 활성화 (Point-in-Time Recovery) |
|  | **Deletion Protection** | 비활성화 | 활성화 (실수 방지) |
| **Gateway** | **CloudFront Price Class** | `PriceClass_100` (저렴한 리전만) | `PriceClass_All` (전 세계) |
|  | **WAF Web ACL** | Count 모드 (모니터링 위주) | Block 모드 (실제 차단) |
| **Common** | **TFC Workspace** | `lionpay-dev` | `lionpay-prod` |

## 8. 배포 워크플로우 (Deployment Workflow)

서울과 도쿄 리전의 모든 리소스가 단일 `plan`으로 관리되어 일관성을 보장한다.
