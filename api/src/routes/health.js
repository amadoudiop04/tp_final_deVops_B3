const express = require("express");
const db = require("../db");

const router = express.Router();

// GET /health — état détaillé : API, DB, version, timestamp
router.get("/", async (req, res) => {
  let dbStatus = "ok";
  let httpStatus = 200;

  try {
    await db.query("SELECT 1");
  } catch {
    dbStatus = "error";
    httpStatus = 503;
  }

  res.status(httpStatus).json({
    status: httpStatus === 200 ? "ok" : "error",
    service: "shoplite-api",
    checks: {
      api: "ok",
      database: dbStatus,
    },
    version: process.env.APP_VERSION || "dev",
    uptime_seconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
