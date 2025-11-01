# 04 - Object Storage OVH (S3 compatible)

Création d'un container Object Storage compatible S3 sur OVHcloud.

## Ressources créées

- Utilisateur S3 avec credentials
- Container Object Storage (bucket)
- Credentials S3 (access key / secret key)

## Compatibilité S3

OVH Object Storage est compatible avec l'API S3 d'Amazon:
- AWS CLI
- SDKs S3 (boto3, aws-sdk, etc.)
- Outils S3 (s3cmd, rclone, etc.)

## Utilisation

```bash
terraform init
terraform apply

# Récupérer les credentials
terraform output -raw s3_access_key
terraform output -raw s3_secret_key

# Configuration AWS CLI
export AWS_ACCESS_KEY_ID=$(terraform output -raw s3_access_key)
export AWS_SECRET_ACCESS_KEY=$(terraform output -raw s3_secret_key)
export AWS_ENDPOINT_URL="https://s3.gra.io.cloud.ovh.net"

# Lister les buckets
aws s3 ls --endpoint-url $AWS_ENDPOINT_URL

# Upload un fichier
echo "Hello OVH" > test.txt
aws s3 cp test.txt s3://my-data-bucket/ --endpoint-url $AWS_ENDPOINT_URL

# Lister les objets
aws s3 ls s3://my-data-bucket/ --endpoint-url $AWS_ENDPOINT_URL
```

## Endpoints par région

- **GRA**: https://s3.gra.io.cloud.ovh.net
- **SBG**: https://s3.sbg.io.cloud.ovh.net
- **BHS**: https://s3.bhs.io.cloud.ovh.net
- **DE**: https://s3.de.io.cloud.ovh.net
- **UK**: https://s3.uk.io.cloud.ovh.net
- **WAW**: https://s3.waw.io.cloud.ovh.net

## Tarification

- Stockage: ~0.01€/GB/mois
- Traffic sortant: ~0.01€/GB (selon destination)
- Traffic entrant: Gratuit
- Requêtes: Incluses

## Cas d'usage

- Backup et archivage
- Data Lake
- Hébergement de fichiers statiques
- Distribution de contenu
