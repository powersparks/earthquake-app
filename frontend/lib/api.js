/**
 * API client for communicating with the earthquake backend.
 */

import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export const apiClient = axios.create({
  baseURL: API_URL,
  timeout: 10000,
});

/**
 * Fetch earthquakes from backend API.
 * 
 * @param {Object} params - Query parameters
 * @param {string} params.start_date - Start date (YYYY-MM-DD)
 * @param {string} params.end_date - End date (YYYY-MM-DD)
 * @param {number} params.min_magnitude - Minimum magnitude (default: 4.0)
 * @returns {Promise<Object>} Earthquakes data
 */
export async function fetchEarthquakes(params = {}) {
  try {
    const response = await apiClient.get('/earthquakes', { params });
    return response.data;
  } catch (error) {
    console.error('Error fetching earthquakes:', error);
    throw error;
  }
}

/**
 * Refresh earthquake data from USGS API.
 * 
 * @param {number} days - Number of days to fetch (default: 1)
 * @returns {Promise<Object>} Refresh status
 */
export async function refreshEarthquakes(days = 1) {
  try {
    const response = await apiClient.post('/refresh', null, {
      params: { days },
    });
    return response.data;
  } catch (error) {
    console.error('Error refreshing earthquakes:', error);
    throw error;
  }
}

/**
 * Check backend health.
 * 
 * @returns {Promise<Object>} Health status
 */
export async function checkHealth() {
  try {
    const response = await apiClient.get('/health');
    return response.data;
  } catch (error) {
    console.error('Error checking health:', error);
    throw error;
  }
}
