# Images pour le Guide Interface Graphique Snowflake

Ce dossier contient toutes les captures d'écran nécessaires pour le guide Snowflake interface graphique.

## 📸 Liste des captures requises

### 1. Création de compte (01-creation-compte.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `01-signup-homepage.png` | Page d'accueil Snowflake avec bouton "Start for Free" | Étape 1 |
| `02-signup-form.png` | Formulaire d'inscription rempli | Étape 2 |
| `03-edition-selection.png` | Page de sélection de l'édition Snowflake | Étape 3 |
| `04-cloud-provider-region.png` | Sélection du cloud provider et région | Étape 4 |
| `05-activation-email.png` | Email d'activation reçu | Étape 5 |
| `06-credentials-creation.png` | Création du nom d'utilisateur et mot de passe | Étape 6 |
| `07-first-login.png` | Première connexion réussie à l'interface | Étape 7 |
| `08-initial-setup-options.png` | Options de configuration initiale | Étape 8 |
| `09-trial-dashboard.png` | Dashboard avec crédits et durée d'essai | Info essai |

### 2. Connexion (02-connexion.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `10-login-page.png` | Page de connexion avec champs username/password | Connexion |
| `11-main-interface.png` | Interface principale avec onglets | Navigation |

### 3. Création de rôle (03-creation-role.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `12-roles-navigation.png` | Navigation vers la section Roles | Accès |
| `13-role-creation-form.png` | Formulaire de création de rôle | Création |

### 4. Création warehouse (04-creation-warehouse.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `13-warehouses-page.png` | Page de gestion des warehouses | Accès |
| `14-warehouse-creation-form.png` | Formulaire de création warehouse | Création |
| `15-warehouse-created.png` | Warehouse créé dans la liste | Validation |
| `16-warehouse-schedule.png` | Configuration planification suspension 17h | Planification |

### 5. Database & Schema (05-creation-database-schema.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `17-databases-navigation.png` | Navigation vers les bases de données | Accès |
| `18-database-creation-form.png` | Formulaire de création database | Création DB |
| `19-schema-creation.png` | Création du schéma | Création schema |

### 6. Tables (06-creation-tables.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `19-create-menu-overview.png` | Menu Create avec toutes les options | Vue d'ensemble |
| `20-table-creation-interface.png` | Interface de création de table | Interface |
| `21-customers-table-columns.png` | Définition colonnes CUSTOMERS | Table 1 |
| `22-products-table-columns.png` | Définition colonnes PRODUCTS | Table 2 |
| `23-orders-table-columns.png` | Définition colonnes ORDERS | Table 3 |
| `24-order-items-table-columns.png` | Définition colonnes ORDER_ITEMS | Table 4 |

### 7. Import données (07-import-donnees.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `25-data-loading-interface.png` | Interface de chargement de données | Import |
| `26-csv-format-config.png` | Configuration format CSV | Configuration |
| `27-csv-column-mapping.png` | Mapping colonnes CSV vers table | Mapping |
| `28-import-success-status.png` | Statut d'import réussi | Validation |
| `29-stage-file-upload.png` | Upload fichiers vers stage | Stage |

### 8. Privilèges (08-gestion-privileges.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `29-warehouse-privileges.png` | Attribution privilèges warehouse | Privilèges |
| `30-role-privileges-list.png` | Liste privilèges attribués au rôle | Liste |
| `31-user-role-assignment.png` | Attribution rôle à utilisateur | Attribution |
| `32-user-creation-form.png` | Formulaire création utilisateur | Création user |

### 9. Monitoring (09-monitoring.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `33-usage-metrics-dashboard.png` | Dashboard métriques d'utilisation | Métriques |
| `34-warehouse-metrics.png` | Détails et métriques warehouse | Warehouse |
| `35-query-history.png` | Historique requêtes avec filtres | Historique |
| `36-query-profile.png` | Query Profile avec plan d'exécution | Performance |
| `37-resource-monitor-config.png` | Configuration monitor de ressources | Monitor |
| `38-notifications-config.png` | Configuration des notifications | Alertes |

### 10. Sécurité (10-securite.md)
| Fichier | Description | Usage |
|---------|-------------|-------|
| `39-security-page.png` | Page sécurité avec historique connexions | Sécurité |
| `40-mfa-setup.png` | Configuration MFA pour utilisateur | MFA |
| `41-encryption-config.png` | Configuration du chiffrement | Chiffrement |
| `42-password-policy.png` | Politique de mots de passe | Politique |
| `43-network-policy.png` | Configuration politique réseau | Réseau |

## 📋 Instructions pour les captures

### Format recommandé
- **Format** : PNG (meilleure qualité)
- **Résolution** : 1920x1080 minimum
- **Compression** : Optimisée pour le web

### Conseils de capture
1. **Interface propre** : Masquez informations sensibles
2. **Zoom approprié** : Texte lisible à 100%
3. **Annotations** : Surlignez éléments importants si nécessaire
4. **Cohérence** : Même navigateur/thème pour toutes les captures

### Éléments à masquer
- Noms de comptes réels
- Adresses email personnelles
- Identifiants de connexion
- Informations de facturation

## 📁 Organisation des fichiers

```
images/
├── README.md (ce fichier)
├── 01-signup-homepage.png
├── 02-edition-selection.png
├── ...
└── 43-network-policy.png
```

## 🔄 Maintenance

- **Mise à jour** : Captures à refaire si interface Snowflake change
- **Versions** : Indiquer version Snowflake dans nom si nécessaire
- **Liens brisés** : Vérifier régulièrement que liens fonctionnent

## 📝 Notes importantes

- Les images sont référencées relativement : `images/nom-fichier.png`
- Aucun texte alternatif dans les liens pour éviter duplication
- Descriptions ajoutées en italique sous chaque image
- Numérotation séquentielle pour faciliter maintenance

---

*Pour ajouter une nouvelle capture, suivez la convention de nommage et mettez à jour ce README.*