# AWS Security Agent Demo Runbook

**Duration:** ~45 minutes
**Region:** us-east-1 (only supported region for Security Agent preview)

---

## Night-Before Setup

> Complete ALL steps below the night before the demo. The penetration test takes 1-4 hours, so everything must be deployed and running in advance. During the live demo, you'll do a live design review, a live code review PR, and walk through the pre-completed pentest results.

### 1. Create a GitHub Repository

1. Create a new **private** GitHub repo (e.g., `security-agent-demo-app`)
2. Push the `lambda/notes_api.py` file to the repo root:
   ```bash
   cd /tmp && mkdir security-agent-demo-app && cd security-agent-demo-app
   git init
   cp /path/to/security-agent-demo/lambda/notes_api.py .
   git add . && git commit -m "Initial commit — notes API"
   git remote add origin git@github.com:<your-org>/security-agent-demo-app.git
   git branch -M main && git push -u origin main
   ```

### 2. Set Terraform Variables

Copy the example and fill in your values:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
hosted_zone_name = "example.com"              # Your Route 53 hosted zone
domain_name      = "securitydemo.example.com"  # Your subdomain
```

Prerequisites:
- A Route 53 hosted zone in your account
- An ACM certificate (ISSUED) covering that zone domain (e.g., `*.example.com`)

### 3. Deploy Infrastructure

```bash
cd security-agent-demo
terraform init
terraform plan
terraform apply
```

### 4. Verify Working State

```bash
./send-test-requests.sh
```

Confirm all 6 tests pass and the API responds on your custom domain.

### 5. Create Security Agent Space (Console)

> **Docs:** https://docs.aws.amazon.com/securityagent/latest/userguide/setup-security-agent.html

1. Go to **AWS Console → Security Agent** (https://us-east-1.console.aws.amazon.com/securityagent/)
2. Click **Set up Security Agent**
3. Agent Space name: `demo-notes-api`
4. Description: `Vulnerable notes API for Security Agent demo`
5. User access: **IAM-only access** (simplest for demo)
6. Permissions: **Create default role**
7. Click **Set up**
8. Wait for setup to complete (~1-2 min)

### 6. Configure Security Requirements

1. In the left nav, go to **Security requirements**
2. Enable **AWS managed requirements** (these cover OWASP Top 10, auth, encryption, etc.)
3. Optionally create a custom requirement:
   - Name: `Input Validation Required`
   - Description: `All API endpoints must validate and sanitize user input before processing. No raw user input should be passed directly to database queries or external service calls.`

### 7. Enable Penetration Testing

1. Go to **Agent Spaces** → select `demo-notes-api`
2. Click **Enable penetration test**
3. Add target domain: your subdomain (e.g., `securitydemo.example.com`)
4. Verify domain ownership:
   - If domain is in the same AWS account's Route 53: auto-verified
   - Otherwise: add the TXT record shown to your DNS
5. Use the default IAM role
6. Click **Enable**

### 8. Connect GitHub Repository

1. In the Agent Space, look for the GitHub connection banner or go to **Integrations**
2. Click **Create new registration** → select **GitHub** → **Next**
3. Click **Install and authorize** — redirects to GitHub
4. Select your org/user → select the `security-agent-demo-app` repo
5. Click **Install & Authorize**
6. Back in AWS: name the registration, confirm account type
7. Select the repo for penetration testing context
8. Enable **Pentest remediation enabled** on the repo
9. Click **Connect**

### 9. Enable Code Review

1. In the Agent Space, click **Enable code review**
2. Select the `security-agent-demo-app` repo
3. Enable code review for the repo

### 10. Run Penetration Test

1. Click **Web app** tab → **Admin access** to open the Security Agent Web Application
2. Click **Penetration Test** → **Create your first penetration test**
3. Select your verified domain
4. Select the IAM role and log group
5. Enable **Automatic code remediation**
6. Attach the GitHub repo for source code context
7. Upload `design-doc.md` as additional context
8. Click **Create and execute**
9. Wait for completion (1-4 hours) — verify findings are populated before demo day

### 11. Prepare the Code Review PR Branch

Create the branch but do NOT open the PR yet — you'll do that live:

```bash
cd /tmp/security-agent-demo-app
git checkout -b feature/add-admin-endpoint
```

Add this inside the `handler` function in `notes_api.py`, before the `else` clause:

```python
        elif path == "/admin/users" and method == "GET":
            # Admin endpoint for user management
            result = table.scan()
            return response(200, {"users": result["Items"]})
