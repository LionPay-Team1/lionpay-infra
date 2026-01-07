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

### 2. Terraform Apply
If infrastructure is missing or you want to ensure it's up to date:
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
