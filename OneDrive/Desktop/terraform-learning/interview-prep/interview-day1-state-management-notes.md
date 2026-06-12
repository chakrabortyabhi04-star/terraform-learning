# Interview Prep — Day 1: State Management
## Mock Interview Notes + Ideal Answers

---

## Q1 — What is Terraform State and Why Does it Exist?

**Ideal Answer:**
> *"Terraform state is a JSON file that records every resource Terraform creates. It's Terraform's single source of truth about what infrastructure exists and what properties those resources have.*
>
> *Without state, Terraform would have no idea which resources it created vs which already existed. Every `terraform apply` would try to create everything from scratch, causing duplicates and errors.*
>
> *But state does something even more important — it lets Terraform detect drift. If someone manually deletes a resource in Azure that Terraform owns, the next `terraform plan` compares the state file to reality and shows you the difference. Without state, Terraform can't detect that something changed."*

**Key Points:**
- State = Terraform's memory
- JSON file format
- Without state → duplicates on every apply
- Drift detection — compares state vs reality

---

## Q2 — Two Engineers Run terraform apply Simultaneously. What Happens?

**Ideal Answer:**
> *"State locking prevents exactly this problem. When the first engineer runs `terraform apply`, Terraform acquires a lease lock on the state file in the remote backend — Azure Blob Storage. The lease is held for the duration of the apply.*
>
> *If the second engineer tries to apply at the same time, Terraform detects the lock is already held and throws an error: 'Error acquiring the state lock: resource already exists.' The error includes the lock ID and who holds it.*
>
> *The second engineer has to wait until the first one finishes and the lock is released automatically. If the first engineer's machine crashes mid-apply, the lock can get stuck — that's why you need `terraform force-unlock` to manually release it."*

**Key Points:**
- Azure Blob Storage uses blob lease for locking
- One lock at a time — second engineer gets blocked
- Error message includes Lock ID
- Lock releases automatically on success
- Crashed machine → stuck lock → use `terraform force-unlock`

---

## Q3 — State File Got Corrupted. How Do You Recover?

**Ideal Answer:**
> *"First, I'd verify that the infrastructure still exists in Azure — even if the state file is corrupted, my VNets, storage accounts, and VMs are still running. State corruption doesn't delete real resources.*
>
> *Then I'd restore the state file from backup. Azure Blob Storage has versioning enabled on the tfstate container, so I'd restore the last known good version.*
>
> *After restore, I'd run `terraform plan` to check for drift — if anything was manually changed in Azure since the last state, the plan will show it.*
>
> *If the restore didn't capture a resource that was created recently, I'd use `terraform import` to bring it back under Terraform management.*
>
> *The key lesson: always enable versioning on your state backend so you can recover from corruption without losing everything."*

**Key Points:**
- State corruption ≠ Azure resources deleted
- Restore from Azure Blob Storage versioning/snapshots
- Run terraform plan after restore to check drift
- Use terraform import for any resources not captured in restore
- Always enable versioning on state backend

**Recovery Order:**
1. Verify Azure resources still exist
2. Restore state from versioned backup
3. Run terraform plan — check for drift
4. Import any missing resources
5. Get team sign-off before applying

---

## Q4 — Terraform Wants to Destroy/Recreate a Resource You Didn't Change. Why?

**Ideal Answer:**
> *"This usually means there's a difference between what Terraform expects and what Azure actually returns — even though functionally the resource is identical.*
>
> *Common causes: the provider version changed and reads properties differently, or Azure returns properties in a different order or format than Terraform's code specifies.*
>
> *I'd debug by running `terraform plan -json` or `TF_LOG=DEBUG terraform plan` to see the exact diff — what property is different? Then I'd check: did the provider version change? Is Azure returning a computed value differently?*
>
> *If the diff is harmless — like a property order or a default Azure adds — I'd use `terraform state rm` and `terraform import` to re-sync the state with reality, fixing the mismatch without destroying anything."*

**Common Causes:**
- Provider version changed — reads properties differently
- Azure returns computed values in different format
- Property order mismatch
- Azure adds default values Terraform didn't set

**Debug Steps:**
1. `TF_LOG=DEBUG terraform plan` — see full diff
2. `terraform plan -json` — machine readable output
3. Identify which property is mismatched
4. Fix in code OR re-sync state with import

---

## Q5 — terraform state rm vs terraform state mv

**`terraform state rm` — Remove from state:**
> Use when: You want Terraform to stop managing a resource — but keep it in Azure.

Real scenario:
> Security team takes over a storage account. You run `terraform state rm azurerm_storage_account.storage1`. The storage account stays in Azure but Terraform no longer tracks it.

**`terraform state mv` — Move/rename in state:**
> Use when: You refactor your code structure but don't want to destroy/recreate resources.

