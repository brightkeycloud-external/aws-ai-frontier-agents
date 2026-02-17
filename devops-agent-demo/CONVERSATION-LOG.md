# DevOps Agent Demo — Conversation Log

## Phase 1: Research & Planning (from compacted context)

> **Prompt:** `I want to create a demonstration using the aws devops agent. For this demo, I want to use terraform to create any necessary resources - use the terraform-standards and diagram-standards skills as needed. Please research using the aws knowledge mcp before doing any work. Check both documentation and blogs as the devops frontier agent is rather new. Ask me single questions to get clarity on requirements. I expect this demonstration to take 30 minutes to deliver, so plan accordingly. Create a directory in this directory to hold all resources. Keep conversation terse to preserve tokens.`

**Response:** Researched DevOps Agent via AWS docs and blogs, then asked clarifying questions one at a time about architecture, fault injection method, and demo scope. Demo was later increased to 45 min to cover both incident response and proactive prevention.

### Research
- Searched AWS docs, blogs, getting started guides for DevOps Agent
- Read Terraform setup guide, incident response docs, Agent Space creation docs
- Loaded terraform-standards and diagram-standards skills

### Architecture Decision
- **User guidance:** Mixed architecture — ECS frontend → Lambda processing → DynamoDB + S3 + SNS/SQS
- **Fault injection:** IAM permission removal (remove S3 PutObject from Lambda role)
- **Region:** us-east-1 (only region for DevOps Agent preview)
- **Demo length:** 45 min (incident response + proactive prevention)
- **Assume no prior DevOps Agent setup exists**

### Infrastructure Created
- `main.tf` — Provider (us-east-1), default_tags, data sources
- `variables.tf` — env, project, aws_region, costcenter, repo with descriptions
- `locals.tf` — prefix `${var.env}-${var.project}`, centralized tags
- `app.tf` — SNS, SQS, DynamoDB, S3, Lambda + IAM, ECS cluster + task def, 2 CloudWatch alarms
- `outputs.tf` — 8 outputs with descriptions
- `lambda/order_processor.py` — reads SQS, writes DynamoDB + S3 (S3 write is fault target)
- `inject-fault.sh` — strips s3:PutObject from inline policy; restore via targeted terraform apply
- `send-test-orders.sh` — publishes 10 SNS messages
- `DEMO-RUNBOOK.md` — full script with timing, talking points, cleanup
- `diagram.py` — architecture diagram source
- `CONVERSATION-RECOVERY.md` — context recovery file

### Validation
- `terraform init` ✅
- `terraform validate` ✅
- `terraform fmt` ✅
- Architecture diagram generated ✅

---

## Phase 2: Checkov Scan & Fixes

> **Prompt:** *(Checkov scan results submitted — 60 passed, 19 failed)*

**Response:** Recommended fixing 4 quick findings, skipping 15 that are overkill for a demo:

Fixed (1-line each):
- CKV_AWS_50: Lambda X-Ray tracing (`tracing_config { mode = "Active" }`)
- CKV_AWS_27: SQS encryption (`sqs_managed_sse_enabled = true`)
- CKV_AWS_336: ECS read-only root filesystem (`readonlyRootFilesystem = true`)
- CKV_AWS_115: Lambda concurrency limit (`reserved_concurrent_executions = 10`)

Skipped for demo: SNS/DynamoDB/S3 KMS encryption, Lambda VPC/DLQ/code-signing, CW log retention, S3 versioning/replication/logging/lifecycle.

---

## Phase 3: Save Context

> **Prompt:** `save the context in a file, just in case`

**Response:** Updated `CONVERSATION-RECOVERY.md` with Checkov results and current status.

---

## Phase 4: Deploy & Verify

> **Prompt:** `please continue`

**Response:** Applied 4 Checkov fixes to `app.tf`. Ran `terraform validate` ✅, `terraform plan` ✅ — 20 resources to create.

> **Prompt:** `do I need to create the aws devops agent resources first, or can the resources be deployed first?`

**Response:** Deploy Terraform resources first. The DevOps Agent Space discovers existing infrastructure — it needs real resources to map relationships.

> **Prompt:** `yes, I don't need output until it is complete`

**Response:** `terraform apply` ✅ — 20 resources created:
- SNS: `arn:aws:sns:us-east-1:997075698610:demo-devops-agent-orders`
- SQS: `https://sqs.us-east-1.amazonaws.com/997075698610/demo-devops-agent-order-processing`
- Lambda: `demo-devops-agent-order-processor`
- S3: `demo-devops-agent-receipts-997075698610`
- DynamoDB: `demo-devops-agent-orders`
- ECS: `demo-devops-agent-frontend`

> **Prompt:** `did you complete the tasks in the runbook for "Verify Working State"?`

**Response:** Not yet. Ran verification steps:
1. `./send-test-orders.sh` — 10 orders sent ✅
2. `aws s3 ls` — receipts landing in S3 ✅
3. `aws dynamodb scan` — orders recorded in DynamoDB ✅

Pipeline working end-to-end.

---

## Phase 5: Topology Navigation

> **Prompt:** `in the runbook step Verify Topology, where exactly will I find the topology in the web app?`

**Response:** It's called **DevOps Center** in the left navigation of the DevOps Agent web app (not the AWS Console). Three zoom levels: System view → Container view → Resource view. Topology auto-builds ~2-5 min after Agent Space creation.

---

## Phase 6: Tag Update

> **Prompt:** `update the terraform to set costcenter to demo, and ensure that I only need to change tags in one place to apply everywhere`

**Response:** Tags were already centralized — defined once in `locals.tf`, applied everywhere via `default_tags` in `main.tf`. Changed costcenter default from `"demo-devops-agent"` to `"demo"` in `variables.tf`.

---

## Phase 7: Diagram Source Confirmation

> **Prompt:** `did you save the code used to generate the diagram? I want to ensure that is what we update and use to generate new diagrams when any terraform updates occur`

**Response:** Confirmed `diagram.py` exists alongside the `.tf` files. It's the source of truth — update it and regenerate when infrastructure changes.

---

## Phase 8: Gitignore

> **Prompt:** `please create a .gitignore in ../ which contains common entries for python, node.js, and terraform. I want to be able to execute demos without affecting my git repo when I commit later.`

**Response:** Created `/Users/csmith/Work/github/ai-config/kiro/.gitignore` covering:
- Terraform: `.terraform/`, state files, `*.tfplan`, lock file
- Python: `__pycache__/`, venvs, eggs
- Node.js: `node_modules/`, debug logs
- Demo artifacts: `*.zip`, `generated-diagrams/`
- IDE/OS: `.vscode/`, `.idea/`, `.DS_Store`

---

## Phase 9: Demo Builder Instructions

> **Prompt:** `create an instruction file that I can tell kiro to use if I want to create a demo which highlights a different AWS service/feature, which uses an analogous flow with terraform infrastructure, and either console or terraform for the highlighted service/feature`

**Response:** Created `.kiro/instructions/demo-builder.md` — a reusable instruction file that codifies the full demo-building flow: research, single-question requirements gathering, Terraform infrastructure with standards, scripts, runbook, diagram, validation, and documentation. Invoke with e.g. "Follow the demo-builder instructions to create a demo for AWS GuardDuty."
