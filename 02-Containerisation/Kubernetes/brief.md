# Brief Pratique - Kubernetes (K8s)

## Informations Générales

**Durée :** 6 heures
**Type :** Exercices pratiques et projet
**Niveau :** Débutant à Intermédiaire
**Objectif :** Maîtriser les fondamentaux de Kubernetes et déployer une application complète sur Azure Kubernetes Service (AKS)

## Objectifs Pédagogiques

À l'issue de ce brief, vous serez capable de :
- Installer et configurer un environnement Kubernetes local
- Créer et gérer des Pods et des Deployments
- Configurer différents types de Services
- Utiliser ConfigMaps et Secrets pour la configuration
- Gérer la persistance avec les Volumes
- Configurer un Ingress Controller
- Déployer une application complète sur Azure AKS

## Prérequis

- Connaissance de base de Docker et des conteneurs
- Notions de ligne de commande (bash)
- Compréhension des concepts réseau de base
- Compte Azure actif (gratuit pour démarrer)
- Avoir suivi la formation Kubernetes

## Matériel Nécessaire

- Ordinateur avec au moins 8 Go de RAM
- Connexion Internet stable
- Éditeur de code (VS Code recommandé)
- Docker Desktop installé

---

## Partie 1 : Installation et Configuration (45 minutes)

### Exercice 1.1 : Installation de Minikube et kubectl

**Objectif :** Mettre en place un environnement Kubernetes local

**Tâches :**

1. Installez Minikube sur votre système :

```bash
# macOS
brew install minikube

# Windows (avec Chocolatey)
choco install minikube

# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

2. Installez kubectl :

```bash
# macOS
brew install kubectl

# Windows (avec Chocolatey)
choco install kubernetes-cli

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

3. Démarrez Minikube :

```bash
minikube start --driver=docker --cpus=2 --memory=4096
```

4. Vérifiez l'installation :

```bash
kubectl version --client
kubectl cluster-info
kubectl get nodes
```

**Livrable :** Capture d'écran montrant le résultat de `kubectl get nodes` avec votre node Minikube en état "Ready"

### Exercice 1.2 : Exploration du Cluster

**Objectif :** Se familiariser avec les commandes kubectl de base

**Tâches :**

1. Listez tous les namespaces :

```bash
kubectl get namespaces
```

2. Explorez les ressources dans le namespace kube-system :

```bash
kubectl get all -n kube-system
```

3. Obtenez des informations détaillées sur un pod système :

```bash
kubectl describe pod <nom-du-pod> -n kube-system
```

4. Activez le dashboard Kubernetes :

```bash
minikube dashboard
```

**Livrable :** Document listant les composants système que vous avez identifiés dans le namespace kube-system

---

## Partie 2 : Pods et Deployments (1h15)

### Exercice 2.1 : Créer votre Premier Pod

**Objectif :** Comprendre la structure d'un Pod

**Tâches :**

1. Créez un fichier `nginx-pod.yaml` :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    environment: dev
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

2. Déployez le Pod :

```bash
kubectl apply -f nginx-pod.yaml
```

3. Vérifiez le statut :

```bash
kubectl get pods
kubectl describe pod nginx-pod
kubectl logs nginx-pod
```

4. Accédez au Pod en port-forward :

```bash
kubectl port-forward nginx-pod 8080:80
# Accédez à http://localhost:8080 dans votre navigateur
```

5. Supprimez le Pod :

```bash
kubectl delete pod nginx-pod
```

**Livrable :** Fichier `nginx-pod.yaml` et capture d'écran du Pod en cours d'exécution

### Exercice 2.2 : Créer un Deployment

**Objectif :** Gérer des Pods avec un Deployment

**Tâches :**

1. Créez un fichier `web-deployment.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

2. Déployez l'application :

```bash
kubectl apply -f web-deployment.yaml
```

3. Vérifiez le déploiement :

```bash
kubectl get deployments
kubectl get pods -l app=web
kubectl get replicasets
```

4. Effectuez un scale-up :

```bash
kubectl scale deployment web-app --replicas=5
kubectl get pods -w
```

5. Testez l'auto-healing en supprimant un Pod :

```bash
kubectl delete pod <nom-d-un-pod>
kubectl get pods -w
```

6. Mettez à jour l'image :

```bash
kubectl set image deployment/web-app nginx=nginx:1.26
kubectl rollout status deployment/web-app
```

7. Visualisez l'historique des déploiements :

```bash
kubectl rollout history deployment/web-app
```

8. Effectuez un rollback si nécessaire :

```bash
kubectl rollout undo deployment/web-app
```

**Livrable :** Fichier `web-deployment.yaml` et captures d'écran montrant :
- Les 5 réplicas en cours d'exécution
- Le processus d'auto-healing
- La mise à jour de l'image

---

## Partie 3 : Services et Networking (1h)

### Exercice 3.1 : Service ClusterIP

**Objectif :** Créer un service interne au cluster

**Tâches :**

1. Créez un fichier `web-service-clusterip.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

