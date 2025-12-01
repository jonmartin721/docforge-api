#!/bin/bash

# docforge.sh - CLI for DocForge API
# Usage: ./docforge.sh [options]

set -euo pipefail

# Colors and Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
API_PORT=5257
CLIENT_PORT=5173
API_DIR="./DocumentGenerator.API"
CLIENT_DIR="./DocumentGenerator.Client"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global variables
SKIP_DEPENDENCY_CHECK=${SKIP_DEPENDENCY_CHECK:-0}
AUTO_FIX_DEPENDENCIES=${AUTO_FIX_DEPENDENCIES:-0}
DEPENDENCY_STATUS=0

# Helper Functions
# Check if a port is listening (returns 0 if yes, 1 if no)
is_port_listening() {
    local port=$1

    # Try lsof first (most common)
    if command -v lsof >/dev/null 2>&1; then
        lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 && return 0
    fi
    # Try ss (modern Linux)
    if command -v ss >/dev/null 2>&1; then
        ss -tlnp 2>/dev/null | grep -q ":$port " && return 0
    fi
    # Try netstat (fallback)
    if command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep -q ":$port " && return 0
    fi

    return 1
}

check_port() {
    local port=$1

    if is_port_listening $port; then
        echo -e "${GREEN}UP${NC}"
    else
        echo -e "${RED}DOWN${NC}"
    fi
}

test_quick_dependency() {
    local cmd="$1"
    # Extract the command name (first word) from the full command string
    local cmd_name=$(echo "$cmd" | cut -d' ' -f1)

    if command -v "$cmd_name" >/dev/null 2>&1; then
        if eval "$cmd" >/dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

show_dependency_status() {
    if [[ "$DEPENDENCY_STATUS" -eq 0 ]]; then
        echo -e "🔍 Dependencies: ${GREEN}OK${NC}"
    else
        echo -e "🔍 Dependencies: ${RED}ISSUES${NC}"
    fi
}

proactive_dependency_check() {
    if [[ "$SKIP_DEPENDENCY_CHECK" -eq 1 ]]; then
        return 0
    fi

    echo -e "${CYAN}🔍 Checking dependencies...${NC}"
    local issues=()

    # Quick dependency checks
    if ! test_quick_dependency "dotnet --version"; then
        issues+=(".NET 8 SDK not found")
    fi

    if ! test_quick_dependency "node --version"; then
        issues+=("Node.js not found")
    fi

    if ! test_quick_dependency "npm --version"; then
        issues+=("npm not found")
    fi

    if [[ ${#issues[@]} -gt 0 ]]; then
        echo
        echo -e "${YELLOW}⚠️  Found dependency issues:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "   • ${RED}$issue${NC}"
        done

        if [[ "$AUTO_FIX_DEPENDENCIES" -eq 1 ]]; then
            echo
            echo -e "${CYAN}🔧 Attempting to fix dependencies automatically...${NC}"

            local dependency_checker="$SCRIPT_DIR/scripts/check-dependencies.sh"
            if [[ -f "$dependency_checker" ]]; then
                if "$dependency_checker" --auto-install --quiet; then
                    echo -e "${GREEN}✅ Dependencies fixed!${NC}"
                    DEPENDENCY_STATUS=0
                    return 0
                else
                    echo -e "${YELLOW}⚠️  Some dependencies could not be fixed automatically${NC}"
                fi
            else
                echo -e "${RED}❌ Dependency checker not found${NC}"
            fi
        fi

        echo
        echo -e "${CYAN}🔧 Options:${NC}"
        echo "   1) Run automatic fix (./docforge.sh --autofix)"
        echo "   2) Run full dependency check"
        echo "   3) Continue anyway (may fail)"
        echo

        while true; do
            read -p "Select option (1-3, or skip with --skip-dependency-check): " choice
            case "$choice" in
                1|2|3) break ;;
                *) echo "Please enter 1, 2, or 3" ;;
            esac
        done

        case "$choice" in
            1)
                local dependency_checker="$SCRIPT_DIR/scripts/check-dependencies.sh"
                if [[ -f "$dependency_checker" ]]; then
                    if "$dependency_checker" --auto-install; then
                        echo -e "${GREEN}✅ Dependencies installed successfully!${NC}"
                        DEPENDENCY_STATUS=0
                        return 0
                    else
                        echo -e "${RED}❌ Some dependencies failed to install${NC}"
                        DEPENDENCY_STATUS=1
                        return 1
                    fi
                else
                    echo -e "${RED}❌ Dependency checker not found${NC}"
                    DEPENDENCY_STATUS=1
                    return 1
                fi
                ;;
            2)
                local dependency_checker="$SCRIPT_DIR/scripts/check-dependencies.sh"
                if [[ -f "$dependency_checker" ]]; then
                    "$dependency_checker"
                    local exit_code=$?
                    DEPENDENCY_STATUS=$((exit_code == 0 ? 0 : 1))
                    return $exit_code
                else
                    echo -e "${RED}❌ Dependency checker not found${NC}"
                    DEPENDENCY_STATUS=1
                    return 1
                fi
                ;;
            3)
                echo -e "${YELLOW}⚠️  Continuing with potential issues...${NC}"
                DEPENDENCY_STATUS=1
                return 0
                ;;
        esac
    else
        echo -e "${GREEN}✅ All dependencies appear to be installed${NC}"
        DEPENDENCY_STATUS=0
        return 0
    fi
}

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "   DOCFORGE"
    echo -e "${NC}"
    echo "==============================================="
    show_dependency_status
    echo -e " Backend (API):    $(check_port $API_PORT) (Port $API_PORT)"
    echo -e " Frontend (Client): $(check_port $CLIENT_PORT) (Port $CLIENT_PORT)"
    echo "==============================================="
    echo ""
}

