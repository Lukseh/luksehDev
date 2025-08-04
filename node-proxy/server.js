import express from 'express';
import cors from 'cors';
import axios from 'axios';

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5188';

// Middleware
app.use(cors({
  origin: ['http://localhost:5173', 'http://localhost:5174', 'http://localhost:4173', 'http://localhost:3000'],
  credentials: true
}));
app.use(express.json());

// Root route - redirect to frontend or show API info
app.get('/', (req, res) => {
  res.json({
    message: 'lukseh.dev Node.js Proxy Server',
    version: '1.0.0',
    services: {
      frontend: 'http://localhost:5174',
      backend: BACKEND_URL,
      proxy: `http://localhost:${PORT}`
    },
    endpoints: {
      health: '/health',
      social: '/api/social/:username',
      github: '/api/github/repos/:username',
      linkedin: '/api/linkedin/profile/:profileId'
    },
    status: 'running'
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    services: {
      proxy: 'running',
      backend: BACKEND_URL,
      frontend: 'Vue.js + Vuetify'
    }
  });
});

// Proxy endpoint for social data
app.get('/api/social/:username', async (req, res) => {
  try {
    const { username } = req.params;
    console.log(`📡 Proxying request for user: ${username}`);
    
    const response = await axios.get(`${BACKEND_URL}/api/social/${username}`, {
      timeout: 10000,
      headers: {
        'User-Agent': 'lukseh-dev-vue-proxy'
      }
    });
    
    console.log(`✅ Backend responded with status: ${response.status}`);
    
    res.json({
      success: true,
      data: response.data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error(`❌ Proxy error:`, error.message);
    
    if (error.code === 'ECONNREFUSED') {
      res.status(503).json({
        success: false,
        error: 'Backend service unavailable. Make sure the .NET API is running on port 5188.',
        details: error.message
      });
    } else if (error.response) {
      res.status(error.response.status).json({
        success: false,
        error: `Backend returned ${error.response.status}: ${error.response.statusText}`,
        details: error.message
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Proxy server error',
        details: error.message
      });
    }
  }
});

// GitHub proxy endpoint
app.get('/api/github/repos/:username', async (req, res) => {
  try {
    const { username } = req.params;
    const response = await axios.get(`${BACKEND_URL}/api/github/repos/${username}`);
    
    res.json({
      success: true,
      data: response.data
    });
  } catch (error) {
    console.error('GitHub proxy error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch GitHub data',
      details: error.message
    });
  }
});

// LinkedIn proxy endpoint
app.get('/api/linkedin/profile/:profileId', async (req, res) => {
  try {
    const { profileId } = req.params;
    const response = await axios.get(`${BACKEND_URL}/api/linkedin/profile/${profileId}`);
    
    res.json({
      success: true,
      data: response.data
    });
  } catch (error) {
    console.error('LinkedIn proxy error:', error.message);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch LinkedIn data',
      details: error.message
    });
  }
});

// Catch-all for API routes
app.use('/api/*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'API endpoint not found',
    availableEndpoints: [
      'GET /api/social/:username',
      'GET /api/github/repos/:username',
      'GET /api/linkedin/profile/:profileId',
      'GET /health'
    ]
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Node.js proxy server running on http://localhost:${PORT}`);
  console.log(`📡 Proxying to backend: ${BACKEND_URL}`);
  console.log(`🎨 Frontend: Vue.js + Vuetify`);
  console.log(`🔍 Health check: http://localhost:${PORT}/health`);
});

export default app;
