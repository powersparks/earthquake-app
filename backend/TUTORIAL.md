# FastAPI Backend Tutorial - Build from Scratch

## Architecture Overview

```
USGS API (earthquake.usgs.gov)
    ↓
USGSClient (usgs_client.py) ← Fetches & parses GeoJSON
    ↓
Schemas (schemas.py) ← Validates data structure
    ↓
Models (models.py) ← ORM maps to database
    ↓
Database (database.py) ← PostgreSQL connection
    ↓
Main API (main.py) ← FastAPI routes
    ↓
Frontend (GET /earthquakes, POST /refresh)
```

---

## Step-by-Step Build Order

### **Phase 1: Configuration & Database Setup**

#### **1. config.py** - Configuration Management
**Purpose:** Centralize all environment variables and settings

**Key concepts:**
- Use `pydantic_settings` for type-safe config
- Environment variables override defaults
- Single source of truth for database credentials

**What to customize:**
- Add new env vars (API keys, feature flags)
- Change defaults for your infrastructure
- Add validation for config values

**Learning tasks:**
- [ ] Add a new setting: `LOG_LEVEL` (default: "INFO")
- [ ] Add validation: ensure `database_port` is 1-65535

---

#### **2. database.py** - ORM & Database Connection
**Purpose:** Set up SQLAlchemy and manage database sessions

**Key concepts:**
- `create_engine()` - connects to PostgreSQL
- `SessionLocal` - factory for creating database sessions
- `Base` - parent class for all models
- `pool_pre_ping=True` - tests connections before use

**What to customize:**
- Connection pooling strategy
- Echo SQL in debug mode
- Add connection retry logic

**Learning tasks:**
- [ ] Add connection pool size limit (default 20)
- [ ] Add connection timeout

---

### **Phase 2: Data Modeling**

#### **3. models.py** - SQLAlchemy ORM Models
**Purpose:** Define database schema as Python classes

**Key concepts:**
- `@dataclass`-like syntax for database tables
- Columns with types, constraints, indexes
- Relationships (foreign keys, one-to-many)
- `__repr__` for debugging

**Current schema:**
```
earthquakes table
├── id (PK)
├── usgs_id (UNIQUE) ← From USGS API
├── magnitude (INDEXED)
├── location
├── depth
├── latitude, longitude
└── timestamp (INDEXED)
```

**What to customize/extend:**
- Add new columns (magnitude range category, alert level)
- Add relationships (earthquakes_by_region, hazard_level)
- Add indexes for query performance

**Learning tasks:**
- [ ] Add `alert_level` field (string, nullable)
- [ ] Add `created_at` timestamp (auto-set)
- [ ] Create a new model: `Region` with one-to-many to Earthquake

---

#### **4. schemas.py** - Pydantic Validation
**Purpose:** Define API request/response schemas (data validation)

**Key concepts:**
- Pydantic validates incoming/outgoing data
- `from_attributes=True` lets ORM models map to schemas
- Reusable across multiple endpoints
- Auto-generates OpenAPI docs

**Current schemas:**
- `EarthquakeResponse` - single earthquake
- `EarthquakesListResponse` - list with count

**What to customize/extend:**
- Add request schemas (`EarthquakeCreateRequest`)
- Add filters (`EarthquakeFilterRequest`)
- Add pagination

**Learning tasks:**
- [ ] Create `EarthquakeFilterRequest` with optional date/magnitude filters
- [ ] Add validation: magnitude > 0, end_date > start_date
- [ ] Create `EarthquakeBulkResponse` for CSV export

---

### **Phase 3: External Data Integration**

#### **5. usgs_client.py** - USGS API Client
**Purpose:** Fetch and parse earthquake data from external API

**Key concepts:**
- HTTP requests to public API
- GeoJSON parsing
- Date range filtering
- Error handling and logging

**Current flow:**
```
1. Calculate date range (now - N days)
2. Fetch GeoJSON from USGS all_month endpoint
3. Parse features into earthquakes
4. Filter by date range
5. Return list of dicts
```

