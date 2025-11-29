#!/bin/bash
# DocForge Docker Quick Start for Linux/macOS
# The ultimate zero-prerequisite setup - just Docker required

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SIMPLE=0
PRODUCTION=0
STOP=0
LOGS=0

# Output functions
write_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

write_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

write_error() {
    echo -e "${RED}❌ $1${NC}"
}

write_info() {
    echo -e "${CYAN}$1${NC}"
}

write_header() {
    clear
    echo -e "${WHITE}$1${NC}"
    echo -e "${WHITE}$(printf '=%.0s' {1..50})${NC}"
    echo
}

wait_for_enter() {
    local message="${1:-Press Enter to continue...}"
    echo
    read -p "$message"
}

# Platform detection
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Docker availability check
check_docker() {
    write_info "Checking Docker availability..."

    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            write_success "Docker is available and running"
            return 0
        else
            write_warning "Docker is installed but not running"
            if is_macos; then
                write_info "Please start Docker Desktop and try again"
            else
                write_info "Please start Docker service and try again"
                write_info "sudo systemctl start docker"
            fi
            return 1
        fi
    else
        write_error "Docker is not installed"
        write_info "Please install Docker first:"
        if is_macos; then
            write_info "  brew install --cask docker"
        else
            write_info "  Follow instructions at: https://docs.docker.com/get-docker/"
        fi
        return 1
    fi
}

# Start DocForge
start_docforge() {
    local is_production=${1:-0}

    write_header "🚀 Starting DocForge with Docker"

    # Check if docker-compose file exists
    local compose_file="docker-compose.simple.yml"
    if [[ "$is_production" -eq 1 ]]; then
        compose_file="docker-compose.yml"
    fi

    if [[ ! -f "$compose_file" ]]; then
        write_error "$compose_file not found. Please run this from the project root."
        wait_for_enter
        return 1
    fi

    write_info "🐳 Building and starting containers..."
    write_info "This may take a few minutes on the first run..."
    echo

    # Build and start containers
    if [[ "$is_production" -eq 1 ]]; then
        # Production mode - build frontend first
        write_info "Building frontend..."
        docker-compose --profile build up docforge-frontend-builder

        write_info "Starting production services..."
        if docker-compose up -d; then
            show_success_production
        else
            write_error "Failed to start containers"
            return 1
        fi
    else
        # Simple development mode
        write_info "Starting development services..."
        if docker-compose -f "$compose_file" up -d; then
            show_success_simple
        else
            write_error "Failed to start containers"
            return 1
        fi
    fi
}

show_success_simple() {
    write_success "DocForge is starting up!"
    echo
    write_info "🌐 Application URLs:"
    echo -e "   📱 Frontend: ${WHITE}http://localhost:5173${NC}"
    echo -e "   📊 API: ${WHITE}http://localhost:5000${NC}"
    echo -e "   📚 API Docs: ${WHITE}http://localhost:5000/swagger${NC}"
    echo
    write_info "🔧 Management Commands:"
    echo -e "   View logs: ${CYAN}./scripts/docker-quick-start.sh --logs${NC}"
    echo -e "   Stop app: ${CYAN}./scripts/docker-quick-start.sh --stop${NC}"
    echo -e "   Restart: ${CYAN}docker-compose restart${NC}"
    echo

    wait_for_enter "Press Enter to open the application in your browser..."
    open_browser "http://localhost:5173"
}

show_success_production() {
    write_success "DocForge is starting up!"
    echo
    write_info "🌐 Application URLs:"
    echo -e "   📱 Web App: ${WHITE}http://localhost${NC}"
    echo -e "   📊 API: ${WHITE}http://localhost/api${NC}"
    echo -e "   📚 API Docs: ${WHITE}http://localhost/swagger${NC}"
    echo
    write_info "🔧 Management Commands:"
    echo -e "   View logs: ${CYAN}./scripts/docker-quick-start.sh --logs${NC}"
    echo -e "   Stop app: ${CYAN}./scripts/docker-quick-start.sh --stop${NC}"
    echo -e "   Restart: ${CYAN}docker-compose restart${NC}"
    echo

    wait_for_enter "Press Enter to open the application in your browser..."
    open_browser "http://localhost"
}

