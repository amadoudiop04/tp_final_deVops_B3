/**
 * Tests d'intégration — /products contre une vraie base PostgreSQL.
 *
 * MOMENT CLÉ (incident/rollback) :
 *   1. Ce test PASSE en conditions normales (DB saine, table products peuplée).
 *   2. Ce test ÉCHOUE si la table products est absente (simulation d'incident).
 *   3. Ce test REPASSE après restauration via database/init.sql (rollback).
 *
 * Ce cycle est rejoué automatiquement dans le job `tests-integration` de la CI.
 * Requis : variable d'environnement DATABASE_URL pointant vers une vraie instance PostgreSQL.
 */
const request = require("supertest");
const app = require("../src/app");
const db = require("../src/db");

afterAll(async () => {
  await db.getPool().end();
});

describe("GET /products - intégration (vraie DB)", () => {
  test("retourne 200 avec source=database", async () => {
    const response = await request(app).get("/products");

    expect(response.status).toBe(200);
    expect(response.body.source).toBe("database");
  });

  test("le tableau data contient au moins un produit", async () => {
    const response = await request(app).get("/products");

    expect(Array.isArray(response.body.data)).toBe(true);
    expect(response.body.data.length).toBeGreaterThan(0);
  });

  test("chaque produit a id, name, description et price_cents > 0", async () => {
    const response = await request(app).get("/products");

    for (const product of response.body.data) {
      expect(typeof product.id).toBe("number");
      expect(typeof product.name).toBe("string");
      expect(typeof product.description).toBe("string");
      expect(typeof product.price_cents).toBe("number");
      expect(product.price_cents).toBeGreaterThan(0);
    }
  });

  test("contient les 3 produits de référence de init.sql", async () => {
    const response = await request(app).get("/products");
    const names = response.body.data.map((p) => p.name);

    expect(names).toContain("Clavier compact");
    expect(names).toContain("Souris precision");
    expect(names).toContain("Ecran 24 pouces");
  });

  test("les produits sont triés par id croissant", async () => {
    const response = await request(app).get("/products");
    const ids = response.body.data.map((p) => p.id);
    const sorted = [...ids].sort((a, b) => a - b);

    expect(ids).toEqual(sorted);
  });

  test("le paramètre limit=1 retourne exactement un produit", async () => {
    const response = await request(app).get("/products?limit=1");

    expect(response.status).toBe(200);
    expect(response.body.data).toHaveLength(1);
  });
});
