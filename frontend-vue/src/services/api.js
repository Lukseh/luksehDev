// API service for handling requests to backend/worker
import axios from 'axios'

// Get the API base URL from environment variables
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

// Create axios instance with default configuration
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// GitHub API client for direct access
const githubClient = axios.create({
  baseURL: 'https://api.github.com',
  timeout: 10000,
  headers: {
    'Accept': 'application/vnd.github.v3+json',
    'User-Agent': 'lukseh-dev-portfolio'
  },
})

// Request interceptor for logging
apiClient.interceptors.request.use(
  (config) => {
    console.log(`🔗 API Request: ${config.method?.toUpperCase()} ${config.url}`)
    return config
  },
  (error) => {
    console.error('❌ API Request Error:', error)
    return Promise.reject(error)
  }
)

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => {
    console.log(`✅ API Response: ${response.status} ${response.config.url}`)
    return response
  },
  (error) => {
    console.error('❌ API Response Error:', error.response?.status, error.message)
    return Promise.reject(error)
  }
)

export const apiService = {
  // Health check
  async healthCheck() {
    try {
      const response = await apiClient.get('/health')
      return response.data
    } catch (error) {
      throw new Error(`Health check failed: ${error.message}`)
    }
  },

  // Get social data (GitHub repos) - Use direct GitHub API as fallback
  async getSocialData(username) {
    try {
      // Try the worker/backend first
      try {
        const response = await apiClient.get(`/api/social/${username}`)
        return response.data
      } catch (backendError) {
        console.warn('Backend not available, using GitHub API directly:', backendError.message)
        
        // Fallback to direct GitHub API
        const reposResponse = await githubClient.get(`/users/${username}/repos`, {
          params: {
            sort: 'updated',
            per_page: 100,
            type: 'owner'
          }
        })
        
        return {
          GitHub: {
            Repos: reposResponse.data,
            Error: null
          }
        }
      }
    } catch (error) {
      throw new Error(`Failed to fetch social data: ${error.message}`)
    }
  },

  // Get GitHub repositories - Direct GitHub API
  async getGitHubRepos(username) {
    try {
      const response = await githubClient.get(`/users/${username}/repos`, {
        params: {
          sort: 'updated',
          per_page: 100,
          type: 'owner'
        }
      })
      return response.data
    } catch (error) {
      throw new Error(`Failed to fetch GitHub repos: ${error.message}`)
    }
  },

  // Get GitHub releases for a specific repo
  async getGitHubReleases(username, repo) {
    try {
      const response = await githubClient.get(`/repos/${username}/${repo}/releases`)
      return response.data
    } catch (error) {
      throw new Error(`Failed to fetch GitHub releases: ${error.message}`)
    }
  },
}

export default apiService
