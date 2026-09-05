FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package definition files
COPY package*.json ./

# Install production dependencies
RUN npm ci --omit=dev || npm install --omit=dev

# Copy backend source files
COPY . .

# Set non-root user for security
USER node

# Expose backend port
EXPOSE 3000

# ENVs are specified in the docker-compose

# Start application
CMD ["node", "server.js"]
