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

// eval() func ki VULNERABILITY - should be caught by ESLint plugin
// app.get("/eval", (req, res) => {
//   const code = req.query.code || "1+1";
//   try {
//     const result = eval(code); // vulnerability
//     res.json({ result });
//   } catch (error) {
//     res.status(400).json({ error: error.message });
//   }
// });
//
// // Dusri VULNERABILITY - Command injection
// const { exec } = require("child_process");
// app.get("/ping", (req, res) => {
//   const host = req.query.host || "localhost";
//   // No input sanitization - command injection vulnerability
//   exec(`ping -c 1 ${host}`, (error, stdout) => {
//     if (error) {
//       return res.status(500).json({ error: error.message });
//     }
//     res.json({ output: stdout });
//   });
// });

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
