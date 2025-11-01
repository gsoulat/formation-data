# 01 - Configuration du Provider Infomaniak Public Cloud

Configuration pour utiliser Infomaniak Public Cloud avec Terraform via OpenStack.

## Prérequis

1. Un compte Infomaniak
2. Un projet Public Cloud Infomaniak
3. Credentials OpenStack (username/password)

## Obtenir les credentials

1. Se connecter à l'espace client Infomaniak
2. Aller dans Public Cloud
3. Créer un projet si nécessaire
4. Dans les paramètres du projet, récupérer:
   - Username OpenStack
   - Password (à générer)
   - Project Name

## Configuration

```bash
# Créer terraform.tfvars
cat > terraform.tfvars <<EOF
user_name    = "PCU-XXXXXX"
password     = "votre_mot_de_passe"
project_name = "PCP-XXXXXX"
EOF

terraform init
terraform plan
terraform apply
```

## Infomaniak Public Cloud

- Hébergeur suisse (données en Suisse)
- Infrastructure OpenStack
- Datacenter à Genève
- Respect du RGPD
- Support en français

## Documentation

- [Public Cloud Infomaniak](https://www.infomaniak.com/fr/hebergement/public-cloud)
- [Documentation OpenStack](https://docs.openstack.org/)
