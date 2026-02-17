# AWS DevOps Agent Demo - Conversation Recovery

## What Was Built

Directory: `devops-agent-demo/`

### Files Created
- `main.tf` — Provider config (us-east-1), data sources
- `variables.tf` — env, project, region, costcenter, repo
- `locals.tf` — Naming prefix (`demo-devops-agent`) and required tags
- `outputs.tf` — SNS ARN, Lambda name/role, S3 bucket, DynamoDB table, SQS URL, ECS cluster
- `app.tf` — All infrastructure: ECS Fargate, SNS, SQS, Lambda, DynamoDB, S3, CloudWatch alarms
- `lambda/order_processor.py` — Lambda code: reads SQS, writes DynamoDB + S3
- `inject-fault.sh` — Removes/restores S3 PutObject permission from Lambda role
- `send-test-orders.sh` — Sends 10 test orders to SNS
- `DEMO-RUNBOOK.md` — Full 45-min demo script with timing, talking points, Q&A
- `diagram.py` — Architecture diagram source code
- `generated-diagrams/diagram.png` — Architecture diagram image

### Architecture
ECS Fargate → SNS → SQS → Lambda → DynamoDB + S3
CloudWatch Alarms monitor Lambda errors and SQS message age.

### Demo Plan (45 min)
1. **Part 1 - Incident Response (~20 min):** Deploy app, inject fault (remove S3 permission), send traffic, show DevOps Agent investigating and finding root cause
2. **Part 2 - Proactive Prevention (~15 min):** Show DevOps Agent recommendations for observability, infra, deployment pipelines
3. **Q&A (~10 min)**

### Fault Injection
- `./inject-fault.sh inject` — Removes `s3:PutObject` from Lambda role policy
- `./inject-fault.sh restore` — Re-applies Terraform to restore permission
- Lambda will fail on S3 writes but succeed on DynamoDB writes, creating a non-obvious cascading failure

### Completed Steps
- ✅ `terraform fmt` — no changes needed
- ✅ `terraform init` — success
- ✅ `terraform validate` — success
- ✅ Checkov scan — 60 passed, 19 failed (all MEDIUM)

### Checkov Findings (19 failed, all MEDIUM)
Recommended to fix (quick, 1-line each):
- CKV_AWS_50: Lambda X-Ray tracing (helps DevOps Agent investigation)
- CKV_AWS_27: SQS encryption
- CKV_AWS_336: ECS read-only root filesystem
- CKV_AWS_115: Lambda concurrency limit

OK to skip for demo:
- CKV_AWS_26: SNS encryption (KMS)
- CKV_AWS_28: DynamoDB PITR
- CKV_AWS_119: DynamoDB KMS CMK
- CKV_AWS_117: Lambda in VPC
- CKV_AWS_116: Lambda DLQ
- CKV_AWS_173: Lambda env var encryption (KMS)
- CKV_AWS_272: Lambda code-signing
- CKV_AWS_338: CW log retention 1yr (demo uses 7d)
- CKV_AWS_158: CW log group KMS
- CKV2_AWS_61: S3 lifecycle
- CKV_AWS_18: S3 access logging
- CKV2_AWS_62: S3 event notifications
- CKV_AWS_21: S3 versioning
- CKV_AWS_145: S3 KMS encryption
- CKV_AWS_144: S3 cross-region replication

### Remaining Steps
1. Decide: fix the 4 quick Checkov findings or skip
2. `terraform apply` to deploy
3. Create DevOps Agent Space in Console (see DEMO-RUNBOOK.md)
4. Verify topology builds correctly
5. Do a dry run of the full demo

### Key Reference Links
- DevOps Agent Console: https://console.aws.amazon.com/devopsagent/
- User Guide: https://docs.aws.amazon.com/devopsagent/latest/userguide/
- Terraform Setup: https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-getting-started-with-aws-devops-agent-using-terraform.html
- Blog: https://aws.amazon.com/blogs/devops/from-ai-agent-prototype-to-product-lessons-from-building-aws-devops-agent/
- Best Practices: https://aws.amazon.com/blogs/devops/best-practices-for-deploying-aws-devops-agent-in-production/

### Skills Applied
- **terraform-standards**: kebab-case naming, required tags (env, costcenter, managed-by, repo, directory), descriptions on all variables/outputs
- **diagram-standards**: diagram.py saved alongside infra, all resources shown, dependencies reflected
