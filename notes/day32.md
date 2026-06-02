# Day 32 — Remote Backend: Azure Storage (Hands-On Verification)

## What We Did Today
Verified the remote backend is working end-to-end by inspecting the actual state file in Azure Blob Storage.

---

## Key Concepts

### How Terraform Stores State Remotely
- State file lives as a **blob** inside your Azure Storage container (`tfstate`)
- File name = the `key` value in your backend block → `terraform.tfstate`
- It is a plain JSON file — same structure as your local `.terraform/terraform.tfstate`

### State File Structure (what we saw)
```json
{
  "version": 4,
  "terraform_version": "1.13.3",
  "serial": 1,
  "lineage": "01eb82bb-df90-3e75-6f6f-493dbcc7e0de",
  "outputs": {},
  "resources": [],
  "check_results": null
}
```
| Field | Meaning |
|---|---|
| `version` | State file format version (always 4 for modern Terraform) |
| `terraform_version` | Which Terraform CLI wrote this file |
| `serial` | Increments every time state changes — used to detect stale state |
| `lineage` | Unique ID for this state — never changes, even across applies |
| `resources` | Array of all tracked infrastructure — empty because no real resources applied yet |

---

## State Locking — How It Works on Azure

### The Mechanism
Terraform uses **Azure Blob Lease** (a native Azure feature) to lock the state file during `apply`.

- `apply` starts → Terraform **acquires a lease** on the blob → Lease state: **Leased**
- `apply` finishes → Terraform **releases the lease** → Lease state: **Available**
- You can see this in the Azure Portal → Storage Browser → `tfstate` container → **Lease state** column

### When Does Locking Happen?
| Command | Locks State? | Why |
|---|---|---|
| `terraform plan` | ❌ No | Read-only — safe for concurrent reads |
| `terraform apply` | ✅ Yes | Writes to state — concurrent writes = corruption |

### Two Layers of Protection
Terraform has two independent safety mechanisms:

**Layer 1 — Blob Lease Lock**
Prevents two `apply` runs from happening at the same time. If Engineer A holds the lease, Engineer B's apply will fail immediately with a lock error.

**Layer 2 — Serial Number Check**
Catches edge cases where the lock somehow failed.
- Engineer A and B both read state at `serial: 1`
- Engineer A applies → state becomes `serial: 2`
- Engineer B tries to apply with stale `serial: 1` copy → **Terraform rejects it**
- Serial only moves forward — stale state can never overwrite newer state

---

## Commands Used Today

### Download state file from Azure (for inspection)
```bash
az storage blob download \
  --account-name tfstateabhishek2024 \
  --container-name tfstate \
  --name terraform.tfstate \
  --file downloaded-state.json \
  --auth-mode key

cat downloaded-state.json
```
> Note: `--auth-mode login` requires RBAC roles (Storage Blob Data Reader etc.) — use `--auth-mode key` instead with this storage account.

---

## IT Ops Analogy
Think of state locking like a **CMDB record checkout system**:
- Reading the CMDB = anyone can do it simultaneously (plan)
- Editing a CMDB record = only one person can check it out at a time (apply)
- Serial number = version stamp on the record — you can't save changes based on a version older than the current one

---

## What's Next — Day 33
- State locking deep dive — what happens when a lock gets **stuck**
- How to manually release a stuck lock
- `terraform force-unlock` command