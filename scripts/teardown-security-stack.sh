#!/bin/bash
set -e

# Teardown Security Stack: Trivy + Prometheus + Grafana

echo "=== Tearing Down Security Stack ==="

# Confirm before deletion
read -p "This will delete monitoring, trivy-system namespaces. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

# 1. Uninstall Helm releases
echo "[1/3] Uninstalling Helm releases..."
helm uninstall prom -n monitoring 2>/dev/null || echo "Prometheus not found"
helm uninstall trivy-operator -n trivy-system 2>/dev/null || echo "Trivy Operator not found"
kubectl delete all --all -n monitoring --force
kubectl delete all --all -n trivy-system --force

# 2. Delete namespaces
echo "[2/3] Deleting namespaces..."
kubectl delete namespace monitoring 2>/dev/null || echo "Namespace not found"
kubectl delete namespace trivy-system 2>/dev/null || echo "Namespace not found"

# 3. Verify
echo "[3/3] Verifying cleanup..."
kubectl get namespace | grep -E "monitoring|trivy" && echo "Warning: Some namespaces still exist" || echo "Cleanup verified"

echo ""
echo "=== Security Stack Removed ==="
