# Helm Chart Best Practices & Procedure Guide

## Table of Contents

1. [Chart Structure](#chart-structure)
2. [Template Patterns](#template-patterns)
3. [Values Hierarchy](#values-hierarchy)
4. [Best Practices](#best-practices)
5. [Common Pitfalls & How We Fixed Them](#common-pitfalls--how-we-fixed-them)
6. [Procedure: Building a New Helm Chart](#procedure-building-a-new-helm-chart)
7. [Procedure: Extending Existing Chart](#procedure-extending-existing-chart)
8. [Testing & Validation](#testing--validation)

---

## Chart Structure

```
helm/earthquake-app-chart/
├── Chart.yaml                 # Chart metadata (name, version, description)
├── values.yaml               # Default configuration values
├── charts/                    # Dependency charts (if any)
├── templates/                # Kubernetes manifests (rendered with values)
│   ├── _helpers.tpl         # Template functions/macros (reusable helpers)
│   ├── NOTES.txt            # Post-install instructions
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   ├── postgres-statefulset.yaml
│   ├── postgres-service.yaml
│   ├── postgres-secret.yaml
│   ├── configmap.yaml
│   ├── serviceaccount.yaml
│   ├── ingress.yaml         # Optional: external access
│   ├── hpa.yaml             # Optional: auto-scaling
│   ├── httproute.yaml       # Optional: Gateway API
│   └── tests/               # Helm test definitions
└── .helmignore              # Files to exclude from chart package
```

**Key insight:** Chart is a **template engine**, not a deployment engine.
- `Chart.yaml` = metadata
- `values.yaml` = configuration variables
- `templates/` = Kubernetes YAML with placeholders
- **Helm merges them** to produce actual Kubernetes manifests

---

## Template Patterns

### **Pattern 1: Values-Driven Configuration (Preferred)**

**Use when:** Deployment varies by environment (dev, staging, prod)

```yaml
# values.yaml
backend:
  replicaCount: 1
  image:
    repository: parksharley11873/earthquake-backend
    tag: latest
    pullPolicy: IfNotPresent
```

```yaml
# templates/backend-deployment.yaml
replicas: {{ .Values.backend.replicaCount }}
image: "{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}"
imagePullPolicy: {{ .Values.backend.image.pullPolicy }}
```

**Override at deploy time:**
```bash
helm install app . --set backend.replicaCount=3 --set backend.image.tag=v1.2.3
```

**Advantage:** Same chart, different configs. No template changes.

---

### **Pattern 2: Hardcoded in Template (Only for Invariants)**

**Use when:** Value NEVER changes (hardening, security, infrastructure)

```yaml
# templates/backend-deployment.yaml
env:
- name: DATABASE_HOST
  value: "{{ include "earthquake-app-chart.fullname" . }}-postgres"  # Generated name, but pattern is fixed
- name: DATABASE_PORT
  value: "5432"  # Port is always 5432, won't change
```

**Avoid for:**
- Image versions
- Resource limits
- Replica counts
- Any environment-specific value

---

### **Pattern 3: Conditional Rendering**

**Use when:** Feature is optional

```yaml
# values.yaml
ingress:
  enabled: false
```

```yaml
# templates/ingress.yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "earthquake-app-chart.fullname" . }}
spec:
  # ... ingress config
{{- end }}
```

**Enable at deploy time:**
```bash
helm install app . --set ingress.enabled=true
```

---

### **Pattern 4: Helpers for Reusable Functions**

**Use when:** Same logic used in multiple templates

```yaml
# templates/_helpers.tpl
{{- define "earthquake-app-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
```

```yaml
# templates/backend-deployment.yaml
metadata:
  name: {{ include "earthquake-app-chart.fullname" . }}-backend
```

```yaml
# templates/frontend-deployment.yaml
metadata:
  name: {{ include "earthquake-app-chart.fullname" . }}-frontend
```

**Benefit:** Single source of truth for naming logic.

---

## Values Hierarchy

**Helm resolves values in this order (highest to lowest priority):**

1. **Command-line flags** `--set` (highest priority)
   ```bash
   helm install app . --set backend.image.tag=v2.0.0
   ```

2. **-f values file** (can pass multiple)
   ```bash
   helm install app . -f values-prod.yaml -f values-secrets.yaml
   ```

3. **values.yaml in chart** (default, lowest priority)

**Example:**
```bash
# Uses:
# 1. backend.image.tag=v1.2.3 (from --set)
# 2. backend.replicaCount=2 (from values-prod.yaml)
# 3. Everything else (from default values.yaml)
helm install app . \
  -f values-prod.yaml \
  --set backend.image.tag=v1.2.3
```

**Best practice:**
- `values.yaml` — defaults for local development
- `values-dev.yaml` — dev environment overrides
- `values-prod.yaml` — prod environment overrides
- `--set` — runtime tweaks (don't commit these)

---

## Best Practices

### **1. Values Should Be Configurable**

❌ **Bad:**
```yaml
# templates/backend-deployment.yaml
replicas: 1  # Hardcoded!
```

✅ **Good:**
```yaml
# values.yaml
backend:
  replicaCount: 1

# templates/backend-deployment.yaml
replicas: {{ .Values.backend.replicaCount }}
```

**Why:** Dev/staging/prod need different replicas.

---

### **2. Use Naming Helpers for Consistency**

❌ **Bad:**
```yaml
# templates/backend-deployment.yaml
metadata:
  name: backend  # Conflicts with other deployments!

# templates/frontend-deployment.yaml
metadata:
  name: frontend  # Same issue
```

✅ **Good:**
```yaml
# templates/backend-deployment.yaml
metadata:
  name: {{ include "earthquake-app-chart.fullname" . }}-backend

# templates/frontend-deployment.yaml
metadata:
  name: {{ include "earthquake-app-chart.fullname" . }}-frontend
```

**Why:** Names must be unique. Helpers prevent conflicts.

---

### **3. Use Labels & Selectors Consistently**

```yaml
# templates/_helpers.tpl
{{- define "earthquake-app-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "earthquake-app-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

# templates/backend-deployment.yaml
labels:
  {{- include "earthquake-app-chart.labels" . | nindent 4 }}
  app.kubernetes.io/component: backend
selector:
  matchLabels:
    {{- include "earthquake-app-chart.selectorLabels" . | nindent 6 }}
    app.kubernetes.io/component: backend
```

**Why:** Consistent labels allow easy filtering/management.

---

### **4. Document Configuration in values.yaml**

```yaml
# values.yaml

# Backend configuration
# - Handles USGS API calls and database operations
# - Requires DATABASE_HOST env var (set from postgres service)
# - Must have imagePullSecrets for Docker Hub access
backend:
  enabled: true                    # Set to false to disable
  replicaCount: 1                  # Number of replicas (use HPA for auto-scaling)
  image:
    repository: parksharley11873/earthquake-backend
    tag: "latest"                  # Use specific version in production
    pullPolicy: IfNotPresent      # IfNotPresent avoids rate limiting
  service:
    type: ClusterIP                # Internal-only access
    port: 8000                     # API port (must match backend config)
```

---

### **5. Separate Concerns by Component**

```
templates/
├── backend-deployment.yaml   # Backend-specific
├── backend-service.yaml
├── frontend-deployment.yaml  # Frontend-specific
├── frontend-service.yaml
├── postgres-statefulset.yaml # Database-specific
├── postgres-service.yaml
├── postgres-secret.yaml
├── configmap.yaml            # Shared configuration
├── serviceaccount.yaml       # Shared RBAC
└── _helpers.tpl             # Shared helpers
```

**Why:** Easy to find, modify, or remove components.

---

### **6. Use Secrets for Sensitive Data**

```yaml
# templates/postgres-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "earthquake-app-chart.fullname" . }}-postgres-secret
type: Opaque
data:
  username: {{ .Values.postgresql.username | b64enc | quote }}
  password: {{ .Values.postgresql.password | b64enc | quote }}
```

**Never commit passwords** to values.yaml. Instead:
```bash
helm install app . \
  --set postgresql.password=$(openssl rand -base64 32)
```

Or use external secret management (Vault, AWS Secrets Manager).

---

### **7. Use ImagePullSecrets for Private Registries**

```yaml
# values.yaml
imagePullSecrets:
  - name: dockerhub-secret

# templates/backend-deployment.yaml
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 8 }}
{{- end }}
```

**Create secret first:**
```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=user \
  --docker-password=token
```

---

## Common Pitfalls & How We Fixed Them

### **Pitfall 1: Default Deployments Conflict with Custom Manifests**

**Problem:**
```
We created deployment.yaml manually, then helm init created deployment.yaml template.
Both tried to deploy the same thing → naming conflicts!
```

**Solution:**
- ✅ Remove old default templates created by `helm create`
- ✅ Organize templates by component (backend-deployment.yaml, frontend-deployment.yaml, etc.)
- ✅ Use naming helpers to avoid collisions

```bash
# Clean up old/unused templates
rm templates/deployment.yaml  # If you have component-specific versions
rm templates/service.yaml     # If you have component-specific versions
```

---

### **Pitfall 2: Values Hardcoded in Templates**

**Problem:**
```yaml
# templates/backend-deployment.yaml
replicas: 1      # Can't scale!
image: parksharley11873/earthquake-backend:latest  # Can't version!
```

**Solution:**
- ✅ Move ALL configurable values to `values.yaml`
- ✅ Reference via `{{ .Values.path.to.value }}`
- ✅ Use `--set` to override at deploy time

```yaml
# values.yaml
backend:
  replicaCount: 1
  image:
    repository: parksharley11873/earthquake-backend
    tag: latest
    pullPolicy: IfNotPresent
```

---

### **Pitfall 3: Docker Registry Not Configured**

**Problem:**
```
Pods fail with ImagePullBackOff → can't pull from Docker Hub without credentials
```

**Solution:**
- ✅ Create docker-registry secret
- ✅ Reference in `imagePullSecrets` in values.yaml
- ✅ Apply secret to all namespaces that need it

```bash
# Create secret
./scripts/create-docker-secrets.sh parksharley11873 dckr_pat_XXXXX

# Already in values.yaml
imagePullSecrets:
  - name: dockerhub-secret
```

---

### **Pitfall 4: Environment Variables Not Consistent**

**Problem:**
```
Backend expects DATABASE_HOST, but service is named differently
Database password hardcoded in ConfigMap instead of Secret
```

**Solution:**
- ✅ Use naming helpers for predictable service names
- ✅ Pass env vars from Secrets/ConfigMaps, not hardcoded
- ✅ Document expected env vars in README

```yaml
# templates/backend-deployment.yaml
env:
- name: DATABASE_HOST
  value: "{{ include "earthquake-app-chart.fullname" . }}-postgres"  # Predictable!
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "earthquake-app-chart.fullname" . }}-postgres-secret
      key: password  # From Secret, not ConfigMap
```

---

### **Pitfall 5: No Way to Customize for Different Environments**

**Problem:**
```
Same chart can't scale from 1 replica (dev) to 10 replicas (prod)
```

**Solution:**
- ✅ Create environment-specific values files
- ✅ Use `-f` to layer configs at deploy time
- ✅ Use `--set` for runtime overrides

```bash
# Development
helm install app . -f values-dev.yaml

# Production
helm install app . -f values-prod.yaml --set backend.replicaCount=10

# One-off override
helm install app . --set frontend.image.tag=v2.0.0
```

**values-dev.yaml:**
```yaml
backend:
  replicaCount: 1
postgresql:
  persistence:
    size: 5Gi
```

**values-prod.yaml:**
```yaml
backend:
  replicaCount: 5
postgresql:
  persistence:
    size: 100Gi
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
```

---

## Procedure: Building a New Helm Chart

### **Step 1: Initialize**
```bash
helm create earthquake-app-chart
cd earthquake-app-chart
```

### **Step 2: Update Chart Metadata**
```yaml
# Chart.yaml
apiVersion: v2
name: earthquake-app-chart
description: USGS Earthquake Data Pipeline
type: application
version: 0.1.0
appVersion: "1.0.0"
```

### **Step 3: Define Values**
```yaml
# values.yaml
# Global
replicaCount: 1
nameOverride: ""
fullnameOverride: ""

# Component: Backend
backend:
  enabled: true
  replicaCount: 1
  image:
    repository: earthquake-backend
    tag: latest
    pullPolicy: IfNotPresent
  service:
    type: ClusterIP
    port: 8000

# Component: Frontend
frontend:
  enabled: true
  image:
    repository: earthquake-frontend
    tag: latest
    pullPolicy: IfNotPresent
  service:
    type: NodePort
    port: 3000

# Component: Database
postgresql:
  enabled: true
  image:
    repository: postgres
    tag: "16-alpine"
    pullPolicy: IfNotPresent
  database: earthquake_db
  username: postgres
  password: postgres  # NEVER in prod, use --set

# Shared
imagePullSecrets: []
serviceAccount:
  create: true
  name: ""
```

### **Step 4: Create Component Templates**

**templates/backend-deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "earthquake-app-chart.fullname" . }}-backend
  labels:
    {{- include "earthquake-app-chart.labels" . | nindent 4 }}
    app.kubernetes.io/component: backend
spec:
  replicas: {{ .Values.backend.replicaCount }}
  selector:
    matchLabels:
      {{- include "earthquake-app-chart.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: backend
  template:
    metadata:
      labels:
        {{- include "earthquake-app-chart.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: backend
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
      - name: backend
        image: "{{ .Values.backend.image.repository }}:{{ .Values.backend.image.tag }}"
        imagePullPolicy: {{ .Values.backend.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.backend.service.port }}
```

Repeat for: frontend, postgres, services, secrets, configmaps.

### **Step 5: Create Helpers**
```yaml
# templates/_helpers.tpl
{{- define "earthquake-app-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end }}
{{- end }}

{{- define "earthquake-app-chart.labels" -}}
helm.sh/chart: {{ include "earthquake-app-chart.chart" . }}
{{ include "earthquake-app-chart.selectorLabels" . }}
{{- end }}

{{- define "earthquake-app-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### **Step 6: Test**
```bash
# Validate syntax
helm lint .

# Dry-run to see what would be deployed
helm install app . --dry-run --debug

# Inspect rendered manifests
helm template app .
```

### **Step 7: Deploy**
```bash
helm install app . --namespace default

# Verify
helm status app
kubectl get all -n default
```

---

## Procedure: Extending Existing Chart

### **To Add a New Component (e.g., Redis Cache):**

1. **Add values to values.yaml**
   ```yaml
   redis:
     enabled: false
     image:
       repository: redis
       tag: "7-alpine"
     port: 6379
   ```

2. **Create template redis-deployment.yaml**
   ```yaml
   {{- if .Values.redis.enabled }}
   apiVersion: apps/v1
   kind: Deployment
   # ... redis config
   {{- end }}
   ```

3. **Create redis-service.yaml**
   ```yaml
   {{- if .Values.redis.enabled }}
   apiVersion: v1
   kind: Service
   # ... redis service
   {{- end }}
   ```

4. **Update backend env vars to use Redis**
   ```yaml
   # templates/backend-deployment.yaml
   env:
   {{- if .Values.redis.enabled }}
   - name: REDIS_HOST
     value: "{{ include "earthquake-app-chart.fullname" . }}-redis"
   {{- end }}
   ```

5. **Test & deploy**
   ```bash
   helm lint .
   helm install app . --set redis.enabled=true
   ```

---

### **To Change Image Version:**

```bash
helm upgrade app . --set backend.image.tag=v1.2.3 --set frontend.image.tag=v2.0.0
```

---

### **To Scale for Production:**

```bash
helm upgrade app . \
  -f values-prod.yaml \
  --set backend.replicaCount=10 \
  --set autoscaling.enabled=true \
  --set autoscaling.maxReplicas=20
```

---

## Testing & Validation

### **Lint (Syntax Check)**
```bash
helm lint .
# Checks for common mistakes in templates
```

### **Dry-Run (Preview What Would Deploy)**
```bash
helm install app . --dry-run --debug
# Shows rendered YAML without deploying
```

### **Template Rendering (See Final YAML)**
```bash
helm template app .
# Outputs all rendered manifests to stdout
```

### **Validate Kubernetes**
```bash
helm install app . --dry-run | kubectl apply --dry-run=client -f -
# Validates manifests against Kubernetes API
```

### **Debug Template Rendering**
```bash
helm template app . --values values-debug.yaml --debug
# Shows which values are being used
```

---

## Quick Reference: Common Commands

```bash
# Create new chart
helm create myapp

# Validate
helm lint myapp/

# Preview
helm template release-name myapp/
helm install release-name myapp/ --dry-run --debug

# Deploy
helm install release-name myapp/
helm install release-name myapp/ -f values-prod.yaml
helm install release-name myapp/ --set key=value

# Upgrade
helm upgrade release-name myapp/
helm upgrade release-name myapp/ --set key=value

# Check status
helm status release-name
helm list
helm history release-name

# Rollback
helm rollback release-name 1  # Rollback to revision 1

# Remove
helm uninstall release-name
```

---

## Key Takeaways

1. **Separate values from templates** — All config in values.yaml, all logic in templates/
2. **Use helpers for consistency** — Naming, labels, selectors
3. **Make everything configurable** — Avoid hardcoding
4. **Document configuration** — Comments in values.yaml
5. **Test before deploying** — Use `--dry-run` and `helm lint`
6. **Layer configs** — Use `-f` for environments, `--set` for runtime
7. **Use conditional rendering** — `{{- if .Values.enabled }}`
8. **Security first** — Secrets for sensitive data, not ConfigMaps
