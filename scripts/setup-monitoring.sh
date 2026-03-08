#!/bin/bash
set -e

# Setup Monitoring Stack: Prometheus + Grafana + Trivy ServiceMonitor
# This script automates the full monitoring setup for Trivy Operator vulnerability scanning

echo "=== Setting up Monitoring Stack ==="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. Create monitoring namespace
echo -e "${BLUE}[1/7] Creating monitoring namespace...${NC}"
kubectl create namespace monitoring 2>/dev/null || echo "Namespace already exists"

# 2. Add Helm repos
echo -e "${BLUE}[2/7] Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || echo "Repo already added"
helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || echo "Repo already added"
helm repo add aqua https://aquasecurity.github.io/helm-charts/ 2>/dev/null || echo "Repo already added"
helm repo update

# 3. Install kube-prometheus-stack (Prometheus + Grafana)
echo -e "${BLUE}[3/7] Installing Prometheus + Grafana stack...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helm upgrade --install prom prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f "${SCRIPT_DIR}/prometheus-values.yaml" \
  --wait \
  --timeout 5m

# 4. Wait for Grafana to be ready
echo -e "${BLUE}[4/7] Waiting for Grafana to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s 2>/dev/null || true

# 5. Enable Trivy ServiceMonitor
echo -e "${BLUE}[5/7] Enabling Trivy Operator ServiceMonitor...${NC}"
helm upgrade trivy-operator aqua/trivy-operator \
  -n trivy-system \
  -f "${SCRIPT_DIR}/trivy-values.yaml" \
  --wait \
  --timeout 5m

# 6. Verify Trivy ServiceMonitor created
echo -e "${BLUE}[6/7] Verifying ServiceMonitor...${NC}"
kubectl get servicemonitor -n trivy-system

# 7. Get Grafana credentials
echo -e "${BLUE}[7/7] Retrieving Grafana credentials...${NC}"
GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring prom-grafana -o jsonpath="{.data.admin-password}" | base64 -d)

echo ""
echo -e "${GREEN}=== Monitoring Stack Ready ===${NC}"
echo ""
echo "Grafana Credentials:"
echo "  Username: admin"
echo "  Password: ${GRAFANA_PASSWORD}"
echo ""
echo "Access Grafana:"
echo "  kubectl port-forward service/prom-grafana -n monitoring 3000:80"
echo "  Then open: http://localhost:3000"
echo ""
echo "Access Prometheus:"
echo "  kubectl port-forward service/prom-kube-prometheus-stack-prometheus -n monitoring 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "Import Trivy Dashboard in Grafana:"
echo "  1. Go to Dashboards → Browse → New → Import"
echo "  2. Enter Dashboard ID: 17813"
echo "  3. Select 'Prometheus' as data source"
echo "  4. Click Import"
echo ""
echo "Query Trivy Metrics in Prometheus:"
echo "  - Total vulnerabilities: sum(trivy_image_vulnerabilities)"
echo "  - Total misconfigurations: sum(trivy_resource_configaudits)"
echo "  - Exposed secrets: sum(trivy_image_exposedsecrets)"
echo ""
