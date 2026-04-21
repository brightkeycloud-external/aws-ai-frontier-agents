# Kiro Autonomous Agent Demo — Prompt for Live Demo

Use this as the initial prompt in Kiro IDE to kick off the autonomous agent.
Copy-paste into the Kiro chat when ready.

---

## The Prompt

```
Build a serverless web application called "Ye Olde Translator" that converts modern English text to Old English (Shakespearean style) using Amazon Bedrock.

Requirements:
- A static HTML/CSS/JS frontend hosted on S3 behind CloudFront with a dark medieval theme
- An API Gateway (HTTP API) with two routes: POST /translate and GET /history
- A single Lambda function (Python 3.12) that handles both routes
- POST /translate: accepts { "text": "..." }, calls Bedrock with the latest Claude Haiku model (dynamically discovered via Terraform data source) to translate the text to Old English, saves the result to DynamoDB, and returns the translation. Since newer Bedrock models require inference profiles for on-demand invocation, the Terraform must derive the inference profile ID by prepending "us." to the model ID (e.g. us.anthropic.claude-haiku-4-5-20251001-v1:0) and pass that to the Lambda as MODEL_ID. The IAM policy must allow bedrock:InvokeModel on both the inference profile ARN and the foundation model ARN with a wildcard region (arn:aws:bedrock:*::foundation-model/...) since cross-region profiles route to multiple regions.
- GET /history: returns the last 20 translations from DynamoDB
- DynamoDB table with translationId as the partition key
- All infrastructure defined in Terraform with proper tagging (env=demo, costcenter=demo, managed-by=terraform)
- Lambda should have X-Ray tracing enabled and a concurrency limit of 10
- Include a deploy-website.sh script that injects the API URL into the HTML and uploads to S3
- Include a send-test-translations.sh script that sends 5 sample phrases and checks history
- IMPORTANT: In the frontend JavaScript, do NOT name any function "translate" — this collides with the built-in HTMLElement.translate property and silently breaks onclick handlers. Use a name like "doTranslate" instead.
- Region: us-east-1
- Use CloudWatch alarms for Lambda errors

After building the application, install the CloudWatch Application Signals Kiro Power to add observability guidance for monitoring the deployed application.
```

---

## What to Expect

Kiro will go through its spec-driven development workflow:

1. **Requirements** — Generates user stories in EARS format
2. **Design** — Creates architecture document with service choices
3. **Implementation** — Breaks design into tasks, executes each one

The autonomous agent should create:
- `main.tf`, `variables.tf`, `locals.tf`, `app.tf`, `outputs.tf`
- `lambda/translator.py`
- `website/index.html`
- `deploy-website.sh`, `send-test-translations.sh`
- Architecture diagram (if diagram tools available)

Total autonomous execution time: ~10-15 minutes
