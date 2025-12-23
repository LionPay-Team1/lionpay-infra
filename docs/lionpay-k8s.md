# Lionpay Kubernetes (GitOps) 설계 문서 (1)

## 1. 개요 (Overview)

본 문서는 `Lionpay` 서비스의 애플리케이션 배포 및 쿠버네티스 리소스 관리를 위한 설계 명세서이다. 테라폼으로 구축된 서울 리전의 **Admin 클러스터**와 서울/도쿄 리전의 **Service 클러스터** 환경을 기반으로 하며, **ArgoCD**를 활용한 Hub-and-Spoke 방식의 GitOps 배포 체계를 정의한다. 모니터링은 Grafana Cloud(SaaS)로 통합되어 Admin 클러스터는 순수 배포 관제 역할에 집중한다.

## 2. 저장소 구조 (Repository Structure)

ArgoCD가 참조하는 매니페스트 저장소는 서비스별 공통점을 추상화한 Helm Chart와 각 클러스터의 환경 설정을 담은 Values 파일로 구성된다.

```
lionpay-infra/
├── k8s/
│   ├── apps/                      # [ArgoCD Applications] - 클러스터별 배포 정의
│   │   ├── dev-seoul.yaml         # Dev 서울 클러스터용 Root App
│   │   ├── prod-seoul.yaml        # Prod 서울 클러스터용 Root App
│   │   └── prod-tokyo.yaml        # Prod 도쿄 클러스터용 Root App
│   │
│   ├── charts/                    # [Custom Helm Charts]
│   │   └── lionpay-backend/       # 백엔드 공통 차트 (Auth, Wallet)
│   │       ├── templates/         # Deployment, Service, Ingress, HPA 등
│   │       └── values.yaml        # 차트 기본값 (ARM 노드 설정 포함)
│   │
│   ├── monitoring/                # [Monitoring Manifests]
│   │   └── alloy/                 # Grafana Alloy DaemonSet 및 ConfigMap
│   │
│   └── environments/              # [Values by Cluster]
│       ├── dev-seoul/             # Dev 서울 서비스 설정
│       ├── prod-seoul/            # Prod 서울 서비스 설정
│       └── prod-tokyo/            # Prod 도쿄 서비스 설정

```

## 3. 멀티 클러스터 아키텍처 및 역할

### 3.1. Hub-and-Spoke 관리 체계

| **클러스터 유형** | **위치 (Region)** | **역할 및 배포 서비스** |
| --- | --- | --- |
| **Admin Cluster (Hub)** | 서울 (ap-northeast-2) | **ArgoCD (GitOps Control Plane)**, ExternalDNS (Global) |
| **Service Cluster (Spoke)** | 서울 (ap-northeast-2) | 실서비스 API (`lionpay-auth`, `lionpay-wallet`), Grafana Alloy |
| **Service Cluster (Spoke)** | 도쿄 (ap-northeast-1) | 실서비스 API (`lionpay-auth`, `lionpay-wallet`), Grafana Alloy |

### 3.2. ArgoCD 클러스터 등록

Admin 클러스터에 설치된 ArgoCD는 외부(Spoke) 클러스터의 API 엔드포인트를 등록하여 관리한다.

- **서울 서비스:** `https://<seoul-eks-api-endpoint>`
- **도쿄 서비스:** `https://<tokyo-eks-api-endpoint>`

## 4. 핵심 컴포넌트 구성 상세

### 4.1. Ingress 라우팅 정책 (ALB)

AWS Load Balancer Controller를 사용하여 각 서비스 클러스터에 ALB를 생성한다. CloudFront 게이트웨이와 연동하기 위해 특정 경로(Path)를 기반으로 서비스를 분기한다.

- **Routing Rule:**
    - `GET/POST /api/auth/*` → `lionpay-auth` 서비스 (Port 80)
    - `GET/POST /api/wallet/*` → `lionpay-wallet` 서비스 (Port 80)
- **Annotation:** `alb.ingress.kubernetes.io/target-type: ip` 설정을 통해 Fargate 또는 EC2 노드에 직접 트래픽을 전달한다.

### 4.2. ExternalDNS 및 Route 53 Latency 연동

각 서비스 클러스터의 Ingress는 테라폼 `gateway` 모듈에서 정의된 **Latency Routing 도메인**(`origin-api.lionpay.com`)의 타겟으로 자신의 ALB 주소를 등록해야 한다.

