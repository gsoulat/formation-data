# 03 - Réseau privé Hetzner Cloud

Cet exemple crée un réseau privé sur Hetzner Cloud avec un serveur connecté.

## Ressources créées

- Un réseau privé (10.0.0.0/16)
- Un sous-réseau (10.0.1.0/24)
- Un serveur connecté au réseau privé

## Avantages du réseau privé

- Communication sécurisée entre serveurs
- Pas de coût de bande passante pour le trafic interne
- Isolation du réseau

## Utilisation

```bash
terraform init
terraform apply

# Le serveur aura deux IPs :
# - IP publique pour l'accès externe
# - IP privée (10.0.1.5) pour la communication interne
```
