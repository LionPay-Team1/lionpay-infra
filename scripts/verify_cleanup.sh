#!/bin/bash

REGIONS=("ap-northeast-2" "ap-northeast-1")
echo "========================================================"
echo "Verifying Resource Cleanup in Regions: ${REGIONS[*]}"
echo "========================================================"

for REGION in "${REGIONS[@]}"; do
    echo ""
    echo "--------------------------------------------------------"
    echo "Checking Region: $REGION"
    echo "--------------------------------------------------------"

    # 1. EKS Clusters
    echo "1. EKS Clusters:"
    CLUSTERS=$(aws eks list-clusters --region $REGION --query "clusters[]" --output text)
    if [ -z "$CLUSTERS" ] || [ "$CLUSTERS" == "None" ]; then
        echo "   [OK] No clusters found."
    else
        echo "   [WARNING] Found clusters: $CLUSTERS"
    fi

    # 2. VPCs (tagged with lionpay or dev)
    echo "2. VPCs (Project related):"
    VPCS=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Project,Values=lionpay" "Name=tag:Environment,Values=dev" --query "Vpcs[].VpcId" --output text)
    if [ -z "$VPCS" ] || [ "$VPCS" == "None" ]; then
        echo "   [OK] No project VPCs found."
    else
        echo "   [WARNING] Found VPCs: $VPCS"
    fi

    # 3. EC2 Instances (Running or Pending)
    echo "3. EC2 Instances (Active):"
    INSTANCES=$(aws ec2 describe-instances --region $REGION --filters "Name=instance-state-name,Values=running,pending" --query "Reservations[].Instances[].InstanceId" --output text)
    if [ -z "$INSTANCES" ] || [ "$INSTANCES" == "None" ]; then
        echo "   [OK] No active instances found."
    else
        echo "   [WARNING] Found active instances: $INSTANCES"
    fi

    # 4. Load Balancers
    echo "4. Load Balancers (ELBv2):"
    LBS=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[].LoadBalancerArn" --output text)
    if [ -z "$LBS" ] || [ "$LBS" == "None" ]; then
        echo "   [OK] No Load Balancers found."
    else
        # Filter for project related if many exist, but for now list all to be safe or just count
        COUNT=$(echo $LBS | wc -w)
        # Simple check for lionpay in ARN
        LION_LBS=$(echo "$LBS" | grep "lionpay")
        if [ ! -z "$LION_LBS" ]; then
             echo "   [WARNING] Found 'lionpay' Load Balancers!"
        else
             echo "   [INFO] Found $COUNT Load Balancers (likely unrelated)."
        fi
    fi

    # 5. DynamoDB Tables
    echo "5. DynamoDB Tables:"
    TABLES=$(aws dynamodb list-tables --region $REGION --query "TableNames[]" --output text)
    if [ -z "$TABLES" ] || [ "$TABLES" == "None" ]; then
        echo "   [OK] No tables found."
    else
        LION_TABLES=$(echo "$TABLES" | grep "lionpay")
        if [ -z "$LION_TABLES" ]; then
             echo "   [OK] No 'lionpay' tables found."
        else
             echo "   [WARNING] Found tables: $LION_TABLES"
        fi
    fi

    # 6. DSQL Clusters
    echo "6. DSQL Clusters:"
    # aws dsql list-clusters returns json list
    DSQLS=$(aws dsql list-clusters --region $REGION --query "clusters[].identifier" --output text 2>/dev/null)
    if [ -z "$DSQLS" ] || [ "$DSQLS" == "None" ]; then
        echo "   [OK] No DSQL clusters found."
    else
        echo "   [WARNING] Found DSQL clusters: $DSQLS"
    fi
done

echo ""
echo "--------------------------------------------------------"
echo "Checking Global Resources"
echo "--------------------------------------------------------"

# 7. S3 Buckets
echo "7. S3 Buckets (lionpay-dev*):"
BUCKETS=$(aws s3api list-buckets --query "Buckets[?contains(Name, 'lionpay-dev')].Name" --output text)
if [ -z "$BUCKETS" ] || [ "$BUCKETS" == "None" ]; then
    echo "   [OK] No project buckets found."
else
    echo "   [WARNING] Found buckets: $BUCKETS"
fi

# 8. ECR Repositories
echo "8. ECR Repositories:"
# ECR is regional but often used in one primary region. Checking both just in case or primary (Seoul).
ECR_REPOS=$(aws ecr describe-repositories --region ap-northeast-2 --query "repositories[?contains(repositoryName, 'lionpay')].repositoryName" --output text 2>/dev/null)
if [ -z "$ECR_REPOS" ] || [ "$ECR_REPOS" == "None" ]; then
    echo "   [OK] No project ECR repositories found in Seoul."
else
    echo "   [WARNING] Found ECR repos in Seoul: $ECR_REPOS"
fi
