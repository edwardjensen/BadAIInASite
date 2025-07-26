# Bad AI In A Site - Project Summary

## Overview
Created a complete web application called "Bad AI In A Site" - a web adaptation of the physical "Bad AI In A Box" (BAIIAB) project. The application hosts a chatbot that provides intentionally humorous "bad" advice through a menu-driven interface.

## Project Status
✅ **COMPLETED** - Full implementation from greenfield project to production-ready application with automated deployment.

## Recent Updates

### Session 2
- Fixed GitHub Actions deployment workflow issues (GHCR authentication, Tailscale connectivity)
- Optimized CI/CD to skip container builds for non-essential file changes while always running deployment
- Added alphabetical sorting to the frontend UI menu display
- Integrated logo assets as favicon and in the site header  
- Added logo to README.md

### Session 3 - Humor Enhancement
- **Primary Issue**: AI responses were too serious; "fake facts" were actually real facts
- **Solution**: Enhanced all prompts in `menu.json` to emphasize humor, absurdity, and explicitly fake content
- **System Prompt Updated**: Modified server configuration to be more mischievous and playful
- **Technical Fixes**: 
  - Port conflict resolution with automatic process cleanup in dev script
  - Markdown formatting issues resolved by stripping syntax
  - Text alignment centered in response boxes
  - Localhost-only binding for development server

### Session 4 - Release & Enhancement Features
- **Docker Distribution**: Added GitHub Container Registry integration to README.md
- **Version 1.0.0 Release**: Created automated release workflow triggered by git tags
- **Build Optimization**: Added smart conditional builds that skip when only docs change
- **Responsive Theming**: Implemented automatic light/dark mode based on system preferences
- **Dynamic Footer**: Added version info from git tags, GitHub links, and configurable disclaimers
- **Configurable Content**: Made disclaimers configurable in settings.conf with multiple random options

## Key Features Implemented
- **Mobile-First Design**: iPhone-optimized interface with fixed-position UI elements
- **Menu-Driven Interaction**: Uses `menu.json` for predefined prompts instead of free text
- **Dual AI Backend**: Local LM Studio API + cloud OpenRouter API with automatic fallback
- **Docker Containerization**: Multi-stage build with health checks and non-root user
- **Automated Deployment**: GitHub Actions → Ubuntu VM via Tailscale VPN
- **Configuration System**: `settings.conf` for build-specific settings separate from environment variables
- **Response Formatting**: Markdown-to-HTML conversion with XSS protection and 80-token limits

## Architecture

### File Structure
```
badaiinasite/
├── src/server.js           # Express server with async initialization
├── public/
│   ├── index.html          # Mobile-first SPA
│   ├── styles.css          # Responsive dark theme
│   └── script.js           # BadAI class with config loading
├── menu.json               # Categorized AI prompts (5 categories)
├── settings.conf           # INI-format configuration
├── Dockerfile              # Node.js 20-alpine container
├── .github/workflows/      # Tailscale v3 + SSH deployment
└── package.json            # Express, ini, dotenv dependencies
```

### Technical Stack
- **Backend**: Node.js + Express with async/await patterns
- **Frontend**: Vanilla HTML/CSS/JavaScript (no external dependencies)
- **AI Integration**: REST APIs to LM Studio (localhost:1234) and OpenRouter
- **Configuration**: INI parsing with fallback defaults
- **Deployment**: Docker + GitHub Actions + Tailscale + SSH

## Configuration System

### settings.conf Structure
```ini
[ai_response]
max_tokens = 80              # Response length limit
temperature = 0.9            # AI creativity setting
concise_prompt = "..."       # System prompt for brevity

[ui]
response_min_height = 120    # CSS variable for response container
loading_timeout = 30000      # Frontend timeout setting

[server]
default_port = 3000          # Fallback port
api_timeout = 30000          # AI API timeout
```

### Environment Variables (.env)
```bash
LM_STUDIO_ADDRESS=localhost  # Local AI server IP/hostname
OPENROUTER_API_KEY=sk-...    # Cloud AI backup (safe in .env - not tracked)
PORT=3000                    # Server port
NODE_ENV=development         # Environment mode
```

