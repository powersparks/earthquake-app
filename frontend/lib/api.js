/**
 * API client for communicating with the earthquake backend via Next.js proxy routes.
 */

import axios from 'axios';

export const apiClient = axios.create({
  baseURL: '/',
  timeout: 10000,
});

/**
 * Fetch earthquakes from backend API (via proxy).
 * 
 * @param {Object} params - Query parameters
 * @param {string} params.start_date - Start date (YYYY-MM-DD)
 * @param {string} params.end_date - End date (YYYY-MM-DD)
 * @param {number} params.min_magnitude - Minimum magnitude (default: 4.0)
 * @returns {Promise<Object>} Earthquakes data
 */
export async function fetchEarthquakes(params = {}) {
  try {
    const response = await apiClient.get('/api/earthquakes', { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching earthquakes:', error);
    throw error;
  }
}

/**
 * Refresh earthquake data from USGS API (via proxy).
 * 
 * @param {number} days - Number of days to fetch (default: 1)
 * @returns {Promise<Object>} Refresh status
 */
export async function refreshEarthquakes(days = 1) {
  try {
    const response = await apiClient.post('/api/refresh', null, {
      params: { days },
    });
    return response.data;
  } catch (error) {
    console.error('Error refreshing earthquakes:', error);
    throw error;
  }
}

/**
 * Check backend health (via direct call).
 * 
 * @returns {Promise<Object>} Health status
 */
export async function checkHealth() {
  try {
    const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    const response = await fetch(`${backendUrl}/health`);
    return response.json();
  } catch (error) {
    console.error('Error checking health:', error);
    throw error;
  }
}
