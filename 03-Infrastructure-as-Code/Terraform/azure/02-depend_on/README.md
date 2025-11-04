# Exemple 02 : Depends_on (Gestion des dépendances)

## Objectif
Comprendre comment Terraform gère les **dépendances entre ressources** et quand utiliser `depends_on` explicitement.

## Concepts clés

### Types de dépendances

Terraform gère deux types de dépendances :

#### 1. Dépendances IMPLICITES (Automatiques) ✅
Terraform les détecte automatiquement quand une ressource référence une autre :

```hcl
resource "azurerm_storage_account" "storage" {
  resource_group_name = azurerm_resource_group.rg.name  # Référence directe
}
```

→ Terraform sait que le RG doit être créé AVANT le Storage Account

#### 2. Dépendances EXPLICITES (depends_on) 🔧
Nécessaires quand la dépendance n'est pas évidente dans le code :

```hcl
resource "azurerm_role_assignment" "example" {
  scope        = azurerm_storage_account.storage.id
  # ...

  depends_on = [
    azurerm_storage_account.storage  # Dépendance explicite
  ]
}
```

## Quand utiliser depends_on ?

### ✅ Utilisez depends_on quand :

1. **Pas de référence directe** mais dépendance réelle
   ```hcl
   # Role assignment qui dépend du storage mais ne référence pas tous ses attributs
   depends_on = [azurerm_storage_account.storage]
   ```

2. **Order de création important** sans lien dans le code
   ```hcl
   # Script qui doit s'exécuter APRÈS toutes les autres ressources
   depends_on = [
     azurerm_resource_group.rg,
     azurerm_storage_account.storage
   ]
   ```

3. **Ressources qui doivent être complètement prêtes**
   ```hcl
   # Attendre que le service soit complètement déployé
   depends_on = [azurerm_kubernetes_cluster.aks]
   ```

4. **Éviter les erreurs de timing**
   ```hcl
   # Certaines ressources Azure peuvent avoir des délais de propagation
   depends_on = [azurerm_resource_provider_registration.example]
   ```

### ❌ N'utilisez PAS depends_on quand :

- Une référence directe existe déjà (dépendance implicite)
- Terraform peut détecter la dépendance automatiquement
- Ce n'est pas nécessaire (ajoute de la complexité)

## Structure de l'exemple

```
Resource Group (créé en 1er)
     ↓ (dépendance implicite)
Storage Account (créé en 2ème)
     ↓ (dépendance implicite)
Storage Container (créé en 3ème)
     ↓ (dépendance EXPLICITE avec depends_on)
Role Assignment (créé en 4ème)
     ↓ (dépendance EXPLICITE avec depends_on)
Post-Deployment Script (créé en 5ème)
     ↓ (dépendance EXPLICITE avec depends_on)
Storage Blob (créé en dernier)
```

## Code de l'exemple

### Dépendance implicite

```hcl
# Terraform détecte automatiquement l'ordre
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  resource_group_name = azurerm_resource_group.rg.name  # Référence → Dépendance implicite
  # ...
}
```

### Dépendance explicite

```hcl
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id

  # Sans cette ligne, le role pourrait être créé trop tôt
  depends_on = [
    azurerm_storage_account.storage
  ]
}
```

### Multiple dépendances

```hcl
resource "null_resource" "post_deployment" {
  # Attend que TOUTES ces ressources soient créées
  depends_on = [
    azurerm_resource_group.rg,
    azurerm_storage_account.storage,
    azurerm_storage_container.container,
    azurerm_role_assignment.storage_contributor
  ]

  provisioner "local-exec" {
    command = "echo 'Déploiement terminé!'"
  }
}
```

## Commandes

```bash
# 1. Créer le fichier de configuration
cp dev.tfvars.example dev.tfvars
# Éditer dev.tfvars avec votre subscription_id

# 2. Initialiser Terraform
terraform init

# 3. Voir le graphe de dépendances
terraform graph | dot -Tpng > dependency-graph.png
# (Nécessite graphviz : brew install graphviz)

# 4. Voir le plan (observer l'ordre de création)
terraform plan -var-file="dev.tfvars"

# 5. Appliquer (observer l'ordre dans les logs)
terraform apply -var-file="dev.tfvars"

# 6. Voir les outputs
terraform output

# 7. Voir le graphe de dépendances
terraform output dependency_graph

# 8. Vérifier le fichier créé par le provisioner
cat deployment-complete.txt

# 9. Détruire (observer l'ordre inverse)
terraform destroy -var-file="dev.tfvars"
```

## Prérequis

1. Provider Azure configuré
2. Authentification Azure (`az login`)
3. Subscription ID dans `dev.tfvars`
4. Un nom de storage account unique

## Ordre d'exécution

### Création (terraform apply)

```
1. azurerm_resource_group.rg
2. azurerm_storage_account.storage
3. azurerm_storage_container.container
4. azurerm_role_assignment.storage_contributor (depends_on)
5. null_resource.post_deployment (depends_on)
6. azurerm_storage_blob.example_blob (depends_on)
```

### Destruction (terraform destroy)

L'ordre est **inversé** :
```
1. azurerm_storage_blob.example_blob
2. null_resource.post_deployment
3. azurerm_role_assignment.storage_contributor
4. azurerm_storage_container.container
5. azurerm_storage_account.storage
6. azurerm_resource_group.rg
```

## Visualiser le graphe de dépendances

### Méthode 1 : Graphviz

