# Day 37 — `count` and `for_each`

## The Core Problem `count` Solves

Before `count`, the instinct is to copy-paste the same resource block multiple times — one file per environment. This works until your manager says "add a tag to every resource group." Now you're editing 3 files. With 10 environments, you're editing 10 files. Every time.

**`count` = write the block once, tell Terraform how many times to create it.**

IT Ops analogy: Group Policy in Active Directory. Instead of configuring 50 machines one by one, you write the policy once and apply it to all 50.

---

## `count` — How It Works

```hcl
variable "environments" {
  type        = list(string)
  default     = ["dev", "staging", "prod"]
  description = "Deployment environment"
}

resource "azurerm_resource_group" "practice" {
  count    = length(var.environments)
  name     = "rg-${var.environments[count.index]}"
  location = "East US"
}
```

### Key concepts:
- `count = length(var.environments)` — never hardcode the number; let Terraform measure the list automatically
- `count.index` — Terraform gives each instance a number starting at `0`
- `var.environments[count.index]` — use the index to look up the name from the list

### What the plan shows:
```
azurerm_resource_group.practice[0] → rg-dev
azurerm_resource_group.practice[1] → rg-staging
azurerm_resource_group.practice[2] → rg-prod
```

---

## The Critical Problem with `count` — Index Shifting

This is the most important concept in this entire day.

You have 3 environments: `["dev", "staging", "prod"]`

Terraform tracks them as:
- `practice[0]` → dev
- `practice[1]` → staging
- `practice[2]` → prod

You remove `"staging"` from the middle. Your list becomes `["dev", "prod"]`.

Terraform now sees:
- `practice[0]` → dev (unchanged)
- `practice[1]` → prod (**was index 2, now index 1**)

**Terraform interprets this as: destroy prod, recreate it as index 1.**

You wanted to delete staging. You accidentally destroyed prod.

> This is why `count` is fragile for anything identity-based like environments, regions, or users.

---

## `for_each` — The Fix

`for_each` tracks resources by **name**, not position.

```hcl
resource "azurerm_resource_group" "practice" {
  for_each = toset(var.environments)
  name     = "rg-${each.key}"
  location = "East US"
}
```

### Key concepts:
- `for_each = toset(var.environments)` — converts list to a set (for_each requires a set or map, not a list)
- `each.key` — the current item's name (`"dev"`, `"staging"`, `"prod"`)
- No index needed — `each.key` IS the value, not a position number

### What the plan shows:
```
azurerm_resource_group.practice["dev"]     → rg-dev
azurerm_resource_group.practice["prod"]    → rg-prod
azurerm_resource_group.practice["staging"] → rg-staging
```

Remove `"staging"` now? Terraform only touches `practice["staging"]`. Dev and prod are completely stable.

---

## count vs for_each — Decision Rule

| | `count` | `for_each` |
|---|---|---|
| Tracks by | Index number `[0]`, `[1]`, `[2]` | Name/key `["dev"]`, `["prod"]` |
| Safe to remove middle item? | ❌ No — indexes shift | ✅ Yes — names don't shift |
| Use when | Resources are truly identical (e.g. 3 identical VMs) | Resources have unique identity (environments, regions, users) |

---

## Interview Answer

> *"I use `count` when I need multiple identical resources and the number is what matters — like 3 VMs of the same type. But `count` tracks resources by index, so removing an item from the middle of the list shifts all indexes — Terraform may destroy and recreate resources unintentionally, including production.*
>
> *`for_each` solves this by tracking resources by name instead of position. If I have dev, staging, and prod and I remove staging, Terraform only touches staging — dev and prod are completely stable.*
>
> *For anything environment-based or identity-based, I always prefer `for_each` for resource stability."*

---

## Files Changed Today
- `count_practice.tf` — created in root of terraform-learning repo

## Commands Used
```bash
touch count_practice.tf
terraform plan
git add count_practice.tf
git commit -m "Day 37: count and for_each practice"
git push origin master
```

---

## What's Next — Day 38
Dynamic blocks — generating nested blocks programmatically inside a resource.