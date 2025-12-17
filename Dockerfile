# syntax=docker/dockerfile:1.7

FROM node:20.18.0-alpine AS builder
WORKDIR /app

ARG NODE_ENV=production
ARG VITE_API_URL=http://localhost:3001
ENV NODE_ENV=$NODE_ENV

COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
  if [ -f package-lock.json ]; then \
    npm ci --no-fund --no-audit; \
  else \
    npm install --no-fund --no-audit; \
  fi

COPY . .

RUN VITE_API_URL=$VITE_API_URL npm run build

FROM nginx:1.27.2-alpine AS runtime

RUN addgroup -S app -g 1001 && adduser -S -D -H -u 1001 -G app app
RUN sed -i 's/^user .*/user app;/' /etc/nginx/nginx.conf \
  && rm -f /etc/nginx/conf.d/default.conf

COPY --from=builder /app/dist /usr/share/nginx/html

RUN cat > /etc/nginx/conf.d/default.conf <<'EOF'
server {
  listen 8080;
  server_name _;
  root /usr/share/nginx/html;
  index index.html;
  location / {
    try_files $uri $uri/ /index.html;
  }
}
EOF

RUN chown -R app:app /usr/share/nginx/html /var/cache/nginx /var/run /var/log/nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -qO- http://127.0.0.1:8080/ || exit 1

USER app

LABEL org.opencontainers.image.title="mern-frontend" \
      org.opencontainers.image.description="React + Vite frontend static build" \
      org.opencontainers.image.version="0.1.0" \
      org.opencontainers.image.source="local/mern-frontend"

CMD ["nginx", "-g", "daemon off;"]
