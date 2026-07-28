locals {
  ecp_deployment_level = "0"

  level_azure_tags = {}
}

inputs = {
  azure_tags = local.level_azure_tags
}
