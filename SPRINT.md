# Earthquake Data Pipeline - Sprint Document

## PROBLEM STATEMENT

Build a microservices architecture to fetch, process, and visualize USGS earthquake data using a Python backend, PostgreSQL database, and Next.js frontend — deployed via Kubernetes with Helm and ArgoCD.

---

## PURPOSE

Learn microservices communication, database persistence, and multi-container Kubernetes deployments using a real-world data pipeline.

---

## SPRINT SUMMARY

Develop a three-tier application: Python FastAPI backend fetches USGS earthquake data and stores in PostgreSQL; Next.js frontend queries the backend and displays events on a D3.js timeline; deploy all three services via Helm to local Kubernetes cluster (kind) managed by ArgoCD.

---

## TASK

Build and deploy a microservices earthquake data pipeline (Python FastAPI backend + PostgreSQL + Next.js frontend) to kind Kubernetes via Helm with persistent data storage and ArgoCD GitOps integration.

---

## KEY DECISIONS

### Technology Stack
- **Kubernetes:** kind (local cluster, reproducible tear-down/recreate)
- **Backend:** Python FastAPI + SQLAlchemy ORM
- **Database:** PostgreSQL with persistent volume (data survives cluster tear-down)
- **Frontend:** Next.js with D3.js timeline visualization
- **Package Manager:** Helm for multi-service deployment
- **GitOps:** ArgoCD for automated Git-driven deployments
- **Git Hosting:** GitHub (private repo, no company GitLab until inspection ends)
- **Container Registry:** Local Docker images (no remote registry yet)

### Data Acquisition Strategy
- **Option 3 (Hybrid):** Pre-populate on startup + manual refresh endpoint
- **Initial load:** Last 1 day of earthquake data (magnitude 4.0+)
- **Refresh endpoint:** `POST /refresh?days=N` to load N days of data
- **User queries:** Filter cached database by date range and magnitude
- **Data persistence:** PostgreSQL on PersistentVolume survives cluster tear-down

### Database Schema
```
earthquakes table:
- id (primary key)
- magnitude (float)
- location (string)
- depth (float)
- latitude (float)
- longitude (float)
- timestamp (datetime)
- usgs_id (string, unique)
```

### Architecture
- **Backend:** FastAPI server fetches USGS API → processes → stores in PostgreSQL
- **Database:** PostgreSQL StatefulSet with PVC mount to host volume
- **Frontend:** Next.js client fetches from backend API → renders D3.js timeline
- **Communication:** Frontend → Backend via HTTP REST API; Backend → PostgreSQL via SQLAlchemy
- **Service Discovery:** Kubernetes DNS (backend connects to `postgres:5432`)

### Frontend UI
- Simple D3.js timeline (no complex mapping)
- Display earthquakes by date/magnitude
- Filter controls: date range, minimum magnitude
- No map visualization (focus on data flow, not UI complexity)

### Deployment
- Single Helm chart with 3 services: backend, frontend, postgres
- All services in default namespace
- Environment variables for connections (database URL, backend API URL)
- ArgoCD watches Git repo and syncs automatically

---

## CHECKLIST

### Phase 1: Python Backend
- [ ] Create FastAPI project structure
- [ ] Define SQLAlchemy models (Earthquake table)
- [ ] Implement USGS API integration
- [ ] Create endpoints:
  - `GET /earthquakes?start_date=X&end_date=Y&min_magnitude=Z`
  - `POST /refresh?days=N`
  - `GET /health`
- [ ] Database initialization on startup
- [ ] Create Dockerfile
- [ ] Create requirements.txt

### Phase 2: Next.js Frontend
- [ ] Create Next.js project
- [ ] Build D3.js timeline component
- [ ] Create API client for backend
- [ ] Filter UI (date range, magnitude)
- [ ] Error handling and loading states
- [ ] Update Next.js config (hostname=0.0.0.0)
- [ ] Create Dockerfile
- [ ] Create package.json with dependencies

