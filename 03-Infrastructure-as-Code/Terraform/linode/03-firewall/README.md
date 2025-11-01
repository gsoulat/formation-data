# 03 - Firewall Linode

Création d'un firewall cloud Linode pour sécuriser une instance.

## Ressources créées

- Firewall avec règles pour HTTP/HTTPS/SSH
- Instance web protégée par le firewall

## Règles de sécurité

**Entrantes (ACCEPT):**
- Port 22 (SSH)
- Port 80 (HTTP)
- Port 443 (HTTPS)

**Sortantes:** ACCEPT (tout autorisé)

**Politique par défaut:** DROP (tout le reste est bloqué)

## Utilisation

```bash
terraform init
terraform apply

# L'instance est maintenant protégée par le firewall
# Seuls les ports 22, 80 et 443 sont accessibles
```
