# Day 28 — Public Registry Modules

**Phase 4: Modular Design | Terraform Learning Journey**
**Date:** 2026-05-27

---

## 🎯 What We Learned Today

Today we discovered the Terraform Registry — thousands of community-built modules ready to use. We explored the `Azure/vnet` module, understood how public modules differ from local modules, and successfully called a public registry module in our project.

---

## 🌐 The Terraform Registry

URL: `registry.terraform.io`

The registry is like npm for Terraform — a central repository of reusable modules built by:
- HashiCorp
- Cloud providers (Azure, AWS, Google)
- Community contributors

**Key stats seen today:**
- AWS IAM module: 369.3M downloads
- Azure VNet module: 3.2M downloads

---

## 📦 Public Module Source Format

```
namespace/module-name/provider
```

| Part | Example | Meaning |
|---|---|---|
| `namespace` | `Azure` | Who published it |
| `module-name` | `vnet` | What it does |
| `provider` | `azurerm` | Which provider it uses |

**Examples:**
- `Azure/vnet/azurerm` — Azure VNet module
- `terraform-aws-modules/vpc/aws` — AWS VPC module
- `Azure/avm-res-network-virtualnetwork/azurerm` — newer Azure VNet module

---

## 🔑 Local vs Public Module Comparison

| | Local Module | Public Module |
|---|---|---|
| Source | `"./modules/networking"` | `"Azure/vnet/azurerm"` |
| Version pin | Not needed | **Always required** |
| Location | Your repo | `.terraform/modules/` |
| Dependencies | None | May bring extra providers |
| Control | Full | Limited to module's design |

---

## 📞 How to Call a Public Registry Module

```hcl
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.1"

  resource_group_name = var.resource_group_name
  vnet_location       = var.location
}
```

**Critical difference from local module:**
- Local: `source = "./modules/networking"` — no version needed
- Public: `source = "Azure/vnet/azurerm"` + `version = "5.0.1"` — version always required

---

## ⚡ What Happens During `terraform init` with Public Modules

```
Initializing modules...
Downloading registry.terraform.io/Azure/vnet/azurerm 5.0.1 for vnet...
- vnet in .terraform\modules\vnet

Initializing provider plugins...
- Installing azure/modtm v0.3.2...
- Installing hashicorp/random v3.9.0...
```

Three things happen:
1. Terraform **downloads** the module from the registry
2. Saves it to `.terraform/modules/`
3. Also installs any **extra providers** the module depends on

This is why `terraform init` must be re-run whenever you add a new public module.

---

## 📖 How to Read a Registry Module Page

When evaluating a public module, always check these tabs:

| Tab | What to look for |
|---|---|
| **Readme** | Is it deprecated? What does it do? |
| **Inputs** | Required vs optional inputs |
| **Outputs** | What values does it expose? |
| **Dependencies** | What extra providers does it need? |
| **Resources** | What Azure resources does it create? |

**Today's finding on `Azure/vnet`:**
- Only 2 required inputs: `resource_group_name`, `vnet_location`
- 7 outputs: `vnet_id`, `vnet_name`, `vnet_subnets`, etc.
- **DEPRECATED** — pointing to `avm-res-network-virtualnetwork`

---

## ⚠️ CRITICAL: Always Pin Module Versions

```hcl
# WRONG — dangerous in production
module "vnet" {
  source = "Azure/vnet/azurerm"
  # no version = gets latest automatically
}

# RIGHT — safe and predictable
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.1"
}
```

**Why?** Module authors can release breaking changes at any time. Without a pinned version:
- `terraform init` today downloads v5.0.1 ✅
- `terraform init` next month downloads v6.0.0 with breaking changes ❌
- Your infrastructure breaks unexpectedly

This is identical to `pip install requests==2.28.0` vs `pip install requests`.

---

## 🤔 When to Use Public vs Write Your Own

| Situation | Use Public | Write Your Own |
|---|---|---|
| Standard infrastructure (VNet, S3, IAM) | ✅ | |
| Company-specific naming conventions | | ✅ |
| Sensitive internal configuration | | ✅ |
| Learning and understanding internals | | ✅ |
| Quick prototyping | ✅ | |
| Strict compliance requirements | | ✅ |
| Module is deprecated | | ✅ |

**Rule of thumb:** Use public modules for standard well-known infrastructure. Write your own when you need custom logic, naming, or security controls.

---

## ⚠️ Common Mistakes to Avoid

### ❌ Mistake 1: Not pinning module version

```hcl
# WRONG
source = "Azure/vnet/azurerm"

# RIGHT
source  = "Azure/vnet/azurerm"
version = "5.0.1"
```

### ❌ Mistake 2: Using deprecated modules in production

Always check the **Readme** tab first. If it says `[DEPRECATED]`, find the recommended replacement. `Azure/vnet` → use `Azure/avm-res-network-virtualnetwork` instead.

### ❌ Mistake 3: Forgetting to run `terraform init` after adding a public module

Public modules must be downloaded first. Unlike local modules, they don't exist in your repo. Always run `terraform init` after adding a new public module source.

### ❌ Mistake 4: Not checking required inputs before calling a module

Always click the **Inputs** tab on the registry page before writing your module call. Missing a required input will cause a validate error.

### ❌ Mistake 5: Committing `.terraform/modules/` to Git

The downloaded public modules live in `.terraform/modules/` — this folder should be in your `.gitignore`. Your colleagues will download them themselves via `terraform init`.

---

## 💡 Deeper Insight — Public Modules Bring Their Own Dependencies

When you added `Azure/vnet`, Terraform also installed:
- `azure/modtm` — Microsoft telemetry provider
- `hashicorp/random` — for generating random values

This is important because:
1. Your `.terraform.lock.hcl` gets updated with new provider hashes
2. These extra providers must be available wherever you run Terraform
3. In CI/CD pipelines, all providers are downloaded fresh — version pins ensure consistency

Always commit your `.terraform.lock.hcl` to Git — it ensures everyone uses the same provider versions.

---

## 🧪 What We Did Today

```bash
# Added public module to main.tf
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.1"
  resource_group_name = var.resource_group_name
  vnet_location       = var.location
}

terraform init
# Downloading registry.terraform.io/Azure/vnet/azurerm 5.0.1 ✅

terraform validate
# Success! The configuration is valid. ✅
```

---

## 🔮 Coming Up — Day 29

Multi-environment module design:
- Using the same modules for dev, staging, prod
- How environment-specific values flow through modules
- Workspace vs separate tfvars approaches

---

## 📝 Key Takeaway

> The Terraform Registry is your module library — use it for standard infrastructure. Always pin versions, always check for deprecation, always run `terraform init` after adding a new public module. You don't always need to build from scratch.

---

*Notes written by Claude | Terraform Mentorship Day 28 | Phase 4: Modular Design*