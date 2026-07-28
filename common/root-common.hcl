locals {
  # Layer discovery — depth-independent (find_in_parent_folders evaluates from the
  # including unit's directory), an improvement over ECP's fixed ../../.. paths
  root_vars  = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  env_vars   = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  level_vars = read_terragrunt_config(find_in_parent_folders("level.hcl"))
  area_vars  = read_terragrunt_config(find_in_parent_folders("area.hcl"))

  merged_locals = merge(
    local.root_vars.locals,
    local.env_vars.locals,
    local.level_vars.locals,
    local.area_vars.locals,
  )

  ######## Deployment Identity ########

  ecp_deployment_data_object = {
    deployment_code   = local.merged_locals.ecp_deployment_code
    deployment_env    = local.merged_locals.ecp_deployment_env
    deployment_number = local.merged_locals.ecp_deployment_number
    deployment_level  = local.merged_locals.ecp_deployment_level
    deployment_area   = local.merged_locals.ecp_deployment_area
    deployment_unit   = try(local.merged_locals.ecp_deployment_unit, basename(get_original_terragrunt_dir()))
    environment_name  = lower("${local.merged_locals.ecp_deployment_code}-${substr(local.merged_locals.ecp_deployment_env, 0, 1)}${local.merged_locals.ecp_deployment_number}")
  }

  ######## Azure Context ########
  # Resolution order: pipeline environment variable -> hcl configuration (standalone mode).

  ecp_entra_tenant_id          = get_env("ECP_TG_TENANT_ID", try(local.merged_locals.ecp_entra_tenant_id, ""))
  ecp_workload_subscription_id = get_env("ECP_TG_SUBSCRIPTION_ID", try(local.merged_locals.ecp_workload_subscription_id, ""))

  ######## Remote State Backend ########
  # Three-tier resolution:
  #   1. ECP_TG_BACKEND_LEVEL{N}_* — ECP platform pipeline compatibility (per-level storage accounts)
  #   2. ECP_TG_BACKEND_*          — primary for this pattern (one vended storage account per subscription)
  #   3. ecp_backend_* hcl locals  — standalone fallback (env.hcl)

  backend_level = local.ecp_deployment_data_object.deployment_level

  backend_level_env_present = alltrue([
    get_env("ECP_TG_BACKEND_LEVEL${local.backend_level}_SUBSCRIPTION_ID", "") != "",
    get_env("ECP_TG_BACKEND_LEVEL${local.backend_level}_RESOURCE_GROUP_NAME", "") != "",
    get_env("ECP_TG_BACKEND_LEVEL${local.backend_level}_NAME", "") != "",
    get_env("ECP_TG_BACKEND_LEVEL${local.backend_level}_CONTAINER", "") != "",
  ])

  backend_env_present = alltrue([
    get_env("ECP_TG_BACKEND_SUBSCRIPTION_ID", "") != "",
    get_env("ECP_TG_BACKEND_RESOURCE_GROUP_NAME", "") != "",
    get_env("ECP_TG_BACKEND_NAME", "") != "",
  ])

  backend_config = local.backend_level_env_present ? {
    subscription_id      = get_env("ECP_TG_BACKEND_LEVEL${local.backend_level}_SUBSCRIPTION_ID")
    resource_group_name  = get_env("ECP_TG_BACKEND_LEVEL${local.backend_level}_RESOURCE_GROUP_NAME")
    storage_account_name = get_env("ECP_TG_BACKEND_LEVEL${local.backend_level}_NAME")
    container_name       = get_env("ECP_TG_BACKEND_LEVEL${local.backend_level}_CONTAINER")
    } : local.backend_env_present ? {
    subscription_id      = get_env("ECP_TG_BACKEND_SUBSCRIPTION_ID")
    resource_group_name  = get_env("ECP_TG_BACKEND_RESOURCE_GROUP_NAME")
    storage_account_name = get_env("ECP_TG_BACKEND_NAME")
    container_name       = get_env("ECP_TG_BACKEND_CONTAINER", "tfstate")
    } : {
    subscription_id      = try(local.merged_locals.ecp_backend_subscription_id, "")
    resource_group_name  = try(local.merged_locals.ecp_backend_resource_group_name, "")
    storage_account_name = try(local.merged_locals.ecp_backend_storage_account_name, "")
    container_name       = try(local.merged_locals.ecp_backend_container_name, "tfstate")
  }

  # Fail with a readable message when no tier provided a backend (file() is the
  # established Terragrunt trick for custom errors — the "file name" is the message).
  # Only enforced for commands that touch state, so lint/validate work without config.
  backend_required = contains(["init", "plan", "apply", "destroy", "import", "refresh", "state"], get_terraform_command())
  backend_storage_account_name = length(local.backend_config.storage_account_name) > 0 ? local.backend_config.storage_account_name : (
    local.backend_required ? file("ERROR: remote state backend not configured — set ECP_TG_BACKEND_* environment variables (see .env.example) or ecp_backend_* locals in env.hcl") : ""
  )

  # Env-prefixed, unique across environments even on a shared storage account:
  # environments/dev/level0/imaging/gallery -> dev/level0/imaging/gallery.tfstate
  state_key = "${trimprefix(replace(get_path_from_repo_root(), "\\", "/"), "environments/")}.tfstate"

  ######## Terraform & Provider Versions ########
  # Pinned centrally — modules must NOT declare required_providers themselves.

  tf_version = ">= 1.15.0"

  provider_versions = {
    azapi    = "~> 2.11" # preferred provider for Azure resources
    azurerm  = "~> 4.81" # fallback where azapi is impractical
    azuread  = "~> 3.9"  # 3.9+ contains PIM fixes
    azurecaf = "~> 1.2"  # resource naming
    time     = "~> 0.13"
    random   = "~> 3.7"
  }

  ######## Tags ########

  root_common_azure_tags = {
    createdBy = "ecp-terraform"
  }
}

