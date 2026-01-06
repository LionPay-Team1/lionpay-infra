# LionPay Kubernetes 배포 가이드

초보자도 따라하기 쉽도록 작성된 단계별 배포 가이드입니다.

## 📁 디렉토리 구조

```
kubernetes/
├── base/                    # 공통 설정 (모든 환경이 공유)
│   ├── namespace.yaml       # 네임스페이스
│   ├── configmap.yaml       # 환경변수
│   ├── auth-service.yaml    # Auth 서비스
│   ├── auth-deployment.yaml # Auth 배포
│   ├── wallet-service.yaml  # Wallet 서비스
│   ├── wallet-deployment.yaml
│   ├── ingress.yaml         # ALB Ingress
│   ├── hpa.yaml             # 자동 확장
│   ├── pdb.yaml             # Pod 중단 예산
│   └── kustomization.yaml   # 통합 관리
├── overlays/
│   ├── dev/                 # Dev 환경 설정
│   │   └── kustomization.yaml
│   └── prod/                # Prod 환경 설정
│       └── kustomization.yaml
└── README.md
```

## 🚀 사전 준비사항

### 1. AWS ECR 이미지 확인
```bash
# AWS 계정 ID 확인
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo $AWS_ACCOUNT_ID

# ECR 리포지토리 확인
aws ecr describe-repositories --region ap-northeast-2 | grep repositoryUri
```

다음과 같이 출력되어야 합니다:
```
<AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/lionpay-auth
<AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/lionpay-wallet
```

### 2. EKS 클러스터 연결 확인
```bash
# kubeconfig 업데이트
aws eks update-kubeconfig --name lionpay-dev-eks --region ap-northeast-2

# 클러스터 연결 확인
kubectl cluster-info
```

### 3. ALB Ingress Controller 설치
```bash
# ALB Ingress Controller OIDC 공급자 설정
eksctl utils associate-iam-oidc-provider --cluster=lionpay-dev-eks --region ap-northeast-2 --approve

# ALB Ingress Controller 설치
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=lionpay-dev-eks
```

### 4. Metrics Server 설치 (HPA를 위해 필수)
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## 📝 단계별 배포 절차

### Step 1: 이미지 태그 수정
모든 매니페스트에서 `YOUR_AWS_ACCOUNT_ID`를 실제 AWS 계정 ID로 변경합니다:

```bash
# AWS 계정 ID 저장
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 모든 파일에서 일괄 수정 (Windows PowerShell)
$accountId = aws sts get-caller-identity --query Account --output text
Get-ChildItem -Path "kubernetes" -Recurse -Include "*.yaml" | 
  ForEach-Object {
    (Get-Content $_.FullName) -replace 'YOUR_AWS_ACCOUNT_ID', $accountId | 
    Set-Content $_.FullName
  }
```

### Step 2: Dev 환경 배포

#### 2-1. 모든 리소스 미리 보기
```bash
kubectl kustomize kubernetes/overlays/dev
```

#### 2-2. 네임스페이스 먼저 생성
```bash
kubectl apply -f kubernetes/base/namespace.yaml
```

#### 2-3. 전체 리소스 배포
```bash
kubectl apply -k kubernetes/overlays/dev
```

#### 2-4. 배포 상태 확인
```bash
# 네임스페이스 확인
kubectl get namespaces

# 네임스페이스 내 리소스 확인
kubectl get all -n lionpay

# Pod 실행 상태 확인
kubectl get pods -n lionpay -w  # -w는 watch 옵션 (Ctrl+C로 종료)

# 상세 정보 확인
kubectl describe deployment auth-deployment -n lionpay
kubectl describe deployment wallet-deployment -n lionpay
```

#### 2-5. Pod 로그 확인
```bash
# Auth Pod 로그 확인
kubectl logs -n lionpay -l app=auth --tail=100 -f

# Wallet Pod 로그 확인
kubectl logs -n lionpay -l app=wallet --tail=100 -f

# 특정 Pod 로그 확인
kubectl logs -n lionpay <POD_NAME>
```

#### 2-6. 서비스 및 Ingress 확인
```bash
# 서비스 확인
kubectl get svc -n lionpay

# Ingress 확인
kubectl get ingress -n lionpay

# Ingress 상세 정보 (ALB DNS 주소 확인)
kubectl describe ingress lionpay-ingress -n lionpay
```

이 명령어로 출력된 "Address" 필드가 ALB의 DNS 주소입니다.
예: `k8s-lionpay-ingress-xxxx.ap-northeast-2.elb.amazonaws.com`

### Step 3: HPA 및 PDB 상태 확인
```bash
# HPA 확인
kubectl get hpa -n lionpay

# HPA 상세 정보
kubectl describe hpa auth-hpa -n lionpay

# PDB 확인
kubectl get poddisruptionbudget -n lionpay
```

### Step 4: CloudFront 설정 (별도)

Ingress 배포 후, AWS CloudFront를 설정합니다:

#### 4-1. Route53에서 ALB DNS 주소 확인
위에서 확인한 ALB DNS 주소를 사용합니다.

#### 4-2. CloudFront Distribution 생성 (api.lionpay.shop)
```
도메인: api.lionpay.shop
Origin 도메인: k8s-lionpay-ingress-xxxx.ap-northeast-2.elb.amazonaws.com
Protocol: HTTP Only
Viewer Protocol Policy: Redirect HTTP to HTTPS
```

자세한 설정은 설계 문서의 "1.1 CloudFront 설정" 참조

#### 4-3. Route53 CNAME 레코드 추가
```
호스트 이름: api.lionpay.shop
값: CloudFront Distribution 도메인
타입: CNAME
```

