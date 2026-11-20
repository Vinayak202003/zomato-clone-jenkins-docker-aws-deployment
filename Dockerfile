
# Build Stage
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

# Install all dependencies
RUN npm ci

COPY . .

# Fix compatibility issues
ENV SKIP_PREFLIGHT_CHECK=true

# Build React application
RUN NODE_OPTIONS=--openssl-legacy-provider npm run build

# Production Stage
FROM nginx:alpine

# Copy React build files into Nginx
COPY --from=builder /app/build /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
