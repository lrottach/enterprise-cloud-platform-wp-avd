# ============================================================================
# Enterprise Cloud Platform (ECP) - Terraform Configuration
# ============================================================================
# Module:       Azure Compute Gallery
# Type:         variables.tf
# Repository:   enterprise-cloud-platform-wp-avd
# ============================================================================

# Variables provided by Enterprise Cloud Platform (ECP) Framework
# ============================================================================
variable "azure_location" {
  type = string
}

variable "azure_resource_name_elements" {
  type = object({
    prefixes      = optional(list(string))
    suffixes      = optional(list(string))
    name          = optional(string)
    random_length = optional(number)
  })
  description = "Object containing naming components to be used by the azurecaf_name data source to generate resource names."
}

variable "azure_tags" {
  type    = map(string)
  default = {}
}

# Module specific variables
# ============================================================================

variable "gallery_description" {
  type        = string
  description = "Description of the Azure Compute Gallery."
  default     = "Azure Compute Gallery created by Enterprise Cloud Platform (ECP)."
}
