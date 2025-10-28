# Chapitre 0 : Guide des commandes DBT

## 🎯 Objectifs
- Maîtriser toutes les commandes DBT essentielles
- Comprendre les workflows typiques de développement
- Optimiser votre productivité avec les bonnes commandes

## 📊 Tableau comparatif des commandes DBT

| Commande | Objectif principal | Modifie la DB | Durée | Cas d'usage | Options principales |
|----------|-------------------|---------------|-------|-------------|-------------------|
| `dbt compile` | Vérifier la syntaxe | ❌ Non | ⚡ Rapide | Développement, debug | `--select`, `--exclude` |
| `dbt run` | Exécuter les modèles | ✅ Oui | 🐌 Moyen/Lent | Matérialisation des données | `--select`, `--full-refresh`, `--exclude` |
| `dbt test` | Valider la qualité | ❌ Non | ⚡ Rapide | Contrôle qualité | `--select`, `--exclude` |
| `dbt build` | Pipeline complet | ✅ Oui | 🐌 Lent | Production, CI/CD | `--select`, `--exclude` |
| `dbt seed` | Charger des CSV | ✅ Oui | ⚡ Rapide | Données de référence | `--select`, `--full-refresh` |
| `dbt snapshot` | Historiser les données | ✅ Oui | 🐌 Moyen | Suivi des changements | `--select` |
| `dbt docs generate` | Créer la documentation | ❌ Non | ⚡ Rapide | Documentation | Aucune option majeure |
| `dbt docs serve` | Serveur de docs | ❌ Non | ⚡ Instant | Consultation locale | `--port` |
| `dbt list` | Lister les ressources | ❌ Non | ⚡ Très rapide | Exploration, vérification | `--select`, `--models`, `--tests` |
| `dbt show` | Aperçu des données | ❌ Non | ⚡ Rapide | Debug, validation | `--select`, `--limit` |
| `dbt debug` | Diagnostic système | ❌ Non | ⚡ Rapide | Setup, troubleshooting | `--config-dir` |
| `dbt parse` | Parser le projet | ❌ Non | ⚡ Rapide | Validation structure | Aucune option majeure |
| `dbt run-operation` | Exécuter une macro | ⚠️ Dépend | ⚡ Variable | Opérations personnalisées | `--args` |
| `dbt source freshness` | Vérifier fraîcheur | ❌ Non | ⚡ Rapide | Monitoring sources | `--select` |
| `dbt deps` | Installer packages | ❌ Non | ⚡ Rapide | Gestion dépendances | Aucune option majeure |
| `dbt clean` | Nettoyer le projet | ❌ Non | ⚡ Très rapide | Maintenance | Aucune option majeure |

### 🔍 Légende

**Durée d'exécution :**
- ⚡ **Rapide** : Secondes
- 🐌 **Moyen** : Minutes
- 🐌 **Lent** : Dizaines de minutes

**Modification de la base de données :**
- ✅ **Oui** : Crée/modifie des tables/vues
- ❌ **Non** : Lecture seule ou pas d'interaction DB
- ⚠️ **Dépend** : Selon la macro exécutée

## 🔄 Workflows recommandés

### 🔧 Développement quotidien
```bash
dbt compile → dbt show → dbt run --select model → dbt test --select model
```

### 🚀 Déploiement production
```bash
dbt deps → dbt build → dbt docs generate
```

### 🐛 Débogage
```bash
dbt debug → dbt compile → dbt list --select problematic_model
```

### 📊 Contrôle qualité
```bash
dbt source freshness → dbt test → dbt docs serve
```

## ⚙️ Options globales communes

### Sélection de ressources
```bash
# Sélection simple
--select model_name
--select tag:marts
--select path:models/analytics

# Avec dépendances
--select +model_name   # avec dépendances amont
--select model_name+   # avec dépendances aval
--select +model_name+  # toute la lignée

# Combinaisons
--select tag:analytics,model_name
```

### Exclusion
```bash
--exclude tag:deprecated
--exclude path:models/staging
```

### Environnement
```bash
--target prod
--profiles-dir ~/.dbt
--project-dir /mon/projet
```

### Logging et performance
```bash
--log-level debug
--log-level info
--threads 8          # Nombre de threads parallèles
--fail-fast          # Arrête à la première erreur
```

### Refresh et modes
```bash
--full-refresh       # Recrée complètement les tables
--store-failures     # Stocke les tests qui échouent
--defer             # Utilise l'état de production pour les dépendances
```

## 🔄 Workflows typiques

### Développement quotidien
```bash
# 1. Vérification de l'environnement
dbt debug

# 2. Installation des dépendances (si nécessaire)
dbt deps

# 3. Développement itératif
dbt compile --select mon_modele
dbt run --select mon_modele
dbt test --select mon_modele

# 4. Aperçu des données
dbt show --select mon_modele
```

### Test complet avant commit
```bash
# Pipeline complet
dbt build

# Ou étape par étape
dbt seed
dbt run
dbt test
dbt snapshot
```

### Déploiement en production
```bash
# 1. Seeds (données de référence)
dbt seed --target prod

# 2. Modèles
dbt run --target prod

# 3. Tests de qualité
dbt test --target prod

# 4. Documentation
dbt docs generate --target prod
```

### Débogage d'erreurs
```bash
# 1. Vérifier la compilation
dbt compile --select mon_modele_cassé

# 2. Voir les logs détaillés
dbt run --select mon_modele_cassé --log-level debug

# 3. Aperçu des données sources
dbt show --select source:ma_source.ma_table
```

### Maintenance et nettoyage
```bash
# Full refresh d'un modèle incrémental
dbt run --select mon_modele_incremental --full-refresh

# Nettoyer les anciens snapshots
dbt run-operation clean_old_snapshots

# Reset complet du projet
dbt clean
```

## 🎯 Conseils d'utilisation

### 1. **Développement efficace**
```bash
# Utilisez --select pour tester rapidement
dbt run --select +mon_modele+ --exclude tag:slow
```

### 2. **CI/CD et automatisation**
```bash
# Pipeline de validation
dbt parse && dbt compile && dbt build --fail-fast
```

### 3. **Performance**
```bash
# Parallélisation
dbt run --threads 10

# Déférer les dépendances en développement
dbt run --defer --state ./prod-manifest/
```

### 4. **Monitoring**
```bash
# Vérifier la fraîcheur
dbt source freshness

# Lister ce qui va être exécuté
dbt list --select tag:daily
```

## 📚 Sélecteurs avancés

| Sélecteur | Description | Exemple |
|-----------|-------------|---------|
| `model:` | Modèle spécifique | `--select model:curation_hosts` |
| `tag:` | Par tag | `--select tag:analytics` |
| `path:` | Par chemin | `--select path:models/marts` |
| `source:` | Sources | `--select source:raw_data` |
| `test_type:` | Type de test | `--select test_type:unit` |
| `config:` | Par configuration | `--select config.materialized:incremental` |
| `state:` | État modifié | `--select state:modified` |

## 🎯 Points clés à retenir

1. **`dbt build`** : Commande principale pour la production
2. **`--select` et `--exclude`** : Essentiels pour la sélectivité
3. **`dbt debug`** : Premier réflexe en cas de problème
4. **`dbt docs`** : Documentation automatique indispensable
5. **`dbt test`** : Qualité des données en continu

---

**Prochaine étape** : [Chapitre 1 - Configuration de l'environnement](chapitre-1-environnement.md)