# 02 - Instance Infomaniak Public Cloud

Création d'une instance Ubuntu 22.04 sur Infomaniak Public Cloud.

## Ressources créées

- Réseau privé (192.168.1.0/24)
- Routeur connecté au réseau externe
- Security group (ports 22 et 80)
- Instance a1-ram2-disk20-perf1 (1 vCPU, 2GB RAM)
- Floating IP publique

## Flavors disponibles

- **a1-ram2-disk20-perf1**: 1 vCPU, 2GB RAM, 20GB (~8 CHF/mois)
- **a2-ram4-disk50-perf1**: 2 vCPU, 4GB RAM, 50GB (~16 CHF/mois)
- **a4-ram8-disk80-perf1**: 4 vCPU, 8GB RAM, 80GB (~32 CHF/mois)

## Utilisation

```bash
# Générer une clé SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/infomaniak_key

# Créer terraform.tfvars
cat > terraform.tfvars <<EOF
user_name      = "PCU-XXXXXX"
password       = "votre_password"
project_name   = "PCP-XXXXXX"
ssh_public_key = "$(cat ~/.ssh/infomaniak_key.pub)"
EOF

terraform init
terraform apply

# Se connecter
terraform output -raw ssh_command
```

## Datacenter

Toutes les instances sont hébergées dans le datacenter Infomaniak à Genève, Suisse.

## Avantages

- Données hébergées en Suisse
- Respect du RGPD
- Énergie 100% renouvelable
- Support en français
