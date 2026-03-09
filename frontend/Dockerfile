FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* yarn.lock* ./

# NOTE: if you don't have the certs or don't need them, comment out
# RUN npm set strict-ssl false
COPY ./cert/Zscaler-bundle.pem /usr/local/share/ca-certificates/Zscaler-bundle.crt  
ENV NODE_EXTRA_CA_CERTS=/usr/local/share/ca-certificates/Zscaler-bundle.crt
# Install dependencies
RUN npm ci

# Copy source code
COPY . .

ARG NEXT_PUBLIC_API_URL=http://earthquake-app-earthquake-app-chart-backend.default.svc.cluster.local:8000
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
# Build Next.js app
RUN npm run build

# Production stage
FROM node:18-alpine
#env:

ARG NEXT_PUBLIC_API_URL=http://earthquake-app-earthquake-app-chart-backend.default.svc.cluster.local:8000
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* yarn.lock* ./

# Install production dependencies only
RUN npm ci --only=production

# Copy built app from builder
COPY --from=builder /app/.next ./.next
# Copy public if it exists (optional)
## COPY --from=builder /app/public ./public 2>/dev/null || true
RUN if [ -d /app/public ]; then cp -r /app/public ./public; fi
# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Run the application
CMD ["npm", "start"]
