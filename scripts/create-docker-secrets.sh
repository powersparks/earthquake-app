#!/bin/bash
set -e

# Create Docker Hub image pull secrets in Kubernetes
# Usage: ./scripts/create-docker-secrets.sh <docker-username> <docker-pat>

DOCKER_USERNAME="${1:-}"
DOCKER_PAT="${2:-}"

if [[ -z "$DOCKER_USERNAME" || -z "$DOCKER_PAT" ]]; then
  echo "Usage: $0 <docker-username> <docker-pat>"
  echo ""
  echo "Creates Docker Hub image pull secrets in both default and trivy-system namespaces"
  echo ""
  echo "Arguments:"
  echo "  docker-username  - Docker Hub username (e.g., parksharley11873)"
  echo "  docker-pat       - Docker Hub Personal Access Token"
  echo ""
  echo "Example:"
  echo "  $0 parksharley11873 dckr_pat_XXXXX"
  echo ""
  echo "To create a PAT:"
  echo "  1. Go to https://hub.docker.com"
  echo "  2. Account Settings → Security → Personal Access Tokens"
  echo "  3. Generate New Token (read-only is fine)"
  echo "  4. Copy the token"
  exit 1
fi

echo "=== Creating Docker Hub Image Pull Secrets ==="
echo ""
echo "Username: $DOCKER_USERNAME"
echo "PAT: ${DOCKER_PAT:0:20}..."
echo ""

# Create secret in default namespace
echo "[1/2] Creating secret in default namespace..."
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username="$DOCKER_USERNAME" \
  --docker-password="$DOCKER_PAT" \
  --docker-email=user@example.com \
  --namespace=default \
  2>/dev/null || echo "Secret already exists in default namespace"

# Create secret in trivy-system namespace
echo "[2/2] Creating secret in trivy-system namespace..."
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username="$DOCKER_USERNAME" \
  --docker-password="$DOCKER_PAT" \
  --docker-email=user@example.com \
  --namespace=trivy-system \
  2>/dev/null || echo "Secret already exists in trivy-system namespace"

echo ""
echo "=== Secrets Created ==="
echo ""
echo "Verify with:"
echo "  kubectl get secret dockerhub-secret -n default"
echo "  kubectl get secret dockerhub-secret -n trivy-system"
echo ""
echo "Delete pods to force image pull with new credentials:"
echo "  kubectl delete pod -n default -l app.kubernetes.io/component=frontend"
echo "  kubectl delete pod -n default -l app.kubernetes.io/component=backend"
echo ""
