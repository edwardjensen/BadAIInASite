# Production Debugging Guide

## Check Container Logs

To debug the production deployment, check the container logs to see what environment variables are being used:

```bash
# Check if container is running
docker ps | grep badaiinasite

# View recent logs
docker logs badaiinasite

# Follow logs in real-time
docker logs -f badaiinasite

# View last 50 lines of logs
docker logs --tail 50 badaiinasite
```

## Expected Debug Output

With the new debug logging, you should see something like:

```
🔧 Environment Debug:
   LM_STUDIO_ADDRESS: not set
   LM_STUDIO_URL: http://100.106.49.116:1234/v1/chat/completions
   OPENROUTER_API_KEY: ***configured***
   Constructed LM Studio URL: http://100.106.49.116:1234/v1/chat/completions
```

## Check GitHub Secrets

Verify these secrets are set in your GitHub repository:

1. Go to: `https://github.com/edwardjensen/BadAIInASite/settings/secrets/actions`
2. Confirm these secrets exist:
   - `LM_STUDIO_ADDRESS` (should be the IP of your LM Studio server, e.g., "100.106.49.116")
   - `OPENROUTER_API_KEY` (your OpenRouter API key)

## Test Connectivity from Container

To test if the container can reach LM Studio:

```bash
# Enter the running container
docker exec -it badaiinasite sh

# Test connectivity to LM Studio
wget -qO- http://YOUR_LM_STUDIO_IP:1234/v1/models || echo "Cannot reach LM Studio"

# Check environment variables inside container
env | grep -E "(LM_STUDIO|OPENROUTER)"

# Exit container
exit
```

## Manual Container Test

To test with a temporary container:

```bash
# Run a test container with the same environment
docker run --rm -it \
  -e OPENROUTER_API_KEY="your-key-here" \
  -e LM_STUDIO_URL="http://your-lm-studio-ip:1234/v1/chat/completions" \
  ghcr.io/edwardjensen/badaiinasite:latest \
  sh

# Inside the container, test the URLs
wget -qO- $LM_STUDIO_URL/models
```

## Common Issues

### LM Studio Not Accessible
- **Check**: Is LM Studio running on the target machine?
- **Check**: Is port 1234 open and accessible from the Docker container?
- **Check**: Is the IP address correct in `LM_STUDIO_ADDRESS` secret?

### OpenRouter Not Working
- **Check**: Is the `OPENROUTER_API_KEY` secret set correctly?
- **Check**: Is the API key valid and has credits?

### Container Not Getting Environment Variables
- **Check**: Did the GitHub Actions workflow complete successfully?
- **Check**: Are the secrets properly configured in GitHub repository settings?

## Redeploy with Debug Logs

The latest version includes debug logging. To see the new logs:

1. Create a new release tag: `git tag v1.2.0-rc5 && git push origin v1.2.0-rc5`
2. Wait for GitHub Actions deployment to complete
3. Check the new container logs: `docker logs badaiinasite`

You should now see detailed environment variable information in the logs!
