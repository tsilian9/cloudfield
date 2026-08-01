# CloudField IoT Platform 🌾

**Cloud-Native Smart Agriculture Platform** – Παρακολούθηση υγρασίας εδάφους και αυτοματοποίηση ποτίσματος σε καλλιέργειες.

---

## 🏗️ Αρχιτεκτονική

```mermaid
graph TB
    subgraph "Data Collection"
        NR[Node-RED<br/>Sensor Simulator]
        WA[Open-Meteo<br/>Weather API]
    end

    subgraph "IoT Platform"
        TB[ThingsBoard<br/>Dashboard & Rule Engine]
        KC[Keycloak<br/>SSO / Identity Provider]
    end

    subgraph "Message Broker"
        RMQ[RabbitMQ<br/>valve.commands queue]
    end

    subgraph "Object Storage"
        MN[MinIO<br/>farm-images / farm-data]
    end

    subgraph "Serverless"
        KN[Knative<br/>image-analyzer]
    end

    subgraph "Observability"
        PR[Prometheus]
        GR[Grafana<br/>Dashboard + Alerts]
    end

    subgraph "CI/CD & GitOps"
        JK[Jenkins<br/>Build Pipeline]
        AR[ArgoCD<br/>GitOps Sync]
        GH[GitHub<br/>cloudfield repo]
    end

    subgraph "IaC"
        OT[OpenTofu<br/>Secrets + Buckets + Keycloak]
        AN[Ansible<br/>Automation Playbook]
    end

    NR -->|MQTT telemetry| TB
    NR -->|farm.humidity| RMQ
    NR -->|farm.tank| RMQ
    NR -->|PUT object| MN
    WA -->|weather data| NR
    TB -->|Rule Engine: OPEN_VALVE| RMQ
    TB <-->|OAuth2/OIDC SSO| KC
    MN <-->|OpenID Connect SSO| KC
    RMQ -->|valve.commands| NR
    MN -->|S3 Event Notification| KN
    PR -->|scrape metrics| RMQ
    PR -->|scrape metrics| NR
    GR -->|query| PR
    JK -->|build + push image| GH
    AR -->|sync YAMLs| GH
    OT -->|provision| KC
    OT -->|provision| MN
    AN -->|kubectl apply| AR
```

---

## 🌐 Service URLs

| Υπηρεσία | URL | Credentials |
|----------|-----|-------------|
| Node-RED | http://nodered.172.31.76.79.nip.io | - |
| ThingsBoard | http://thingsboard.172.31.76.79.nip.io | sysadmin@thingsboard.org / sysadmin |
| RabbitMQ | http://rabbitmq.172.31.76.79.nip.io | guest / guest |
| MinIO | http://minio.172.31.76.79.nip.io | minioadmin / minioadmin |
| Keycloak | http://keycloak.172.31.76.79.nip.io | admin / admin |
| Grafana | http://grafana.172.31.76.79.nip.io | admin / prom-operator |
| ArgoCD | http://argocd.172.31.76.79.nip.io | admin / (kubectl get secret) |
| Jenkins | http://jenkins.172.31.76.79.nip.io | admin / (kubectl get secret) |
| Image Analyzer | http://image-analyzer.default.172.31.76.79.nip.io | - |

---

## 📦 Υπηρεσίες & Τεχνολογίες

| Υπηρεσία | Τεχνολογία | Namespace | Σκοπός |
|----------|-----------|-----------|--------|
| Node-RED | Kubernetes Deployment | default | Προσομοίωση αισθητήρων, MQTT, AMQP flows |
| ThingsBoard | Kubernetes Deployment | default | IoT Dashboard, Rule Engine, Alarms |
| RabbitMQ | Kubernetes Deployment | default | Message broker για valve commands |
| MinIO | Kubernetes Deployment | default | Object storage για εικόνες καμερών |
| Keycloak | Kubernetes Deployment | default | SSO για ThingsBoard + MinIO |
| Image Analyzer | Knative Service | default | Serverless image metadata extraction |
| Jenkins | Kubernetes Deployment | default | CI/CD pipeline |
| ArgoCD | Kubernetes Deployment | argocd | GitOps continuous deployment |
| Prometheus | Helm (kube-prom-stack) | observability | Metrics collection |
| Grafana | Helm (kube-prom-stack) | observability | Dashboards + Alerts |

