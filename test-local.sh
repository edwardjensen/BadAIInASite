#!/bin/bash
# Shell script to build and test BadAIInASite container locally
# Cross-platform alternative to the PowerShell script

set -e

# Default configuration
CONTAINER_NAME="badaiinasite-test"
IMAGE_NAME="badaiinasite-local-test"
LM_STUDIO_MODEL="${LM_STUDIO_MODEL:-local-model}"
OPENROUTER_MODEL="${OPENROUTER_MODEL:-google/gemini-2.0-flash-exp:free}"
LM_STUDIO_ADDRESS="${LM_STUDIO_ADDRESS:-localhost}"
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}"
PORT="${PORT:-3000}"
NO_BUILD=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

function show_help() {
    cat << EOF
BadAIInASite Local Test Script

USAGE:
    ./test-local.sh [OPTIONS] [COMMAND]

COMMANDS:
    run       Build and run the test container (default)
    stop      Stop and remove the test container
    logs      Show container logs
    help      Show this help message

OPTIONS:
    --lm-studio-model <model>     LM Studio model name
    --openrouter-model <model>    OpenRouter model name  
    --lm-studio-address <address> LM Studio server address
    --openrouter-api-key <key>    OpenRouter API key
    --port <port>                 Local port to bind
    --no-build                    Skip building, use existing image

ENVIRONMENT VARIABLES:
    LM_STUDIO_MODEL      Default: "local-model"
    OPENROUTER_MODEL     Default: "google/gemini-2.0-flash-exp:free"
    LM_STUDIO_ADDRESS    Default: "localhost"
    OPENROUTER_API_KEY   Default: "" (empty)
    PORT                 Default: 3000

EXAMPLES:
    # Build and run with defaults
    ./test-local.sh

    # Test with specific models
    ./test-local.sh --lm-studio-model "deepseek-r1-distill-llama-8b"

    # Test with environment variables
    LM_STUDIO_MODEL="phi-4" OPENROUTER_API_KEY="sk-..." ./test-local.sh

    # Show logs
    ./test-local.sh logs

    # Stop container
    ./test-local.sh stop
EOF
}

function log_step() {
    echo -e "${CYAN}🔄 $1${NC}"
}

function log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

function log_error() {
    echo -e "${RED}❌ $1${NC}"
}

function log_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

function stop_container() {
    log_step "Stopping and removing test container..."
    
    # Stop container if running
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        docker stop "$CONTAINER_NAME" > /dev/null
        log_success "Container stopped"
    fi
    
    # Remove container if exists
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        docker rm "$CONTAINER_NAME" > /dev/null
        log_success "Container removed"
    fi
}

function show_logs() {
    log_step "Showing container logs..."
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        docker logs "$CONTAINER_NAME"
    else
        log_error "Test container '$CONTAINER_NAME' not found"
        exit 1
    fi
}

function build_image() {
    log_step "Building Docker image with custom model configuration..."
    log_info "LM Studio Model: $LM_STUDIO_MODEL"
    log_info "OpenRouter Model: $OPENROUTER_MODEL"
    
    docker build \
        --build-arg "DEFAULT_LMSTUDIO_MODEL=$LM_STUDIO_MODEL" \
        --build-arg "DEFAULT_OPENROUTER_MODEL=$OPENROUTER_MODEL" \
        --build-arg "BUILD_VERSION=local-test" \
        --build-arg "BUILD_DATE=$(date -u +%Y-%m-%dTH:%M:%SZ)" \
        --build-arg "BUILD_COMMIT=local-test" \
        -t "$IMAGE_NAME" .
    
    log_success "Image built successfully: $IMAGE_NAME"
}

function start_container() {
    log_step "Starting test container..."
    
    # Prepare environment variables
    ENV_VARS=(
        "-e" "NODE_ENV=development"
        "-e" "LM_STUDIO_ADDRESS=$LM_STUDIO_ADDRESS"
        "-e" "DEFAULT_LMSTUDIO_MODEL=$LM_STUDIO_MODEL"
        "-e" "DEFAULT_OPENROUTER_MODEL=$OPENROUTER_MODEL"
    )
    
    # Add OpenRouter API key if provided
    if [[ -n "$OPENROUTER_API_KEY" ]]; then
        ENV_VARS+=("-e" "OPENROUTER_API_KEY=$OPENROUTER_API_KEY")
        log_info "OpenRouter API key configured"
    else
        log_info "No OpenRouter API key provided (local-only mode)"
    fi
    
    # Run container
    CONTAINER_ID=$(docker run -d \
        "${ENV_VARS[@]}" \
        --name "$CONTAINER_NAME" \
        -p "$PORT:3000" \
        --restart no \
        "$IMAGE_NAME")
    
    log_success "Container started with ID: ${CONTAINER_ID:0:12}"
    
    # Wait for container to start
    sleep 3
    
    # Check if container is running
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log_success "Container is running successfully"
        log_info "🌐 Access the application at: http://localhost:$PORT"
        log_info "🔍 View logs with: ./test-local.sh logs"
        log_info "⏹️  Stop container with: ./test-local.sh stop"
        
        # Show initial logs
        echo -e "\n${MAGENTA}📋 Initial container logs:${NC}"
        docker logs "$CONTAINER_NAME"
    else
        log_error "Container failed to start"
        echo -e "\n${RED}📋 Container logs:${NC}"
        docker logs "$CONTAINER_NAME"
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --lm-studio-model)
            LM_STUDIO_MODEL="$2"
            shift 2
            ;;
        --openrouter-model)
            OPENROUTER_MODEL="$2"
            shift 2
            ;;
        --lm-studio-address)
            LM_STUDIO_ADDRESS="$2"
            shift 2
            ;;
        --openrouter-api-key)
            OPENROUTER_API_KEY="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --no-build)
            NO_BUILD=true
            shift
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        stop)
            stop_container
            exit 0
            ;;
        logs)
            show_logs
            exit 0
            ;;
        run)
            # Default action, continue
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main execution
echo -e "${MAGENTA}🤖 BadAIInASite Local Test Script${NC}"
echo -e "${MAGENTA}=================================${NC}"

# Stop any existing test container
stop_container

# Build image unless --no-build is specified
if [[ "$NO_BUILD" == "false" ]]; then
    build_image
else
    log_info "Skipping build (using existing image: $IMAGE_NAME)"
    
    # Check if image exists
    if ! docker images -q "$IMAGE_NAME" | grep -q .; then
        log_error "Image '$IMAGE_NAME' not found. Run without --no-build to build it first."
        exit 1
    fi
fi

# Start the container
start_container

echo -e "\n${GREEN}🎉 Test environment ready!${NC}"
echo -e "   ${GREEN}Application: http://localhost:$PORT${NC}"
echo -e "   ${GREEN}LM Studio: http://$LM_STUDIO_ADDRESS:1234${NC}"
