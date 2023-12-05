dependency "s3" {
  config_path = "../s3"
  mock_outputs = {
    wrapper = {
      sample-django-app-bucket = {
        s3_bucket_arn    = "arn:aws:s3:::sample-django-app-123456789012"
        s3_bucket_id     = "sample-django-app-123456789012"
        s3_bucket_region = "ap-southeast-2"
      }
    }
  }
}

include "global" {
  path   = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

inputs = {
  app_hostnames  = ["api", "sample-django-app"]
  db_secret_name = "/rds/stefan-db/primary/evaluation/api"
  parameter_name = get_env("PARAMETER_NAME", "/apps/shared/devops/sydney")
  ecr_registry   = get_env("ECR_REGISTRY", "450356697252.dkr.ecr.ap-southeast-2.amazonaws.com")
  s3_buckets     = dependency.s3.outputs.wrapper
}

locals {
  global = include.global.locals
}

terraform {
  source = "${get_repo_root()}//deploy/tf/ecs"
}
