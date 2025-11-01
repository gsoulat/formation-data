# 01 - Configuration du Provider Hetzner Cloud

Cet exemple montre comment configurer le provider Hetzner Cloud avec Terraform.

## Prérequis

1. Un compte Hetzner Cloud
2. Un token API Hetzner Cloud (à créer dans la console Hetzner)

## Variables requises

- `hcloud_token` : Token API Hetzner Cloud

## Utilisation

```bash
# Initialiser Terraform
terraform init

# Créer un fichier terraform.tfvars
cat > terraform.tfvars <<EOF
hcloud_token = "votre_token_ici"
EOF

# Planifier
terraform plan

# Appliquer
terraform apply
```

## Ressources créées

Aucune ressource n'est créée, cet exemple récupère uniquement la liste des datacenters disponibles.
