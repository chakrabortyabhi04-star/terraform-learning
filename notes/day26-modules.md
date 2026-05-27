# Day 26 — Calling Modules from Root: Full Wiring

**Phase 4: Modular Design | Terraform Learning Journey**
**Date:** 2026-05-26

---

## 🎯 What We Learned Today

Today we stepped back and looked at the **bigger picture** — how the root module and child modules should be wired together cleanly. We removed duplication, fixed broken references, and understood when to keep flat resources vs move them into modules.

---

## 🧹 The Duplication Problem

When we started today, the root `main.tf` had:
- A **VNet resource** directly in root (lines 8–16)
- A **module call** that also creates a VNet (lines 18–25)

This is like having two teams managing the same server — one using a runbook, one doing it manually. The runbook wins. The manual work goes away.

**Rule:** Once a module handles a resource, remove it from root.

---

## 🔗 Fixing Broken References After Removing Root Resources

When you delete a resource from root, everything that referenced it **breaks**. Terraform will throw:

```
Error: Reference to undeclared resource
A managed resource "azurerm_virtual_network" "vnet" has not been declared in the root module.
```

**The fix:** Replace direct resource references with module output references.

| Before (broken) | After (fixed) |
|---|---|
| `azurerm_virtual_network.vnet.name` | `module.module_practice.vnet_name` |
| `azurerm_virtual_network.vnet.id` | `module.module_practice.vnet_id` |

**Pattern:** `module.<label>.<output_name>`

---

## 📤 Adding New Outputs to a Module

If you need an attribute that the module doesn't currently expose, the process is always **two steps**:

**Step 1:** Add the output to `modules/networking/outputs.tf`
```hcl
output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
```

**Step 2:** Reference it in root `outputs.tf`
```hcl
output "module_vnet_id" {
  value       = module.module_practice.vnet_id
  description = "Azure module VNet ID"
}
```

You can never skip Step 1 — the root can only consume what the module explicitly exposes.

---

## 🏗️ When to Keep Flat Resources vs Move to Module

Today we kept `subnet.tf` in root even though the module also creates a subnet. Here's the decision framework:

| Situation | Decision |
|---|---|
| Resource belongs to a logical group (VNet+Subnet+NSG) | Move to module |
| Resource is one-off and project-specific | Keep in root |
| Module only handles part of what you need | Keep the rest in root temporarily |
| Multiple environments need the same resource pattern | Move to module |

**Today's situation:** Module creates `subnet-web`. Root `subnet.tf` creates web, app, and database subnets. We kept `subnet.tf` because the module doesn't handle all three yet — that's Day 29 work.

---

## 🔍 Reading `terraform plan` for Duplication

When you see both root resources AND module resources of the same type in the plan:

```
# azurerm_subnet.subnet_1 will be created          ← root
# azurerm_subnet.subnet_2 will be created          ← root
# module.module_practice.azurerm_subnet.web        ← module
```

Ask yourself: **Are these doing the same job?** If yes — duplication. One needs to go.

---

## 📊 Current Output Structure (After Day 26)

```hcl
# Root outputs.tf
output "vnet_name"        → module.module_practice.vnet_name   # "vnet-dev"
output "module_vnet_name" → module.module_practice.vnet_name   # "vnet-dev"
output "module_vnet_id"   → module.module_practice.vnet_id     # (known after apply)
output "rg_id"            → azurerm_resource_group.terraformlearning.id
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Forgetting to update references after deleting a root resource

When you remove a resource from root, search your **entire project** for references to it. Files like `subnet.tf`, `nsg.tf`, `outputs.tf` may all reference it.

Quick way to find all references in VS Code: `Ctrl + Shift + F` → search for the resource name.

### ❌ Mistake 2: Trying to reference a module attribute that isn't an output

```hcl
# WRONG — vnet_id doesn't exist as module output yet
value = module.module_practice.vnet_id

# Error: This object does not have an attribute named "vnet_id"
```

Always add the output to the module's `outputs.tf` first before referencing it in root.

### ❌ Mistake 3: Keeping duplicate resources without realizing it

Root subnets + module subnets both showing in plan = duplication. Always scan the plan output for the same resource type appearing twice — once with `module.` prefix and once without.

### ❌ Mistake 4: Typos in output names

```
This object does not have an attribute named "vnet_nameter"
```

Terraform output names are case-sensitive and typo-sensitive. When you get this error, check the **exact** output name in your module's `outputs.tf`.

---

## 💡 Deeper Insight — The Modularization Journey

You're in the middle of modularization — and that's the messiest phase. You have:
- Some resources in modules ✅
- Some resources still in root ⚠️
- References being updated gradually

This is **normal in production**. Teams don't modularize everything at once. They move resources incrementally, fixing references as they go. The key is:

1. Move a resource to the module
2. Add outputs for what root needs
3. Update root references
4. Validate
5. Repeat

---

## 🧪 What We Validated Today

```bash
terraform validate
# Success! The configuration is valid.

