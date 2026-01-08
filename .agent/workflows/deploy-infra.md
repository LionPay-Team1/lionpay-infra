---
description: Deploy LionPay infrastructure, setup DSQL peering, and run database migrations
---

# Deploy LionPay Infrastructure

This workflow automates the full deployment process for LionPay infrastructure.

## Prerequisites

- AWS CLI installed and configured
- Terraform installed
- .NET SDK installed (for migrations)
- PowerShell installed

## Steps

### 1. Check Infrastructure Status
Search for existing EKS and DSQL clusters to determine if `terraform apply` is needed.
```bash
# Check EKS clusters
aws eks list-clusters --query "clusters" --no-cli-pager
# Check DSQL clusters (Seoul)
aws dsql list-clusters --region ap-northeast-2 --query "clusters[*].identifier" --no-cli-pager
```

### 2. Terraform Plan & Apply
Always run `plan` first. Skip `apply` if there are no infrastructure changes.

#### Plan
```powershell
./terraform/terraform.ps1 plan -Env dev
```

#### Apply
Run this ONLY if the plan output shows "Plan: X to add, Y to change, Z to destroy" and you confirm the changes. If it says "No changes. Your infrastructure matches the configuration.", **skip this step.**
// turbo
```powershell
./terraform/terraform.ps1 apply -Env dev -Auto
```


### 3. Check DSQL Peering Status
Check if the DSQL clusters are already peered.
```bash
# Get Cluster ARNs from Terraform
export CLUSTER1_ARN=$(terraform -chdir=terraform/main workspace select dev && terraform -chdir=terraform/main output -raw dsql_seoul_arn)
export CLUSTER2_ARN=$(terraform -chdir=terraform/main output -raw dsql_tokyo_arn)

# Check Multi-Region Properties
aws dsql get-cluster --identifier $(terraform -chdir=terraform/main output -raw dsql_seoul_id) --region ap-northeast-2 --query "cluster.multiRegionProperties" --no-cli-pager
```

### 4. DSQL Peering
If the clusters are not peered (multiRegionProperties is empty or incomplete):
// turbo
```powershell
./terraform/dsql-peering.ps1 -Cluster1Arn "$CLUSTER1_ARN" -Cluster2Arn "$CLUSTER2_ARN" -WitnessRegion "ap-northeast-3"
```

### 5. Get LionPay Path
Ask the user for the path to the `lionpay` repository if you don't already know it.
> [!IMPORTANT]
> Please provide the absolute path to your `lionpay` repository.

### 6. DSQL Schema Migration
Run the wallet database migrations.
```powershell
# Get DSQL Seoul Endpoint
export DSQL_ENDPOINT=$(terraform -chdir=terraform/main output -raw dsql_seoul_id).dsql.ap-northeast-2.on.aws

# Run migration script in lionpay directory
# Replace <LIONPAY_PATH> with the path provided by the user
cd <LIONPAY_PATH>
./migrate-walletdb.ps1 -endpoint "$DSQL_ENDPOINT" -region "ap-northeast-2"
```

### 7. Update CloudFront Secrets
Check if secrets in the `lionpay` repository are already up to date before setting them.

```bash
# Get Distribution IDs
export DIST_APP_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(Aliases.Items, 'lionpay.shop')].Id" --output text --no-cli-pager)
export DIST_MGMT_ID=$(aws cloudfront list-distributions --query "DistributionList.Items[?contains(Aliases.Items, 'admin.lionpay.shop')].Id" --output text --no-cli-pager)

cd <LIONPAY_PATH>
# Optional: Verify current secret values if possible, otherwise run set (it's safe to overwrite if needed)
gh secret set DIST_APP_ID_DEV --body "$DIST_APP_ID"
gh secret set DIST_MANAGEMENT_ID_DEV --body "$DIST_MGMT_ID"
```

### 8. Trigger Frontend Deployments
Only trigger if deployment is necessary (e.g., first time or after infrastructure changes).

```bash
cd <LIONPAY_PATH>
# Check if S3 bucket is empty (optional)
# aws s3 ls s3://lionpay-dev-frontend

gh workflow run deploy-app.yml
gh workflow run deploy-management.yml
```

> [!CAUTION]
> **Environment Variables**: Before triggering frontend deployments, ensure that the environment variables (e.g., `.env.production` or GitHub repository secrets) in the `lionpay` repository are correctly configured to match the newly deployed infrastructure (API endpoints, User Pool IDs, etc.).
