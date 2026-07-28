locals {
  ecp_deployment_env = "dev"

  # Standalone: set here; ECP pipeline: ECP_TG_SUBSCRIPTION_ID wins
  ecp_workload_subscription_id = ""

  # Standalone remote state fallback (tier 3) — leave empty when deploying on ECP,
  # where the pipeline provides ECP_TG_BACKEND_* environment variables
  ecp_backend_subscription_id      = ""
  ecp_backend_resource_group_name  = ""
  ecp_backend_storage_account_name = ""
  ecp_backend_container_name       = "tfstate"

  env_azure_tags = {
    environment = local.ecp_deployment_env
  }
}

inputs = merge(
  {
    azure_tags = local.env_azure_tags
  },
  length(try(local.ecp_azure_main_location, "")) > 0 ? {
    azure_location = local.ecp_azure_main_location
  } : {},
)
