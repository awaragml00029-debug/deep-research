FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Install dependencies based on the preferred package manager
COPY package.json pnpm-lock.yaml ./
RUN yarn global add pnpm && pnpm install --frozen-lockfile

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build arguments for customization
ARG BUILD_VARIANT=open
ARG MODAI_API_BASE_URL=https://generativelanguage.googleapis.com
ARG MODAI_THINKING_MODEL=gemini-2.0-flash-thinking-exp-01-21
ARG MODAI_NETWORKING_MODEL=gemini-2.0-flash-exp

# Set environment variables for the build
ENV NEXT_PUBLIC_BUILD_VARIANT=${BUILD_VARIANT}
ENV NEXT_PUBLIC_MODAI_API_BASE_URL=${MODAI_API_BASE_URL}
ENV NEXT_PUBLIC_MODAI_THINKING_MODEL=${MODAI_THINKING_MODEL}
ENV NEXT_PUBLIC_MODAI_NETWORKING_MODEL=${MODAI_NETWORKING_MODEL}

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED 1

RUN yarn run build:standalone

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

# Runtime arguments (can be overridden at runtime)
ARG MODAI_API_BASE_URL=https://generativelanguage.googleapis.com

ENV NODE_ENV=production
ENV NEXT_PUBLIC_BUILD_MODE=standalone
ENV MODAI_API_BASE_URL=${MODAI_API_BASE_URL}

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

EXPOSE 3000

# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/next-config-js/output
CMD ["node", "server.js"]