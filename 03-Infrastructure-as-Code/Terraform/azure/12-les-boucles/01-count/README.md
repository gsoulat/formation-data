# Exemple 01 : Count

## Objectif
Apprendre à utiliser **count** pour créer plusieurs instances identiques d'une ressource.

## Concept : Count

`count` est le moyen le plus simple de créer plusieurs ressources :
```hcl
resource "azurerm_resource_group" "rg" {
  count    = 3
  name     = "rg-${count.index}"
  location = var.location
}
```

### count.index
- Variable spéciale disponible dans les ressources avec `count`
- Commence à **0** (0, 1, 2, ...)
- Utile pour nommer les ressources de manière unique

## Code de l'exemple

```hcl
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}${count.index}"
  location = var.location
  count    = 3
}
```

Résultat : Crée 3 Resource Groups :
- `rg-myapp0`
- `rg-myapp1`
- `rg-myapp2`

## Accès aux ressources créées

```hcl
# Accéder à une ressource spécifique
azurerm_resource_group.rg[0]  # Premier RG
azurerm_resource_group.rg[1]  # Deuxième RG
azurerm_resource_group.rg[2]  # Troisième RG

# Accéder à tous (splat expression)
azurerm_resource_group.rg[*].name  # Liste de tous les noms
azurerm_resource_group.rg[*].id    # Liste de tous les IDs
```

## Commandes

```bash
# 1. Créer dev.tfvars
cp dev.tfvars.example dev.tfvars
# Éditer avec vos valeurs

# 2. Initialiser
terraform init

# 3. Voir le plan (3 ressources à créer)
terraform plan -var-file="dev.tfvars"

# 4. Appliquer
terraform apply -var-file="dev.tfvars"

# 5. Voir les ressources créées
terraform state list

# 6. Détruire
terraform destroy -var-file="dev.tfvars"
```

## Avantages de count

✅ Simple et intuitif
✅ Parfait pour des ressources identiques
✅ Facile à comprendre

## Limitations de count

❌ Difficile de supprimer une ressource du milieu (réindexation)
❌ Ne fonctionne pas bien avec des maps
❌ Moins flexible que `for_each`

## Exemple de limitation

Si vous avez 3 RG (index 0, 1, 2) et que vous voulez supprimer le RG 1 :
- count ne permet pas de le faire facilement
- Terraform va recréer les RG 1 et 2 pour maintenir les index

→ Utilisez `for_each` pour plus de flexibilité (voir exemple 03)

## Quand utiliser count

- Créer N ressources identiques
- Le nombre est connu à l'avance
- L'ordre n'est pas important
- Pas besoin de supprimer des ressources spécifiques

## Exercices

1. Changez `count = 3` à `count = 5` et observez le plan
2. Ajoutez des tags avec l'index : `tags = { index = count.index }`
3. Créez un output qui liste tous les noms de RG
4. Utilisez `count` avec une variable : `count = var.rg_count`

## Ressources

- [Documentation Terraform - count](https://www.terraform.io/docs/language/meta-arguments/count.html)
