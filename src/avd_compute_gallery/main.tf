# ============================================================================
# Enterprise Cloud Platform (ECP) - Terraform Configuration
# ============================================================================
# Module:       Azure Compute Gallery
# Type:         main.tf
# Repository:   enterprise-cloud-platform-wp-avd
# ============================================================================
#
resource "azurerm_resource_group" "gallery" {

  name     = data.azurecaf_name.rg.result
  location = var.azure_location

  tags = var.azure_tags
}
