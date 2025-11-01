# 02 - Créer un serveur Hetzner Cloud

Cet exemple crée un serveur Ubuntu 22.04 sur Hetzner Cloud.

## Ressources créées

- Une clé SSH
- Un serveur CX11 (1 vCPU, 2GB RAM)

## Variables requises

- `hcloud_token` : Token API Hetzner Cloud
- `ssh_public_key` : Votre clé SSH publique

## Utilisation

```bash
# Générer une clé SSH si nécessaire
ssh-keygen -t rsa -b 4096 -f ~/.ssh/hetzner_key

# Créer le fichier terraform.tfvars
cat > terraform.tfvars <<EOF
hcloud_token = "votre_token"
ssh_public_key = "$(cat ~/.ssh/hetzner_key.pub)"
EOF

# Déployer
terraform init
terraform apply

# Se connecter au serveur
terraform output -raw server_ip
ssh root@<server_ip>
```

## Coût estimé

~3€/mois pour un serveur CX11
