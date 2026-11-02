#!/bin/bash
# =============================================================================
# deploy.sh — Full deployment automation script
# Usage: ./scripts/deploy.sh [dev|prod]
# =============================================================================
set -euo pipefail

ENVIRONMENT="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TF_DIR="$ROOT_DIR/terraform/environments/$ENVIRONMENT"

# Validate environment
if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
  echo "ERROR: Environment must be 'dev' or 'prod'"
  echo "Usage: $0 [dev|prod]"
  exit 1
fi

echo "========================================================"
echo "  AWS Infrastructure Deployment"
echo "  Environment: $ENVIRONMENT"
echo "========================================================"

# ---- Check prerequisites ----
echo ""
echo "[*] Checking prerequisites..."
for cmd in terraform aws ansible; do
  if command -v "$cmd" &>/dev/null; then
    echo "  ✓ $cmd found: $(${cmd} --version 2>&1 | head -1)"
  else
    echo "  ✗ $cmd not found — please install it"
    exit 1
  fi
done

# ---- Verify AWS credentials ----
echo ""
echo "[*] Verifying AWS credentials..."
CALLER=$(aws sts get-caller-identity --output json 2>/dev/null) || {
  echo "  ✗ AWS credentials not configured. Run: aws configure"
  exit 1
}
echo "  ✓ AWS Account: $(echo $CALLER | python3 -c 'import sys,json; print(json.load(sys.stdin)["Account"])')"
echo "  ✓ ARN:         $(echo $CALLER | python3 -c 'import sys,json; print(json.load(sys.stdin)["Arn"])')"

# ---- Verify tfvars ----
if [[ ! -f "$TF_DIR/terraform.tfvars" ]]; then
  echo ""
  echo "ERROR: $TF_DIR/terraform.tfvars not found"
  echo "Copy and edit the example: cp terraform/terraform.tfvars.example $TF_DIR/terraform.tfvars"
  exit 1
fi

# ---- Terraform Init ----
echo ""
echo "[1/4] Terraform Init ($ENVIRONMENT)..."
cd "$TF_DIR"
terraform init -input=false
echo "  ✓ Init complete"

# ---- Terraform Validate ----
echo ""
echo "[2/4] Terraform Validate..."
terraform validate
echo "  ✓ Validation passed"

# ---- Terraform Plan ----
echo ""
echo "[3/4] Terraform Plan..."
terraform plan \
  -var-file=terraform.tfvars \
  -out=tfplan \
  -detailed-exitcode 2>&1
PLAN_EXIT=$?

if [[ $PLAN_EXIT -eq 0 ]]; then
  echo "  ✓ No changes to apply"
  exit 0
elif [[ $PLAN_EXIT -eq 1 ]]; then
  echo "  ✗ Terraform plan failed"
  exit 1
fi

# ---- Prod confirmation ----
if [[ "$ENVIRONMENT" == "prod" ]]; then
  echo ""
  echo "⚠️  You are deploying to PRODUCTION."
  read -r -p "  Type 'yes' to continue: " CONFIRM
  if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# ---- Terraform Apply ----
echo ""
echo "[4/4] Terraform Apply..."
terraform apply tfplan
echo "  ✓ Apply complete"

# ---- Outputs ----
echo ""
echo "========================================================"
echo "  Deployment Complete — Outputs"
echo "========================================================"
terraform output -no-color 2>/dev/null || true

echo ""
echo "  Run Ansible to configure servers:"
echo "  make ansible-deploy"
echo ""

