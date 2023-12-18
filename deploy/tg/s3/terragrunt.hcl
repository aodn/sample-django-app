include "global" {
  path   = find_in_parent_folders("global.hcl")
  expose = true
}

inputs = {
  defaults = {
    attach_deny_insecure_transport_policy = true
    server_side_encryption_configuration = {
      rule = {
        bucket_key_enabled = true
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
      }
    }
  }

  items = {
    "sample-django-app-${local.global.environment}-${get_aws_account_id()}" = {
      bucket                   = "sample-django-app-${local.global.environment}-${get_aws_account_id()}"
      acl                      = "public-read"
      block_public_acls        = false
      block_public_policy      = false
      ignore_public_acls       = false
      control_object_ownership = true
      object_ownership         = "BucketOwnerPreferred"
      restrict_public_buckets  = false
    }
    "django-extra-bucket-${local.global.environment}-${get_aws_account_id()}" = {
      create = local.global.environment == "production" ? true : false
      bucket = "django-extra-bucket-${local.global.environment}-${get_aws_account_id()}"
    }
  }
}

locals {
  global = include.global.locals
}

terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws//wrappers?version=3.15.1"
}
