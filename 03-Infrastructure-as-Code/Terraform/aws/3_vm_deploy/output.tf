output "public_ip" {
  value       = aws_eip.nginx_eip.public_ip
  description = "IP publique du serveur"
}

output "website_url" {
  value       = "http://${aws_eip.nginx_eip.public_ip}"
  description = "URL du site web"
}

output "ssh_command" {
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.nginx_eip.public_ip}"
  description = "Commande SSH"
}

output "upload_status" {
  value       = "Le fichier HTML sera uploadé automatiquement après la création de l'instance"
  description = "Statut de l'upload"
}
