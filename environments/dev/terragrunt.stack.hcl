# Dev environment stack — declares every deployment unit for this environment.
# `path` encodes level/area/unit and is parsed by common/root-common.hcl for
# naming, tagging, and the remote state key. Regenerate with `terragrunt stack generate`.

unit "gallery" {
  source = "../../common/units/avd-gallery"
  path   = "level0/imaging/gallery"

  values = {
    workload_block_name = "avd-imaging-gallery"
  }
}
