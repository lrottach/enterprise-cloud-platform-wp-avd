---
applyTo: "**/*.hcl"
---

# Terragrunt Instructions for ECP AVD

## Configuration Inheritance Chain

Terragrunt configurations follow this hierarchy:

```
root.hcl -> env.hcl -> level.hcl -> area.hcl -> terragrunt.hcl
```

Locals from all levels are deep-merged in `common/root-common.hcl`.

## Key Configuration Files

| File | Purpose |
|------|---------|
| `root.hcl` | Root-level defaults |
| `env.hcl` | Environment variables (subscription ID, deployment code) |
| `level.hcl` | Level-specific settings |
| `area.hcl` | Area configuration (deployment area name) |
| `terragrunt.hcl` | Unit-specific configuration (inputs only) |
| `common/root-common.hcl` | Provider generation, shared inputs |

## Directory Structure

```
environments/
├── root.hcl
└── {env}/                   # dev, test, prod
    ├── env.hcl
    └── level{N}/            # 0, 1, 2, 3
        ├── level.hcl
        └── {area}/
            ├── area.hcl
            └── {unit}/
                └── terragrunt.hcl
```

## Unit `terragrunt.hcl` Pattern

Keep unit configurations focused on inputs:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "root_common" {
  path   = find_in_parent_folders("root-common.hcl")
  expose = true
}

locals {
  # Unit-specific locals if needed
}

inputs = {
  # Module-specific inputs
  some_setting = "value"
}
```

## Environment `env.hcl` Pattern

```hcl
locals {
  environment         = "dev"
  deployment_number   = "1"
  deployment_code     = "ecp"
  azure_subscription_id = "00000000-0000-0000-0000-000000000000"
}
```

## Level `level.hcl` Pattern

```hcl
locals {
  deployment_level = "level0"
}
```

## Area `area.hcl` Pattern

```hcl
locals {
  deployment_area = "imaging"
}
```

## Dependencies Between Units

Use `dependency` blocks for cross-module references:

```hcl
dependency "gallery" {
  config_path = "../gallery"
}

inputs = {
  gallery_id = dependency.gallery.outputs.gallery_id
}
```

## Provider Auto-Generation

The `root-common.hcl` automatically generates:
- `providers.tf` with Azure provider configuration
- `versions.tf` with required provider versions
- Subscription ID injection from `env.hcl`

Do not create these files manually in modules.

## State Configuration

State is stored in ECP foundation storage account. Lock timeout is 20 minutes.

## Common Commands

```bash
# Single unit
cd environments/dev/level0/imaging/gallery
terragrunt init
terragrunt plan
terragrunt apply

# Entire level
cd environments/dev/level0
terragrunt run-all plan
terragrunt run-all apply

# Format Terragrunt files
terragrunt hclfmt
```

## Best Practices

1. Keep `terragrunt.hcl` files minimal and focused on inputs
2. Use `dependency` blocks instead of hardcoding resource IDs
3. Define environment-specific values in `env.hcl`
4. Use `expose = true` in includes when accessing parent locals
5. Follow the deployment level order: Level 0 -> 1 -> 2 -> 3
