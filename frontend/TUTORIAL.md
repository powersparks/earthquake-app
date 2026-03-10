# Next.js Frontend Tutorial - Build from Scratch

## Architecture Overview

```
Next.js App Router (app/ folder)
├── layout.jsx (Root HTML shell)
├── page.jsx (Main app logic & state)
└── api/ (Proxy routes to backend)

Components
├── Timeline.jsx (D3.js visualization)
└── Timeline.module.css (Scoped styles)

Utilities
└── lib/api.js (Backend HTTP client)

Styling
├── app/globals.css (Global styles)
├── app/page.module.css (Page styles)
└── components/Timeline.module.css (Component styles)
```

**Data Flow:**
```
User interactions (filters, refresh)
  ↓
page.jsx state & handlers
  ↓
lib/api.js (axios calls to backend)
  ↓
Next.js API routes (/api/earthquakes, /api/refresh)
  ↓
Backend FastAPI server
  ↓
Response → page.jsx state → Timeline.jsx renders
```

---

## Step-by-Step Build Order

### **Phase 1: Project Setup & Configuration**

#### **1. package.json** - Dependencies
**Purpose:** Declare all npm packages and build scripts

**Key concepts:**
- `dependencies` vs `devDependencies`
- Scripts: `dev`, `build`, `start`, `lint`
- Version ranges (`^` = minor updates allowed)

**Current stack:**
- `react` & `react-dom` — UI library
- `next` — Framework (routing, SSR, builds)
- `d3` — Visualization
- `axios` — HTTP client

**What to customize:**
- Add new packages as needed
- Update versions carefully
- Add new npm scripts (e.g., `test`, `deploy`)

**Learning tasks:**
- [ ] Understand semantic versioning (1.2.3 = major.minor.patch)
- [ ] Know difference between `^` and `~` version constraints
- [ ] Know what `npm install` vs `npm ci` does

---

#### **2. next.config.js** - Framework Configuration
**Purpose:** Customize Next.js build and runtime behavior

**Common configs:**
- Image optimization
- TypeScript support
- Environment variables
- Custom webpack plugins
- API route configuration

**Learning tasks:**
- [ ] Read and understand current config
- [ ] Add custom env variables
- [ ] Configure API route handlers

---

### **Phase 2: Layout & Styling**

#### **3. app/layout.jsx** - Root HTML Shell
**Purpose:** Wraps all pages with HTML structure

**Key concepts:**
- Server component (not 'use client')
- Sets metadata (title, description)
- Applies global fonts
- Renders `{children}` slot for page content

**Current structure:**
```jsx
<html>
  <body>
    {children}  // Your page content goes here
  </body>
</html>
```

**What to customize:**
- Add navigation header
- Add footer
- Add global theme provider
- Add analytics tracking

**Learning tasks:**
- [ ] Understand when layout runs (server-side, once)
- [ ] Add a navigation bar component
- [ ] Change global font from Inter to custom font

---

#### **4. app/globals.css** - Global Styles
**Purpose:** CSS applied to entire app

**Key concepts:**
- CSS custom properties (variables)
- Reset/normalize styles
- Responsive typography
- Light/dark mode setup

**Learning tasks:**
- [ ] Add CSS variables for colors, spacing, fonts
- [ ] Add dark mode support (prefers-color-scheme)
- [ ] Understand CSS specificity

---

### **Phase 3: Main Page & State Management**

#### **5. app/page.jsx** - Main Page & App Logic
**Purpose:** Entry point for the app, manages all state and interactions

**Key concepts:**
- `'use client'` — Makes it client-side interactive
- `useState` — Manage UI state
- `useEffect` — Side effects (API calls on mount)
- Controlled components (form inputs)
- Event handlers

**Current features:**
```javascript
// State
[earthquakes, setEarthquakes] — data from backend
[loading, setLoading] — loading indicator
[error, setError] — error messages
[startDate, setStartDate] — filter: start date
[endDate, setEndDate] — filter: end date
[minMagnitude, setMinMagnitude] — filter: min magnitude
[backendHealthy, setBackendHealthy] — backend status

// Handlers
loadEarthquakes() — fetch with filters
handleRefresh() — trigger USGS refresh
handleFilter() — apply filters
checkHealth() — test backend connection
```

**What to customize/extend:**
- Add sorting (by magnitude, date, location)
- Add pagination
- Add export to CSV
- Add bookmarking/favorites
- Add regional filtering (by bounding box or region)
- Add comparison mode (two date ranges side-by-side)

**Learning tasks:**
- [ ] Understand `useEffect` dependency arrays
- [ ] Add a "Sort By" dropdown (magnitude, date)
- [ ] Add pagination (show 25/50/100 results)
- [ ] Add local storage to persist filters
- [ ] Add error retry button
- [ ] Add loading skeleton while data fetches

---

#### **6. app/page.module.css** - Page Styles
**Purpose:** Scoped CSS for page.jsx (prevents name collisions)

