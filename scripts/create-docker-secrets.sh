#!/bin/bash
set -e

# Create Docker Hub image pull secrets in Kubernetes
# Usage: ./scripts/create-docker-secrets.sh <docker-username> <docker-pat>

DOCKER_USERNAME="${1:-}"
DOCKER_PAT="${2:-}"

if [[ -z "$DOCKER_USERNAME" || -z "$DOCKER_PAT" ]]; then
  echo "Usage: $0 <docker-username> <docker-pat>"
  echo ""
  echo "Creates Docker Hub image pull secrets in default, trivy-system, and argocd namespaces"
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

echo "=== Creating Docker Hub Secrets ==="
echo ""
echo "Username: $DOCKER_USERNAME"
echo "PAT: ${DOCKER_PAT:0:20}..."
echo ""

# Create namespaces if they don't exist
echo "[0/4] Creating namespaces..."
kubectl create namespace default 2>/dev/null || true
kubectl create namespace trivy-system 2>/dev/null || true
kubectl create namespace argocd 2>/dev/null || true
echo ""

# Create secret in default namespace
echo "[1/4] Creating docker-registry secret in default namespace..."
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username="$DOCKER_USERNAME" \
  --docker-password="$DOCKER_PAT" \
  --docker-email=user@example.com \
  --namespace=default \
  2>/dev/null || echo "Secret already exists in default namespace"

# Create secret in trivy-system namespace
echo "[2/4] Creating docker-registry secret in trivy-system namespace..."
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username="$DOCKER_USERNAME" \
  --docker-password="$DOCKER_PAT" \
  --docker-email=user@example.com \
  --namespace=trivy-system \
  2>/dev/null || echo "Secret already exists in trivy-system namespace"

# Create ArgoCD repository credentials secret
echo "[3/4] Creating ArgoCD repo-creds secret in argocd namespace..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: docker-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repo-creds
type: Opaque
stringData:
  url: https://docker.io
  username: $DOCKER_USERNAME
  password: $DOCKER_PAT
EOF

echo ""
echo "=== Secrets Created ==="
echo ""
echo "Verify with:"
echo "  kubectl get secret dockerhub-secret -n default"
echo "  kubectl get secret dockerhub-secret -n trivy-system"
echo "  kubectl get secret docker-repo-creds -n argocd"
echo ""
echo "Delete pods to force image pull with new credentials:"
echo "  kubectl delete pod -n default -l app.kubernetes.io/component=frontend"
echo "  kubectl delete pod -n default -l app.kubernetes.io/component=backend"
echo ""
