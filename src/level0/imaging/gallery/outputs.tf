# ============================================================================
# Enterprise Cloud Platform (ECP) - Terraform Configuration
# ============================================================================
# Module:       Azure Compute Gallery
# Type:         outputs.tf
# Repository:   enterprise-cloud-platform-wp-avd
# ============================================================================
#
output "gallery_rg_id" {
  value = azurerm_resource_group.gallery.id
}

output "gallery_rg_name" {
  value = azurerm_resource_group.gallery.name
}
