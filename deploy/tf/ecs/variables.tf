variable "app_hostnames" {
  description = "Hostnames to associate with the application"
  type        = list(string)
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

variable "ecr_registry" {
  description = "The URL of the docker registry"
  type        = string
}

variable "image_tag" {
  description = "The tag of the docker image to pull from ECR"
  type        = string
  default     = "latest"
}

variable "s3_buckets" {
  description = "Map of s3 buckets"
  type        = any
}

variable "parameter_name" {
  type = string
}
