# 트러블슈팅 및 이슈 해결 로그 (Troubleshooting Log)

## 1. Karpenter Pod CrashLoopBackOff (IMDS 오류)

**Component**: `Karpenter`, `EKS`, `IAM`

### 현상 (Symptom)

Karpenter 배포 후 Pod 상태가 `CrashLoopBackOff`로 지속되며, 로그에 IMDS(Instance Metadata Service) 접근 실패 오류 발생.

```plaintext
panic: operation error ec2imds: GetRegion, canceled, context deadline exceeded
```

### 원인 (Cause)

Karpenter가 AWS 리소스(EC2, SQS 등)를 제어하기 위한 권한을 획득하지 못함.

1. **Pod Identity 누락**: Helm Chart 설정과 실제 Pod Identity Association 연결 미비.
2. **Namespace 불일치 (Core Cause)**: Terraform 모듈(`terraform-aws-modules/eks/aws//modules/karpenter`)의 기본 Pod Identity 생성 위치는 `kube-system` 네임스페이스였으나, Karpenter는 `karpenter` 네임스페이스에 배포됨. 이로 인해 Pod에 IAM Role 자격 증명이 주입되지 않음.

### 해결 (Resolution)

`terraform/modules/karpenter/main.tf` 파일의 `module "karpenter"` 블록에 `namespace` 파라미터 명시.

```hcl
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  # ...
  
  # Pod Identity Association이 생성될 네임스페이스를 Helm 릴리즈와 일치시킴
  namespace = local.namespace  # "karpenter"
}
```

---

## 2. 노드 프로비저닝 실패 (Subnet Not Found)

**Component**: `Karpenter`, `Terraform`

### 현상 (Symptom)

테스트 워크로드를 배포했으나 Pod가 `Pending` 상태로 유지됨. Karpenter 로그에 서브넷을 찾을 수 없다는 에러 발생.

```
"error":"no subnets found"
```

### 원인 (Cause)

`EC2NodeClass` 설정을 수동으로 (`kubectl apply -f dev-karpenter.yaml`) 적용함.
YAML 파일 내의 `${cluster_name}`과 같은 Terraform 템플릿 변수가 치환되지 않은 상태로 클러스터에 적용되어, 실제 태그 값(`lionpay-dev-seoul`)과 매칭되지 않음.

### 해결 (Resolution)

1. **자동화**: `apply.ps1` 스크립트를 통해 Terraform이 변수를 치환하여 생성한 매니페스트 파일(`.terraform/karpenter_*.yaml`)을 자동으로 적용하도록 구성됨.
2. **수동 적용 시**: `main/config/dev-karpenter.yaml` 원본 대신, Terraform apply 후 생성되는 `.terraform/` 디렉토리 내의 파일을 사용해야 함.

```powershell
# 올바른 수동 적용 방법
kubectl apply -f terraform/main/.terraform/karpenter_seoul.yaml
```

---

## 3. 인스턴스 타입 최적화 (t4g.xlarge vs t4g.medium)

**Component**: `Karpenter`, `Cost Optimization`

### 현상 (Symptom)

Karpenter가 예상보다 큰 `t4g.xlarge` 인스턴스를 프로비저닝함.

### 원인 (Cause)

`NodePool` 설정에서 CPU 요구사항 범위가 넓게 잡혀 있었음. Karpenter는 Pod의 리소스 요청량과 가용 인스턴스 중 비용 효율성을 고려해 선택하는데, 이 과정에서 더 큰 인스턴스가 선택됨.

### 해결 (Resolution)

`dev-karpenter.yaml`의 `requirements`를 수정하여 원하는 인스턴스 크기만 허용하도록 제한.

```yaml
- key: "karpenter.k8s.aws/instance-cpu"
  operator: In
  values: ["2"]  # 2 vCPU (medium, large 등)만 허용
```

---

## 4. 운영 편의성 개선

**Component**: `Operations`

### 내용

1. **스크립트 Auto Approve 옵션 추가**: 반복적인 배포/삭제 작업의 효율성을 위해 `apply.ps1` 및 `destroy.ps1`에 `-Auto` 옵션 추가.

   ```powershell
   ./apply.ps1 -Env dev -Auto
   ```

