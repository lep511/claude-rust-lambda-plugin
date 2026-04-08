---
name: rust-lambda-add-http
description: >
  Add HTTP event handling to a Rust Lambda function for use with API Gateway, Application
  Load Balancers, or Lambda Function URLs. Use when the user wants to expose their function
  over HTTP. Provides two approaches: typed API Gateway events or the unified lambda_http crate.
---

# AWS Lambda Rust — HTTP Handler

Add HTTP event processing to the Rust Lambda function.

## Context from $ARGUMENTS
- HTTP source: `api-gateway`, `alb` (Application Load Balancer), `function-url`, or `any` (unified)
- Preferred approach: typed events or `lambda_http` abstraction

## Approach 1: Typed API Gateway events (explicit)

Use `aws_lambda_events` with feature flags to minimize compilation time:

### Cargo.toml dependency
```toml
aws_lambda_events = { version = "0.8.3", default-features = false, features = ["apigw"] }
http = "1"
```

### Handler code
```rust
use aws_lambda_events::apigw::{ApiGatewayProxyRequest, ApiGatewayProxyResponse};
use http::HeaderMap;
use lambda_runtime::{service_fn, Error, LambdaEvent};

async fn handler(
    _event: LambdaEvent<ApiGatewayProxyRequest>,
) -> Result<ApiGatewayProxyResponse, Error> {
    let mut headers = HeaderMap::new();
    headers.insert("content-type", "text/html".parse().unwrap());
    let resp = ApiGatewayProxyResponse {
        status_code: 200,
        multi_value_headers: headers.clone(),
        is_base64_encoded: false,
        body: Some("Hello AWS Lambda HTTP request".into()),
        headers,
    };
    Ok(resp)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    lambda_runtime::run(service_fn(handler)).await
}
```

**Available pre-defined event types** in `aws_lambda_events` (use the corresponding feature flag):
- `apigw` → `ApiGatewayProxyRequest` / `ApiGatewayProxyResponse`
- `alb` → `AlbTargetGroupRequest` / `AlbTargetGroupResponse`
- `sqs` → `SqsEvent`
- `s3` → `S3Event`
- `sns` → `SnsEvent`
- `kinesis` → `KinesisEvent`

See the full list at https://crates.io/crates/aws_lambda_events

## Approach 2: Unified lambda_http crate (recommended for new projects)

Works transparently with **API Gateway, Application Load Balancers, and Lambda Function URLs** without changing code. Uses native HTTP types.

**Note**: `lambda_http` uses `lambda_runtime` internally — do NOT import `lambda_runtime` separately.

### Cargo.toml dependency
```toml
lambda_http = "0.13.0"
```

### Handler code
```rust
use lambda_http::{service_fn, Error, IntoResponse, Request, RequestExt, Response};

async fn handler(event: Request) -> Result<impl IntoResponse, Error> {
    let resp = Response::builder()
        .status(200)
        .header("content-type", "text/html")
        .body("Hello AWS Lambda HTTP request")
        .map_err(Box::new)?;
    Ok(resp)
}

#[tokio::main]
async fn main() -> Result<(), Error> {
    lambda_http::run(service_fn(handler)).await
}
```

### Accessing query parameters and body
```rust
async fn handler(event: Request) -> Result<impl IntoResponse, Error> {
    // Query string parameters
    let params = event.query_string_parameters();
    let name = params.first("name").unwrap_or("world");

    // Request body
    let body = std::str::from_utf8(event.body()).unwrap_or("");

    let resp = Response::builder()
        .status(200)
        .header("content-type", "application/json")
        .body(format!(r#"{{"message": "Hello, {}!"}}"#, name))
        .map_err(Box::new)?;
    Ok(resp)
}
```

## After adding HTTP handling

Remind the user:
- If using API Gateway, set `--runtime provided.al2023` when deploying
- For Cargo Lambda deployment: the handler will still be named `rust.handler`
- To test locally with an HTTP payload, use:
  ```bash
  cargo lambda invoke --remote \
    --data-file ./test-events/apigw-event.json \
    <function-name>
  ```
