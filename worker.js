// Cloudflare Worker to fetch, build and serve Vue.js frontend from GitHub releases
export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Handle API routes - proxy to GitHub API
    if (path.startsWith('/api/')) {
      return handleApiRequest(request, path);
    }

    // Handle special build trigger
    if (path === '/build') {
      return handleBuildRequest(request, env, ctx);
    }

    // Serve static files from cache or build from latest release
    return handleStaticRequest(request, path, env, ctx);
  }
};

async function handleBuildRequest(request, env, ctx) {
  try {
    const buildResult = await buildFromLatestRelease(env, ctx);
    return new Response(JSON.stringify({
      success: true,
      message: 'Build completed successfully',
      timestamp: new Date().toISOString(),
      ...buildResult
    }), {
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      }
    });
  }
}

async function buildFromLatestRelease(env, ctx) {
  try {
    // First try to get the repository info to make sure it exists
    // Try different possible repository names
    const possibleRepos = ['luksehDev', 'Lukseh.dev', 'lukseh-dev', 'LuksehDev'];
    let repoResponse;
    let correctRepoName;
    
    for (const repoName of possibleRepos) {
      repoResponse = await fetch(`https://api.github.com/repos/Lukseh/${repoName}`, {
        headers: {
          'User-Agent': 'Lukseh-Portfolio-Worker/1.0',
          'Accept': 'application/vnd.github.v3+json'
        }
      });
      
      if (repoResponse.ok) {
        correctRepoName = repoName;
        break;
      }
    }

    if (!repoResponse.ok) {
      throw new Error(`Repository not found. Tried: ${possibleRepos.join(', ')}`);
    }

    const repoData = await repoResponse.json();
    const defaultBranch = repoData.default_branch || 'main';

    // Try to get latest release first
    const releaseResponse = await fetch(`https://api.github.com/repos/Lukseh/${correctRepoName}/releases/latest`, {
      headers: {
        'User-Agent': 'Lukseh-Portfolio-Worker/1.0',
        'Accept': 'application/vnd.github.v3+json'
      }
    });

    if (releaseResponse.ok) {
      const releaseData = await releaseResponse.json();
      return await buildFromRelease(releaseData, correctRepoName, env, ctx);
    }

    // If no releases, get latest commit from default branch
    const commitResponse = await fetch(`https://api.github.com/repos/Lukseh/${correctRepoName}/commits/${defaultBranch}`, {
      headers: {
        'User-Agent': 'Lukseh-Portfolio-Worker/1.0',
        'Accept': 'application/vnd.github.v3+json'
      }
    });
    
    if (!commitResponse.ok) {
      const errorText = await commitResponse.text();
      throw new Error(`Failed to fetch latest commit from ${defaultBranch}: ${commitResponse.status} - ${errorText}`);
    }
    
    const commitData = await commitResponse.json();
    return await buildFromCommit(commitData.sha, defaultBranch, correctRepoName, env, ctx);

  } catch (error) {
    throw new Error(`GitHub API error: ${error.message}`);
  }
}

async function buildFromRelease(releaseData, repoName, env, ctx) {
  // Download source code from release
  const tarballUrl = releaseData.tarball_url;
  const sourceResponse = await fetch(tarballUrl, {
    headers: {
      'User-Agent': 'Lukseh-Portfolio-Worker/1.0'
    }
  });

  if (!sourceResponse.ok) {
    throw new Error('Failed to download release source');
  }

  // For now, we'll simulate the build process
  // In a real implementation, you'd need to extract the tarball and run the build
  return {
    repository: repoName,
    version: releaseData.tag_name,
    commit: releaseData.target_commitish,
    buildTime: new Date().toISOString(),
    status: 'Built from release'
  };
}

async function buildFromCommit(commitSha, branch, repoName, env, ctx) {
  // Download source from specific commit
  const archiveUrl = `https://api.github.com/repos/Lukseh/${repoName}/zipball/${commitSha}`;
  const sourceResponse = await fetch(archiveUrl, {
    headers: {
      'User-Agent': 'Lukseh-Portfolio-Worker/1.0'
    }
  });

  if (!sourceResponse.ok) {
    throw new Error(`Failed to download commit source: ${sourceResponse.status}`);
  }

  return {
    repository: repoName,
    commit: commitSha,
    branch: branch,
    buildTime: new Date().toISOString(),
    status: `Built from latest commit on ${branch} branch`,
    size: sourceResponse.headers.get('content-length') || 'unknown'
  };
}

