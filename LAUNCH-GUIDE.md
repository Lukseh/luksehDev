# 🚀 Full Stack Launch Guide

## 🔧 **ISSUE FIXED: Backend Stops After npm install**

### 🚨 **Problem Identified**
The "Launch Full Stack (Clean Build)" was using a preLaunchTask that included starting services, which conflicted with the launch configuration also trying to start them.

### ✅ **Solution Applied**
1. Created separate **"Clean and Build (Pre-Launch)"** task that only cleans and builds
2. Updated launch configuration to use the correct pre-launch task
3. Added process cleanup to prevent port conflicts

### 🎯 **Fixed Launch Sequence**
```
Launch Full Stack (Clean Build):
1. Stop Running Processes (clears ports 3000, 5173, 5174, 5188)
2. Clean All (removes build artifacts)
3. Install All Dependencies (npm install for both projects)
4. Build Backend (dotnet build)
5. Launch Backend API (via launch config)
6. Launch Node Proxy (via launch config)  
7. Launch Vue Frontend (via launch config)
```

## Available Launch Options

### 🔧 **VS Code Tasks** (Ctrl+Shift+P → Tasks: Run Task)

#### Quick Start (No Clean)
- **`Start Full Stack`** - Starts all services without cleaning/rebuilding
  - ✅ Fast startup (30-60 seconds)
  - ✅ Good for development when you haven't changed dependencies
  - ❌ Doesn't clean old builds or reinstall dependencies

#### Clean Rebuild & Start
- **`Clean Build and Start Full Stack`** - Full clean rebuild and launch
  - ✅ Guarantees fresh build
  - ✅ Cleans old files and reinstalls dependencies
  - ✅ Rebuilds .NET backend
  - ⏱️ Slower startup (2-3 minutes)
  - ✅ **Recommended when:**
    - You've changed package.json dependencies
    - You've pulled new code from git
    - Having weird build issues
    - Starting fresh development session

#### Individual Clean Tasks
- **`Clean All`** - Cleans Vue frontend and .NET backend
- **`Clean Vue Frontend`** - Removes dist/ and node_modules/.vite
- **`Clean Backend`** - Cleans .NET build artifacts
- **`Install All Dependencies`** - Reinstalls npm packages

### 🎯 **VS Code Launch Configurations** (F5 or Run and Debug)

#### Standard Launch
- **`Launch Full Stack`** - Starts all services for debugging
  - ✅ Enables debugging for all services
  - ✅ Fast startup
  - ❌ No clean/rebuild

#### Clean Launch  
- **`Launch Full Stack (Clean Build)`** - Clean rebuild then debug launch
  - ✅ Full clean and rebuild before launch
  - ✅ Enables debugging for all services
  - ✅ Guarantees fresh environment
  - ⏱️ Takes 2-3 minutes

## 📋 **What Each Option Does**

### `Start Full Stack` (Quick)
```
1. Start .NET Backend (port 5188)
2. Start Node.js Proxy (port 3000)  
3. Start Vue.js Frontend (port 5173/5174)
```

### `Clean Build and Start Full Stack` (Comprehensive)
```
1. Clean Vue frontend (remove dist/, .vite cache)
2. Clean .NET backend (remove bin/, obj/)
3. Install Vue dependencies (npm install)
4. Install Proxy dependencies (npm install)
5. Build .NET backend (dotnet build)
6. Start .NET Backend (port 5188)
7. Start Node.js Proxy (port 3000)
8. Start Vue.js Frontend (port 5173/5174)
```

## 🎯 **Recommendations**

### 🚀 **For Daily Development**
Use **`Start Full Stack`** - Quick and efficient

### 🔄 **When You Should Use Clean Build**
- ✅ After `git pull` or switching branches
- ✅ When you've modified package.json or .csproj files
- ✅ If you're getting weird build errors
- ✅ After updating dependencies
- ✅ At the start of a new development session
- ✅ Before demos or important testing

### ⚡ **Emergency Reset**
If everything is broken:
1. Run `Clean All` task
2. Run `Install All Dependencies` task  
3. Run `Clean Build and Start Full Stack` task

## 🎬 **How to Launch**

### Option 1: VS Code Tasks
1. Press `Ctrl+Shift+P`
2. Type "Tasks: Run Task"
3. Select your preferred task:
   - `Start Full Stack` (quick)
   - `Clean Build and Start Full Stack` (comprehensive)

### Option 2: VS Code Debug
1. Press `F5` or go to Run and Debug
2. Select from dropdown:
   - `Launch Full Stack` (quick)
   - `Launch Full Stack (Clean Build)` (comprehensive)

### Option 3: Manual Terminal
```bash
# Quick start
cd backend && dotnet run &
cd node-proxy && npm start &
cd frontend-vue && npm run dev

# With clean
cd frontend-vue && npm run clean && npm install
cd backend && dotnet clean && dotnet build
# Then start as above
```

## ⏱️ **Expected Timing**
- **Quick Start**: 30-60 seconds
- **Clean Build**: 2-3 minutes (depending on internet speed for npm install)

## 🔍 **Troubleshooting**
- **Port conflicts**: Clean build will help reset everything
- **Dependency issues**: Always use clean build after package changes
- **Cache problems**: Vue clean script clears Vite cache
- **Build artifacts**: .NET clean removes stale compiled files

---
**💡 TIP: Use Quick Start for daily dev, Clean Build when things get weird!**
