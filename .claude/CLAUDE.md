# CLAUDE.md — Enterprise Cloud Platform AVD Workload Pattern

> Claude Code instructions for the Enterprise Cloud Platform (ECP) Azure Virtual Desktop Workload Pattern repository.

## Project Status: Complete Rewrite In Progress

This repository is being **rewritten from scratch**. The existing code (Terragrunt hierarchy under `environments/`, the `src/avd_compute_gallery` module, `common/root-common.hcl`) is **legacy** and serves only as a reference for prior conventions. Do not extend legacy code — new work follows the target state described below.

Documentation is intentionally basic right now and will grow with the project (developer guides, architecture docs, usage guides). Keep this file up to date as patterns are established.

## What This Repository Is

A **workload pattern** for the Enterprise Cloud Platform (ECP): a self-contained, layered Azure Virtual Desktop deployment using Terraform and Terragrunt.

**Core principles:**

1. **Stand-alone single repository.** Unlike the ECP platform itself (which is split across conf/tgcommon/azure/lib repos with submodules), this workload pattern contains everything in one repo: Terragrunt configuration, Terraform modules, and documentation.
2. **ECP-first, ECP-optional.** The preferred deployment target is a subscription vended by ECP, running inside the Azure DevOps pipeline that ECP subscription vending prepares. The pattern must also work fully standalone (development, non-ECP customers) — foundation inputs are then supplied via configuration instead of platform handover.
3. **Policy-compatible.** Deployments must comply with ECP's policy-driven guardrails (see "ECP Guardrails" below) so the pattern deploys cleanly into a policy-managed landing zone.
4. **AzAPI-first.** Prefer the `azapi` provider over `azurerm`. Azure Verified Modules (AVM) may be used, but each adoption is an individual decision — do not introduce AVM modules without discussion.
5. **DRY and reusable.** Terragrunt handles configuration layering; Terraform modules are small, composable, and follow the ECP module conventions.
6. **Identity is part of the pattern.** Entra ID group management (e.g. groups assigned to AVD application groups) is implemented in Terraform alongside the Azure resources.

## Related ECP Repositories

These are the authoritative reference for ECP conventions. Consult them before inventing new patterns:

