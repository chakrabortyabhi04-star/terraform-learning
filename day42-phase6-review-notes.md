# Day 42 — Phase 6 Review

## Phase 6 Complete — All Concepts

| Day | Concept | One Line Summary |
|---|---|---|
| 37 | `count` vs `for_each` | Index vs name tracking |
| 38 | Dynamic blocks | Generate nested blocks from variables |
| 39 | Functions | `lookup`, `merge`, `flatten`, `toset` |
| 40 | Conditionals | `count = 0` kills a resource |
| 41 | Data sources | Read without owning |

---

## Q1 — count vs for_each

**Interview Answer:**
> "`count` creates multiple instances tracked by index number — `resource[0]`, `resource[1]`, `resource[2]`. The problem is if you remove an item from the middle of the list, all indexes shift and Terraform may destroy and recreate resources unintentionally — including production.
>
> `for_each` tracks resources by name instead of position — `resource["dev"]`, `resource["staging"]`, `resource["prod"]`. Removing one item only touches that item, nothing else shifts.
>
> Rule: use `count` for truly identical resources where order doesn't matter. Use `for_each` for anything with unique identity — environments, regions, users."

**Code:**
```hcl
# count — fragile
resource "azurerm_resource_group" "practice" {
  count    = length(var.environments)
  name     = "rg-${var.environments[count.index]}"
  location = "East US"
}
# Tracks as: practice[0], practice[1], practice[2]

# for_each — stable
resource "azurerm_resource_group" "practice" {
  for_each = toset(var.environments)
  name     = "rg-${each.key}"
  location = "East US"
}
# Tracks as: practice["dev"], practice["staging"], practice["prod"]
```

---

## Q2 — Dynamic Blocks

**Interview Answer:**
> "Dynamic blocks let you generate repeated nested blocks inside a resource automatically from a variable — instead of writing them manually.
>
> For example, an NSG can have multiple `security_rule` blocks. Without dynamic blocks you copy-paste each rule manually. With dynamic blocks you define your rules as a `list(object())` variable and Terraform generates all the blocks automatically.
>
> The key syntax difference from `for_each` on resources is the iterator name — in a dynamic block the iterator matches the block name itself. So `dynamic "security_rule"` uses `security_rule.value.name`, not `each.value.name`.
>
> The real benefit is maintainability — adding a new rule means just adding one object to the variable. The module code never needs to change."

**Code:**
```hcl
dynamic "security_rule" {
  for_each = var.security_rules
  content {
    name     = security_rule.value.name
    priority = security_rule.value.priority
    ...
  }
}
```

---

## Q3 — Terraform Functions

**Interview Answer:**
> "`length()` — returns the count of items in a list. Use with `count = length(var.environments)` so the number never needs to be hardcoded.
>
> `toset()` — converts a list to a set, removing duplicates. Required for `for_each` because it doesn't accept lists directly.
>
> `lookup(map, key, default)` — finds a value in a map by key, returns a default if the key doesn't exist. Like Excel VLOOKUP. Use for different values per environment with a safe fallback.
>
> `merge(map1, map2)` — combines two maps into one. Second map wins on duplicate keys. Use to add resource-specific tags on top of common_tags.
>
> `flatten()` — squashes a list of lists into a single flat list. Useful when combining subnet ranges from multiple sources."

**Code:**
```hcl
count    = length(var.environments)
for_each = toset(var.environments)
size     = lookup(var.vm_sizes, var.environment, "Standard_B1s")
tags     = merge(local.common_tags, { data_sensitivity = "high" })
subnets  = flatten([var.web_subnets, var.app_subnets])
```

---

## Q4 — Conditionals

**Interview Answer:**
> "Terraform conditionals use a ternary expression — `condition ? value_if_true : value_if_false`.
>
> The most powerful use is controlling whether a resource gets created at all: `count = var.environment == "prod" ? 1 : 0`. Count zero means the resource doesn't exist — saving cost in dev and staging.
>
> One important rule — when a resource uses `count`, every reference to it elsewhere must include `[count.index]`, otherwise Terraform throws a 'Missing resource instance key' error.
>
> For two outcomes use ternary. For three or more outcomes use `lookup()` with a map instead."

**Code:**
```hcl
# Resource only in prod
resource "azurerm_linux_virtual_machine" "vm" {
  count = var.environment == "prod" ? 1 : 0
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]
}

# Value based on environment
size = var.environment == "prod" ? "Standard_D4s_v3" : "Standard_B1s"
```

---

## Q5 — Data Sources

**Interview Answer:**
> "Data sources let you reference existing Azure resources without importing them into Terraform state. The key difference is ownership.
>
> A `resource` block means Terraform owns the resource — it can create, modify, and destroy it. A `data` block just reads the resource — Terraform has no ownership and cannot destroy it.
>
> This is critical when working with infrastructure owned by other teams. If the network team owns a VNet, I use a data source to read it safely without risking accidental destruction.
>
> One important rule — data sources connect to Azure at plan time. If the resource doesn't exist yet, Terraform throws a 'not found' error."

**Code:**
```hcl
# Declare
data "azurerm_virtual_network" "existing_vnet" {
  name                = "vnet-hub-prod"
  resource_group_name = "rg-network-prod"
}

# Reference
resource "azurerm_subnet" "my_subnet" {
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = data.azurerm_virtual_network.existing_vnet.resource_group_name
}
```

---

## Bonus — Tying Everything Together

**Interview Answer:**
> "I'd combine all Phase 6 concepts in a real production setup:
>
> `for_each` with `toset()` for environment resource groups — tracked by name, not index.
>
> Dynamic blocks for NSG security rules — adding rules only requires updating the variable, never the module.
>
> Conditionals for expensive resources — `count = var.environment == "prod" ? 1 : 0` keeps dev and staging costs low.
>
> `lookup()` for VM sizes — dev gets small, prod gets large, with a safe default fallback.
>
> `merge()` for tags — every resource inherits common tags but can add its own.
>
> Data sources for shared infrastructure — hub VNets and Key Vaults owned by other teams are read safely without ownership risk."

---

## What's Next — Phase 7
- Day 43: Terraform in CI/CD — GitHub Actions pipeline
- Day 44: Debugging — TF_LOG, plan analysis, common errors
- Day 45: Final project — full production infrastructure