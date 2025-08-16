# Use Node.js LTS Alpine image for smaller size and security
FROM node:20-alpine

# Accept build arguments for version info
ARG BUILD_VERSION=unknown
ARG BUILD_DATE=unknown
ARG BUILD_COMMIT=unknown

# Accept build arguments for AI model configurations
ARG DEFAULT_LMSTUDIO_MODEL=local-model
ARG DEFAULT_OPENROUTER_MODEL=google/gemini-2.0-flash-exp:free

# Set working directory
WORKDIR /app

# Update packages and install security updates
RUN apk update && apk upgrade

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --omit=dev

# Copy application files
COPY src/ ./src/
COPY public/ ./public/
COPY menu.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S badai -u 1001 -G nodejs

# Change ownership of app directory
RUN chown -R badai:nodejs /app

# Switch to non-root user
USER badai

# Set environment variables
ENV NODE_ENV=production
ENV BUILD_VERSION=${BUILD_VERSION}
ENV BUILD_DATE=${BUILD_DATE}
ENV BUILD_COMMIT=${BUILD_COMMIT}
ENV DEFAULT_LMSTUDIO_MODEL=${DEFAULT_LMSTUDIO_MODEL}
ENV DEFAULT_OPENROUTER_MODEL=${DEFAULT_OPENROUTER_MODEL}

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Start the application
CMD ["npm", "start"]