include "global" {
  path   = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

inputs = {
  parameter_name = get_env("PARAMETER_NAME", "/apps/shared/devops/sydney")
}

locals {
  global = include.global.locals
}

terraform {
  source = "${get_repo_root()}//deploy/tf/ssm-parameter"
}
