---
name: rust-lambda-new-handler
description: >
  Scaffold or generate a complete AWS Lambda handler in Rust. Use when the user wants to
  write a new handler function, understand the handler signature, define input/output event
  structs, or see a full working example with business logic.
---

# AWS Lambda Rust — Handler Scaffolding

Generate a well-structured Lambda handler in Rust based on the user's use case.

## Context from $ARGUMENTS
Parse $ARGUMENTS for:
- What the handler should do (e.g. "process S3 orders", "handle SQS messages", "generic JSON")
- Whether it uses a pre-defined event type or a custom struct

## Standard handler signature

The canonical handler signature for Rust Lambda functions:

```rust
async fn function_handler(event: LambdaEvent<T>) -> Result<U, Error>
```

Where:
- `LambdaEvent<T>` — wrapper from `lambda_runtime` that gives access to the payload AND the context object (request ID, ARN, deadline, etc.)
- `T` — deserialized input type. Can be `serde_json::Value` for any generic JSON, or a specific type like `ApiGatewayProxyRequest`
- `U` — output type. Must implement `serde::Serialize`. Can be `String`, `serde_json::Value`, or a custom struct.
- On `Ok(U)` → successful execution, returns `U` as JSON
- On `Err(Error)` → Lambda logs the error to CloudWatch and returns an error response

## Variant signatures (also valid)

**Without LambdaEvent wrapper** (loses access to context object):
```rust
async fn handler(event: serde_json::Value) -> Result<String, Error>
```

**With unit type input** (for scheduled/periodic invocations):
```rust
async fn handler(_: ()) -> Result<Value, Error>
```

## Complete example: Custom JSON event with S3 interaction

Generate this template when the user needs to process a custom event and interact with AWS services:

```rust
use aws_sdk_s3::{Client, primitives::ByteStream};
use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::env;

// Define the shape of the expected input event as a Rust struct.
// #[derive(Deserialize, Serialize)] auto-generates serialization/deserialization code.
#[derive(Deserialize, Serialize)]
struct Order {
    order_id: String,
    amount: f64,
    item: String,
}

async fn function_handler(event: LambdaEvent<Value>) -> Result<String, Error> {
    let payload = event.payload;

    // Deserialize the generic JSON input into the Order struct
    let order: Order = serde_json::from_value(payload)?;

    // Read environment variable — never hard-code resource names
    let bucket_name = env::var("RECEIPT_BUCKET")
        .map_err(|_| "RECEIPT_BUCKET environment variable is not set")?;

    let receipt_content = format!(
        "OrderID: {}\nAmount: ${:.2}\nItem: {}",
        order.order_id, order.amount, order.item
    );
    let key = format!("receipts/{}.txt", order.order_id);

    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let s3_client = Client::new(&config);

    upload_receipt_to_s3(&s3_client, &bucket_name, &key, &receipt_content).await?;

    Ok("Success".to_string())
}

async fn upload_receipt_to_s3(
    client: &Client,
    bucket_name: &str,
    key: &str,
    content: &str,
) -> Result<(), Error> {
    client
        .put_object()
        .bucket(bucket_name)
        .key(key)
        .body(ByteStream::from(content.as_bytes().to_vec()))
        .content_type("text/plain")
        .send()
        .await?;

    Ok(())
}

// #[tokio::main] marks the entry point and sets up the Tokio async runtime.
#[tokio::main]
async fn main() -> Result<(), Error> {
    run(service_fn(function_handler)).await
}
```

## Accessing the context object

The `LambdaEvent` wrapper provides Lambda-specific metadata via `event.context`:

```rust
async fn function_handler(event: LambdaEvent<Value>) -> Result<String, Error> {
    let request_id = event.context.request_id;
    // other context fields:
    // event.context.deadline            — execution deadline in ms
    // event.context.invoked_function_arn — ARN of the function
    // event.context.xray_trace_id       — X-Ray trace ID
    // event.context.env_config          — function name, memory, version, log stream
    ...
}
```

## Accessing environment variables

Always use environment variables for operational parameters — never hard-code resource names:

```rust
let bucket_name = env::var("RECEIPT_BUCKET")
    .map_err(|_| "RECEIPT_BUCKET environment variable is not set")?;
```

## Defining input event structs

Match the struct fields to the expected JSON keys. Use `#[derive(Deserialize, Serialize)]` for automatic serde support:

```rust
#[derive(Deserialize, Serialize)]
struct Order {
    order_id: String,
    amount: f64,
    item: String,
}
```

Access fields with dot notation: `order.order_id`, `order.amount`, `order.item`.

## File structure for larger projects

For larger Lambda functions, split code into logical modules:

```
/<project-name>
├── src/
│   ├── main.rs        # Entry point — sets up tokio and calls run()
│   ├── handler.rs     # Main handler function
│   ├── services.rs    # Back-end service calls (S3, DynamoDB, etc.)
│   └── models.rs      # Data model structs
└── Cargo.toml
```

## Best practices to enforce
- **Separate handler from core logic** — makes unit testing easier
- **Use environment variables** for all resource names (buckets, table names, etc.)
- **Initialize SDK clients outside the handler** when using shared state (see `/rust-lambda:add-s3` for the shared-state pattern)
- **Write idempotent code** — duplicate events must be handled the same way
- **Avoid recursive invocations** — a function that invokes itself can cause uncontrolled scaling and cost escalation
- **Do not use non-public Lambda internal APIs** — only use documented public APIs

After generating the handler, remind the user to:
1. Add required IAM permissions to the execution role (e.g. `s3:PutObject`)
2. Set required environment variables in the Lambda configuration
3. Run `/rust-lambda:build` to compile
