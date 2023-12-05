module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.7.0"

  # Cluster Configuration
  cluster_name = "sample-django-app"
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

    sample-django-app = {
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

      # Container definition(s)
      container_definitions = {
        api = {
          name  = "api"
          image = "${var.ecr_registry}/api:${var.image_tag}"
          health_check = {
            command = ["CMD-SHELL", "uwsgi-is-ready --stats-socket /tmp/statsock > /dev/null 2>&1 || exit 1"]
          }
          readonly_root_filesystem = false
          essential                = true
          memory_reservation       = 256
          environment = [
            { name = "DJANGO_SECRET_KEY", value = "changeme" },
            { name = "DB_HOST", value = local.params.rds_url },
            { name = "DB_NAME", value = "api" },
            { name = "DB_USER", value = "api" },
            { name = "DB_SECRET_NAME", value = var.db_secret_name },
            { name = "DB_SECRET_REGION", value = var.db_secret_region },
            { name = "ALLOWED_HOSTS", value = "*" },
            { name = "ALLOWED_CIDR_NETS", value = "${join(",", local.params.vpc_subnet_cidrs.private)}" },
            { name = "S3_STORAGE_BUCKET_NAME", value = var.s3_buckets["sample-django-app-bucket"].s3_bucket_id },
            { name = "S3_STORAGE_BUCKET_REGION", value = var.s3_buckets["sample-django-app-bucket"].s3_bucket_region }
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
          image = "${var.ecr_registry}/nginx-proxy:latest"
          health_check = {
            command = ["CMD-SHELL", "curl -so /dev/null http://localhost/health || exit 1"]
          }
          readonly_root_filesystem = false
          essential                = true
          memory_reservation       = 256
          environment = [
            { name = "APP_HOST", value = "127.0.0.1" },
            { name = "APP_PORT", value = 9000 },
            { name = "LISTEN_PORT", value = 80 }
          ]
          port_mappings = [
            {
              name          = "nginx"
              containerPort = 80
              hostPort      = 80
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
          container_port   = 80
        }
      }

      subnet_ids = local.params.vpc_private_subnets

      security_group_rules = {
        ingress_vpc = {
          type        = "ingress"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = [local.params.vpc_cidr]
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
            var.s3_buckets["sample-django-app-bucket"].s3_bucket_arn,
            "${var.s3_buckets["sample-django-app-bucket"].s3_bucket_arn}/*"
          ]
        },
        {
          actions = [
            "secretsmanager:GetSecretValue"
          ]
          resources = [
            "arn:aws:secretsmanager:ap-southeast-2:450356697252:secret:/rds/stefan-db/primary/evaluation/api*"
          ]
        }
      ]

      volume = {
        static = {}
      }
    }
  }
}
