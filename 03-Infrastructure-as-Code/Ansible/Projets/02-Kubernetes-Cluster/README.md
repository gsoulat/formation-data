# Projet 02 : Cluster Kubernetes avec Ansible

## Objectif

Déployer un cluster Kubernetes complet (1 master + 2 workers) en utilisant Ansible, avec networking, ingress controller, monitoring et dashboard.

## Architecture

```
┌─────────────────────────────────────────────┐
│         Control Plane (Master)              │
│         - API Server                         │
│         - etcd                               │
│         - Controller Manager                 │
│         - Scheduler                          │
│         192.168.1.10                         │
└──────────────────┬──────────────────────────┘
                   │
       ┌───────────┴────────────┐
       │                        │
┌──────▼──────┐         ┌───────▼──────┐
│  Worker 1   │         │  Worker 2    │
│  - kubelet  │         │  - kubelet   │
│  - kube-proxy│        │  - kube-proxy│
│  - Container│         │  - Container │
│  Runtime    │         │  Runtime     │
│ 192.168.1.11│         │ 192.168.1.12 │
└─────────────┘         └──────────────┘

Add-ons:
- Calico CNI (networking)
- Nginx Ingress Controller
- MetalLB (LoadBalancer)
- Kubernetes Dashboard
- Prometheus + Grafana (monitoring)
```

## Composants

### 1. Control Plane (Master Node)
- **kube-apiserver** : Point d'entrée API du cluster
- **etcd** : Base de données clé-valeur pour l'état du cluster
- **kube-controller-manager** : Gestion des contrôleurs
- **kube-scheduler** : Planification des pods

### 2. Worker Nodes
- **kubelet** : Agent sur chaque node
- **kube-proxy** : Proxy réseau
- **Container Runtime** : containerd ou CRI-O

### 3. Networking (Calico)
- **CNI Plugin** : Container Network Interface
- **IP-in-IP** ou **VXLAN** encapsulation
- **Network Policies** : Sécurité réseau

### 4. Ingress Controller (Nginx)
- **Reverse Proxy** : Routage HTTP/HTTPS
- **SSL Termination** : Gestion des certificats
- **Load Balancing** : Distribution du trafic

### 5. Monitoring
- **Prometheus** : Collecte de métriques
- **Grafana** : Visualisation
- **Alertmanager** : Gestion des alertes

## Prérequis

- 3 serveurs Ubuntu 22.04 (minimum 2 CPU, 4 GB RAM par serveur)
- Ansible 2.12+ installé sur la machine de contrôle
- Accès SSH avec clés aux serveurs
- Connexion Internet sur tous les serveurs
- Connaissances Kubernetes de base

## Structure du Projet

```
02-Kubernetes-Cluster/
├── README.md
├── ansible.cfg
├── inventory/
│   ├── production
│   └── staging
├── group_vars/
│   ├── all.yml
│   ├── master.yml
│   └── workers.yml
├── host_vars/
│   └── k8s-master.yml
├── roles/
│   ├── common/
│   │   ├── tasks/
│   │   ├── handlers/
│   │   └── templates/
│   ├── containerd/
│   │   ├── tasks/
│   │   └── templates/
│   ├── kubernetes/
│   │   ├── tasks/
│   │   ├── handlers/
│   │   └── templates/
│   ├── master/
│   │   ├── tasks/
│   │   └── templates/
│   ├── worker/
│   │   └── tasks/
│   ├── calico/
│   │   ├── tasks/
│   │   └── files/
│   ├── ingress/
│   │   ├── tasks/
│   │   └── files/
│   ├── metallb/
│   │   ├── tasks/
│   │   └── templates/
│   ├── dashboard/
│   │   ├── tasks/
│   │   └── files/
│   └── monitoring/
│       ├── tasks/
│       └── files/
├── playbooks/
│   ├── site.yml
│   ├── prepare-nodes.yml
│   ├── install-k8s.yml
│   ├── init-master.yml
│   ├── join-workers.yml
│   ├── install-addons.yml
│   └── monitoring.yml
└── files/
    ├── manifests/
    └── configs/
```

## Tâches

### Phase 1 : Préparation (1h)

#### 1. Créer l'inventaire

**`inventory/production`** :
```ini
[master]
k8s-master ansible_host=192.168.1.10

[workers]
k8s-worker1 ansible_host=192.168.1.11
k8s-worker2 ansible_host=192.168.1.12

[k8s:children]
master
workers
```

#### 2. Définir les variables globales

