#!/bin/bash
set -e

# Setup Security Stack: Trivy Operator + Prometheus + Grafana
# Run this AFTER cluster.sh setup to add security monitoring

echo "=== Setting up Security Stack (Trivy + Prometheus + Grafana) ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Create monitoring namespace
echo "[1/4] Creating monitoring namespace..."
kubectl create namespace monitoring 2>/dev/null || echo "Namespace already exists"

# 2. Install Prometheus + Grafana (provides ServiceMonitor CRD needed by Trivy)
#helm upgrade --install prom prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f "./prometheus-values.yaml" --wait  --timeout 5m
echo "[2/4] Installing Prometheus + Grafana..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
helm upgrade --install prom prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f "${SCRIPT_DIR}/prometheus-values.yaml" \
  --wait \
  --timeout 5m

# 3. Install Trivy Operator (now ServiceMonitor CRD is available)
# helm upgrade --install trivy-operator aqua/trivy-operator -n trivy-system --create-namespace -f "./trivy-values.yaml" --wait  --timeout 5m

echo "[3/4] Installing Trivy Operator..."
helm repo add aqua https://aquasecurity.github.io/helm-charts/ 2>/dev/null || true
helm repo update
helm upgrade --install trivy-operator aqua/trivy-operator \
  -n trivy-system \
  --create-namespace \
  -f "${SCRIPT_DIR}/trivy-values.yaml" \
  --wait \
  --timeout 5m

# 4. Get Grafana password
echo "[4/4] Retrieving credentials..."
GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring prom-grafana -o jsonpath="{.data.admin-password}" | base64 -d)

echo ""
echo "=== Security Stack Ready ==="
echo ""
echo "Grafana Access:"
echo "  kubectl port-forward service/prom-grafana -n monitoring 3000:80"
echo "  URL: http://localhost:3000"
echo "  Username: admin"
echo "  Password: ${GRAFANA_PASSWORD}"
echo ""
echo "Prometheus Access:"
echo "  kubectl port-forward service/prom-kube-prometheus-stack-prometheus -n monitoring 9090:9090"
echo "  URL: http://localhost:9090"
echo ""
echo "To import Trivy dashboard in Grafana:"
echo "  1. Dashboards → Browse → New → Import"
echo "  2. Enter ID: 17813"
echo "  3. Click Import"
echo ""
echo "Query Trivy metrics in Prometheus:"
echo "  sum(trivy_image_vulnerabilities)"
echo "  sum(trivy_resource_configaudits)"
echo "  sum(trivy_image_exposedsecrets)"
echo ""
