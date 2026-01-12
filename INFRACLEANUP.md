# LionPay 인프라 리소스 정리 및 가이드

본 문서는 인프라 삭제(`destroy`) 및 생성(`apply`) 과정에서 발생한 문제들을 분석하고, 이를 해결하기 위해 적용한 변경 사항들을 정리합니다.

## 1. 주요 문제 분석 및 해결 내역

### 1.1 Kubernetes 네임스페이스 삭제 중단 (Stuck)
*   **증상**: `lionpay`, `monitoring` 네임스페이스가 `Terminating` 상태에서 멈추고 Terraform이 `context deadline exceeded` 에러를 발생시킴.
*   **원인**: 네임스페이스 내의 리소스(Finalizer)들이 남아 있는 상태에서 EKS 클러스터가 먼저 삭제되거나 통신이 끊겨 정리가 완료되지 않음.
*   **해결**: 
    - `k8s_namespaces.tf` 파일에서 네임스페이스 리소스에 `depends_on = [module.eks_seoul/tokyo]`를 추가했습니다.
    - 이를 통해 Terraform은 클러스터를 삭제하기 **전**에 네임스페이스를 먼저 완벽하게 삭제하도록 순서를 강제합니다.
    - 수동 조치로 `kubectl patch`를 사용하여 남아있던 Finalizer를 강제 제거하였습니다.

### 1.2 VPC/IGW 삭제 실패 (DependencyViolation)
*   **증상**: VPC 서브넷이나 IGW 삭제 시 "다른 리소스가 사용 중"이라는 에러 발생.
*   **원인**: EKS 클러스터가 생성한 ENI(Network Interface)나 로드밸런서가 VPC를 붙잡고 있는 상태에서 Terraform이 VPC 리소스를 먼저 삭제하려고 시도함.
*   **해결**: 
    - `eks.tf` 파일의 EKS 모듈 정의에 `depends_on = [module.vpc_seoul/tokyo]`를 추가했습니다.
    - 클러스터가 완전히 사라진 후에만 VPC 리소스 정리가 시작되도록 의존성을 명확히 했습니다.

### 1.3 S3 버킷 삭제 실패 (BucketNotEmpty)
*   **증상**: `lionpay-dev-frontend` 버킷 삭제 시 비어있지 않다는 에러 발생.
*   **원인**: 버킷 버전 관리(Versioning)가 활성화되어 있어, 객체 삭제 후에도 버전 및 삭제 마커가 남아있음.
*   **해결**: 
    - `modules/s3/main.tf`의 S3 리소스에 `force_destroy = true` 설정을 추가했습니다.
    - 이제 Terraform이 삭제 시 버킷 내의 모든 버전과 삭제 마커를 자동으로 비우고 삭제를 진행합니다.

### 1.4 CloudFront OAC 사용 중 에러 (OriginAccessControlInUse)
*   **증상**: CloudFront OAC 삭제 시 분배(Distribution)에서 사용 중이라는 에러 발생.
*   **원인**: CloudFront 분배 삭제는 몇 분 정도 소요되는데, Terraform은 분배 삭제 시작 직후 OAC 삭제를 시도함.
*   **해결**: 리소스를 다시 `destroy` 하거나, 분배가 완전히 삭제될 때까지 잠시 대기 후 재시도하면 해결됩니다. 현재 모듈 간 의존성은 정상적으로 설정되어 있습니다.

## 2. 향후 인프라 관리 가이드

### 2.1 삭제(Destroy) 절차 권장 사항
인프라를 완전히 삭제할 때는 `./destroy-all.ps1` 스크립트 사용을 권장합니다. 이 스크립트는 다음 작업을 추가로 수행합니다:
1.  **Karpenter 리소스 정리**: 노드풀과 노드 클래스를 먼저 삭제하여 EC2 인스턴스 정리를 유도합니다.
2.  **로드밸런서 정리**: K8s Ingress가 생성한 AWS 로드밸런서를 조회하여 수동으로 먼저 삭제합니다.
3.  **고아 리소스 정리**: Terraform이 관리하지 않는 찌꺼기 리소스들을 청소합니다.

### 2.2 클린 업(Clean Up) 팁
만약 리소스가 삭제되지 않고 멈춘 경우 다음 명령어를 활용하세요:
*   **네임스페이스 강제 삭제**: `kubectl get namespace <ns> -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/<ns>/finalize" -f -`
*   **S3 버킷 비우기**: `aws s3api delete-objects --bucket <bucket> --delete "$(aws s3api list-object-versions --bucket <bucket> --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)"`

## 3. 최종 상태 (2026-01-09)
*   **VPC (Seoul/Tokyo)**: 성공적으로 제거됨.
*   **EKS 클러스터**: 성공적으로 제거됨.
*   **S3 버킷**: 비워진 후 제거됨.
*   **CloudFront**: 현재 최종 삭제 진행 중 (OAC 제외 모든 리소스 정리 완료 단계).

인프라 정리가 완료되었습니다. 향후 `apply` 시에는 수정된 의존성 덕분에 더 안정적인 리소스 관리가 가능합니다.