**`group_vars/all.yml`** :
```yaml
---
# Version Kubernetes
kubernetes_version: "1.28"
kubernetes_version_full: "1.28.0-00"

# Container Runtime
container_runtime: containerd
containerd_version: "1.7.2"

# Réseau
pod_network_cidr: "10.244.0.0/16"
service_cidr: "10.96.0.0/12"

# Calico
calico_version: "v3.26.1"
calico_manifest_url: "https://raw.githubusercontent.com/projectcalico/calico/{{ calico_version }}/manifests/calico.yaml"

# Système
timezone: "Europe/Paris"
disable_swap: true
```

**`group_vars/master.yml`** :
```yaml
---
# Configuration master
kubeadm_init_extra_args: "--upload-certs"

# Dashboard
k8s_dashboard_enabled: true

# Monitoring
monitoring_enabled: true
```

### Phase 2 : Rôle Common (30 min)

Créer un rôle `common` pour préparer tous les nodes :

**`roles/common/tasks/main.yml`** :
```yaml
---
- name: Update system packages
  apt:
    update_cache: yes
    upgrade: dist

- name: Install required packages
  apt:
    name:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
      - software-properties-common
    state: present

- name: Disable swap (Kubernetes requirement)
  shell: |
    swapoff -a
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
  when: disable_swap

- name: Load kernel modules
  modprobe:
    name: "{{ item }}"
    state: present
  loop:
    - overlay
    - br_netfilter

- name: Configure sysctl for Kubernetes
  sysctl:
    name: "{{ item.key }}"
    value: "{{ item.value }}"
    state: present
    reload: yes
  loop:
    - { key: 'net.bridge.bridge-nf-call-iptables', value: '1' }
    - { key: 'net.bridge.bridge-nf-call-ip6tables', value: '1' }
    - { key: 'net.ipv4.ip_forward', value: '1' }

- name: Configure timezone
  timezone:
    name: "{{ timezone }}"
```

### Phase 3 : Rôle Containerd (30 min)

**`roles/containerd/tasks/main.yml`** :
```yaml
---
- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present

- name: Install containerd
  apt:
    name: containerd.io
    state: present
    update_cache: yes

- name: Create containerd config directory
  file:
    path: /etc/containerd
    state: directory
    mode: '0755'

- name: Generate default containerd config
  shell: containerd config default > /etc/containerd/config.toml

- name: Configure containerd to use systemd cgroup driver
  lineinfile:
    path: /etc/containerd/config.toml
    regexp: '            SystemdCgroup = false'
    line: '            SystemdCgroup = true'

- name: Restart containerd
  systemd:
    name: containerd
    state: restarted
    enabled: yes
    daemon_reload: yes
```

### Phase 4 : Rôle Kubernetes (30 min)

**`roles/kubernetes/tasks/main.yml`** :
```yaml
---
- name: Add Kubernetes GPG key
  apt_key:
    url: https://packages.cloud.google.com/apt/doc/apt-key.gpg
    state: present

- name: Add Kubernetes repository
  apt_repository:
    repo: "deb https://apt.kubernetes.io/ kubernetes-xenial main"
    state: present
    filename: kubernetes

- name: Install Kubernetes packages
  apt:
    name:
      - kubelet={{ kubernetes_version_full }}
      - kubeadm={{ kubernetes_version_full }}
      - kubectl={{ kubernetes_version_full }}
    state: present
    update_cache: yes

- name: Hold Kubernetes packages (prevent auto-upgrade)
  dpkg_selections:
    name: "{{ item }}"
    selection: hold
  loop:
    - kubelet
    - kubeadm
    - kubectl

- name: Enable kubelet service
  systemd:
    name: kubelet
    enabled: yes
```

### Phase 5 : Initialiser le Master (1h)

**`roles/master/tasks/main.yml`** :
```yaml
---
- name: Check if cluster is already initialized
  stat:
    path: /etc/kubernetes/admin.conf
  register: k8s_initialized

- name: Initialize Kubernetes cluster
  shell: |
    kubeadm init \
      --pod-network-cidr={{ pod_network_cidr }} \
      --service-cidr={{ service_cidr }} \
      --apiserver-advertise-address={{ ansible_default_ipv4.address }} \
      {{ kubeadm_init_extra_args | default('') }}
  when: not k8s_initialized.stat.exists
  register: kubeadm_init

- name: Create .kube directory
  file:
    path: "{{ ansible_env.HOME }}/.kube"
    state: directory
    mode: '0755'

- name: Copy admin.conf to user's kube config
  copy:
    src: /etc/kubernetes/admin.conf
    dest: "{{ ansible_env.HOME }}/.kube/config"
    remote_src: yes
    owner: "{{ ansible_user }}"
    group: "{{ ansible_user }}"
    mode: '0600'

- name: Generate join command
  shell: kubeadm token create --print-join-command
  register: join_command
  when: not k8s_initialized.stat.exists

- name: Save join command to file
  copy:
    content: "{{ join_command.stdout }}"
    dest: /tmp/k8s-join-command.sh
    mode: '0755'
  when: not k8s_initialized.stat.exists

- name: Fetch join command to control machine
  fetch:
    src: /tmp/k8s-join-command.sh
    dest: /tmp/k8s-join-command.sh
    flat: yes
  when: not k8s_initialized.stat.exists
```

