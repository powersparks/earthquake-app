#!/bin/bash
set -e

# Teardown Monitoring Stack
# This script removes Prometheus, Grafana, and monitoring namespace

echo "=== Tearing Down Monitoring Stack ==="

# Colors for output
RED='\033[0;31m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Confirm before deletion
read -p "This will delete the monitoring namespace. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled."
  exit 0
fi

# 1. Delete Helm release
echo -e "${BLUE}[1/2] Uninstalling Prometheus + Grafana stack...${NC}"
helm uninstall prom -n monitoring 2>/dev/null || echo "Release not found"

# 2. Delete namespace (cascades to all resources)
echo -e "${BLUE}[2/2] Deleting monitoring namespace...${NC}"
kubectl delete namespace monitoring 2>/dev/null || echo "Namespace not found"

echo -e "${GREEN}=== Monitoring Stack Removed ===${NC}"
echo ""
echo "Note: Trivy Operator remains installed. To remove it:"
echo "  helm uninstall trivy-operator -n trivy-system"
echo "  kubectl delete namespace trivy-system"
