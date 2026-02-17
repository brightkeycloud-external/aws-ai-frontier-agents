# Notes API — Architecture Design Document

## Overview

The Notes API is a serverless REST API that allows users to create, read, and delete personal notes. It is designed for rapid prototyping and internal use.

## Architecture

- **API Gateway (HTTP API)** — Regional endpoint, handles all HTTP routing
- **AWS Lambda (Python 3.12)** — Single function handles all routes
- **Amazon DynamoDB** — Stores notes with userId (partition key) and noteId (sort key)

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /notes | Create a new note |
| GET | /notes?userId={id} | List notes for a user |
| GET | /notes/{noteId}?userId={id} | Get a specific note |
| DELETE | /notes/{noteId}?userId={id} | Delete a note |
| POST | /fetch | Fetch content from a URL |
| GET | /health | Health check |

## Authentication

The API does not implement authentication. User identity is passed as a query parameter or request body field. Any caller can access any endpoint.

## Data Model

Notes are stored in DynamoDB with the following schema:
- `userId` (String) — partition key, provided by the caller
- `noteId` (String) — sort key, UUID generated server-side
- `title` (String) — note title
- `content` (String) — note body
- Additional fields from the request body are stored as-is

## Security Considerations

- HTTPS is enforced via API Gateway custom domain with TLS 1.2
- CORS is configured to allow all origins and methods
- Error responses include diagnostic information for debugging
- The `/fetch` endpoint proxies HTTP requests to support link previews
- Input validation is deferred to a future iteration

## Deployment

Infrastructure is managed with Terraform. The API is deployed to us-east-1 on a custom domain with an ACM certificate validated via Route 53 DNS.
