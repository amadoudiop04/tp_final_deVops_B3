module.exports = function logger(req, res, next) {
  const startedAt = Date.now();

  res.on("finish", () => {
    console.log(
      JSON.stringify({
        level: "info",
        method: req.method,
        path: req.originalUrl,
        status: res.statusCode,
        duration_ms: Date.now() - startedAt,
        timestamp: new Date().toISOString(),
      })
    );
  });

  next();
};
