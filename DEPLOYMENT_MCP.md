# Deploying LibreChat on a Subpath (/mcp)

This document explains how to deploy LibreChat when serving it from a subpath like `https://propertyads.co/mcp/` instead of the root domain.

## Problem
When serving LibreChat from a subpath, static assets (CSS, JS files) try to load from the root domain instead of the subpath, causing MIME type errors like:
```
Loading module from "https://propertyads.co/assets/..." was blocked because of a disallowed MIME type ("text/html").
```

## Solution 1: Custom Build (Recommended)

### Steps:

1. **Use the provided custom Docker configuration:**
   ```bash
   # Make the deployment script executable
   chmod +x deploy-mcp.sh
   
   # Run the deployment
   ./deploy-mcp.sh
   ```

2. **Manual deployment:**
   ```bash
   # Stop existing containers
   docker-compose down
   
   # Build and start with custom configuration
   docker-compose -f docker-compose.mcp.yml up -d --build
   ```

### What this does:
- Builds LibreChat from source with `VITE_BASE_PATH=/mcp/`
- Configures all static assets to load from the correct subpath
- Creates a custom container with the proper base path

## Solution 2: Reverse Proxy Configuration (Alternative)

If you prefer to use the pre-built image, configure your reverse proxy to handle static assets:

### Apache Configuration:
```apache
<VirtualHost *:80>
    ServerName propertyads.co
    
    # Proxy API calls
    ProxyPass /mcp/api/ http://localhost:3080/api/
    ProxyPassReverse /mcp/api/ http://localhost:3080/api/
    
    # Proxy OAuth
    ProxyPass /mcp/oauth/ http://localhost:3080/oauth/
    ProxyPassReverse /mcp/oauth/ http://localhost:3080/oauth/
    
    # Serve static assets with correct path rewriting
    ProxyPass /mcp/assets/ http://localhost:3080/assets/
    ProxyPassReverse /mcp/assets/ http://localhost:3080/assets/
    
    # Handle the main application
    ProxyPass /mcp/ http://localhost:3080/
    ProxyPassReverse /mcp/ http://localhost:3080/
    
    # Rewrite asset URLs in HTML responses
    ProxyPassReverse /mcp/ http://localhost:3080/
    ProxyHTMLEnable On
    ProxyHTMLURLMap http://localhost:3080/ /mcp/
    ProxyHTMLURLMap / /mcp/
</VirtualHost>
```

### Nginx Configuration:
```nginx
server {
    listen 80;
    server_name propertyads.co;
    
    location /mcp/ {
        proxy_pass http://localhost:3080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Handle WebSocket connections
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Rewrite asset URLs
        sub_filter 'src="/' 'src="/mcp/';
        sub_filter 'href="/' 'href="/mcp/';
        sub_filter_once off;
    }
    
    # Serve static assets directly
    location /mcp/assets/ {
        proxy_pass http://localhost:3080/assets/;
    }
}
```

## Verification

After deployment, verify the setup:

1. **Check container status:**
   ```bash
   docker-compose -f docker-compose.mcp.yml ps
   ```

2. **View logs:**
   ```bash
   docker-compose -f docker-compose.mcp.yml logs -f api
   ```

3. **Test asset loading:**
   - Open browser developer tools
   - Navigate to `https://propertyads.co/mcp`
   - Check that all assets load from `/mcp/assets/` instead of `/assets/`

## Environment Variables

The custom build uses these environment variables:

- `VITE_BASE_PATH=/mcp/` - Sets the base path for frontend assets
- `PORT=3080` - Application port (default)
- `UID` and `GID` - User permissions for Docker

## Troubleshooting

### Assets still loading from root:
- Ensure you're using the custom build (`docker-compose.mcp.yml`)
- Verify `VITE_BASE_PATH` is set correctly during build
- Clear browser cache

### 404 errors on API calls:
- Check your reverse proxy configuration
- Ensure API endpoints are proxied to `/api/` not `/mcp/api/`

### Build errors:
- Ensure Node.js dependencies are available
- Check Docker build logs: `docker-compose -f docker-compose.mcp.yml logs`

## Files Created

- `Dockerfile.custom` - Custom Dockerfile with proper base path
- `docker-compose.mcp.yml` - Docker Compose configuration for subpath deployment
- `deploy-mcp.sh` - Deployment script
- `DEPLOYMENT_MCP.md` - This documentation

## Notes

- The custom build will take longer than using the pre-built image
- Static assets will be correctly configured for the `/mcp/` subpath
- The service worker and PWA manifest will also respect the base path 