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
trivy-operator

kubectl port-forward svc/trivy-operator -n trivy-system 8080:80  
 
kubectl port-forward svc/earthquake-app-earthquake-app-chart-backend -n trivy-system 8000:8000  
helm upgrade argocd argo/argo-cd -n argocd -f argocd-values.yaml

https://aquasecurity.github.io/trivy-operator/latest/#option-1-install-from-traditional-helm-chart-repository

  helm repo add aqua https://aquasecurity.github.io/helm-charts/
   helm repo update

      helm install trivy-operator aqua/trivy-operator \
     --namespace trivy-system \
     --create-namespace \
     --version 0.32.0

helm uninstall trivy-operator -n trivy-system
helm install trivy-operator aquasecurity/trivy-operator \
  --namespace trivy-system \
  --version 0.32.0 \
  -f trivy-values.yaml
read only on the private images:
  dckr_pat_B6cehqUjPOicNZhtj4iGTHAD-kM

kubectl get vulnerabilityreport -n default -o json | jq '.items[] | {image: .report.artifact.repository, vulnerabilities: .report.vulnerabilities[] | {cve: .vulnerabilityID, severity: .severity, package: .resource, fixedVersion: .fixedVersion}}' > vulnerabilities.json


  kubectl get vulnerabilityreport replicaset-574d86cd58 -n default -o json | jq '.report.vulnerabilities[] | "\(.vulnerabilityID) - \(.resource) - \(.severity) - Fix: \(.fixedVersion)"'

  kubectl port-forward svc/earthquake-app-earthquake-app-chart-frontend  3000:3000  

  kubectl port-forward service/argocd-server -n argocd 6443:443 


