const express = require("express");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Root endpoint
app.get("/", (req, res) => {
  res.json({
    message: "App is running",
    version: "1.0.0",
  });
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
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

// vulnerabilities here

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
