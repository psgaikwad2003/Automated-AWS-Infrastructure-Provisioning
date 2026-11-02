#!/bin/bash
# =============================================================================
# bootstrap.sh — Create S3 backend + DynamoDB lock table for Terraform state
# Usage: ./scripts/bootstrap.sh [bucket-name] [region]
# =============================================================================
set -euo pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
BUCKET_NAME="${1:-terraform-state-${ACCOUNT_ID}-us-east-1}"
REGION="${2:-us-east-1}"
DYNAMODB_TABLE="terraform-state-lock"

echo "========================================================"
echo "  Terraform Backend Bootstrap"
echo "========================================================"
echo "  Bucket:    $BUCKET_NAME"
echo "  Region:    $REGION"
echo "  DynamoDB:  $DYNAMODB_TABLE"
echo "========================================================"

# ---- S3 Bucket ----
echo ""
echo "[1/5] Creating S3 state bucket..."

if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null; then
  echo "  ✓ Bucket already exists: $BUCKET_NAME"
else
  if [[ "$REGION" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" 2>/dev/null
  else
    aws s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION" 2>/dev/null
  fi
  echo "  ✓ Bucket created: $BUCKET_NAME"
fi

# ---- Versioning ----
echo ""
echo "[2/5] Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled
echo "  ✓ Versioning enabled"

# ---- Encryption ----
echo ""
echo "[3/5] Enabling server-side encryption..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'
echo "  ✓ Encryption enabled (AES256)"

# ---- Block public access ----
echo ""
echo "[4/5] Blocking all public access..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "  ✓ Public access blocked"

# ---- DynamoDB Table ----
echo ""
echo "[5/5] Creating DynamoDB state lock table..."
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" 2>/dev/null; then
  echo "  ✓ DynamoDB table already exists: $DYNAMODB_TABLE"
else
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION" \
    --tags Key=Purpose,Value=TerraformStateLock >/dev/null
  echo "  ✓ DynamoDB table created: $DYNAMODB_TABLE"
fi

echo ""
echo "========================================================"
echo "  Bootstrap complete!"
echo "========================================================"
echo ""
echo "  Next steps:"
echo "  1. Update terraform/backend.tf with:"
echo "     bucket = \"$BUCKET_NAME\""
echo "  2. Update terraform/environments/dev/main.tf backend with the same bucket"
echo "  3. Update terraform/environments/prod/main.tf backend with the same bucket"
echo ""
echo "  Then run:"
echo "     make init ENVIRONMENT=dev"
echo "     make plan ENVIRONMENT=dev"
echo "     make apply ENVIRONMENT=dev"
echo ""

