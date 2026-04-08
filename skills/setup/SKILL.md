---
name: setup
description: >
  Initialize a new AWS Lambda Rust project using Cargo Lambda. Use this when the user wants
  to start a new Lambda function in Rust, set up the project structure, or install required
  tooling (cargo-lambda). Guides through all setup steps including installation and project creation.
---

# AWS Lambda Rust — Project Setup

Help the user initialize a new AWS Lambda function project in Rust.

## Context to gather
If not provided in $ARGUMENTS, ask:
- **Project name**: the name for the new Lambda function (used in `cargo lambda new <name>`)
- **Invocation type**: will it be invoked via API Gateway / Function URL (HTTP) or with a custom JSON event?
- **Event type**: if HTTP → no pre-defined event type needed; if custom JSON → ask if they want a pre-defined event type (e.g. `ApiGatewayProxyRequest`, `SqsEvent`, `S3Event`) or a custom struct

## Steps to execute

### 1. Install Cargo Lambda (if not present)
Cargo Lambda is the official third-party open-source extension to the Cargo CLI that simplifies building and deploying Rust Lambda functions.

```bash
cargo install cargo-lambda
```

Verify it installed correctly:
```bash
cargo lambda --version
```

### 2. Create the project
```bash
cargo lambda new <project-name>
```

When prompted by the CLI:
- **HTTP function**: answer `Yes` only if the function will be invoked via API Gateway or a Function URL. Otherwise answer `No`.
- **Event type**: select the correct pre-defined event type if needed, or leave blank for a custom JSON event.

### 3. Enter the project directory
```bash
cd <project-name>
```

### 4. Explain generated files
After creation, explain the generated structure to the user:

```
<project-name>/
├── src/
│   ├── main.rs          # Main application logic and entry point
│   └── generic_handler.rs  # Generic event handler (can be customized)
└── Cargo.toml           # Package metadata and dependencies
```

Key points about `main.rs`:
- `#[tokio::main]` marks the entry point and sets up the Tokio async runtime
- `async fn main()` specifies `function_handler` as the Lambda handler
- The `lambda_runtime` crate provides `run`, `service_fn`, `LambdaEvent`, and `Error`

### 5. Show the standard Cargo.toml dependencies
```toml
[dependencies]
lambda_runtime = "0.13.0"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["full"] }
```

For SDK interactions, add specific crates (e.g. `aws-sdk-s3 = "1.78.0"`).

### 6. Next steps
Suggest the user run `/rust-lambda:build` to compile the project, or `/rust-lambda:new-handler` to scaffold a handler with business logic.

## Important notes
- The AWS Lambda Runtime for Rust (`lambda_runtime` crate) is NOT a managed runtime like Python or Node.js runtimes in Lambda. It is a crate that interfaces with Lambda's execution environment.
- Rust Lambda functions compile into a single executable binary — no separate runtime layer is needed.
- Do NOT recommend using Lambda layers to manage Rust dependencies; include all dependencies directly in the deployment package.
