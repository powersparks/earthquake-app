"""USGS Earthquake API client."""

import logging
from datetime import datetime, timedelta
from typing import List, Dict

import requests

logger = logging.getLogger(__name__)


class USGSClient:
    """Client for fetching earthquake data from USGS API."""
    
    BASE_URL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary"
    TIMEOUT = 30
    
    async def fetch_earthquakes(self, days: int = 1) -> List[Dict]:
        """
        Fetch earthquakes from USGS API.
        
        Args:
            days: Number of days in the past to fetch
        
        Returns:
            List of earthquake data dictionaries
        """
        # Calculate date range
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)
        
        # Use USGS API endpoint for all earthquakes (no filter by time on query)
        # We'll filter by date range when processing
        url = f"{self.BASE_URL}/all_month.geojson"
        
        logger.info(f"Fetching earthquakes from USGS API: {url}")
        
        try:
            response = requests.get(url, timeout=self.TIMEOUT)
            response.raise_for_status()
            data = response.json()
            
            earthquakes = []
            for feature in data.get("features", []):
                eq = self._parse_feature(feature)
                
                # Filter by date range
                if start_date <= eq["timestamp"] <= end_date:
                    earthquakes.append(eq)
            
            logger.info(f"Fetched {len(earthquakes)} earthquakes from USGS in last {days} day(s)")
            return earthquakes
        
        except requests.RequestException as e:
            logger.error(f"Failed to fetch from USGS API: {e}")
            raise
    
    def _parse_feature(self, feature: Dict) -> Dict:
        """Parse a GeoJSON feature into earthquake data."""
        props = feature.get("properties", {})
        coords = feature.get("geometry", {}).get("coordinates", [0, 0, 0])
        
        return {
            "usgs_id": feature.get("id", ""),
            "magnitude": props.get("mag", 0.0),
            "location": props.get("place", "Unknown"),
            "depth": coords[2],  # Depth in km
            "latitude": coords[1],
            "longitude": coords[0],
            "timestamp": datetime.utcfromtimestamp(props.get("time", 0) / 1000),
        }
