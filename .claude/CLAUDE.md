# CLAUDE.md - Enterprise Cloud Platform AVD Workload Pattern

> Claude Code instructions for the Enterprise Cloud Platform (ECP) Azure Virtual Desktop Workload Pattern repository.

## Project Overview

This repository implements the **Azure Virtual Desktop (AVD) Workload Pattern** for the Enterprise Cloud Platform (ECP). It provides a production-ready, scalable AVD infrastructure deployment using Terraform and Terragrunt with a layered architecture approach.

**Key Characteristics:**
- Builds on ECP foundation services (VNets, Log Analytics, State Storage)
- Uses layered deployment architecture (Levels 0-3)
- Follows ECP naming conventions and tagging standards
- Implements DRY configuration through Terragrunt

## Technology Stack

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | >= 1.9.0 | Infrastructure as Code |
| Azure Provider | ~> 4.14.0 | Azure resource management |
| Terragrunt | Latest | DRY configuration management |
| Azure CAF Naming | Latest | Resource naming standardization |
| PowerShell | <= 7.0 | Cross-platform automation |

**Default Azure Region:** WestEurope

## Allowed Languages and Tools

Use ONLY the following languages in this repository:

| Language | Extensions | Use Case |
|----------|------------|----------|
| Terragrunt | `.hcl` | Environment configuration |
| Terraform | `.tf` | Infrastructure modules |
| PowerShell | `.ps1` | Automation scripts (cross-platform) |
| Bash | `.sh` | Shell scripts |
| YAML | `.yaml`, `.yml` | Configuration files |

**NOT ALLOWED:** Python, JavaScript, TypeScript, or other languages. This maintains consistency with ECP standards.

## Project Structure

```
enterprise-cloud-platform-wp-avd/
├── common/
│   └── root-common.hcl          # Shared Terragrunt logic, provider generation
├── environments/
│   ├── root.hcl                 # Environment root config
│   └── {env}/                   # Environment (dev, test, prod)
│       ├── env.hcl              # Environment variables
│       └── level{N}/            # Deployment level
│           ├── level.hcl        # Level configuration
│           └── {area}/          # Functional area
│               ├── area.hcl     # Area configuration
│               └── {unit}/      # Deployment unit
│                   └── terragrunt.hcl
├── src/
│   ├── level0/                  # Foundation modules
│   ├── level1/                  # Management plane modules
│   ├── level2/                  # Session host modules
│   └── level3/                  # Configuration modules
└── root.hcl                     # Root Terragrunt config
```

### Directory Purposes

- **`src/`** - Terraform modules organized by deployment level and area
- **`environments/`** - Environment-specific Terragrunt configurations
- **`common/`** - Shared Terragrunt logic (provider generation, inputs)

## Deployment Architecture

### Level 0: AVD Foundation
- Storage Accounts (FSLogix, MSIX)
- Azure Compute Gallery
- Azure Image Builder Infrastructure
- Private Endpoints

### Level 1: Management Plane
- AVD Workspaces
- Host Pools (Pooled & Personal)
- Application Groups
- Scaling Plans

### Level 2: Session Hosts
- Session Host VMs
- Domain Join (Azure AD or AD DS)
- AVD Agent Registration
- Monitoring Agents

### Level 3: Configuration
- Custom Images
- FSLogix Profile Management
- MSIX App Attach
- Application Automation

## Terragrunt Configuration Patterns

### Configuration Inheritance Chain
```
root.hcl -> env.hcl -> level.hcl -> area.hcl -> terragrunt.hcl
```

Locals from all levels are deep-merged in `root-common.hcl`.

### Key Configuration Files

| File | Purpose |
|------|---------|
| `root.hcl` | Root-level defaults |
| `env.hcl` | Environment variables (subscription ID, deployment code) |
| `level.hcl` | Level-specific settings |
| `area.hcl` | Area configuration (deployment area name) |
| `terragrunt.hcl` | Unit-specific configuration |
| `common/root-common.hcl` | Provider generation, shared inputs |

### Provider Auto-Generation
The `root-common.hcl` automatically generates `providers.tf` and `versions.tf` files with:
- Azure provider configuration
- Subscription ID injection
- Required provider versions

### State Locking
Lock timeout is set to **20 minutes** for concurrent operations.

## Terraform Module Patterns

### Standard File Structure
```
src/level{N}/{area}/{unit}/
├── main.tf              # Resource group and primary resources
├── {resource}.tf        # Resource-specific files
├── variables.tf         # Input variables
├── outputs.tf           # Output values
└── resource_name_data.tf # Azure CAF naming data sources
```

