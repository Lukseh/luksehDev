# 🚀 Getting Started with lukseh.dev

Welcome! This is a quick guide to get your portfolio deployed to Cloudflare Workers.

## 📋 What You Need

1. **Node.js** (download from [nodejs.org](https://nodejs.org/))
2. **Cloudflare Account** (free at [cloudflare.com](https://cloudflare.com/))
3. **5 minutes** ⏰

## 🎯 Quick Deploy

### Step 1: Open Terminal
- **Windows**: Press `Win + R`, type `powershell`, press Enter
- **Mac**: Press `Cmd + Space`, type `terminal`, press Enter
- **Linux**: Press `Ctrl + Alt + T`

### Step 2: Navigate to Project
```bash
cd /path/to/lukseh.dev/deploy
```

### Step 3: Run Setup (First Time Only)
```bash
# Windows
.\setup-cloudflare.ps1

# Mac/Linux
./setup-cloudflare.sh
```

### Step 4: Login to Cloudflare
```bash
wrangler login
```
This opens your browser - just click "Allow" to authenticate.

### Step 5: Deploy
```bash
# Windows
.\deploy-cloudflare.ps1

# Mac/Linux
./deploy-cloudflare.sh
```

### Step 6: View Your Site
The script will show you the URLs:
- **Your portfolio**: `https://lukseh-dev.pages.dev`
- **API**: `https://lukseh-dev-api.your-subdomain.workers.dev`

## ✏️ Customize Your CV

1. Open `frontend-vue/src/views/CV.vue`
2. Replace the placeholder text `[Your Name]`, `[Your Email]`, etc.
3. Update your work experience, education, and skills
4. Save the file
5. Run the deploy script again

## 🔧 Update API URL

1. Open `frontend-vue/.env.production`
2. Replace `YOUR_SUBDOMAIN` with your actual Cloudflare subdomain
3. Save and redeploy

## 🆘 Need Help?

- **Build errors**: Delete `node_modules` folder and run `npm install`
- **Authentication issues**: Run `wrangler logout` then `wrangler login`
- **Can't find files**: Make sure you're in the `/deploy` directory

## 🎉 That's It!

Your portfolio is now live on Cloudflare's global network! 

**Next Steps:**
- Customize your CV content
- Add your own GitHub username
- Set up a custom domain (optional)

---

**Questions?** Check the main [README.md](../README.md) for detailed documentation.
