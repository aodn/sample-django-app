locals {
  params = jsondecode(data.aws_ssm_parameter.shared.value)
}

data "aws_ssm_parameter" "shared" {
  name = var.parameter_name
}
