# Day 25 — Module Inputs and Outputs (Deeper Dive)

**Phase 4: Modular Design | Terraform Learning Journey**
**Date:** 2026-05-25

---

## 🎯 What We Learned Today

Today we went deeper on the **communication layer** between root and child modules:
- How to consume module outputs in the root
- How to use complex types (`list(string)`) as module inputs
- The full input → resource → output → root flow

---

## 📞 How to Reference a Module Output in Root

Syntax:
```
module.<module_label>.<output_name>
```

**Real example from today:**
```hcl
# In root outputs.tf
output "module_vnet_name" {
  value       = module.module_practice.vnet_name
  description = "VNet name from networking module"
}
```

**How to find your module label:**
Always check your root `main.tf` — look for the `module {}` block. The label is right after the `module` keyword:
```hcl
module "module_practice" {   ← this is the label
  source = "./modules/networking"
  ...
}
```

---

## 🔄 The Full Communication Loop

```
root variable → module input → resource → module output → root output
     ↓                ↓            ↓              ↓              ↓
var.vnet_address   address_space  VNet        vnet_name    module_vnet_name
_space             = var.         created     = "vnet-dev"  = "vnet-dev"
                   address_space
```

In plain English:
1. Root passes `var.vnet_address_space` into module as `address_space`
2. Module uses it to create the VNet
3. Module exposes `vnet_name` as output
4. Root consumes it via `module.module_practice.vnet_name`

---

## 📦 Complex Input Types — `list(string)`

Not all variables are simple strings. `address_space` in Azure is a list of CIDR blocks.

**Wrong:**
```hcl
variable "address_space" {
  type = list    # ❌ incomplete — what type of list?
}
```

**Right:**
```hcl
variable "address_space" {
  type        = list(string)    # ✅ a list of strings
  description = "VNet address space CIDR blocks"
}
```

**Common Terraform variable types:**

| Type | Example value | Use case |
|---|---|---|
| `string` | `"dev"` | Names, locations, environment |
| `number` | `3` | Counts, ports, priorities |
| `bool` | `true` | Feature flags |
| `list(string)` | `["10.0.0.0/16"]` | Address spaces, availability zones |
| `map(string)` | `{env = "dev"}` | Tags, key-value pairs |

---

## 🔗 Passing a List Variable from Root to Module

**Root `variable.tf`** — define it once with a default:
```hcl
variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}
```

**Root `main.tf`** — pass it into the module:
```hcl
module "module_practice" {
  source        = "./modules/networking"
  address_space = var.vnet_address_space    # root var → module input
}
```

**Module `variables.tf`** — receive it:
```hcl
variable "address_space" {
  type        = list(string)
  description = "VNet address space CIDR blocks"
}
```

**Module `main.tf`** — use it:
```hcl
resource "azurerm_virtual_network" "vnet" {
  address_space = var.address_space    # no hardcoding!
}
```

---

## 🔍 Reading `terraform plan` Outputs Section

When you run `terraform plan`, look at the **Changes to Outputs** section:

```
Changes to Outputs:
  + module_vnet_name = "vnet-dev"       ← already computed from var.environment
  + rg_id            = (known after apply)
  + vnet_id          = (known after apply)
```

- `"vnet-dev"` is known immediately — computed from a variable
- `(known after apply)` — only known after Azure creates the resource (IDs, IPs)

This tells you which outputs Terraform can predict now vs which require actual deployment.

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Using resource reference syntax instead of module output syntax

```hcl
# WRONG — referencing root resource directly
value = azurerm_virtual_network.vnet.name

# WRONG — mixing resource and module syntax
value = module.azurerm_virtual_network.vnet.name

# RIGHT — module output syntax
value = module.module_practice.vnet_name
```

### ❌ Mistake 2: Incomplete list type

```hcl
# WRONG
type = list

# RIGHT
type = list(string)
```

### ❌ Mistake 3: Trailing space in output name

```hcl
# WRONG — space after name causes "Invalid output name" error
output "module_vnet_name " {

# RIGHT
output "module_vnet_name" {
```

Terraform names cannot contain spaces. Always check for trailing spaces if you get an "Invalid output name" error.

### ❌ Mistake 4: Creating a new root variable when one already exists

Before adding a new variable, always scan your existing `variable.tf`. You may already have what you need with a slightly different name (e.g. `vnet_address_space` vs `address_space`).

### ❌ Mistake 5: Forgetting to pass a new module variable in the root module call

When you add a new variable to a module's `variables.tf`, you must also:
1. Add/use a matching variable in root `variable.tf`
2. Pass it in the `module {}` block in root `main.tf`

Missing either step causes a validation error.

---

## 💡 Deeper Insight — Why `(known after apply)`?

Some output values show `(known after apply)` in the plan. This is because Azure generates them at creation time — IDs, IP addresses, hostnames.

Terraform is honest: it tells you "I don't know this yet — Azure will tell me after the resource exists."

Values computed purely from variables (like names using `var.environment`) are known immediately because Terraform can calculate them without talking to Azure.

---

## 🧪 What We Validated Today

```bash
terraform validate
# Success! The configuration is valid.

terraform plan
# Changes to Outputs:
#   + module_vnet_name = "vnet-dev"   ← module output flowing to root output ✅
```

---

## 🔮 Coming Up — Day 26

Calling modules from root — full wiring:
- Cleaning up the root module
- Understanding when to use modules vs flat resources
- Passing outputs from one module as inputs to another

---

## 📝 Key Takeaway

> The module communication pattern is always the same:
> **Root variable → Module input → Resource → Module output → Root output**
> Once you understand this flow, you can wire any modules together.

---

*Notes written by Claude | Terraform Mentorship Day 25 | Phase 4: Modular Design*