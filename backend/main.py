"""
FastAPI backend for USGS earthquake data pipeline.
Fetches, processes, and stores earthquake data from USGS API.
"""

import logging
from contextlib import asynccontextmanager
from datetime import datetime, timedelta

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from database import Base, engine, SessionLocal
from models import Earthquake
from schemas import EarthquakeResponse, EarthquakesListResponse
from usgs_client import USGSClient
from config import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage app startup and shutdown."""
    logger.info("Starting up...")
    
    # Create database tables
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables created")
    
    # Fetch initial earthquake data
    try:
        await fetch_earthquakes_from_usgs(days=1)
        logger.info("Initial earthquake data loaded")
    except Exception as e:
        logger.error(f"Failed to load initial data: {e}")
    
    yield
    
    logger.info("Shutting down...")


app = FastAPI(
    title="Earthquake Data API",
    description="API for querying USGS earthquake data",
    version="0.1.0",
    lifespan=lifespan,
)

# Add CORS middleware for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for local dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["health"])
async def health_check():
    """Health check endpoint."""
    return {"status": "ok"}


@app.get("/earthquakes", response_model=EarthquakesListResponse, tags=["earthquakes"])
async def get_earthquakes(
    start_date: str = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: str = Query(None, description="End date (YYYY-MM-DD)"),
    min_magnitude: float = Query(4.0, description="Minimum magnitude"),
):
    """
    Query earthquakes from database.
    
    If no dates provided, returns last 7 days of data.
    """
    db = SessionLocal()
    try:
        query = db.query(Earthquake).filter(Earthquake.magnitude >= min_magnitude)
        
        # Parse dates
        if start_date:
            try:
                start_dt = datetime.strptime(start_date, "%Y-%m-%d")
                query = query.filter(Earthquake.timestamp >= start_dt)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid start_date format (use YYYY-MM-DD)")
        
        if end_date:
            try:
                end_dt = datetime.strptime(end_date, "%Y-%m-%d")
                # Add 1 day to include the entire end_date
                end_dt = end_dt + timedelta(days=1)
                query = query.filter(Earthquake.timestamp < end_dt)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid end_date format (use YYYY-MM-DD)")
        
        earthquakes = query.order_by(Earthquake.timestamp.desc()).all()
        
        return EarthquakesListResponse(
            count=len(earthquakes),
            earthquakes=[EarthquakeResponse.from_orm(eq) for eq in earthquakes],
        )
    finally:
        db.close()


@app.post("/refresh", tags=["earthquakes"])
async def refresh_earthquakes_endpoint(days: int = Query(1, description="Number of days to fetch")):
    """
    Manually refresh earthquake data from USGS API.
    Fetches last N days of data.
    """
    if days < 1 or days > 365:
        raise HTTPException(status_code=400, detail="Days must be between 1 and 365")
    
    try:
        count = await fetch_earthquakes_from_usgs(days=days)
        return {"status": "success", "message": f"Fetched {count} earthquakes from last {days} day(s)"}
    except Exception as e:
        logger.error(f"Refresh failed: {e}")
        raise HTTPException(status_code=500, detail=f"Refresh failed: {str(e)}")


async def fetch_earthquakes_from_usgs(days: int = 1):
    """Fetch earthquakes from USGS API and store in database."""
    client = USGSClient()
    db = SessionLocal()
    
    try:
        logger.info(f"Fetching earthquakes from last {days} day(s)...")
        earthquakes_data = await client.fetch_earthquakes(days=days)
        
        count = 0
        for eq_data in earthquakes_data:
            # Check if earthquake already exists
            existing = db.query(Earthquake).filter(
                Earthquake.usgs_id == eq_data["usgs_id"]
            ).first()
            
            if not existing:
                earthquake = Earthquake(**eq_data)
                db.add(earthquake)
                count += 1
        
        db.commit()
        logger.info(f"Stored {count} new earthquakes in database")
        return count
    
    except Exception as e:
        db.rollback()
        logger.error(f"Error fetching earthquakes: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