# Open browser helper
open_browser() {
    local url="$1"

    if grep -q Microsoft /proc/version 2>/dev/null; then
        # WSL
        explorer.exe "$url"
    elif command -v xdg-open >/dev/null 2>&1; then
        # Linux
        xdg-open "$url"
    elif command -v open >/dev/null 2>&1; then
        # macOS
        open "$url"
    else
        write_info "Please open $url manually in your browser"
    fi
}

# Stop DocForge
stop_docforge() {
    write_header "🛑 Stopping DocForge"

    write_info "Stopping all DocForge containers..."

    # Stop both versions
    docker-compose down 2>/dev/null || true
    docker-compose -f docker-compose.simple.yml down 2>/dev/null || true

    write_success "All DocForge containers stopped"
    write_info "Data volumes are preserved. Use 'docker system prune' to clean up."

    wait_for_enter
}

# Show logs
show_logs() {
    write_header "📋 DocForge Logs"

    write_info "Showing logs from all containers..."
    write_info "Press Ctrl+C to exit"
    echo

    if docker-compose ps | grep -q "Up"; then
        docker-compose logs -f
    else
        write_warning "No containers are currently running"
        write_info "Try starting DocForge first, or use:"
        write_info "  docker-compose logs docforge-api"
        write_info "  docker-compose logs docforge-frontend"
    fi

    wait_for_enter
}

# Show menu
show_menu() {
    write_header "[DOCKER] DocForge Docker Quick Start"

    echo -e "${CYAN}Choose your deployment mode:${NC}"
    echo
    echo -e "${GREEN}1) [DEV] Quick Start (Development)${NC}"
    echo -e "${GRAY}   * Fast startup, live reloading${NC}"
    echo -e "${GRAY}   * Frontend: http://localhost:5173${NC}"
    echo -e "${GRAY}   * API: http://localhost:5000${NC}"
    echo
    echo -e "${YELLOW}2) [PROD] Production Mode${NC}"
    echo -e "${GRAY}   * Optimized build, single port${NC}"
    echo -e "${GRAY}   * Everything: http://localhost${NC}"
    echo -e "${GRAY}   * Built-in reverse proxy${NC}"
    echo
    echo -e "3) [LOGS] View Logs"
    echo -e "4) [STOP] Stop Services"
    echo -e "5) [EXIT] Exit"
    echo

    while true; do
        read -p "Select option (1-5): " choice
        case "$choice" in
            1|2|3|4|5) break ;;
            *) echo "Please enter 1, 2, 3, 4, or 5" ;;
        esac
    done

    case "$choice" in
        1)
            start_docforge 0
            ;;
        2)
            start_docforge 1
            ;;
        3)
            show_logs
            ;;
        4)
            stop_docforge
            ;;
        5)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --simple)
            SIMPLE=1
            shift
            ;;
        --production)
            PRODUCTION=1
            shift
            ;;
        --stop)
            STOP=1
            shift
            ;;
        --logs)
            LOGS=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --simple         Start in simple development mode"
            echo "  --production     Start in production mode"
            echo "  --stop           Stop all services"
            echo "  --logs           Show logs"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Main execution
if [[ "$STOP" -eq 1 ]]; then
    stop_docforge
elif [[ "$LOGS" -eq 1 ]]; then
    show_logs
else
    # Check Docker availability first
    if check_docker; then
        if [[ "$SIMPLE" -eq 1 ]]; then
            start_docforge 0
        elif [[ "$PRODUCTION" -eq 1 ]]; then
            start_docforge 1
        else
            show_menu
        fi
    else
        echo
        write_info "Docker setup instructions:"
        if is_macos; then
            echo -e "${WHITE}1. Install Docker Desktop:${NC}"
            echo -e "   brew install --cask docker"
        else
            echo -e "${WHITE}1. Install Docker:${NC}"
            echo -e "   Follow instructions at: https://docs.docker.com/get-docker/"
        fi
        echo
        echo -e "${WHITE}2. Start Docker${NC}"
        if is_linux; then
            echo -e "   sudo systemctl start docker"
            echo -e "   sudo systemctl enable docker"
        fi
        echo
        echo -e "${WHITE}3. Run this script again${NC}"
        echo
        wait_for_enter
    fi
fi