# LinkedIn Integration Setup Guide

## Overview
The lukseh.dev project now includes LinkedIn API integration alongside GitHub functionality, allowing you to display professional profile information and posts.

## Backend API Endpoints

### GitHub Endpoints
- `GET /api/github/repos/{username}` - Get user's repositories
- `GET /api/github/repos/{username}/{repo}/releases` - Get repository releases/changelogs

### LinkedIn Endpoints
- `GET /api/linkedin/profile/{profileId}` - Get LinkedIn profile information
- `GET /api/linkedin/posts/{profileId}` - Get LinkedIn posts and updates

### Combined Endpoint
- `GET /api/social/{username}` - Get combined GitHub and LinkedIn data

## LinkedIn API Setup

### 1. Create LinkedIn App
1. Go to [LinkedIn Developer Portal](https://developer.linkedin.com/)
2. Create a new app
3. Request access to required APIs:
   - Profile API
   - Share API
   - Posts API

### 2. Configure Permissions
Required LinkedIn API permissions:
- `r_liteprofile` - Basic profile information
- `r_emailaddress` - Email address
- `w_member_social` - Share content
- `r_member_social` - Read member's posts

### 3. Get Access Token
1. Use LinkedIn OAuth 2.0 flow to get access token
2. Store the token securely in your configuration

### 4. Update Configuration Files

#### backend/appsettings.Development.json
```json
{
  "ApiSettings": {
    "GitHubToken": "your_github_personal_access_token",
    "LinkedInAccessToken": "your_linkedin_access_token",
    "LinkedInProfileId": "your_linkedin_profile_id"
  }
}
```

#### Environment Variables (Alternative)
```bash
LINKEDIN_ACCESS_TOKEN=your_access_token
LINKEDIN_PROFILE_ID=your_profile_id
GITHUB_TOKEN=your_github_token
```

## Frontend Integration

### Social Data Display
The frontend automatically fetches and displays:
- GitHub repositories with stars, language, and links
- LinkedIn profile information
- Professional timeline combining both platforms

### API Usage Example
```javascript
// Fetch combined social data
const response = await fetch('/api/social/lukseh');
const data = await response.json();

// Access GitHub repos
const repos = data.GitHub.Repos;

// Access LinkedIn profile
const profile = data.LinkedIn.Profile;
```

## Development Workflow

### 1. Start Backend
```bash
dotnet run --project backend/LuksehDev.Backend.csproj
```
Backend runs on: `http://localhost:5000`

### 2. Start Frontend
```bash
cd frontend
npm run build
npm start
```
Frontend runs on: `http://localhost:3000`

### 3. Access Combined View
Visit `http://localhost:3000` to see the integrated social media dashboard.

## Features

### GitHub Integration
- ✅ Repository listing with metadata
- ✅ Star counts and programming languages
- ✅ Release/changelog parsing
- ✅ Direct links to repositories

### LinkedIn Integration
- ✅ Profile information display
- ✅ Professional headline
- ✅ Post and update fetching
- ✅ Professional timeline view

### Combined Features
- ✅ Unified social media dashboard
- ✅ Cross-platform data aggregation
- ✅ Error handling for each service
- ✅ Responsive design
- ✅ Real-time data fetching

## Security Considerations

1. **API Keys**: Store LinkedIn and GitHub tokens securely
2. **Rate Limiting**: Implement caching to avoid API limits
3. **CORS**: Properly configure cross-origin requests
4. **Environment Variables**: Use environment-specific configurations

## Troubleshooting

### LinkedIn API Issues
- Verify app permissions in LinkedIn Developer Portal
- Check access token expiration
- Ensure profile ID is correct

### GitHub API Issues
- Check rate limiting (60 requests/hour without token)
- Verify personal access token if using authenticated requests

### CORS Issues
- Ensure frontend URL is allowed in backend CORS policy
- Check browser console for specific CORS errors

## Next Steps

1. **Vue.js Integration**: Replace static HTML with Vue.js components
2. **Real-time Updates**: Add WebSocket support for live data
3. **Caching**: Implement Redis for API response caching
4. **Analytics**: Add visitor tracking and engagement metrics
5. **Mobile App**: Create mobile companion app using same APIs
