# Security Agent Demo — Conversation Log

## Phase 1: Research & Planning

> **Prompt:** `Follow the demo-builder instructions to create a demo for the AWS security agent. Tell me if you can't find the instructions. Read the files in devops-agent-demo to understand the complexity and type of implementation`

**Response:** Found demo-builder instructions at `.kiro/instructions/demo-builder.md`. Read all devops-agent-demo files to understand complexity and patterns. Researched AWS Security Agent via AWS docs and blogs — identified it as a frontier agent (preview, us-east-1) with three capabilities: design review, code review, penetration testing.

### Requirements Gathering (one question at a time per demo-builder instructions)
1. **Service:** AWS Security Agent (frontier agent, preview, us-east-1)
2. **Audience:** Security engineers, DevOps professionals — match devops demo complexity
3. **Architecture:** API Gateway (regional) + Lambda + DynamoDB — intentionally vulnerable notes API. Chose over ALB+ECS because easier to embed intentional vulns in thin Lambda handlers.
4. **Interesting moment:** Three-part demo covering all three capabilities (design review → code review → pentest)
5. **Setup method:** Console with click-by-click steps (same pattern as devops demo). No Terraform provider for Security Agent yet.
6. **Duration:** 45 minutes
7. **Additional:** User will create DNS subdomain and GitHub repo; instructions in runbook

### Architecture Decision
- Regional API Gateway + Lambda + DynamoDB
- Custom domain via Route 53 + ACM (required for pentest domain verification)
- Intentional vulnerabilities: no auth, IDOR, SSRF, verbose errors, no input validation, missing security headers, overly permissive CORS
- Design doc with security gaps for design review demo
- GitHub repo with PR workflow for code review demo

### Files Created
- `main.tf` — Provider (us-east-1), default_tags, data sources (route53 zone, acm cert)
- `variables.tf` — env, project, region, costcenter, repo, domain_name (defaults to securitydemo.aws.brightkey.cloud)
- `locals.tf` — Naming prefix, centralized tags
- `app.tf` — DynamoDB, Lambda + IAM, API Gateway (regional HTTP), custom domain (data-sourced ACM + Route 53), CloudWatch logs
- `outputs.tf` — API endpoint, custom domain URL, Lambda name, DynamoDB table, API ID
- `lambda/notes_api.py` — Intentionally vulnerable notes API with 7 security issues
- `send-test-requests.sh` — Verifies all endpoints work
- `design-doc.md` — Architecture doc with security gaps (for design review)
- `diagram.py` — Architecture diagram source
- `DEMO-RUNBOOK.md` — Full 45-min demo script
- `CONVERSATION-LOG.md` — This file

### Intentional Vulnerabilities in notes_api.py
1. No authentication on any endpoint
2. IDOR — any user can access any other user's notes
3. SSRF — `/fetch` endpoint proxies arbitrary URLs
4. Verbose error responses — stack traces, table name, region, function name
5. No input validation — arbitrary fields stored in DynamoDB
6. Missing security headers — no CSP, X-Frame-Options, etc.
7. Overly permissive CORS — allows all origins/methods/headers

### Validation
- `terraform init` ✅
- `terraform validate` ✅
- `terraform fmt` ✅
- Checkov scan ✅ — 29 passed, 9 failed (all MEDIUM)
- Architecture diagram generated ✅

### Checkov Findings (9 failed, all MEDIUM — all skipped for demo)
- CKV_AWS_28: DynamoDB PITR
- CKV_AWS_119: DynamoDB KMS CMK
- CKV_AWS_117: Lambda in VPC
- CKV_AWS_116: Lambda DLQ
- CKV_AWS_173: Lambda env var encryption (KMS)
- CKV_AWS_272: Lambda code-signing
- CKV_AWS_309: API Gateway route auth type (intentionally no auth for demo)
- CKV_AWS_338: CW log retention 1yr (demo uses 7d)
- CKV_AWS_158: CW log group KMS

All skipped — overkill for demo or intentionally insecure.

---

## Phase 2: Runbook Timing Fix

> **Prompt:** `how can I kick off the penetration test in step 10 if I haven't deployed the infrastructure or connected the github repo yet?`

**Response:** Acknowledged sequencing error. Updated pre-demo setup timing from "~20 min before" to "~2-4 hours before" since pentest takes 1-4 hours.

---

## Phase 3: Night-Before / Live Demo Split

