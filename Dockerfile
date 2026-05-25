# ── Stage 1: Build Flutter Web ──────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

RUN flutter config --enable-web

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

RUN flutter precache --web

COPY . .

ARG BACKEND_URL=https://appacademia-production-be7e.up.railway.app
RUN flutter build web --release --base-href "/" \
    --dart-define=BACKEND_URL=${BACKEND_URL} && \
    ls -lah /app/build/web/

# ── Stage 2: Nginx ──────────────────────────────────────────────────────────
FROM nginx:stable-alpine

RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build/web /usr/share/nginx/html

RUN test -f /usr/share/nginx/html/index.html && echo "index.html OK" && \
    ls -lah /usr/share/nginx/html/

RUN printf 'server {\n\
    listen 8080;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    gzip on;\n\
    gzip_static on;\n\
    location = /index.html {\n\
        add_header Cache-Control "no-cache, no-store, must-revalidate";\n\
        add_header Pragma "no-cache";\n\
        add_header Expires "0";\n\
    }\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    location ~* \.(?:js|css|wasm|png|jpg|jpeg|gif|ico|svg|ttf|woff|woff2|json)$ {\n\
        expires 1y;\n\
        add_header Cache-Control "public, immutable";\n\
        try_files $uri =404;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