```

```bash
git add . && git commit -m "Add admin endpoint for user management"
git push origin feature/add-admin-endpoint
```

### 12. Pre-Demo Checklist

- [ ] API responds on custom domain (`./send-test-requests.sh`)
- [ ] Security Agent Space exists with security requirements configured
- [ ] Pentest completed with findings visible
- [ ] GitHub repo connected with code review enabled
- [ ] `feature/add-admin-endpoint` branch pushed (PR not yet created)
- [ ] `design-doc.md` ready to upload
- [ ] Architecture diagram ready to show (`generated-diagrams/diagram.png`)

---

## Live Demo

### Opening — Architecture & Context (~5 min)

**Talking Points (2 min):**
- AWS Security Agent is a **frontier agent** — autonomous, multi-step reasoning for application security
- Three capabilities: design review, code review, penetration testing
- Understands your **application context** — not just generic scanning
- Available at **no cost during preview** in us-east-1
- Operates across AWS, on-prem, hybrid, and multi-cloud

**Show the Architecture (3 min):**
1. Show the architecture diagram (`generated-diagrams/diagram.png`)
2. Walk through: Route 53 → ACM → API Gateway → Lambda → DynamoDB
3. "This is a simple notes API — but it has several intentional security issues"
4. Briefly show the API working: `curl https://securitydemo.example.com/health`
5. Show the Security Agent Console — the Agent Space, security requirements, connected GitHub repo

---

### Part 1: Design Security Review — LIVE (~12 min)

**Talking Points (2 min):**
- Security Agent reviews architecture docs *before code is written*
- Checks against your org's security requirements — not just generic best practices
- Catches insecure designs early, when they're cheapest to fix

**Run a Live Design Review (10 min):**
1. In the Security Agent Web Application, click **Create design review**
2. Name: `Notes API Design Review`
3. Upload `design-doc.md`
4. Click **Start design review**
5. Wait for results (~1-2 min)

**Walk through findings:**
- **Non-compliant:** No authentication — the design explicitly says "does not implement authentication"
- **Non-compliant:** SSRF risk — the `/fetch` endpoint proxies arbitrary URLs
- **Non-compliant:** No input validation — design says "deferred to future iteration"
- **Non-compliant:** Overly permissive CORS — allows all origins
- **Insufficient data:** May flag encryption or logging gaps not detailed in the doc

**Key message:** "Security Agent caught these issues *before any code was written*. In a real workflow, the design would go back to the team for revision before development starts."

---

### Part 2: Code Security Review — LIVE (~13 min)

**Talking Points (2 min):**
- Security Agent integrates directly with GitHub
- Auto-reviews PRs against your org's security requirements AND common vulnerabilities
- Developers get remediation guidance right in the PR — no context switching

**Create the PR Live (3 min):**
1. Open GitHub in the browser
2. Navigate to the `security-agent-demo-app` repo
3. Create a new PR: `feature/add-admin-endpoint` → `main`
4. Title: "Add admin endpoint for user management"
5. Submit the PR

**Show the Code Review (8 min):**
1. Security Agent will post a comment within ~2-3 min:
   - Initial comment: "Analysis in progress..."
   - Final review with all security findings
2. Walk through the findings:
   - **No authentication** on the admin endpoint
   - **Data exposure** — scanning entire table and returning all items
   - **Missing input validation** (inherited from existing code)
   - **Security requirement violations** — whatever custom requirements you defined
3. Show the remediation guidance — specific to your code, not generic advice

**Key message:** "Every PR gets reviewed automatically. The security team defined the rules once, and the agent enforces them across all repos. No manual review bottleneck."

---

### Part 3: Penetration Testing — Pre-Completed Walkthrough (~10 min)

**Talking Points (2 min):**
- Traditional pentests take weeks to schedule and days to execute
- Security Agent runs on-demand, creates a customized attack plan from your app context
- Tests against OWASP Top 10 with multi-step attack chains
- Provides ready-to-implement code fixes and auto-creates PRs
- "I kicked off this pentest earlier — let me show you what it found"

**Walk Through Pentest Results (8 min):**
1. In the Security Agent Web Application, go to **Penetration Test**
2. Select the completed test run

**Overview tab:**
- Show test duration, status, discovered endpoints
- Show severity breakdown (expect Critical/High findings)

