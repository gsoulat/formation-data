# Exemple 14 : Data Sources

## Objectif
Apprendre à utiliser les **data sources** pour récupérer des informations sur des ressources existantes dans Azure.

## Concepts clés

### Qu'est-ce qu'un Data Source ?
- Les data sources permettent de **lire** des informations sur des ressources existantes
- Contrairement aux `resource`, les data sources ne créent ni ne modifient des ressources
- Ils sont définis avec le mot-clé `data` au lieu de `resource`

### Cas d'usage
1. Référencer des ressources créées en dehors de Terraform
2. Récupérer des informations dynamiques (localisations disponibles, images, etc.)
3. Partager des informations entre différents modules Terraform
4. Éviter de hard-coder des valeurs qui peuvent changer

## Prérequis

**IMPORTANT** : Avant d'exécuter cet exemple, vous devez :
1. Avoir un resource group existant dans votre subscription Azure
2. Mettre à jour `variables.tf` avec :
   - Votre `subscription_id`
   - Le nom de votre resource group existant

## Structure des fichiers

```
14-data-source/
├── main.tf          # Configuration principale avec data sources
├── variables.tf     # Variables d'entrée
├── outputs.tf       # Sorties pour afficher les informations récupérées
└── README.md        # Ce fichier
```

## Commandes

```bash
# 1. Initialiser Terraform
terraform init

# 2. Voir le plan d'exécution
terraform plan

# 3. Appliquer la configuration
terraform apply

# 4. Voir les outputs
terraform output

# 5. Détruire les ressources créées (pas le RG existant !)
terraform destroy
```

## Points d'attention

- Les data sources sont évalués lors de chaque exécution de `terraform plan` ou `apply`
- Si la ressource référencée n'existe pas, Terraform retournera une erreur
- Les data sources ne peuvent pas modifier les ressources existantes
- Seules les ressources créées par ce template seront détruites avec `terraform destroy`

## Exercice

Essayez de :
1. Créer un data source pour récupérer une image Ubuntu
2. Utiliser ce data source pour créer une VM avec cette image
3. Ajouter un output pour afficher la version de l'image
