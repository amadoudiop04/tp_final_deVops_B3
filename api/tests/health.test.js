const request = require("supertest");

jest.mock("../src/db");
const db = require("../src/db");
const app = require("../src/app");

afterEach(() => {
  jest.resetAllMocks();
});

describe("GET /", () => {
  test("retourne le nom et la version de l'API", async () => {
    const response = await request(app).get("/");

    expect(response.status).toBe(200);
    expect(response.body.name).toBe("ShopLite API");
    expect(response.body.version).toBe("0.1.0");
    expect(Array.isArray(response.body.endpoints)).toBe(true);
  });
});

describe("GET /health", () => {
  test("retourne 200 et status ok quand la DB est disponible", async () => {
    db.query.mockResolvedValueOnce({ rows: [{ "?column?": 1 }] });

    const response = await request(app).get("/health");

    expect(response.status).toBe(200);
    expect(response.body.status).toBe("ok");
    expect(response.body.service).toBe("shoplite-api");
    expect(response.body.checks.api).toBe("ok");
    expect(response.body.checks.database).toBe("ok");
    expect(response.body.timestamp).toBeDefined();
  });

  test("retourne 503 et status error quand la DB est indisponible", async () => {
    db.query.mockRejectedValueOnce(new Error("Connection refused"));

    const response = await request(app).get("/health");

    expect(response.status).toBe(503);
    expect(response.body.status).toBe("error");
    expect(response.body.checks.api).toBe("ok");
    expect(response.body.checks.database).toBe("error");
  });

  test("la réponse contient toujours un timestamp ISO 8601", async () => {
    db.query.mockResolvedValueOnce({ rows: [] });

    const response = await request(app).get("/health");
    const ts = new Date(response.body.timestamp);

    expect(isNaN(ts.getTime())).toBe(false);
  });
});
