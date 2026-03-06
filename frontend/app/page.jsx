'use client';

import React, { useState, useEffect } from 'react';
import Timeline from '@/components/Timeline';
import { fetchEarthquakes, refreshEarthquakes, checkHealth } from '@/lib/api';
import styles from './page.module.css';

export default function Home() {
  const [earthquakes, setEarthquakes] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [backendHealthy, setBackendHealthy] = useState(false);
  
  // Filter state
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [minMagnitude, setMinMagnitude] = useState(4.0);
  
  // Refresh state
  const [refreshing, setRefreshing] = useState(false);
  const [refreshDays, setRefreshDays] = useState(1);

  // Check backend health on mount
  useEffect(() => {
    const checkHealth = async () => {
      try {
        await checkHealth();
        setBackendHealthy(true);
      } catch (err) {
        setBackendHealthy(false);
        setError('Backend API is not available');
      }
    };
    checkHealth();
    loadEarthquakes();
  }, []);

  // Load earthquakes
  const loadEarthquakes = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = {
        min_magnitude: minMagnitude,
      };
      if (startDate) params.start_date = startDate;
      if (endDate) params.end_date = endDate;
      
      const data = await fetchEarthquakes(params);
      setEarthquakes(data.earthquakes || []);
    } catch (err) {
      setError(`Failed to load earthquakes: ${err.message}`);
      setEarthquakes([]);
    } finally {
      setLoading(false);
    }
  };

  // Refresh data from USGS
  const handleRefresh = async () => {
    setRefreshing(true);
    setError(null);
    try {
      const result = await refreshEarthquakes(refreshDays);
      setError(`${result.message} - Reloading data...`);
      await new Promise(resolve => setTimeout(resolve, 1000));
      await loadEarthquakes();
    } catch (err) {
      setError(`Refresh failed: ${err.message}`);
    } finally {
      setRefreshing(false);
    }
  };

  // Handle filter submit
  const handleFilter = (e) => {
    e.preventDefault();
    loadEarthquakes();
  };

  return (
    <div className={styles.container}>
      <header className={styles.header}>
        <h1>🌍 Earthquake Data Pipeline</h1>
        <p>Real-time USGS earthquake data visualization</p>
        <div className={styles.statusBadge}>
          {backendHealthy ? (
            <span className={styles.statusHealthy}>✓ Backend Connected</span>
          ) : (
            <span className={styles.statusError}>✗ Backend Unavailable</span>
          )}
        </div>
      </header>

      <main className={styles.main}>
        {/* Controls */}
        <div className={styles.controls}>
          <form onSubmit={handleFilter} className={styles.filterForm}>
            <div className={styles.formGroup}>
              <label htmlFor="startDate">Start Date:</label>
              <input
                id="startDate"
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
            </div>

            <div className={styles.formGroup}>
              <label htmlFor="endDate">End Date:</label>
              <input
                id="endDate"
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
              />
            </div>

            <div className={styles.formGroup}>
              <label htmlFor="minMagnitude">Min Magnitude:</label>
              <input
                id="minMagnitude"
                type="number"
                min="0"
                max="10"
                step="0.1"
                value={minMagnitude}
                onChange={(e) => setMinMagnitude(parseFloat(e.target.value))}
              />
            </div>

            <button type="submit" disabled={loading}>
              {loading ? 'Loading...' : 'Search'}
            </button>
          </form>

          <div className={styles.refreshForm}>
            <label htmlFor="refreshDays">Fetch last:</label>
            <input
              id="refreshDays"
              type="number"
              min="1"
              max="365"
              value={refreshDays}
              onChange={(e) => setRefreshDays(parseInt(e.target.value))}
            />
            <span>days</span>
            <button onClick={handleRefresh} disabled={refreshing}>
              {refreshing ? 'Refreshing...' : 'Refresh Data'}
            </button>
          </div>
        </div>

        {/* Error message */}
        {error && (
          <div className={styles.errorMessage}>
            <strong>⚠️ {error}</strong>
          </div>
        )}

        {/* Results */}
        <div className={styles.results}>
          <h2>Results: {earthquakes.length} earthquakes found</h2>
          
          {earthquakes.length > 0 ? (
            <>
              <Timeline data={earthquakes} />
              
              {/* Earthquake list */}
              <div className={styles.earthquakeList}>
                <h3>Earthquake Details</h3>
                <table>
                  <thead>
                    <tr>
                      <th>Date/Time</th>
                      <th>Location</th>
                      <th>Magnitude</th>
                      <th>Depth (km)</th>
                      <th>Latitude</th>
                      <th>Longitude</th>
                    </tr>
                  </thead>
                  <tbody>
                    {earthquakes.map((eq, idx) => (
                      <tr key={idx}>
                        <td>{new Date(eq.timestamp).toLocaleString()}</td>
                        <td>{eq.location}</td>
                        <td className={styles.magnitude}>{eq.magnitude.toFixed(2)}</td>
                        <td>{eq.depth.toFixed(1)}</td>
                        <td>{eq.latitude.toFixed(2)}</td>
                        <td>{eq.longitude.toFixed(2)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          ) : (
            <p className={styles.noResults}>No earthquakes found. Try different filters or refresh data.</p>
          )}
        </div>
      </main>

      <footer className={styles.footer}>
        <p>Data source: <a href="https://earthquake.usgs.gov/" target="_blank" rel="noopener noreferrer">USGS Earthquake Hazards Program</a></p>
      </footer>
    </div>
  );
}