wait_for_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

# Actions
do_setup() {
    echo -e "${CYAN}🔧 Setup Options:${NC}"
    echo ""
    echo -e "1) 🐳 Docker Setup (Easiest)" "${GREEN}"
    echo -e "2) 🔧 Native Setup (Full development)" "${YELLOW}"
    echo -e "3) 🔍 Check Dependencies Only" "${CYAN}"
    echo -e "4) 📦 Install Dependencies Automatically" "${NC}"
    echo ""

    while true; do
        read -p "Select setup option (1-4): " choice
        case "$choice" in
            1|2|3|4) break ;;
            *) echo "Please enter 1, 2, 3, or 4" ;;
        esac
    done

    case "$choice" in
        1)
            local setup_wizard="$SCRIPT_DIR/scripts/setup-wizard.sh"
            if [[ -f "$setup_wizard" ]]; then
                "$setup_wizard" --force-native
            else
                echo -e "${RED}❌ Setup wizard not found${NC}"
                echo -e "${YELLOW}   Falling back to native setup...${NC}"
                do_native_setup
            fi
            ;;
        2)
            do_native_setup
            ;;
        3)
            local dependency_checker="$SCRIPT_DIR/scripts/check-dependencies.sh"
            if [[ -f "$dependency_checker" ]]; then
                "$dependency_checker"
            else
                echo -e "${RED}❌ Dependency checker not found${NC}"
            fi
            ;;
        4)
            local dependency_checker="$SCRIPT_DIR/scripts/check-dependencies.sh"
            if [[ -f "$dependency_checker" ]]; then
                if "$dependency_checker" --auto-install; then
                    echo -e "${GREEN}✅ Dependencies installed successfully!${NC}"
                else
                    echo -e "${RED}❌ Some dependencies failed to install${NC}"
                fi
            else
                echo -e "${RED}❌ Dependency checker not found${NC}"
            fi
            ;;
    esac

    wait_for_enter
}

