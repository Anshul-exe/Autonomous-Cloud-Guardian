const express = require("express");
const os = require("os");

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

// Hello endpoint
app.get("/hello", (req, res) => {
  res.json({
    message: "hello world!",
    timestamp: new Date(),
  });
});

// CPU load endpoint with realtime stats
app.get("/load", (req, res) => {
  const cpus = os.cpus();

  let totalIdle = 0,
    totalTick = 0;
  cpus.forEach((cpu) => {
    const times = cpu.times;
    totalTick += times.user + times.nice + times.sys + times.idle + times.irq;
    totalIdle += times.idle;
  });

  const cpuUsage = ((1 - totalIdle / totalTick) * 100).toFixed(2);
  const loadAvg = os.loadavg();

  res.json({
    cpu: {
      cores: cpus.length,
      usage: `${cpuUsage}%`,
      load_average: {
        "1min": loadAvg[0].toFixed(2),
        "5min": loadAvg[1].toFixed(2),
        "15min": loadAvg[2].toFixed(2),
      },
    },
    memory: {
      total: `${(os.totalmem() / 1024 / 1024 / 1024).toFixed(2)} GB`,
      free: `${(os.freemem() / 1024 / 1024 / 1024).toFixed(2)} GB`,
      used_percent: `${((1 - os.freemem() / os.totalmem()) * 100).toFixed(2)}%`,
    },
    timestamp: new Date(),
  });
});

// vulnerabilities here below

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
