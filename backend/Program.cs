using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddOpenApi();
builder.Services.AddHttpClient();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins("http://localhost:3000", "http://localhost:8080", "http://localhost:5173", "http://localhost:4173")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Add configuration for API keys
builder.Services.Configure<ApiSettings>(builder.Configuration.GetSection("ApiSettings"));

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

// Disable HTTPS redirection in development to avoid port conflicts
// app.UseHttpsRedirection();
app.UseCors("AllowFrontend");

// Root endpoint
app.MapGet("/", () => new
{
    service = "lukseh.dev Backend API",
    version = "1.0.0",
    status = "running",
    endpoints = new
    {
        social = "/api/social/{username}",
        github = "/api/github/repos/{username}",
        linkedin = "/api/linkedin/profile/{profileId}"
    },
    timestamp = DateTime.UtcNow
});

// GitHub API endpoints
app.MapGet("/api/github/repos/{username}", async ([FromRoute] string username, HttpClient httpClient) =>
{
    try
    {
        httpClient.DefaultRequestHeaders.Add("User-Agent", "lukseh-dev-website");
        
        // Get more repositories and include archived ones
        var response = await httpClient.GetAsync($"https://api.github.com/users/{username}/repos?sort=updated&per_page=50&type=all");
        
        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            return Results.Ok(content);
        }
        
        return Results.Problem($"GitHub API returned: {response.StatusCode}");
    }
    catch (Exception ex)
    {
        return Results.Problem($"Error fetching GitHub repos: {ex.Message}");
    }
})
.WithName("GetGitHubRepos")
.WithOpenApi();

app.MapGet("/api/github/repos/{username}/{repo}/releases", async ([FromRoute] string username, [FromRoute] string repo, HttpClient httpClient) =>
{
    try
    {
        httpClient.DefaultRequestHeaders.Add("User-Agent", "lukseh-dev-website");
        var response = await httpClient.GetAsync($"https://api.github.com/repos/{username}/{repo}/releases?per_page=5");
        
        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            return Results.Ok(content);
        }
        
        return Results.Problem($"GitHub API returned: {response.StatusCode}");
    }
    catch (Exception ex)
    {
        return Results.Problem($"Error fetching releases: {ex.Message}");
    }
})
.WithName("GetGitHubReleases")
.WithOpenApi();

// LinkedIn API endpoints
app.MapGet("/api/linkedin/profile/{profileId}", async ([FromRoute] string profileId, HttpClient httpClient, IConfiguration config) =>
{
    try
    {
        var accessToken = config["ApiSettings:LinkedInAccessToken"];
        if (string.IsNullOrEmpty(accessToken))
        {
            return Results.Problem("LinkedIn access token not configured");
        }

        httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {accessToken}");
        var response = await httpClient.GetAsync($"https://api.linkedin.com/v2/people/{profileId}");
        
        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            return Results.Ok(content);
        }
        
        return Results.Problem($"LinkedIn API returned: {response.StatusCode}");
    }
    catch (Exception ex)
    {
        return Results.Problem($"Error fetching LinkedIn profile: {ex.Message}");
    }
})
.WithName("GetLinkedInProfile")
.WithOpenApi();

app.MapGet("/api/linkedin/posts/{profileId}", async ([FromRoute] string profileId, HttpClient httpClient, IConfiguration config) =>
{
    try
    {
        var accessToken = config["ApiSettings:LinkedInAccessToken"];
        if (string.IsNullOrEmpty(accessToken))
        {
            return Results.Problem("LinkedIn access token not configured");
        }

        httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {accessToken}");
        var response = await httpClient.GetAsync($"https://api.linkedin.com/v2/shares?q=owners&owners={profileId}&count=10");
        
        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            return Results.Ok(content);
        }
        
        return Results.Problem($"LinkedIn API returned: {response.StatusCode}");
    }
    catch (Exception ex)
    {
        return Results.Problem($"Error fetching LinkedIn posts: {ex.Message}");
    }
})
.WithName("GetLinkedInPosts")
.WithOpenApi();

