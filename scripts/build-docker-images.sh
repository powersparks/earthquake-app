#!/bin/bash
set -e

# Build and push Docker images to Docker Hub
# Usage: ./scripts/build-docker-images.sh <docker-username>

DOCKER_USERNAME="${1:-}"

if [[ -z "$DOCKER_USERNAME" ]]; then
  echo "Usage: $0 <docker-username>"
  echo ""
  echo "Examples:"
  echo "  $0 powersparks"
  echo " $0 parksharley11873"
  echo "  $0 mycompanyaccount"
  echo ""
  echo "This will build both backend and frontend images with --platform linux/amd64"
  echo "and push them to Docker Hub under your account."
  exit 1
fi

echo "=== Building Docker Images for $DOCKER_USERNAME ==="
echo ""

# Verify docker login
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker daemon not running"
  exit 1
fi

# Check if user is logged in (simple check)
if ! docker images > /dev/null 2>&1; then
  echo "Error: Cannot access Docker. Try running 'docker login' first."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

# Backend image
echo "[1/4] Building backend image..."
cd backend
echo "  Building: $DOCKER_USERNAME/earthquake-backend:latest (linux/amd64)"
docker build --platform linux/amd64 -t "$DOCKER_USERNAME/earthquake-backend:latest" .

echo "[2/4] Pushing backend image..."
docker push "$DOCKER_USERNAME/earthquake-backend:latest"
cd ..

# Frontend image
echo "[3/4] Building frontend image..."
cd frontend
echo "  Building: $DOCKER_USERNAME/earthquake-frontend:latest (linux/amd64)"
docker build --platform linux/amd64 -t "$DOCKER_USERNAME/earthquake-frontend:latest" .

echo "[4/4] Pushing frontend image..."
docker push "$DOCKER_USERNAME/earthquake-frontend:latest"
cd ..

echo ""
echo "=== Build Complete ==="
echo ""
echo "Images pushed to Docker Hub:"
echo "  - $DOCKER_USERNAME/earthquake-backend:latest"
echo "  - $DOCKER_USERNAME/earthquake-frontend:latest"
echo ""
echo "Next steps:"
echo "  1. Update helm/earthquake-app-chart/values.yaml:"
echo "     - backend.image.repository: $DOCKER_USERNAME/earthquake-backend"
echo "     - frontend.image.repository: $DOCKER_USERNAME/earthquake-frontend"
echo ""
echo "  2. Run cluster setup:"
echo "     ./scripts/cluster.sh setup --type docker-desktop"
echo ""
