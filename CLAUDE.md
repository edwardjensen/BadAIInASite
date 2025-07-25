# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the "Bad AI In A Site" web application - a web adaptation of the physical "Bad AI In A Box" (BAIIAB) project. The application hosts a chatbot that provides intentionally humorous "bad" advice through a menu-driven interface.

## Project Status

**IMPORTANT**: This is a greenfield project in the initial planning phase. The codebase currently only contains a specification document (`/prompt/context.md`). All implementation needs to be created from scratch following the specifications.

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
# Edit .env with your LM Studio server address and OpenRouter API key

# Development server
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
│   ├── frontend/     # Client-side code
│   ├── backend/      # Server-side code
│   └── shared/       # Shared utilities/types
├── public/           # Static assets
├── test/             # Test files
├── .github/
│   └── workflows/    # GitHub Actions CI/CD
├── Dockerfile
├── menu.json         # Predefined prompts
└── package.json
```

## Important Implementation Notes

1. **Menu System**: The `menu.json` file contains categories and prompts. Users select from predefined options rather than typing custom prompts. Prompts are optimized for brevity.

2. **AI Integration**: The server switches between LM Studio and OpenRouter based on configuration. Responses are limited to ~80 tokens for concise output matching the original BAIIAB constraints.

3. **Response Formatting**: The frontend supports basic markdown formatting (bold, italic, line breaks) and safely renders HTML. Responses are displayed with proper styling.

4. **Deployment**: The GitHub Actions workflow builds the Docker image and deploys to the specified Ubuntu VM using configurable secrets for LM Studio address and OpenRouter API key.

5. **Environment Configuration**: Uses dotenv for local development with `.env` file support (excluded from git).

## Deployment Configuration

### GitHub Secrets Required
The automated deployment requires these repository secrets:
- `DEPLOY_SSH_KEY`: Private SSH key for Ubuntu server access
- `DEPLOY_HOST`: IP/hostname of deployment server (e.g., "100.106.49.116")
- `DEPLOY_USER`: Username for SSH access (e.g., "edwardjensen")
- `LM_STUDIO_ADDRESS`: IP/hostname of LM Studio server (e.g., "100.106.49.116")
- `OPENROUTER_API_KEY`: OpenRouter API key for cloud AI fallback

### Local Deployment
For manual server deployment, set these environment variables:
```bash
export LM_STUDIO_ADDRESS="your-lm-studio-ip"  # defaults to localhost
export OPENROUTER_API_KEY="your-api-key"      # optional
./deploy-server.sh
```

## References

For detailed requirements and specifications, see `/prompt/context.md`