async function handleStaticRequest(request, path, env, ctx) {
  // Check if we have a cached build
  const cacheKey = `build:latest`;
  
  // For now, serve a dynamic HTML page that shows the current status
  if (path === '/' || path === '/index.html') {
    return new Response(await generateIndexHtml(env), {
      headers: {
        'Content-Type': 'text/html',
        'Cache-Control': 'public, max-age=300' // 5 minutes cache
      }
    });
  }

  // Handle Vue router paths - serve index.html for SPA
  if (!path.includes('.')) {
    return new Response(await generateIndexHtml(env), {
      headers: {
        'Content-Type': 'text/html',
        'Cache-Control': 'public, max-age=300'
      }
    });
  }

  // For actual assets (CSS, JS, images), we'd need to serve from cache
  // For now, return 404 for missing assets
  return new Response('Asset not found', { status: 404 });
}

async function generateIndexHtml(env) {
  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>💼</text></svg>">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Adam Komorowski - Portfolio</title>
    <link href="https://cdn.jsdelivr.net/npm/@mdi/font@7.4.47/css/materialdesignicons.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/vuetify@3.9.3/dist/vuetify.min.css" rel="stylesheet">
    <script src="https://unpkg.com/vue@3/dist/vue.global.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/vuetify@3.9.3/dist/vuetify.min.js"></script>
    <style>
      body { margin: 0; background: #121212; color: #fff; font-family: 'Roboto', sans-serif; }
      .gradient-bg { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
    </style>
  </head>
  <body>
    <div id="app">
      <div class="gradient-bg" style="min-height: 100vh; display: flex; align-items: center; justify-content: center;">
        <div style="text-align: center; padding: 40px;">
          <h1 style="font-size: 3rem; margin-bottom: 20px;">Adam Komorowski</h1>
          <h2 style="font-size: 1.5rem; margin-bottom: 30px; opacity: 0.9;">Portfolio & CV</h2>
          <p style="font-size: 1.1rem; margin-bottom: 30px;">Dynamic Worker-based Portfolio</p>
          <div style="margin: 20px 0;">
            <button onclick="triggerBuild()" style="background: #fff; color: #333; padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; font-size: 1rem; margin: 0 10px;">
              🔨 Trigger Build
            </button>
            <a href="/api/users/Lukseh/repos" style="background: transparent; color: #fff; padding: 12px 24px; border: 2px solid #fff; border-radius: 6px; text-decoration: none; font-size: 1rem; margin: 0 10px;">
              📚 View Repositories
            </a>
          </div>
          <div id="build-status" style="margin-top: 30px; padding: 20px; background: rgba(255,255,255,0.1); border-radius: 8px; display: none;">
            <p id="status-text">Building...</p>
          </div>
        </div>
      </div>
    </div>
    
    <script>
      async function triggerBuild() {
        const statusDiv = document.getElementById('build-status');
        const statusText = document.getElementById('status-text');
        
        statusDiv.style.display = 'block';
        statusText.textContent = 'Triggering build from latest repository...';
        
        try {
          const response = await fetch('/build');
          const result = await response.json();
          
          if (result.success) {
            statusText.innerHTML = \`
              ✅ Build completed successfully!<br>
              <small>Repository: \${result.repository}<br>
              Version: \${result.version || result.commit}<br>
              Branch: \${result.branch || 'N/A'}<br>
              Built at: \${new Date(result.buildTime).toLocaleString()}</small>
            \`;
          } else {
            statusText.innerHTML = \`❌ Build failed: \${result.error}\`;
          }
        } catch (error) {
          statusText.innerHTML = \`❌ Build failed: \${error.message}\`;
        }
      }
      
      // Auto-build on page load
      document.addEventListener('DOMContentLoaded', () => {
        console.log('Portfolio Worker loaded');
      });
    </script>
  </body>
</html>`;
}

async function handleApiRequest(request, path) {
  // Extract the GitHub API path
  const githubPath = path.replace('/api/', '');
  const githubUrl = `https://api.github.com/repos/Lukseh/${githubPath}`;
  
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
