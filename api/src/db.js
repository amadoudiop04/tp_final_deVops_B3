const { Pool } = require("pg");

let pool;

function getPool() {
  if (!pool) {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
    });
  }

  return pool;
}

async function query(sql, params = []) {
  return getPool().query(sql, params);
}

module.exports = {
  getPool,
  query,
};
