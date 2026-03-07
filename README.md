docker pull postgres:16-alpine

docker run -d \
  --name earthquake-postgres \
  -e POSTGRES_DB=earthquake_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:16-alpine


trivy:
cd /Users/harleyparks/repos/local/earthquake-app
cat > trivy-values.yaml << 'EOF'
trivy:
  dbRepository: ghcr.io/aquasecurity/trivy-db
  image:
    tag: "0.53.0"
scanJob:
  image:
    tag: "0.53.0"
EOF


helm repo add aquasecurity https://aquasecurity.github.io/helm-charts/
helm repo update
helm install trivy-operator aquasecurity/trivy-operator \
  -n trivy-system \
  --create-namespace \
  -f trivy-values.yaml

kubectl get imageauditreports -A
kubectl get vulnerabilityreports -A
