variable "alb_dns_name" {
  description = "The DNS name of the application load-balancer"
  type        = string
}

variable "alb_https_listener_arn" {
  description = "The ARN of the application load-balancer listener"
  type        = string
}

variable "alb_zone_id" {
  description = "The DNS zone ID of the application load-balancer"
  type        = string
}

variable "app_name" {
  description = "The name of the application e.g. sample-django-app"
  type        = string
}

variable "app_hostnames" {
  description = "Hostnames to associate with the application"
  type        = list(string)
}

variable "container_port" {
  description = "The port to expose to the load balancer on the container"
  type        = number
  default     = 80
}

variable "db_host" {
  description = "Override variable for database host"
  type        = string
}

variable "ecr_repository_url" {
  description = "The name of the repository to pull the image from"
  type        = string
}

variable "environment" {
  description = "Environment name to prepend/append to resource names"
  type        = string
}

variable "image" {
  description = "The digest/tag of the docker image to pull from ECR"
  type        = string
}

variable "rds_url" {
  description = "The hostname of the database instance"
  type        = string
}

variable "subnets_private" {
  description = "ID's of the subnets to deploy the container too"
  type        = string
}

variable "subnets_private_cidr" {
  description = "CIDR's of the subnets to deploy the container too"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR of the VPC"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "zone_id" {
  description = "The ID of the route53 zone"
  type        = string
}

# Container environment variables
variable "allowed_hosts" {
  description = "Hosts allowed to access the application container (i.e. 127.0.0.1)"
  type        = string
}

variable "allowed_cidr_nets" {
  description = "Subnet CIDR's allowed to access the application container"
  type        = string
}

variable "django_secret_key" {
  description = "The secret key for django app"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_user" {
  description = "The user to connect to the database with"
  type        = string
}

variable "db_secret_name" {
  description = "The name of the secret to fetch DB login credentials from"
  type        = string
}

variable "db_secret_region" {
  description = "The region to fetch the secret from"
  type        = string
  default     = "ap-southeast-2"
}

variable "s3_storage_bucket_name" {
  description = "Name of the S3 bucket to use"
  type        = string
}

variable "s3_storage_bucket_region" {
  description = "The bucket region"
  type        = string
}