### Phase 6 : Joindre les Workers (30 min)

**`roles/worker/tasks/main.yml`** :
```yaml
---
- name: Check if node is already joined
  stat:
    path: /etc/kubernetes/kubelet.conf
  register: node_joined

- name: Copy join command from control machine
  copy:
    src: /tmp/k8s-join-command.sh
    dest: /tmp/k8s-join-command.sh
    mode: '0755'
  when: not node_joined.stat.exists

- name: Join node to cluster
  shell: /tmp/k8s-join-command.sh
  when: not node_joined.stat.exists

- name: Remove join command file
  file:
    path: /tmp/k8s-join-command.sh
    state: absent
```

### Phase 7 : Installer Calico CNI (30 min)

**`roles/calico/tasks/main.yml`** :
```yaml
---
- name: Download Calico manifest
  get_url:
    url: "{{ calico_manifest_url }}"
    dest: /tmp/calico.yaml
    mode: '0644'

- name: Modify Calico CIDR if needed
  replace:
    path: /tmp/calico.yaml
    regexp: '192.168.0.0/16'
    replace: "{{ pod_network_cidr }}"

- name: Apply Calico CNI
  shell: kubectl apply -f /tmp/calico.yaml
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf

- name: Wait for Calico pods to be ready
  shell: kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf
  retries: 3
  delay: 10
```

### Phase 8 : Installer Ingress Nginx (30 min)

**`roles/ingress/tasks/main.yml`** :
```yaml
---
- name: Install Nginx Ingress Controller
  shell: |
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf

- name: Wait for Ingress Controller to be ready
  shell: kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf
```

### Phase 9 : Installer MetalLB (30 min)

**`roles/metallb/tasks/main.yml`** :
```yaml
---
- name: Install MetalLB
  shell: |
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf

- name: Create MetalLB IP address pool
  copy:
    content: |
      apiVersion: metallb.io/v1beta1
      kind: IPAddressPool
      metadata:
        name: default-pool
        namespace: metallb-system
      spec:
        addresses:
        - 192.168.1.100-192.168.1.110
      ---
      apiVersion: metallb.io/v1beta1
      kind: L2Advertisement
      metadata:
        name: default
        namespace: metallb-system
    dest: /tmp/metallb-config.yaml

- name: Apply MetalLB configuration
  shell: kubectl apply -f /tmp/metallb-config.yaml
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf
```

### Phase 10 : Dashboard et Monitoring (1h)

**`roles/dashboard/tasks/main.yml`** :
```yaml
---
- name: Install Kubernetes Dashboard
  shell: |
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf

- name: Create admin service account
  copy:
    content: |
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: admin-user
        namespace: kubernetes-dashboard
      ---
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRoleBinding
      metadata:
        name: admin-user
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: ClusterRole
        name: cluster-admin
      subjects:
      - kind: ServiceAccount
        name: admin-user
        namespace: kubernetes-dashboard
    dest: /tmp/dashboard-admin.yaml

- name: Apply admin service account
  shell: kubectl apply -f /tmp/dashboard-admin.yaml
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf
```

**`roles/monitoring/tasks/main.yml`** :
```yaml
---
- name: Clone kube-prometheus
  git:
    repo: 'https://github.com/prometheus-operator/kube-prometheus.git'
    dest: /tmp/kube-prometheus
    version: release-0.12

- name: Create monitoring namespace and CRDs
  shell: kubectl apply --server-side -f /tmp/kube-prometheus/manifests/setup
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf

- name: Wait for CRDs to be ready
  pause:
    seconds: 30

- name: Install Prometheus and Grafana
  shell: kubectl apply -f /tmp/kube-prometheus/manifests/
  environment:
    KUBECONFIG: /etc/kubernetes/admin.conf
```

