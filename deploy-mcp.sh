#!/bin/bash

echo "🚀 Deploying LibreChat with /mcp base path..."

# Stop existing containers
echo "📦 Stopping existing containers..."
docker-compose -f docker-compose.mcp.yml down

# Remove old containers and images (optional)
read -p "🗑️  Remove old LibreChat-MCP containers and images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker container rm LibreChat-MCP 2>/dev/null || true
    docker image rm $(docker images | grep librechat-mcp | awk '{print $3}') 2>/dev/null || true
fi

# Build and start services
echo "🔨 Building custom LibreChat image with /mcp base path..."
docker-compose -f docker-compose.mcp.yml up -d --build

echo "✅ Deployment complete!"
echo "📋 Container status:"
docker-compose -f docker-compose.mcp.yml ps

echo ""
echo "🌐 Your LibreChat should now be accessible at:"
echo "   - Local: http://localhost:3080"
echo "   - Production: https://propertyads.co/mcp"
echo ""
echo "📊 To view logs:"
echo "   docker-compose -f docker-compose.mcp.yml logs -f api" 