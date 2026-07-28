# Includes merge "inputs" deep, with the last include taking precedence.

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

include "level" {
  path           = find_in_parent_folders("level.hcl")
  merge_strategy = "deep"
  expose         = false
}

include "area" {
  path           = find_in_parent_folders("area.hcl")
  merge_strategy = "deep"
  expose         = false
}

include "unit_common" {
  path           = "${get_repo_root()}/common/units/l0-img-gallery.hcl"
  merge_strategy = "deep"
  expose         = false
}
