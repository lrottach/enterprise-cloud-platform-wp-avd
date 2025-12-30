locals {
  ecp_entra_tenant_id = "cb5d5a54-23f2-447e-8850-d43b278d1d15"

  ecp_deployment_code   = "dark" # Think of it as "customer code"
  ecp_deployment_number = "1"

  ecp_azure_main_location = "northeurope"

  root_azure_tags = {
    businessUnit  = "virtual-desktop-team"
    workloadName  = "eavd"
    workloadOwner = "admin-a_lrottach@darkcontoso.com"
  }
}

inputs = merge(
  {
    azure_tags = local.root_azure_tags
  },
  length(try(local.ecp_azure_main_location, "")) > 0 ? {
    azure_location = local.ecp_azure_main_location
  } : {},
)