**Key concepts:**
- CSS Modules — automatic scope (class names are unique)
- Flexbox layout
- Responsive design (@media queries)
- Component composition via CSS classes

**Sections:**
- `.container` — outer wrapper
- `.header` — title and status
- `.controls` — filters and refresh form
- `.results` — earthquakes display
- `.earthquakeList` — table of results
- `.footer` — attribution

**Learning tasks:**
- [ ] Add responsive mobile styles
- [ ] Add dark mode support
- [ ] Improve form styling (better inputs, labels)
- [ ] Add loading animations/spinners

---

### **Phase 4: API Communication**

#### **7. lib/api.js** - Backend HTTP Client
**Purpose:** Centralize all HTTP calls to backend

**Key concepts:**
- Axios instance for reusable config
- Request/response interceptors
- Error handling patterns
- API versioning

**Current functions:**
```javascript
fetchEarthquakes(params) — GET /api/earthquakes
refreshEarthquakes(days) — POST /api/refresh
checkHealth() — GET /health (direct to backend)
```

**What to customize/extend:**
- Add retry logic on network failure
- Add request caching
- Add request/response logging
- Add authentication headers
- Add new endpoints as backend grows

**Learning tasks:**
- [ ] Add axios interceptors for logging
- [ ] Add error handling with retries
- [ ] Add TypeScript types (JSDoc comments)
- [ ] Add request timeout handling
- [ ] Add mock data for testing

---

### **Phase 5: Visualization & Components**

#### **8. components/Timeline.jsx** - D3.js Chart
**Purpose:** Render interactive earthquake timeline visualization

**Key concepts:**
- D3 scales (time, linear, sqrt)
- SVG rendering
- Event listeners (mouseover, mouseout)
- State management with React hooks

**Current features:**
```javascript
// Scales
xScale — time axis (dates)
yScale — magnitude axis
radiusScale — circle size (sqrt scaled)

// Rendering
Circles for each earthquake
Color coding by magnitude
Tooltip on hover
Axes with labels
Grid lines

// Commented out:
Brush selection (for filtering by date range)
Master/slave chart coordination
```

**What to customize/extend:**
- Enable brush selection (already coded, just commented)
- Add zoom interaction
- Add pan interaction
- Add earthquake detail popup on click
- Add animation on load
- Add region highlighting
- Switch between views (timeline, map, table)

**Learning tasks:**
- [ ] Uncomment and enable brush selection
- [ ] Understand D3 scales and axes
- [ ] Add zoom behavior
- [ ] Add custom color scale based on magnitude
- [ ] Add transitions/animations
- [ ] Create a separate map view component

---

#### **9. components/Timeline.module.css** - Component Styles
**Purpose:** Scoped styles for Timeline component

**Key concepts:**
- SVG styling via CSS classes
- Tooltip positioning
- Z-index for layering
- Pointer events control

**Learning tasks:**
- [ ] Style the tooltip better
- [ ] Add responsive sizing for small screens
- [ ] Add legend for magnitude colors

---

### **Phase 6: API Routes & Backend Integration**

#### **10. app/api/earthquakes/route.js** - Proxy Endpoint
**Purpose:** Proxy requests from frontend to backend

**Why proxy?**
- Avoid CORS issues
- Add authentication in one place
- Rate limiting
- Request transformation

**Current behavior:**
```javascript
GET /api/earthquakes → forwards to http://localhost:8000/earthquakes
```

**What to add:**
- Authentication/authorization
- Request validation
- Response caching
- Rate limiting
- Logging

**Learning tasks:**
- [ ] Understand API route structure
- [ ] Add custom headers
- [ ] Add error handling
- [ ] Add request logging

---

#### **11. app/api/refresh/route.js** - Refresh Proxy
**Purpose:** Proxy refresh requests to backend

---

## Tutorial Progression

### **Week 1: Understanding Next.js Fundamentals**

**Day 1-2: Setup & Configuration**
```bash
npm install
npm run dev  # Start dev server on localhost:3000
# Open http://localhost:3000
```
Study:
- package.json
- next.config.js
- app/layout.jsx

**Day 3-4: Layout & Styling**
- app/globals.css — global styles
- app/page.module.css — page styles
- components/Timeline.module.css — component styles
- Understand CSS Modules

**Day 5: Main Page Logic**
- Read app/page.jsx
- Understand useState and useEffect
- Trace data flow: filters → API call → state update → render

**Day 6-7: API Communication**
- Read lib/api.js
- Understand axios configuration
- Test API calls manually in browser console

---

### **Week 2: React & Components**

**Task 1: Add Sorting**
```jsx
// In page.jsx
const [sortBy, setSortBy] = useState('date'); // 'date' or 'magnitude'

// Modify loadEarthquakes to sort results
const sorted = earthquakes.sort((a, b) => {
  if (sortBy === 'magnitude') return b.magnitude - a.magnitude;
  return new Date(b.timestamp) - new Date(a.timestamp);
});
```