2. Déployez le service :

```bash
kubectl apply -f web-service-clusterip.yaml
```

3. Vérifiez le service :

```bash
kubectl get services
kubectl describe service web-service
```

4. Testez le service depuis un Pod temporaire :

```bash
kubectl run test-pod --rm -it --image=curlimages/curl -- sh
# Dans le pod :
curl http://web-service
exit
```

**Livrable :** Fichier `web-service-clusterip.yaml` et capture de la réponse curl

### Exercice 3.2 : Service NodePort

**Objectif :** Exposer un service sur un port de node

**Tâches :**

1. Créez un fichier `web-service-nodeport.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
```

2. Déployez le service :

```bash
kubectl apply -f web-service-nodeport.yaml
```

3. Obtenez l'URL Minikube :

```bash
minikube service web-nodeport --url
```

4. Accédez à l'application via votre navigateur

**Livrable :** Fichier `web-service-nodeport.yaml` et capture d'écran de l'application accessible via NodePort

### Exercice 3.3 : Service LoadBalancer (Simulation)

**Objectif :** Comprendre le fonctionnement d'un LoadBalancer

**Tâches :**

1. Créez un fichier `web-service-lb.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

2. Déployez le service :

```bash
kubectl apply -f web-service-lb.yaml
```

3. Avec Minikube, créez un tunnel pour simuler le LoadBalancer :

```bash
# Dans un terminal séparé
minikube tunnel
```

4. Vérifiez l'IP externe :

```bash
kubectl get service web-loadbalancer
```

**Livrable :** Fichier `web-service-lb.yaml` et capture d'écran montrant l'EXTERNAL-IP

---

## Partie 4 : Configuration avec ConfigMaps et Secrets (45 minutes)

### Exercice 4.1 : ConfigMap

**Objectif :** Gérer la configuration d'application

**Tâches :**

1. Créez un fichier `app-config.yaml` :

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.properties: |
    environment=development
    log_level=debug
    max_connections=100
  database.url: "postgresql://db-service:5432/myapp"
  feature.flags: "new-ui:true,beta-features:false"
```

2. Créez un Deployment qui utilise la ConfigMap :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-config
spec:
  replicas: 2
  selector:
    matchLabels:
      app: configured-app
  template:
    metadata:
      labels:
        app: configured-app
    spec:
      containers:
      - name: app
        image: nginx:1.25
        env:
        - name: DATABASE_URL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database.url
        - name: FEATURE_FLAGS
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: feature.flags
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config
      volumes:
      - name: config-volume
        configMap:
          name: app-config
```

3. Déployez les ressources :

```bash
kubectl apply -f app-config.yaml
kubectl apply -f app-deployment-config.yaml
```

4. Vérifiez la configuration dans un Pod :

```bash
kubectl exec -it <pod-name> -- cat /etc/config/app.properties
kubectl exec -it <pod-name> -- env | grep DATABASE_URL
```

**Livrable :** Fichiers YAML et capture d'écran montrant les variables d'environnement et fichiers de configuration

### Exercice 4.2 : Secrets

**Objectif :** Gérer des données sensibles de manière sécurisée

**Tâches :**

1. Créez un Secret pour les identifiants de base de données :

```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=SuperSecretPass123!
```

2. Créez un fichier `app-with-secrets.yaml` :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-secrets
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      containers:
      - name: app
        image: nginx:1.25
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
```

3. Déployez l'application :

```bash
kubectl apply -f app-with-secrets.yaml
```

4. Vérifiez que les secrets sont bien injectés (mais masqués) :

```bash
kubectl exec -it <pod-name> -- env | grep DB_
```

5. Créez un Secret TLS pour HTTPS :

```bash
# Générez un certificat auto-signé
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=myapp.local"

# Créez le Secret TLS
kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key
```

