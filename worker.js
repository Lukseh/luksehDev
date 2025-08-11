import { getAssetFromKV } from '@cloudflare/kv-asset-handler';

// Simple Cloudflare Worker to serve Vue.js frontend and handle API routes
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Handle API routes - proxy to GitHub API
    if (path.startsWith('/api/')) {
      return handleApiRequest(request, path);
    }

    // Serve static files from Vue build
    try {
      return await getAssetFromKV(
        {
          request,
          waitUntil: ctx.waitUntil.bind(ctx),
        },
        {
          ASSET_NAMESPACE: env.__STATIC_CONTENT,
          ASSET_MANIFEST: env.__STATIC_CONTENT_MANIFEST,
          // Serve index.html for SPA routes
          mapRequestToAsset: (req) => {
            const url = new URL(req.url);
            if (url.pathname.startsWith('/api/')) {
              return req;
            }
            // For SPA routing, serve index.html for non-asset requests
            if (!url.pathname.includes('.') || url.pathname === '/') {
              url.pathname = '/index.html';
            }
            return new Request(url.toString(), req);
          },
        }
      );
    } catch (e) {
      // If asset not found, serve index.html for SPA routing
      try {
        const indexRequest = new Request(new URL('/index.html', request.url).toString(), request);
        return await getAssetFromKV(
          {
            request: indexRequest,
            waitUntil: ctx.waitUntil.bind(ctx),
          },
          {
            ASSET_NAMESPACE: env.__STATIC_CONTENT,
            ASSET_MANIFEST: env.__STATIC_CONTENT_MANIFEST,
          }
        );
      } catch (indexError) {
        return new Response('Not Found', { status: 404 });
      }
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
