locals {
  # set container definition variables with default fallback values from ssm if available
  allowed_hosts            = var.allowed_hosts
  allowed_cidr_nets        = coalesce(var.allowed_cidr_nets, var.subnets_private_cidr)
  django_secret_key        = var.django_secret_key
  db_host                  = coalesce(var.db_host, var.rds_url)
  db_name                  = var.db_name
  db_user                  = var.db_user
  db_secret_name           = var.db_secret_name
  db_secret_region         = var.db_secret_region
  s3_storage_bucket_name   = var.s3_storage_bucket_name
  s3_storage_bucket_region = var.s3_storage_bucket_region

  ecr_registry = split("/", var.ecr_repository_url)[0]
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.7.0"

  # Cluster Configuration
  cluster_name = "${var.app_name}-${var.environment}"
  cluster_configuration = {
    name  = "containerInsights"
    value = "enabled"
  }
  create_task_exec_iam_role = true
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }

  # Service Configuration
  services = {

    "${var.app_name}-${var.environment}" = {
      capacity_provider_strategy = {
        dedicated = {
          base              = 0
          capacity_provider = "FARGATE"
          weight            = 100
        }
        #        spot = {
        #          base              = 0
        #          capacity_provider = "FARGATE_SPOT"
        #          weight            = 100
        #        }
      }

      # allow ECS exec commands on containers (e.g. to get a shell session)
      enable_execute_command = true

      # resources
      cpu    = 512
      memory = 1024

      # wait for service to reach steady state
      wait_for_steady_state = true

      # Container definition(s)
      container_definitions = {
        api = {
          name  = "api"
          image = startswith(var.image, "sha256") ? "${var.ecr_repository_url}@${var.image}" : "${var.ecr_repository_url}:${var.image}"
          health_check = {
            command = ["CMD-SHELL", "uwsgi-is-ready --stats-socket /tmp/statsock > /dev/null 2>&1 || exit 1"]
          }
          readonly_root_filesystem = false
          essential                = true
          memory_reservation       = 256
          environment = [
            { name = "ALLOWED_HOSTS", value = local.allowed_hosts },
            { name = "ALLOWED_CIDR_NETS", value = local.allowed_cidr_nets },
            { name = "DJANGO_SECRET_KEY", value = local.django_secret_key },
            { name = "DB_HOST", value = local.db_host },
            { name = "DB_NAME", value = local.db_name },
            { name = "DB_USER", value = local.db_user },
            { name = "DB_SECRET_NAME", value = local.db_secret_name },
            { name = "DB_SECRET_REGION", value = local.db_secret_region },
            { name = "S3_STORAGE_BUCKET_NAME", value = local.s3_storage_bucket_name },
            { name = "S3_STORAGE_BUCKET_REGION", value = local.s3_storage_bucket_region }
          ]
          port_mappings = [
            {
              name          = "api"
              containerPort = 9000
              hostPort      = 9000
            }
          ]
          mount_points = [
            {
              readOnly      = false
              containerPath = "/vol/web"
              sourceVolume  = "static"
            }
          ]
        }
        proxy = {
          name  = "proxy"
          image = "${local.ecr_registry}/nginx-proxy:latest"
          health_check = {
            command = ["CMD-SHELL", "curl -so /dev/null http://localhost/health || exit 1"]
          }
          readonly_root_filesystem = false
          essential                = true
          memory_reservation       = 256
          environment = [
            { name = "APP_HOST", value = "127.0.0.1" },
            { name = "APP_PORT", value = 9000 },
            { name = "LISTEN_PORT", value = var.container_port }
          ]
          port_mappings = [
            {
              name          = "nginx"
              containerPort = var.container_port
              hostPort      = var.container_port
            }
          ]
          mount_points = [
            {
              readOnly      = false
              containerPath = "/vol/static"
              sourceVolume  = "static"
            }
          ]
        }
      }

      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }

      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.app.arn
          container_name   = "proxy"
          container_port   = var.container_port
        }
      }

      subnet_ids = split(",", var.subnets_private)

      security_group_rules = {
        ingress_vpc = {
          type        = "ingress"
          from_port   = var.container_port
          to_port     = var.container_port
          protocol    = "tcp"
          cidr_blocks = [var.vpc_cidr]
        }
        egress_all = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      tasks_iam_role_statements = [
        {
          actions = [
            "s3:PutObject",
            "s3:GetObjectAcl",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject",
            "s3:PutObjectAcl"
          ]
          resources = [
            "arn:aws:s3:::${var.s3_storage_bucket_name}",
            "arn:aws:s3:::${var.s3_storage_bucket_name}/*"
          ]
        },
        {
          actions = [
            "secretsmanager:GetSecretValue"
          ]
          resources = [
            "arn:aws:secretsmanager:${var.db_secret_region}:*:secret:${var.db_secret_name}*"
          ]
        }
      ]

      volume = {
        static = {}
      }
    }
  }
}
