# Earthquake App - Complete Setup & Operations Guide

## Quick Start

### 1. **Docker Hub Image Push** (First Time Only)
Push images to Docker Hub for Trivy scanning:
```bash
# Build with explicit amd64 architecture (CRITICAL for Kubernetes scanning)
cd backend && docker build --platform linux/amd64 -t powersparks/earthquake-backend:latest . && docker push powersparks/earthquake-backend:latest
cd ../frontend && docker build --platform linux/amd64 -t powersparks/earthquake-frontend:latest . && docker push powersparks/earthquake-frontend:latest
```

**Why amd64?** Kubernetes clusters (even on Mac Docker Desktop) run amd64. Trivy Operator rejects arm64 images.

### 2. **Create Docker Hub Image Pull Secrets**
```bash
# Create Personal Access Token on Docker Hub (read-only)
# Then create Kubernetes secrets with the token:

kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=powersparks \
  --docker-password=dckr_pat_XXXXX \
  --docker-email=user@example.com \
  --namespace=default

kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=powersparks \
  --docker-password=dckr_pat_XXXXX \
  --docker-email=user@example.com \
  --namespace=trivy-system
```

### 3. **Deploy Full Stack with ArgoCD + Trivy + Monitoring**
```bash
# Use existing cluster.sh to set up Kubernetes + ArgoCD + Trivy
./scripts/cluster.sh setup docker-desktop

# Then enable monitoring:
chmod +x scripts/setup-monitoring.sh
./scripts/setup-monitoring.sh
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │  default ns      │  │  argocd ns       │                 │
│  ├──────────────────┤  ├──────────────────┤                 │
│  │ Backend Pod      │  │ ArgoCD Server    │                 │
│  │ Frontend Pod     │  │ ArgoCD Repo Svr  │                 │
│  │ PostgreSQL Pod   │  │ ArgoCD Controller│                 │
│  │ (Trivy scans)    │  │                  │                 │
│  └──────────────────┘  └──────────────────┘                 │
│         ↓                       ↓                            │
│  VulnerabilityReports    Watches local Git                   │
│                          /mnt/argocd-repo                    │
│  ┌────────────────────────────────────────┐                 │
│  │  trivy-system ns                       │                 │
│  ├────────────────────────────────────────┤                 │
│  │ Trivy Operator Pod                     │                 │
│  │ (Scans images, writes VulnReports)     │                 │
│  │ ServiceMonitor → Prometheus scrapes    │                 │
│  └────────────────────────────────────────┘                 │
│                                                             │
│  ┌────────────────────────────────────────┐                 │
│  │  monitoring ns                         │                 │
│  ├────────────────────────────────────────┤                 │
│  │ Prometheus (scrapes ServiceMonitor)    │                 │
│  │ Grafana (visualizes Prometheus data)   │                 │
│  │ AlertManager                           │                 │
│  └────────────────────────────────────────┘                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
         ↓                           ↓
    Docker Hub            Local Git Repo
   (earthquake images)    (/earthquake-app)
```

---

## Component Details

### 1. Earthquake App (default namespace)
- **Backend**: FastAPI on port 8000, fetches USGS earthquake data
- **Frontend**: Next.js on port 3000, displays D3.js timeline
- **Database**: PostgreSQL, persists earthquake data

**Deployment**: Via Helm chart (`helm/earthquake-app-chart/`) + ArgoCD GitOps

### 2. ArgoCD (argocd namespace)
- Watches local Git repo: `/mnt/argocd-repo` (volume mount in repo-server pod)
- Auto-syncs Helm chart changes
- No UI extension (mziyabo Trivy extension had structural bugs)

### 3. Trivy Operator (trivy-system namespace)
- Scans all pod images in cluster
- Creates `VulnerabilityReport` CRDs for each image
- Exports metrics via ServiceMonitor
- Uses Docker Hub credentials (imagePullSecrets) to access private/public images

### 4. Prometheus + Grafana (monitoring namespace)
- **Prometheus**: Scrapes Trivy ServiceMonitor every 30s, stores metrics
- **Grafana**: Visualizes Prometheus data, imports dashboard ID 17813 (Trivy Operator Dashboard)
- **Queries**: 
  - `sum(trivy_image_vulnerabilities)` — total vulns
  - `sum(trivy_resource_configaudits)` — misconfigurations
  - `sum(trivy_image_exposedsecrets)` — exposed secrets

---

## Common Operations

### Check Vulnerability Reports
```bash
# List all reports
kubectl get vulnerabilityreports -n default -o wide

# View specific report (YAML)
kubectl get vulnerabilityreport replicaset-57c4f4cb89 -n default -o yaml

# Export to JSON for analysis
kubectl get vulnerabilityreports -n default -o json > trivy-reports.json
```

### Access Grafana Dashboard
```bash
kubectl port-forward service/prom-grafana -n monitoring 3000:80
# Open http://localhost:3000
# Login: admin / <password from kubectl secret>
```