### Phase 11 : Playbook Principal (30 min)

**`playbooks/site.yml`** :
```yaml
---
# Préparation de tous les nodes
- name: Prepare all nodes
  hosts: k8s
  become: yes
  roles:
    - common
    - containerd
    - kubernetes

# Initialiser le master
- name: Initialize Kubernetes master
  hosts: master
  become: yes
  roles:
    - master
    - calico

# Joindre les workers
- name: Join worker nodes to cluster
  hosts: workers
  become: yes
  roles:
    - worker

# Installer les add-ons
- name: Install cluster add-ons
  hosts: master
  become: yes
  roles:
    - ingress
    - metallb
    - dashboard
    - monitoring
  when: monitoring_enabled
```

### Phase 12 : Tests et Validation (30 min)

#### 1. Vérifier la syntaxe
```bash
ansible-playbook playbooks/site.yml --syntax-check
```

#### 2. Dry-run
```bash
ansible-playbook playbooks/site.yml --check
```

#### 3. Déployer le cluster
```bash
ansible-playbook playbooks/site.yml
```

#### 4. Vérifier le cluster
```bash
# Sur le master
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info

# Vérifier Calico
kubectl get pods -n kube-system | grep calico

# Vérifier Ingress
kubectl get pods -n ingress-nginx

# Vérifier MetalLB
kubectl get pods -n metallb-system

# Vérifier Monitoring
kubectl get pods -n monitoring
```

#### 5. Accéder au Dashboard
```bash
# Créer un token
kubectl -n kubernetes-dashboard create token admin-user

# Port-forward
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443

# Accéder à https://localhost:8443
```

#### 6. Accéder à Grafana
```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Accéder à http://localhost:3000
# User: admin, Password: admin (changé au premier login)
```

## Application de Test

**`test-app.yaml`** :
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

Déployer :
```bash
kubectl apply -f test-app.yaml

# Vérifier
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get ingress

# Tester
curl http://<EXTERNAL-IP>
```

## Livrables

- ✅ Cluster Kubernetes 3 nodes (1 master + 2 workers)
- ✅ Calico CNI configuré
- ✅ Nginx Ingress Controller opérationnel
- ✅ MetalLB pour LoadBalancer services
- ✅ Kubernetes Dashboard accessible
- ✅ Prometheus + Grafana pour monitoring
- ✅ Application de test déployée
- ✅ Playbooks idempotents
- ✅ Documentation complète

## Extensions possibles

1. **High Availability** :
   - 3 master nodes avec etcd cluster
   - HAProxy pour load balancer API server
   - Keepalived pour VIP

2. **Stockage** :
   - NFS ou Ceph pour PersistentVolumes
   - StorageClass avec provisioning dynamique
   - Velero pour backup/restore

3. **Sécurité** :
   - Pod Security Policies/Standards
   - Network Policies avec Calico
   - OPA (Open Policy Agent)
   - Falco pour runtime security

4. **Service Mesh** :
   - Istio ou Linkerd
   - Traffic management
   - mTLS entre services

5. **CI/CD** :
   - ArgoCD pour GitOps
   - Tekton Pipelines
   - Harbor pour registry privé

6. **Observabilité** :
   - ELK/EFK Stack pour logs
   - Jaeger pour tracing
   - Kiali pour service mesh observability

## Troubleshooting

### Problèmes courants

#### 1. Nodes pas prêts
```bash
# Vérifier kubelet
systemctl status kubelet
journalctl -xeu kubelet

# Vérifier CNI
kubectl get pods -n kube-system
kubectl logs -n kube-system <calico-pod>
```

#### 2. Pods en état Pending
```bash
# Vérifier les événements
kubectl describe pod <pod-name>

# Vérifier les ressources
kubectl top nodes
```

#### 3. Problèmes réseau
```bash
# Tester la connectivité
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash

# Vérifier DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

## Critères d'évaluation

- ✅ Cluster fonctionnel avec tous les nodes Ready (30%)
- ✅ Networking (Calico) opérationnel (15%)
- ✅ Ingress et LoadBalancer fonctionnels (15%)
- ✅ Monitoring configuré et accessible (10%)
- ✅ Application de test déployée (10%)
- ✅ Playbooks idempotents et bien structurés (10%)
- ✅ Documentation et tests (10%)

## Ressources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubeadm Installation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/)
- [Ingress Nginx](https://kubernetes.github.io/ingress-nginx/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Ansible Kubernetes Module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html)

---

**Durée estimée** : 6 heures

**Niveau** : Avancé