### File Header Format
```hcl
# ============================================================================
# Enterprise Cloud Platform (ECP) - Terraform Configuration
# ============================================================================
# Module:       {Module Name}
# Type:         {File Type}
# Repository:   enterprise-cloud-platform-wp-avd
# ============================================================================
```

### Standard Variables Pattern
Always include these ECP framework variables:

```hcl
variable "azure_location" {
  type = string
}

variable "azure_resource_name_elements" {
  type = object({
    prefixes      = optional(list(string))
    suffixes      = optional(list(string))
    name          = optional(string)
    random_length = optional(number)
  })
  description = "Object containing naming components for azurecaf_name data source."
}

variable "azure_tags" {
  type    = map(string)
  default = {}
}
```

### Azure CAF Naming Pattern
```hcl
data "azurecaf_name" "rg" {
  name          = try(var.azure_resource_name_elements.name, null)
  resource_type = "azurerm_resource_group"
  prefixes      = try(var.azure_resource_name_elements.prefixes, [])
  suffixes      = try(var.azure_resource_name_elements.suffixes, [])
  random_length = try(var.azure_resource_name_elements.random_length, 0)
  clean_input   = true
  use_slug      = true
}
```

## Naming Conventions

### Environment Name Formula
```
{deployment_code}-{env_first_letter}{deployment_number}
```

**Examples:**
- `ecp-d1` - ECP Development environment 1
- `ecp-t1` - ECP Test environment 1
- `ecp-p1` - ECP Production environment 1

### Resource Naming
Uses Azure CAF naming provider with:
- **Prefixes:** Environment name (e.g., `ecp-d1`)
- **Name:** Deployment area
- **Suffixes:** Deployment unit

## ECP Integration Points

This workload pattern integrates with ECP foundation services:

| ECP Service | Integration |
|-------------|-------------|
| Virtual Networks | AVD resources deployed into ECP subnets |
| Log Analytics | Diagnostics sent to ECP workspace |
| State Storage | Terraform state in ECP storage account |
| Private DNS | AVD uses ECP DNS zones |
| Key Vault | Secrets management (optional) |

## Common Tasks and Commands

### Initialize Configuration
```bash
cd environments/dev/level0/imaging/gallery
terragrunt init
```

### Plan Changes
```bash
terragrunt plan
```

### Apply Changes
```bash
terragrunt apply
```

### Format Code
```bash
# Terraform files
terraform fmt -recursive

# Terragrunt files
terragrunt hclfmt
```

### Validate Configuration
```bash
terraform validate
terragrunt validate
```

### Run All in Level
```bash
cd environments/dev/level0
terragrunt run-all plan
terragrunt run-all apply
```

## Code Style Guidelines

1. **Variable Organization:** Group ECP framework variables first, then module-specific variables
2. **Use `try()` Function:** For optional object properties to avoid null errors
3. **Descriptive Names:** Use clear, descriptive resource and variable names
4. **Consistent Tagging:** Always pass `azure_tags` to resources
5. **Comments:** Add comments for complex logic, not obvious code
6. **File Separation:** Split resources into logical files (not everything in main.tf)

## Common Issues and Solutions

### State Lock Timeout
**Issue:** State lock held by another process
**Solution:** Wait up to 20 minutes (configured timeout) or manually unlock if safe

### Provider Version Mismatch
**Issue:** Provider version conflicts
**Solution:** Check `root-common.hcl` for required versions, run `terragrunt init -upgrade`

### Naming Conflicts
**Issue:** Resource name already exists
**Solution:** Adjust `azure_resource_name_elements` suffixes or add random_length

### Missing ECP Foundation
**Issue:** Cannot find VNet/Subnet/Log Analytics
**Solution:** Ensure ECP foundation is deployed first; check subscription ID in env.hcl

## Key Files Reference

| File | Purpose |
|------|---------|
| `common/root-common.hcl` | Provider generation, shared configuration |
| `README.md` | Architecture and ECP integration documentation |
| `src/level0/imaging/gallery/` | Reference module implementation |
| `.devcontainer/devcontainer.json` | Development environment configuration |
| `.gitignore` | Terraform/Terragrunt ignore patterns |

## Trust Guidelines

1. **Source of Truth:** This file provides conventions; `root-common.hcl` and existing modules are authoritative for patterns
2. **README.md:** Refer to README.md for architecture decisions and ECP integration details
3. **Consistency:** Follow existing patterns in `src/` modules when creating new ones
4. **Breaking Changes:** Major changes to Terragrunt hierarchy require team review
5. **Documentation:** Update this file when patterns change
