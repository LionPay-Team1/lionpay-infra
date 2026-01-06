---
description: Destroy all infrastructure resources
---

# Destroy All Resources Workflow

이 워크플로우는 LionPay 인프라의 모든 AWS 리소스를 완전히 삭제합니다.

## Prerequisites

- AWS CLI 설치 및 구성
- kubectl 설치
- Terraform 설치
- PowerShell 7+

## Execution

### 1. 사용자 확인

실행 전 사용자에게 다음을 확인합니다:
- 삭제할 환경 이름 (예: dev, prod)
- 정말로 모든 리소스를 삭제할 것인지 여부

> **주의**: 이 작업은 되돌릴 수 없습니다. 모든 데이터가 영구적으로 삭제됩니다.

### 2. 스크립트 실행

// turbo
```powershell
cd terraform && ./destroy-all.ps1 -Env dev -Auto
```

## Script Phases

1. **Terraform output 조회** - 클러스터 이름 등 리소스 정보 조회
2. **Seoul 클러스터 정리** - Karpenter NodePool, EC2NodeClass, LoadBalancer 삭제
3. **Tokyo 클러스터 정리** - Seoul과 동일
4. **Orphaned EC2 정리** - Karpenter 태그 기반 남은 인스턴스 종료
5. **Terraform Destroy** - 나머지 인프라 삭제

## Parameters

| 파라미터 | 필수 | 설명 |
| :--- | :--- | :--- |
| `-Env` | Yes | 환경 이름 (dev, prod) |
| `-AwsProfile` | No | AWS 프로필 이름 |
| `-Auto` | No | 확인 프롬프트 스킵 및 auto-approve |

## Exit Codes

- `0`: 성공
- `1`: 실패

## Troubleshooting

### VPC 삭제 실패 시

```bash
# 남은 EC2 인스턴스 확인
aws ec2 describe-instances --filters "Name=vpc-id,Values=<VPC_ID>" --query "Reservations[].Instances[].InstanceId" --no-cli-pager

# 남은 ENI 확인
aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=<VPC_ID>" --query "NetworkInterfaces[].NetworkInterfaceId" --no-cli-pager
```

### Terraform State 문제 시

```bash
terraform state rm <resource_address>
terraform destroy -var-file="<env>.tfvars" -auto-approve
```

### IAM 시간 기반 Deny 정책으로 중단된 경우

`Cloud4-ProjectTimeDeny`와 같은 정책으로 인해 특정 시간대(예: 18:00 이후)에 AWS 작업이 차단될 수 있습니다.

**증상:**
- `explicit deny in an identity-based policy` 오류 발생
- S3, EC2, DynamoDB 등 거의 모든 AWS 작업 실패

**해결 방법:**
1. 허용된 시간대(예: 다음 날 오전)에 다시 실행
2. `errored.tfstate` 파일이 생성된 경우 아래 복구 절차 수행

### errored.tfstate 복구

Terraform이 리소스 삭제 중 상태 저장에 실패하면 로컬에 `errored.tfstate` 파일이 생성됩니다.

```bash
cd terraform/main

# 1. 워크스페이스 선택
terraform workspace select <env>

# 2. 로컬 상태 파일을 원격으로 푸시
terraform state push errored.tfstate

# 3. 남은 리소스 삭제 재시도
terraform destroy -var-file="<env>.tfvars" -auto-approve

# 4. 성공 시 로컬 errored.tfstate 삭제
rm errored.tfstate
```

### Karpenter 리소스 수동 정리

스크립트가 Karpenter 리소스 삭제에 실패한 경우:

```bash
# kubeconfig 업데이트
aws eks update-kubeconfig --name <cluster-name> --region <region> --no-cli-pager

# Finalizer 강제 제거 후 삭제
kubectl get ec2nodeclasses -o name | xargs -I {} kubectl patch {} --type merge -p '{"metadata":{"finalizers":null}}'
kubectl get nodeclaims -o name | xargs -I {} kubectl patch {} --type merge -p '{"metadata":{"finalizers":null}}'
kubectl get nodepools -o name | xargs -I {} kubectl patch {} --type merge -p '{"metadata":{"finalizers":null}}'
```

