# Includes merge "inputs", with last include taking precedence over previously defined.
# Expose: allows content (e.g. locals) to be used by "include"

terraform {
  source = "${get_repo_root()}/src/avd_compute_gallery"
}

# Includes
include "root-common" {
  path           = format("%s/common/root-common.hcl", get_repo_root())
  expose         = false
  merge_strategy = "deep"
}

include "root" {
  path           = find_in_parent_folders("root.hcl")
  expose         = false
  merge_strategy = "deep"
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = false
  merge_strategy = "deep"
}

include "level" {
  path           = find_in_parent_folders("level.hcl")
  expose         = false
  merge_strategy = "deep"
}

include "area" {
  path           = find_in_parent_folders("area.hcl")
  expose         = false
  merge_strategy = "deep"
}

locals {
  module_azure_tags = {
    workloadBlockName = "avd-imaging-gallery"
  }
}

inputs = {
  # unit inputs mostly from unit-common.hcl
  azure_tags = local.module_azure_tags
}
