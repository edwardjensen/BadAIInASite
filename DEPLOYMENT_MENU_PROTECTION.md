# Custom Menu Protection

## Overview

The BadAIInASite deployment system includes automatic protection for custom menu.json files in production environments. This prevents CI/CD processes from accidentally overwriting manual customizations.

## How It Works

### First Deployment
- Uses the repository's `menu.json` as the initial menu
- Sets up the volume mount for persistent menu storage

### Subsequent Deployments
- **Checks for existing menu**: Before overwriting, checks if a menu.json already exists
- **Preserves custom files**: If found, the existing menu is kept unchanged
- **Logs actions**: Clear console output shows what action was taken

## Deployment Behaviors

### 🏷️ Release Deployment (Full App)
```bash
# In release-and-deploy.yml workflow
if [ -f "$DEPLOY_MENU_PATH/menu.json" ]; then
  echo "📋 Custom menu.json found - preserving existing file"
  # Keeps existing menu
else
  echo "📋 No custom menu.json found - installing default from repository..."
  # Installs repository menu
fi
```

### ⚡ Menu-Only Deployment
```bash
# In deploy-menu.yml workflow
if [ "$CUSTOM_MENU_EXISTS" = "true" ]; then
  echo "📋 Custom menu.json detected on server"
  echo "⚠️  Skipping menu update to preserve custom configuration"
  # No changes made to existing menu
else
  # Deploys repository menu
fi
```

## Manual Management

### Check for Custom Menu
```bash
ssh user@server "ls -la /path/to/menu/menu.json"
```

### Force Update from Repository
```bash
# Remove custom menu (this will allow next deployment to update)
ssh user@server "rm /path/to/menu/menu.json"

# Then trigger deployment via:
# - Push to main branch (for menu-only deployment)
# - Create new version tag (for full deployment)
```

## Benefits

1. **No accidental overwrites**: Production customizations are safe
2. **Clear logging**: Always know what the deployment system is doing
3. **Flexible override**: Easy to force updates when needed
4. **Zero configuration**: Works automatically without setup

## Example Console Output

### With Custom Menu (Protected)
```console
📋 Custom menu.json found - preserving existing file
📋 Keeping custom menu.json (not updating from repository)
```

### Without Custom Menu (Updated)
```console
📋 No custom menu.json found - installing default from repository...
```

This system ensures that your production environment can have customized menus that won't be lost during routine deployments!
