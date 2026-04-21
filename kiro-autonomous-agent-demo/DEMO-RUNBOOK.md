# Kiro Autonomous Agent Demo Runbook

**Duration:** ~45 minutes
**Region:** us-east-1
**Kiro Feature:** Autonomous Agent (spec-driven development)
**Kiro Power:** CloudWatch Application Signals

---

## Pre-Demo Setup (~10 min before demo)

### 1. Verify Bedrock Model Access

```bash
cd kiro-autonomous-agent-demo/translator_app_working
terraform init
terraform plan 2>&1 | grep bedrock_model_id
```

Terraform dynamically discovers the latest Claude Haiku model and derives the inference profile ID. Before deploying, ensure the model's Marketplace agreement is accepted in us-east-1:

```bash
# Accept the model agreement (only needed once per model per region)
OFFER_TOKEN=$(aws bedrock list-foundation-model-agreement-offers \
  --model-id "$(terraform output -raw bedrock_model_id)" \
  --region us-east-1 --query 'offers[0].offerToken' --output text)
aws bedrock create-foundation-model-agreement \
  --model-id "$(terraform output -raw bedrock_model_id)" \
  --offer-token "$OFFER_TOKEN" --region us-east-1
```

If no Haiku models are accessible, go to **Bedrock Console → Model access → Enable** for Claude Haiku models.

### 2. Prepare Kiro IDE

1. Open Kiro IDE
2. Create a new empty project/folder (e.g., `ye-olde-translator`)
3. Ensure you're signed in with AWS credentials that have permissions for:
   - Lambda, API Gateway, DynamoDB, S3, CloudFront, CloudWatch, Bedrock, IAM
4. Have the `KIRO-PROMPT.md` file open in a separate tab for easy copy-paste

### 3. Pre-Baked Backup (Optional)

If you want a safety net in case the live demo hits issues:

```bash
cd kiro-autonomous-agent-demo/translator_app_working
terraform init
terraform apply
./deploy-website.sh
./send-test-translations.sh
```

This gives you a working deployment to fall back on. You can still do the live Kiro demo and compare outputs.

### 4. Pre-Demo Checklist

- [ ] AWS credentials configured with sufficient permissions
- [ ] Bedrock Claude Haiku model access enabled in us-east-1 (Marketplace agreement accepted)
- [ ] Kiro IDE installed and signed in
- [ ] Empty project folder ready
- [ ] `KIRO-PROMPT.md` accessible for copy-paste
- [ ] Pre-baked backup deployed (optional)
- [ ] Architecture diagram ready to show (`generated-diagrams/diagram.png`)

---

## Part 1: Introduction & Context (~5 min)

### Talking Points (3 min)

- **Kiro** is an agentic IDE built by AWS — it turns natural language prompts into structured specs, code, docs, and tests
- **Spec-driven development** vs "vibe coding": Kiro creates requirements → design → implementation plan before writing any code
- **Autonomous Agent** mode: Kiro executes the full plan autonomously — you watch it work
- Key features: **Steering** (consistent behavior), **Hooks** (automated tasks), **Powers** (pre-packaged MCP integrations)
- Real-world example: A team of 3 built a production drug discovery agent in 3 weeks using Kiro, with Kiro generating 95% of the business logic

### Show the Target Architecture (2 min)

1. Show the architecture diagram (`generated-diagrams/diagram.png`)
2. Walk through: User → CloudFront → S3 (static site) → API Gateway → Lambda → Bedrock + DynamoDB
3. "We're going to watch Kiro build this entire application from a single prompt"

---

## Part 2: Live Autonomous Agent Demo (~25 min)

### Give Kiro the Prompt (2 min)

1. In the empty Kiro IDE project, open the chat
2. Copy the prompt from `KIRO-PROMPT.md` and paste it
3. "I'm giving Kiro a natural language description of what I want. Watch what happens."

### Requirements Phase (~3 min)

Kiro generates structured requirements:

**Point out:**
- User stories in EARS format (Event-Action-Response-State)
- Acceptance criteria for each story
- Non-functional requirements (performance, security)
- "This is the spec-driven approach — requirements are documented before any code is written"

### Design Phase (~3 min)

Kiro creates an architecture document:

**Point out:**
- Service selection rationale (why Lambda, why DynamoDB, why CloudFront)
- API contract definition (routes, request/response schemas)
- Data model design (DynamoDB schema)
- Security considerations (IAM roles, least privilege)
- "A human architect would create this same document — Kiro does it in seconds"

### Implementation Phase (~12 min)

Kiro breaks the design into tasks and executes them:

**Point out as each file is created:**
- **Terraform files**: "Notice the proper tagging, naming conventions, and security settings"
- **Lambda function**: "It's using the Bedrock API with the latest Claude Haiku via a cross-region inference profile — dynamically discovered"
- **Frontend**: "A complete HTML/CSS/JS application with a medieval theme"
- **Scripts**: "Deployment and testing scripts — production-ready from the start"
- **Error handling**: "The Lambda has proper error handling, not just happy path"

**Key talking points during implementation:**
- "Kiro isn't just generating code — it's following the design document it created"
- "Each task references the requirements and design decisions"
- "This is reproducible — another developer could follow the same spec"

### Install CloudWatch Application Signals Power (~5 min)

1. In Kiro IDE, go to **Powers** (or the Powers marketplace)
2. Search for "CloudWatch Application Signals"
3. Click **Install** (one-click)
4. Show what was installed: MCP server, steering files, hooks
5. Ask Kiro: *"Using the Application Signals power, what observability should I add to monitor this application's health?"*
6. Show Kiro's response — it will recommend SLOs, dashboards, and tracing configuration specific to the app

