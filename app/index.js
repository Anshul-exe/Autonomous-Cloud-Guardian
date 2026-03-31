const express = require("express");
const { exec } = require("child_process");

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

// INTENTIONAL VULNERABILITY #1: eval() - Code Injection
// This should be caught by Semgrep SAST
// app.get("/eval", (req, res) => {
//   const code = req.query.code || "1+1";
//   try {
//     const result = eval(code); // eslint-disable-line no-eval
//     res.json({ result });
//   } catch (error) {
//     res.status(400).json({ error: error.message });
//   }
// });
//
// // INTENTIONAL VULNERABILITY #2: Command Injection
// // No input sanitization - should be caught by security scanners
// app.get("/ping", (req, res) => {
//   const host = req.query.host || "localhost";
//   exec(`ping -c 1 ${host}`, (error, stdout) => { // eslint-disable-line security/detect-child-process
//     if (error) {
//       return res.status(500).json({ error: error.message });
//     }
//     res.json({ output: stdout });
//   });
// });

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
