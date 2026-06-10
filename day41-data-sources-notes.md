# Day 41 — Data Sources

## The Problem Data Sources Solve

You join a new company. Azure already has a Resource Group, VNet, and Key Vault — created manually or by another team. You need to deploy new resources **into** that existing infrastructure.

You have two options:
1. **Import** — Terraform takes ownership. Can modify or destroy the resource.
2. **Data source** — Terraform just reads. No ownership. Cannot destroy.

For infrastructure owned by other teams — always use data sources. Never import what you don't own.

---

## Resource vs Data — The Key Difference

| | `resource` block | `data` block |
|---|---|---|
| Creates in Azure? | ✅ Yes | ❌ No |
| Terraform owns it? | ✅ Yes | ❌ No |
| Can Terraform destroy it? | ✅ Yes | ❌ No |
| When does it act? | On apply | On plan (reads Azure) |
| Use when | You're creating new infrastructure | Referencing existing infrastructure |

---

## Syntax — Declaring a Data Source

```hcl
data "azurerm_resource_group" "existing_rg" {
  name = "rg-dev-terraform-learning"
}
```

- Keyword `data` instead of `resource`
- Resource type: `azurerm_resource_group`
- Label: `existing_rg` (your reference name in code)
- `name`: the actual name that exists in Azure

For a VNet (needs resource group too):
```hcl
data "azurerm_virtual_network" "existing_vnet" {
  name                = "vnet-dev-terraform-learning"
  resource_group_name = "rg-dev-terraform-learning"
}
```

---

## Syntax — Referencing a Data Source

Pattern: `data.resource_type.label.attribute`

```hcl
# Reference the resource group name
resource_group_name = data.azurerm_resource_group.existing_rg.name

# Reference the resource group location
location = data.azurerm_resource_group.existing_rg.location

# Reference the VNet address space
value = data.azurerm_virtual_network.existing_vnet.address_space
```

Compare to resource references: `azurerm_resource_group.terraformlearning.name`
Data references add the `data.` prefix: `data.azurerm_resource_group.existing_rg.name`

---

## Important — Data Sources Require Real Resources

`terraform validate` only checks syntax — it doesn't contact Azure.

`terraform plan` actually connects to Azure and looks up the resource. If the resource doesn't exist in Azure, Terraform throws:

```
Error: Resource Group "rg-dev-terraform-learning" was not found
```

> Rule: The resource must already exist in Azure before a data source can reference it.

This is fundamentally different from `resource` blocks — which create things that don't exist yet.

---

## Real World Use Cases

**Referencing network team's VNet:**
```hcl
data "azurerm_virtual_network" "hub_vnet" {
  name                = "vnet-hub-prod"
  resource_group_name = "rg-network-prod"
}

resource "azurerm_subnet" "my_subnet" {
  virtual_network_name = data.azurerm_virtual_network.hub_vnet.name
  resource_group_name  = data.azurerm_virtual_network.hub_vnet.resource_group_name
  ...
}
```

**Reading Key Vault secrets owned by security team:**
```hcl
data "azurerm_key_vault" "existing" {
  name                = "kv-prod-secrets"
  resource_group_name = "rg-security-prod"
}
```

---

## Interview Answer

> *"Data sources in Terraform let you reference existing Azure resources without importing them into state. The key difference is ownership — a `resource` block means Terraform owns and can destroy the resource, while a `data` block just reads it. Terraform cannot modify or destroy a data source. This is important when working with infrastructure owned by other teams — like a network team's VNet or a security team's Key Vault. You just read what you need without risking accidental destruction. One important rule: the resource must already exist in Azure at plan time, because data sources look up real infrastructure during `terraform plan`."*

---

## Files Changed Today
- `data_practice.tf` — created with two data sources and one output block

## Commands Used
```bash
touch data_practice.tf
terraform validate
terraform plan
git add data_practice.tf
git commit -m "Day 41: data sources practice"
git push origin master
```

---

## What's Next — Day 42
Phase 6 Review — scenario-based questions covering count, for_each, dynamic blocks, functions, conditionals, and data sources. Final checkpoint before Phase 7 (CI/CD with GitHub Actions).