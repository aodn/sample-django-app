resource "aws_vpc" "ecs_test" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${local.prefix}-vpc"
  }
}

resource "aws_internet_gateway" "ecs_test" {
  vpc_id = aws_vpc.ecs_test.id
  tags = {
    Name = "${local.prefix}-igw"
  }
}