### Phase 3: Helm Chart
- [ ] Create `helm/earthquake-app/` directory structure
- [ ] Backend service manifests (Deployment, Service, ConfigMap)
- [ ] PostgreSQL StatefulSet with PVC
- [ ] Frontend service manifests (Deployment, Service)
- [ ] values.yaml with all configurable parameters
- [ ] Test Helm chart locally

### Phase 4: ArgoCD Integration
- [ ] Create ArgoCD Application CRD manifest
- [ ] Configure local Git repo mount in ArgoCD Helm values
- [ ] Test Git-driven deployments
- [ ] Verify automatic sync on Git commits

### Phase 5: Kubernetes Deployment
- [ ] Deploy to kind cluster
- [ ] Verify all 3 services running
- [ ] Test data flow: frontend → backend → database
- [ ] Verify persistent volume contains data
- [ ] Access frontend UI and timeline

### Phase 6: Tear-down and Redeploy
- [ ] Update cluster.sh script for this project
- [ ] Test full tear-down: `./scripts/cluster.sh teardown --type kind`
- [ ] Test full redeploy: `./scripts/cluster.sh setup --type kind`
- [ ] Verify data persists across tear-down/redeploy cycles
- [ ] Verify fresh startup fetches 1 day of data

### Phase 7: Documentation
- [ ] README.md (setup, run, architecture)
- [ ] Architecture diagram (draw.io or ASCII)
- [ ] API endpoint documentation (FastAPI auto-docs)
- [ ] Database schema documentation
- [ ] Troubleshooting guide

### Phase 8: GitHub
- [ ] Initialize Git repo
- [ ] Commit all code, Helm chart, scripts
- [ ] Push to GitHub private repo
- [ ] Clean up any secrets or credentials

---

## SUCCESS CRITERIA

1. ✅ Python backend successfully fetches USGS earthquake data via API
2. ✅ SQLAlchemy ORM correctly creates and queries earthquake table
3. ✅ PostgreSQL data persists on PersistentVolume
4. ✅ Backend `/refresh?days=N` endpoint populates database on demand
5. ✅ Frontend receives JSON from backend API
6. ✅ D3.js timeline renders earthquake events with date/magnitude
7. ✅ All three services (backend, frontend, postgres) communicate via Kubernetes DNS
8. ✅ Single Helm chart deploys entire stack with `helm install`
9. ✅ ArgoCD syncs changes from local Git repo automatically
10. ✅ Full lifecycle repeatable: `kind create cluster` → deploy → tear down → redeploy
11. ✅ Data persists across cluster tear-down/redeploy (PV not deleted)
12. ✅ Frontend accessible at `http://localhost:<NodePort>`
13. ✅ Backend health check (`GET /health`) passes
14. ✅ All code in GitHub private repo with documentation

---

## TIMELINE & PHASES

| Phase | Deliverable | Estimated Time |
|-------|-------------|-----------------|
| 1 | Python FastAPI backend + SQLAlchemy + PostgreSQL | 2 days |
| 2 | Next.js frontend + D3.js timeline | 2 days |
| 3 | Helm chart (3 services) | 1 day |
| 4 | ArgoCD integration + Git mount | 1 day |
| 5 | Kubernetes deployment + testing | 1 day |
| 6 | Tear-down/redeploy validation | 1 day |
| 7 | Documentation | 1 day |
| 8 | GitHub push + cleanup | 0.5 days |

**Total: ~9.5 days (1.5 weeks)**

---

## ENVIRONMENT SETUP

- **Local machine:** macOS with Docker Desktop or kind installed
- **Kubernetes:** kind cluster (disposable, fresh on each deploy)
- **Database volume:** Host mount at `/tmp/earthquake-db` (customize as needed)
- **Git repo:** Local directory at `~/repos/local/earthquake-app/`
- **Git hosting:** GitHub private repo (later migrate to company GitLab)

---

## NOTES

- Keep frontend UI simple (no maps, focus on data flow)
- Use D3.js timeline only (proven experience with it)
- Persistent volume allows data caching without re-fetching unless explicitly refreshed
- Full automation via cluster.sh script for repeatability
- Document as you build (not after)
- No CI/CD pipeline initially (add later after inspection ends)