**Livrable :** Fichier `app-with-secrets.yaml` et captures d'écran montrant :
- Les secrets créés (sans révéler leur contenu)
- Les variables d'environnement dans le Pod

---

## Partie 5 : Persistance avec Volumes (45 minutes)

### Exercice 5.1 : EmptyDir Volume

**Objectif :** Comprendre les volumes éphémères

**Tâches :**

1. Créez un fichier `pod-with-emptydir.yaml` :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shared-volume-pod
spec:
  containers:
  - name: writer
    image: busybox
    command: ['sh', '-c', 'while true; do date >> /data/log.txt; sleep 5; done']
    volumeMounts:
    - name: shared-data
      mountPath: /data
  - name: reader
    image: busybox
    command: ['sh', '-c', 'tail -f /data/log.txt']
    volumeMounts:
    - name: shared-data
      mountPath: /data
  volumes:
  - name: shared-data
    emptyDir: {}
```

2. Déployez le Pod :

```bash
kubectl apply -f pod-with-emptydir.yaml
```

3. Observez les logs des deux conteneurs :

```bash
kubectl logs shared-volume-pod -c writer
kubectl logs shared-volume-pod -c reader -f
```

**Livrable :** Fichier `pod-with-emptydir.yaml` et capture des logs montrant le partage de données

### Exercice 5.2 : PersistentVolume et PersistentVolumeClaim

**Objectif :** Gérer le stockage persistant

**Tâches :**

1. Créez un fichier `persistent-storage.yaml` :

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /data/pv-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

2. Créez un Deployment utilisant le PVC :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-storage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: persistent-app
  template:
    metadata:
      labels:
        app: persistent-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        volumeMounts:
        - name: data-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: data-volume
        persistentVolumeClaim:
          claimName: pvc-data
```

3. Déployez les ressources :

```bash
kubectl apply -f persistent-storage.yaml
kubectl apply -f app-with-storage.yaml
```

4. Vérifiez le PV et PVC :

```bash
kubectl get pv
kubectl get pvc
```

5. Écrivez des données dans le volume :

```bash
kubectl exec -it <pod-name> -- bash -c "echo '<h1>Persistent Data</h1>' > /usr/share/nginx/html/index.html"
```

6. Supprimez et recréez le Pod pour vérifier la persistance :

```bash
kubectl delete pod <pod-name>
# Attendez que le nouveau Pod soit créé
kubectl exec -it <nouveau-pod-name> -- cat /usr/share/nginx/html/index.html
```

**Livrable :** Fichiers YAML et captures d'écran montrant :
- Le PV et PVC créés et liés
- La persistance des données après suppression du Pod

---

## Partie 6 : Ingress Controller (30 minutes)

### Exercice 6.1 : Configuration d'Ingress

**Objectif :** Exposer plusieurs services via un point d'entrée unique

**Tâches :**

1. Activez l'addon Ingress dans Minikube :

```bash
minikube addons enable ingress
```

2. Créez deux applications de test :

```yaml
# app1-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 80
```

```yaml
# app2-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: httpd
        image: httpd:2.4
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 80
```

3. Créez un fichier `ingress.yaml` :

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

4. Déployez toutes les ressources :

```bash
kubectl apply -f app1-deployment.yaml
kubectl apply -f app2-deployment.yaml
kubectl apply -f ingress.yaml
```

5. Ajoutez une entrée dans votre fichier hosts :

```bash
# Obtenez l'IP de Minikube
minikube ip

# Ajoutez dans /etc/hosts (Linux/macOS) ou C:\Windows\System32\drivers\etc\hosts (Windows)
<minikube-ip> myapp.local
```

6. Testez l'Ingress :

```bash
curl http://myapp.local/app1
curl http://myapp.local/app2
```

**Livrable :** Fichiers YAML et captures d'écran montrant :
- L'Ingress créé
- Les réponses de curl pour les deux chemins

---

## Partie 7 : Projet Final - Déploiement sur Azure AKS (1h30)

### Objectif du Projet

Déployer une application web complète sur Azure Kubernetes Service (AKS) avec :
- Frontend (Nginx)
- Backend API (Node.js ou Python)
- Base de données (PostgreSQL)
- Configuration avec ConfigMaps et Secrets
- Stockage persistant
- Exposition via LoadBalancer et Ingress

### Étape 7.1 : Préparation Azure

**Tâches :**

1. Installez Azure CLI :

