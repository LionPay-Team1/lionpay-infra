# Lionpay Kubernetes (GitOps) 설계 문서

## 1. 개요 (Overview)

본 문서는 Lionpay 서비스의 애플리케이션 배포 및 쿠버네티스 리소스 관리를 위한 설계 명세서이다. 서울 리전 클러스터가 ArgoCD Hub 역할을 겸임하며, 도쿄 리전 클러스터를 Hub-and-Spoke 방식으로 통합 관리한다. 모니터링은 **Grafana Cloud(SaaS)**로 통합된다.

## 2. 저장소 구조 (Repository Structure)

ArgoCD가 참조하는 매니페스트 저장소 구조이다. 서울과 도쿄 클러스터는 동일한 애플리케이션 리소스를 공유한다.

```text
lionpay-infra/
├── k8s/
│   ├── apps/                      # [ArgoCD Applications]
│   │   ├── lionpay-services.yaml   # 전 리전 공통 서비스 배포 정의
│   │
│   ├── charts/                    # [Custom Helm Charts]
│   │   └── lionpay-backend/       # 백엔드 공통 차트
│   │
│   ├── monitoring/                # [Monitoring Manifests]
│   │   └── alloy/                 # Grafana Alloy DaemonSet
│   │
│   └── environments/              # [Values by Cluster]
│       ├── seoul/                 # 서울 리전 설정 (values.yaml)
│       └── tokyo/                 # 도쿄 리전 설정 (values.yaml)
```

## 3. 멀티 클러스터 아키텍처 및 역할

### 3.1. Hub-and-Spoke 관리 체계

| 클러스터 | 위치 | 역할 | 배포 항목 |
| :--- | :--- | :--- | :--- |
| **Seoul Cluster** | 서울 | ArgoCD Hub & Service | ArgoCD, ExternalDNS, Lionpay API |
| **Tokyo Cluster** | 도쿄 | Service Spoke | Lionpay API, Monitoring Agent |

### 3.2. ArgoCD 클러스터 등록

서울 클러스터 내부에 설치된 ArgoCD는 다음과 같이 동작한다:

- **Local (in-cluster)**: 서울 클러스터 자신을 `https://kubernetes.default.svc`로 관리.
- **Remote (external)**: 도쿄 클러스터를 ArgoCD CLI로 등록하여 VPC Peering을 통해 원격 관리.

## 4. 핵심 컴포넌트 구성 상세

### 4.1. Ingress 라우팅 정책 (ALB)

AWS Load Balancer Controller를 사용하며 CloudFront 게이트웨이와 연동된다.

- **Routing Rule**: `/api/auth/*`, `/api/wallet/*`
- **Annotation**: `alb.ingress.kubernetes.io/target-type: ip`

### 4.2. ExternalDNS 및 Route 53 Latency 연동

각 클러스터의 Ingress는 테라폼에서 정의된 Latency Routing 도메인(`origin-api.lionpay.com`)의 타겟으로 자신의 ALB 주소를 등록한다.

### 4.3. 서비스 계정 (IRSA)

- **lionpay-auth-sa**: DynamoDB 접근 권한.
- **lionpay-wallet-sa**: Aurora DSQL 접근 권한.

## 5. Helm Chart 설계 (lionpay-backend)

모든 서비스는 ARM(Graviton) 아키텍처를 기본으로 사용한다.

```yaml
# charts/lionpay-backend/values.yaml
global:
  architecture: arm64

nodeSelector:
  kubernetes.io/arch: arm64
```

## 6. 주요 매니페스트 명세

### 6.1. Shared ArgoCD Application

동일한 애플리케이션 명세를 사용하여 복수의 대상 클러스터에 배포한다.

```yaml
# k8s/apps/lionpay-services.yaml (예시)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: lionpay-backend
spec:
  project: default
  source:
    path: k8s/charts/lionpay-backend
    helm:
      valueFiles:
        - ../../environments/{{cluster}}/values.yaml
  destinations:
    - server: https://kubernetes.default.svc  # Seoul (Local)
    - name: lionpay-tokyo                     # Tokyo (Remote)
```

## 7. 배포 및 동기화 절차 (Workflow)

1. **인프라 및 도구 준비**: Terraform으로 VPC, EKS 및 **ArgoCD(EKS Addon)** 배포.
2. **클러스터 연결**: 서울 클러스터의 ArgoCD에서 도쿄 클러스터를 원격 클러스터로 등록.
3. **App 적용**: `k8s/apps/`의 공통 매니페스트를 ArgoCD에 적용하여 전체 리전 동기화 시작.

## 8. 모니터링 연동 (Grafana Cloud)

Grafana Cloud로 데이터를 직접 전송한다.

### 8.1. Grafana Alloy 배포

- **구성**: 서울 및 도쿄 클러스터 모두에 Alloy DaemonSet을 배포한다.
- **역할**:
  - **서울**: 서비스 메트릭 + ArgoCD 상태 전송.
  - **도쿄**: 서비스 메트릭 전송.
- **인증**: Kubernetes Secret(`alloy-credentials`)을 통해 API Token 주입.
