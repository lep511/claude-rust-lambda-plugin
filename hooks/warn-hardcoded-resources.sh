#!/bin/bash
# Hook: warn-hardcoded-resources
# Scans source code for common anti-patterns before building.

echo "=== rust-lambda plugin: Code quality scan ==="

WARNINGS=0

# Check for unwrap() on env::var (should use map_err instead)
if grep -rn "env::var.*\.unwrap()" src/ 2>/dev/null | grep -q .; then
  echo "[WARN] Found env::var().unwrap() — prefer .map_err(|_| \"VAR not set\")? for better error messages:"
  grep -rn "env::var.*\.unwrap()" src/ 2>/dev/null || true
  WARNINGS=$((WARNINGS + 1))
fi

# Check for recursive lambda invocations (very basic heuristic)
if grep -rn "lambda.*invoke\|InvokeFunction" src/ 2>/dev/null | grep -q .; then
  echo "[WARN] Possible recursive Lambda invocation detected. Ensure the function does not invoke itself."
  WARNINGS=$((WARNINGS + 1))
fi

# Check that provided.al2023 is not accidentally overridden by a template
if [ -f "template.yaml" ] || [ -f "template.yml" ]; then
  if grep -q "runtime:" template.yaml template.yml 2>/dev/null; then
    if ! grep -q "provided.al2023" template.yaml template.yml 2>/dev/null; then
      echo "[WARN] SAM template may be using a managed runtime. Rust requires: Runtime: provided.al2023"
      WARNINGS=$((WARNINGS + 1))
    else
      echo "[OK] SAM template uses provided.al2023."
    fi
  fi
fi

echo "============================================="

if [ "$WARNINGS" -gt 0 ]; then
  echo "[INFO] $WARNINGS warning(s) found. Build will continue."
fi

exit 0