### Step 5: CORS 설정 확인

백엔드 코드의 CORS 설정을 확인합니다:

#### 5-1 Auth 서비스 (Spring Boot)
파일: `lionpay-auth/src/main/java/.../SecurityConfig.java`

```java
configuration.setAllowedOrigins(Arrays.asList(
    "https://lionpay.shop",
    "https://admin.lionpay.shop",
    "http://localhost:5173",
    "http://localhost:5174"
));
```

#### 5-2 Wallet 서비스 (.NET)
파일: `lionpay-wallet/Program.cs`

```csharp
corsBuilder.WithOrigins(
    "https://lionpay.shop",
    "https://admin.lionpay.shop",
    "http://localhost:5173",
    "http://localhost:5174"
)
```

## 🧪 배포 검증

### 1. API 엔드포인트 테스트 (로컬)
```bash
# ALB DNS 주소 확인
ALB_DNS=$(kubectl get ingress -n lionpay -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')
echo $ALB_DNS

# Auth API 테스트
curl -H "Host: api.lionpay.shop" http://$ALB_DNS/api/v1/auth/health

# Wallet API 테스트
curl -H "Host: api.lionpay.shop" http://$ALB_DNS/api/v1/wallet/health
```

### 2. Pod 내부 테스트
```bash
# Auth Pod 내부에서 테스트
kubectl exec -it -n lionpay <AUTH_POD_NAME> -- /bin/sh
curl localhost:8080/api/v1/auth/health

# Wallet Pod 내부에서 테스트
kubectl exec -it -n lionpay <WALLET_POD_NAME> -- /bin/sh
curl localhost:8081/api/v1/wallet/health
```

### 3. CORS 테스트
```bash
# CloudFront를 통해 API 호출
curl -X OPTIONS https://api.lionpay.shop/api/v1/auth/health \
  -H "Origin: https://lionpay.shop" \
  -H "Access-Control-Request-Method: GET" \
  -v
```

응답 헤더에 다음이 포함되어야 합니다:
```
Access-Control-Allow-Origin: https://lionpay.shop
Access-Control-Allow-Methods: GET, POST, PUT, DELETE
```

## 🔄 Prod 환경 배포

Dev 환경 배포 후 동일한 절차로 Prod 배포:

```bash
# Prod 환경 리소스 미리 보기
kubectl kustomize kubernetes/overlays/prod

# Prod 환경 배포
kubectl apply -k kubernetes/overlays/prod

# Prod 환경 상태 확인
kubectl get all -n lionpay -l environment=prod
```

## 🛠️ 자주 사용하는 명령어

### 배포 업데이트
```bash
# 이미지 태그 업데이트 후 배포
kubectl set image deployment/auth-deployment \
  auth=YOUR_AWS_ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/lionpay-auth:v1.1 \
  -n lionpay

# Kustomize로 업데이트
kubectl apply -k kubernetes/overlays/dev
```

### Pod 재시작
```bash
# 전체 Pod 재시작
kubectl rollout restart deployment/auth-deployment -n lionpay
kubectl rollout restart deployment/wallet-deployment -n lionpay

# 배포 상태 확인
kubectl rollout status deployment/auth-deployment -n lionpay
```

### 배포 히스토리
```bash
# Deployment 변경 이력 확인
kubectl rollout history deployment/auth-deployment -n lionpay

# 특정 리비전으로 롤백
kubectl rollout undo deployment/auth-deployment -n lionpay --to-revision=2
```

### 네임스페이스 삭제
```bash
# 네임스페이스 및 모든 리소스 삭제
kubectl delete namespace lionpay
```

## 📊 모니터링 및 로깅 설정 (선택사항)

### CloudWatch Logs 통합
```bash
# CloudWatch Log Group 생성
aws logs create-log-group --log-group-name /lionpay/eks --region ap-northeast-2

# Pod 로그를 CloudWatch로 전송하도록 설정
# (별도의 fluent-bit 또는 CloudWatch Container Insights 설정 필요)
```

### Prometheus + Grafana (선택사항)
```bash
# Prometheus Community Helm Chart 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Prometheus 설치
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace
```

## ⚠️ 트러블슈팅

### Pod이 Pending 상태인 경우
```bash
# Pod 상세 정보 확인
kubectl describe pod <POD_NAME> -n lionpay

# 노드 리소스 확인
kubectl top nodes
kubectl top pods -n lionpay
```

### 이미지 Pull 실패
```bash
# ECR 인증 토큰 갱신
aws ecr get-login-password --region ap-northeast-2 | \
  docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com

# imagePullSecret 생성 (필요시)
kubectl create secret docker-registry ecr-secret \
  --docker-server=<AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-northeast-2) \
  -n lionpay
```

### Ingress가 ALB를 생성하지 못한 경우
```bash
# ALB Ingress Controller 로그 확인
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# IAM 역할 권한 확인 (노드에 필요한 IAM 정책이 있는지 확인)
```

### CORS 오류
```bash
# 요청 헤더 확인
curl -v https://api.lionpay.shop/api/v1/auth/health

# 응답 CORS 헤더 확인
Access-Control-Allow-Origin
Access-Control-Allow-Methods
Access-Control-Allow-Headers
```

## 📚 추가 참고 자료

- [Kubernetes 공식 문서](https://kubernetes.io/docs/)
- [AWS EKS 문서](https://docs.aws.amazon.com/eks/)
- [ALB Ingress Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Kustomize 가이드](https://kustomize.io/)

---

**작성일**: 2025년 12월 30일
**버전**: 1.0
