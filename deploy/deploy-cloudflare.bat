@echo off
REM Cloudflare Workers Deployment Script for lukseh.dev (Windows)
REM This script builds and deploys the Vue.js frontend to Cloudflare Pages
REM and creates a Cloudflare Worker for the API endpoints

echo 🚀 Starting Cloudflare Workers deployment for lukseh.dev

REM Configuration
set "PROJECT_NAME=lukseh-dev"
set "FRONTEND_DIR=..\frontend-vue"
set "WORKER_DIR=.\cloudflare-worker"
set "BUILD_DIR=%FRONTEND_DIR%\dist"

REM Check if required commands are available
where npm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ npm is not installed. Please install Node.js first.
    exit /b 1
)

where wrangler >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ❌ wrangler is not installed. Please install it with: npm install -g wrangler
    exit /b 1
)

echo 📋 Checking prerequisites...

REM Check if user is logged in to Wrangler
wrangler whoami >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo ⚠️  You are not logged in to Wrangler.
    echo 🔐 Please run: wrangler login
    exit /b 1
)

REM Build the Vue.js frontend
echo 🏗️  Building Vue.js frontend...
cd "%FRONTEND_DIR%"

REM Clean previous build
if exist "dist" (
    rmdir /s /q "dist"
    echo ✅ Cleaned previous build
)

REM Install dependencies if needed
if not exist "node_modules" (
    echo 📦 Installing frontend dependencies...
    npm install
)

REM Build for production
echo 🔨 Building for production...
npm run build

if not exist "dist" (
    echo ❌ Build failed - dist directory not found
    exit /b 1
)

echo ✅ Frontend build completed

REM Go back to deploy directory
cd ..\deploy

REM Create Cloudflare Worker if it doesn't exist
if not exist "%WORKER_DIR%" (
    echo ⚡ Creating Cloudflare Worker...
    mkdir "%WORKER_DIR%"
)

REM Copy worker files
copy cloudflare-worker.js "%WORKER_DIR%\"
copy wrangler.toml "%WORKER_DIR%\"
copy cloudflare-package.json "%WORKER_DIR%\package.json"

cd "%WORKER_DIR%"

REM Install worker dependencies
if not exist "node_modules" (
    echo 📦 Installing worker dependencies...
    npm install
)

REM Deploy the worker
echo ⚡ Deploying Cloudflare Worker...
wrangler deploy

echo ✅ Worker deployed successfully

REM Go back to deploy directory for Pages deployment
cd ..

REM Deploy to Cloudflare Pages
echo 📄 Deploying to Cloudflare Pages...

REM Deploy to Pages
echo 🚀 Deploying to Cloudflare Pages...
wrangler pages deploy "%BUILD_DIR%" --project-name %PROJECT_NAME%

echo 🎉 Deployment completed successfully!
echo 📄 Your site will be available at: https://%PROJECT_NAME%.pages.dev
echo ⚡ Worker API will be available at: https://lukseh-dev-api.YOUR_SUBDOMAIN.workers.dev
echo.
echo 📝 Next steps:
echo 1. Configure your custom domain in Cloudflare Pages dashboard
echo 2. Update your worker's domain routing if needed
echo 3. Set up environment variables in the Cloudflare dashboard
echo.
echo ✨ Deployment complete!

pause
