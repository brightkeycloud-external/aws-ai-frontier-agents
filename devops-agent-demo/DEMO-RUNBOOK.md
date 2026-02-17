# AWS DevOps Agent Demo Runbook

**Duration:** ~45 minutes
**Region:** us-east-1 (only supported region for DevOps Agent preview)

---

## Pre-Demo Setup (~15 min before demo)

### 1. Deploy Infrastructure

```bash
cd devops-agent-demo
terraform init
terraform plan
terraform apply
```

### 2. Verify Working State

```bash
# Send test orders — should succeed with no errors
./send-test-orders.sh

# Confirm receipts landed in S3
aws s3 ls s3://$(terraform output -raw s3_bucket)/receipts/ --region us-east-1

# Confirm DynamoDB has records
aws dynamodb scan --table-name $(terraform output -raw dynamodb_table) --max-items 3 --region us-east-1
```

### 3. Create DevOps Agent Space (Console)

> **Docs:** https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-creating-an-agent-space.html

1. Go to **AWS Console → DevOps Agent** (https://console.aws.amazon.com/devopsagent/)
2. Click **Create Agent Space +**
3. Name: `demo-order-processing`
4. Primary account access: **Auto-create a new AWS DevOps Agent role** (recommended)
5. Enable Web App: **Auto-create a new AWS DevOps Agent role** (recommended)
6. Click **Submit**
7. Wait for topology to build (~2-5 min)

> **Terraform alternative:** https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-getting-started-with-aws-devops-agent-using-terraform.html
> Clone `https://github.com/aws-samples/sample-aws-devops-agent-terraform.git` and follow the README.

### 4. Verify Topology

- In the Agent Space web app, check that the topology shows:
  - ECS cluster → SNS → SQS → Lambda → DynamoDB + S3
- This confirms DevOps Agent understands the application architecture

---

## Part 1: Incident Response Demo (~20 min)

### Talking Points (2 min)

- DevOps Agent is a **frontier agent** — autonomous, multi-step reasoning
- Uses **multi-agent architecture**: lead agent delegates to specialized sub-agents
- Investigates like an experienced DevOps engineer: correlates telemetry, code, deployments
- Available at **no cost during preview** in us-east-1

### Show the Healthy App (3 min)

1. Show the architecture diagram (`diagram.png`)
2. Show CloudWatch alarms — both in OK state
3. Show S3 bucket with receipts from pre-demo test
4. Show DynamoDB table with processed orders

### Inject the Fault (2 min)

```bash
# Remove S3 PutObject permission from Lambda
./inject-fault.sh inject
```

Explain: "We've simulated a bad deployment that accidentally removed an IAM permission deep in the dependency chain. The Lambda can still read from SQS and write to DynamoDB, but S3 writes will fail."

### Generate Traffic to Trigger Alarm (2 min)

```bash
./send-test-orders.sh
```

- Show Lambda errors appearing in CloudWatch Logs
- Show the `demo-devops-agent-lambda-errors` alarm transitioning to ALARM state

### DevOps Agent Investigation (10 min)

1. **In the Agent Space web app**, either:
   - Wait for automatic investigation (if alarm is connected), OR
   - Start a manual investigation via chat: *"Investigate the Lambda errors alarm for demo-devops-agent-order-processor"*

2. **Walk through the investigation timeline:**
   - **Planning**: Agent creates investigation plan
   - **Fetching data**: Agent pulls CloudWatch logs, metrics, IAM policies
   - **Observations**: Agent identifies S3 AccessDenied errors in logs
   - **Findings**: Agent traces the dependency chain
   - **Root cause**: Missing `s3:PutObject` permission on the Lambda role

3. **Show the mitigation plan:**
   - Click "Generate mitigation plan"
   - Agent recommends restoring the S3 permission
   - Shows specific IAM policy changes needed
   - Includes pre/post validation steps

4. **Chat interaction** (optional):
   - Ask: *"What other resources were affected by this?"*
   - Ask: *"Could this have been prevented?"*

### Restore (1 min)

```bash
./inject-fault.sh restore
./send-test-orders.sh
# Confirm alarm returns to OK
```

---

## Part 2: Proactive Prevention Demo (~15 min)

### Talking Points (2 min)

- DevOps Agent doesn't just fight fires — it **prevents** them
- Analyzes patterns across incidents for actionable recommendations
- Four areas: observability, infrastructure, deployment pipelines, code

### Show Recommendations (10 min)

> **Docs:** https://docs.aws.amazon.com/devopsagent/latest/userguide/devops-agent-incident-response-preventing-future-incidents.html

In the Agent Space web app, navigate to the **Incident Prevention** tab:

1. **Observability recommendations** — Agent may suggest:
   - Adding CloudWatch alarms for S3 PutObject failures specifically
   - Adding X-Ray tracing to the Lambda function
   - Creating a dashboard for the order processing pipeline

2. **Infrastructure recommendations** — Agent may suggest:
   - DLQ configuration for the SQS queue
   - Lambda error retry configuration
   - S3 bucket versioning

3. **Deployment pipeline recommendations** — Agent may suggest:
   - IAM policy validation in CI/CD
   - Canary deployments for Lambda
   - Automated rollback triggers

Walk through 2-3 specific recommendations, showing how each would prevent the incident we just demonstrated.

### Key Takeaway (3 min)

- The agent learned from the incident and now recommends **specific, actionable** improvements
- These aren't generic best practices — they're tailored to YOUR application topology
- Recommendations improve over time as the agent learns from your team's feedback

---

## Q&A (~10 min)

### Common Questions

**Q: What observability tools does it support?**
A: CloudWatch (native), Datadog, Dynatrace, New Relic, Splunk

**Q: Can it take automated action?**
A: It generates mitigation plans with specific commands. Automated remediation is on the roadmap.

**Q: What about multi-account?**
A: Agent Spaces support cross-account monitoring via IAM trust relationships.

**Q: Cost?**
A: Free during preview. Check https://aws.amazon.com/devops-agent/ for GA pricing.

**Q: How does it differ from CloudWatch AIOps?**
A: DevOps Agent is a frontier agent — it reasons autonomously across multiple tools and data sources, not just CloudWatch metrics.

---

## Cleanup

```bash
# Remove Terraform resources
terraform destroy

# Delete Agent Space via Console
# https://console.aws.amazon.com/devopsagent/
```

---

## Reference Links

- **DevOps Agent User Guide:** https://docs.aws.amazon.com/devopsagent/latest/userguide/
- **Getting Started:** https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent.html
- **Creating Agent Spaces:** https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-creating-an-agent-space.html
- **Terraform Setup:** https://docs.aws.amazon.com/devopsagent/latest/userguide/getting-started-with-aws-devops-agent-getting-started-with-aws-devops-agent-using-terraform.html
- **Incident Response:** https://docs.aws.amazon.com/devopsagent/latest/userguide/devops-agent-incident-response.html
- **Prevention:** https://docs.aws.amazon.com/devopsagent/latest/userguide/devops-agent-incident-response-preventing-future-incidents.html
- **Blog - Prototype to Product:** https://aws.amazon.com/blogs/devops/from-ai-agent-prototype-to-product-lessons-from-building-aws-devops-agent/
- **Blog - Best Practices:** https://aws.amazon.com/blogs/devops/best-practices-for-deploying-aws-devops-agent-in-production/
- **Announcement:** https://aws.amazon.com/about-aws/whats-new/2025/12/devops-agent-preview-frontier-agent-operational-excellence/