terraform plan
# Changes to Outputs:
#   + module_vnet_id   = (known after apply)
#   + module_vnet_name = "vnet-dev"
#   + rg_id            = (known after apply)
#   + vnet_name        = "vnet-dev"
```

Module wiring confirmed working. ✅

---

## 🔮 Coming Up — Day 27

Production-standard folder structure:
- How real teams organize Terraform projects
- Separating environments properly
- Where modules live in a real repo
- What files belong where

---

## 📝 Key Takeaway

> Modularization is not a one-time event — it's a gradual process. Move resources into modules incrementally, fix references as you go, and validate at every step. The module is the runbook; root is the orchestrator.

---

*Notes written by Claude | Terraform Mentorship Day 26 | Phase 4: Modular Design*# Day 27 — Folder Structure: Production Standard

**Phase 4: Modular Design | Terraform Learning Journey**
**Date:** 2026-05-27

---

## 🎯 What We Learned Today

Today we zoomed out and looked at how real production teams organize Terraform projects. We explored HashiCorp's own examples on GitHub and made a practical improvement to our project structure.

---

## 📁 Production Standard Folder Structure

```
terraform-learning/
├── environments/           ← Each environment's tfvars
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/                ← Shared reusable modules
│   └── networking/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── notes/                  ← Learning notes
├── main.tf                 ← Root module
├── provider.tf
├── variable.tf
├── locals.tf
├── outputs.tf
└── .gitignore
```

---

## 📊 Structure Complexity Scale

There is no single "correct" structure. It depends on team size and complexity:

| Project Size | Recommended Structure |
|---|---|
| Solo / learning | Flat files, one folder |
| Small team, one environment | Flat files + `modules/` folder |
| Medium team, multiple environments | `environments/` folders + shared modules |
| Large team, many projects | Separate module repos + Terragrunt |

**Your current project = Level 2 moving toward Level 3. That's exactly right.**

---

## 🔑 Key Structural Decisions Explained

### Why `environments/` folder?

Before: `dev.tfvars`, `staging.tfvars`, `prod.tfvars` all dumped in root alongside `.tf` files.

After: All environment-specific values live in `environments/` — clean separation.

**Real benefit:** A new engineer immediately knows where to find environment configs without hunting through a flat file list.

### Why each environment eventually gets its own folder?

In large teams, each environment folder becomes its own Terraform root:
```
environments/
├── dev/
│   ├── main.tf       ← calls modules
│   ├── variables.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf       ← same modules, different values
    ├── variables.tf
    └── terraform.tfvars
```

Benefits:
- `dev` and `prod` have **separate state files** — completely isolated
- Engineers can work on `dev` without risking `prod`
- Each environment is independently deployable

---

## ⚠️ Important: tfvars Path Change

After moving tfvars to `environments/`, you must update the path when running commands:

```bash
# OLD (before Day 27)
terraform plan -var-file="dev.tfvars"

# NEW (after Day 27)
terraform plan -var-file="environments/dev.tfvars"
```

Terraform doesn't auto-discover tfvars from subfolders — you must specify the full path.

---

## 💡 What HashiCorp's Own Examples Teach Us

Looking at `github.com/hashicorp/terraform-provider-azurerm/tree/main/examples/virtual-networks/basic`:

- HashiCorp keeps examples **minimal** — just `main.tf` and `variables.tf`
- Provider block lives **inside `main.tf`** for simple examples — not a separate file
- Naming uses `var.prefix` pattern — same as your `var.environment`
- No `outputs.tf` or `locals.tf` unless needed

**Key lesson:** Don't over-engineer structure. Add complexity only when you need it.

---

## 🤔 Why Can't Provider Be Shared Across Environments?

You asked a great question today: *"Why do we write provider in multiple environments instead of referencing one shared provider?"*

**Honest answer:** Terraform doesn't support shared provider folders. Each environment folder is a completely independent Terraform root module — it needs its own `provider.tf`.

Two ways teams solve this:

| Solution | When to use |
|---|---|
| Copy `provider.tf` into each environment | Standard approach, simple projects |
| **Terragrunt** (wrapper tool) | Large teams, many environments — Phase 6+ |

This is a **known pain point** in Terraform that the community actively debates. You independently identified a real limitation of the tool. 💪

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Creating folders in the wrong location

Always check VS Code's breadcrumb or use `pwd` in terminal before creating folders. Easy to accidentally create `notes/environments/` instead of `environments/`.

**Fix:** Use terminal `mkdir` from the project root — more reliable than VS Code right-click.

### ❌ Mistake 2: Typos in folder names when using `mv`

```bash
mv dev.tfvars enviroments/    # ← typo! missing 'n'
# mv: cannot move 'dev.tfvars' to 'enviroments/': No such file or directory

mv dev.tfvars environments/   # ← correct
```

Always check the exact folder name with `ls` before running `mv`.

### ❌ Mistake 3: Forgetting to update `-var-file` path after moving tfvars

After moving tfvars to `environments/`, old commands will fail:
```bash
terraform plan -var-file="dev.tfvars"
# Error: No such file or directory
```

Update to:
```bash
terraform plan -var-file="environments/dev.tfvars"
```

### ❌ Mistake 4: Over-engineering structure too early

Don't create `environments/dev/`, `environments/prod/` folders with full Terraform configs until you actually need multi-environment isolation. Start simple, add structure as complexity grows.

---

## 🧪 What We Did Today

```bash
mkdir environments
mv dev.tfvars environments/
mv staging.tfvars environments/
mv prod.tfvars environments/
terraform validate
# Success! The configuration is valid.
```

Project structure improved. ✅

---

## 🔮 Coming Up — Day 28

Public registry modules:
- What the Terraform Registry is
- How to use community modules
- Calling a public module vs writing your own
- When to use public vs private modules

---

## 📝 Key Takeaway

> There is no single correct Terraform structure. Match your structure to your team size and complexity. Start flat, add folders as you grow. The goal is: a new engineer should understand the project in under 5 minutes.

---

*Notes written by Claude | Terraform Mentorship Day 27 | Phase 4: Modular Design*