do_native_setup() {
    echo -e "${YELLOW}🔧 Setting up native development environment...${NC}"

    # Check and install dependencies
    local dependency_checker="$SCRIPT_DIR/scripts/check-dependencies.sh"
    if [[ -f "$dependency_checker" ]]; then
        echo -e "${CYAN}📦 Checking and installing dependencies...${NC}"
        if "$dependency_checker" --auto-install; then
            echo -e "${GREEN}✅ Dependencies installed successfully!${NC}"

            # Restore .NET packages
            echo -e "${CYAN}📦 Restoring .NET packages...${NC}"
            if dotnet restore; then
                echo -e "${GREEN}✅ .NET packages restored${NC}"
            else
                echo -e "${YELLOW}⚠️  .NET package restore had issues${NC}"
            fi

            # Install npm dependencies
            echo -e "${CYAN}📦 Installing frontend dependencies...${NC}"
            if [[ -f "$CLIENT_DIR/package.json" ]]; then
                if (cd "$CLIENT_DIR" && npm install); then
                    echo -e "${GREEN}✅ Frontend dependencies installed${NC}"
                else
                    echo -e "${YELLOW}⚠️  Frontend dependency installation had issues${NC}"
                fi
            else
                echo -e "${YELLOW}⚠️  Frontend package.json not found${NC}"
            fi

            echo
            echo -e "${GREEN}🎉 Native setup completed!${NC}"
            echo -e "${CYAN}You can now start the backend and frontend services.${NC}"
        else
            echo -e "${RED}❌ Dependency installation failed${NC}"
            echo -e "${YELLOW}Please check the error messages above and try again.${NC}"
        fi
    else
        echo -e "${RED}❌ Dependency checker not found${NC}"
        echo -e "${YELLOW}Please run the setup wizard instead: ./scripts/setup-wizard.sh${NC}"
    fi
}

do_start_backend() {
    # Pre-flight checks
    if [[ ! -d "$API_DIR" ]]; then
        echo -e "${RED}❌ API directory not found: $API_DIR${NC}"
        echo -e "${YELLOW}   Make sure you're running this from the project root.${NC}"
        wait_for_enter
        return
    fi

    if ! test_quick_dependency "dotnet --version"; then
        echo -e "${RED}❌ .NET SDK not found. Please run setup first.${NC}"
        echo -e "${YELLOW}   Option 1) Setup Dependencies${NC}"
        wait_for_enter
        return
    fi

    echo -e "${YELLOW}🚀 Starting Backend...${NC}"

    if dotnet run --project "$API_DIR" > api.log 2>&1 & then
        API_PID=$!
        echo -e "${GREEN}✓ Backend process started (PID: $API_PID)${NC}"

        # Wait for API to be ready (with timeout)
        echo -e "${CYAN}⏳ Waiting for API to be ready...${NC}"
        for i in {1..30}; do  # Increased timeout to 30 seconds
            if is_port_listening $API_PORT; then
                echo -e "${GREEN}✅ API is up and running on port $API_PORT!${NC}"
                echo -e "${CYAN}   API URL: http://localhost:$API_PORT${NC}"
                echo -e "${CYAN}   Swagger UI: http://localhost:$API_PORT/swagger${NC}"
                wait_for_enter
                return
            fi

            # Show progress
            if [[ $((i % 5)) -eq 0 ]]; then
                echo -e "${CYAN}   Still waiting... ($i/30 seconds)${NC}"
            fi
            sleep 1
        done

        echo -e "${YELLOW}⚠️  WARNING: API may not have started within expected time.${NC}"
        echo -e "${YELLOW}   Check api.log for errors and consider:${NC}"
        echo -e "   • Running 'dotnet restore' first${NC}"
        echo -e "   • Checking for missing dependencies${NC}"
        echo -e "   • Looking for build errors${NC}"
    else
        echo -e "${RED}❌ Failed to start backend process${NC}"
        echo -e "${YELLOW}   • Make sure .NET 8 SDK is installed${NC}"
        echo -e "${YELLOW}   • Check that the API project exists and can build${NC}"
    fi

    wait_for_enter
}

