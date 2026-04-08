#!/bin/bash
# Hook: validate-before-deploy
# Runs before every `cargo lambda deploy` to catch common issues early.

set -e

echo "=== rust-lambda plugin: Pre-deploy validation ==="

ERRORS=0

# 1. Check Cargo.toml exists
if [ ! -f "Cargo.toml" ]; then
  echo "[ERROR] Cargo.toml not found. Are you in the project root directory?"
  ERRORS=$((ERRORS + 1))
fi

# 2. Check AWS credentials are configured
if ! aws sts get-caller-identity &>/dev/null; then
  echo "[ERROR] AWS credentials not configured or invalid. Run: aws configure"
  ERRORS=$((ERRORS + 1))
else
  echo "[OK] AWS credentials valid."
fi

# 3. Check cargo-lambda is installed
if ! command -v cargo-lambda &>/dev/null && ! cargo lambda --version &>/dev/null 2>&1; then
  echo "[WARN] cargo-lambda not found. Install with: cargo install cargo-lambda"
  ERRORS=$((ERRORS + 1))
else
  echo "[OK] cargo-lambda is installed."
fi

# 4. Warn if no release build exists
if [ ! -d "target/lambda" ]; then
  echo "[WARN] No build output found in target/lambda/. Run: cargo lambda build --release"
fi

# 5. Warn about hard-coded resource names (basic heuristic)
if grep -r "bucket_name\s*=\s*\"" src/ 2>/dev/null | grep -v "env::var" | grep -q .; then
  echo "[WARN] Possible hard-coded bucket name detected. Use env::var() for resource names."
fi

echo "==================================================="

if [ "$ERRORS" -gt 0 ]; then
  echo "[BLOCKED] Fix $ERRORS error(s) before deploying."
  exit 1
fi

echo "[OK] Pre-deploy validation passed."
exit 0
