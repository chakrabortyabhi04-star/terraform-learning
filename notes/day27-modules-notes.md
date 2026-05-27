# Day 27 — Folder Structure: Production Standard

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