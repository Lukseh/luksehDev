// Enhanced GitHub API endpoint with optional token authentication
app.MapGet("/api/github/repos/{username}", async ([FromRoute] string username, HttpClient httpClient, IConfiguration config) =>
{
    try
    {
        httpClient.DefaultRequestHeaders.Add("User-Agent", "lukseh-dev-website");
        
        // Add authentication if token is configured
        var githubToken = config["ApiSettings:GitHubToken"];
        if (!string.IsNullOrEmpty(githubToken))
        {
            httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {githubToken}");
        }
        
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
});
