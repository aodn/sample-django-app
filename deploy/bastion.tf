data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

data "http" "myip" {
  url = "https://wtfismyip.com/text"
}

resource "tls_private_key" "bastion" {
  rsa_bits  = 4096
  algorithm = "ED25519"
}

resource "local_file" "private_key" {
  content         = tls_private_key.bastion.private_key_openssh
  filename        = "id_${local.prefix}_bastion"
  file_permission = "0600"
}

resource "aws_key_pair" "bastion" {
  public_key = tls_private_key.bastion.public_key_openssh
  key_name   = "${local.prefix}-bastion"
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.bastion.key_name
  vpc_security_group_ids = [aws_security_group.bastion_host.id]

  tags = {
    Name = "${local.prefix}-bastion"
  }
}

resource "aws_security_group" "bastion_host" {
  name        = "${local.prefix}-bastion"
  description = "Bastion security group"

  ingress {
    description = "Allow SSH in from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["${trimspace(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "Allow bastion general internet access"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
