# Enterprise Cloud Platform | Workload Pattern — Azure Virtual Desktop (AVD)

> **Note:** This repository is undergoing a complete rewrite. The current code base is considered legacy and will be replaced level by level. Documentation is intentionally kept basic for now and will grow together with the implementation (developer guides, architecture documentation, usage guides).

## Overview

This repository implements the **Azure Virtual Desktop (AVD) Workload Pattern** for the Enterprise Cloud Platform (ECP) — a production-ready, layered AVD deployment built with Terraform and Terragrunt.

Workload patterns are self-contained infrastructure solutions that plug into an ECP landing zone. They consume foundational services handed over by the platform (vended subscription, virtual networks, Terraform state storage, Azure DevOps project and pipelines) and are fully compatible with ECP's policy-driven management and guardrails.

**Key characteristics:**

- **Stand-alone single repository** — everything needed to deploy the pattern lives here (no submodules into platform repositories)
- **ECP-first, but ECP-optional** — the preferred deployment target is a subscription vended by the Enterprise Cloud Platform; the pattern also works fully standalone for development or non-ECP scenarios
- **Layered architecture** — deployment levels build on top of each other, from foundational services up to session hosts and permission management
- **AzAPI-first** — the `azapi` Terraform provider is preferred over `azurerm`; Azure Verified Modules may be adopted case by case
- **Identity included** — Entra ID group management and application group assignments are part of the pattern, not an afterthought
- **Confidential AVD ready** (planned) — besides regular AVD environments, the pattern will support confidential AVD deployments using Azure confidential computing (confidential VMs as session hosts) and the highest encryption standards for supporting services such as storage accounts and Log Analytics (e.g. customer-managed keys, confidential disk encryption)
- **Flexible per host pool** — identity join type (Entra ID join or classic Active Directory domain join), Intune enrollment, and desktop model (personal desktops or pooled multi-session) are all decided per host pool

## Deployment Modes

| Mode | Description |
|------|-------------|
| **ECP-integrated** (preferred) | Runs in the Azure DevOps pipeline prepared by ECP subscription vending. State storage, networking, service connection, and policy guardrails are provided by the platform. |
| **Standalone** | Runs against any Azure subscription without ECP. Used for development and non-ECP deployments. Foundation inputs (network, state backend) are supplied via configuration. |

## Architecture

The deployment is split into levels; each level builds on the one below it:

| Level | Scope | Examples |
|-------|-------|----------|
| **Level 0** | AVD foundation | Azure Compute Gallery, Log Analytics workspace for AVD Insights, FSLogix storage |
| **Level 1** | AVD management plane | Workspaces, host pools, application groups, scaling plans |
| **Level 2** | Session hosts | Session host VMs, AVD agent registration, monitoring |
| **Level 3** | Configuration & identity | Entra ID groups, application group assignments, FSLogix configuration, image automation |

> The exact level composition is being refined as part of the rewrite — see `.claude/CLAUDE.md` for the current target state.

## Technology

| Tool | Version |
|------|---------|
| Terraform | >= 1.15 |
| Terragrunt | latest |
| AzAPI provider | ~> 2.x (preferred) |
| AzureRM provider | ~> 4.x (fallback) |
| AzureAD provider | ~> 3.x |
| Azure CAF Naming | ~> 1.2 |

## Related Repositories

The Enterprise Cloud Platform this pattern integrates with:

| Repository | Purpose |
|------------|---------|
| [enterprise-cloud-platform-conf](https://github.com/rafabu/enterprise-cloud-platform-conf) | Platform deployment configuration (Terragrunt hierarchy) |
| [enterprise-cloud-platform-tgcommon](https://github.com/rafabu/enterprise-cloud-platform-tgcommon) | Shared Terragrunt library |
| [enterprise-cloud-platform-azure](https://github.com/rafabu/enterprise-cloud-platform-azure) | Terraform module library |
| [enterprise-cloud-platform-lib](https://github.com/rafabu/enterprise-cloud-platform-lib) | Platform artefact library (ALZ/ECP artefacts) |

## Roadmap

- [x] Rewrite of the Terragrunt configuration hierarchy on latest Terragrunt — explicit Terragrunt Stacks: each environment declares its units in a `terragrunt.stack.hcl` from reusable templates under `common/units/`
- [ ] Level 0: AVD foundation modules (compute gallery, monitoring, storage)
- [ ] Level 1: AVD management plane (workspaces, host pools, application groups)
- [ ] Level 2: Session host deployment (per-host-pool join type, Intune enrollment, personal vs. multi-session)
- [ ] Entra ID permission management (groups, application group assignments)
- [ ] Azure DevOps pipeline integration (ECP-vended pipelines)
- [ ] Confidential AVD environments (confidential VM session hosts, customer-managed keys, hardened storage and Log Analytics encryption)
- [ ] Developer guide, architecture documentation, and usage guides