```bash
# Installer graphviz
brew install graphviz  # macOS
# ou
sudo apt-get install graphviz  # Linux

# Générer le graphe
terraform graph | dot -Tpng > graph.png
open graph.png
```

### Méthode 2 : Terraform show

```bash
# Voir l'état avec les dépendances
terraform show
```

### Méthode 3 : Output personnalisé

```bash
# Notre output dependency_graph
terraform output dependency_graph
```

## Cas d'usage réels

### 1. Role Assignments

```hcl
# Le role doit être créé APRÈS la ressource
resource "azurerm_role_assignment" "example" {
  scope      = azurerm_storage_account.storage.id
  # ...
  depends_on = [azurerm_storage_account.storage]
}
```

### 2. Scripts de post-déploiement

```hcl
# Script qui configure quelque chose APRÈS la création
resource "null_resource" "configure" {
  depends_on = [azurerm_kubernetes_cluster.aks]

  provisioner "local-exec" {
    command = "kubectl apply -f manifests/"
  }
}
```

### 3. Resource Provider Registration

```hcl
# Enregistrer un provider AVANT de créer des ressources
resource "azurerm_resource_provider_registration" "example" {
  name = "Microsoft.ContainerService"
}

resource "azurerm_kubernetes_cluster" "aks" {
  depends_on = [azurerm_resource_provider_registration.example]
  # ...
}
```

### 4. Délais de propagation

```hcl
# Attendre que DNS se propage
resource "time_sleep" "wait_for_dns" {
  depends_on      = [azurerm_dns_a_record.example]
  create_duration = "30s"
}

resource "azurerm_app_service" "app" {
  depends_on = [time_sleep.wait_for_dns]
  # ...
}
```

## Points d'attention

### ⚠️ Performance

Trop de `depends_on` peut ralentir le déploiement :
- Terraform ne peut pas paralléliser
- Les ressources sont créées séquentiellement

```hcl
# ❌ Mauvais : Force la création séquentielle
resource "azurerm_storage_account" "storage1" {
  depends_on = [azurerm_resource_group.rg]
  # Pas nécessaire, dépendance implicite suffit
}

# ✅ Bon : Terraform parallélise automatiquement
resource "azurerm_storage_account" "storage1" {
  resource_group_name = azurerm_resource_group.rg.name
  # Dépendance implicite, Terraform optimise
}
```

### 📝 Bonnes pratiques

1. **Préférez les dépendances implicites** quand possible
2. **Utilisez depends_on** seulement quand nécessaire
3. **Documentez** pourquoi un depends_on est nécessaire
4. **Testez** le plan pour vérifier l'ordre
5. **Visualisez** le graphe de dépendances

## Dépendances circulaires

Terraform **interdit** les dépendances circulaires :

```hcl
# ❌ ERREUR : Dépendance circulaire
resource "azurerm_resource_a" "a" {
  depends_on = [azurerm_resource_b.b]
}

resource "azurerm_resource_b" "b" {
  depends_on = [azurerm_resource_a.a]
}

# Erreur : Cycle: azurerm_resource_a.a → azurerm_resource_b.b → azurerm_resource_a.a
```

**Solution** : Revoir l'architecture pour éliminer le cycle

## Dépendances entre modules

```hcl
module "network" {
  source = "./modules/network"
}

module "compute" {
  source    = "./modules/compute"
  subnet_id = module.network.subnet_id  # Dépendance implicite
}

module "monitoring" {
  source = "./modules/monitoring"

  # Dépendance explicite sur plusieurs modules
  depends_on = [
    module.network,
    module.compute
  ]
}
```

## Debugging des dépendances

### Voir l'ordre prévu

```bash
# Plan avec logs détaillés
TF_LOG=DEBUG terraform plan -var-file="dev.tfvars" 2>&1 | grep "dependencies"
```

### Forcer la recréation dans l'ordre

```bash
# Taint une ressource pour la recréer
terraform taint azurerm_storage_account.storage

# Voir le plan de recréation
terraform plan -var-file="dev.tfvars"
```

## Exercices

1. **Modifier l'ordre** : Essayez de retirer un `depends_on` et observez ce qui se passe
2. **Ajouter une ressource** : Ajoutez une nouvelle ressource qui dépend de plusieurs autres
3. **Graphe visuel** : Générez le graphe PNG et identifiez les dépendances
4. **Temps de création** : Comparez le temps avec et sans depends_on
5. **Dépendance circulaire** : Créez volontairement une erreur de cycle et résolvez-la

## Comparaison avec d'autres outils

| Outil | Gestion des dépendances |
|-------|-------------------------|
| **Terraform** | Automatique + depends_on |
| **CloudFormation** | DependsOn explicite |
| **ARM Templates** | dependsOn explicite |
| **Pulumi** | Automatique (plus intelligent) |

## Erreurs courantes

### Erreur : Resource not found

```
Error: Error creating Role Assignment: Resource not found
```

**Cause** : La ressource parente n'était pas prête

**Solution** : Ajoutez `depends_on`

```hcl
depends_on = [azurerm_storage_account.storage]
```

### Erreur : Cycle detected

```
Error: Cycle: resource A → resource B → resource A
```

**Solution** : Cassez le cycle en révisant l'architecture

## Ressources

- [Documentation Terraform - depends_on](https://www.terraform.io/docs/language/meta-arguments/depends_on.html)
- [Resource Graph](https://www.terraform.io/docs/cli/commands/graph.html)
- [Resource Dependencies](https://www.terraform.io/docs/language/resources/behavior.html#resource-dependencies)
