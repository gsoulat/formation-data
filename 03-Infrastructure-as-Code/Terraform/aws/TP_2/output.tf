output "ip" {
  value = aws_eip.lb.id
}

output "instance_public_ip" {
  value       = aws_instance.web.public_ip
  description = "IP publique de l'instance EC2"
}

output "instance_private_ip" {
  value       = aws_instance.web.private_ip
  description = "IP privée de l'instance EC2"
}
