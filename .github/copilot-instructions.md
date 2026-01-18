# GitHub Copilot Instructions - Enterprise Cloud Platform AVD

Repository instructions for the Enterprise Cloud Platform (ECP) Azure Virtual Desktop Workload Pattern.

## Project Context

This repository implements the Azure Virtual Desktop (AVD) Workload Pattern for ECP using Terraform and Terragrunt with a layered architecture (Levels 0-3).

## Allowed Languages

Use ONLY these languages in this repository:

- **Terragrunt** (`.hcl`) - Environment configuration
- **Terraform** (`.tf`) - Infrastructure modules
- **PowerShell** (`.ps1`) - Automation scripts (cross-platform)
- **Bash** (`.sh`) - Shell scripts
- **YAML** (`.yaml`, `.yml`) - Configuration files

**NOT ALLOWED:** Python, JavaScript, TypeScript, or other languages. Never suggest or generate code in these languages.

## Technology Stack

- Terraform >= 1.9.0
- Azure Provider ~> 4.14.0
- Terragrunt (Latest)
- Azure CAF Naming Provider
- Default Azure Region: WestEurope

## Project Structure

```
├── common/                  # Shared Terragrunt logic
├── environments/{env}/      # Environment configs (dev, test, prod)
│   └── level{N}/{area}/{unit}/
└── src/level{N}/{area}/{unit}/  # Terraform modules
```

## Deployment Levels

- **Level 0:** Foundation (Storage, Compute Gallery, Image Builder)
- **Level 1:** Management Plane (Workspaces, Host Pools, App Groups)
- **Level 2:** Session Hosts (VMs, Domain Join, Agents)
- **Level 3:** Configuration (Images, FSLogix, MSIX)

## Naming Conventions

Environment name formula: `{deployment_code}-{env_first_letter}{deployment_number}`
Examples: `ecp-d1` (dev), `ecp-t1` (test), `ecp-p1` (prod)

Use Azure CAF naming provider with prefixes (environment name), name (area), and suffixes (unit).

## Code Style Guidelines

1. Group ECP framework variables first, then module-specific variables
2. Use `try()` function for optional object properties
3. Use clear, descriptive resource and variable names
4. Always pass `azure_tags` to resources
5. Add comments for complex logic only, not obvious code
6. Split resources into logical files (not everything in main.tf)

## ECP Framework Variables

Always include these variables in Terraform modules:

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
}

variable "azure_tags" {
  type    = map(string)
  default = {}
}
```

## Terragrunt Configuration Chain

Configuration inheritance: `root.hcl -> env.hcl -> level.hcl -> area.hcl -> terragrunt.hcl`

Keep `terragrunt.hcl` files focused on inputs only.

## Common Commands

```bash
terragrunt init          # Initialize
terragrunt plan          # Plan changes
terragrunt apply         # Apply changes
terragrunt run-all plan  # Plan entire level
terraform fmt -recursive # Format Terraform
terragrunt hclfmt        # Format Terragrunt
```

## Key References

- `common/root-common.hcl` - Provider generation, shared configuration
- `src/level0/imaging/gallery/` - Reference module implementation
- Existing modules in `src/` are authoritative for patterns
