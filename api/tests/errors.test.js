const request = require("supertest");

jest.mock("../src/db");
const db = require("../src/db");
const app = require("../src/app");

afterEach(() => {
  jest.resetAllMocks();
});

describe("Erreurs HTTP — scénarios contrôlés", () => {
  describe("404 — Route inexistante", () => {
    test("GET /inexistant retourne 404 avec message d'erreur JSON", async () => {
      const response = await request(app).get("/inexistant");

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty("error", "Route not found");
    });

    test("GET /api/inexistant retourne 404", async () => {
      const response = await request(app).get("/api/inexistant");

      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty("error");
    });

    test("POST /products retourne 404 (méthode non supportée)", async () => {
      const response = await request(app).post("/products").send({});

      expect(response.status).toBe(404);
    });

    test("DELETE /health retourne 404", async () => {
      const response = await request(app).delete("/health");

      expect(response.status).toBe(404);
    });
  });

  describe("400 — Paramètre invalide", () => {
    test("GET /products?limit=abc retourne 400", async () => {
      const response = await request(app).get("/products?limit=abc");

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty("error");
      expect(typeof response.body.error).toBe("string");
    });

    test("GET /products?limit=-1 retourne 400", async () => {
      const response = await request(app).get("/products?limit=-1");

      expect(response.status).toBe(400);
    });

    test("GET /products?limit=3.5 retourne 400 (décimal non autorisé)", async () => {
      const response = await request(app).get("/products?limit=3.5");

      expect(response.status).toBe(400);
    });
  });

  describe("500 — Erreur interne serveur", () => {
    test("GET /products retourne 500 si la DB plante", async () => {
      db.query.mockRejectedValueOnce(new Error("FATAL: database unavailable"));

      const response = await request(app).get("/products");

      expect(response.status).toBe(500);
      expect(response.body.error).toBe("Internal server error");
    });

    test("la réponse 500 ne divulgue pas les détails internes", async () => {
      db.query.mockRejectedValueOnce(new Error("password authentication failed for user shoplite"));

      const response = await request(app).get("/products");

      expect(response.status).toBe(500);
      const body = JSON.stringify(response.body);
      expect(body).not.toContain("password");
      expect(body).not.toContain("stack");
      expect(body).not.toContain("shoplite");
    });
  });

  describe("Format des réponses d'erreur", () => {
    test("toutes les erreurs retournent du JSON valide", async () => {
      const response = await request(app).get("/route-inconnue");

      expect(response.headers["content-type"]).toMatch(/application\/json/);
      expect(() => JSON.parse(JSON.stringify(response.body))).not.toThrow();
    });

    test("le corps d'erreur contient toujours la clé 'error'", async () => {
      const r404 = await request(app).get("/nonexistent");
      expect(r404.body).toHaveProperty("error");

      db.query.mockRejectedValueOnce(new Error("DB down"));
      const r500 = await request(app).get("/products");
      expect(r500.body).toHaveProperty("error");
    });
  });
});