**Task 2: Add Pagination**
```jsx
const [page, setPage] = useState(1);
const itemsPerPage = 25;
const totalPages = Math.ceil(earthquakes.length / itemsPerPage);
const paginatedEarthquakes = earthquakes.slice(
  (page - 1) * itemsPerPage,
  page * itemsPerPage
);
```

**Task 3: Enable D3 Brush Selection**
```jsx
// In Timeline.jsx, uncomment the brush code section
// This allows date range filtering by dragging on the chart
```

**Task 4: Add Local Storage Persistence**
```jsx
// Save filters to localStorage on change
useEffect(() => {
  localStorage.setItem('earthquakeFilters', JSON.stringify({
    startDate, endDate, minMagnitude
  }));
}, [startDate, endDate, minMagnitude]);

// Restore filters on mount
useEffect(() => {
  const saved = localStorage.getItem('earthquakeFilters');
  if (saved) {
    const { startDate, endDate, minMagnitude } = JSON.parse(saved);
    setStartDate(startDate);
    setEndDate(endDate);
    setMinMagnitude(minMagnitude);
  }
}, []);
```

---

### **Week 3: Visualization & Advanced Features**

**Task 5: Add D3 Zoom**
```jsx
// In Timeline.jsx useEffect
const zoom = d3.zoom()
  .on('zoom', (event) => {
    // Rescale on zoom
  });

svg.call(zoom);
```

**Task 6: Create a Map View Component**
```jsx
// New: components/Map.jsx
// Use react-leaflet to show earthquake locations
```

**Task 7: Add Export to CSV**
```jsx
const exportToCSV = () => {
  const csv = earthquakes.map(eq => 
    `"${eq.location}",${eq.magnitude},${eq.depth},...`
  ).join('\n');
  // Download as file
};
```

**Task 8: Add Dark Mode Toggle**
```jsx
const [isDark, setIsDark] = useState(false);
// Apply theme class to root element
document.documentElement.setAttribute('data-theme', isDark ? 'dark' : 'light');
```

---

## File-by-File Checklist

### Core Files
- [ ] **package.json** — know dependencies and scripts
- [ ] **next.config.js** — understand customization options
- [ ] **app/layout.jsx** — understand root structure

### Pages & Styling
- [ ] **app/page.jsx** — understand state management and component composition
- [ ] **app/page.module.css** — understand CSS Modules
- [ ] **app/globals.css** — understand global styles

### Components
- [ ] **components/Timeline.jsx** — understand D3 rendering
- [ ] **components/Timeline.module.css** — understand component styling

### API & Utilities
- [ ] **lib/api.js** — understand HTTP client and error handling
- [ ] **app/api/earthquakes/route.js** — understand proxy pattern
- [ ] **app/api/refresh/route.js** — understand proxy pattern

---

## Common Customizations

### Add a new filter
1. Add state in `page.jsx`: `const [filterName, setFilterName] = useState(defaultValue)`
2. Add form input in render
3. Add to params in `loadEarthquakes()`
4. Update backend query string

### Add a new visualization
1. Create `components/NewViz.jsx`
2. Use D3 or other library
3. Import in `page.jsx`
4. Pass data and handlers as props
5. Style with `.module.css`

### Add a new API endpoint
1. Create `app/api/newEndpoint/route.js`
2. Define handler (GET, POST, etc.)
3. Add function to `lib/api.js`
4. Call from event handler in `page.jsx`

### Add authentication
1. Create `lib/auth.js` with token management
2. Add token to axios headers in `lib/api.js`
3. Redirect to login on 401 response
4. Store token in localStorage or cookies

---

## Next Learning Goals

1. **TypeScript** — Migrate to `.tsx` files for type safety
2. **State Management** — Use Context API or Zustand instead of useState everywhere
3. **Testing** — Add Jest/React Testing Library tests
4. **Performance** — Add React.memo, useMemo for optimization
5. **SEO** — Use next/head for metadata, generate sitemaps
6. **Maps** — Add Leaflet or Mapbox for geographic visualization
7. **Real-time** — Add WebSockets or Server-Sent Events for live updates
8. **Authentication** — Add NextAuth.js for user login/permissions

---

## Key Next.js Concepts to Master

- **App Router** — File-based routing (app/page.jsx → /)
- **Server vs Client Components** — Use `'use client'` for interactivity
- **API Routes** — Create backend endpoints in app/api/
- **Incremental Static Regeneration** — Cache and revalidate pages
- **Image Optimization** — Use next/image for responsive images
- **Font Optimization** — Use next/font for web fonts
- **Middleware** — Intercept requests at edge

---

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [React Hooks Guide](https://react.dev/reference/react/hooks)
- [D3.js Documentation](https://d3js.org)
- [CSS Modules](https://nextjs.org/docs/app/building-your-application/styling/css-modules)
- [Axios Documentation](https://axios-http.com/)
- [USGS Earthquake API](https://earthquake.usgs.gov/earthquakes/feed/)
