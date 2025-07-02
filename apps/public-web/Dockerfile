# VibeBiz Public Web App - Secure Multi-stage Dockerfile
# Foundation+ stage container with security hardening

# Build stage
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Add security labels
LABEL maintainer="VibeBiz <security@vibebiz.dev>" \
      org.opencontainers.image.title="VibeBiz Public Web" \
      org.opencontainers.image.description="Next.js frontend for VibeBiz SaaS Template" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.vendor="VibeBiz" \
      org.opencontainers.image.licenses="Apache-2.0"

# Install security updates and required packages
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Copy package files for dependency installation
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/public-web/package.json ./apps/public-web/
COPY packages/types/package.json ./packages/types/

# Install dependencies
RUN npm install -g pnpm@10.12.4 && \
    pnpm config set registry https://registry.npmjs.org/ && \
    pnpm install --frozen-lockfile --prod=false

# Copy source code
COPY . .

# Build the application
RUN pnpm turbo build --filter=@vibebiz/public-web

# Production stage
FROM node:20-alpine AS runner

# Install security updates and dumb-init
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder --chown=nextjs:nodejs /app/apps/public-web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/public-web/.next/static ./apps/public-web/.next/static
COPY --from=builder --chown=nextjs:nodejs /app/apps/public-web/public ./apps/public-web/public

# Set proper permissions
RUN chmod -R 755 /app

# Switch to non-root user
USER nextjs

# Expose port (non-privileged)
EXPOSE 3000

# Set environment to production
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node apps/public-web/healthcheck.js

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "apps/public-web/server.js"]
