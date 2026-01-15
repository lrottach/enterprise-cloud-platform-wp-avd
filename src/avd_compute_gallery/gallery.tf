# ============================================================================
# Enterprise Cloud Platform (ECP) - Terraform Configuration
# ============================================================================
# Module:       Azure Compute Gallery
# Type:         gallery.tf
# Repository:   enterprise-cloud-platform-wp-avd
# ============================================================================
#

resource "azurerm_shared_image_gallery" "gallery" {
  name                = replace(data.azurecaf_name.rg.result, "-rg-", "-acg-")
  resource_group_name = azurerm_resource_group.gallery.name
  location            = var.azure_location
  description         = var.gallery_description

  tags = var.azure_tags
}
