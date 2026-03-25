#!/usr/bin/env bash
# Run integration tests against LocalStack Azure.
#
# Prerequisites:
#   - LocalStack Azure running: IMAGE_NAME=localstack/localstack-azure-alpha localstack start
#   - Terraform installed
#
# Usage:
#   ./scripts/integration-test.sh                    # run all
#   ./scripts/integration-test.sh az-virtual-network  # run one module

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
MODULES_DIR="$REPO_ROOT/Azure"

# Verify LocalStack is running
if ! curl -sf "https://localhost.localstack.cloud:4566/metadata/endpoints?api-version=2024-05-01" > /dev/null 2>&1; then
  echo "ERROR: LocalStack Azure is not running."
  echo "Start it with: IMAGE_NAME=localstack/localstack-azure-alpha localstack start"
  exit 1
fi

echo "LocalStack Azure is running."

# Determine which modules to test
if [ $# -gt 0 ]; then
  MODULES=("$@")
else
  MODULES=()
  for dir in "$MODULES_DIR"/*/tests/integration; do
    MOD=$(basename "$(dirname "$(dirname "$dir")")")
    MODULES+=("$MOD")
  done
fi

PASSED=0
FAILED=0
ERRORS=()

for MOD in "${MODULES[@]}"; do
  TEST_DIR="$MODULES_DIR/$MOD/tests/integration"
  if [ ! -d "$TEST_DIR" ]; then
    echo "SKIP: $MOD (no integration tests)"
    continue
  fi

  echo ""
  echo "=========================================="
  echo "TESTING: $MOD"
  echo "=========================================="

  cd "$TEST_DIR"

  # Init
  if ! terraform init -input=false > /dev/null 2>&1; then
    echo "FAIL: $MOD (terraform init failed)"
    FAILED=$((FAILED + 1))
    ERRORS+=("$MOD: init failed")
    continue
  fi

  # Apply
  if terraform apply -auto-approve -input=false 2>&1; then
    echo "PASS: $MOD (apply succeeded)"
    PASSED=$((PASSED + 1))
  else
    echo "FAIL: $MOD (apply failed)"
    FAILED=$((FAILED + 1))
    ERRORS+=("$MOD: apply failed")
  fi

  # Always destroy
  echo "Destroying $MOD resources..."
  terraform destroy -auto-approve -input=false > /dev/null 2>&1 || true

  # Clean up local state
  rm -rf .terraform terraform.tfstate* .terraform.lock.hcl
done

echo ""
echo "=========================================="
echo "RESULTS: $PASSED passed, $FAILED failed"
echo "=========================================="

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "Failures:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  exit 1
fi
