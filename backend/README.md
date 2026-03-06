# Earthquake Backend API

FastAPI backend for fetching, processing, and storing USGS earthquake data.

## Setup

### Local Development

1. **Create virtual environment:**
   ```bash
   uv venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

2. **Install dependencies:**
   ```bash
   uv sync
   ```

3. **Set up PostgreSQL database:**
   ```bash
   # Using Docker
   docker run -d \
     --name earthquake-postgres \
     -e POSTGRES_DB=earthquake_db \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_PASSWORD=postgres \
     -p 5432:5432 \
     postgres:15
   ```

4. **Run the application:**
   ```bash
   uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

5. **Access API documentation:**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

## API Endpoints

### Health Check
```bash
GET /health
```

### Query Earthquakes
```bash
GET /earthquakes?start_date=2024-01-15&end_date=2024-01-16&min_magnitude=4.0
```

Parameters:
- `start_date` (optional): Start date in YYYY-MM-DD format
- `end_date` (optional): End date in YYYY-MM-DD format
- `min_magnitude` (default: 4.0): Minimum magnitude filter

### Refresh Data
```bash
POST /refresh?days=7
```

Fetches earthquakes from the last N days and stores in database.

## Docker Build

```bash
docker build -t earthquake-backend:latest .
docker run -d \
  --name earthquake-backend \
  -e DATABASE_HOST=host.docker.internal \
  -e DATABASE_PORT=5432 \
  -p 8000:8000 \
  earthquake-backend:latest
```

## Database Schema

```
earthquakes table:
- id: Integer (primary key)
- usgs_id: String (unique, from USGS API)
- magnitude: Float
- location: String
- depth: Float (kilometers)
- latitude: Float
- longitude: Float
- timestamp: DateTime
```

## Environment Variables

See `.env` for available configuration options.

For Kubernetes deployment, pass these as environment variables:
- `DATABASE_HOST`: PostgreSQL host (default: localhost)
- `DATABASE_PORT`: PostgreSQL port (default: 5432)
- `DATABASE_USER`: PostgreSQL user (default: postgres)
- `DATABASE_PASSWORD`: PostgreSQL password (default: postgres)
- `DATABASE_NAME`: Database name (default: earthquake_db)
- `DEBUG`: Enable debug mode (default: false)