**Logs tab:**
- Show how the agent discovered endpoints
- Show the multi-step attack chains it executed
- Point out how it adapted based on responses

**Findings tab — walk through key findings:**

| Expected Finding | Severity | Description |
|---|---|---|
| SSRF via /fetch | Critical | Agent discovers it can fetch arbitrary URLs including internal endpoints |
| Missing Authentication | High | No auth on any endpoint — agent accesses all data freely |
| IDOR | High | Agent accesses other users' notes by changing userId parameter |
| Verbose Error Disclosure | Medium | Stack traces and internal config leaked in error responses |
| Missing Security Headers | Medium | No CSP, X-Frame-Options, etc. |

3. **Show remediation:**
   - Click a finding → show the detailed description, steps to reproduce, impact
   - Show the auto-generated PR with code fixes (if remediation was enabled)
   - Walk through the fix code — it's specific to your application, not generic advice

**Key message:** "The agent found real, exploitable vulnerabilities — not theoretical risks. It provides the exact code fix and creates the PR. Your developers can merge the fix immediately."

---

### Wrap-Up & Q&A (~5 min)

**Recap (1 min):**
- **Design review** caught architectural security gaps before code was written
- **Code review** flagged vulnerabilities in a PR automatically, with remediation guidance
- **Penetration testing** found exploitable issues in the live app and generated code fixes
- All three capabilities use the same application context — requirements defined once, enforced everywhere

**Q&A (4 min):**

**Q: What can it pentest?**
A: Live web applications and APIs accessible via HTTPS. You verify domain ownership first.

**Q: Can it test internal/private apps?**
A: Yes — configure VPC access so the agent can reach private endpoints.

**Q: What about non-AWS apps?**
A: It works across AWS, on-prem, hybrid, and multi-cloud. It tests the application, not the infrastructure.

**Q: How long does a pentest take?**
A: Typically 1-4 hours depending on application complexity. Design and code reviews are minutes.

**Q: Does it replace human pentesters?**
A: It augments them. Use it for continuous testing across all apps; reserve human experts for the most critical assessments.

**Q: What code repos does it support?**
A: GitHub currently. Code review works on PRs; pentest remediation creates PRs.

**Q: Cost?**
A: Free during preview. Check https://aws.amazon.com/security-agent/ for GA pricing.

**Q: How does it differ from Inspector/GuardDuty?**
A: Inspector scans for known CVEs in packages/images. GuardDuty monitors for threats at the infrastructure level. Security Agent understands your *application* — its design, code, and runtime behavior — and tests it like a human pentester would.

---

## Cleanup

```bash
# Remove Terraform resources
terraform destroy

# Delete Agent Space via Console
# https://us-east-1.console.aws.amazon.com/securityagent/

# Delete GitHub repo if created for demo
```

---

## Reference Links

- **Security Agent Console:** https://us-east-1.console.aws.amazon.com/securityagent/
- **User Guide:** https://docs.aws.amazon.com/securityagent/latest/userguide/what-is.html
- **Capabilities:** https://docs.aws.amazon.com/securityagent/latest/userguide/agent-capabilities.html
- **Quickstart:** https://docs.aws.amazon.com/securityagent/latest/userguide/quickstart.html
- **Setup Guide:** https://docs.aws.amazon.com/securityagent/latest/userguide/setup-security-agent.html
- **Enable Pentest:** https://docs.aws.amazon.com/securityagent/latest/userguide/enable-penetration-test.html
- **Create Pentest:** https://docs.aws.amazon.com/securityagent/latest/userguide/perform-penetration-test.html
- **Review Findings:** https://docs.aws.amazon.com/securityagent/latest/userguide/review-penetration-findings.html
- **Code Review in GitHub:** https://docs.aws.amazon.com/securityagent/latest/userguide/review-code-findings-github.html
- **Security Best Practices:** https://docs.aws.amazon.com/securityagent/latest/userguide/security-best-practices.html
- **Blog — Launch Announcement:** https://aws.amazon.com/blogs/aws/new-aws-security-agent-secures-applications-proactively-from-design-to-deployment-preview/
- **Blog — re:Invent Security Innovations:** https://aws.amazon.com/blogs/security/aws-launches-ai-enhanced-security-innovations-at-reinvent-2025/
- **Product Page:** https://aws.amazon.com/security-agent
- **What's New Announcement:** https://aws.amazon.com/about-aws/whats-new/2025/12/aws-security-agent-preview/
