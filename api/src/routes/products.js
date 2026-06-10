const express = require("express");
const db = require("../db");

const router = express.Router();

router.get("/", async (req, res, next) => {
  const { limit } = req.query;

  if (limit !== undefined) {
    const n = Number(limit);
    if (!Number.isInteger(n) || n <= 0) {
      return res.status(400).json({ error: "Le paramètre 'limit' doit être un entier positif" });
    }
  }

  try {
    const sql =
      "SELECT id, name, description, price_cents FROM products ORDER BY id" +
      (limit ? " LIMIT $1" : "");
    const result = await db.query(sql, limit ? [Number(limit)] : []);

    res.json({
      source: "database",
      data: result.rows,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