2. **EC2 Initializing 상태 관련**:
   - **관찰**: Karpenter로 생성된 노드에서 Pod는 정상 실행 중이나, AWS 콘솔에서는 EC2 상태가 여전히 `Initializing`으로 표시됨.
   - **분석**: Bottlerocket 등 최적화된 OS는 부팅이 매우 빨라 AWS의 상태 검사(Status Check)가 완료되기 전에 이미 K8s 노드로 Join하여 작동함. 이는 정상적인 동작임.

---

## 5. 리소스 제한 설정 (Resource Limits)

**Component**: `Kubernetes`, `Stability`

### 현상 (Symptom)

IDE 또는 배포 도구에서 `No resource limits specified for this container` 경고 발생. 리소스 제한 미설정 시 "Noisy Neighbor" 문제로 타 프로세스 장애 유발 가능.

### 해결 (Resolution)

Pod 정의 시 `limits`를 명시적으로 설정. `requests`와 `limits`를 동일하게 설정(Guaranteed QoS)하는 것이 권장됨.

```yaml
        resources:
          requests:
            cpu: "0.5"
            memory: "1Gi"
          limits:
            cpu: "0.5"
            memory: "1Gi" # limits를 명시하여 리소스 점유 독점 방지
```

---

## 6. EKS Extended Support 비용 방지

**Component**: `EKS`, `Cost Optimization`

### 현상 (Symptom)

Terraform State(`support_type`) 확인 결과, EKS 클러스터가 `EXTENDED` Support 모드로 설정되어 시간당 추가 비용 발생.

### 원인 (Cause)

Terraform EKS 모듈이 `upgrade_policy` 미설정 시, 혹은 Kubernetes 버전 정책에 따라 자동으로 Extended Support가 활성화될 수 있음.

### 해결 (Resolution)

`terraform/modules/eks/main.tf`에 `upgrade_policy`를 추가하여 명시적으로 `STANDARD` Support만 사용하도록 강제.

```hcl
  # Use Standard Support (no additional cost) instead of Extended Support
  upgrade_policy = {
    support_type = "STANDARD"
  }
```

---

## 7. Karpenter Helm Chart ECR 인증 오류

**Component**: `Helm`, `ECR`

### 현상 (Symptom)

`terraform apply` 시 Karpenter Helm Chart 설치 단계에서 `public.ecr.aws` 로그인 실패 오류 발생.

```plaintext
Error: could not login to OCI registry "public.ecr.aws": error storing credentials - err: exit status 1
```

### 원인 (Cause)

Windows 환경에서 Terraform이 `public.ecr.aws` 인증을 위해 자격 증명 헬퍼(wincred)를 사용하는 과정에서 오류 발생. Public ECR 이미지는 인증 불필요.

### 해결 (Resolution)

1. `modules/karpenter/main.tf`의 `helm_release` 리소스에서 `repository_username`, `repository_password` 제거.
2. `terraform/main/main.tf`에서 사용하지 않는 `aws_ecrpublic_authorization_token` 데이터 소스 제거.

---

## 8. EKS Node Group 아키텍처 불일치

**Component**: `EKS`, `Compute`

### 현상 (Symptom)

Karpenter용 EKS Managed Node Group 생성 실패.

```plaintext
InvalidParameterException: [t4g.medium] is not a valid instance type for requested amiType BOTTLEROCKET_x86_64
```

### 원인 (Cause)

`t4g` 시리즈는 ARM64 아키텍처를 사용하지만, 노드 그룹 설정(`ami_type`)이 `BOTTLEROCKET_x86_64`로 되어 있었음.

### 해결 (Resolution)

`modules/eks/main.tf`에서 Karpenter 노드 그룹의 `ami_type`을 `BOTTLEROCKET_ARM_64`로 변경.

---

## 9. IAM Role 및 Access Entry 충돌

**Component**: `IAM`, `EKS`

### 현상 (Symptom)

1. **IAM Role 충돌**: `EntityAlreadyExists`
2. **Access Entry 충돌**: `ResourceInUseException`

### 원인 (Cause)

`modules/eks`와 `modules/karpenter` 두 모듈 모두에서 Karpenter 노드용 IAM Role과 EKS Access Entry를 생성하려고 시도하여 리소스 중복 발생.

