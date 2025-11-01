# 01 - Configuration du Provider Linode

Configuration de base du provider Linode (Akamai Cloud Computing).

## Prérequis

1. Un compte Linode
2. Un token API Linode (à créer dans la console: Profile → API Tokens)

## Utilisation

```bash
terraform init

# Créer terraform.tfvars
echo 'linode_token = "votre_token"' > terraform.tfvars

terraform plan
terraform apply
```

## Documentation

- [Linode Provider](https://registry.terraform.io/providers/linode/linode/latest/docs)
- [API Linode](https://www.linode.com/docs/api/)
