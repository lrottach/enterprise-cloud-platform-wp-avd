# Unit template — only valid after `terragrunt stack generate` places it inside an
# environment tree (environments/<env>/.terragrunt-stack/level<N>/<area>/<unit>),
# where the parent-folder includes below resolve.

terraform {
  source = "${get_repo_root()}/src/avd_compute_gallery"
}

include "root_common" {
  path           = "${get_repo_root()}/common/root-common.hcl"
  merge_strategy = "deep"
  expose         = false
}

include "root" {
  path           = find_in_parent_folders("root.hcl")
  merge_strategy = "deep"
  expose         = false
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  merge_strategy = "deep"
  expose         = false
}

inputs = {
  azure_tags = {
    workloadBlockName = values.workload_block_name
  }
}
