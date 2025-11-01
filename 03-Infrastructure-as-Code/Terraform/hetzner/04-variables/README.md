# 04 - Utilisation avancée des variables

Cet exemple démontre l'utilisation avancée des variables avec Terraform sur Hetzner Cloud.

## Concepts

- Variables avec valeurs par défaut
- Validation des variables
- Locals pour réutiliser des valeurs
- Map de objets pour créer plusieurs ressources
- Merge de tags

## Utilisation

```bash
# Copier l'exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec vos valeurs
vim terraform.tfvars

# Déployer
terraform init
terraform apply

# Voir les IPs des serveurs
terraform output servers
```

## Personnalisation

Ajoutez ou modifiez des serveurs dans `terraform.tfvars` :

```hcl
servers = {
  frontend = {
    type  = "cx11"
    image = "ubuntu-22.04"
  }
  backend = {
    type  = "cx21"
    image = "ubuntu-22.04"
  }
  database = {
    type  = "cx31"
    image = "ubuntu-22.04"
  }
}
```
