include "global" {
  path   = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

inputs = {
  items = {
    "sample-django-app-${local.global.environment}-${local.global.aws_account}" = {
      bucket                   = "sample-django-app-${local.global.environment}-${local.global.aws_account}"
      acl                      = "public-read"
      block_public_acls        = false
      block_public_policy      = false
      ignore_public_acls       = false
      control_object_ownership = true
      object_ownership         = "BucketOwnerPreferred"
      restrict_public_buckets  = false
    }
  }
}

locals {
  global = include.global.locals
}

terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws//wrappers?version=3.15.1"
}
