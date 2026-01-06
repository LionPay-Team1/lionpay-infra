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
