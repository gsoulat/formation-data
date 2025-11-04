# Exemple 15 : Provisioners

## Objectif
Comprendre l'utilisation des **provisioners** dans Terraform pour exécuter des scripts et des commandes lors de la création ou destruction de ressources.

## Concepts clés

### Qu'est-ce qu'un Provisioner ?
Les provisioners permettent d'exécuter des scripts ou des commandes :
- Lors de la **création** d'une ressource (par défaut)
- Lors de la **destruction** d'une ressource (avec `when = destroy`)

### Types de Provisioners

#### 1. local-exec
- S'exécute sur la **machine locale** (là où Terraform est lancé)
- Utile pour des scripts de configuration locale, notifications, logs, etc.

#### 2. remote-exec
- S'exécute sur la **machine distante** (ex: VM créée)
- Nécessite une connexion SSH ou WinRM
- Utile pour installer des logiciels, configurer le système, etc.

### ⚠️ Bonnes pratiques

**IMPORTANT** : Les provisioners doivent être utilisés en **dernier recours** !

**Préférez plutôt :**
- Cloud-init pour la configuration de VMs
- Azure VM Extensions
- Configuration management tools (Ansible, Chef, Puppet)
- Images préconfigurées (Packer)

**Pourquoi éviter les provisioners ?**
- Ils rendent l'infrastructure moins prédictible
- Difficiles à déboguer
- Ne respectent pas le principe déclaratif de Terraform
- Peuvent causer des problèmes de dépendances

## Structure des fichiers

```
15-provisionneurs/
├── main.tf          # Configuration avec différents types de provisioners
├── variables.tf     # Variables d'entrée
├── outputs.tf       # Sorties
├── terraform.tf     # Configuration du provider null
└── README.md        # Ce fichier
```

## Commandes

```bash
# 1. Initialiser Terraform
terraform init

# 2. Voir le plan
terraform plan

# 3. Appliquer (observer les provisioners dans les logs)
terraform apply

# 4. Consulter le fichier de log créé
cat provisioner-log.txt

# 5. Détruire (observer le provisioner de destruction)
terraform destroy

# 6. Re-consulter le log
cat provisioner-log.txt
```

## Points d'attention

### Gestion des erreurs
- **on_failure = fail** (défaut) : Arrête l'exécution si le provisioner échoue
- **on_failure = continue** : Continue même si le provisioner échoue

### Paramètres when
- **when = create** (défaut) : S'exécute lors de la création
- **when = destroy** : S'exécute lors de la destruction

### null_resource
- Permet d'exécuter des provisioners sans créer de ressource réelle
- Utile pour des tâches de configuration ponctuelles
- Le paramètre `triggers` permet de contrôler quand le provisioner se réexécute

## Ce que fait cet exemple

1. **Resource Group** :
   - Provisioner local-exec qui log la création
   - Provisioner de destruction qui log la suppression

2. **Storage Account** :
   - Provisioner avec commandes multiples (heredoc)
   - Gestion d'erreur avec on_failure

3. **null_resource** :
   - Démontre l'utilisation de null_resource
   - Montre comment utiliser différents interpréteurs (python)
   - Utilise triggers pour contrôler l'exécution

## Exercice

Modifiez l'exemple pour :
1. Créer un script shell externe et l'appeler avec local-exec
2. Ajouter un provisioner qui envoie une notification (echo ou curl)
3. Expérimenter avec `on_failure = continue` vs `on_failure = fail`

## Ressources

- [Documentation Terraform - Provisioners](https://www.terraform.io/docs/language/resources/provisioners/syntax.html)
- [Why Provisioners are a Last Resort](https://www.terraform.io/docs/language/resources/provisioners/syntax.html#provisioners-are-a-last-resort)