### 해결 (Resolution)

Karpenter 모듈(`modules/karpenter/main.tf`)이 리소스를 생성하지 않고, EKS 모듈에서 생성한 리소스를 사용하도록 설정 변경.

- `create_node_iam_role = false`
- `create_access_entry = false`
- `node_iam_role_arn` 변수 주입

---

## 10. Karpenter Helm Values YAML 문법 오류

**Component**: `Helm`, `YAML`

### 현상 (Symptom)

`terraform apply` 시 YAML 파싱 에러 (`did not find expected '-' indicator`) 발생.

### 원인 (Cause)

`helm_release`의 `values` 블록 내 heredoc(`<<-EOT`) 사용 시 들여쓰기(Indentation)가 잘못되어 `webhook` 설정이 `tolerations` 리스트 내부에 포함됨.

### 해결 (Resolution)

`webhook` 블록의 들여쓰기를 수정하여 최상위 레벨로 이동.

---

## 11. ECR 삭제 실패 (RepositoryNotEmpty)

**Component**: `ECR`, `Terraform`

### 현상 (Symptom)

`terraform destroy` 시 ECR 리포지토리에 이미지가 남아있어 삭제 실패.

### 해결 (Resolution)

1. `terraform/ecr/variables.tf`에서 `force_delete` 변수 기본값을 `true`로 변경.
2. `terraform apply`로 설정을 먼저 업데이트한 후 `terraform destroy` 실행.

---

## 12. S3 State Bucket 삭제 실패 (BucketNotEmpty)

**Component**: `S3`, `Terraform`

### 현상 (Symptom)

`terraform destroy` 시 Terraform State를 저장하는 S3 버킷 삭제 실패 및 `prevent_destroy`로 인한 삭제 계획 생성 실패.

### 해결 (Resolution)

1. **Lifecycle 해제**: `lifecycle { prevent_destroy = true }` 블록 제거.
2. **Force Destroy 활성화**: `aws_s3_bucket` 리소스에 `force_destroy = true` 추가.
3. `terraform apply` 실행 후 `terraform destroy` 진행.

---

## 13. 최종 구성 요약

**Component**: `Architecture`

- **배포 방식**: Terraform (`apply.ps1`, `destroy.ps1`) 스크립트를 통한 환경별(`dev`, `prod`) 원클릭 관리.
- **상태 관리**: S3 Backend + DynamoDB Locking 사용. Workspace를 활용하여 환경별 State 격리.
- **Karpenter**:
  - ARM64 Spot 인스턴스 활용 최적화.
  - Helm Chart 설치 시 OCI 인증 우회 및 EKS Pod Identity 활용.
- **EKS**: Standard Support 강제하여 비용 절감.

---

## 14. Terraform Cycle Error (EKS ↔ Karpenter ↔ Helm)

**Component**: `Terraform`, `Structure`

### 현상 (Symptom)

`terraform validate` 시 순환 종속성(Cycle) 오류 발생.

```
Error: Cycle: module.eks_seoul.helm_release.karpenter, module.eks_seoul ...
```

### 원인 (Cause)

EKS 모듈이 Helm Release를 포함하고, Helm Provider는 EKS 클러스터 정보에 의존함.

### 해결 (Resolution)

Karpenter 및 Metrics Server 구성을 **EKS 모듈 외부로 분리**하여 의존성 방향을 단방향(`EKS 모듈 -> Provider -> Karpenter 모듈`)으로 정리.

---

## 15. DSQL 삭제 시 Pending Delete 문제 (삭제 의존성 고착)

**Component**: `DSQL`, `Terraform`

### 현상 (Symptom)

`terraform destroy` 실행 시 도쿄 리전 DSQL이 먼저 삭제되고 서울 리전 DSQL은 `Pending Delete` 상태로 무한 대기.

### 원인 (Cause)

Terraform 설정 상 도쿄 모듈이 서울 모듈에 의존(`depends_on`)하여 삭제 순서가 `도쿄 -> 서울`로 진행됨. 멀티 리전 클러스터 해제 시 교착 상태 발생.

### 해결 (Resolution)

`depends_on = [module.dsql_seoul]` 라인을 제거하여 병렬 삭제되도록 수정.
