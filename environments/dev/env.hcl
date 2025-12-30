locals {
  ecp_workload_subscription_id = ""

  ecp_deployment_env = "dev"

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
