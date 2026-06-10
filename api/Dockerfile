FROM node:20-alpine AS deps

WORKDIR /app

# Copier uniquement les manifestes pour profiter du cache Docker
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV API_PORT=3000
# Évite les crashs silencieux en production
ENV NODE_OPTIONS="--max-old-space-size=512"

# Copier node_modules depuis le stage deps (pas de npm dans l'image finale)
COPY --from=deps /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./

# Durcissement sécurité 
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 --ingroup nodejs appuser \
    && chown -R appuser:nodejs /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3000/health || exit 1

# Utiliser exec form + signal handling propre
CMD ["node", "--enable-source-maps", "src/server.js"]