const crypto = require("crypto");

// Champs à masquer dans les logs pour ne pas exposer de données sensibles
const SENSITIVE_FIELDS = ["password", "token", "secret", "authorization", "cookie"];

function sanitizeHeaders(headers) {
  const safe = { ...headers };
  for (const field of SENSITIVE_FIELDS) {
    if (safe[field]) safe[field] = "[MASKED]";
  }
  return safe;
}

function getLevel(statusCode) {
  if (statusCode >= 500) return "error";
  if (statusCode >= 400) return "warn";
  return "info";
}

module.exports = function logger(req, res, next) {
  const requestId = crypto.randomUUID();
  const startedAt = Date.now();

  // Propagation du request_id dans la réponse
  req.requestId = requestId;
  res.setHeader("X-Request-Id", requestId);

  res.on("finish", () => {
    const duration = Date.now() - startedAt;
    const level = getLevel(res.statusCode);

    const entry = {
      level,
      request_id: requestId,
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      duration_ms: duration,
      timestamp: new Date().toISOString(),
    };

    // Niveau DEBUG : ajouter les headers sanitisés si LOG_LEVEL=debug
    if (process.env.LOG_LEVEL === "debug") {
      entry.headers = sanitizeHeaders(req.headers);
    }

    console.log(JSON.stringify(entry));
  });

  next();
};
