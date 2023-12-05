locals {
  # are we running in CI environment?
  is_ci          = can(get_env("CI"))
  aws_account_id = trim(run_cmd("--terragrunt-quiet", "sh", "-c", "aws sts get-caller-identity --query=Account 2> /dev/null || true"), "\"")
  aws_role_name  = local.is_ci ? "TempGithubActionsRole" : try(get_env("TG_ROLE_NAME", "AodnTerraformAdminRole"))
  aws_account    = local.is_ci ? get_env("AWS_ACCOUNT_ID") : local.aws_account_id
  aws_region     = get_env("AWS_REGION", "ap-southeast-2")
  state_bucket   = "tfstate-${local.aws_account}-${local.aws_region}"
  state_key      = "apps/${basename(get_repo_root())}/${basename(get_terragrunt_dir())}.tfstate"
  aws_role_arn   = "arn:aws:iam::${local.aws_account}:role/${local.aws_role_name}"
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region              = "${local.aws_region}"
  allowed_account_ids = ["${local.aws_account}"]
  assume_role {
    role_arn = "${local.aws_role_arn}"
  }
  default_tags {
    tags = {
      "Environment" = "apps"
      "ManagedBy" = "Terradeploy Apps - ${local.state_bucket}/${local.state_key}"
      "Owner" = "Platform Engineering"
      "Project" = "AODN Applications"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket                      = local.state_bucket
    key                         = local.state_key
    region                      = local.aws_region
    dynamodb_table              = local.state_bucket
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    disable_bucket_update       = true
    encrypt                     = true
    role_arn                    = local.aws_role_arn
  }
}