**What to customize/extend:**
- Add caching (don't refetch same data)
- Add retry logic with exponential backoff
- Parse additional USGS fields (magnitude type, depth uncertainty)
- Add support for different magnitude thresholds

**Learning tasks:**
- [ ] Add retry logic (3 retries, 2s backoff)
- [ ] Add min_magnitude filter to API call
- [ ] Parse additional fields: `mag_type`, `depth_error`
- [ ] Add unit tests (mock USGS response)

---

### **Phase 4: API & Database Integration**

#### **6. main.py** - FastAPI App & Routes
**Purpose:** Expose HTTP endpoints for frontend/clients

**Key concepts:**
- FastAPI router decorators (`@app.get`, `@app.post`)
- Dependency injection (database sessions)
- Request/response models
- Error handling
- Lifespan events (startup/shutdown)

**Current routes:**
```
GET /health
  ← Simple health check

GET /earthquakes?start_date=...&end_date=...&min_magnitude=...
  ← Query from database
  
POST /refresh?days=7
  ← Trigger USGS fetch & store
```

**What to customize/extend:**
- Add filter routes (`GET /earthquakes/by-region`)
- Add update routes (`PATCH /earthquakes/{id}`)
- Add delete routes (`DELETE /earthquakes/{id}`)
- Add statistics routes (`GET /earthquakes/stats`)
- Add pagination
- Add sorting

**Learning tasks:**
- [ ] Create `GET /earthquakes/stats` (min, max, avg magnitude)
- [ ] Add `limit` and `offset` query params for pagination
- [ ] Add `sort_by` query param (magnitude, timestamp)
- [ ] Create `DELETE /earthquakes/{id}` with proper auth
- [ ] Add input validation with HTTPException

---

## Tutorial Progression

### **Week 1: Understanding the Foundations**

**Day 1-2: Configuration & Database**
```bash
cd backend
# Read config.py
# Read database.py
# Understand pydantic_settings and SQLAlchemy basics
```

**Day 3-4: Data Modeling**
```bash
# Read models.py - understand ORM
# Read schemas.py - understand validation
# Task: Add 2 new fields to Earthquake model
```

**Day 5: External Integration**
```bash
# Read usgs_client.py
# Understand GeoJSON parsing
# Test: fetch live data locally
```

**Day 6-7: API & Integration**
```bash
# Read main.py - understand FastAPI routes
# Run locally and test all endpoints
# Access /docs for interactive API browser
```

---

### **Week 2: Extensions & Customization**

**Task 1: Add Statistics Endpoint**
```python
# Add to main.py
@app.get("/earthquakes/stats")
async def get_stats():
    """Return min/max/avg magnitude, count by region"""
    pass
```

**Task 2: Add Filtering Schema**
```python
# Update schemas.py
class EarthquakeFilterRequest(BaseModel):
    min_magnitude: float = 4.0
    max_magnitude: float = 10.0
    start_date: Optional[date] = None
    end_date: Optional[date] = None
```

**Task 3: Extend USGS Client**
```python
# Update usgs_client.py
# Add caching to avoid refetching same data
# Add retry logic on network failure
# Parse additional fields
```

**Task 4: Add Database Relationships**
```python
# Create Region model
# Add foreign key: Earthquake.region_id
# Create new endpoint: GET /regions/{id}/earthquakes
```

---

### **Week 3: Performance & Production**

**Task 5: Add Pagination**
```python
# Update main.py
@app.get("/earthquakes")
async def get_earthquakes(skip: int = 0, limit: int = 100):
    pass
```

**Task 6: Add Caching**
```python
# Use Redis or in-memory cache
# Cache USGS responses for 1 hour
# Cache aggregate stats for 10 minutes
```

**Task 7: Add Bulk Operations**
```python
# POST /earthquakes/bulk (import CSV)
# DELETE /earthquakes/before/{date} (cleanup)
```

---

## File-by-File Checklist

### config.py
- [ ] Understand `BaseSettings`
- [ ] Know how env vars override defaults
- [ ] Add custom validation
- [ ] Add new config fields

### database.py
- [ ] Understand `create_engine()`
- [ ] Know difference between engine and session
- [ ] Understand connection pooling
- [ ] Know when to use SessionLocal

### models.py
- [ ] Understand Column types and constraints
- [ ] Know what `index=True` does
- [ ] Understand `__tablename__`
- [ ] Know when to use relationships

### schemas.py
- [ ] Understand Pydantic validation
- [ ] Know `ConfigDict(from_attributes=True)`
- [ ] Understand request vs response schemas
- [ ] Know how to add custom validators

### usgs_client.py
- [ ] Understand GeoJSON structure
- [ ] Know how to parse coordinates
- [ ] Know how to handle dates/times
- [ ] Understand error handling in API calls

### main.py
- [ ] Understand `@app.get` and `@app.post`
- [ ] Know dependency injection with `SessionLocal`
- [ ] Understand request models and validation
- [ ] Understand response models
- [ ] Know lifespan events

---

## Common Customizations

### Add a new field to earthquake
1. Add column to `models.py`
2. Add field to `EarthquakeResponse` in `schemas.py`
3. Update `usgs_client.py` to parse it
4. Update `main.py` to filter by it (if needed)

### Add a new endpoint
1. Create response schema in `schemas.py`
2. Add route function to `main.py`
3. Use `SessionLocal()` to query database
4. Return `response_model=YourSchema`

### Add authentication
1. Create `auth.py` with token validation
2. Add `Depends(verify_token)` to protected routes
3. Add Bearer token scheme to OpenAPI

---

## Next Learning Goals

1. **Async/Await:** Update `usgs_client.py` to use `aiohttp` instead of `requests`
2. **Database Relationships:** Create Region model, link earthquakes
3. **Caching:** Add Redis caching for API responses
4. **Testing:** Write pytest tests for each module
5. **Monitoring:** Add Prometheus metrics to track API usage
6. **Background Tasks:** Use Celery for periodic USGS refreshes

---

## Resources

- [FastAPI Tutorial](https://fastapi.tiangolo.com/)
- [SQLAlchemy ORM](https://docs.sqlalchemy.org/en/20/)
- [Pydantic Docs](https://docs.pydantic.dev/)
- [USGS Earthquake API](https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php)
- [GeoJSON Spec](https://tools.ietf.org/html/rfc7946)
