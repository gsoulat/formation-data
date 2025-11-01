# 03 - Object Storage Oracle Cloud

Création d'un bucket Object Storage avec versioning activé.

## Ressources créées

- Bucket Object Storage privé
- Versioning activé
- Un objet exemple (README.txt)

## Free Tier

- 20 GB de stockage Always Free
- 10 GB de téléchargement par mois

## Utilisation

```bash
terraform init
terraform apply

# Lister les objets avec OCI CLI
oci os object list \
  --bucket-name data-bucket \
  --namespace-name <namespace>

# Télécharger un fichier
oci os object get \
  --bucket-name data-bucket \
  --name README.txt \
  --file readme.txt
```

## Cas d'usage

- Stockage de backups
- Data Lake
- Hébergement de fichiers statiques
- Archives
