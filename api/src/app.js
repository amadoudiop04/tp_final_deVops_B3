const express = require("express");
const cors = require("cors");
const logger = require("./middleware/logger");
const healthRoutes = require("./routes/health");
const productRoutes = require("./routes/products");
const db = require("./db");

const app = express();

app.use(cors());
app.use(express.json());
app.use(logger);

app.get("/", (req, res) => {
  res.json({
    name: "ShopLite API",
    version: process.env.APP_VERSION || "dev",
    endpoints: ["/health", "/ready", "/products"],
  });
});

// GET /ready — vérifie que l'API et PostgreSQL sont prêts (utilisé par le healthcheck Compose)
app.get("/ready", async (req, res) => {
  try {
    await db.query("SELECT 1");
    res.json({ status: "ready", database: "ok" });
  } catch {
    res.status(503).json({ status: "not ready", database: "error" });
  }
});

app.use("/health", healthRoutes);
app.use("/products", productRoutes);

app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});

app.use((err, req, res, next) => {
  console.error(
    JSON.stringify({
      level: "error",
      request_id: req.requestId || null,
      message: err.message,
      timestamp: new Date().toISOString(),
    })
  );
  res.status(500).json({ error: "Internal server error" });
});

module.exports = app;