// Combined social data endpoint
app.MapGet("/api/social/{username}", async ([FromRoute] string username, HttpClient httpClient, IConfiguration config) =>
{
    var githubRepos = new List<object>();
    string? githubError = null;
    object? linkedInProfile = null;
    var linkedInPosts = new List<object>();
    string? linkedInError = null;

    try
    {
        // Fetch GitHub data
        httpClient.DefaultRequestHeaders.Clear();
        httpClient.DefaultRequestHeaders.Add("User-Agent", "lukseh-dev-website");
        var githubResponse = await httpClient.GetAsync($"https://api.github.com/users/{username}/repos?sort=updated&per_page=50&type=all");
        
        if (githubResponse.IsSuccessStatusCode)
        {
            var githubContent = await githubResponse.Content.ReadAsStringAsync();
            var githubReposJson = JsonSerializer.Deserialize<JsonElement>(githubContent);
            githubRepos.AddRange(githubReposJson.EnumerateArray().Select(repo => new
            {
                id = repo.GetProperty("id").GetInt32(),
                name = repo.GetProperty("name").GetString(),
                description = repo.TryGetProperty("description", out var desc) ? desc.GetString() : null,
                html_url = repo.GetProperty("html_url").GetString(),
                stargazers_count = repo.GetProperty("stargazers_count").GetInt32(),
                language = repo.TryGetProperty("language", out var lang) ? lang.GetString() : null,
                updated_at = repo.GetProperty("updated_at").GetString(),
                created_at = repo.GetProperty("created_at").GetString(),
                archived = repo.GetProperty("archived").GetBoolean(),
                fork = repo.GetProperty("fork").GetBoolean()
            }));
        }
        else
        {
            githubError = $"GitHub API error: {githubResponse.StatusCode}";
        }
    }
    catch (Exception ex)
    {
        githubError = $"GitHub error: {ex.Message}";
    }

    try
    {
        // Fetch LinkedIn data (if configured)
        var linkedInAccessToken = config["ApiSettings:LinkedInAccessToken"];
        var linkedInProfileId = config["ApiSettings:LinkedInProfileId"];
        
        if (!string.IsNullOrEmpty(linkedInAccessToken) && !string.IsNullOrEmpty(linkedInProfileId))
        {
            httpClient.DefaultRequestHeaders.Clear();
            httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {linkedInAccessToken}");
            
            var linkedInResponse = await httpClient.GetAsync($"https://api.linkedin.com/v2/people/{linkedInProfileId}");
            if (linkedInResponse.IsSuccessStatusCode)
            {
                var linkedInContent = await linkedInResponse.Content.ReadAsStringAsync();
                linkedInProfile = JsonSerializer.Deserialize<JsonElement>(linkedInContent);
            }
            else
            {
                linkedInError = $"LinkedIn API error: {linkedInResponse.StatusCode}";
            }
        }
        else
        {
            linkedInError = "LinkedIn API credentials not configured";
        }
    }
    catch (Exception ex)
    {
        linkedInError = $"LinkedIn error: {ex.Message}";
    }

    var result = new
    {
        GitHub = new { Repos = githubRepos, Error = githubError },
        LinkedIn = new { Profile = linkedInProfile, Posts = linkedInPosts, Error = linkedInError }
    };

    return Results.Ok(result);
})
.WithName("GetSocialData")
.WithOpenApi();

// LinkedIn OAuth endpoints
app.MapGet("/auth/linkedin", (IConfiguration config) =>
{
    var clientId = "77c0av43d6f3yc"; // From your screenshot
    var redirectUri = "http://localhost:5188/auth/linkedin/callback";
    var scope = "r_liteprofile r_emailaddress";
    var state = Guid.NewGuid().ToString(); // For security
    
    var authUrl = $"https://www.linkedin.com/oauth/v2/authorization" +
                  $"?response_type=code" +
                  $"&client_id={clientId}" +
                  $"&redirect_uri={Uri.EscapeDataString(redirectUri)}" +
                  $"&scope={Uri.EscapeDataString(scope)}" +
                  $"&state={state}";
    
    return Results.Redirect(authUrl);
})
.WithName("LinkedInAuth")
.WithOpenApi();

app.MapGet("/auth/linkedin/callback", async ([FromQuery] string code, [FromQuery] string state, HttpClient httpClient, IConfiguration config) =>
{
    try
    {
        var clientId = "77c0av43d6f3yc";
        var clientSecret = config["ApiSettings:LinkedInClientSecret"];
        var redirectUri = "http://localhost:5188/auth/linkedin/callback";
        
        if (string.IsNullOrEmpty(clientSecret))
        {
            return Results.Problem("LinkedIn client secret not configured");
        }
        
        // Exchange code for access token
        var tokenRequest = new FormUrlEncodedContent(new[]
        {
            new KeyValuePair<string, string>("grant_type", "authorization_code"),
            new KeyValuePair<string, string>("code", code),
            new KeyValuePair<string, string>("redirect_uri", redirectUri),
            new KeyValuePair<string, string>("client_id", clientId),
            new KeyValuePair<string, string>("client_secret", clientSecret)
        });
        
        var tokenResponse = await httpClient.PostAsync("https://www.linkedin.com/oauth/v2/accessToken", tokenRequest);
        
        if (tokenResponse.IsSuccessStatusCode)
        {
            var tokenContent = await tokenResponse.Content.ReadAsStringAsync();
            return Results.Ok(new { 
                message = "LinkedIn OAuth successful!", 
                token_response = tokenContent,
                instructions = "Copy the 'access_token' value to your appsettings.Development.json"
            });
        }
        
        return Results.Problem($"Token exchange failed: {tokenResponse.StatusCode}");
    }
    catch (Exception ex)
    {
        return Results.Problem($"OAuth callback error: {ex.Message}");
    }
})
.WithName("LinkedInCallback")
.WithOpenApi();

app.Run();

// Configuration classes
public class ApiSettings
{
    public string? GitHubToken { get; set; }
    public string? LinkedInAccessToken { get; set; }
    public string? LinkedInClientSecret { get; set; }
    public string? LinkedInProfileId { get; set; }
}
