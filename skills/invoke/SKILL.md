---
name: rust-lambda-invoke
description: >
  Invoke and test an AWS Lambda Rust function with a payload. Use when the user wants to test
  their function locally with Cargo Lambda or remotely against a deployed function with the
  AWS CLI.
---

# AWS Lambda Rust — Invoke & Test

Test the Lambda function with a payload.

## Context from $ARGUMENTS
- Function name
- Test payload (JSON)
- Target: local (Cargo Lambda watch mode) or remote (deployed function)

## Method 1: Remote invocation with Cargo Lambda

Test a deployed function:
```bash
cargo lambda invoke --remote \
  --data-ascii '{"command": "Hello world"}' \
  <function-name>
```

For a custom event (e.g. the Order example):
```bash
cargo lambda invoke --remote \
  --data-ascii '{"order_id": "12345", "amount": 199.99, "item": "Wireless Headphones"}' \
  <function-name>
```

## Method 2: Remote invocation with the AWS CLI

```bash
aws lambda invoke \
  --function-name <function-name> \
  --cli-binary-format raw-in-base64-out \
  --payload '{"order_id": "12345", "amount": 199.99, "item": "Wireless Headphones"}' \
  /tmp/out.txt
```

Then read the response:
```bash
cat /tmp/out.txt
```

**Note**: `--cli-binary-format raw-in-base64-out` is required for AWS CLI v2. To make it the default:
```bash
aws configure set cli-binary-format raw-in-base64-out
```

## Expected input format for the Order example

```json
{
    "order_id": "12345",
    "amount": 199.99,
    "item": "Wireless Headphones"
}
```

## Checking logs after invocation

Lambda automatically sends logs to Amazon CloudWatch. After invoking:
```bash
aws logs tail /aws/lambda/<function-name> --follow
```

Or filter for errors:
```bash
aws logs filter-log-events \
  --log-group-name /aws/lambda/<function-name> \
  --filter-pattern "ERROR"
```

## Remind the user
- A successful invocation of the Order receipt example should place a `.txt` file under `receipts/` in the configured S3 bucket
- If the function returns an error, check that environment variables (e.g. `RECEIPT_BUCKET`) are set and the execution role has the required permissions