| Repository | Content | What to take from it |
|------------|---------|----------------------|
| [enterprise-cloud-platform-conf](https://github.com/rafabu/enterprise-cloud-platform-conf) | Terragrunt deployment configuration | Hierarchy layout, include chain, tag layering |
| [enterprise-cloud-platform-tgcommon](https://github.com/rafabu/enterprise-cloud-platform-tgcommon) | Shared Terragrunt library (`ecp-v1/root-common.hcl`, `unit-common.hcl` files) | Provider generation, backend config, dependency patterns |
| [enterprise-cloud-platform-azure](https://github.com/rafabu/enterprise-cloud-platform-azure) | Terraform module library | Module file layout, AzAPI patterns, naming, Entra group patterns |
| [enterprise-cloud-platform-lib](https://github.com/rafabu/enterprise-cloud-platform-lib) | ALZ/ECP artefact library (JSON) | Artefact schema/README style, policy artefacts |

## Technology Stack

| Tool | Version | Notes |
|------|---------|-------|
| Terraform | >= 1.15 | Aligned with ECP tgcommon |
| Terragrunt | latest | Modern syntax: `root.hcl`, `find_in_parent_folders("root.hcl")`, `get_repo_root()`, `terragrunt hcl format` |
| AzAPI provider | ~> 2.11 | **Preferred** for Azure resources |
| AzureRM provider | ~> 4.x | Fallback only (e.g. where azapi is impractical) |
| AzureAD provider | ~> 3.9 | Entra ID groups, PIM (3.9+ contains PIM fixes) |
| Azure CAF Naming (`aztfmod/azurecaf`) | ~> 1.2 | All resource naming |
| PowerShell | 7.x | Cross-platform automation scripts |

**Default Azure region:** WestEurope (overridable per deployment).

## Allowed Languages

Only these languages, consistent with ECP standards:

| Language | Extensions | Use Case |
|----------|------------|----------|
| Terragrunt | `.hcl` | Environment configuration |
| Terraform | `.tf` | Infrastructure modules |
| PowerShell 7 | `.ps1` | Automation scripts (cross-platform) |
| Bash | `.sh` | Shell scripts |
| YAML | `.yaml`, `.yml` | Pipelines, configuration |

**NOT ALLOWED:** Python, JavaScript, TypeScript, or other languages.

## Target Architecture

Layered deployment; each level builds on the previous one. Exact composition will be refined during the rewrite — update this section as levels are implemented.

| Level | Scope | Planned content |
|-------|-------|-----------------|
| **Level 0** | AVD foundation | Azure Compute Gallery, Log Analytics workspace (AVD Insights), FSLogix/profile storage, private endpoints |
| **Level 1** | AVD management plane | AVD workspaces, host pools (pooled & personal), application groups, scaling plans |
| **Level 2** | Session hosts | Session host VMs, domain/Entra join, AVD agent registration, monitoring agents |
| **Level 3** | Configuration & identity | Entra ID groups + application group assignments, FSLogix configuration, custom images / image automation |

Permission management (Entra ID groups assigned to application groups, RBAC) is a first-class deliverable, not an add-on.

### Host pool flexibility

The following are **per-host-pool decisions**, configurable independently for each host pool (not global settings):

- **Identity join type** — Entra ID join or classic Active Directory (AD DS) domain join
- **Intune enrollment** — whether session hosts are enrolled into Intune (Entra ID join scenarios)
- **Desktop model** — personal desktops or pooled multi-session

Design host pool and session host modules so these are host-pool-level variables (e.g. a host pool configuration object covering join type, Intune enrollment, and `personalDesktopAssignment` vs. multi-session settings). Session host provisioning (VM extensions for domain join vs. Entra join + Intune MDM enrollment, AVD agent registration) must follow the owning host pool's configuration.

### Deployment flavors: regular and confidential AVD (planned)

The pattern will ultimately support two flavors from the same code base:

- **Regular AVD** — standard session hosts and supporting services (current focus).
- **Confidential AVD** — Azure confidential computing throughout: confidential VMs as session hosts (e.g. DCasv5/ECasv5, confidential OS disk encryption, vTPM/Secure Boot) and the highest encryption standards for supporting services — customer-managed keys / double encryption for storage accounts, Log Analytics, and similar.

Not a current priority, but **design for it now**: keep security/encryption settings (VM `securityProfile`, disk encryption sets, CMK configuration) as module variables with sensible regular-AVD defaults rather than hard-coded values, so the confidential flavor can be layered in without restructuring modules.

## Terragrunt Conventions

> **Approved deviation from ECP:** this repo uses **explicit Terragrunt Stacks** (`terragrunt.stack.hcl`) instead of the hand-written `level/area/unit` directory tree the ECP conf repo uses. The ECP naming/tagging/state contracts are preserved; only the mechanics differ.

### Configuration hierarchy (stacks-based)

```
common/
├── root-common.hcl            # machinery: locals merge, remote_state, provider generation
└── units/<unit-name>/         # reusable unit templates (stack sources)
    └── terragrunt.hcl
environments/
├── root.hcl                   # workload identity: tenant, deployment code/number, location, root tags
└── <env>/
    ├── env.hcl                # deployment_env, subscription, standalone backend fallback, env tag
    └── terragrunt.stack.hcl   # declares the env's units: unit "x" { source, path, values }
```

- Each environment declares its units in `terragrunt.stack.hcl`; `terragrunt stack generate` materializes them under `environments/<env>/.terragrunt-stack/` (gitignored).
- The stack unit `path` encodes the level hierarchy: `level<N>/<area>/<unit>` (e.g. `level0/imaging/gallery`). `root-common.hcl` parses level/area/unit from this path — there are **no** `level.hcl`/`area.hcl` files.
- Unit templates include the deep-merge chain (`merge_strategy = "deep"`, `expose = false`): `root-common.hcl` (via `get_repo_root()`) → `root.hcl` → `env.hcl` (via `find_in_parent_folders()`). `root-common.hcl` re-reads root/env itself into `merged_locals`.
- Per-unit configuration flows through stack `values` (e.g. `workload_block_name`); access `values.*` only in the unit template's `terragrunt.hcl`, not in included files.
- Layer `inputs` are guarded so unset values never override lower layers: `length(try(local.x, "")) > 0 ? { ... } : {}`.
- Adding a unit = add a template under `common/units/` (or reuse one) + a `unit` block in the env's stack file. Adding an environment = `env.hcl` + `terragrunt.stack.hcl`.

### Remote state

- Backend `azurerm`, `use_azuread_auth = true` — never access keys.
- State key: repo-root-relative with `.terragrunt-stack/` stripped → `<env>/level<N>/<area>/<unit>.tfstate` (e.g. `dev/level0/imaging/gallery.tfstate`). Unique across environments even on a shared storage account.
- Standalone layout decision: **one storage account, one shared `tfstate` container** for all environments; ECP mode gets one vended storage account per environment automatically.
- Backend configuration three-tier resolution (first complete tier wins):
  1. `ECP_TG_BACKEND_LEVEL{N}_*` env vars (ECP platform pipeline compatibility)
  2. `ECP_TG_BACKEND_*` env vars (primary for this pattern — one storage account per vended subscription)
  3. `ecp_backend_*` locals in `env.hcl` (standalone fallback)
- Azure context resolution: `ECP_TG_TENANT_ID` / `ECP_TG_SUBSCRIPTION_ID` env vars override `ecp_entra_tenant_id` (root.hcl) / `ecp_workload_subscription_id` (env.hcl).
- Lock timeout 20 minutes: `extra_arguments "retry_lock"` with `-lock-timeout=20m`; `init` runs with `-lock=false`.
- `.terraform.lock.hcl` files are **gitignored** (ECP convention) — the generated `versions.tf` pins are the source of truth.

### Provider generation

`root-common.hcl` generates `providers.tf` and `versions.tf` (`if_exists = "overwrite"`). Provider versions are pinned centrally there — modules generally do **not** declare `required_providers` themselves.

### Dependencies

Use `dependency` blocks with full `mock_outputs` (so `plan` works before dependencies are applied) and `mock_outputs_merge_strategy_with_state = "shallow"`. Dependency label convention: `l<level>-<area-abbrev>-<unit-abbrev>` (e.g. `l0-img-gallery`).

## Terraform Module Conventions (from ECP)

### File layout per module

```
src/.../{module}/
├── main.tf                  # client config data sources only — NOT the main resources
├── locals.tf                # computed locals
├── variables.tf             # inputs (framework variables first, then module-specific)
├── variables_constant.tf    # AVM/module version pins (if any)
├── resource_name_data.tf    # all azurecaf_name data sources + name-template locals
├── <resource>.tf            # one file per resource area (e.g. workspace.tf, host_pool.tf)
└── outputs.tf               # structured object/map outputs
```

No file-header comment banners (legacy modules have them; new modules do not). Use section banners inside larger files and inline `#` comments explaining *why* (API quirks, provider bugs), not *what*.

### Framework variables (every module)

```hcl
variable "azure_location" {
  type        = string
  description = "Default region for resources deployed into this subscription."
}

variable "azure_resource_name_elements" {
  type = object({
    prefixes      = optional(list(string))
    suffixes      = optional(list(string))
    name          = optional(string)
    random_length = optional(number)
  })
  description = "Object containing naming components to be used by the azurecaf_name data source to generate resource names."
}

variable "azure_tags" {
  type        = map(string)
  description = "A map of tags to assign to the resource."
  default     = {}
}
```

Validation style: `contains([...], x)` with explicit `error_message`; GUID regex validation for subscription/tenant ID variables.

### AzAPI patterns

```hcl
resource "azapi_resource" "example" {
  type      = "Microsoft.DesktopVirtualization/hostPools@<explicit-api-version>"
  name      = data.azurecaf_name.example.result
  location  = var.azure_location
  parent_id = azapi_resource.resource_group.id

  body = { properties = { ... } }

  tags                      = var.azure_tags
  response_export_values    = ["*"]        # or a narrow list

  lifecycle {
    ignore_changes = [tags]
  }
}
```

- Pin `type` to an explicit, recent API version; note newer candidates in a comment.
- Chain `parent_id` off the owning azapi resource.
- Consume exported values via `.output.<path>`; parse IDs with `provider::azapi::parse_resource_id(...)`.
- Conditional creation: `for_each = toset(var.x_enabled ? ["this"] : [])`.
- Use `time_sleep` for Entra/ARM replication waits; consider resource-provider registration checks for `Microsoft.DesktopVirtualization`.

### Naming

- All names from `data "azurecaf_name"` blocks in `resource_name_data.tf` with `clean_input = true`, `use_slug = true`, fed from `var.azure_resource_name_elements`.
- Where azurecaf lacks a resource type, rewrite the slug: `replace(data.azurecaf_name.rg.result, "-rg-", "-vdpool-")` — with a comment explaining why.
- Environment name formula: `lower("${deployment_code}-${substr(deployment_env, 0, 1)}${deployment_number}")` → e.g. `ecp-d1`, `dark-d1`.
- Name elements: prefixes = `[environment_name]`, name = deployment area, suffixes = `[deployment_unit]`.

### Entra ID group patterns

Follow the ECP role/permission group pair model:

- `ra-<prefix>-<name>-<suffix>-<role>` — role-assignable group holding humans (PIM-capable).
- `pm-<prefix>-<name>-<suffix>-<permission>` — permission group holding the role group as member; **this** group receives Azure RBAC and AVD application group assignments.
- RBAC via `azapi_resource "Microsoft.Authorization/roleAssignments@2022-04-01"` with deterministic `uuidv5(...)` names.

### Outputs

Structured objects/maps with stable shapes (`{ id, name, resource_group_name, location, ... }`), `description` on non-obvious outputs, `try(..., "")` for conditionally created resources.

### Tags

Tags are merged across the Terragrunt hierarchy. Layer contributions: `createdBy = "ecp-terraform"` (root-common), `businessUnit`/`workloadName`/`workloadOwner` (root), `environment` (env), `workloadBlockName` (unit template, fed from stack `values`). Always pass `var.azure_tags` to every resource.

## ECP Integration Contract

When deployed on ECP, subscription vending hands over (via the vended Azure DevOps project's variable group):

- Vended subscription (`azureSubscriptionId`), placed in the policy-managed MG hierarchy
- Virtual network + subnets (with private endpoint subnet, `default_outbound_access_enabled = false`)
- Terraform state storage account (OAuth-only, private endpoint, `tfstate` container)
- Azure DevOps project, repo, WIF service connection, managed DevOps pool, deploy pipeline
- Entra ID `lz-owner` / `lz-user` role groups
- Platform private DNS zones (linked to the vended VNet)

### ECP Guardrails (must-comply)

- `public_network_access_enabled = false` for PaaS services — use private endpoints in the designated PE subnet, joined to platform private DNS zones
- Storage: HTTPS-only, TLS 1.2+, shared keys disabled, Entra ID auth
- No default outbound access on subnets — egress via platform NAT Gateway / hub
- Key Vault purge protection (enforced outside dev)
- Diagnostics to Log Analytics

In standalone mode these same practices apply by default; the pattern provides its own equivalents where the platform would normally supply them.

## Development Workflow

### Branches & commits

- Branch naming: `feature/<topic>` (kebab-case), matching ECP convention. Also used: `fix/<topic>`, `docs/<topic>` where appropriate.
- PRs target `main`.
- Commit messages: Conventional Commits style as used in this repo's history (`feat:`, `fix:`, `docs:`, `refactor:`, `merge:`).

### Validation

```bash
terraform fmt -recursive          # format Terraform
terragrunt hcl format             # format Terragrunt (modern command)
terragrunt stack generate         # materialize units from terragrunt.stack.hcl (run in environments/<env>/)
terragrunt hcl validate           # lint hcl — run from environments/<env>/, NOT repo root (templates don't resolve)
terragrunt stack run plan         # plan all units of an environment
terragrunt validate               # validate a generated unit (run inside .terragrunt-stack/<path>)
terragrunt render --json          # inspect a unit's merged config (inputs, backend, generate blocks)
```

Local runs without Azure access: export dummy `ECP_TG_BACKEND_*` values (see `.env.example`) so backend resolution succeeds, then use `terragrunt init -backend=false` + `terragrunt validate` inside a generated unit. Unit templates under `common/units/` are **not** valid standalone — their parent-folder includes only resolve after generation into an environment tree.

### Pipelines

Production deployments run in Azure DevOps pipelines provided by ECP subscription vending. Local/standalone runs use the same Terragrunt entry points with backend configuration supplied via environment variables or config.

## Documentation Roadmap

Keep docs basic for now; grow them alongside the implementation:

- `README.md` — project overview and roadmap (current)
- Planned: developer guide, architecture documentation (level design, dependency graph), usage guide (ECP-integrated vs standalone), artefact/configuration reference

When a pattern or decision is established during the rewrite, record it here immediately.

## Trust Guidelines

1. **This file describes the target state**; legacy code under `src/` and `environments/` may contradict it — the target state wins for new work.
2. **ECP repos are authoritative** for platform conventions; follow their patterns unless this file explicitly deviates (e.g. single-repo layout, no submodules).
3. **Prefer official documentation**: AzAPI provider docs (registry.terraform.io/providers/Azure/azapi), Microsoft Learn for AVD and Azure Landing Zones / enterprise-scale, Terragrunt docs (terragrunt.gruntwork.io) — over third-party blogs.
4. **Breaking changes** to the Terragrunt hierarchy require discussion before implementation.
5. **Update this file** when patterns change or decisions are made.
