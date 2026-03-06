"""SQLAlchemy ORM models for database tables."""

from datetime import datetime
from sqlalchemy import Column, Integer, Float, String, DateTime, UniqueConstraint

from database import Base


class Earthquake(Base):
    """Earthquake event record."""
    
    __tablename__ = "earthquakes"
    
    id = Column(Integer, primary_key=True, index=True)
    usgs_id = Column(String, unique=True, index=True, nullable=False)  # Unique ID from USGS
    magnitude = Column(Float, nullable=False, index=True)
    location = Column(String, nullable=False)
    depth = Column(Float, nullable=False)  # In kilometers
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    timestamp = Column(DateTime, nullable=False, index=True)
    
    __table_args__ = (
        UniqueConstraint('usgs_id', name='uq_earthquake_usgs_id'),
    )
    
    def __repr__(self):
        return f"<Earthquake(id={self.id}, magnitude={self.magnitude}, location={self.location}, timestamp={self.timestamp})>"
