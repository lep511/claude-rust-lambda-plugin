---
name: rust-lambda-deploy
description: >
  Deploy a compiled Rust Lambda function to AWS. Use when the user wants to publish their
  function to AWS Lambda using Cargo Lambda, the AWS CLI, or AWS SAM. Covers creating new
  functions and updating existing ones.
---

# AWS Lambda Rust — Deploy

Deploy the compiled Rust binary to AWS Lambda.

## Context from $ARGUMENTS
- Deployment method: `cargo-lambda` (simplest), `aws-cli`, or `sam`
- Function name (if known)
- Existing IAM role ARN (if available)
- AWS account/region configuration status

## Prerequisites: Configure AWS credentials

Before deploying, ensure AWS credentials are configured:
```bash
aws configure
```

## Method 1: Deploy with Cargo Lambda (recommended for development)

Cargo Lambda's `deploy` subcommand automatically creates an execution role and the Lambda function:

```bash
cargo lambda deploy <function-name>
```

**To use an existing IAM execution role:**
```bash
cargo lambda deploy <function-name> --iam-role arn:aws:iam::111122223333:role/lambda-role
```

## Method 2: Deploy with the AWS CLI

### Step 1: Build the .zip package
```bash
cargo lambda build --release --output-format zip
```

### Step 2: Create the Lambda function

**Critical parameters:**
- `--runtime provided.al2023` — the OS-only runtime required for Rust compiled binaries and custom runtimes
- `--handler rust.handler` — the handler identifier for Rust functions
- `--zip-file fileb://target/lambda/<function-name>/bootstrap.zip`

```bash
aws lambda create-function \
  --function-name <function-name> \
  --runtime provided.al2023 \
  --role arn:aws:iam::111122223333:role/lambda-role \
  --handler rust.handler \
  --zip-file fileb://target/lambda/<function-name>/bootstrap.zip
```

**Update an existing function's code:**
```bash
aws lambda update-function-code \
  --function-name <function-name> \
  --zip-file fileb://target/lambda/<function-name>/bootstrap.zip
```

## Method 3: Deploy with AWS SAM CLI

### Step 1: Create a SAM template (`template.yaml`)

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: SAM template for Rust binaries
Resources:
  RustFunction:
    Type: AWS::Serverless::Function
    Properties:
      CodeUri: target/lambda/<function-name>/
      Handler: rust.handler
      Runtime: provided.al2023
Outputs:
  RustFunction:
    Description: "Lambda Function ARN"
    Value: !GetAtt RustFunction.Arn
```

For ARM64/Graviton2, add under `Properties`:
```yaml
Architectures:
  - arm64
```

### Step 2: Build
```bash
cargo lambda build --release
```

### Step 3: Deploy
```bash
sam deploy --guided
```

## IAM execution role requirements

The Lambda execution role must include the permissions your function uses. Common policies:
- Basic execution: `AWSLambdaBasicExecutionRole` (CloudWatch Logs)
- S3 write: add `s3:PutObject` on the target bucket
- DynamoDB: add relevant DynamoDB actions

After deploying, remind the user to:
1. Set required **environment variables** in the Lambda console or via CLI
2. Verify the **execution role** has all required IAM permissions
3. Run `/rust-lambda:invoke` to test the deployed function
