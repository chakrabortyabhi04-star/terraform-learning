# Day 40 — Conditionals

## The Ternary Expression

Terraform conditionals use a **ternary expression** — one line, three parts:

```hcl
condition ? value_if_true : value_if_false
```

Read it as: *"Is the condition true? If yes, use this. If no, use that."*

Same as Excel's IF formula:
```
=IF(condition, value_if_true, value_if_false)
```

Real example:
```hcl
var.environment == "prod" ? "Standard_D4s_v3" : "Standard_B1s"
```
If environment is prod → use `Standard_D4s_v3`. Otherwise → use `Standard_B1s`.

---

## The Most Important Pattern — Controlling Resource Creation

The most common real-world use of conditionals in Terraform:

```hcl
count = var.environment == "prod" ? 1 : 0
```

- `count = 1` → resource gets created
- `count = 0` → resource does not exist at all

This controls whether an entire resource gets deployed based on environment. No resource created = no Azure bill.

---

## Real Example — VM Only in Prod

In `vm.tf`, all three resources (Public IP, NIC, VM) should only exist in prod:

```hcl
resource "azurerm_public_ip" "Publicip" {
  count            = var.environment == "prod" ? 1 : 0
  name             = "publicip-${local.common_prefix}"
  ...
}

resource "azurerm_network_interface" "nic" {
  count               = var.environment == "prod" ? 1 : 0
  name                = "nic-${local.common_prefix}"
  ...
}

resource "azurerm_linux_virtual_machine" "vm" {
  count    = var.environment == "prod" ? 1 : 0
  name     = "vm-${local.common_prefix}"
  ...
}
```

Dev and staging deployments → no VM, no NIC, no Public IP. No cost. No clutter.

---

## Critical — Referencing count Resources

When a resource uses `count`, **every reference to it elsewhere must include `[count.index]`**.

Terraform throws this error if you forget:
```
Error: Missing resource instance key
Because azurerm_public_ip.Publicip has "count" set, 
its attributes must be accessed on specific instances.
```

**Wrong:**
```hcl
public_ip_address_id = azurerm_public_ip.Publicip.id
```

**Correct:**
```hcl
public_ip_address_id = azurerm_public_ip.Publicip[count.index].id
```

**Wrong:**
```hcl
network_interface_ids = [azurerm_network_interface.nic.id]
```

**Correct:**
```hcl
network_interface_ids = [azurerm_network_interface.nic[count.index].id]
```

> Rule: Once a resource has `count`, all references to it need `[count.index]` — Terraform doesn't know which instance you mean otherwise.

---

## Ternary vs lookup() — When to Use Which

| Scenario | Use |
|---|---|
| 2 outcomes (prod vs non-prod) | Ternary `? :` |
| 3+ outcomes (dev, staging, prod all different) | `lookup()` with a map |

**Ternary for 2 outcomes:**
```hcl
size = var.environment == "prod" ? "Standard_D4s_v3" : "Standard_B1s"
```

**lookup() for 3+ outcomes:**
```hcl
size = lookup(var.vm_sizes, var.environment, "Standard_B1s")
```

Where:
```hcl
variable "vm_sizes" {
  default = {
    dev     = "Standard_B1s"
    staging = "Standard_B2s"
    prod    = "Standard_D4s_v3"
  }
}
```

---

## Interview Answer

> *"In Terraform, conditionals use the ternary pattern — `condition ? value_if_true : value_if_false`. The most powerful use is controlling whether a resource gets created at all using `count = var.environment == "prod" ? 1 : 0`. Count zero means the resource doesn't exist. This is how we avoid spinning up expensive resources like VMs and VPN Gateways in dev and staging environments. One important rule — when a resource uses count, all references to it in other resources must use `[count.index]` to specify which instance you mean, otherwise Terraform throws a missing resource instance key error."*

---

## Files Changed Today
- `vm.tf` — added `count = var.environment == "prod" ? 1 : 0` to all three resources, updated references to use `[count.index]`

## Commands Used
```bash
terraform validate
git add vm.tf
git commit -m "Day 40: conditionals - count based resource creation"
git push origin master
```

---

## What's Next — Day 41
Data sources — referencing existing Azure resources that Terraform didn't create, without importing them into state.