**Key talking point:** "Powers give Kiro instant expertise in specific technologies. Instead of me explaining CloudWatch Application Signals, the power provides the context automatically."

---

## Part 3: Deploy & Verify (~10 min)

### Deploy Infrastructure (3 min)

If Kiro built the Terraform (live demo succeeded):
```bash
cd <kiro-project-folder>
terraform init
terraform apply
```

If using pre-baked backup:
```bash
cd kiro-autonomous-agent-demo/translator_app_working
# Already deployed in pre-demo setup
```

### Deploy Website (2 min)

```bash
./deploy-website.sh
```

Show the output — S3 upload, CloudFront invalidation, final URL.

### Show the Working App (3 min)

1. Open the CloudFront URL in a browser
2. Type: "Hello, how are you doing today?"
3. Click Translate — show the Old English result
4. Type: "Please send me the quarterly report by Friday"
5. Click Translate — show another result
6. Scroll down — show the translation history populating
7. "This entire application — frontend, backend, infrastructure, AI integration — was built by Kiro from a single prompt"

### Run Test Script (2 min)

```bash
./send-test-translations.sh
```

Show 5 translations completing successfully and history count.

---

## Part 4: What Kiro Built vs What We'd Build (~5 min)

### Side-by-Side Comparison

Walk through the generated code and compare to what a human developer would write:

1. **Terraform**: Proper tagging, least-privilege IAM, X-Ray tracing, concurrency limits
2. **Lambda**: Error handling, logging, clean separation of concerns
3. **Frontend**: Responsive design, loading states, error handling
4. **Scripts**: Idempotent deployment, verification steps

### Key Takeaways

- Kiro's spec-driven approach produces **documented, reviewable** code — not a black box
- The requirements and design docs serve as **living documentation**
- The autonomous agent handles the tedious parts while humans focus on **what to build, not how**
- Powers extend Kiro's expertise to specific AWS services without manual context

---

## Q&A (~5 min)

### Common Questions

**Q: How is this different from ChatGPT/Copilot generating code?**
A: Kiro uses spec-driven development — it creates requirements and design docs first, then implements against them. The output is structured, documented, and reviewable. It's not just code generation; it's a full development workflow.

**Q: Can Kiro modify existing applications?**
A: Yes. You can point Kiro at an existing codebase and ask it to add features, refactor, or fix bugs. The autonomous agent understands project context.

**Q: What about testing?**
A: Kiro can generate tests as part of the implementation plan. We skipped tests in this demo for time, but in production you'd include them in the prompt.

**Q: What are Kiro Powers?**
A: Pre-packaged MCP servers, steering files, and hooks validated by AWS partners. They give Kiro instant expertise in specific technologies — Aurora, CloudWatch, HealthOmics, etc. One-click install from the Powers marketplace.

**Q: What models does Kiro use internally?**
A: Kiro uses Amazon Bedrock foundation models for its AI capabilities. The specific model can vary.

**Q: Cost?**
A: Kiro has free and paid tiers. Check https://kiro.dev for current pricing. The AWS resources deployed in this demo cost pennies (pay-per-request DynamoDB, Lambda invocations, Bedrock per-token pricing).

**Q: Can I use Kiro CLI instead of the IDE?**
A: Yes — `kiro-cli chat` provides the same AI capabilities in a terminal. The autonomous agent is currently best experienced in the IDE where you can see the spec-driven workflow visually.

---

## Cleanup

```bash
# Remove Terraform resources
cd kiro-autonomous-agent-demo/translator_app_working
terraform destroy

# If you deployed the pre-baked backup too:
cd kiro-autonomous-agent-demo/translator_app_working
terraform destroy
```

---

## Reference Links

- **Kiro**: https://kiro.dev
- **Kiro Powers**: https://kiro.dev/powers/
- **Kiro GovCloud**: https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/govcloud-kiro.html
- **Blog — Drug Discovery Agent**: https://aws.amazon.com/blogs/industries/from-spec-to-production-a-three-week-drug-discovery-agent-using-kiro/
- **Blog — Business Logic to Code**: https://aws.amazon.com/blogs/enterprise-strategy/from-business-logic-to-working-code-how-aws-kiro-changes-who-can-build/
- **Blog — Fitness App with DocumentDB**: https://aws.amazon.com/blogs/database/build-a-fitness-center-management-application-with-kiro-using-amazon-documentdb-with-mongodb-compatibility/
- **Blog — Modernize with AgentCore Gateway + Kiro**: https://aws.amazon.com/blogs/migration-and-modernization/modernize-your-applications-using-amazon-bedrock-agentcore-gateway-and-kiro-powers/
- **Blog — Cost Optimization with Kiro**: https://aws.amazon.com/blogs/aws-cloud-financial-management/5-ways-to-use-amazon-q-to-optimize-your-infrastructure/
- **Blog — Agentic Cloud Modernization**: https://aws.amazon.com/blogs/migration-and-modernization/agentic-cloud-modernization-accelerating-modernization-with-aws-mcps-and-kiro/
- **CloudWatch Application Signals Power**: https://aws.amazon.com/about-aws/whats-new/2026/01/cloudwatch-application-signals-kiro-powers/
- **Bedrock Claude Haiku 4.5**: https://docs.aws.amazon.com/bedrock/latest/userguide/models-supported.html
- **re:Invent Session — Kiro Spec-Driven Development**: https://aws.amazon.com/blogs/devops/your-guide-to-the-developer-tools-track-at-aws-reinvent-2025/