do_start_frontend() {
    # Pre-flight checks
    if [[ ! -d "$CLIENT_DIR" ]]; then
        echo -e "${RED}❌ Client directory not found: $CLIENT_DIR${NC}"
        echo -e "${YELLOW}   Make sure you're running this from the project root.${NC}"
        wait_for_enter
        return
    fi

    if [[ ! -f "$CLIENT_DIR/package.json" ]]; then
        echo -e "${RED}❌ package.json not found in client directory${NC}"
        echo -e "${YELLOW}   Make sure the frontend project is properly set up.${NC}"
        wait_for_enter
        return
    fi

    if ! test_quick_dependency "node --version"; then
        echo -e "${RED}❌ Node.js not found. Please run setup first.${NC}"
        echo -e "${YELLOW}   Option 1) Setup Dependencies${NC}"
        wait_for_enter
        return
    fi

    if ! test_quick_dependency "npm --version"; then
        echo -e "${RED}❌ npm not found. Please run setup first.${NC}"
        echo -e "${YELLOW}   Option 1) Setup Dependencies${NC}"
        wait_for_enter
        return
    fi

    # Check if node_modules exists
    if [[ ! -d "$CLIENT_DIR/node_modules" ]]; then
        echo -e "${YELLOW}⚠️  node_modules not found. Running npm install first...${NC}"
        if (cd "$CLIENT_DIR" && npm install); then
            echo -e "${GREEN}✅ Dependencies installed${NC}"
        else
            echo -e "${RED}❌ Failed to install dependencies${NC}"
            wait_for_enter
            return
        fi
    fi

    echo -e "${YELLOW}🚀 Starting Frontend...${NC}"

    if (cd "$CLIENT_DIR" && npm run dev > ../client.log 2>&1 &); then
        CLIENT_PID=$!
        echo -e "${GREEN}✓ Frontend process started (PID: $CLIENT_PID)${NC}"

        # Wait for Vite to be ready (with timeout)
        echo -e "${CYAN}⏳ Waiting for Vite to be ready...${NC}"
        for i in {1..30}; do  # Increased timeout to 30 seconds
            if is_port_listening $CLIENT_PORT; then
                echo -e "${GREEN}✅ Frontend is up and running on port $CLIENT_PORT!${NC}"
                echo -e "${CYAN}   Frontend URL: http://localhost:$CLIENT_PORT${NC}"
                wait_for_enter
                return
            fi

            # Show progress
            if [[ $((i % 5)) -eq 0 ]]; then
                echo -e "${CYAN}   Still waiting... ($i/30 seconds)${NC}"
            fi
            sleep 1
        done

        echo -e "${YELLOW}⚠️  WARNING: Frontend may not have started within expected time.${NC}"
        echo -e "${YELLOW}   Check client.log for errors and consider:${NC}"
        echo -e "   • Running 'npm install' first${NC}"
        echo -e "   • Checking for missing Node.js dependencies${NC}"
        echo -e "   • Looking for build errors${NC}"
    else
        echo -e "${RED}❌ Failed to start frontend process${NC}"
        echo -e "${YELLOW}   • Make sure Node.js and npm are installed${NC}"
        echo -e "${YELLOW}   • Check that package.json exists and is valid${NC}"
        echo -e "${YELLOW}   • Try running 'npm install' in the client directory${NC}"
    fi

    wait_for_enter
}

do_stop_all() {
    echo -e "${YELLOW}Stopping all services...${NC}"
    # Kill by port is safer than PID tracking in a simple script
    kill_port $API_PORT
    kill_port $CLIENT_PORT
    echo -e "${GREEN}Stopped.${NC}"
    sleep 1
}

# Helper function to kill processes on a port with fallbacks
kill_port() {
    local port=$1

    # Try fuser first (Linux)
    if command -v fuser >/dev/null 2>&1; then
        fuser -k $port/tcp >/dev/null 2>&1 || true
    # Try lsof + kill (macOS and Linux)
    elif command -v lsof >/dev/null 2>&1; then
        local pids=$(lsof -ti :$port 2>/dev/null)
        if [[ -n "$pids" ]]; then
            echo "$pids" | xargs -r kill -9 2>/dev/null || true
        fi
    # Try ss + kill (modern Linux without lsof)
    elif command -v ss >/dev/null 2>&1; then
        local pids=$(ss -tlnp 2>/dev/null | grep ":$port " | grep -oP 'pid=\K[0-9]+' | sort -u)
        if [[ -n "$pids" ]]; then
            echo "$pids" | xargs -r kill -9 2>/dev/null || true
        fi
    fi
}

do_view_logs() {
    LOG_FILE=$1
    NAME=$2
    
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${RED}Log file $LOG_FILE not found.${NC}"
        wait_for_enter
        return
    fi

    echo -e "${YELLOW}Viewing $NAME logs (Press Ctrl+C to exit)...${NC}"
    sleep 1
    tail -f "$LOG_FILE"
}

do_open_browser() {
    if ! is_port_listening $CLIENT_PORT; then
        echo -e "${RED}Frontend is not running! Please start it first.${NC}"
        wait_for_enter
        return
    fi

    URL="http://localhost:$CLIENT_PORT"
    echo -e "${GREEN}Opening $URL...${NC}"
    
    if grep -q Microsoft /proc/version; then
        # WSL
        explorer.exe "$URL"
    elif command -v xdg-open >/dev/null; then
        # Linux
        xdg-open "$URL"
    elif command -v open >/dev/null; then
        # macOS
        open "$URL"
    else
        echo -e "${RED}Could not detect browser opener. Please open $URL manually.${NC}"
    fi
    wait_for_enter
}

