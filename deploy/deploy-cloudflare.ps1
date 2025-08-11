# Cloudflare Workers Deployment Script for lukseh.dev (PowerShell)
# This script builds and deploys the Vue.js frontend to Cloudflare Pages
# and creates a Cloudflare Worker for the API endpoints

param(
    [string]$ProjectName = "lukseh-dev",
    [string]$WorkerName = "lukseh-dev-api"
)

# Enable verbose output
$VerbosePreference = "Continue"

Write-Host "🚀 Starting Cloudflare Workers deployment for lukseh.dev" -ForegroundColor Green

# Configuration
$FrontendDir = "..\frontend-vue"
$WorkerDir = ".\cloudflare-worker"
$BuildDir = "$FrontendDir\dist"

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Check prerequisites
Write-Host "📋 Checking prerequisites..." -ForegroundColor Blue

if (-not (Test-Command "npm")) {
    Write-Host "❌ npm is not installed. Please install Node.js first." -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "wrangler")) {
    Write-Host "❌ wrangler is not installed. Installing..." -ForegroundColor Yellow
    npm install -g wrangler
    if (-not (Test-Command "wrangler")) {
        Write-Host "❌ Failed to install wrangler." -ForegroundColor Red
        exit 1
    }
}

# Check if user is logged in to Wrangler
try {
    $whoami = wrangler whoami 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  You are not logged in to Wrangler." -ForegroundColor Yellow
        Write-Host "🔐 Please run: wrangler login" -ForegroundColor Blue
        exit 1
    }
    Write-Host "✅ Wrangler authentication verified" -ForegroundColor Green
}
catch {
    Write-Host "❌ Error checking Wrangler authentication" -ForegroundColor Red
    exit 1
}

# Build the Vue.js frontend
Write-Host "🏗️  Building Vue.js frontend..." -ForegroundColor Blue
Push-Location $FrontendDir

# Clean previous build
if (Test-Path "dist") {
    Remove-Item -Path "dist" -Recurse -Force
    Write-Host "✅ Cleaned previous build" -ForegroundColor Green
}

# Install dependencies if needed
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing frontend dependencies..." -ForegroundColor Blue
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install frontend dependencies" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Build for production
Write-Host "🔨 Building for production..." -ForegroundColor Blue
npm run build

if ($LASTEXITCODE -ne 0 -or -not (Test-Path "dist")) {
    Write-Host "❌ Build failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "✅ Frontend build completed" -ForegroundColor Green

# Go back to deploy directory
Pop-Location

# Create Cloudflare Worker if it doesn't exist
if (-not (Test-Path $WorkerDir)) {
    Write-Host "⚡ Creating Cloudflare Worker directory..." -ForegroundColor Blue
    New-Item -ItemType Directory -Path $WorkerDir -Force | Out-Null
}

# Copy worker files
Write-Host "📁 Copying worker files..." -ForegroundColor Blue
Copy-Item "cloudflare-worker.js" "$WorkerDir\" -Force
Copy-Item "wrangler.toml" "$WorkerDir\" -Force
Copy-Item "cloudflare-package.json" "$WorkerDir\package.json" -Force

Push-Location $WorkerDir

# Install worker dependencies
if (-not (Test-Path "node_modules")) {
    Write-Host "📦 Installing worker dependencies..." -ForegroundColor Blue
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install worker dependencies" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Deploy the worker
Write-Host "⚡ Deploying Cloudflare Worker..." -ForegroundColor Blue
wrangler deploy

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Worker deployment failed" -ForegroundColor Red
    Pop-Location
    exit 1
}

Write-Host "✅ Worker deployed successfully" -ForegroundColor Green

# Go back to deploy directory for Pages deployment
Pop-Location

# Deploy to Cloudflare Pages
Write-Host "📄 Deploying to Cloudflare Pages..." -ForegroundColor Blue

# Check if Pages project exists (create if it doesn't)
$projectList = wrangler pages project list 2>&1
if ($projectList -notmatch $ProjectName) {
    Write-Host "📄 Creating Cloudflare Pages project..." -ForegroundColor Blue
    wrangler pages project create $ProjectName --production-branch main
}

# Deploy to Pages
Write-Host "🚀 Deploying to Cloudflare Pages..." -ForegroundColor Blue
wrangler pages deploy $BuildDir --project-name $ProjectName

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pages deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host "📄 Your site will be available at: https://$ProjectName.pages.dev" -ForegroundColor Blue
Write-Host "⚡ Worker API will be available at: https://$WorkerName.YOUR_SUBDOMAIN.workers.dev" -ForegroundColor Blue
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure your custom domain in Cloudflare Pages dashboard"
Write-Host "2. Update your worker's domain routing if needed"
Write-Host "3. Set up environment variables in the Cloudflare dashboard"
Write-Host "4. Update VITE_API_BASE_URL in .env.production with your actual worker URL"
Write-Host ""
Write-Host "✨ Deployment complete!" -ForegroundColor Green

# Show worker information
Write-Host ""
Write-Host "🔍 Worker Information:" -ForegroundColor Cyan
try {
    Push-Location $WorkerDir
    wrangler dev --help | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "• To test locally: wrangler dev"
        Write-Host "• To view logs: wrangler tail"
        Write-Host "• To update: wrangler deploy"
    }
    Pop-Location
}
catch {
    # Ignore errors for informational commands
}

Write-Host ""
Read-Host "Press Enter to continue..."
