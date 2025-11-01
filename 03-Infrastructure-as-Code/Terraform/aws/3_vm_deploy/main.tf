resource "tls_private_key" "my_tls_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.my_tls_private_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.my_tls_private_key.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
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

# Security Group
# Security Group
resource "aws_security_group" "nginx_sg" {
  name        = "${var.project_name}-${var.environment}-nginx-sg"
  description = "Security group for ${var.project_name} Nginx web server"


  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Instance EC2
resource "aws_instance" "nginx_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Logs
    exec > >(tee /var/log/user-data.log)
    exec 2>&1
    
    # Mise à jour du système
    echo "Mise à jour du système..."
    yum update -y
    
    # Installation de Nginx
    echo "Installation de Nginx..."
    yum install -y nginx
    
    # Démarrer Nginx
    systemctl start nginx
    systemctl enable nginx
    
    # Créer un fichier temporaire pour recevoir le HTML
    echo "Préparation pour recevoir le fichier HTML..."
    mkdir -p /tmp/upload
    chmod 777 /tmp/upload
    
    # Log de fin
    echo "Configuration initiale terminée à $(date)"
  EOF
  )

  root_block_device {
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attendre que l'instance soit prête
resource "time_sleep" "wait_30_seconds" {
  depends_on      = [aws_instance.nginx_server]
  create_duration = "30s"
}

# Connexion SSH pour upload
resource "null_resource" "upload_html" {
  depends_on = [time_sleep.wait_30_seconds]

  # Trigger pour ré-exécuter si le fichier change
  triggers = {
    html_file_hash = filemd5("${path.module}/index.html")
    instance_id    = aws_instance.nginx_server.id
  }

  # Connexion SSH
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/${var.key_name}.pem")
    host        = aws_instance.nginx_server.public_ip
    timeout     = "5m"
  }

  # Upload du fichier HTML
  provisioner "file" {
    source      = "${path.module}/index.html"
    destination = "/tmp/index.html"
  }

  # Déplacer le fichier et définir les permissions
  provisioner "remote-exec" {
    inline = [
      "sudo cp /tmp/index.html /usr/share/nginx/html/index.html",
      "sudo chown nginx:nginx /usr/share/nginx/html/index.html",
      "sudo chmod 644 /usr/share/nginx/html/index.html",
      "sudo systemctl reload nginx",
      "echo 'Fichier HTML uploadé avec succès à $(date)' >> ~/upload.log"
    ]
  }
}

# Elastic IP
resource "aws_eip" "nginx_eip" {
  domain = "vpc"

  tags = {
    Name = "nginx-eip"
  }
}

# Association EIP
resource "aws_eip_association" "nginx_eip_assoc" {
  instance_id   = aws_instance.nginx_server.id
  allocation_id = aws_eip.nginx_eip.id
}
