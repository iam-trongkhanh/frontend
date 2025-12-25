ARG NODE_VERSION=20
ARG ALPINE_VERSION=3.19
ARG NODE_IMAGE_SHA256=abc123...
ARG BUILD_DATE
ARG AUTHOR=devops@example.com
ARG DESCRIPTION="Production-ready Node.js application"
ARG LICENSE="MIT"
ARG VCS_REF
ARG VCS_URL=https://github.com/your-org/your-repo
ARG VERSION=1.0.0
ARG MyCompany="MyCompany"
ARG SOURCE_DATE_EPOCH


FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION}@sha256:{NODE_IMAGE_SHA256} AS base

RUN apk add --no-cache \ 
dumb-init \
ca-certificates \
tzdata \
&& rm -rf /var/cache/apk/* \
&& rm -rf /tmp/*

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
org.opencontainers.image.author="${AUTHOR}" \
org.opencontainers.image.description="${DESCRIPTION}" \
org.opencontainers.image.licenses="${LICENSE}" \
org.opencontainers.image.revision="${VCS_REF}" \
org.opencontainers.image.source="${VCS_URL}" \
org.opencontainers.image.title="myapp" \
org.opencontainers.image.version="${VERSION}" \
org.opencontainers.image.vendor="${MyCompany}" \
org.opencontainers.image.schema.version="1.0"

LABEL maintainer="${AUTHOR}" \
version="${VERSION}" \
description="${DESCRIPTION}"

ENV NODE_ENV=production \
TZ=UTC \
NODE_OPTIONS="--max-old-space-size=2048" \
SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}

FROM base AS dependencies

WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apk \
apk add --no-cache python3 \ 
make \
g++ \
pkgconfig && \
rm -rf /var/cache/apk/*

COPY --link package*.json ./

RUN --mount=type=cache,target=/root/.npm \
--mount=type=bind,source=package.json,target=package.json \
npm ci --only=production && \
npm cache clean --force


FROM base AS development

WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apk \
apk add --no-cache \
    python3 \
    make \
    g++ \
    pkgconfig \
&& rm -rf /var/cache/apk/*

COPY --link package*.json ./

RUN --mount=type=cache,target=/root/.npm \
      npm ci && \

COPY --link . .

RUN addgroup -g 1001 -S nodejs && \
adduser -S nextjs -u 1001 -G nodejs

USER nextjs

EXPOSE 3000

ENTRYPOINT [ "dumb-init", "--" ]

CMD [ "npm", "run", "dev" ]



FROM base AS builder

WORKDIR /app

COPY --from=dependencies --link /app/node_modules ./node_modules

COPY --link . .

ARG VERSION

ARG BUILD_DATE
ARG VCS_REF

RUN --mount=type=cache,target=/root/.npm \
--mount=type=cache,target=/app/.next/cache \
npm run build

RUN --mount=type=cache,target=/root/.npm \
    npm install -g @cyclonedx/cyclonedx-npm && \
    cyclonedx-npm --output-format json --output-file sbom.json && \
    cyclonedx-npm --output-format xml --output-file sbom.xml

RUN mkdir -p /app/public && \
mv sbom.json sbom.xml /app/public/   

RUN npm prune --production && \
npm cache clean --force


FROM base AS security-scan

WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache wget && \
    wget -qO - https://aquasecurity.github.io/trivy-repo/debian/public.key | \
    apk add --no-cache trivy

COPY --from=builder --link /app /app

RUN trivy filesystem --no-progress --severity CRITICAL,HIGH --exit-code 1 /app || \
(echo "Security scan failed! Fix critical vulnerabilities before deploying." && exit 1)


FROM base AS production

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001 -G nodejs

WORKDIR /app

COPY --from=builder --chown=nextjs:nodejs --link \
/app/.next ./.next

COPY --from=builder --chown=nextjs:nodejs --link \
    /app/node_modules ./node_modules

COPY --from=builder --chown=nextjs:nodejs --link \
    /app/package.json ./package.json

COPY --from=builder --chown=nextjs:nodejs --link \
    /app/public ./public

COPY --from=builder --chown=nextjs:nodejs --link \
    /app/public/sbom*.json ./public/

COPY --from=builder --chown=nextjs:nodejs --link \
    /app/public/sbom*.xml ./public/

RUN mkdir -p /app/.next/cache && \
chown -R nextjs:nodejs /app/.next && \
chmod -R 755 /app

USER nextjs

ENV NODE_ENV=production \
PORT=3000 \
HOSTNAME="0.0.0.0" \
NODE_OPTIONS="--max-old-space-size=2048"

STOPSIGNAL SIGTERM

EXPOSE 3000

HEALTHCHECK --interval=30s \
--timeout=5s \
--start-period=10s \
--retries=3 \
CMD node -e "const http = require('http');"

const options = { host: 'localhost', port: 3000, path: '/api/health', timeout: 2000 };

const request = http.request(options, (res) => {
      process.exit(res.statusCode === 200 ? 0 : 1);  });