# Intentional Vulnerabilities for Security Testing

# had to make a seperate file coz semgrep was still detecting the commented out code

## Copy paste into index.js to test semgrep sast

```javascript
const { exec } = require("child_process");
```

## Vulnerability #1: eval() - Code Injection

```javascript
// INTENTIONAL VULNERABILITY: eval() - Code Injection
app.get("/eval", (req, res) => {
  const code = req.query.code || "1+1";
  try {
    const result = eval(code);
    res.json({ result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

## Vulnerability #2: Command Injection

```javascript
// INTENTIONAL VULNERABILITY: Command Injection
app.get("/ping", (req, res) => {
  const host = req.query.host || "localhost";
  exec(`ping -c 1 ${host}`, (error, stdout) => {
    if (error) {
      return res.status(500).json({ error: error.message });
    }
    res.json({ output: stdout });
  });
});
```
