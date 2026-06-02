# Day 33 — State Locking Deep Dive

## What We Covered Today
What happens when a lock gets stuck — and how to safely recover from it.

---

## How State Locking Works (Quick Recap)

Terraform uses **two separate mechanisms** for locking on Azure:

| Mechanism | What It Is | Who Manages It | Auto-Expires? |
|---|---|---|---|
| Azure Blob Lease | Native Azure feature on the blob | Azure | ✅ Yes — ~60 seconds after no renewal |
| Terraform Lock Record | Lock metadata written to state backend | Terraform | ❌ No — stays until explicitly released |

While `apply` is running, Terraform **actively renews** the blob lease every few seconds. If the process crashes — renewal stops, Azure expires the lease. But Terraform's own lock record stays behind.

---

## The Stuck Lock Scenario

### How It Happens
1. `terraform apply` starts → acquires blob lease + writes lock record
2. Mid-apply: process crashes (pipeline runner dies, laptop killed, network drops)
3. Azure blob lease expires after ~60 seconds ✅
4. Terraform lock record stays in backend ❌ — **this is the stuck lock**

### What You See Next Time
```
Error: Error acquiring the state lock

Lock Info:
  ID:        abc123-def456-ghi789
  Operation: OperationTypeApply
  Who:       pipeline@ci-runner-07
  Created:   2026-05-31 23:45:00
```

---

## Safe Recovery Process — Before Force-Unlocking

**Never run force-unlock immediately.** Follow this checklist:

### Step 1 — Verify the lock owner is dead
- **GitHub Actions** → Actions tab → find the workflow → confirm it shows Failed or Cancelled
- **Azure DevOps** → check pipeline run status
- **Manual run** → ask the engineer directly — did it crash?

> Key question: Is there any process *anywhere* still actively running this apply?

### Step 2 — Check for partial resources in Azure
- Go to the Resource Group Terraform was deploying into
- Look for resources in **"Deployment failed"** state or unexpected partial resources
- Cross-reference with your `terraform plan` output — what was Terraform trying to create when it crashed?

### Step 3 — Force-unlock
Only after Steps 1 and 2 are confirmed:
```bash
terraform force-unlock <LOCK_ID>
```
Example:
```bash
terraform force-unlock abc123-def456-ghi789
```
The Lock ID comes directly from the error message Terraform showed.

---

## Why the Checklist Matters

| Risk | What Happens |
|---|---|
| Force-unlock while apply is still running | Two applies write to state simultaneously → **corrupted state** |
| Force-unlock with partial resources | Next apply may try to recreate resources that already exist → **conflicts** |

---

## When Does Locking Happen?

| Command | Locks State? | Reason |
|---|---|---|
| `terraform plan` | ❌ No | Read-only — safe for concurrent reads |
| `terraform apply` | ✅ Yes | Writes to state — concurrent writes = corruption |
| `terraform destroy` | ✅ Yes | Writes to state |
| `terraform state` commands | ✅ Some | Depends on whether they write |

---

## IT Ops Analogy
Think of it like a **shared network drive file** that someone had open when their computer crashed:
- The file appears locked to everyone else
- IT can see the lock is stale (the computer is off)
- IT clears the lock manually — that's `force-unlock`
- But IT first confirms the computer is actually off, not just rebooting

---

## What's Next — Day 34
- `terraform state` commands deep dive
- `terraform state list`, `show`, `mv`, `rm`
- When and why you'd manually manipulate state