## Key Implementation Details

### AI Integration Pattern
```javascript
async callAI(messages, useLocal = true) {
    const config = {
        model: useLocal ? 'local-model' : 'google/gemma-2-9b-it:free',
        messages: [...messages, {role: 'system', content: this.config.ai_response.concise_prompt}],
        max_tokens: this.config.ai_response.max_tokens,
        temperature: this.config.ai_response.temperature
    };
    
    const url = useLocal ? 
        `http://${process.env.LM_STUDIO_ADDRESS || 'localhost'}:1234/v1/chat/completions` :
        'https://openrouter.ai/api/v1/chat/completions';
    
    // API call with timeout and fallback logic
}
```

### Configuration Loading Pattern
```javascript
async loadConfig() {
    try {
        const configPath = path.join(__dirname, '../settings.conf');
        const configFile = await fs.readFile(configPath, 'utf8');
        this.config = ini.parse(configFile);
    } catch (error) {
        // Fallback to hardcoded defaults
        this.config = { /* defaults */ };
    }
}
```

### Frontend Architecture
- **BadAI Class**: Single-page application controller
- **Async Initialization**: Loads menu.json and settings.conf on startup
- **State Management**: currentView, currentCategory, currentPrompt tracking
- **UI Updates**: Dynamic CSS variable application from configuration
- **Error Handling**: Graceful fallbacks with user-friendly messages

### Deployment Pipeline
1. **Trigger**: Push to main branch
2. **Build**: Docker image with linux/amd64 platform
3. **Network**: Tailscale v3 OAuth authentication for VPN access
4. **Deploy**: Standard SSH commands (no third-party actions)
5. **Cleanup**: Automatic SSH key removal after deployment

## Security Measures
- ✅ No secrets in tracked files (.env excluded from git)
- ✅ GitHub Secrets for deployment credentials
- ✅ XSS protection with HTML sanitization
- ✅ Non-root Docker container user
- ✅ SSH key cleanup in CI/CD
- ✅ Environment variable separation from configuration

## GitHub Secrets Required
```
DEPLOY_SSH_KEY         # Private SSH key for server access
DEPLOY_HOST           # Tailscale IP of deployment server
DEPLOY_USER           # SSH username for deployment
LM_STUDIO_ADDRESS     # Tailscale IP of LM Studio server
OPENROUTER_API_KEY    # Cloud AI backup API key
TS_OAUTH_CLIENT_ID    # Tailscale OAuth Client ID
TS_OAUTH_SECRET       # Tailscale OAuth Secret
```

## Menu Categories Implemented
1. **Advice**: Bad, Silly, Cryptic, Existential advice prompts
2. **Fake Facts**: False, Absurd, Historical, Scientific "facts"
3. **Cocktail**: Terrible, Weird, Fancy, Healthy drink recipes
4. **Conspiracy**: Silly, Tech, Food, Weather conspiracy theories
5. **Insult**: Creative, Backhanded, Sarcastic, Witty insults

## Key User Feedback Addressed
- ✅ Hardcoded IPs → GitHub Secrets
- ✅ Unreadable markdown → HTML conversion with formatting
- ✅ Long responses → 80-token limits with concise prompts
- ✅ Third-party SSH action → Standard bash scripting
- ✅ Security concerns → Comprehensive credential management
- ✅ Configuration flexibility → INI-based settings system

## Development Commands
```bash
npm install              # Install dependencies
cp .env.example .env     # Set up environment
npm run dev             # Development server
npm start               # Production server
docker build -t badaiinasite .  # Build container
docker run -p 3000:3000 badaiinasite  # Run container
```

## Current State
The project is **production-ready** with:
- Complete implementation of all specified features
- Automated CI/CD pipeline configured
- Security best practices implemented
- Configuration system for easy customization
- Comprehensive documentation in README.md and CLAUDE.md
- MIT license applied

The application successfully bridges the gap between the original physical BAIIAB device and a modern web application while maintaining the core concept of providing entertainingly "bad" AI advice through a curated menu system.