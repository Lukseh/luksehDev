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
        github = "/api/github/repos/{username}"
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

// Simplified social data endpoint - GitHub only
app.MapGet("/api/social/{username}", async ([FromRoute] string username, HttpClient httpClient) =>
{
    var githubRepos = new List<object>();
    string? githubError = null;

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

    var result = new
    {
        GitHub = new { Repos = githubRepos, Error = githubError }
    };

    return Results.Ok(result);
})
.WithName("GetSocialData")
.WithOpenApi();

app.Run();

// Configuration classes
public class ApiSettings
{
    public string? GitHubToken { get; set; }
}
