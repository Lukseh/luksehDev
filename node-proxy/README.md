# Node.js Proxy Server

A minimal Express proxy server that bridges the Vue.js frontend with the .NET backend API.

## Purpose
- Handles CORS for cross-origin requests between frontend and backend
- Provides a unified API interface for the Vue.js application
- Acts as a middleware layer between frontend (port 5174) and backend (port 5188)

## Features
- **Health Check**: `/health` endpoint for service monitoring
- **Social API Proxy**: `/api/social/:username` for combined GitHub/LinkedIn data
- **Individual Service Proxies**: Separate endpoints for GitHub and LinkedIn
- **Error Handling**: Comprehensive error responses with helpful messages
- **CORS Support**: Configured for Vue.js development server

## Available Endpoints

### Health Check
```
GET /health
```
Returns server status and configuration info.

### Social Data (Combined)
```
GET /api/social/:username
```
Fetches both GitHub repositories and LinkedIn profile data.

### GitHub Repositories
```
GET /api/github/repos/:username
```
Fetches GitHub repositories for a specific user.

### LinkedIn Profile
```
GET /api/linkedin/profile/:profileId
```
Fetches LinkedIn profile information.

## Environment Variables
- `PORT`: Server port (default: 3000)
- `BACKEND_URL`: .NET backend URL (default: http://localhost:5188)

## Usage

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

## CORS Configuration
Configured to allow requests from:
- `http://localhost:5174` (Vite dev server)
- `http://localhost:4173` (Vite preview)
- `http://localhost:3000` (proxy server)

## Error Handling
- **503**: Backend service unavailable
- **500**: Proxy server errors
- **404**: Unknown API endpoints
- **Timeout**: 10-second request timeout to backend

## Integration
This proxy server works with:
- **Frontend**: Vue.js + Vuetify (port 5174)
- **Backend**: .NET Web API (port 5188)
- **APIs**: GitHub API, LinkedIn API (via backend)
