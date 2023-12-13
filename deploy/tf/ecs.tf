locals {
  nginx_vars = {
    app_host    = "127.0.0.1"
    app_port    = var.app_port
    listen_port = var.proxy_port
  }

  app_container_vars   = [for k, v in var.container_vars : { name = upper(k), value = v }]
  nginx_container_vars = [for k, v in local.nginx_vars : { name = upper(k), value = v }]

  container_definitions = var.nginx_proxy ? merge(local.app_container_definition, local.nginx_container_definition) : local.app_container_definition
  app_container_definition = {
    app = {
      name  = var.app_container_name
      image = startswith(var.image, "sha256") ? "${var.ecr_registry}@${var.image}" : "${var.ecr_registry}:${var.image}"
      health_check = {
        command = ["CMD-SHELL", "uwsgi-is-ready --stats-socket /tmp/statsock > /dev/null 2>&1 || exit 1"]
      }
      readonly_root_filesystem = false
      essential                = true
      memory_reservation       = 256
      environment              = local.app_container_vars
      port_mappings = [
        {
          name          = var.app_container_name
          containerPort = var.app_port
          hostPort      = var.app_port
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
  }
  nginx_container_definition = {
    nginx = {
      name  = "nginx"
      image = "${var.ecr_registry}/nginx-proxy:latest"
      health_check = {
        command = ["CMD-SHELL", "curl -so /dev/null http://localhost/health || exit 1"]
      }
      readonly_root_filesystem = false
      essential                = true
      memory_reservation       = 256
      environment              = local.nginx_container_vars
      port_mappings = [
        {
          name          = "nginx"
          containerPort = var.proxy_port
          hostPort      = var.proxy_port
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
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.7.0"

  depends_on = [module.s3.wrapper]

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
      container_definitions = local.container_definitions

      deployment_circuit_breaker = {
        enable   = true
        rollback = true
      }

      load_balancer = {
        service = {
          target_group_arn = aws_lb_target_group.app.arn
          container_name   = var.nginx_proxy ? "nginx" : "app"
          container_port   = var.nginx_proxy ? var.proxy_port : var.app_port
        }
      }

      subnet_ids = local.private_subnets

      security_group_rules = {
        ingress_vpc = {
          type        = "ingress"
          from_port   = var.nginx_proxy ? var.proxy_port : var.app_port
          to_port     = var.nginx_proxy ? var.proxy_port : var.app_port
          protocol    = "tcp"
          cidr_blocks = [local.vpc_cidr]
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
          resources = flatten([for bucket in module.s3.wrapper :
            split(",", "arn:aws:s3:::${bucket.s3_bucket_id},arn:aws:s3:::${bucket.s3_bucket_id}/*"
          )])
        },
        {
          actions = [
            "secretsmanager:GetSecretValue"
          ]
          resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:*:secret:/rds*"]
        }
      ]

      volume = {
        static = {}
      }
    }
  }
}