### Access Prometheus
```bash
kubectl port-forward service/prom-kube-prometheus-stack-prometheus -n monitoring 9090:9090
# Open http://localhost:9090
# Query: sum(trivy_image_vulnerabilities)
```

### Access ArgoCD UI
```bash
kubectl port-forward service/argocd-server -n argocd 8080:443
# Open http://localhost:8080
# Login: admin / <password from kubectl secret>
```

### Trigger Earthquake Data Refresh
```bash
# Frontend has /api/refresh endpoint
curl http://localhost:3000/api/refresh

# Or refresh via kubectl port-forward to backend
kubectl port-forward service/earthquake-app-earthquake-app-chart-backend default 8000:8000
curl http://localhost:8000/refresh
```

### Update & Redeploy via ArgoCD
1. Edit Helm chart in Git: `helm/earthquake-app-chart/values.yaml`
2. Commit: `git add . && git commit -m "..."`
3. ArgoCD auto-syncs within 3 minutes
4. Or manually sync: `argocd app sync earthquake-app --server localhost:8080`

---

## Troubleshooting

### Images not pulling / Trivy not scanning
- Check ServiceMonitor exists: `kubectl get servicemonitor -n trivy-system`
- Verify Prometheus scrapes Trivy: port-forward to Prometheus, go to Status → Targets, search "trivy-operator"
- Check Docker Hub secrets: `kubectl get secret dockerhub-secret -n default -o yaml`

### ArgoCD not syncing Git changes
- Restart repo-server: `kubectl rollout restart deployment -n argocd argocd-repo-server`
- Verify Git mount: `kubectl exec -n argocd <repo-server-pod> -- ls /mnt/argocd-repo`

### Earthquake backend won't start
- Check logs: `kubectl logs -n default <backend-pod>`
- Verify PostgreSQL is ready: `kubectl get pod -l component=postgres -n default`
- Check database credentials in secret: `kubectl get secret <app>-postgres-secret -n default -o yaml`

### Trivy scan stuck / no reports
- Check Trivy Operator logs: `kubectl logs -n trivy-system -l app.kubernetes.io/name=trivy-operator`
- Verify imagePullSecrets: `kubectl get pod -n trivy-system -l app=trivy-operator -o yaml | grep imagePullSecrets`
- Check cache lock: Restart Trivy Operator if "cache lock" errors persist

---

## Files & Structure

```
/Users/harleyparks/repos/local/earthquake-app/
├── backend/                              # FastAPI app
├── frontend/                             # Next.js app
├── helm/earthquake-app-chart/            # Helm chart for deployment
│   ├── values.yaml                       # Image refs, config
│   ├── templates/
│   │   ├── backend-deployment.yaml
│   │   ├── frontend-deployment.yaml
│   │   ├── postgres-statefulset.yaml
│   │   └── ...
│   └── Chart.yaml
├── scripts/
│   ├── cluster.sh                        # Main setup/teardown script
│   ├── setup-monitoring.sh               # Monitoring stack setup
│   └── teardown-monitoring.sh            # Monitoring stack teardown
├── argocd-app.yaml                       # ArgoCD Application CRD
├── argocd-values.yaml                    # ArgoCD Helm config (disabled extensions)
├── trivy-values.yaml                     # Trivy Operator Helm config (ServiceMonitor enabled)
├── prometheus-values.yaml                # Prometheus Helm config
└── .git/
    └── (local Git repo watched by ArgoCD)
```

---

## Next Steps

1. **Fix Frontend Vulnerabilities**
   - Node 18 has known CVEs → upgrade to Node 22 LTS
   - Update npm packages: `npm audit fix --force`
   - Rebuild with `--platform linux/amd64`

2. **GitHub Integration**
   - Push local repo to GitHub: `git remote add origin https://github.com/powersparks/earthquake-app.git && git push -u origin main`
   - Update ArgoCD to pull from GitHub instead of local mount
   - Enable GitHub Actions CI/CD for automated builds

3. **Production Hardening**
   - Add RBAC policies for Trivy Operator ServiceMonitor access
   - Set resource limits on all pods
   - Enable Pod Security Standards
   - Add ingress for Grafana/Prometheus behind auth

4. **Alerts & Policies**
   - Configure PrometheusRule for critical vulnerability alerts
   - Set Grafana alert thresholds
   - Add Slack/email notifications

---

## References

- Trivy Operator: https://aquasecurity.github.io/trivy-operator/
- Trivy Grafana Integration: https://aquasecurity.github.io/trivy-operator/v0.10.2/tutorials/grafana-dashboard/
- Kubernetes: https://kubernetes.io/docs/
- ArgoCD: https://argo-cd.readthedocs.io/
- Prometheus: https://prometheus.io/docs/
- Grafana: https://grafana.com/docs/
