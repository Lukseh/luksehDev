# 🚀 Lukseh.dev Portfolio

A modern developer portfolio built with Vue.js, showcasing GitHub repositories and a professional CV, deployable to Cloudflare Workers.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Vue.js SPA    │───▶│ Cloudflare      │───▶│  GitHub API     │
│  (Frontend)     │    │ Worker (API)    │    │  (External)     │
│                 │    │                 │    │                 │
│ • Vuetify UI    │    │ • GitHub API    │    │ • Repository    │
│ • Vue Router    │    │ • CORS Handler  │    │   Data          │
│ • Static CV     │    │ • Error Handler │    │ • User Info     │
│ • Material      │    │ • Rate Limiting │    │                 │
│   Design        │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

This project has evolved to a modern serverless architecture using Cloudflare Workers and Pages for global deployment.

## ✨ Features

### 🎨 Frontend (Vue.js + Vuetify)
- **Vue.js 3.5.18** with Composition API and **Vuetify 3.9.3**
- **Vue Router 4.5.1** for multi-page navigation
- **Material Design** components with dark theme
- **Responsive** mobile-first design
- **GitHub repository** filtering, sorting, and display
- **Static CV** page with professional information
- **Vite 7.0.6** development server with Hot Module Replacement

### ⚡ Backend (Cloudflare Worker)
- **Serverless API** running on Cloudflare's edge network
- **GitHub API** integration for repository data
- **CORS handling** for cross-origin requests
- **Error management** and response formatting
- **Global deployment** with 300+ edge locations

### 🌟 Key Improvements
- **Removed LinkedIn dependency** - simplified to GitHub-only integration
- **Added static CV section** - professional experience and skills
- **Cloudflare Workers deployment** - serverless and globally distributed
- **No backend server required** - completely serverless architecture

## 🚀 Quick Start (Cloudflare Deployment)

### Prerequisites
- Node.js (version 16+)
- Cloudflare account (free tier sufficient)

### 1. Setup Environment
```bash
cd deploy
./setup-cloudflare.sh    # Linux/Mac
# or
.\setup-cloudflare.ps1   # Windows PowerShell
```

### 2. Authenticate with Cloudflare
```bash
wrangler login
```

### 3. Deploy to Cloudflare
```bash
./deploy-cloudflare.sh    # Linux/Mac
# or
.\deploy-cloudflare.ps1   # Windows PowerShell
```

Your site will be available at:
- **Frontend**: `https://lukseh-dev.pages.dev`
- **API**: `https://lukseh-dev-api.your-subdomain.workers.dev`

## 🛠️ Local Development

### Prerequisites
- Node.js 16+
- npm or yarn

### Frontend Development
```bash
cd frontend-vue
npm install
npm run dev
```

### API Testing (Local)
```bash
cd node-proxy
npm install
npm start
```

### Backend Development (.NET - Optional)
```bash
cd backend
dotnet run
```

## 📁 Project Structure

```
lukseh.dev/
├── frontend-vue/           # Vue.js + Vuetify frontend
│   ├── src/
│   │   ├── views/         # Page components (Home, GitHub, CV)
│   │   ├── services/      # API service layer
│   │   ├── router/        # Vue Router configuration
│   │   └── assets/        # Styles and static assets
│   ├── .env.production    # Production environment config
│   └── package.json
├── deploy/                # Cloudflare Workers deployment
│   ├── cloudflare-worker.js      # Worker API code
│   ├── wrangler.toml             # Worker configuration
│   ├── deploy-cloudflare.sh      # Deployment script (Linux/Mac)
│   ├── deploy-cloudflare.ps1     # Deployment script (Windows)
│   └── CLOUDFLARE-README.md      # Detailed deployment guide
├── node-proxy/            # Express.js proxy (local dev)
├── backend/               # .NET Web API (local dev)
└── .vscode/               # VS Code configuration
```

## 🌐 Deployment Options

### 🔥 Cloudflare Workers (Recommended)
- **Global edge deployment**
- **Automatic scaling**
- **Built-in DDoS protection**
- **Free tier available**
- See `deploy/CLOUDFLARE-README.md` for detailed guide

### 🐳 Traditional Hosting
- Docker containers available in `/deploy`
- Supports local development with .NET backend
- Node.js proxy for CORS handling

## 🎯 Customization Guide

### 1. Update Personal Information

#### CV Page (`frontend-vue/src/views/CV.vue`)
- Replace placeholder text with your information
- Update work experience, education, and skills
- Customize technologies and certifications

#### GitHub Username
Update the username in:
- `frontend-vue/src/views/GitHub.vue` (line with `getSocialData('lukseh')`)
- `deploy/cloudflare-worker.js` if needed

### 2. Customize Styling
- Colors and theme: `frontend-vue/src/main.js`
- Component styles: Individual `.vue` files
- Global styles: `frontend-vue/src/assets/`

### 3. Add Features
- **Analytics**: Add Google Analytics or Cloudflare Analytics
- **Contact Form**: Use Cloudflare Workers or third-party service
- **Blog**: Add a blog section with markdown support
- **Projects**: Expand beyond GitHub repositories

## 🔧 Environment Configuration

### Development (.env.development)
```env
VITE_API_BASE_URL=http://localhost:3000
```

### Production (.env.production)
```env
VITE_API_BASE_URL=https://lukseh-dev-api.your-subdomain.workers.dev
```

## 📊 Performance & Analytics

### Built-in Features
- **Cloudflare Analytics**: Automatic visitor tracking
- **Core Web Vitals**: Performance monitoring
- **CDN Caching**: Global asset distribution
- **Image Optimization**: Automatic image processing

### Performance Optimizations
- **Bundle splitting**: Optimized JavaScript chunks
- **Asset minification**: CSS and JS compression
- **Tree shaking**: Unused code elimination
- **Lazy loading**: Route-based code splitting

## 🔒 Security

### Cloudflare Security Features
- **DDoS Protection**: Built-in attack mitigation
- **SSL/TLS**: Automatic HTTPS certificates
- **WAF**: Web Application Firewall
- **Bot Management**: Automatic bot detection

### API Security
- **CORS**: Proper cross-origin handling
- **Rate Limiting**: Prevent API abuse
- **Input Validation**: Secure request processing

## 🧪 Testing

### Frontend Testing
```bash
cd frontend-vue
npm run test        # Unit tests
npm run test:e2e    # End-to-end tests
```

### API Testing
```bash
# Test worker locally
cd deploy/cloudflare-worker
wrangler dev

# Test endpoints
curl http://localhost:8787/health
curl http://localhost:8787/api/social/lukseh
```

## 📈 Monitoring & Logging

### Cloudflare Dashboard
- **Real-time analytics**
- **Error tracking**
- **Performance metrics**
- **Security events**

### Worker Logs
```bash
# Stream real-time logs
wrangler tail lukseh-dev-api

# View logs in dashboard
# Go to Cloudflare Dashboard > Workers & Pages > lukseh-dev-api > Logs
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Documentation
- [Vue.js Documentation](https://vuejs.org/)
- [Vuetify Documentation](https://vuetifyjs.com/)
- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)

### Issues
- Check existing issues in the GitHub repository
- Create new issues with detailed descriptions
- Use the issue templates when available

## 🎉 Acknowledgments

- **Vue.js Team** for the amazing framework
- **Vuetify Team** for the Material Design components
- **Cloudflare** for the edge computing platform
- **GitHub** for the API and hosting

---

**Built with ❤️ by Lukseh**

*Ready to deploy your portfolio to the edge? Get started with Cloudflare Workers today!* 🚀