```bash
# macOS
brew install azure-cli

# Windows
# Téléchargez depuis https://aka.ms/installazurecliwindows

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

2. Connectez-vous à Azure :

```bash
az login
```

3. Créez un groupe de ressources :

```bash
az group create --name rg-kubernetes-training --location francecentral
```

4. Créez un Azure Container Registry (ACR) :

```bash
az acr create \
  --resource-group rg-kubernetes-training \
  --name acrk8straining \
  --sku Basic
```

5. Créez un cluster AKS :

```bash
az aks create \
  --resource-group rg-kubernetes-training \
  --name aks-training-cluster \
  --node-count 2 \
  --node-vm-size Standard_B2s \
  --enable-addons monitoring \
  --attach-acr acrk8straining \
  --generate-ssh-keys
```

6. Connectez kubectl à AKS :

```bash
az aks get-credentials \
  --resource-group rg-kubernetes-training \
  --name aks-training-cluster
```

7. Vérifiez la connexion :

```bash
kubectl get nodes
```

**Livrable :** Capture d'écran des ressources Azure créées et des nodes AKS

### Étape 7.2 : Préparation des Images Docker

**Tâches :**

1. Créez un dossier de projet :

```bash
mkdir fullstack-k8s-app
cd fullstack-k8s-app
```

2. Créez un simple backend API (fichier `backend/app.py`) :

```python
from flask import Flask, jsonify
import os
import psycopg2

app = Flask(__name__)

@app.route('/api/health')
def health():
    return jsonify({"status": "healthy", "service": "backend"})

