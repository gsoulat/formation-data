# 03 - Object Storage Infomaniak (Swiss Backup)

Création d'un bucket S3 sur Infomaniak Swiss Backup.

## Prérequis

1. Un compte Infomaniak
2. Swiss Backup activé
3. Credentials S3 (à générer dans l'espace client)

## Obtenir les credentials

1. Se connecter à l'espace client Infomaniak
2. Aller dans Swiss Backup
3. Créer un projet si nécessaire
4. Générer les credentials S3 (Access Key + Secret Key)

## Swiss Backup

- Stockage S3 compatible
- Hébergement en Suisse (Genève)
- Tarification avantageuse
- Compatible avec tous les outils S3

## Utilisation

```bash
# Créer terraform.tfvars
cat > terraform.tfvars <<EOF
access_key  = "votre_access_key"
secret_key  = "votre_secret_key"
bucket_name = "mon-bucket-$(date +%s)"
EOF

terraform init
terraform apply

# Utiliser AWS CLI
export AWS_ACCESS_KEY_ID="votre_access_key"
export AWS_SECRET_ACCESS_KEY="votre_secret_key"
export AWS_ENDPOINT_URL="https://s3.swiss-backup02.infomaniak.com"

# Lister les buckets
aws s3 ls --endpoint-url $AWS_ENDPOINT_URL

# Upload
echo "Test" > test.txt
aws s3 cp test.txt s3://mon-bucket/test.txt --endpoint-url $AWS_ENDPOINT_URL

# Liste des objets
aws s3 ls s3://mon-bucket/ --endpoint-url $AWS_ENDPOINT_URL
```

## Endpoints

- **swiss-backup02**: https://s3.swiss-backup02.infomaniak.com
- **swiss-backup03**: https://s3.swiss-backup03.infomaniak.com

## Tarification

- Stockage: Environ 0.009 CHF/GB/mois
- Traffic: Gratuit
- Requêtes: Incluses

## Avantages

- Données en Suisse (RGPD)
- Prix compétitifs
- Pas de frais de sortie (egress gratuit)
- Compatible S3
