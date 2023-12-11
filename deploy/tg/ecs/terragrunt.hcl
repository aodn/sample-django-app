dependency "s3" {
  config_path = "../s3"
  mock_outputs = {
    wrapper = {
      "sample-django-app-${local.global.environment}-${local.global.aws_account}" = {
        s3_bucket_arn    = "arn:aws:s3:::sample-django-app-${local.global.environment}-${local.global.aws_account}"
        s3_bucket_id     = "sample-django-app-${local.global.environment}-${local.global.aws_account}"
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
  app_name    = get_env("APP_NAME")
  environment = local.global.environment

  # fetch the ssm parameter names
  alb_parameter_name = get_env("ALB_PARAMETER_NAME")
  ecr_parameter_name = get_env("ECR_PARAMETER_NAME")
  rds_parameter_name = get_env("RDS_PARAMETER_NAME")

  # DNS hostnames to associate with the container
  app_hostnames = ["api-${local.global.environment}"]

  # get docker environment variable values with default fallback values
  allowed_hosts     = get_env("ALLOWED_HOSTS", "*")
  allowed_cidr_nets = get_env("ALLOWED_CIDR_NETS", "")
  django_secret_key = get_env("DJANGO_SECRET_KEY", "changeme")
  db_host           = get_env("DB_HOST", "")
  db_name           = get_env("DB_NAME", "api")
  db_user           = get_env("DB_USER", "api")
  db_secret_name    = get_env("DB_SECRET_NAME", "/rds/stefan-db/primary/evaluation/api")
  db_secret_region  = get_env("DB_SECRET_REGION", "ap-southeast-2")
  s3_storage_bucket_name = get_env("S3_STORAGE_BUCKET_NAME",
  dependency.s3.outputs.wrapper["sample-django-app-${local.global.environment}-${local.global.aws_account}"].s3_bucket_id)
  s3_storage_bucket_region = get_env("S3_STORAGE_BUCKET_REGION",
  dependency.s3.outputs.wrapper["sample-django-app-${local.global.environment}-${local.global.aws_account}"].s3_bucket_region)
}

locals {
  global = include.global.locals
}

terraform {
  source = "${get_repo_root()}//deploy/tf/ecs"
}
