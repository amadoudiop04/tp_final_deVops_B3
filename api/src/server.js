require("dotenv").config();

const app = require("./app");

const port = Number(process.env.API_PORT || process.env.PORT || 3000);

app.listen(port, "0.0.0.0", () => {
  console.log(
    JSON.stringify({
      level: "info",
      message: "ShopLite API started",
      port,
      timestamp: new Date().toISOString(),
    })
  );
});
