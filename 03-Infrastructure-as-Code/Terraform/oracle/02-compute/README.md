# 02 - Instance Compute Oracle Cloud (Free Tier)

Création d'une instance compute gratuite (Always Free) avec réseau VCN.

## Ressources créées

- VCN (Virtual Cloud Network)
- Subnet public
- Internet Gateway
- Security List (ports 22 et 80)
- Instance VM.Standard.E2.1.Micro (Always Free)

## Instance Always Free

- 1 OCPU
- 1 GB RAM
- Ubuntu 22.04

## Utilisation

```bash
# Créer terraform.tfvars avec vos informations
cat > terraform.tfvars <<EOF
tenancy_ocid     = "ocid1.tenancy.oc1..xxx"
user_ocid        = "ocid1.user.oc1..xxx"
fingerprint      = "aa:bb:cc:..."
private_key_path = "~/.oci/oci_api_key.pem"
compartment_ocid = "ocid1.compartment.oc1..xxx"
ssh_public_key   = "$(cat ~/.ssh/id_rsa.pub)"
EOF

terraform init
terraform apply

# Se connecter
terraform output -raw ssh_command
```

## Note

L'instance est Always Free (gratuite à vie) tant que vous restez dans les limites du Free Tier.
