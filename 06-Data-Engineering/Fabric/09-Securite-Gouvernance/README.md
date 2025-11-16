# Module 09 - Sécurité & Gouvernance

## Objectifs d'apprentissage

À la fin de ce module, vous serez capable de :

- ✅ Gérer la sécurité des workspaces Fabric
- ✅ Implémenter Row-Level Security (RLS)
- ✅ Configurer Column-Level Security (CLS)
- ✅ Utiliser Dynamic Data Masking
- ✅ Intégrer Microsoft Purview pour la gouvernance
- ✅ Tracer la data lineage
- ✅ Appliquer des sensitivity labels
- ✅ Gérer compliance et audit

## Contenu du module

### [01 - Workspace Security](./01-workspace-security.md)
- Rôles dans les workspaces :
  - **Admin** : contrôle total
  - **Member** : création et modification
  - **Contributor** : édition de contenu
  - **Viewer** : lecture seule
- Permissions granulaires
- Service principals
- Managed identities
- Azure AD groups integration
- Best practices de gestion des accès

### [02 - Row-Level Security (RLS)](./02-row-level-security.md)
- Concept de RLS
- Création de rôles de sécurité
- DAX pour règles RLS
- Dynamic RLS (basé sur l'utilisateur connecté)
- Testing de RLS ("View as")
- RLS dans Direct Lake
- Limitations et considérations
- Use cases typiques (région, département, client)

### [03 - Column-Level Security (CLS)](./03-column-level-security.md)
- Introduction à CLS
- Définition de permissions par colonne
- Object-Level Security (OLS)
- Combinaison CLS + RLS
- Impact sur les performances
- Use cases : masquage de données sensibles (salaires, PII)

### [04 - Dynamic Data Masking](./04-dynamic-data-masking.md)
- Concept de masquage dynamique
- Types de masquage :
  - Default (complet)
  - Partial (partiel avec pattern)
  - Random
  - Email
  - Credit card
- Configuration dans SQL Database
- Permissions unmask
- Différence avec CLS

### [05 - Microsoft Purview Integration](./05-purview-integration.md)
- Vue d'ensemble de Purview
- Enregistrement de sources Fabric
- Scanning et cataloging
- Data classification automatique
- Glossaire métier (business glossary)
- Recherche de données
- Endorsement (certified, promoted)
- Integration avec Fabric

### [06 - Data Lineage](./06-data-lineage.md)
- Concept de lineage
- Lineage view dans Fabric
- Traçabilité end-to-end
- Impact analysis
- Dependency mapping
- Lineage dans Purview
- Best practices pour maintenir la traçabilité

### [07 - Sensitivity Labels](./07-sensitivity-labels.md)
- Microsoft Information Protection
- Création de labels (Public, Internal, Confidential, Highly Confidential)
- Application automatique vs manuelle
- Protection et chiffrement
- Label inheritance
- Downgrade protection
- Audit des labels

### [08 - Compliance & Audit](./08-compliance-audit.md)
- Audit logs dans Fabric
- Activity log
- Compliance standards (GDPR, HIPAA, SOC 2)
- Data retention policies
- Legal hold
- eDiscovery
- Compliance Manager
- Best practices de conformité

## Exercices pratiques

### Exercice 1 : Gestion workspace
1. Créer un workspace
2. Ajouter des membres avec différents rôles
3. Tester les permissions
4. Configurer un service principal

### Exercice 2 : Row-Level Security
1. Créer un modèle avec table Sales et Regions
2. Définir un rôle RLS par région
3. Tester avec "View as"
4. Implémenter dynamic RLS avec USERNAME()
5. Valider dans Power BI

### Exercice 3 : Column-Level Security
1. Identifier les colonnes sensibles (Salary, SSN)
2. Configurer CLS pour masquer ces colonnes
3. Créer des rôles avec accès différencié
4. Tester l'accès

### Exercice 4 : Purview integration
1. Se connecter à Microsoft Purview
2. Enregistrer un Lakehouse Fabric
3. Lancer un scan
4. Explorer le Data Catalog
5. Ajouter des descriptions métier

### Exercice 5 : Data Lineage
1. Créer un pipeline simple (Source → Bronze → Silver → Gold)
2. Visualiser le lineage
3. Analyser les dépendances
4. Simuler un changement et voir l'impact

### Exercice 6 : Sensitivity Labels
1. Créer des labels de sensibilité
2. Appliquer manuellement sur un dataset
3. Configurer une règle automatique
4. Vérifier l'héritage dans les rapports

## Quiz

1. Quels sont les 4 rôles principaux dans un workspace Fabric ?
2. Comment implémenter une RLS dynamique basée sur l'utilisateur ?
3. Quelle est la différence entre CLS et Dynamic Data Masking ?
4. À quoi sert Microsoft Purview dans Fabric ?
5. Comment tracer la lineage de bout en bout ?

## Exemples de code

### RLS avec DAX

```dax
// Rôle statique : Sales France
[Country] = "France"

// RLS dynamique basée sur l'utilisateur
[Email] = USERPRINCIPALNAME()

// RLS dynamique avec table de mapping
VAR CurrentUser = USERPRINCIPALNAME()
RETURN
    [Region] IN
        CALCULATETABLE(
            VALUES(UserRegions[Region]),
            UserRegions[Email] = CurrentUser
        )

// RLS multi-niveaux
[Region] IN {"North", "South"}
    || USERPRINCIPALNAME() = "admin@company.com"
```

### Column-Level Security (T-SQL)

```sql
-- Créer un rôle
CREATE ROLE SensitiveDataReader;

-- Révoquer l'accès par défaut
REVOKE SELECT ON dbo.Employees FROM SensitiveDataReader;

-- Autoriser uniquement certaines colonnes
GRANT SELECT ON dbo.Employees(EmployeeID, Name, Department) TO SensitiveDataReader;

-- Ajouter un utilisateur
ALTER ROLE SensitiveDataReader ADD MEMBER [user@company.com];
```

### Dynamic Data Masking (T-SQL)

```sql
-- Créer table avec masquage
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100) MASKED WITH (FUNCTION = 'email()'),
    Phone VARCHAR(20) MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-",4)'),
    CreditCard VARCHAR(20) MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)')
);

-- Donner permission de voir les données non masquées
GRANT UNMASK TO [privileged_user@company.com];

-- Ajouter masque sur colonne existante
ALTER TABLE Customers
ALTER COLUMN Salary ADD MASKED WITH (FUNCTION = 'default()');
```

### Sensitivity Labels (PowerShell)

```powershell
# Se connecter
Connect-PowerBIServiceAccount

# Appliquer un label
Set-PowerBIDataset -DatasetId "xxxx-xxxx-xxxx" `
    -SensitivityLabel "Confidential"

# Lister les labels disponibles
Get-PowerBISensitivityLabel
```

## Architecture de sécurité

### Layers de sécurité dans Fabric

```
┌─────────────────────────────────────────┐
│ Azure AD / Identity                     │
├─────────────────────────────────────────┤
│ Workspace Roles (Admin/Member/...)      │
├─────────────────────────────────────────┤
│ Item Permissions (Share individual)     │
├─────────────────────────────────────────┤
│ Row-Level Security (RLS)                │
├─────────────────────────────────────────┤
│ Column-Level Security (CLS)             │
├─────────────────────────────────────────┤
│ Dynamic Data Masking                    │
├─────────────────────────────────────────┤
│ Encryption at rest & in transit         │
└─────────────────────────────────────────┘
```

### Pattern : Sécurité multi-tenant

```
[User A] ─→ [RLS: TenantID = A] ─→ [Data A only]
[User B] ─→ [RLS: TenantID = B] ─→ [Data B only]
[Admin]  ─→ [No RLS filter]     ─→ [All Data]
```

## Checklist de sécurité

- [ ] Workspace roles configurés avec principe du moindre privilège
- [ ] Service principals utilisés pour automation (pas de comptes utilisateur)
- [ ] RLS implémentée pour données multi-tenant ou sensibles
- [ ] CLS configurée pour colonnes PII/sensibles
- [ ] Sensitivity labels appliqués sur tous les datasets
- [ ] Purview intégré pour cataloging et lineage
- [ ] Audit logs activés et monitorés
- [ ] Revue périodique des permissions
- [ ] Documentation des règles de sécurité
- [ ] Tests réguliers de RLS/CLS

## Ressources complémentaires

### Documentation officielle
- [Security in Fabric](https://learn.microsoft.com/fabric/security/security-overview)
- [Row-level security](https://learn.microsoft.com/fabric/security/service-admin-row-level-security)
- [Microsoft Purview](https://learn.microsoft.com/purview/)

### Compliance
- [GDPR compliance](https://learn.microsoft.com/compliance/regulatory/gdpr)
- [Azure compliance](https://learn.microsoft.com/azure/compliance/)

### Best practices
- [Security baseline for Power BI](https://learn.microsoft.com/security/benchmark/azure/baselines/power-bi-security-baseline)

## Durée estimée

- **Lecture** : 4-5 heures
- **Exercices** : 3-4 heures
- **Total** : 7-9 heures

## Prochaine étape

➡️ [Module 10 - Data Science & ML](../10-Data-Science-ML/)

---

[⬅️ Module précédent](../08-Real-Time-Analytics/) | [⬅️ Retour au sommaire](../README.md)
