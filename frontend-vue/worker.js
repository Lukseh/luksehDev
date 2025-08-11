// Simple Cloudflare Worker to serve Vue.js frontend and handle API routes
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Handle API routes - proxy to GitHub API
    if (path.startsWith('/api/')) {
      return handleApiRequest(request, path);
    }

    // For non-API requests, serve from Pages deployment
    // Replace 'your-pages-subdomain' with your actual Pages subdomain
    const pagesUrl = new URL(request.url);
    pagesUrl.hostname = 'lukseh-dev.pages.dev'; // Your Pages subdomain
    
    try {
      const response = await fetch(pagesUrl.toString());
      return response;
    } catch (error) {
      return new Response('Service Unavailable', { status: 503 });
    }
  }
};

async function handleApiRequest(request, path) {
  // Extract the GitHub API path
  const githubPath = path.replace('/api/', '');
  const githubUrl = `https://api.github.com/${githubPath}`;
  
  // Forward the request to GitHub API
  const githubRequest = new Request(githubUrl, {
    method: request.method,
    headers: {
      'User-Agent': 'Lukseh-Portfolio-Worker/1.0',
      'Accept': 'application/vnd.github.v3+json'
    }
  });

  try {
    const response = await fetch(githubRequest);
    const data = await response.text();
    
    return new Response(data, {
      status: response.status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'API request failed' }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}
