locals {
  # Read all the locals from the different levels to enable overridable locals e.g. for backend configuration
  root_vars  = read_terragrunt_config(format("%s/../../../../root.hcl", get_terragrunt_dir()))
  env_vars   = read_terragrunt_config(format("%s/../../../env.hcl", get_terragrunt_dir()))
  level_vars = read_terragrunt_config(format("%s/../../level.hcl", get_terragrunt_dir()))
  area_vars  = read_terragrunt_config(format("%s/../area.hcl", get_terragrunt_dir()))

  merged_locals = merge(
    local.root_vars.locals,
    local.env_vars.locals,
    local.level_vars.locals,
    local.area_vars.locals,
    # local.unit_common_vars.locals # TODO: Add unit-common.hcl support later
  )

  terraform_command = get_terraform_command()

  ######## ECP Defaults ########

  ecp_azure_main_location = "WestEurope"

  ######## Merged ECP Data Object ########
  ecp_deployment_data_object = {
    deployment_code   = local.merged_locals.ecp_deployment_code
    deployment_env    = local.merged_locals.ecp_deployment_env
    deployment_number = local.merged_locals.ecp_deployment_number
    deployment_area   = local.merged_locals.ecp_deployment_area
    deployment_unit   = try(local.merged_locals.ecp_deployment_unit, "main") # TODO: Add deployment_unit_default variable later
    environment_name  = lower("${local.merged_locals.ecp_deployment_code}-${substr(local.merged_locals.ecp_deployment_env, 0, 1)}${local.merged_locals.ecp_deployment_number}")
  }

  ######## Azure Subscriptions ########
  ecp_workload_subscription_id = coalesce(local.merged_locals.ecp_workload_subscription_id, "00000000-0000-0000-0000-000000000000") # From env.hcl normally

  ######## Provider Versions ########
  tf_version                  = ">= 1.9.0"
  tf_provider_azurerm_version = "~> 4.14.0"

  ############ Tags ############
  root_common_azure_tags = {
    # "hidden-ecpTgUnitRootCommon" = format("%s/root-common.hcl", get_parent_terragrunt_dir())

    createdBy = "ecp-terraform"
  }
}

# remote state logic is in each unit-common.hcl file
# remote_state {}

terraform {
  # Force Terraform to keep trying to acquire a lock for
  # up to 20 minutes if someone else already has the lock
  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()

    arguments = [
      "-lock-timeout=20m"
    ]
  }
  extra_arguments "init" {
    commands = ["init"]
    arguments = [
      "-lock=false" # assure we don't need "Blob Data Contributor"
    ]
  }
  # TODO: Add tfplan_path variable and enable plan output later
  # extra_arguments "plan" {
  #   commands = ["plan"]
  #   arguments = [
  #     "--out=${local.tfplan_path}${basename(path_relative_to_include())}.tfplan",
  #     "-lock=false" # assure we don't need "Blob Data Contributor"
  #   ]
  # }
}

# Generate azurerm provider
generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "azurerm" {
  subscription_id = "${local.ecp_workload_subscription_id}"

  features {}
}
EOF
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = "${local.tf_version}"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "${local.tf_provider_azurerm_version}"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.31"
    }
  }
}
EOF
}

inputs = {
  azure_location = local.ecp_azure_main_location
  azure_resource_name_elements = {
    prefixes      = [local.ecp_deployment_data_object.environment_name]
    name          = local.merged_locals.ecp_deployment_area
    suffixes      = [try(local.merged_locals.ecp_deployment_unit, "main")]
    random_length = try(local.merged_locals.ecp_resource_name_random_length, 0)
  }

  azure_tags = local.root_common_azure_tags

  ecp_environment_name = local.ecp_deployment_data_object.environment_name

  # ECP Platform Azure Subscriptions variables
  # ecp_management_subscription_id = local.ecp_management_subscription_id # TODO: Add management subscription support later
}
