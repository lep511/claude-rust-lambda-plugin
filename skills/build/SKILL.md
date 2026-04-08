---
name: rust-lambda-build
description: >
  Build and compile a Rust AWS Lambda function using Cargo Lambda. Use when the user wants
  to compile their Rust Lambda project, target ARM64/Graviton2, or produce a .zip deployment
  package. Works on macOS, Windows, and Linux.
---

# AWS Lambda Rust — Build

Compile the Rust Lambda function using Cargo Lambda.

## Context from $ARGUMENTS
- Target architecture: `x86_64` (default) or `arm64` (AWS Graviton2)
- Output format: binary (default) or `.zip` (needed for AWS CLI / SAM deployment)

## Step 1: Ensure Cargo Lambda is installed

```bash
cargo lambda --version
```

If not found, install it:
```bash
cargo install cargo-lambda
```

## Step 2: Build the function

**Standard release build (x86_64):**
```bash
cargo lambda build --release
```

**For AWS Graviton2 (ARM64) — recommended for better price/performance:**
```bash
cargo lambda build --release --arm64
```

**Build a .zip deployment package (required for AWS CLI or SAM deployment):**
```bash
cargo lambda build --release --output-format zip
```

**Build .zip for ARM64:**
```bash
cargo lambda build --release --arm64 --output-format zip
```

## Step 3: Locate the output

After a successful build:
- Binary: `target/lambda/<function-name>/bootstrap`
- Zip package: `target/lambda/<function-name>/bootstrap.zip`

The compiled binary is named `bootstrap` — this is the required executable name for Lambda custom runtimes (`provided.al2023`).

## Important notes
- Rust Lambda functions use the **`provided.al2023`** OS-only runtime (not a managed runtime like `python3.12` or `nodejs20.x`)
- The entire function compiles into a **single executable** containing your code and all dependencies — no separate layers needed
- Do NOT use Lambda layers for Rust dependencies — include everything in the deployment package
- After a successful build, run `/rust-lambda:deploy` or `/rust-lambda:invoke` to test locally

## Troubleshooting common build errors
- **Missing cross-compilation toolchain**: On macOS/Windows building for Linux, Cargo Lambda handles cross-compilation automatically via Docker or Zig. Ensure Docker is running or Zig is installed.
- **Dependency version conflicts**: Run `cargo update` and retry.
- **`edition = "2024"` errors**: Ensure you're using a recent Rust toolchain (`rustup update stable`).