@app.route('/api/data')
def get_data():
    db_host = os.getenv('DB_HOST', 'localhost')
    return jsonify({
        "message": "Hello from Kubernetes!",
        "database": db_host,
        "items": ["Item 1", "Item 2", "Item 3"]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

3. Créez un Dockerfile pour le backend (`backend/Dockerfile`) :

```dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN pip install flask psycopg2-binary

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
```

4. Créez un frontend simple (`frontend/index.html`) :

```html
<!DOCTYPE html>
<html>
<head>
    <title>Kubernetes Full Stack App</title>
    <style>
        body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; }
        .container { background: #f0f0f0; padding: 20px; border-radius: 8px; }
        button { padding: 10px 20px; font-size: 16px; cursor: pointer; }
        #result { margin-top: 20px; padding: 15px; background: white; border-radius: 4px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Kubernetes Full Stack Application</h1>
        <button onclick="fetchData()">Fetch Data from Backend</button>
        <div id="result"></div>
    </div>
    <script>
        async function fetchData() {
            const result = document.getElementById('result');
            result.innerHTML = 'Loading...';
            try {
                const response = await fetch('/api/data');
                const data = await response.json();
                result.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            } catch (error) {
                result.innerHTML = 'Error: ' + error.message;
            }
        }
    </script>
</body>
</html>
```

5. Créez un Dockerfile pour le frontend avec Nginx (`frontend/Dockerfile`) :

```dockerfile
FROM nginx:1.25-alpine

COPY index.html /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
```

6. Créez la configuration Nginx (`frontend/nginx.conf`) :

```nginx
server {
    listen 80;
    server_name _;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /api/ {
        proxy_pass http://backend-service:5000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

7. Construisez et poussez les images vers ACR :

```bash
# Se connecter à ACR
az acr login --name acrk8straining

# Construire et pousser le backend
cd backend
docker build -t acrk8straining.azurecr.io/backend:v1 .
docker push acrk8straining.azurecr.io/backend:v1

# Construire et pousser le frontend
cd ../frontend
docker build -t acrk8straining.azurecr.io/frontend:v1 .
docker push acrk8straining.azurecr.io/frontend:v1
```

**Livrable :** Code source complet et captures d'écran des images dans ACR

### Étape 7.3 : Déploiement de la Base de Données

**Tâches :**

1. Créez un fichier `k8s/postgres-storage.yaml` :

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: managed-csi
```

2. Créez un Secret pour PostgreSQL (`k8s/postgres-secret.yaml`) :

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  POSTGRES_USER: appuser
  POSTGRES_PASSWORD: AppPassword123!
  POSTGRES_DB: appdb
```

3. Créez le Deployment PostgreSQL (`k8s/postgres-deployment.yaml`) :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        envFrom:
        - secretRef:
            name: postgres-secret
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
```

4. Déployez PostgreSQL :

```bash
kubectl apply -f k8s/postgres-storage.yaml
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/postgres-deployment.yaml
```

5. Vérifiez le déploiement :

```bash
kubectl get pvc
kubectl get pods -l app=postgres
kubectl logs -l app=postgres
```

**Livrable :** Fichiers YAML et capture d'écran de PostgreSQL en cours d'exécution

### Étape 7.4 : Déploiement du Backend

**Tâches :**

1. Créez un ConfigMap pour le backend (`k8s/backend-config.yaml`) :

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  DB_HOST: postgres-service
  DB_PORT: "5432"
  DB_NAME: appdb
  LOG_LEVEL: info
```

2. Créez le Deployment backend (`k8s/backend-deployment.yaml`) :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: acrk8straining.azurecr.io/backend:v1
        ports:
        - containerPort: 5000
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: backend-config
              key: DB_HOST
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /api/health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
```

3. Déployez le backend :

```bash
kubectl apply -f k8s/backend-config.yaml
kubectl apply -f k8s/backend-deployment.yaml
```

4. Vérifiez le déploiement :

```bash
kubectl get pods -l app=backend
kubectl logs -l app=backend
```

**Livrable :** Fichiers YAML et capture d'écran du backend en cours d'exécution

### Étape 7.5 : Déploiement du Frontend

**Tâches :**

1. Créez le Deployment frontend (`k8s/frontend-deployment.yaml`) :

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: acrk8straining.azurecr.io/frontend:v1
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

2. Déployez le frontend :

```bash
kubectl apply -f k8s/frontend-deployment.yaml
```

3. Attendez que le LoadBalancer obtienne une IP publique :

```bash
kubectl get service frontend-service -w
```

4. Accédez à l'application via l'IP publique du LoadBalancer

**Livrable :** Fichier YAML et capture d'écran de l'application accessible via Internet

### Étape 7.6 : Configuration Ingress (Bonus)

**Tâches :**

1. Installez l'Ingress Controller NGINX :

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

2. Créez un fichier `k8s/ingress.yaml` :

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 5000
```

3. Déployez l'Ingress :

```bash
kubectl apply -f k8s/ingress.yaml
```

4. Configurez un nom de domaine pointant vers l'IP de l'Ingress Controller

**Livrable :** Fichier `ingress.yaml` et capture d'écran de l'application accessible via le domaine

### Étape 7.7 : Monitoring et Scaling

**Tâches :**

1. Configurez l'autoscaling horizontal :

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

2. Déployez le HPA :

```bash
kubectl apply -f k8s/backend-hpa.yaml
```

3. Visualisez les métriques dans Azure Portal :

```bash
az aks browse --resource-group rg-kubernetes-training --name aks-training-cluster
```

4. Testez la montée en charge avec un générateur de charge :

```bash
kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://backend-service:5000/api/data; done"
```

5. Observez l'autoscaling :

```bash
kubectl get hpa -w
kubectl get pods -l app=backend -w
```

**Livrable :** Fichier HPA et captures d'écran montrant l'autoscaling en action

### Étape 7.8 : Nettoyage des Ressources

**Important :** Pour éviter des frais Azure, nettoyez les ressources après le projet.

```bash
# Supprimer le cluster AKS
az aks delete \
  --resource-group rg-kubernetes-training \
  --name aks-training-cluster \
  --yes --no-wait

# Supprimer le groupe de ressources
az group delete \
  --name rg-kubernetes-training \
  --yes --no-wait
```

---

## Critères d'Évaluation

### Partie 1 : Installation et Configuration (10 points)
- Minikube et kubectl correctement installés (5 pts)
- Exploration du cluster et compréhension des composants (5 pts)

### Partie 2 : Pods et Deployments (15 points)
- Pod créé et fonctionnel (5 pts)
- Deployment avec réplication (5 pts)
- Test de l'auto-healing et mise à jour rolling (5 pts)

### Partie 3 : Services et Networking (15 points)
- Service ClusterIP fonctionnel (5 pts)
- Service NodePort accessible (5 pts)
- Service LoadBalancer configuré (5 pts)

### Partie 4 : Configuration (10 points)
- ConfigMap créée et utilisée correctement (5 pts)
- Secrets créés et sécurisés (5 pts)

### Partie 5 : Persistance (10 points)
- EmptyDir volume fonctionnel (3 pts)
- PV/PVC créés et liés (4 pts)
- Test de persistance réussi (3 pts)

### Partie 6 : Ingress (10 points)
- Ingress Controller installé (3 pts)
- Ingress configuré pour plusieurs services (4 pts)
- Routing fonctionnel (3 pts)

### Partie 7 : Projet Final AKS (30 points)
- Infrastructure Azure créée correctement (5 pts)
- Images Docker créées et poussées dans ACR (5 pts)
- Base de données PostgreSQL déployée avec persistance (5 pts)
- Backend déployé avec configuration (5 pts)
- Frontend accessible via LoadBalancer (5 pts)
- Application complète fonctionnelle (3 pts)
- Ingress configuré (bonus) (2 pts)

## Ressources et Documentation

### Documentation Officielle
- Kubernetes Documentation : https://kubernetes.io/docs/
- kubectl Cheat Sheet : https://kubernetes.io/docs/reference/kubectl/cheatsheet/
- Azure AKS Documentation : https://docs.microsoft.com/azure/aks/

### Outils Utiles
- Lens : IDE Kubernetes (https://k8slens.dev/)
- k9s : Terminal UI pour Kubernetes (https://k9scli.io/)
- kubectx/kubens : Switch entre contextes et namespaces

### Commandes Kubectl Essentielles

```bash
# Informations sur le cluster
kubectl cluster-info
kubectl get nodes
kubectl get namespaces

# Gestion des ressources
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get all

# Détails et debugging
kubectl describe <resource> <name>
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # follow
kubectl logs <pod-name> -c <container-name>

# Exécution de commandes
kubectl exec -it <pod-name> -- /bin/bash
kubectl port-forward <pod-name> 8080:80

# Application de configurations
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>

# Scaling
kubectl scale deployment <name> --replicas=5
kubectl autoscale deployment <name> --min=3 --max=10 --cpu-percent=70

# Rollout
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>

# Contextes et namespaces
kubectl config get-contexts
kubectl config use-context <context-name>
kubectl config set-context --current --namespace=<namespace>

# Labels et sélecteurs
kubectl get pods -l app=nginx
kubectl label pod <name> env=production
```

## Conseils et Bonnes Pratiques

1. **Organisation des Fichiers**
   - Utilisez un dossier `k8s/` pour tous vos manifests YAML
   - Séparez les ressources par type ou par composant
   - Utilisez des noms explicites pour vos fichiers

2. **Naming Convention**
   - Utilisez des noms en minuscules avec des tirets
   - Soyez cohérent dans vos conventions de nommage
   - Incluez le type de ressource dans le nom du fichier

3. **Labels et Annotations**
   - Utilisez des labels pour organiser et sélectionner les ressources
   - Ajoutez des annotations pour la documentation

4. **Sécurité**
   - Ne committez JAMAIS de secrets en clair dans Git
   - Utilisez toujours des Secrets pour les données sensibles
   - Définissez des limites de ressources pour tous les conteneurs

5. **Monitoring et Logs**
   - Consultez régulièrement les logs de vos Pods
   - Utilisez `kubectl describe` pour diagnostiquer les problèmes
   - Configurez des health checks (liveness/readiness probes)

6. **Performance**
   - Définissez des requests et limits appropriés
   - Utilisez l'autoscaling quand c'est pertinent
   - Optimisez vos images Docker

7. **Documentation**
   - Commentez vos fichiers YAML
   - Documentez votre architecture
   - Tenez à jour un README avec les commandes importantes

## Livrables Finaux

Créez un dossier compressé contenant :

1. **Dossier `exercices/`** : Tous vos fichiers YAML des parties 1 à 6
2. **Dossier `projet-final/`** :
   - Code source de l'application (backend + frontend)
   - Tous les manifests Kubernetes
   - Dockerfiles
   - README.md avec instructions de déploiement
3. **Dossier `captures/`** : Screenshots de chaque exercice
4. **`rapport.md`** : Document récapitulatif incluant :
   - Résumé de votre expérience
   - Difficultés rencontrées et solutions
   - Améliorations possibles
   - Architecture finale de votre projet
   - URL de l'application déployée sur AKS

## Support

Pour toute question ou problème technique :
- Consultez la documentation officielle Kubernetes
- Utilisez `kubectl describe` et `kubectl logs` pour le debugging
- Vérifiez les forums StackOverflow avec le tag `kubernetes`
- Documentation Azure : https://docs.microsoft.com/azure/aks/

Bon courage dans votre apprentissage de Kubernetes !
