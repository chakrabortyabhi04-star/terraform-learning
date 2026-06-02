# Day 34 — Terraform State Commands (Hands-On)

## What We Covered Today
Hands-on practice with all four core `terraform state` commands, plus `terraform import` and `-target` flag.

---

## The Four Core State Commands

| Command | Purpose | Dangerous? |
|---|---|---|
| `terraform state list` | List all resources Terraform is tracking | ❌ Read-only |
| `terraform state show <resource>` | Inspect all attributes of a specific resource | ❌ Read-only |
| `terraform state mv <old> <new>` | Rename/move a resource in state | ⚠️ Writes to state |
| `terraform state rm <resource>` | Remove a resource from state tracking | ⚠️ Writes to state |

---

## Command Deep Dive

### terraform state list
Shows all resources Terraform is currently tracking.
```bash
terraform state list
```
Example output:
```
azurerm_resource_group.terraformlearning
module.vnet.data.azurerm_client_config.telemetry[0]
```
- Returns nothing if state is empty (not an error)
- Think of it as browsing the CMDB index

### terraform state show
Shows full detail of a specific resource — every attribute Terraform knows about it.
```bash
terraform state show azurerm_resource_group.terraformlearning
```
Example output:
```hcl
# azurerm_resource_group.terraformlearning:
resource "azurerm_resource_group" "terraformlearning" {
    id       = "/subscriptions/.../resourceGroups/rg-dev-terraform-learning"
    location = "westeurope"
    name     = "rg-dev-terraform-learning"
    tags     = {
      "environment" = "dev"
      "project"     = "terraform-learning"
    }
}
```
- `list` = CMDB index view
- `show` = opening a specific CI record — full detail

### terraform state rm
Removes a resource from Terraform state tracking. **Does NOT delete the resource from Azure.**
```bash
terraform state rm azurerm_resource_group.terraformlearning
```
Output:
```
Acquiring state lock...
Removed azurerm_resource_group.terraformlearning
Successfully removed 1 resource instance(s).
Releasing state lock...
```

**Critical behaviour:**
- Resource stays alive in Azure ✅
- Terraform loses all knowledge of it ✅
- Next `terraform plan` will try to CREATE it (thinks it's new) ⚠️
- This can cause conflicts if resource already exists in Azure ⚠️

**When would you use this?**
- Resource was deleted manually in Azure — remove stale reference from state
- Refactoring code — removing from one state before importing into another

### terraform state mv
Renames a resource address in state — used when you rename a resource in code.
```bash
terraform state mv azurerm_resource_group.old_name azurerm_resource_group.new_name
```
Without this, Terraform would destroy the old resource and create a new one — even though it's the same infrastructure.

---

## terraform import

Brings an **existing Azure resource** into Terraform state so Terraform can start managing it.

### Syntax
```bash
terraform import <terraform-resource-address> <azure-resource-id>
```

### Example
```bash
MSYS_NO_PATHCONV=1 terraform import azurerm_resource_group.terraformlearning \
  "/subscriptions/a71a75a3-ad25-4d96-a052-13a1a31e9089/resourceGroups/rg-dev-terraform-learning"
```

### ⚠️ Windows Git Bash Fix — CRITICAL
Git Bash converts paths starting with `/` into Windows file paths:
```
/subscriptions/... → C:/Program Files/Git/subscriptions/...
```
**Always prefix with `MSYS_NO_PATHCONV=1`** when running `terraform import` on Windows Git Bash:
```bash
MSYS_NO_PATHCONV=1 terraform import <address> "<azure-id>"
```

### When would you use import?
- A resource was created manually in Azure (outside Terraform)
- You want Terraform to start managing it going forward
- After `state rm` — to bring a resource back under management

---

## terraform apply/destroy -target

Applies or destroys a **specific resource** instead of everything in your config.
```bash
terraform apply -target azurerm_resource_group.terraformlearning
terraform destroy -target azurerm_resource_group.terraformlearning
```

**Warning Terraform always shows:**
```
Warning: Applied changes may be incomplete
Note that the -target option is not for routine use
```
This is expected — `-target` is for exceptional situations, not everyday use.

**When is it useful?**
- Learning/testing — apply one resource at a time
- Recovering from errors — fix a specific broken resource
- Avoiding billing — skip expensive resources during learning

---

## .tf.bak — Temporarily Excluding Files
Terraform only reads files ending in `.tf`. Rename to `.tf.bak` to temporarily exclude:
```bash
mv vm.tf vm.tf.bak      # exclude
mv vm.tf.bak vm.tf      # restore
```

---

## Key Concepts Summary

| Scenario | Command |
|---|---|
| What is Terraform tracking? | `terraform state list` |
| What does Terraform know about resource X? | `terraform state show <resource>` |
| Remove stale state record (keep Azure resource) | `terraform state rm <resource>` |
| Rename resource in code without destroying it | `terraform state mv <old> <new>` |
| Bring manually-created Azure resource into Terraform | `terraform import <address> <azure-id>` |
| Apply/destroy one specific resource | `terraform apply/destroy -target <resource>` |

---

## IT Ops Analogy
- `state list` = browsing your CMDB asset list
- `state show` = opening a specific asset record — full detail
- `state rm` = removing a record from CMDB — the physical asset still exists
- `import` = adding an undocumented asset into the CMDB
- `state mv` = updating the asset name/location in CMDB after a rename

---

## What's Next — Day 35
- Importing existing resources deep dive
- Real-world import scenarios
- Phase 5 Review (Day 36)