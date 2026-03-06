"""Pydantic schemas for API requests and responses."""

from datetime import datetime
from typing import List
from pydantic import BaseModel, ConfigDict


class EarthquakeResponse(BaseModel):
    """Schema for earthquake response."""
    
    id: int
    usgs_id: str
    magnitude: float
    location: str
    depth: float
    latitude: float
    longitude: float
    timestamp: datetime
    
    model_config = ConfigDict(from_attributes=True)


class EarthquakesListResponse(BaseModel):
    """Schema for list of earthquakes."""
    
    count: int
    earthquakes: List[EarthquakeResponse]
