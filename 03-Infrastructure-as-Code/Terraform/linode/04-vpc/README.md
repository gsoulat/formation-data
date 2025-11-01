# 04 - VPC Linode

Création d'un VPC (Virtual Private Cloud) avec plusieurs instances.

## Architecture

- VPC avec subnet 10.0.1.0/24
- Instance web (10.0.1.2) avec IP publique et privée
- Instance backend (10.0.1.3) avec IP publique et privée
- Communication privée entre les instances via le VPC

## Avantages du VPC

- Réseau privé isolé et sécurisé
- Communication gratuite entre instances du même VPC
- Pas de limite de bande passante pour le trafic interne
- Latence très faible entre instances

## Utilisation

```bash
terraform init
terraform apply

# Les instances peuvent communiquer via leurs IPs privées
# Depuis web-server:
ssh root@<web_public_ip>
ping 10.0.1.3  # ping backend via IP privée
```

## Note

Le trafic entre instances via le VPC ne consomme pas de bande passante facturée.
