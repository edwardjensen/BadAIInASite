#!/bin/bash

# Bad AI In A Site - Server Deployment Script
# This script should be placed on the Ubuntu server (100.106.49.116)

set -e

echo "🤖 Bad AI In A Site - Server Deployment Script"
echo "=============================================="

# Configuration
CONTAINER_NAME="badaiinasite"
IMAGE_NAME="ghcr.io/edwardjensen/badaiinasite:latest"
PORT="3000"

# Function to check if Docker is running
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo "❌ Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    echo "✅ Docker is running"
}

# Function to stop and remove existing container
cleanup_existing() {
    echo "🧹 Cleaning up existing container..."
    
    if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
        echo "Stopping existing container..."
        docker stop $CONTAINER_NAME
    fi
    
    if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
        echo "Removing existing container..."
        docker rm $CONTAINER_NAME
    fi
    
    echo "✅ Cleanup completed"
}

# Function to pull latest image
pull_image() {
    echo "📥 Pulling latest image..."
    docker pull $IMAGE_NAME
    echo "✅ Image pulled successfully"
}

# Function to run the container
run_container() {
    echo "🚀 Starting new container..."
    
    # Set default LM Studio address if not provided
    LM_STUDIO_ADDRESS=${LM_STUDIO_ADDRESS:-"localhost"}
    
    # Check if OPENROUTER_API_KEY environment variable is set
    if [ -z "$OPENROUTER_API_KEY" ]; then
        echo "⚠️  Warning: OPENROUTER_API_KEY not set. Only local AI will be available."
        echo "   To set it: export OPENROUTER_API_KEY='your-key-here'"
    fi
    
    echo "🧠 LM Studio address: $LM_STUDIO_ADDRESS"
    
    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -p $PORT:3000 \
        -e LM_STUDIO_URL="http://$LM_STUDIO_ADDRESS:1234/v1/chat/completions" \
        ${OPENROUTER_API_KEY:+-e OPENROUTER_API_KEY="$OPENROUTER_API_KEY"} \
        $IMAGE_NAME
    
    echo "✅ Container started successfully"
}

# Function to show status
show_status() {
    echo "📊 Container status:"
    docker ps -f name=$CONTAINER_NAME
    
    echo ""
    echo "🌐 Application should be available at:"
    echo "   http://localhost:$PORT"
    echo "   http://$(hostname -I | awk '{print $1}'):$PORT (if accessible from network)"
    
    echo ""
    echo "📋 To view logs:"
    echo "   docker logs $CONTAINER_NAME"
    echo "   docker logs -f $CONTAINER_NAME  # Follow logs"
    
    echo ""
    echo "🛑 To stop the container:"
    echo "   docker stop $CONTAINER_NAME"
    
    echo ""
    echo "⚙️  Environment variables used:"
    echo "   LM_STUDIO_ADDRESS=${LM_STUDIO_ADDRESS}"
    echo "   OPENROUTER_API_KEY=${OPENROUTER_API_KEY:+***configured***}"
}

# Main execution
main() {
    check_docker
    cleanup_existing
    pull_image
    run_container
    show_status
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "The Bad AI is ready to give terrible advice! 🤖💭"
}

# Run main function
main "$@"