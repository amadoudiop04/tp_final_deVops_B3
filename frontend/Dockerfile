FROM nginx:1.27-alpine

ARG BUILD_VERSION=dev
ARG GIT_SHA=unknown
ARG BUILD_DATE=unknown

LABEL org.opencontainers.image.title="shoplite-frontend" \
      org.opencontainers.image.description="ShopLite — Frontend Nginx" \
      org.opencontainers.image.version="${BUILD_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.created="${BUILD_DATE}"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY src /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -qO- http://127.0.0.1/ || exit 1
