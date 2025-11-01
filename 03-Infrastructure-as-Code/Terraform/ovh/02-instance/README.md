# 02 - Instance Public Cloud OVH

Création d'une instance Public Cloud sur OVHcloud.

## Ressources créées

- Utilisateur OpenStack
- Instance s1-2 (1 vCore, 2GB RAM) Ubuntu 22.04
- Région: GRA11 (Gravelines, France)

## Flavors disponibles

- **s1-2**: 1 vCore, 2GB RAM (~7€/mois)
- **s1-4**: 1 vCore, 4GB RAM (~14€/mois)
- **s1-8**: 2 vCore, 8GB RAM (~28€/mois)
- **b2-7**: 2 vCore, 7GB RAM (~20€/mois)
- **b2-15**: 4 vCore, 15GB RAM (~40€/mois)

## Régions disponibles

- **GRA** (Gravelines, France)
- **SBG** (Strasbourg, France)
- **BHS** (Beauharnois, Canada)
- **DE** (Francfort, Allemagne)
- **UK** (Londres, UK)
- **WAW** (Varsovie, Pologne)

## Utilisation

```bash
terraform init
terraform apply

# Se connecter
terraform output -raw ssh_command
```

## Note

OVH Public Cloud utilise OpenStack sous le capot. Vous pouvez aussi utiliser le provider OpenStack directement.
