# Quick setup script for Cloudflare Workers deployment (PowerShell)
# This script installs prerequisites and prepares the environment

Write-Host "🚀 Setting up Cloudflare Workers environment for lukseh.dev" -ForegroundColor Green

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Check if Node.js is installed
if (-not (Test-Command "node")) {
    Write-Host "❌ Node.js is not installed" -ForegroundColor Red
    Write-Host "Please install Node.js from https://nodejs.org/" -ForegroundColor Blue
    exit 1
}

$nodeVersion = node --version
Write-Host "✅ Node.js found: $nodeVersion" -ForegroundColor Green

# Check if npm is installed
if (-not (Test-Command "npm")) {
    Write-Host "❌ npm is not installed" -ForegroundColor Red
    exit 1
}

$npmVersion = npm --version
Write-Host "✅ npm found: $npmVersion" -ForegroundColor Green

# Install Wrangler CLI globally
Write-Host "📦 Installing Wrangler CLI..." -ForegroundColor Blue
npm install -g wrangler

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Wrangler installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install Wrangler" -ForegroundColor Red
    exit 1
}

# Check Wrangler version
try {
    $wranglerVersion = wrangler --version
    Write-Host "✅ Wrangler version: $wranglerVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Wrangler installed but version check failed" -ForegroundColor Yellow
}

# Install frontend dependencies
Write-Host "📦 Installing frontend dependencies..." -ForegroundColor Blue
Push-Location "..\frontend-vue"
npm install

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Frontend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install frontend dependencies" -ForegroundColor Red
    Pop-Location
    exit 1
}

# Go back to deploy directory
Pop-Location

# Create worker directory structure
Write-Host "📁 Setting up worker directory..." -ForegroundColor Blue
if (-not (Test-Path "cloudflare-worker")) {
    New-Item -ItemType Directory -Path "cloudflare-worker" -Force | Out-Null
}

Write-Host "✅ Environment setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: wrangler login (to authenticate with Cloudflare)" -ForegroundColor Blue
Write-Host "2. Update the API URL in frontend-vue\.env.production" -ForegroundColor Blue
Write-Host "3. Run: .\deploy-cloudflare.ps1 (to deploy)" -ForegroundColor Blue
Write-Host ""
Write-Host "🎉 Ready to deploy to Cloudflare Workers!" -ForegroundColor Green

Read-Host "Press Enter to continue..."
