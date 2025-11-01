# 01 - Configuration du Provider Oracle Cloud Infrastructure (OCI)

Configuration de base pour se connecter à Oracle Cloud.

## Prérequis

1. Compte Oracle Cloud (Free Tier disponible)
2. Configuration OCI CLI avec:
   - Tenancy OCID
   - User OCID
   - Clé API (publique/privée)
   - Fingerprint de la clé

## Configuration OCI CLI

```bash
# Installer OCI CLI
brew install oci-cli  # macOS
# ou
pip install oci-cli

# Configurer
oci setup config

# Cela créera:
# - ~/.oci/config
# - ~/.oci/oci_api_key.pem (clé privée)
```

## Fichier terraform.tfvars

```hcl
tenancy_ocid     = "ocid1.tenancy.oc1..xxx"
user_ocid        = "ocid1.user.oc1..xxx"
fingerprint      = "aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99"
private_key_path = "~/.oci/oci_api_key.pem"
region           = "eu-frankfurt-1"
```

## Utilisation

```bash
terraform init
terraform plan
terraform apply
```

## Free Tier Oracle Cloud

Oracle offre un free tier généreux avec:
- 2 instances AMD Always Free
- 4 instances ARM Ampere A1 Always Free
- 200 GB de stockage bloc
- 20 GB Object Storage
