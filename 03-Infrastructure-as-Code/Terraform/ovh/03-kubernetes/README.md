# 03 - Kubernetes managé OVH

Création d'un cluster Kubernetes managé sur OVHcloud.

## Ressources créées

- Cluster Kubernetes 1.28
- Node pool avec 3 nodes (autoscaling 1-5)
- Flavor: b2-7 (2 vCore, 7GB RAM par node)

## Caractéristiques

- Control plane managé par OVH (gratuit)
- Auto-scaling des nodes
- Mises à jour automatiques disponibles
- Intégration avec Load Balancer OVH
- Support persistent volumes (Cinder)

## Utilisation

```bash
terraform init
terraform apply

# Récupérer le kubeconfig
terraform output -raw kubeconfig > kubeconfig.yaml
chmod 600 kubeconfig.yaml

# Utiliser kubectl
export KUBECONFIG=./kubeconfig.yaml
kubectl get nodes
kubectl get pods -A

# Déployer une application
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get svc
```

## Coût

- Control plane: Gratuit
- Nodes: ~20€/mois par node b2-7
- Load Balancer: ~10€/mois
- Traffic sortant: Selon usage

## Versions Kubernetes supportées

OVH met à jour régulièrement les versions disponibles. Consultez la documentation pour les versions actuelles.