do_test() {
    echo -e "${YELLOW}Running Tests...${NC}"
    dotnet test
    wait_for_enter
}


do_clear_data() {
    echo -e "${RED}${BOLD}⚠ WARNING: This will delete all data (Database & Generated Files)!${NC}"
    read -p "Are you sure? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        wait_for_enter
        return
    fi

    do_stop_all
    
    echo "Deleting database..."
    rm -f "$API_DIR/documentgenerator.db"
    
    echo "Deleting generated documents..."
    # Ensure directory exists before trying to empty it to avoid errors
    if [ -d "$API_DIR/GeneratedDocuments" ]; then
        rm -rf "$API_DIR/GeneratedDocuments"/*
    fi
    
    echo -e "${GREEN}Data cleared!${NC}"
    wait_for_enter
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-dependency-check)
            export SKIP_DEPENDENCY_CHECK=1
            shift
            ;;
        --autofix)
            export AUTO_FIX_DEPENDENCIES=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-dependency-check    Skip dependency checks"
            echo "  --autofix                 Auto-fix dependency issues"
            echo "  -h, --help               Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Run proactive dependency check on startup
proactive_dependency_check

# Main Loop
while true; do
    print_header

    # Show Docker recommendation if dependencies have issues
    if [[ "$DEPENDENCY_STATUS" -ne 0 ]]; then
        echo -e "${YELLOW}[TIP] Having dependency issues? Try Docker setup (option 5) instead!${NC}"
        echo ""
    fi

    echo -e "${BOLD}Services:${NC}"
    echo "  1) 🚀 Start Backend"
    echo "  2) 🌐 Start Frontend"
    echo "  3) ⚡ Start Both Services"
    echo "  4) 🛑 Stop All Services"
    echo ""
    echo -e "${BOLD}Setup & Dependencies:${NC}"
    echo -e "  5) ${GREEN}🐳 Docker Quick Start${NC}"
    echo "  6) 🔧 Native Setup"
    echo "  7) 🔍 Check Dependencies"
    echo ""
    echo -e "${BOLD}Tools:${NC}"
    echo "  8) 📄 View Backend Logs"
    echo "  9) 📑 View Frontend Logs"
    echo "  0) 🌍 Open App in Browser"
    echo "  t) 🧪 Run Tests"
    echo "  r) 🔄 Refresh Status"
    echo "  c) 🗑️  Clear All Data"
    echo "  q) 👋 Quit"
    echo ""
    read -p "Select an option: " option

    case $option in
        1)
            do_start_backend
            ;;
        2)
            do_start_frontend
            ;;
        3)
            do_start_backend
            do_start_frontend
            ;;
        4)
            do_stop_all
            ;;
        5)
            # Launch Docker quick start
            docker_script="$SCRIPT_DIR/scripts/docker-quick-start.sh"
            if [[ -f "$docker_script" ]]; then
                chmod +x "$docker_script"
                "$docker_script"
            else
                echo -e "${RED}[ERROR] Docker quick start script not found at: $docker_script${NC}"
                echo -e "${YELLOW}You can run it manually: ./scripts/docker-quick-start.sh${NC}"
                wait_for_enter
            fi
            ;;
        6)
            do_setup
            # Re-check dependencies after setup
            proactive_dependency_check
            ;;
        7)
            dependency_checker="$SCRIPT_DIR/scripts/check-dependencies.sh"
            if [[ -f "$dependency_checker" ]]; then
                "$dependency_checker"
                exit_code=$?
                DEPENDENCY_STATUS=$((exit_code == 0 ? 0 : 1))
            else
                echo -e "${RED}❌ Dependency checker not found${NC}"
                wait_for_enter
            fi
            ;;
        8)
            do_view_logs "api.log" "Backend"
            ;;
        9)
            do_view_logs "client.log" "Frontend"
            ;;
        0)
            do_open_browser
            ;;
        t|T)
            do_test
            ;;
        r|R)
            # Just loop to refresh
            ;;
        c|C)
            do_clear_data
            ;;
        q|Q)
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please select 0-9, t, r, c, or q.${NC}"
            sleep 1
            ;;
    esac
done