> **Prompt:** `what if I was to have two repos, two copies of the demo code, and deploy one to completion the night before, and do the other live?`

**Response:** Suggested simpler approach — one environment deployed night before, live demo shows Console UI and does live design review + live PR (both fast), then walks through pre-completed pentest results. User agreed.

Updated runbook structure:
- **Night-before setup:** Deploy infra, create Agent Space, connect GitHub, run pentest, pre-push PR branch
- **Live demo (45 min):**
  - Opening — architecture & context (~5 min)
  - Part 1 — Design review, LIVE (~12 min, ~2 min wait)
  - Part 2 — Code review via live PR, LIVE (~13 min, ~2-3 min wait)
  - Part 3 — Pentest results walkthrough, pre-completed (~10 min)
  - Wrap-up & Q&A (~5 min)

Added step 11 (pre-push PR branch) and step 12 (pre-demo checklist).

---

## Phase 4: Terraform Standards Verification

> **Prompt:** `was the terraform created/reviewed using the terraform-standards agent skill?`

**Response:** Confirmed all 7 checklist items from terraform-standards were applied:
1. Naming: kebab-case `${local.prefix}-*` ✅
2. Required tags: all 5 in locals.tf via default_tags ✅
3. Modules vs resources: no module opportunities ✅
4. Variables vs data sources: appropriate usage ✅
5. Descriptions on all variables/outputs ✅
6. `terraform fmt` ✅
7. `terraform validate` ✅

---

## Phase 5: Account-Specific Values → tfvars

> **Prompt:** `let's update the terraform so that anything which is unique to my aws account is provided in a tfvars file`

**Response:** Only `domain_name` and `hosted_zone_id` were account-specific. Created `terraform.tfvars.example` as template. Repo `.gitignore` already had `*.tfvars` / `!*.tfvars.example`. Removed unused `data "aws_caller_identity"`. User then asked to rename to `terraform.tfvars` directly — done.

---

## Phase 6: Use Existing ACM Certificate

> **Prompt:** `there is already an acm certificate in place for the hosted zone I want to use. the arn is arn:aws:acm:us-east-1:997075698610:certificate/b1e29a1d-da3f-4a0f-8655-20a1f70a62ed`

**Response:** Replaced ACM certificate resource + DNS validation with `var.certificate_arn`. Added `data "aws_route53_zone"` for `aws.brightkey.cloud`. Set `domain_name` default to `securitydemo.aws.brightkey.cloud`. Removed 3 resources (ACM cert, validation record, validation).

---

## Phase 7: ACM Data Source

> **Prompt:** `use a data object for the acm cert as well, just look for a cert using the domain, and make sure it is the latest cert`

**Response:** Replaced `var.certificate_arn` with `data "aws_acm_certificate" "demo"` using `domain = "aws.brightkey.cloud"`, `statuses = ["ISSUED"]`, `most_recent = true`. Removed `certificate_arn` variable entirely. No account-specific values needed in tfvars anymore. Validated ✅.

---

## Current State

### Files in `security-agent-demo/`
```
main.tf                  — Provider, data sources (region, route53 zone, acm cert)
variables.tf             — 5 vars: env, project, region, costcenter, repo, domain_name
locals.tf                — Prefix, tags
app.tf                   — DynamoDB, Lambda+IAM, API Gateway, custom domain, CW logs
outputs.tf               — 5 outputs
lambda/notes_api.py      — Intentionally vulnerable notes API
send-test-requests.sh    — API verification script
design-doc.md            — Architecture doc for design review
diagram.py               — Diagram source
DEMO-RUNBOOK.md          — Full 45-min runbook (night-before + live demo)
CONVERSATION-LOG.md      — This file
terraform.tfvars         — Empty (no account-specific values needed)
generated-diagrams/      — diagram.png
```

### Key Design Decisions
- Route 53 zone: `aws.brightkey.cloud` (data source lookup)
- ACM cert: latest ISSUED cert for `aws.brightkey.cloud` (data source lookup)
- Domain: `securitydemo.aws.brightkey.cloud` (variable default)
- Region: us-east-1 (only region for Security Agent preview)
- No account-specific values in tfvars — everything is looked up

### Remaining Steps
1. `terraform apply` to deploy
2. Create GitHub repo and push `notes_api.py`
3. Create Security Agent Space in Console
4. Configure security requirements, enable pentest, connect GitHub
5. Run pentest (1-4 hours)
6. Pre-push PR branch
7. Dry run the full demo
