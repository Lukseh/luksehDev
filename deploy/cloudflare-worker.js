// Cloudflare Worker for lukseh.dev API
// Handles GitHub API requests and serves as a backend for the portfolio

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Enable CORS for all requests
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };

    // Handle CORS preflight requests
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: corsHeaders,
      });
    }

    // Root endpoint
    if (path === '/' || path === '') {
      const response = {
        service: 'lukseh.dev Cloudflare Worker API',
        version: '1.0.0',
        status: 'running',
        endpoints: {
          social: '/api/social/{username}',
          github: '/api/github/repos/{username}',
        },
        timestamp: new Date().toISOString(),
      };

      return new Response(JSON.stringify(response, null, 2), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      });
    }

    // Health check endpoint
    if (path === '/health') {
      const response = {
        status: 'healthy',
        timestamp: new Date().toISOString(),
        service: 'Cloudflare Worker',
      };

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      });
    }

    // GitHub repos endpoint
    const githubReposMatch = path.match(/^\/api\/github\/repos\/([^\/]+)$/);
    if (githubReposMatch && request.method === 'GET') {
      const username = githubReposMatch[1];
      return await handleGitHubRepos(username, corsHeaders);
    }

    // Social data endpoint (GitHub only)
    const socialMatch = path.match(/^\/api\/social\/([^\/]+)$/);
    if (socialMatch && request.method === 'GET') {
      const username = socialMatch[1];
      return await handleSocialData(username, corsHeaders);
    }

    // GitHub releases endpoint
    const releasesMatch = path.match(/^\/api\/github\/repos\/([^\/]+)\/([^\/]+)\/releases$/);
    if (releasesMatch && request.method === 'GET') {
      const [, username, repo] = releasesMatch;
      return await handleGitHubReleases(username, repo, corsHeaders);
    }

    // 404 for unknown routes
    return new Response(
      JSON.stringify({
        error: 'Not Found',
        message: 'The requested endpoint does not exist.',
        availableEndpoints: [
          'GET /',
          'GET /health',
          'GET /api/social/{username}',
          'GET /api/github/repos/{username}',
          'GET /api/github/repos/{username}/{repo}/releases',
        ],
      }),
      {
        status: 404,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  },
};

// Handle GitHub repositories
async function handleGitHubRepos(username, corsHeaders) {
  try {
    const response = await fetch(
      `https://api.github.com/users/${username}/repos?sort=updated&per_page=50&type=all`,
      {
        headers: {
          'User-Agent': 'lukseh-dev-cloudflare-worker',
        },
      }
    );

    if (!response.ok) {
      throw new Error(`GitHub API returned ${response.status}`);
    }

    const data = await response.text();

    return new Response(data, {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: 'GitHub API Error',
        message: error.message,
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  }
}

// Handle GitHub releases
async function handleGitHubReleases(username, repo, corsHeaders) {
  try {
    const response = await fetch(
      `https://api.github.com/repos/${username}/${repo}/releases?per_page=5`,
      {
        headers: {
          'User-Agent': 'lukseh-dev-cloudflare-worker',
        },
      }
    );

    if (!response.ok) {
      throw new Error(`GitHub API returned ${response.status}`);
    }

    const data = await response.text();

    return new Response(data, {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: 'GitHub API Error',
        message: error.message,
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      }
    );
  }
}

// Handle social data (GitHub only - LinkedIn removed)
async function handleSocialData(username, corsHeaders) {
  let githubRepos = [];
  let githubError = null;

  try {
    const githubResponse = await fetch(
      `https://api.github.com/users/${username}/repos?sort=updated&per_page=50&type=all`,
      {
        headers: {
          'User-Agent': 'lukseh-dev-cloudflare-worker',
        },
      }
    );

    if (githubResponse.ok) {
      const githubData = await githubResponse.json();
      githubRepos = githubData.map((repo) => ({
        id: repo.id,
        name: repo.name,
        description: repo.description,
        html_url: repo.html_url,
        stargazers_count: repo.stargazers_count,
        language: repo.language,
        updated_at: repo.updated_at,
        created_at: repo.created_at,
        archived: repo.archived,
        fork: repo.fork,
      }));
    } else {
      githubError = `GitHub API error: ${githubResponse.status}`;
    }
  } catch (error) {
    githubError = `GitHub error: ${error.message}`;
  }

  const result = {
    GitHub: {
      Repos: githubRepos,
      Error: githubError,
    },
  };

  return new Response(JSON.stringify(result), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders,
    },
  });
}
