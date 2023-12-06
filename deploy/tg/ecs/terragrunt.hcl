dependency "ssm" {
  config_path = "../ssm-parameter"
  mock_outputs = {
    parameter_values = {
      "alb_arn"            = "arn:aws:elasticloadbalancing:ap-southeast-2:450356697252:loadbalancer/app/shared-alb-devops-sydney/45b0c41ea845014b"
      "alb_dns_name"       = "shared-alb-devops-sydney-387767645.ap-southeast-2.elb.amazonaws.com"
      "alb_https_listener" = "arn:aws:elasticloadbalancing:ap-southeast-2:450356697252:listener/app/shared-alb-devops-sydney/45b0c41ea845014b/ecf16c7cec52b0c9"
      "alb_zone_id"        = "Z1GM3OXH4ZPM65"
      "dns_domain_name"    = "gamma.aodn.org.au"
      "dns_zone_id"        = "Z03033261P68C2JNNSWPQ"
      "rds_url"            = "stefan-db-rds-primary-evaluation.gamma.aodn.org.au"
      "vpc_cidr"           = "10.32.0.0/16"
      "vpc_id"             = "vpc-006dcec5d49e40003"
      "vpc_private_subnets" = [
        "subnet-06665685d5a875465",
        "subnet-0df67c37ed85ed7f2",
        "subnet-075ea5fbe179b2b9a",
      ]
      "vpc_subnet_cidrs" = {
        "private" = [
          "10.32.48.0/20",
          "10.32.64.0/20",
          "10.32.80.0/20",
        ]
      }
    }
  }
}

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
  environment = local.global.environment

  # DNS hostnames to associate with the container
  app_hostnames = ["api-${local.global.environment}"]

  # container image repository and tag
  ecr_registry   = get_env("ECR_REGISTRY", "450356697252.dkr.ecr.ap-southeast-2.amazonaws.com")
  ecr_repository = get_env("ECR_REPOSITORY", "api")
  image_tag      = get_env("IMAGE_TAG", "latest")

  # Shared infrastructure details
  alb_dns_name     = dependency.ssm.outputs.parameter_values.alb_dns_name
  alb_listener_arn = dependency.ssm.outputs.parameter_values.alb_https_listener
  alb_zone_id      = dependency.ssm.outputs.parameter_values.alb_zone_id
  dns_zone_id      = dependency.ssm.outputs.parameter_values.dns_zone_id
  subnet_ids       = dependency.ssm.outputs.parameter_values.vpc_private_subnets
  vpc_cidr         = dependency.ssm.outputs.parameter_values.vpc_cidr
  vpc_id           = dependency.ssm.outputs.parameter_values.vpc_id

  # get docker environment variable values with default fallback values
  allowed_hosts            = get_env("ALLOWED_HOSTS", "*")
  allowed_cidr_nets        = get_env("ALLOWED_CIDR_NETS", join(",", dependency.ssm.outputs.parameter_values.vpc_subnet_cidrs.private))
  django_secret_key        = get_env("DJANGO_SECRET_KEY", "changeme")
  db_host                  = get_env("DB_HOST", dependency.ssm.outputs.parameter_values.rds_url)
  db_name                  = get_env("DB_NAME", "api")
  db_user                  = get_env("DB_USER", "api")
  db_secret_name           = get_env("DB_SECRET_NAME", "/rds/stefan-db/primary/evaluation/api")
  db_secret_region         = get_env("DB_SECRET_REGION", "ap-southeast-2")
  s3_storage_bucket_name   = get_env("S3_STORAGE_BUCKET_NAME",
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
