# =============================================================================
# Dockerfile — task_manager_flutter (Flutter Web + Nginx)
# =============================================================================
# Build:    docker build --build-arg BACKEND_URL=<url> -t appacademia-flutter-cliente .
# Run:      docker run -p 8080:8080 appacademia-flutter-cliente
# =============================================================================

# ── Stage 1: Build Flutter Web ────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Enable web target
RUN flutter config --enable-web

# Cache dependencies
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Precache web SDK
RUN flutter precache --web

# Copy full source
COPY . .

# Cache buster — atualizar data para forçar rebuild no Railway
RUN echo "build-2026-06-15-v1-force-rebuild"

# Build with configurable backend URL
ARG BACKEND_URL=https://appacademia-production-be7e.up.railway.app
RUN echo "Building with BACKEND_URL=${BACKEND_URL}" && \
    flutter build web --release --base-href "/" \
        --dart-define=BACKEND_URL=${BACKEND_URL} && \
    echo "✅ Build OK" && \
    ls -lah /app/build/web/

# ── Stage 2: Serve with Nginx ─────────────────────────────────────────────────
FROM nginx:stable-alpine

# Remove default static files
RUN rm -rf /usr/share/nginx/html/*

# Copy Flutter web build
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Verify artifacts
RUN test -f /usr/share/nginx/html/index.html && echo "✅ index.html OK" || exit 1; \
    ls -lah /usr/share/nginx/html/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
