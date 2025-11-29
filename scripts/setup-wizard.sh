#!/bin/bash
# DocForge Setup Wizard for Linux/macOS
# Interactive setup wizard with Docker and native setup options

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SKIP_DOCKER=${SKIP_DOCKER:-0}
FORCE_NATIVE=${FORCE_NATIVE:-0}

# Color output functions
write_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

write_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

write_error() {
    echo -e "${RED}✗ $1${NC}"
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
check_docker_availability() {
    write_info "Checking Docker availability..."

    # Check if Docker is installed
    if command -v docker >/dev/null 2>&1; then
        # Check if Docker daemon is running
        if docker info >/dev/null 2>&1; then
            write_success "Docker is available and running"
            return 0
        else
            write_warning "Docker is installed but not running"
            if is_macos; then
                write_info "  Please start Docker Desktop and try again"
            else
                write_info "  Please start Docker service and try again"
                write_info "  sudo systemctl start docker"
            fi
            return 1
        fi
    else
        write_warning "Docker is not installed"
        return 1
    fi
}

# Welcome screen
show_welcome() {
    write_header "🚀 Welcome to DocForge!"
    echo "DocForge is a powerful document generation system that combines:"
    echo
    echo "• .NET 8 Web API backend"
    echo "• React frontend with Vite"
    echo "• PDF generation using headless Chrome"
    echo "• Template-based document creation"
    echo
    echo "This wizard will help you get DocForge running on your system."
    echo
    wait_for_enter
}

# Setup options screen
show_setup_options() {
    write_header "Choose Your Setup Method"
    echo "How would you like to run DocForge?"
    echo

    # Check Docker availability first
    local docker_available=0
    if [[ "$SKIP_DOCKER" != "1" ]]; then
        if check_docker_availability; then
            docker_available=1
        fi
    fi

    if [[ "$docker_available" == "1" && "$FORCE_NATIVE" != "1" ]]; then
        echo -e "1) 🐳 Docker Setup (Recommended - 5 minutes)" "${GREEN}"
        echo -e "   ✓ No dependencies required" "${CYAN}"
        echo -e "   ✓ Works immediately" "${CYAN}"
        echo -e "   ✓ Isolated environment" "${CYAN}"
        echo

        echo -e "2) 🔧 Native Setup (15 minutes)" "${YELLOW}"
        echo -e "   ✓ Full development environment" "${CYAN}"
        echo -e "   ✓ Direct code access" "${CYAN}"
        echo -e "   ✓ Customizable configuration" "${CYAN}"
        echo

        echo -e "3) 📋 Compare Options" "${CYAN}"
        echo

        while true; do
            read -p "Select option (1-3): " choice
            case "$choice" in
                1|2|3) break ;;
                *) echo "Please enter 1, 2, or 3" ;;
            esac
        done

        echo "$choice"
    else
        write_warning "Docker is not available or was skipped"
        echo
        echo "🔧 Setting up native development environment..."
        echo
        echo "This will install the following:"
        echo "• .NET 8 SDK"
        echo "• Node.js 18+"
        echo "• Git"
        echo "• (Optional) Visual Studio Code"
        echo

        read -p "Continue with native setup? (Y/n): " choice
        if [[ "$choice" == "n" || "$choice" == "N" ]]; then
            write_info "Setup cancelled. Please install Docker first and try again."
            exit 0
        fi

        echo "2"  # Native setup
    fi
}

# Comparison screen
show_comparison() {
    write_header "Setup Method Comparison"
    echo

    echo -e "🐳 Docker Setup:" "${GREEN}"
    echo "  PROS:" "${CYAN}"
    echo "  • No local dependencies to install" "${CYAN}"
    echo "  • Consistent environment across machines" "${CYAN}"
    echo "  • Easy to start fresh (docker-compose down/up)" "${CYAN}"
    echo "  • No conflicts with existing software" "${CYAN}"
    echo
    echo "  CONS:" "${CYAN}"
    echo "  • Requires Docker installation" "${CYAN}"
    echo "  • Slower initial startup" "${CYAN}"
    echo "  • Uses more disk space" "${CYAN}"
    echo "  • More complex for debugging" "${CYAN}"
    echo

    echo -e "🔧 Native Setup:" "${YELLOW}"
    echo "  PROS:" "${CYAN}"
    echo "  • Full development environment" "${CYAN}"
    echo "  • Direct access to code and tools" "${CYAN}"
    echo "  • Faster startup and compilation" "${CYAN}"
    echo "  • Easier debugging and customization" "${CYAN}"
    echo "  • Less disk space usage" "${CYAN}"
    echo
    echo "  CONS:" "${CYAN}"
    echo "  • Requires installing multiple dependencies" "${CYAN}"
    echo "  • May conflict with existing software versions" "${CYAN}"
    echo "  • Platform-specific setup required" "${CYAN}"
    echo

    wait_for_enter "Press Enter to return to options..."
    echo "show-options"
}