---

## 🔄 End-to-End Flow

```
1. Node-RED (κάθε 30s):
   - Παράγει τυχαία τιμή υγρασίας (20-80%)
   - Τραβάει καιρό από Open-Meteo API
   - Στέλνει telemetry μέσω MQTT στο ThingsBoard
   - Στέλνει farm.humidity + farm.tank στο RabbitMQ

2. ThingsBoard Rule Engine:
   - IF υγρασία < 30% AND δεν βρέχει → OPEN_VALVE_1
   - Στέλνει RPC command στο Node-RED
   - Δημιουργεί Alarm

3. Node-RED (Valve Controller):
   - Λαμβάνει RPC από ThingsBoard
   - Function 4 (Idempotency Check): αποτρέπει διπλές εντολές
   - Στέλνει εντολή στο RabbitMQ (valve.commands queue)

4. MinIO:
   - Node-RED ανεβάζει mock εικόνες κάθε 60s
   - S3 Event Notification → Knative image-analyzer
   - Lifecycle Policy: αυτόματη διαγραφή μετά 90 ημέρες

5. Keycloak SSO:
   - Single Sign-On για ThingsBoard + MinIO
   - Realm: cloudfield
   - Clients: thingsboard-client, minio-client

6. Monitoring:
   - Prometheus scrape-άρει RabbitMQ metrics
   - Grafana Dashboard: Queue Depth, Connections, CPU/Memory
   - Alert: queue_messages > 10 → Critical
```

---

## 🚀 Εγκατάσταση

### Προαπαιτούμενα
- MicroK8s με addons: `dns`, `ingress`, `storage`, `observability`, `knative`
- kubectl configured
- Docker Hub account

### 1. Clone repo
```bash
git clone https://github.com/tsilian9/cloudfield.git
cd cloudfield
```

### 2. Deploy με Ansible
```bash
cd ansible
ansible-playbook playbook.yml
```

### 3. Deploy με kubectl (manual)
```bash
kubectl apply -f rabbitmq.yaml
kubectl apply -f minio.yaml
kubectl apply -f nodered.yaml
kubectl apply -f thingsboard.yaml
kubectl apply -f keycloak.yaml
kubectl apply -f jenkins.yaml
kubectl apply -f argocd.yaml
kubectl apply -f monitoring.yaml
kubectl apply -f knative-service.yaml
kubectl apply -f nodered-flow.yaml
kubectl apply -f grafana-alert.yaml
```

### 4. OpenTofu (IaC)
```bash
cd opentofu
tofu init
tofu apply
```

### 5. Επαλήθευση
```bash
kubectl get pods
kubectl get ingress
```

---

## 📊 SLA Classes

| Class | Latency (p95) | Availability | Υπηρεσίες |
|-------|--------------|--------------|-----------|
| 🥇 **Gold** | < 100ms | 99.9% | RabbitMQ (99ms), MinIO (98ms), Node-RED (92ms) |
| 🥈 **Silver** | < 5s | 99.5% | Knative warm start (2.8s), ThingsBoard, Keycloak |
| 🥉 **Bronze** | < 30s | 99.0% | Knative cold start (6.7s), Jenkins builds |

Δες αναλυτικά: [sla-report.md](sla-report.md)

---

## 🔒 Idempotency Pattern (Φάση H)

Το **function 4** στο Node-RED Valve Controller υλοποιεί idempotency:
- **5-second window**: Αν η ίδια εντολή σταλεί 2 φορές μέσα σε 5s → SKIP
- **Flow context**: Αποθηκεύει `lastValveCommand` + `lastValveCommandTime`
- **Αποτέλεσμα**: Αποτρέπει διπλές εντολές στη `valve.commands` queue

---

## 📁 Δομή Project

