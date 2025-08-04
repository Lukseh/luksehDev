import express from 'express';
import cors from 'cors';
import axios from 'axios';
import path from 'path';

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5188';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

// Types for API responses
interface GitHubRepo {
    id: number;
    name: string;
    description: string;
    html_url: string;
    stargazers_count: number;
    language: string;
    updated_at: string;
}

interface LinkedInProfile {
    id: string;
    firstName: string;
    lastName: string;
    headline: string;
}

interface SocialData {
    GitHub: {
        Repos: GitHubRepo[];
        Error: string | null;
    };
    LinkedIn: {
        Profile: LinkedInProfile | null;
        Posts: any[];
        Error: string | null;
    };
}

// API Routes
app.get('/api/social/:username', async (req, res) => {
    try {
        const { username } = req.params;
        const response = await axios.get<SocialData>(`${BACKEND_URL}/api/social/${username}`);
        
        res.json({
            success: true,
            data: response.data
        });
    } catch (error) {
        console.error('Error fetching social data:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch social data'
        });
    }
});

app.get('/api/github/repos/:username', async (req, res) => {
    try {
        const { username } = req.params;
        const response = await axios.get(`${BACKEND_URL}/api/github/repos/${username}`);
        
        res.json({
            success: true,
            data: response.data
        });
    } catch (error) {
        console.error('Error fetching GitHub repos:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch GitHub repositories'
        });
    }
});

app.get('/api/linkedin/profile/:profileId', async (req, res) => {
    try {
        const { profileId } = req.params;
        const response = await axios.get(`${BACKEND_URL}/api/linkedin/profile/${profileId}`);
        
        res.json({
            success: true,
            data: response.data
        });
    } catch (error) {
        console.error('Error fetching LinkedIn profile:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch LinkedIn profile'
        });
    }
});

