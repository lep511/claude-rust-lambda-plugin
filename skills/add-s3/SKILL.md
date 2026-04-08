---
name: add-s3
description: >
  Add Amazon S3 integration to a Rust Lambda function using the AWS SDK for Rust.
  Use when the user wants to read from or write to S3. Covers both the basic pattern
  and the shared-state pattern for reusing the S3 client across invocations.
---

# AWS Lambda Rust — S3 Integration

Add AWS SDK for S3 to the Lambda function.

## Context from $ARGUMENTS
- Operation: `put` (upload/write), `get` (download/read), `list`, or `delete`
- Use shared client across invocations: yes/no (default: yes — best practice)

## Step 1: Add dependency to Cargo.toml

Only add the SDK crates your function needs. For S3:

```toml
[dependencies]
aws-config = "1.5.18"
aws-sdk-s3 = "1.78.0"
lambda_runtime = "0.13.0"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["full"] }
```

> Note: Version numbers shown are from the official AWS documentation. Check https://crates.io for the most recent versions.

## Step 2: Import in your code

```rust
use aws_sdk_s3::{Client, primitives::ByteStream};
```

## Pattern A: Initialize client inside handler (simple, less optimal)

The client is re-initialized on every invocation:

```rust
async fn function_handler(event: LambdaEvent<Value>) -> Result<String, Error> {
    let config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let s3_client = Client::new(&config);

    upload_receipt_to_s3(&s3_client, &bucket_name, &key, &content).await?;
    Ok("Success".to_string())
}
```

## Pattern B: Shared state (recommended — initializes client once during Init phase)

Initialize the S3 client **outside the handler** during the Lambda Init phase. Subsequent invocations on the same execution environment **reuse** the client, saving initialization cost.

```rust
use aws_sdk_s3::{Client, primitives::ByteStream};
use lambda_runtime::{run, service_fn, Error, LambdaEvent};
use serde_json::Value;

async fn function_handler(client: &Client, event: LambdaEvent<Value>) -> Result<String, Error> {
    // client is already initialized — just use it
    let bucket_name = std::env::var("RECEIPT_BUCKET")
        .map_err(|_| "RECEIPT_BUCKET environment variable is not set")?;
    let key = "receipts/example.txt";
    let content = "Receipt content here";

    upload_receipt_to_s3(client, &bucket_name, key, content).await?;
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

#[tokio::main]
async fn main() -> Result<(), Error> {
    // Client initialized once during Init phase
    let shared_config = aws_config::load_defaults(aws_config::BehaviorVersion::latest()).await;
    let client = Client::new(&shared_config);
    let shared_client = &client;

    lambda_runtime::run(service_fn(move |event: LambdaEvent<Value>| async move {
        function_handler(shared_client, event).await
    }))
    .await
}
```

## Common S3 operations

### PutObject (upload)
```rust
client
    .put_object()
    .bucket(bucket_name)
    .key(key)
    .body(ByteStream::from(content.as_bytes().to_vec()))
    .content_type("text/plain")
    .send()
    .await?;
```

### GetObject (download)
```rust
let resp = client
    .get_object()
    .bucket(bucket_name)
    .key(key)
    .send()
    .await?;

let data = resp.body.collect().await?.into_bytes();
let text = String::from_utf8(data.to_vec())?;
```

### ListObjectsV2
```rust
let resp = client
    .list_objects_v2()
    .bucket(bucket_name)
    .prefix("receipts/")
    .send()
    .await?;

for obj in resp.contents() {
    println!("Key: {}", obj.key().unwrap_or(""));
}
```

## IAM permissions required

The Lambda execution role must allow the operations the function performs:
- Upload: `s3:PutObject` on `arn:aws:s3:::<bucket-name>/*`
- Download: `s3:GetObject` on `arn:aws:s3:::<bucket-name>/*`
- List: `s3:ListBucket` on `arn:aws:s3:::<bucket-name>`
- Delete: `s3:DeleteObject` on `arn:aws:s3:::<bucket-name>/*`

## Environment variable for bucket name

Always use an environment variable — never hard-code the bucket name:

```rust
let bucket_name = std::env::var("RECEIPT_BUCKET")
    .map_err(|_| "RECEIPT_BUCKET environment variable is not set")?;
```

Set `RECEIPT_BUCKET` in the Lambda environment configuration after deploying.
