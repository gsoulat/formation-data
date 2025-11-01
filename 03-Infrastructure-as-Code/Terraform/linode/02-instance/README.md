# 02 - Créer une instance Linode

Création d'une instance Ubuntu 22.04 sur Linode.

## Ressources créées

- Instance Linode Nanode 1GB (Frankfurt)
- Configuration SSH avec clé publique

## Utilisation

```bash
# Générer une clé SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/linode_key

# Créer terraform.tfvars
cat > terraform.tfvars <<EOF
linode_token = "votre_token"
ssh_public_key = "$(cat ~/.ssh/linode_key.pub)"
root_password = "VotreMotDePasse123!"
EOF

terraform init
terraform apply

# Se connecter
terraform output -raw ssh_command
```

## Coût

~5$/mois pour un Nanode 1GB