Real scenario:
> You move a VNet from root module into a networking module. Terraform sees it as a new address. Instead of destroying, you run:
> ```bash
> terraform state mv azurerm_virtual_network.vnet \
>   module.networking.azurerm_virtual_network.vnet
> ```
> VNet stays running. State file updated. No Azure changes.

**The Rule:**
| Command | What it does | When to use |
|---|---|---|
| `state rm` | Remove from state entirely | Stop managing a resource |
| `state mv` | Rename/reorganize in state | Refactor code structure |

> Both commands **never touch Azure**. They only update Terraform's memory.

---

## Q6 — Explain State File to a Non-Technical PM

**Ideal Answer:**
> *"Think of the state file like a medical record. It tracks every resource Terraform created and all its details — IP addresses, IDs, configurations.*
>
> *If we delete the state file and recreate everything, it's like deleting a patient's medical history and starting fresh. The patient still exists — the infrastructure still runs in Azure — but we've lost the record.*
>
> *Now when Terraform tries to recreate, it doesn't know the old resources exist. It creates duplicates — two storage accounts with the same name, two networks fighting over the same IP range. Everything breaks.*
>
> *Plus, if something manually changed in Azure since we last looked — a firewall rule got tightened, an IP got reserved — Terraform won't know about it. It will overwrite those manual changes and cause an outage.*
>
> *The state file is cheap to keep and invaluable to have. Deleting it is like deleting your insurance records to save space."*

**Key Analogies:**
- State file = medical record
- Deleting state = deleting patient history
- Result = duplicates, broken infra, outages

---

## Q7 — One Backend with Workspaces vs Separate Backends Per Environment?

**Answer: Separate Backends — Always for Production**

**Ideal Answer:**
> *"I'd use separate backends for each environment — not workspaces.*
>
> *Here's why: workspaces share the same backend, same variables, same code. If someone makes a mistake in prod code — typos a variable, forgets a safety check — it affects prod directly. Workspaces give you false isolation.*
>
> *Separate backends mean:*
> - Dev state is completely isolated from prod state
> - Each environment has its own variables file and backend credentials
> - You can restrict who has access to prod backend — dev team can't even read prod state
> - Cost difference is negligible — a few dollars per month for backend storage
>
> *Workspaces are useful for temporary experimentation — testing a change before applying to real environments. But for permanent environment separation, separate backends is the production pattern."*

**Key Decision:**
| | Workspaces | Separate Backends |
|---|---|---|
| Isolation | ❌ Shared backend | ✅ Fully isolated |
| Access control | ❌ Shared credentials | ✅ Separate credentials |
| Prod safety | ❌ Risk of cross-env mistakes | ✅ No cross-env risk |
| Cost | ✅ Cheaper | Negligible difference |
| Use for | Temporary experiments | Production environments |

---

## Q8 — Migrate 50 Existing Azure Resources Into Terraform

**Ideal Answer — 5 Phase Approach:**

> **Phase 1 — Planning:**
> - List all 50 resources and their types
> - Check dependencies — which resources depend on others?
> - Document current configurations from Azure portal
>
> **Phase 2 — Code First:**
> - Write resource blocks in Terraform for each resource
> - Don't fill in all properties yet — import will help
>
> **Phase 3 — Import:**
> - Get resource ID from portal
> - Run `terraform import azurerm_storage_account.storage1 /subscriptions/.../resourceGroups/...`
> - Terraform reads resource from Azure and populates state
>
> **Phase 4 — Reconcile:**
> - Run `terraform plan` — shows properties in state vs code
> - Copy those properties into code blocks
> - Run `terraform plan` again until it shows no changes
>
> **Phase 5 — Validate:**
> - Check for drift — any manual changes since import?
> - Fix drift in code or accept as expected
> - Get team sign-off before applying
>
> *"The key: import brings state in sync with reality, but I still have to write the code. Don't skip reconciliation."*

---

## Day 1 Score Summary

| Question | Result | Gap |
|---|---|---|
| State basics | ✅ Good | Add drift detection |
| State locking | ✅ Excellent | Say "engineer" not "technician" |
| Corrupted state | ✅ Good | Add versioning by name |
| Destroy/recreate mystery | ❌ Missed | Provider version drift |
| state rm vs mv | ❌ Didn't know | Learn scenarios above |
| Explain to non-tech | ✅ Good | Use medical record analogy |
| Workspaces vs backends | ❌ Missed risk | Separate backends for prod |
| Import 50 resources | ✅ Good | Add 5-phase approach |

**Pattern:** Strong on mechanics, weak on comparisons and edge cases.

---

## Tomorrow — Day 2
Remote backend deep dive + state locking scenarios. Decision-making questions, not just knowledge recall.