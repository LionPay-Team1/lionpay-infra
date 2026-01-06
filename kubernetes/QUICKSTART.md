# 🚀 LionPay 쿠버네티스 빠른 시작 가이드

초보자를 위한 3단계 배포 과정입니다. 자세한 내용은 `DEPLOYMENT_GUIDE.md` 참조.

## ⏱️ 5분 안에 배포하기

### Step 1: 사전 준비 (2분)

```bash
# 1. AWS 계정 ID 확인
$accountId = aws sts get-caller-identity --query Account --output text
Write-Host "AWS Account ID: $accountId"

# 2. kubeconfig 업데이트
aws eks update-kubeconfig --name lionpay-dev-eks --region ap-northeast-2

# 3. 클러스터 연결 확인
kubectl cluster-info
```

### Step 2: 이미지 경로 수정 (1분)

모든 YAML 파일에서 `YOUR_AWS_ACCOUNT_ID`를 실제 ID로 변경:

```powershell
$accountId = aws sts get-caller-identity --query Account --output text

Get-ChildItem -Path "kubernetes" -Recurse -Include "*.yaml" | 
  ForEach-Object {
    (Get-Content $_.FullName) -replace 'YOUR_AWS_ACCOUNT_ID', $accountId | 
    Set-Content $_.FullName
  }
```

### Step 3: 배포 (2분)

```bash
# 네임스페이스 생성
kubectl apply -f kubernetes/base/namespace.yaml

# 전체 리소스 배포
kubectl apply -k kubernetes/overlays/dev

# 배포 상태 확인
kubectl get pods -n lionpay -w
```

**완료!** 🎉

## ✅ 배포 확인

```bash
# Pod 상태 확인
kubectl get pods -n lionpay

# 서비스 확인
kubectl get svc -n lionpay

# Ingress 확인 (ALB 주소 확인)
kubectl get ingress -n lionpay
```

## 📊 로그 보기

```bash
# Auth 서비스 로그
kubectl logs -n lionpay -l app=auth -f

# Wallet 서비스 로그
kubectl logs -n lionpay -l app=wallet -f
```

## 🧪 API 테스트

```bash
# ALB 주소 확인
$albDns = kubectl get ingress -n lionpay -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
Write-Host "ALB Address: $albDns"

# Auth Health Check
curl -H "Host: api.lionpay.shop" "http://$albDns/api/v1/auth/health"

# Wallet Health Check
curl -H "Host: api.lionpay.shop" "http://$albDns/api/v1/wallet/health"
```

## 🔄 배포 업데이트

```bash
# 새 이미지로 업데이트
kubectl set image deployment/auth-deployment `
  auth=<AWS_ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/lionpay-auth:v1.1 `
  -n lionpay

# 롤아웃 상태 확인
kubectl rollout status deployment/auth-deployment -n lionpay
```

## ❌ 배포 롤백

```bash
# 이전 버전으로 롤백
kubectl rollout undo deployment/auth-deployment -n lionpay

# 롤백 상태 확인
kubectl rollout status deployment/auth-deployment -n lionpay
```

## 🗑️ 삭제

```bash
# 모든 리소스 삭제
kubectl delete namespace lionpay
```

---

**문제 발생 시**: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md#-트러블슈팅) 의 트러블슈팅 섹션 참조
