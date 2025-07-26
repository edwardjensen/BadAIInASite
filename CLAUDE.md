# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the "Bad AI In A Site" web application - a web adaptation of the physical "Bad AI In A Box" (BAIIAB) project. The application hosts a chatbot that provides intentionally humorous "bad" advice through a menu-driven interface.

## Project Status

The project is actively developed with a working web application including frontend UI, backend API, AI integration, and live reload functionality for development.

## Key Technical Requirements

1. **Mobile-First Design**: Optimize for iPhone displays with fixed-position UI elements
2. **Menu-Driven Interaction**: Use `menu.json` for predefined prompts instead of free text input
3. **Dual AI Backend Support**:
   - Local: LM Studio API (http://localhost:1234/v1/chat/completions)
   - Cloud: OpenRouter API (https://openrouter.ai/api/v1/chat/completions)
4. **Containerization**: Must run in Docker with no external dependencies
5. **Automated Deployment**: GitHub Actions → Ubuntu VM on Tailscale VPN

## Development Commands

```bash
# Install dependencies
npm install

# Set up environment configuration
cp .env.example .env
# Edit .env with your LM Studio server address and actual OpenRouter API key
# (Safe to use real credentials in .env - this file is excluded from git)

# Development server (includes live reload)
npm run dev

# Production server
npm start

# Build Docker image
docker build -t badaiinasite .

# Run Docker container locally
docker run -p 3000:3000 badaiinasite
```

## Architecture Guidelines

### Frontend Structure
- Create a single-page application with menu-driven interface
- Implement responsive design focusing on mobile (iPhone) first
- Use fixed positioning for header and input area
- Keep the UI simple and focused on the chat interaction

### Backend Structure
- Implement API endpoint(s) for chat interactions
- Support both LM Studio and OpenRouter backends
- Handle API key management securely (environment variables)
- Implement proper error handling for offline scenarios

### File Organization
```
badaiinasite/
├── src/
│   └── server.js     # Express server with AI integration
├── public/           # Static frontend assets
│   ├── index.html    # Main application
│   ├── styles.css    # CSS styling
│   └── script.js     # Frontend JavaScript
├── .github/
│   └── workflows/    # GitHub Actions CI/CD
├── settings.conf     # Application configuration
├── menu.json         # Predefined AI prompts
├── Dockerfile        # Container configuration
└── package.json      # Node.js dependencies
```

## Important Implementation Notes

1. **Menu System**: The `menu.json` file contains categories and prompts based on the original BAIIAB project. Users select from predefined options rather than typing custom prompts. Menu updates can be deployed instantly without rebuilding the application.

2. **Configuration System**: The `settings.conf` file contains build-specific settings like AI response limits, UI parameters, and server timeouts. This is separate from environment variables and allows easy customization without code changes.

3. **AI Integration**: The server switches between LM Studio and OpenRouter based on configuration. Responses are limited by the `max_tokens` setting (default 80) for concise output matching the original BAIIAB thermal printer constraints.

4. **Response Formatting**: The frontend supports basic markdown formatting (bold, italic, line breaks) and safely renders HTML. Responses are displayed with proper styling.

5. **Deployment**: Dual deployment system with full releases (tag-based) and fast menu updates (push-based). Uses Tailscale v3 for secure network access and volume mounting for persistent menu configuration.

6. **Environment Configuration**: Uses dotenv for local development with `.env` file support (excluded from git).

7. **Live Reload**: Development mode includes automatic browser reload when frontend files change. Uses Socket.IO for WebSocket communication and chokidar for file watching.

8. **Version Management**: Build-time version injection ensures accurate version display in production. Automatic fallback to git commands in development mode.

## Deployment Configuration

### Dual Deployment System
The project features two distinct deployment workflows for maximum flexibility:

#### 1. Release Deployment (Full App Updates)
For version releases with code changes:
```bash
# Create and push a version tag to trigger full release pipeline
git tag v1.0.0
git push origin v1.0.0
```

**Workflow Features:**
- ✅ Automatic Docker image building with version info baked in
- ✅ GitHub release creation with auto-generated changelog
- ✅ Production deployment via Tailscale VPN
- ✅ Container cleanup (keeps last 3 versions)
- ✅ Menu.json reset to repository version
- ✅ Manual deployment testing via workflow_dispatch
- ✅ Prerelease detection for alpha/beta/rc/dev tags

#### 2. Menu-Only Deployment (Fast Updates)
For quick menu changes without full releases:
```bash
# Edit menu.json and push to main branch
git add menu.json
git commit -m "Update menu options"
git push origin main
```

**Workflow Features:**
- ⚡ Fast deployment (~30 seconds)
- 🔄 Container restart only (no rebuild)
- 📁 Volume-mounted menu.json for persistence
- 🚀 Instant menu updates without CI/CD overhead

### GitHub Secrets Required
The automated deployment requires these repository secrets:
- `DEPLOY_SSH_KEY`: Private SSH key for Ubuntu server access
- `DEPLOY_HOST`: Tailscale IP/hostname of deployment server (e.g., "100.106.49.116")
- `DEPLOY_USER`: Username for SSH access (e.g., "edwardjensen")
- `DEPLOY_MENU_PATH`: Server path for menu.json storage (e.g., "/media/develop/container-configs/badai")
- `LM_STUDIO_ADDRESS`: Tailscale IP/hostname of LM Studio server (e.g., "100.106.49.116")
- `OPENROUTER_API_KEY`: OpenRouter API key for cloud AI fallback
- `TS_OAUTH_CLIENT_ID`: Tailscale OAuth Client ID for GitHub Actions network access (v3)
- `TS_OAUTH_SECRET`: Tailscale OAuth Secret for GitHub Actions network access (v3)
- `NPM_DOCKER_NETWORK`: Docker network name for container networking (e.g., "npm_default")

### Local Deployment
For manual server deployment, set these environment variables:
```bash
export LM_STUDIO_ADDRESS="your-lm-studio-ip"  # defaults to localhost
export OPENROUTER_API_KEY="your-api-key"      # optional
./deploy-server.sh
```

## References

This project implements the specifications from the original Bad AI In A Box (BAIIAB) project by lastcoolnameleft. See the README.md for complete project documentation.