# Day 23 — What Modules Are and Why They Exist

**Phase 4: Modular Design | Terraform Learning Journey**
**Date:** 2026-05-22

---

## 🎯 What We Learned Today

### The Core Problem Modules Solve

Before modules, if you needed the same infrastructure for two projects — say `terraform-learning` and a new `payments` project — you would:

1. Copy all your `.tf` files manually
2. Do find-and-replace on names
3. Hope you didn't miss anything
4. Maintain **two separate codebases** that drift apart over time

This is painful, error-prone, and doesn't scale.

**Modules solve this by letting you define infrastructure once and reuse it many times.**

---

## 🧠 The GPO Analogy (Your Mental Model)

Think of Terraform modules exactly like **Group Policy Objects (GPO)** in Active Directory:

| IT Ops World | Terraform World |
|---|---|
| GPO Template | Module (a folder of `.tf` files) |
| Laptop/OU receiving the GPO | Root `main.tf` calling the module |
| GPO policy settings (password length, USB rules) | Input variables |
| Configured laptop (end result) | Output values |

> **Key insight:** You define the GPO once. You apply it to many OUs. Each OU can have slightly different settings — but the same base template is used everywhere. Terraform modules work identically.

---

## 📁 Module Folder Structure (Production Standard)

```
terraform-learning/
├── modules/                    ← All local modules live here
│   └── networking/             ← One module = one folder
│       ├── main.tf             ← Resources go here
│       ├── variables.tf        ← Inputs (what the caller must pass in)
│       └── outputs.tf          ← What the module gives back
├── main.tf                     ← Root module — calls child modules
├── provider.tf
├── variable.tf
├── locals.tf
├── outputs.tf
└── ...
```

### Why local modules (not remote) at this stage?

- **Local modules** live inside your project folder — they ship with your repo when someone clones it
- **Remote modules** live in a separate Git repo or Terraform Registry — used when multiple teams share the same module
- Rule of thumb: start local, go remote when multiple projects need the same module

---

## 🔑 The Three Files Every Module Needs

### 1. `variables.tf` — The Inputs (GPO policy settings)

These are the values the **caller must pass in**. The module itself doesn't hardcode them.

```hcl
variable "location" {
  type        = string
  description = "Azure region for resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to deploy into"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
}
```

### 2. `main.tf` — The Resources (GPO logic)

Resources reference **only** variables defined in the module's own `variables.tf`. No hardcoded values. No references to root module resources.

```hcl
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}
```

### 3. `outputs.tf` — The Return Values (what the GPO reports back)

Exposes resource attributes so the root module can use them.

```hcl
output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}
```

---

## 📞 How to Call a Module from Root `main.tf`

```hcl
module "module_practice" {
  source = "./modules/networking"      # Path to the module folder

  location            = var.location
  resource_group_name = var.resource_group_name
  environment         = var.environment
}
```

**Anatomy of a module call:**
- `module "name"` — you choose the label; used to reference outputs later
- `source` — relative path to the module folder (always starts with `./` for local)
- Everything else — input variables you're passing into the module

---

## ⚡ Key Commands

```bash
# After adding or changing a module, always re-init
terraform init

# Validate your configuration is syntactically correct
terraform validate
```

**Why `terraform init` again after adding a module?**
Terraform needs to register the new module source. You'll see:
```
Initializing modules...
- module_practice in modules\networking
```
If you skip `init` after adding a module, Terraform will error.

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Referencing root resources directly inside a module

```hcl
# WRONG — inside modules/networking/main.tf
resource_group_name = azurerm_resource_group.terraformlearning.name
```

The module has no idea what `azurerm_resource_group.terraformlearning` is — that resource lives in the root module. This will **break**.

**Fix:** Pass it as an input variable instead:
```hcl
# RIGHT — module receives it as a variable
resource_group_name = var.resource_group_name
```

### ❌ Mistake 2: Using `local.` values inside a module that don't exist there

```hcl
# WRONG — inside the module
name = "vnet-${local.common_prefix}"
```

`local.common_prefix` is defined in your root `locals.tf` — not inside the module. The module has its own scope.

**Fix:** Either pass the prefix as an input variable, or let the module compute its own naming from input variables.

### ❌ Mistake 3: Forgetting to run `terraform init` after adding a module

You'll get an error like:
```
Error: Module not installed
```
Always run `terraform init` after adding, removing, or changing module sources.

### ❌ Mistake 4: Writing module files in the wrong file

Easy to do when tabs are open — always check the breadcrumb at the top of VS Code:
```
modules > networking > outputs.tf
```
Make sure you're editing the right file before writing code.

### ❌ Mistake 5: Putting the module completely outside your project folder

Instinct says "make it reusable = put it outside". But if it's outside your Git repo, it won't clone with your project. Start local, go remote only when multiple projects need it.

---

## 🧪 What We Validated Today

Running `terraform validate` returned:
```
Success! The configuration is valid.
```

This confirms:
- Module folder structure is correct
- Variable references are valid
- Module call in root `main.tf` is syntactically correct
- Source path `./modules/networking` is resolvable

---

## 💡 Deeper Insight — You Already Had a Module

Your root `terraform-learning/` folder **is already a module** — Terraform calls it the **root module**. Every Terraform project is a module. What we built today is called a **child module**.

The only difference:
- Root module = entry point, called by `terraform` CLI
- Child module = called by another module using `module {}` block

---

## 🔮 Coming Up — Day 24

We'll expand the networking module to include:
- Subnets inside the VNet
- NSG with security rules
- How resources inside a module reference each other
- Moving your existing `subnet.tf` and `nsg.tf` logic into the module cleanly

---

## 📝 In Your Own Words

> *"A module is like writing a configuration once and reusing it many times — just changing the inputs each time, like a GPO template applied to different departments."*
> — Abhishek, Day 23

That's the right mental model. Hold onto it.

---

*Notes written by Claude | Terraform Mentorship Day 23 | Phase 4: Modular Design*