- **동작:** Ingress 생성 시 ExternalDNS가 해당 클러스터의 리전 정보를 기반으로 Route 53의 Latency 레코드를 업데이트한다.
- **설정:** `txt-owner-id`를 리전별로 다르게 설정하여 레코드 충돌을 방지한다.

### 4.3. 서비스 계정 (IRSA) 및 권한

각 애플리케이션 파드는 AWS 리소스 접근을 위해 전용 IAM Role을 부여받는다.

- **lionpay-auth-sa:** DynamoDB 접근 권한.
- **lionpay-wallet-sa:** Aurora DSQL 접근 권한.

## 5. Helm Chart 설계 (lionpay-backend)

모든 서비스는 ARM(Graviton) 아키텍처를 기본으로 사용하도록 `nodeSelector`를 고정한다.

```
# charts/lionpay-backend/values.yaml (기본값)
global:
  architecture: arm64

nodeSelector:
  kubernetes.io/arch: arm64

serviceAccount:
  create: true
  annotations: {} # 환경별 IRSA Role ARN 주입 영역

ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing

```

## 6. 주요 매니페스트 명세

### 6.1. ArgoCD Application (도쿄 클러스터 예시)

`spec.destination` 설정을 통해 원격 리전 클러스터를 특정한다.

```
# k8s/apps/prod-tokyo.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: lionpay-prod-tokyo-root
  namespace: argocd
spec:
  project: default
  source:
    repoURL: '[https://github.com/lionpay/lionpay-infra.git](https://github.com/lionpay/lionpay-infra.git)'
    targetRevision: HEAD
    path: k8s/environments/prod-tokyo
    directory:
      recurse: true
  destination:
    # 도쿄 서비스 클러스터 이름 또는 서버 URL
    name: lionpay-prod-service-tokyo
    namespace: lionpay-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

```

### 6.2. Ingress 라우팅 (Helm Template)

서비스별 경로 분리를 위한 템플릿 구조이다.

```
# charts/lionpay-backend/templates/ingress.yaml
spec:
  rules:
    - host: {{ .Values.ingress.host }}
      http:
        paths:
          - path: {{ .Values.ingress.path }} # /api/auth 또는 /api/wallet
            pathType: Prefix
            backend:
              service:
                name: {{ include "lionpay-backend.fullname" . }}
                port:
                  number: 80

```

## 7. 배포 및 동기화 절차 (Workflow)

1. **인프라 준비:** 테라폼으로 서울/도쿄 클러스터와 VPC 피어링 구성을 완료한다.
2. **ArgoCD 설정:** 서울 Admin 클러스터에 ArgoCD를 설치하고 도쿄 클러스터를 `argocd cluster add`로 연결한다.
3. **Root App 적용:** `k8s/apps/` 폴더의 환경별 Root Application을 Admin 클러스터에 배포한다.
4. **애플리케이션 배포:**
    - CI 도구가 새로운 이미지를 ECR에 푸시한다.
    - `k8s/environments/{env}/values.yaml`의 이미지 태그를 업데이트한다.
    - ArgoCD가 이를 감지하여 해당 리전(서울 또는 도쿄)의 클러스터에 파드를 배포한다.

## 8. 모니터링 연동 (Grafana Cloud)

**Grafana Cloud**로 데이터를 직접 전송하는 방식을 적용한다.

### 8.1. Grafana Alloy 배포

- **구성:** 모든 클러스터(Admin, Seoul Service, Tokyo Service)에 `Grafana Alloy`를 DaemonSet으로 배포한다.
- **역할:**
    - **Metrics:** Node Exporter, Kubelet, cAdvisor 메트릭 수집 → Grafana Cloud Prometheus 엔드포인트 전송.
    - **Logs:** Pod Logs(`/var/log/pods`) 수집 → Grafana Cloud Loki 엔드포인트 전송.
    - **Traces:** OTel SDK(App) → Alloy(Receiver) → Grafana Cloud Tempo 엔드포인트 전송.

### 8.2. 인증 및 설정

- **Secret 관리:** Grafana Cloud의 API Token과 Endpoint URL은 Kubernetes Secret(`alloy-credentials`)으로 관리하며, External Secrets Operator 등을 통해 AWS Secrets Manager와 연동하는 것을 권장한다.
- **가시성:** 별도의 Grafana 서버 구축 없이 **Grafana Cloud Web Console**을 통해 통합 대시보드와 알람을 관리한다.