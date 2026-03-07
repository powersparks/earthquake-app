# Earthquake Frontend

Modern Next.js frontend for visualizing USGS earthquake data with D3.js timeline.

## Setup

### Local Development

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Set environment variables:**
   See `.env.local` — update `NEXT_PUBLIC_API_URL` to match your backend

3. **Run development server:**
   ```bash
   npm run dev
   ```

4. **Access the app:**
   Open http://localhost:3000 in your browser

## Features

- **D3.js Timeline Visualization** — Interactive timeline showing earthquake events
- **Filter Controls** — Filter by date range and minimum magnitude
- **Real-time Data Refresh** — Fetch fresh data from USGS API via backend
- **Earthquake Details Table** — View detailed information for each event
- **Health Check** — Validates backend connection
- **Responsive Design** — Works on desktop and mobile

## Building

```bash
npm run build
npm start
```

## Docker

### Build Image
```bash
docker build -t earthquake-frontend:latest .
```

### Run Container
```bash
docker run -d \
  -e NEXT_PUBLIC_API_URL=http://localhost:8000 \
  -p 3000:3000 \
  earthquake-frontend:latest
```

## Environment Variables

- `NEXT_PUBLIC_API_URL` — Backend API URL (default: http://localhost:8000)

## Architecture

- **Framework:** Next.js 14 with React 18
- **Visualization:** D3.js v7
- **HTTP Client:** Axios
- **Styling:** CSS Modules
- **Container:** Docker with multi-stage build

## API Integration

The frontend communicates with the backend at endpoints:
- `GET /health` — Health check
- `GET /earthquakes` — Query earthquakes
- `POST /refresh` — Refresh data from USGS

See `lib/api.js` for API client implementation.


helm upgrade earthquake ./helm/earthquake-app-chart
