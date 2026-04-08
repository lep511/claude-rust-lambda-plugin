---
name: review-handler
description: >
  Review a Rust Lambda handler for AWS best practices, correctness, and performance.
  Use when the user wants feedback on their handler code, wants to check compliance with
  AWS guidelines, or is preparing to deploy and wants a pre-flight check.
---

# AWS Lambda Rust — Handler Review

Review the provided Rust Lambda handler code against AWS official best practices.

## Input
The user should provide their handler code in $ARGUMENTS or paste it in the conversation.
If no code is provided, ask the user to share their `main.rs` or handler file.

## Review checklist

Evaluate the code against each of the following categories. For each issue found, show the
problematic code and suggest the corrected version.

### 1. Handler structure
- [ ] Uses `async fn` for the handler
- [ ] Handler is registered with `service_fn` inside `main()`
- [ ] `#[tokio::main]` macro is present on `main()`
- [ ] Entry point calls `run(service_fn(function_handler)).await`
- [ ] Handler signature matches: `async fn name(event: LambdaEvent<T>) -> Result<U, Error>`
- [ ] Output type `U` implements `serde::Serialize`

### 2. Separation of concerns
- [ ] Handler function contains only orchestration logic — business logic is in helper functions
- [ ] Helper functions are independently unit-testable

### 3. SDK client initialization
- [ ] AWS SDK clients (S3, DynamoDB, etc.) are initialized **outside** the handler for shared state
- [ ] Clients are NOT re-initialized on every invocation (performance anti-pattern)
- [ ] If shared state is used, the closure captures the client correctly with `move`

### 4. Environment variables
- [ ] All resource names (bucket names, table names, queue URLs) come from `env::var()`
- [ ] No hard-coded AWS resource ARNs or names
- [ ] `env::var()` errors are handled gracefully (not unwrapped without a message)

### 5. Error handling
- [ ] No bare `.unwrap()` on fallible operations in production paths
- [ ] The `?` operator is used to propagate errors
- [ ] Errors return `Err(Error)` — they will be logged to CloudWatch automatically

### 6. Dependencies (Cargo.toml)
- [ ] Only necessary SDK crates are imported (minimize package size)
- [ ] No unused dependencies
- [ ] Layers are NOT used for Rust dependencies (anti-pattern — include everything in the binary)

### 7. Safety and idempotency
- [ ] No recursive Lambda invocations (function invoking itself)
- [ ] No use of non-documented internal Lambda APIs
- [ ] Function handles duplicate events correctly (idempotent behavior)
- [ ] No sensitive user data stored in the execution environment between invocations

### 8. Logging
- [ ] Logging uses `println!` (basic) or `tracing` crate (recommended for structured logs)
- [ ] If using `tracing`: subscriber is initialized in `main()` before `run()`
- [ ] Log levels are appropriate (`info` for normal flow, `error` for failures)
- [ ] ANSI color codes are disabled for CloudWatch: `.with_ansi(false)`
- [ ] Timestamps are disabled (CloudWatch adds ingestion time): `.without_time()`

### 9. HTTP handlers (if applicable)
- [ ] Uses `lambda_http` crate for unified HTTP support (preferred over manual `ApiGatewayProxyResponse`)
- [ ] Does NOT import `lambda_runtime` separately when using `lambda_http`
- [ ] Feature flags are used in `aws_lambda_events` to reduce compilation time

### 10. Runtime and deployment
- [ ] `Cargo.toml` specifies correct `edition`
- [ ] The deployment will use `--runtime provided.al2023`

## Output format

Provide:
1. **Summary**: overall assessment (Ready / Needs minor fixes / Needs significant changes)
2. **Issues found**: for each problem, show affected code + suggested fix
3. **Strengths**: patterns done correctly
4. **Next step**: recommend `/rust-lambda:build` if ready, or list items to fix first