```
cloudfield/
├── rabbitmq.yaml          # RabbitMQ Deployment + Service + Ingress
├── minio.yaml             # MinIO Deployment + Service + Ingress
├── nodered.yaml           # Node-RED Deployment + Service + Ingress
├── thingsboard.yaml       # ThingsBoard Deployment + Service + Ingress
├── keycloak.yaml          # Keycloak Deployment + Service + Ingress
├── jenkins.yaml           # Jenkins Deployment + Service + Ingress
├── argocd.yaml            # ArgoCD Application
├── monitoring.yaml        # ServiceMonitor για RabbitMQ
├── knative-service.yaml   # Knative Service (image-analyzer)
├── nodered-flow.yaml      # Node-RED flows ConfigMap
├── nodered-configmap.yaml # Node-RED settings ConfigMap
├── grafana-dashboard.json # Grafana Dashboard JSON
├── grafana-alert.yaml     # PrometheusRule (alerts)
├── flows.json             # Node-RED flows (local dev)
├── Dockerfile             # Custom Node-RED image
├── Dockerfile.jenkins     # Custom Jenkins image
├── Jenkinsfile            # Jenkins Pipeline
├── docker-compose.yml     # Local development
├── sla-measure.sh         # SLA measurement script
├── sla-report.md          # SLA report με πραγματικές μετρήσεις
├── sla-results.txt        # Raw measurement results
├── ansible/
│   ├── inventory.ini      # Ansible inventory
│   └── playbook.yml       # Ansible playbook
├── opentofu/
│   ├── main.tf            # OpenTofu resources
│   ├── variables.tf       # Variables
│   ├── outputs.tf         # Outputs
│   └── providers.tf       # Providers (K8s, MinIO, Keycloak)
└── knative/
    └── image-analyzer/
        ├── app.py         # Flask image analyzer
        ├── Dockerfile     # Container image
        └── requirements.txt
```

---

## 🔑 Keycloak SSO Integration

### Realm: `cloudfield`
- **ThingsBoard Client**: OAuth2/OIDC integration
  - Client ID: `thingsboard-client`
  - Redirect URI: `http://thingsboard.172.31.76.79.nip.io/*`
- **MinIO Client**: OpenID Connect integration
  - Client ID: `minio-client`
  - Redirect URI: `http://minio.172.31.76.79.nip.io/*`

### Users
| Username | Role | Πρόσβαση |
|----------|------|---------|
| admin | TENANT_ADMIN | ThingsBoard + MinIO |
| farm-operator | CUSTOMER_USER | ThingsBoard dashboard only |

---

## 📈 Grafana Monitoring

**Dashboard**: CloudField IoT Dashboard  
**URL**: http://grafana.172.31.76.79.nip.io/d/cloudfield-iot-v1

### Panels:
- 🐰 **RabbitMQ Connections** (current: 4)
- 📊 **Queue Depth** – valve.commands
- 📈 **Message Rate** – publish/deliver
- 💻 **CPU Usage** – all CloudField pods
- 🧠 **Memory Usage** – all CloudField pods

### Alerts (PrometheusRule):
| Alert | Condition | Severity |
|-------|-----------|----------|
| RabbitMQQueueDepthHigh | messages > 10 for 1m | 🔴 Critical |
| RabbitMQQueueDepthWarning | messages > 5 for 2m | 🟡 Warning |
| RabbitMQDown | up == 0 for 1m | 🔴 Critical |
| TelemetryRateZero | publish_rate == 0 for 5m | 🟡 Warning |

---

## 🛠️ CI/CD Pipeline (Jenkins + ArgoCD)

```
Developer → git push → GitHub
                          ↓
                      Jenkins (Webhook)
                          ↓
                    Build Docker Image
                          ↓
                    Push to Docker Hub
                          ↓
                      ArgoCD (GitOps)
                          ↓
                    kubectl apply → MicroK8s
```

---

*CloudField IoT Platform v1.0 | 2026-08-01*  
*Περιβάλλον: MicroK8s on Ubuntu VM (172.31.76.79)*
