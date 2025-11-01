resource "tls_private_key" "my_tls_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "berry-devops"
  public_key = tls_private_key.my_tls_private_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.my_tls_private_key.private_key_pem
  filename        = "${path.module}/ma_clef.pem"
  file_permission = "0600"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.my_key_pair.key_name
  tags = {
    Name = var.instance_name
  }
}



resource "aws_eip" "lb" {
  instance = aws_instance.web.id
  domain   = "vpc"
}
