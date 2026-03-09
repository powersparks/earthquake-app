#!/bin/bash

set -e

REPO_PATH="/Users/harleyparks/repos/local/earthquake-app"
CHARTS_YAML=(
  "helm/earthquake-app-chart/values.yaml"
  )
CHARTS=(
  "earthquake-app-chart"
  )
CLUSTER_TYPE="docker-desktop"  # Default: kind or docker-desktop
CLUSTER_NAME="earthquake-app-cluster"
TARGET_CONTEXT="docker-desktop" # Default docker-desktop or kind-$CLUSTER_NAME
NAMESPACE="default"
ARGOCD_NAMESPACE="argocd"

# Get repo name dynamically
get_repo_name() {
  cd "$REPO_PATH"  
  # Try to get repo name from git remote first
  local REPO_URL=$(git config --get remote.origin.url 2>/dev/null)
  
  if [[ -n "$REPO_URL" ]]; then
    echo $(basename "$REPO_URL" .git)
  else
    echo $(basename "$REPO_PATH")
  fi
}

# Initialize cluster name from repo name
REPO_NAME=$(get_repo_name)
CLUSTER_NAME="${REPO_NAME}"

echo "Using cluster name: $CLUSTER_NAME"
echo "Using repo name: $REPO_NAME"

usage() {
  echo "Usage: $0 {setup|teardown} [--type {kind|docker-desktop}]"
  echo "  setup    - Create cluster, install ArgoCD, deploy app"
  echo "  teardown - Delete cluster and all resources"
  echo ""
  echo "Options:"
  echo "  --type   - Cluster type: kind (default) or docker-desktop"
  echo ""
  echo "Examples:"
  echo "  $0 setup --type kind"
  echo "  $0 setup --type docker-desktop"
  echo "  $0 teardown --type kind"
  echo "  $0 teardown --type docker-desktop"
  exit 1
}

validate_context() {
  local TARGET_CONTEXT="$1"
  local CLUSTER_TYPE="$2"
  
  # Get current context
  local CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
  
  # If already on target context, we're good
  if [[ "$CURRENT_CONTEXT" == "$TARGET_CONTEXT" ]]; then
    echo "✓ Already on context: $TARGET_CONTEXT"
    return 0
  fi
  
  # Get list of available contexts
  local CONTEXTS=($(kubectl config get-contexts -o name 2>/dev/null))
  # If no contexts found, bail early
  if [[ ${#CONTEXTS[@]} -eq 0 ]]; then
    echo "Error: No kubectl contexts found"
    echo "Please check your kubeconfig or start Kubernetes"
    exit 1
  fi
  # Check if target context exists in list
  if [[ " ${CONTEXTS[@]} " =~ " ${TARGET_CONTEXT} " ]]; then
    echo "Switching to context: $TARGET_CONTEXT"
    kubectl config use-context "$TARGET_CONTEXT"
    return 0
  fi
  
  # Context not found - handle based on cluster type
  if [[ "$CLUSTER_TYPE" == "docker-desktop" ]]; then
    echo "Error: Context 'docker-desktop' not found"
    echo "Please start Docker Desktop and enable Kubernetes:"
    echo "  Settings → Kubernetes → Enable Kubernetes"
    echo "Then run the script again."
    exit 1
  elif [[ "$CLUSTER_TYPE" == "kind" ]]; then
    echo "Error: Context 'kind-${CLUSTER_NAME}' not found"
    echo "Please ensure kind cluster '$CLUSTER_NAME' is created."
    echo "You can create it manually with: kind create cluster --name $CLUSTER_NAME"
    exit 1
  else
    echo "Error: Invalid cluster type or configuration"
    exit 1
  fi
}

setup_kind() {
  echo "=== Setting up kind cluster ==="
  
  # Check if cluster exists
  if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo ""
    echo "Cluster '$CLUSTER_NAME' does not exist."
    read -p "Create it now? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "Creating kind cluster: $CLUSTER_NAME..."
      kind create cluster --name "$CLUSTER_NAME" --config ./kind-config.yaml 

    else
      echo "Aborted. Cluster creation cancelled."
      exit 1
    fi
  else
    echo "Cluster '$CLUSTER_NAME' already exists."
  fi
  
  # Validate and switch context
  validate_context "kind-${CLUSTER_NAME}" "kind"
  
  install_argocd
  deploy_app
  
  echo "=== Setup complete (kind) ==="
}

setup_docker_desktop() {
  echo "=== Setting up Docker Desktop Kubernetes ==="

  # Verify Kubernetes is running
  if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Docker Desktop Kubernetes is not running"
    echo "Enable it in Docker Desktop Settings → Kubernetes → Enable Kubernetes"
    exit 1
  fi
  # Validate and switch context
  validate_context "docker-desktop" "docker-desktop"
 
  install_argocd
  deploy_app
  
  echo "=== Setup complete (Docker Desktop) ==="
}

install_argocd() {
  echo "Installing ArgoCD..."
  kubectl create namespace "$ARGOCD_NAMESPACE" 2>/dev/null || true
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update
  helm install argocd argo/argo-cd -n "$ARGOCD_NAMESPACE" -f argocd-values.yaml 2>/dev/null || helm upgrade argocd argo/argo-cd -n "$ARGOCD_NAMESPACE" -f argocd-values.yaml
  
  # Wait for ArgoCD to be ready
  echo "Waiting for ArgoCD to be ready..."
  kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "$ARGOCD_NAMESPACE"
}

deploy_app() {
  # Apply ArgoCD Application CRD
  echo "Deploying application via ArgoCD..."
  kubectl apply -f argocd-app.yaml
  
  # Wait for app sync
  echo "Waiting for ArgoCD to sync..."
  sleep 10
  
  echo ""
  echo "Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
}

teardown_kind() {
  echo "=== Tearing down kind cluster ==="
  
  kind delete cluster --name "$CLUSTER_NAME"
  
  echo "=== Teardown complete (kind) ==="
}

teardown_docker_desktop() {
  echo "=== Tearing down Docker Desktop resources ==="
  
  # Switch context first
  echo "Switching kubectl context to docker-desktop..."
  kubectl config use-context docker-desktop
  
  echo "Uninstalling charts in default namespace..."
  for CHART in ${CHARTS[@]}; do
  helm uninstall $CHART 2>/dev/null || true
  done
  sleep 10
  kubectl delete all --all -n "$NAMESPACE" 2>/dev/null || true
  echo "Uninstall ARGOCD and delete argocd namespace..."
  helm uninstall argocd -n "$ARGOCD_NAMESPACE" 2>/dev/null || true
  kubectl delete namespace "$ARGOCD_NAMESPACE" 2>/dev/null || true

  echo "=== Teardown complete (Docker Desktop) ==="
}

# Parse arguments
if [ $# -eq 0 ]; then
  usage
fi

COMMAND="$1"
shift

# Parse optional --type argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      CLUSTER_TYPE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Validate cluster type
if [[ "$CLUSTER_TYPE" != "kind" && "$CLUSTER_TYPE" != "docker-desktop" ]]; then
  echo "Error: Invalid cluster type '$CLUSTER_TYPE'"
  echo "Valid options: kind, docker-desktop"
  exit 1
fi

case "$COMMAND" in
  setup)
    if [[ "$CLUSTER_TYPE" == "kind" ]]; then
      setup_kind
    else
      setup_docker_desktop
    fi
    ;;
  teardown)
    if [[ "$CLUSTER_TYPE" == "kind" ]]; then
      teardown_kind
    else
      teardown_docker_desktop
    fi
    ;;
  *)
    usage
    ;;
esac
