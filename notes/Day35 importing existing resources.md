# Day 35 — Importing Existing Resources (Deep Dive)

## What We Covered Today
Two approaches to importing existing Azure resources into Terraform, real-world discovery workflow, and drift detection.

---

## Why Import Exists

In real environments, not everything was created by Terraform. Resources get created:
- Manually in the Azure Portal
- Via Azure CLI by another team
- Before Terraform was adopted

`terraform import` brings these resources under Terraform management without destroying and recreating them.

---

## Pre-Requisite: Resource Block Must Exist First

Terraform needs a matching resource block in your `.tf` files **before** you can import. Without it, import fails immediately.

**Workflow when resource block doesn't exist yet:**
1. Discover the resource's actual attributes from Azure
2. Write a matching resource block in your `.tf` file
3. Then run the import

---

## Step 1 — Discover Actual Attributes via Azure CLI

When you don't have portal access, use Azure CLI:

```bash
az group show --name rg-terraform-state
```

Output:
```json
{
  "id": "/subscriptions/.../resourceGroups/rg-terraform-state",
  "location": "westeurope",
  "name": "rg-terraform-state",
  "tags": null
}
```

Use this output to write your matching resource block:
```hcl
resource "azurerm_resource_group" "terraform_state" {
  name     = "rg-terraform-state"
  location = "westeurope"
}
```

---

## Two Import Approaches

### Approach 1 — CLI Command (Old Way)
```bash
MSYS_NO_PATHCONV=1 terraform import \
  azurerm_resource_group.terraform_state \
  "/subscriptions/.../resourceGroups/rg-terraform-state"
```

**Problems:**
- Runs in terminal only — no Git record
- Team has no visibility — no code review
- Manual — not CI/CD friendly
- Six months later: no one knows why the resource is in state

### Approach 2 — Import Block (Modern Way, Terraform 1.5+)
Write directly in your `.tf` file:
```hcl
import {
  to = azurerm_resource_group.terraform_state
  id = "/subscriptions/.../resourceGroups/rg-terraform-state"
}
```

**Advantages:**
- Lives in Git → full history → team visibility
- Code review before it runs
- CI/CD pipeline runs it automatically
- Declarative — same philosophy as everything in Terraform

| | CLI import | import block |
|---|---|---|
| Recorded in Git? | ❌ No | ✅ Yes |
| Team visibility | ❌ None | ✅ Code review |
| CI/CD friendly | ❌ Manual | ✅ Automatic |
| After import | Nothing to clean up | Delete the block |

---

## Complete Import Workflow (End-to-End)

1. **Discover attributes** — `az resource show` or `az group show`
2. **Write resource block** in `.tf` file matching actual Azure attributes
3. **Write `import` block** in `.tf` file → commit to Git
4. **`terraform plan`** → confirms what will be imported
5. **`terraform apply`** → import executes
6. **`terraform plan` again** → verify **zero drift** = success ✅
7. **Delete the `import` block** → commit to Git
8. Resource is now permanently managed by Terraform

---

## Zero Drift — Why It Matters

After importing, `terraform plan` must show:
```
No changes. Infrastructure is up-to-date.
```

If it shows changes → your resource block doesn't exactly match Azure reality.

**Fix cycle:**
```
plan shows diff → fix resource block → plan again → repeat until zero diff
```

This is called **drift detection** — ensuring your code matches real-world infrastructure.

---

## Import Block Lifecycle

The `import` block is a **one-time operation**:
- Write it → it runs once during `terraform apply`
- If left in permanently → next pipeline run tries to import again → **error** (already in state)
- Always delete after successful import + zero drift confirmed

---

## IT Ops Analogy
Importing is like onboarding an undocumented server into your CMDB:
1. Discover what's actually on the server (`az show` = running a discovery scan)
2. Create the CMDB record matching what you found (resource block)
3. Link the record to the actual server (import)
4. Verify the record matches reality (zero drift check)
5. Remove the "pending import" flag (delete import block)

---

## What's Next — Day 36
Phase 5 Review — covering all of Days 31–35:
- What is Terraform state
- Remote backend on Azure Storage
- State locking mechanics
- `terraform state` commands
- Importing existing resources