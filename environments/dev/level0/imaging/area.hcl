locals {
  ecp_deployment_area = "imaging"

  area_azure_tags = {}
}

inputs = {
  azure_tags = local.area_azure_tags
}
