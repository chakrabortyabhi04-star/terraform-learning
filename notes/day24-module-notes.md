# Day 24 — Expanding the Module (Subnet + NSG)

**Phase 4: Modular Design | Terraform Learning Journey**
**Date:** 2026-05-23

---

## 🎯 What We Learned Today

Yesterday we built the skeleton of a module with just a VNet.
Today we added real networking resources — Subnet and NSG — and learned how resources **inside a module talk to each other**.

---

## 🔑 Golden Rule of Modules (Reinforced Today)

> **A module should never assume what exists outside it. Everything it needs must come in through variables.**

This is why we can't write:
```hcl
resource_group_name = azurerm_resource_group.terraformlearning.name
```
inside a module. That resource lives in the root — the module has no visibility into it.

Instead:
```hcl
resource_group_name = var.resource_group_name
```

The root passes the value in. The module stays self-contained.

---

## 🔗 How Resources Inside a Module Reference Each Other

Resources inside the same module reference each other **directly** — no variables needed for internal wiring. Same pattern as your root module.

| What you need | How to reference it |
|---|---|
| VNet name (for subnet) | `azurerm_virtual_network.vnet.name` |
| Subnet ID (for NSG association) | `azurerm_subnet.web.id` |
| NSG ID (for NSG association) | `azurerm_network_security_group.nsg1.id` |

This is the same `resource_type.resource_label.attribute` pattern you've always used — it works identically inside modules.

---

## 📁 Final Module Structure After Day 24

### `modules/networking/variables.tf`
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

### `modules/networking/main.tf`
Four resources — all internally wired, all using variables for external values:

- `azurerm_virtual_network` — uses `var.environment`, `var.location`, `var.resource_group_name`
- `azurerm_subnet` — references VNet via `azurerm_virtual_network.vnet.name`
- `azurerm_network_security_group` — uses `var.environment` for dynamic naming
- `azurerm_subnet_network_security_group_association` — wires subnet to NSG internally

### `modules/networking/outputs.tf`
```hcl
output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "azurerm_subnet" {
  value = azurerm_subnet.web.id
}

output "azurerm_network_security_group" {
  value = azurerm_network_security_group.nsg1.id
}
```

---

## 📖 How to Find Resource Attributes in Terraform Docs

This is a critical skill — always go to the docs before writing outputs.

**Steps:**
1. Go to `registry.terraform.io`
2. Click **Browse Providers** → search `azurerm` → click **hashicorp/azurerm**
3. Click **Documentation** tab
4. Search for the resource (e.g. `azurerm_subnet`) in the left sidebar
5. Click **Attributes Reference** section on the page
6. That section tells you exactly what attributes a resource exposes after creation

**What we found today:**
- `azurerm_subnet` exposes → `id`
- `azurerm_network_security_group` exposes → `id`

> **Rule:** Always check Attributes Reference — not Arguments Reference. Arguments are what you pass IN. Attributes are what Terraform exposes OUT after creation.

---

## 🔍 Reading `terraform plan` Output for Modules

When you run `terraform plan`, module resources appear with a special prefix:

```
# module.module_practice.azurerm_virtual_network.vnet will be created
# module.module_practice.azurerm_subnet.web will be created
# module.module_practice.azurerm_network_security_group.nsg1 will be created
# module.module_practice.azurerm_subnet_network_security_group_association.example will be created
```

The format is: `module.<module_label>.<resource_type>.<resource_label>`

This tells you:
- Which module the resource belongs to
- Exactly what will be created
- The resource names that will be used

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Writing module files in the wrong file
VS Code has multiple tabs open. Always check the **breadcrumb** at the top:
```
modules > networking > main.tf   ← module file ✅
main.tf .\                       ← root file ❌ (if you meant module)
```
Abhishek caught this himself today — good instinct!

### ❌ Mistake 2: Adding `.name` to a string variable
```hcl
# WRONG
resource_group_name = var.resource_group_name.name

# RIGHT
resource_group_name = var.resource_group_name
```
`var.resource_group_name` is already a string — it IS the name. You can't call `.name` on a string.

### ❌ Mistake 3: Hardcoding resource names inside a module
```hcl
# WRONG — not reusable
name = "example-nsg"

# RIGHT — dynamic, reusable
name = "nsg-web-${var.environment}"
```
If the name is hardcoded, every project using the module gets the same name. That breaks reusability.

### ❌ Mistake 4: Running `git push` before `git commit`
```bash
# WRONG order
git add .
git push        ← "Everything up to date" — nothing moved!

# RIGHT order
git add .
git commit -m "message"
git push
```
Git flow is always: **stage → commit → push**. Push without commit sends nothing.

### ❌ Mistake 5: Confusing Arguments Reference with Attributes Reference in docs
- **Arguments Reference** = what you write inside the resource block (inputs)
- **Attributes Reference** = what Terraform exposes after creation (outputs)

When writing module outputs, always look at **Attributes Reference**.

---

## 💡 Deeper Insight — Module Resource Naming in Plan

Notice how module resources get named differently in `terraform plan`:

```
# Root resource
azurerm_virtual_network.vnet

# Module resource  
module.module_practice.azurerm_virtual_network.vnet
```

This is Terraform's way of keeping namespaces separate. You could have a VNet in the root AND a VNet in the module — they don't conflict because the module prefix separates them.

This also means in the state file, module resources are tracked under their full path including the module label.

---

## 🧪 What We Validated Today

```bash
terraform validate
# Success! The configuration is valid.

terraform plan
# module.module_practice.azurerm_virtual_network.vnet will be created
# module.module_practice.azurerm_subnet.web will be created
# module.module_practice.azurerm_network_security_group.nsg1 will be created
# module.module_practice.azurerm_subnet_network_security_group_association.example will be created
```

Module planned successfully with all 4 resources. ✅

---

## 🔮 Coming Up — Day 25

We'll do a deeper dive into module inputs and outputs:
- Passing complex types (lists, maps) into modules
- Using module outputs in the root module
- Chaining modules together

---

## 📝 Key Takeaway

> Inside a module, resources reference each other directly using `resource_type.label.attribute` — exactly like the root module. Variables are only needed for values that come FROM OUTSIDE the module.

---

*Notes written by Claude | Terraform Mentorship Day 24 | Phase 4: Modular Design*