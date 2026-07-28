# Unit-common for the level0/imaging/gallery unit — the single-repo equivalent of
# ECP tgcommon's unit-common.hcl layer. Shared across all environments; included
# last in the chain so its inputs take precedence.

locals {
  unit_azure_tags = {
    workloadBlockName = "avd-imaging-gallery"
  }
}

terraform {
  source = "${get_repo_root()}/src/avd_compute_gallery"
}

inputs = {
  azure_tags = local.unit_azure_tags
}
