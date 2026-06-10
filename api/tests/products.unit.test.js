const request = require("supertest");

jest.mock("../src/db");
const db = require("../src/db");
const app = require("../src/app");

afterEach(() => {
  jest.resetAllMocks();
});

describe("GET /products - tests unitaires", () => {
  test("retourne les produits depuis la DB mockée", async () => {
    const mockRows = [
      { id: 1, name: "Clavier compact", description: "Clavier mécanique", price_cents: 5990 },
      { id: 2, name: "Souris precision", description: "Souris ergonomique", price_cents: 3490 },
    ];
    db.query.mockResolvedValueOnce({ rows: mockRows });

    const response = await request(app).get("/products");

    expect(response.status).toBe(200);
    expect(response.body.source).toBe("database");
    expect(response.body.data).toHaveLength(2);
    expect(response.body.data[0]).toMatchObject({
      id: 1,
      name: "Clavier compact",
      price_cents: 5990,
    });
  });

  test("retourne un tableau vide si la DB est vide", async () => {
    db.query.mockResolvedValueOnce({ rows: [] });

    const response = await request(app).get("/products");

    expect(response.status).toBe(200);
    expect(response.body.source).toBe("database");
    expect(response.body.data).toHaveLength(0);
  });

  test("chaque produit a les quatre champs requis avec les bons types", async () => {
    db.query.mockResolvedValueOnce({
      rows: [{ id: 1, name: "Test", description: "Desc", price_cents: 100 }],
    });

    const response = await request(app).get("/products");
    const product = response.body.data[0];

    expect(typeof product.id).toBe("number");
    expect(typeof product.name).toBe("string");
    expect(typeof product.description).toBe("string");
    expect(typeof product.price_cents).toBe("number");
  });

  test("retourne 500 si la DB plante", async () => {
    db.query.mockRejectedValueOnce(new Error("DB connection refused"));

    const response = await request(app).get("/products");

    expect(response.status).toBe(500);
    expect(response.body.error).toBe("Internal server error");
  });

  describe("validation du paramètre limit", () => {
    test("retourne 400 si limit est une chaîne non numérique", async () => {
      const response = await request(app).get("/products?limit=abc");

      expect(response.status).toBe(400);
      expect(response.body).toHaveProperty("error");
    });

    test("retourne 400 si limit est négatif", async () => {
      const response = await request(app).get("/products?limit=-5");

      expect(response.status).toBe(400);
    });

    test("retourne 400 si limit est zéro", async () => {
      const response = await request(app).get("/products?limit=0");

      expect(response.status).toBe(400);
    });

    test("accepte limit=2 et appelle la DB avec LIMIT", async () => {
      db.query.mockResolvedValueOnce({
        rows: [{ id: 1, name: "Clavier compact", description: "Desc", price_cents: 5990 }],
      });

      const response = await request(app).get("/products?limit=2");

      expect(response.status).toBe(200);
      expect(db.query).toHaveBeenCalledWith(
        expect.stringContaining("LIMIT"),
        expect.arrayContaining([2])
      );
    });
  });
});