// Serve the main HTML page
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>lukseh.dev - Developer Portfolio</title>
            <style>
                body {
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    margin: 0;
                    padding: 20px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    min-height: 100vh;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 20px;
                }
                .header {
                    text-align: center;
                    margin-bottom: 40px;
                }
                .header h1 {
                    font-size: 3rem;
                    margin: 0;
                    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
                }
                .header p {
                    font-size: 1.2rem;
                    opacity: 0.9;
                }
                .social-container {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 30px;
                    margin-top: 40px;
                }
                .social-section {
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 15px;
                    padding: 25px;
                    backdrop-filter: blur(10px);
                    border: 1px solid rgba(255, 255, 255, 0.2);
                }
                .social-section h2 {
                    margin-top: 0;
                    display: flex;
                    align-items: center;
                    gap: 10px;
                }
                .repo-card, .linkedin-card {
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 10px;
                    padding: 15px;
                    margin: 10px 0;
                    border-left: 4px solid #4CAF50;
                }
                .linkedin-card {
                    border-left-color: #0077B5;
                }
                .btn {
                    background: rgba(255, 255, 255, 0.2);
                    border: none;
                    padding: 10px 20px;
                    border-radius: 25px;
                    color: white;
                    cursor: pointer;
                    margin: 10px 5px;
                    font-size: 1rem;
                    transition: all 0.3s ease;
                }
                .btn:hover {
                    background: rgba(255, 255, 255, 0.3);
                    transform: translateY(-2px);
                }
                .loading {
                    text-align: center;
                    padding: 20px;
                    font-style: italic;
                }
                @media (max-width: 768px) {
                    .social-container {
                        grid-template-columns: 1fr;
                    }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🚀 lukseh.dev</h1>
                    <p>Developer Portfolio with GitHub & LinkedIn Integration</p>
                    <button class="btn" onclick="loadSocialData('lukseh')">Load Portfolio Data</button>
                </div>
                
                <div class="social-container">
                    <div class="social-section">
                        <h2>🐙 GitHub Repositories</h2>
                        <div id="github-content" class="loading">Click "Load Portfolio Data" to see GitHub repos</div>
                    </div>
                    
                    <div class="social-section">
                        <h2>💼 LinkedIn Profile</h2>
                        <div id="linkedin-content" class="loading">Click "Load Portfolio Data" to see LinkedIn profile</div>
                    </div>
                </div>
            </div>

            <script>
                async function loadSocialData(username) {
                    const githubContent = document.getElementById('github-content');
                    const linkedinContent = document.getElementById('linkedin-content');
                    
                    githubContent.innerHTML = '<div class="loading">Loading GitHub data...</div>';
                    linkedinContent.innerHTML = '<div class="loading">Loading LinkedIn data...</div>';
                    
                    try {
                        const response = await fetch(\`/api/social/\${username}\`);
                        const result = await response.json();
                        
                        if (result.success) {
                            const data = result.data;
                            
                            // Display GitHub repos
                            if (data.gitHub.error) {
                                githubContent.innerHTML = \`<div style="color: #ff6b6b;">Error: \${data.gitHub.error}</div>\`;
                            } else if (data.gitHub.repos && data.gitHub.repos.length > 0) {
                                githubContent.innerHTML = data.gitHub.repos.map(repo => \`
                                    <div class="repo-card">
                                        <h3>\${repo.name}</h3>
                                        <p>\${repo.description || 'No description available'}</p>
                                        <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 10px;">
                                            <span>⭐ \${repo.stargazers_count} | 📝 \${repo.language || 'Unknown'}</span>
                                            <a href="\${repo.html_url}" target="_blank" style="color: #4CAF50; text-decoration: none;">View on GitHub →</a>
                                        </div>
                                    </div>
                                \`).join('');
                            } else {
                                githubContent.innerHTML = '<div>No repositories found</div>';
                            }
                            
                            // Display LinkedIn profile
                            if (data.linkedIn.error) {
                                linkedinContent.innerHTML = \`<div style="color: #ffd93d;">Note: \${data.linkedIn.error}</div><div style="margin-top: 10px; font-size: 0.9em; opacity: 0.8;">To enable LinkedIn integration, configure your LinkedIn API credentials in the backend.</div>\`;
                            } else if (data.linkedIn.profile) {
                                linkedinContent.innerHTML = \`
                                    <div class="linkedin-card">
                                        <h3>\${data.linkedIn.profile.firstName} \${data.linkedIn.profile.lastName}</h3>
                                        <p>\${data.linkedIn.profile.headline || 'Professional'}</p>
                                        <div style="margin-top: 10px;">
                                            <a href="https://linkedin.com/in/\${username}" target="_blank" style="color: #0077B5; text-decoration: none;">View LinkedIn Profile →</a>
                                        </div>
                                    </div>
                                \`;
                            } else {
                                linkedinContent.innerHTML = \`
                                    <div>LinkedIn integration available - configure API credentials to enable</div>
                                    <div style="margin-top: 10px; font-size: 0.9em; opacity: 0.8;">
                                        Add your LinkedIn API credentials to appsettings.Development.json:
                                        <br>• LinkedInAccessToken
                                        <br>• LinkedInProfileId
                                    </div>
                                \`;
                            }
                        } else {
                            githubContent.innerHTML = \`<div style="color: #ff6b6b;">Error: \${result.error}</div>\`;
                            linkedinContent.innerHTML = \`<div style="color: #ff6b6b;">Error: \${result.error}</div>\`;
                        }
                    } catch (error) {
                        console.error('Error:', error);
                        githubContent.innerHTML = '<div style="color: #ff6b6b;">Error loading data. Make sure the backend is running.</div>';
                        linkedinContent.innerHTML = '<div style="color: #ff6b6b;">Error loading data. Make sure the backend is running.</div>';
                    }
                }
            </script>
        </body>
        </html>
    `);
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        services: {
            frontend: 'running',
            backend: BACKEND_URL
        }
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Frontend server running on http://localhost:${PORT}`);
    console.log(`📡 Backend URL: ${BACKEND_URL}`);
    console.log(`🔍 Health check: http://localhost:${PORT}/health`);
});

export { app };
