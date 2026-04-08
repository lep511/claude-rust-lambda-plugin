# rust-lambda — Claude Code Plugin

Develop, build, and deploy AWS Lambda functions written in Rust using the official
[AWS Lambda Runtime for Rust](https://github.com/aws/aws-lambda-rust-runtime) and
[Cargo Lambda](https://www.cargo-lambda.info/).

All guidance is based on official [AWS Lambda Rust documentation](https://docs.aws.amazon.com/lambda/latest/dg/lambda-rust.html).

---

## Skills

| Skill | Command | Description |
|---|---|---|
| Setup | `/rust-lambda:setup` | Initialize a new Rust Lambda project with Cargo Lambda |
| New handler | `/rust-lambda:new-handler` | Scaffold a handler with the correct signature and patterns |
| Build | `/rust-lambda:build` | Compile with `cargo lambda build` (x86_64 or ARM64) |
| Deploy | `/rust-lambda:deploy` | Deploy via Cargo Lambda, AWS CLI, or AWS SAM |
| Invoke | `/rust-lambda:invoke` | Test the function with a JSON payload |
| HTTP handler | `/rust-lambda:add-http` | Add API Gateway / Function URL HTTP handling |
| S3 integration | `/rust-lambda:add-s3` | Integrate the AWS SDK for S3 |
| Review | `/rust-lambda:review-handler` | Review handler code for AWS best practices |

---

## Hooks

| Hook | Trigger | Purpose |
|---|---|---|
| `validate-before-deploy` | Before `cargo lambda deploy` | Checks AWS credentials, cargo-lambda install, warns on anti-patterns |
| `warn-no-env-vars` | Before `cargo lambda build` | Scans for `unwrap()` on env vars, recursive invocations, wrong runtime in SAM templates |

---

## Quick start

```bash
# Install the plugin (from the plugin directory)
claude --plugin-dir ./rust-lambda-plugin

# Initialize a new project
/rust-lambda:setup my-order-processor

# Scaffold a handler that processes orders and writes to S3
/rust-lambda:new-handler process order events and upload receipts to S3

# Build for release
/rust-lambda:build

# Deploy
/rust-lambda:deploy

# Test with a payload
/rust-lambda:invoke my-order-processor '{"order_id":"123","amount":99.99,"item":"Book"}'
```

---

## Key facts about Rust on Lambda

- Uses the **`provided.al2023`** OS-only runtime — not a managed runtime
- The `lambda_runtime` crate is **not** a managed runtime; it's a Cargo crate
- Rust compiles to a **single binary** — never use Lambda Layers for dependencies
- Deploy the binary as `bootstrap` inside a `.zip` file

---

## References

- [AWS Lambda Rust handler docs](https://docs.aws.amazon.com/lambda/latest/dg/rust-handler.html)
- [Deploy Rust Lambda with .zip](https://docs.aws.amazon.com/lambda/latest/dg/rust-package.html)
- [AWS Lambda Runtime for Rust (GitHub)](https://github.com/aws/aws-lambda-rust-runtime)
- [Cargo Lambda docs](https://www.cargo-lambda.info/)
- [aws_lambda_events crate](https://crates.io/crates/aws_lambda_events)
