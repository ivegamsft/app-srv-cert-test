const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  // Extract SSL/TLS information
  const protocol = req.protocol;
  const isSecure = req.secure || req.headers['x-forwarded-proto'] === 'https';
  const tlsVersion = req.socket.getProtocol ? req.socket.getProtocol() : 'N/A';
  
  // DNS and host information
  const hostname = req.hostname;
  const host = req.get('host');
  const forwardedHost = req.get('x-forwarded-host');
  const originalHost = req.get('x-original-host');
  
  // Certificate information (when available via Azure headers)
  const clientCertThumbprint = req.get('X-ARR-ClientCert');
  const sslCipher = req.get('X-ARR-SSL-Cipher') || 'N/A';
  
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>SSL Certificate & DNS Info</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          max-width: 900px;
          margin: 30px auto;
          padding: 20px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
        }
        .container {
          background: rgba(255, 255, 255, 0.1);
          border-radius: 10px;
          padding: 40px;
          backdrop-filter: blur(10px);
        }
        h1 { 
          margin-top: 0; 
          border-bottom: 2px solid rgba(255, 255, 255, 0.3);
          padding-bottom: 15px;
        }
        h2 {
          margin-top: 25px;
          font-size: 1.3em;
          border-left: 4px solid #ffd700;
          padding-left: 15px;
        }
        .info { 
          background: rgba(255, 255, 255, 0.2); 
          padding: 12px 15px; 
          border-radius: 5px; 
          margin: 8px 0;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .info strong { 
          min-width: 180px;
          color: #ffd700;
        }
        code { 
          background: rgba(0, 0, 0, 0.3); 
          padding: 4px 10px; 
          border-radius: 4px;
          font-size: 0.9em;
          word-break: break-all;
        }
        .secure { color: #00ff00; }
        .insecure { color: #ff6b6b; }
        .badge {
          display: inline-block;
          padding: 4px 12px;
          border-radius: 12px;
          font-size: 0.85em;
          font-weight: bold;
        }
        .badge.success { background: #00ff00; color: #000; }
        .badge.warning { background: #ffd700; color: #000; }
        .footer {
          margin-top: 30px;
          padding-top: 20px;
          border-top: 1px solid rgba(255, 255, 255, 0.2);
          text-align: center;
          font-size: 0.9em;
          opacity: 0.8;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>� SSL Certificate & DNS Binding Information</h1>
        
        <h2>🌐 Connection Security</h2>
        <div class="info">
          <strong>Protocol:</strong>
          <span class="${isSecure ? 'secure' : 'insecure'}">
            ${isSecure ? 'HTTPS ✅' : 'HTTP ⚠️'}
          </span>
        </div>
        <div class="info">
          <strong>Secure Connection:</strong>
          <span class="badge ${isSecure ? 'success' : 'warning'}">
            ${isSecure ? 'SECURED' : 'NOT SECURED'}
          </span>
        </div>
        <div class="info">
          <strong>TLS Version:</strong>
          <code>${tlsVersion}</code>
        </div>
        <div class="info">
          <strong>SSL Cipher:</strong>
          <code>${sslCipher}</code>
        </div>
        
        <h2>🔗 DNS Bindings</h2>
        <div class="info">
          <strong>Hostname:</strong>
          <code>${hostname}</code>
        </div>
        <div class="info">
          <strong>Host Header:</strong>
          <code>${host}</code>
        </div>
        <div class="info">
          <strong>Forwarded Host:</strong>
          <code>${forwardedHost || 'Not set'}</code>
        </div>
        <div class="info">
          <strong>Original Host:</strong>
          <code>${originalHost || 'Not set'}</code>
        </div>
        
        <h2>📋 Request Details</h2>
        <div class="info">
          <strong>Request URL:</strong>
          <code>${req.protocol}://${req.get('host')}${req.originalUrl}</code>
        </div>
        <div class="info">
          <strong>Client IP:</strong>
          <code>${req.get('x-forwarded-for') || req.socket.remoteAddress || 'Unknown'}</code>
        </div>
        <div class="info">
          <strong>User Agent:</strong>
          <code>${req.get('user-agent') || 'N/A'}</code>
        </div>
        <div class="info">
          <strong>Timestamp:</strong>
          <code>${new Date().toISOString()}</code>
        </div>
        
        ${clientCertThumbprint ? `
        <h2>📜 Client Certificate</h2>
        <div class="info">
          <strong>Certificate Present:</strong>
          <span class="secure">Yes ✅</span>
        </div>
        ` : ''}
        
        <div class="footer">
          <p>Azure App Service | Node.js ${process.version}</p>
        </div>
      </div>
    </body>
    </html>
  `);
});

// API endpoint example
app.get('/api/info', (req, res) => {
  res.json({
    application: 'Azure App Service Demo',
    version: '1.0.0',
    nodejs: process.version,
    platform: process.platform,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Not Found',
    path: req.path 
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// Start server
app.listen(port, () => {
  console.log(`🚀 Server running on port ${port}`);
  console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  process.exit(0);
});
