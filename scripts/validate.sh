#!/usr/bin/env bash
# =============================================================================
# validate.sh — Local Pre-Commit Validation & Linting Suite
# Checks Terraform formatting, syntax validation, and Ansible syntax
# Usage: ./scripts/validate.sh
# =============================================================================
set -euo pipefail

BOLD="\033[1m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}  Automated AWS Infrastructure — Validation Suite      ${RESET}"
echo -e "${BOLD}======================================================${RESET}"

ERRORS=0

# 1. Terraform Format Check
echo ""
echo -e "${YELLOW}[1/4] Checking Terraform code formatting...${RESET}"
if terraform fmt -check -recursive terraform/; then
  echo -e "  ${GREEN}✓ All Terraform files are properly formatted.${RESET}"
else
  echo -e "  ${RED}✗ Terraform formatting issues found! Run: make format${RESET}"
  ERRORS=$((ERRORS + 1))
fi

# 2. Terraform Root Validation
echo ""
echo -e "${YELLOW}[2/4] Validating Terraform root configuration...${RESET}"
(
  cd terraform
  terraform init -backend=false > /dev/null 2>&1 || true
  if terraform validate; then
    echo -e "  ${GREEN}✓ Root module is valid.${RESET}"
  else
    echo -e "  ${RED}✗ Root module validation failed.${RESET}"
    ERRORS=$((ERRORS + 1))
  fi
)

# 3. Environment Validations
echo ""
echo -e "${YELLOW}[3/4] Validating environments (dev & prod)...${RESET}"
for ENV in dev prod; do
  (
    cd "terraform/environments/${ENV}"
    terraform init -backend=false > /dev/null 2>&1 || true
    if terraform validate > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓ Environment [${ENV}] is valid.${RESET}"
    else
      echo -e "  ${RED}✗ Environment [${ENV}] validation failed.${RESET}"
      ERRORS=$((ERRORS + 1))
    fi
  )
done

# 4. Ansible Syntax Check (if available)
echo ""
echo -e "${YELLOW}[4/4] Checking Ansible playbooks syntax...${RESET}"
if command -v ansible-playbook &> /dev/null; then
  for PLAYBOOK in ansible/playbooks/*.yml; do
    if ansible-playbook "${PLAYBOOK}" --syntax-check > /dev/null 2>&1; then
      echo -e "  ${GREEN}✓ Playbook [${PLAYBOOK}] syntax OK.${RESET}"
    else
      echo -e "  ${RED}✗ Playbook [${PLAYBOOK}] syntax check failed.${RESET}"
      ERRORS=$((ERRORS + 1))
    fi
  done
else
  echo -e "  ${YELLOW}⚠ ansible-playbook not found locally. Skipping syntax check.${RESET}"
fi

echo ""
echo -e "${BOLD}======================================================${RESET}"
if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}✓ ALL VALIDATION CHECKS PASSED SUCCESSFULLY!${RESET}"
  exit 0
else
  echo -e "${RED}${BOLD}✗ VALIDATION FAILED WITH ${ERRORS} ISSUE(S).${RESET}"
  exit 1
fi
