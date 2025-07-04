# Railway Deployment Configuration

# Node.js version
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package-production.json package.json
COPY package-lock.json* ./

# Install dependencies
RUN npm ci --only=production

# Copy application files
COPY production-server.js ./
COPY .env.example ./

# Expose port
EXPOSE $PORT

# Start the application
CMD ["npm", "start"]