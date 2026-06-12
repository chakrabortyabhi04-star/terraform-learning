# Day 43 — Terraform CI/CD with GitHub Actions

## What We Built

A pipeline that automatically runs `terraform validate` and `terraform plan` every time code is pushed to master — without touching the terminal once.

---

## Why CI/CD for Terraform?

In real DevOps teams, nobody runs `terraform plan` manually on their laptop in production. The pipeline does it automatically. This ensures:
- Every change is validated before it touches infrastructure
- The team sees the plan output before merging
- No "works on my machine" problems — the runner is always a clean, consistent environment

---

## File Structure

```
terraform-learning/
└── .github/
    └── workflows/
        └── terraform.yml
```

GitHub automatically picks up every `.yml` file in `.github/workflows/` — no registration needed.

---

## The Complete Workflow File

```yaml
name: Terraform workflow
on:
  push:
    branches:
      - master  # Triggers on any push to master

jobs:
  terraform:
    name: Terraform Plan and Apply
    runs-on: ubuntu-latest
    env:
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.13.3

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan
```

---

## Key Concepts — Explained at Point of Need

### Workflow
The entire `terraform.yml` file is one workflow. It has a name, a trigger, and jobs.

### Trigger (`on:`)
Defines what event causes the workflow to run. We use `push` to `master`. Other options: `pull_request`, `schedule`, `workflow_dispatch`.

### Runner (`runs-on:`)
A fresh Ubuntu VM that GitHub spins up for every run. It has nothing installed — no Terraform, no Azure CLI, nothing. That's why the first steps install everything needed.

> Analogy: Every pipeline run gets a brand new machine. Clean slate every time.

### Steps — `uses` vs `run`
- `uses:` — runs a pre-built GitHub Action (e.g. `actions/checkout@v4`, `hashicorp/setup-terraform@v3`)
- `run:` — runs a shell command directly (e.g. `terraform init`)

### Why Checkout is Step 1
The runner is a fresh VM with no files. `actions/checkout@v4` pulls your repo onto the runner so Terraform has code to work with.

### Why Pin Terraform Version
`terraform_version: 1.13.3` ensures the pipeline uses the exact same version as your local machine. Without pinning, it installs latest — which could behave differently.

### Environment Variables (`env:`)
Set at job level so every step automatically gets them. Terraform reads ARM_* variables for Azure authentication — same as when you export them locally.

---

## GitHub Secrets — Storing Credentials Safely

**Never hardcode credentials in YAML.** They get pushed to GitHub and anyone can see them.

**Solution: GitHub Secrets**
- Go to repo → Settings → Secrets and variables → Actions → New repository secret
- Add all four ARM variables as secrets
- Reference them in YAML as `${{ secrets.SECRET_NAME }}`
- GitHub injects the value at runtime — never visible in logs or code

**Four secrets needed:**
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET` ← must be the **Value**, not the Secret ID
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

---

## Common Errors Encountered

### Error 1 — invalid_client (HTTP 401)
```
Ensure the secret being sent is the client secret VALUE, not the client secret ID
```
Fix: Go to Azure Portal → App registrations → Certificates & secrets → create new secret → copy the **Value** column immediately.

### Error 2 — unauthorized_client (HTTP 400)
```
Application with identifier was not found in the directory
```
Fix: Wrong `ARM_CLIENT_ID` or `ARM_TENANT_ID` in GitHub Secrets. Verify against Azure Portal.

### Error 3 — Data source not found
```
Resource Group "rg-dev-terraform-learning" was not found
```
Expected — data sources require real Azure resources to exist. Learning files should not be in production pipelines.

---

## Pipeline Results

| Step | Status | Why |
|---|---|---|
| Set up job | ✅ | GitHub runner provisioned |
| Checkout | ✅ | Code pulled onto runner |
| Setup Terraform | ✅ | v1.13.3 installed |
| Terraform Init | ✅ | Backend connected, providers downloaded |
| Terraform Validate | ✅ | Syntax valid |
| Terraform Plan | ✅ | Plan generated (data source error is expected) |

---

## Interview Answer

> *"We store Azure Service Principal credentials as encrypted GitHub Secrets — ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, and ARM_TENANT_ID. In the workflow YAML we inject them as environment variables using `${{ secrets.SECRET_NAME }}` syntax. The runner never sees the actual values — GitHub injects them at runtime and masks them in logs.*
>
> *The pipeline runs on every push to master. It uses a fresh Ubuntu runner, checks out the code, installs the pinned Terraform version, then runs init, validate, and plan automatically. Nobody touches a terminal — the pipeline does everything.*
>
> *For production environments, the more secure approach is OIDC with Azure Managed Identity, which eliminates secret rotation entirely."*

---

## Files Changed Today
- `.github/workflows/terraform.yml` — created CI/CD pipeline

## Commands Used
```bash
mkdir -p .github/workflows
touch .github/workflows/terraform.yml
git add .github/workflows/terraform.yml
git commit -m "Day 43: Terraform CI/CD pipeline"
git push origin master
```

---

## What's Next — Day 44
Debugging — TF_LOG environment variable, reading plan output like a pro, common Terraform errors and how to diagnose them fast.