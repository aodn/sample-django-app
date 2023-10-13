terraform {
  required_version = "~> 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "tfstate-450356697252-ap-northeast-1"
    key            = "recipe-app.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "tfstate-450356697252-ap-northeast-1"
  }
}

provider "aws" {
  region              = "ap-northeast-1"
  allowed_account_ids = ["450356697252"]
  default_tags {
    tags = {
      Owner   = "Stefan"
      Project = "ECS Training"
    }
  }
}
