#!/bin/bash
# =============================================================================
# destroy.sh — Tear down AWS infrastructure for a given environment
# Usage: ./scripts/destroy.sh [dev|prod]
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
echo "  ⚠️  Infrastructure DESTROY"
echo "  Environment: $ENVIRONMENT"
echo "========================================================"
echo ""
echo "  This will PERMANENTLY DESTROY all resources in: $ENVIRONMENT"
echo "  There is no undo!"
echo ""

# Safety confirmation
read -r -p "  Type the environment name '$ENVIRONMENT' to confirm: " CONFIRM1
if [[ "$CONFIRM1" != "$ENVIRONMENT" ]]; then
  echo "Confirmation mismatch. Aborted."
  exit 0
fi

if [[ "$ENVIRONMENT" == "prod" ]]; then
  echo ""
  echo "  ⛔  PRODUCTION ENVIRONMENT — Extra confirmation required"
  read -r -p "  Type 'destroy production' to proceed: " CONFIRM2
  if [[ "$CONFIRM2" != "destroy production" ]]; then
    echo "Confirmation mismatch. Aborted."
    exit 0
  fi
fi

echo ""
echo "[*] Verifying AWS credentials..."
aws sts get-caller-identity --output table || {
  echo "  ✗ AWS credentials not configured."
  exit 1
}

cd "$TF_DIR"

echo ""
echo "[1/2] Terraform Init..."
terraform init -input=false
echo "  ✓ Init complete"

echo ""
echo "[2/2] Terraform Destroy..."
terraform destroy \
  -var-file=terraform.tfvars \
  -auto-approve

echo ""
echo "========================================================"
echo "  ✓ Destroy complete for environment: $ENVIRONMENT"
echo "========================================================"