# Docker setup
start_docker_setup() {
    write_header "🐳 Docker Setup"
    echo "Setting up DocForge with Docker containers..."
    echo

    # Check if we're in the right directory
    if [[ ! -f "docker-compose.yml" ]]; then
        write_error "docker-compose.yml not found. Please run this script from the project root."
        wait_for_enter
        return 1
    fi

    write_info "Building Docker images..."
    if docker-compose build; then
        write_success "Docker images built successfully"
    else
        write_error "Docker build failed"
        write_warning "Please check the error messages above and try again."
        wait_for_enter
        return 1
    fi

    write_info "Starting containers..."
    if docker-compose up -d; then
        write_success "DocForge is now running!"
        echo
        echo "🌐 Application URLs:" "${CYAN}"
        echo -e "   API: http://localhost:5000" "${WHITE}"
        echo -e "   API Documentation: http://localhost:5000/swagger" "${WHITE}"
        echo
        echo "🔧 Management Commands:" "${CYAN}"
        echo -e "   View logs: docker-compose logs -f" "${CYAN}"
        echo -e "   Stop application: docker-compose down" "${CYAN}"
        echo -e "   Restart application: docker-compose restart" "${CYAN}"
        echo

        wait_for_enter "Press Enter to open the application in your browser..."

        # Try to open browser
        if command -v xdg-open >/dev/null 2>&1; then
            xdg-open http://localhost:5000
        elif command -v open >/dev/null 2>&1; then
            open http://localhost:5000
        else
            write_info "Please open http://localhost:5000 in your browser"
        fi
    else
        write_error "Failed to start containers"
        write_warning "Please check the error messages above."
    fi
}

# Native setup
start_native_setup() {
    write_header "🔧 Native Setup"
    echo "Setting up native development environment..."
    echo

    # Check if dependency checker script exists
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local dependency_checker="$script_dir/check-dependencies.sh"

    if [[ ! -f "$dependency_checker" ]]; then
        write_error "Dependency checker script not found: $dependency_checker"
        wait_for_enter
        return 1
    fi

    # Make sure it's executable
    chmod +x "$dependency_checker"

    write_info "Checking and installing dependencies..."
    echo

    # Run dependency checker with auto-install
    if "$dependency_checker" --auto-install; then
        write_success "All dependencies installed successfully!"
    else
        write_warning "Some dependencies may not have installed correctly"
        write_info "You can try running the dependency checker manually:"
        write_info "   ./scripts/check-dependencies.sh --auto-install"
    fi

    echo
    write_info "Setting up project dependencies..."

    # Restore .NET dependencies
    write_info "Restoring .NET packages..."
    if dotnet restore; then
        write_success ".NET packages restored"
    else
        write_warning ".NET package restore had issues"
    fi

    # Install npm dependencies
    write_info "Installing frontend dependencies..."
    if [[ -d "DocumentGenerator.Client" && -f "DocumentGenerator.Client/package.json" ]]; then
        pushd DocumentGenerator.Client >/dev/null
        if npm install; then
            write_success "Frontend dependencies installed"
        else
            write_warning "Frontend dependency installation had issues"
        fi
        popd >/dev/null
    else
        write_warning "Frontend package.json not found"
    fi

    echo
    write_success "Native setup completed!"
    echo
    echo "🚀 Next Steps:" "${CYAN}"
    echo -e "   1. Run: ./docforge.sh" "${WHITE}"
    echo -e "   2. Select option 2 to start the backend" "${WHITE}"
    echo -e "   3. Select option 3 to start the frontend" "${WHITE}"
    echo -e "   4. Select option 8 to open in your browser" "${WHITE}"
    echo
    echo -e "💡 Or use option 4 to start both services at once!" "${YELLOW}"
    echo

    wait_for_enter "Press Enter to start the DocForge CLI..."

    # Start the DocForge CLI
    local docforge_cli="$script_dir/../docforge.sh"
    if [[ -f "$docforge_cli" ]]; then
        chmod +x "$docforge_cli"
        exec "$docforge_cli"
    else
        write_warning "DocForge CLI not found. Please run: ./docforge.sh"
    fi
}

# Error handling
handle_error() {
    local exit_code=$?
    local line_number=$1

    write_error "Setup wizard encountered an error on line $line_number"
    echo
    echo "If this error persists, please:"
    echo "1. Check the error message above"
    echo "2. Ensure you have sufficient disk space"
    echo "3. Try running with appropriate permissions"
    echo "4. Visit https://github.com/your-repo/docforge for troubleshooting"
    echo
    wait_for_enter

    exit $exit_code
}

# Main execution
main() {
    # Set up error handling
    trap 'handle_error $LINENO' ERR

    show_welcome

    while true; do
        local choice=$(show_setup_options)

        case "$choice" in
            1)
                start_docker_setup
                break
                ;;
            2)
                start_native_setup
                break
                ;;
            3)
                local result=$(show_comparison)
                if [[ "$result" == "show-options" ]]; then
                    continue
                fi
                ;;
        esac
    done
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-docker)
            export SKIP_DOCKER=1
            shift
            ;;
        --force-native)
            export FORCE_NATIVE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-docker    Skip Docker setup options"
            echo "  --force-native   Force native setup only"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            write_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run the wizard
main