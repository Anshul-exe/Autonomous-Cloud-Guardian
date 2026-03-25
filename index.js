const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    uptime: process.uptime(),
    timestamp: new Date(),
  });
});

// Dummy load endpoint
app.get("/load", (req, res) => {
  let sum = 0;
  for (let i = 0; i < 1e7; i++) {
    sum += i;
  }
  res.json({ message: "CPU load simulated", result: sum });
});

// Root endpoint
app.get("/", (req, res) => {
  res.send("App Running");
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
