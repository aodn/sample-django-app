output "buckets" {
  value = module.s3.wrapper
}

output "cluster" {
  value = module.cluster
}

output "service" {
  value = module.service
}