remote_state {
  backend = "azurerm"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    tenant_id            = local.ecp_entra_tenant_id
    subscription_id      = local.backend_config.subscription_id
    resource_group_name  = local.backend_config.resource_group_name
    storage_account_name = local.backend_storage_account_name
    container_name       = local.backend_config.container_name
    key                  = local.state_key
    use_azuread_auth     = true # ECP guardrail: Entra ID auth only, never access keys
  }

  disable_init = tobool(get_env("TERRAGRUNT_DISABLE_INIT", "false"))
}

terraform {
  # Keep trying to acquire the state lock for up to 20 minutes (parallel pipeline runs)
  extra_arguments "retry_lock" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=20m"]
  }

  extra_arguments "init" {
    commands  = ["init"]
    arguments = ["-lock=false"] # assure init does not require "Storage Blob Data Contributor"
  }
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "azapi" {
      tenant_id       = "${local.ecp_entra_tenant_id}"
      subscription_id = "${local.ecp_workload_subscription_id}"
    }

    provider "azurerm" {
      tenant_id           = "${local.ecp_entra_tenant_id}"
      subscription_id     = "${local.ecp_workload_subscription_id}"
      storage_use_azuread = true

      features {}
    }

    provider "azuread" {
      tenant_id = "${local.ecp_entra_tenant_id}"
    }

    provider "azurecaf" {}
  EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      required_version = "${local.tf_version}"

      required_providers {
        azapi = {
          source  = "Azure/azapi"
          version = "${local.provider_versions.azapi}"
        }
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "${local.provider_versions.azurerm}"
        }
        azuread = {
          source  = "hashicorp/azuread"
          version = "${local.provider_versions.azuread}"
        }
        azurecaf = {
          source  = "aztfmod/azurecaf"
          version = "${local.provider_versions.azurecaf}"
        }
        time = {
          source  = "hashicorp/time"
          version = "${local.provider_versions.time}"
        }
        random = {
          source  = "hashicorp/random"
          version = "${local.provider_versions.random}"
        }
      }
    }
  EOF
}

inputs = {
  azure_location = try(local.merged_locals.ecp_azure_main_location, "westeurope")

  azure_resource_name_elements = {
    prefixes      = [local.ecp_deployment_data_object.environment_name]
    name          = local.ecp_deployment_data_object.deployment_area
    suffixes      = [local.ecp_deployment_data_object.deployment_unit]
    random_length = try(local.merged_locals.ecp_resource_name_random_length, 0)
  }

  azure_tags = local.root_common_azure_tags

  ecp_environment_name = local.ecp_deployment_data_object.environment_name
}
