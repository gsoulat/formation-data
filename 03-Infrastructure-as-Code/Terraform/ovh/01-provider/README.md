# 01 - Configuration du Provider OVHcloud

Configuration de base pour utiliser l'API OVHcloud.

## Prérequis

1. Un compte OVHcloud
2. Un projet Public Cloud
3. Credentials API OVH (application key, secret, consumer key)

## Obtenir les credentials OVH

### 1. Créer une application

Aller sur: https://eu.api.ovh.com/createApp/

Remplir les informations et noter:
- Application Key
- Application Secret

### 2. Obtenir le Consumer Key

```bash
# Méthode 1: Script Python
pip install ovh

# Créer un script pour obtenir le consumer key
cat > get_consumer_key.py <<EOF
import ovh

client = ovh.Client(
    endpoint='ovh-eu',
    application_key='YOUR_APP_KEY',
    application_secret='YOUR_APP_SECRET',
)

ck = client.new_consumer_key_request()
ck.add_rules(ovh.API_READ_WRITE, "/*")
validation = ck.request()

print("Consumer key:", validation['consumerKey'])
print("Validation URL:", validation['validationUrl'])
EOF

python get_consumer_key.py
# Suivre le lien pour valider

# Méthode 2: Terraform
# Le provider OVH peut générer le consumer key automatiquement
```

### 3. Créer un projet Public Cloud

Dans l'espace client OVH:
- Aller dans Public Cloud
- Créer un nouveau projet
- Noter le Project ID (Service Name)

## Configuration

```bash
# Créer terraform.tfvars
cat > terraform.tfvars <<EOF
ovh_endpoint           = "ovh-eu"
ovh_application_key    = "your_app_key"
ovh_application_secret = "your_app_secret"
ovh_consumer_key       = "your_consumer_key"
project_id             = "your_project_id"
EOF

terraform init
terraform plan
terraform apply
```

## Documentation

- [API OVH](https://eu.api.ovh.com/console/)
- [Provider Terraform OVH](https://registry.terraform.io/providers/ovh/ovh/latest/docs)
