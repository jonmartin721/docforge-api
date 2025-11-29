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

do_api_playground() {
    # Check if API is running
    if ! is_port_listening $API_PORT; then
        echo -e "${YELLOW}⚠️  API is not running! Start it first for full functionality.${NC}"
        echo ""
    fi

    echo -e "${CYAN}🔌 API Playground${NC}"
    echo -e "${CYAN}===================${NC}"
    echo ""
    echo -e "${WHITE}API Base URL: http://localhost:$API_PORT${NC}"
    echo ""
    echo -e "${WHITE}Quick Actions:${NC}"
    echo -e "  1) ${GREEN}❤️  Health Check${NC}"
    echo -e "  2) ${CYAN}📖 Open Swagger UI (API Docs)${NC}"
    echo -e "  3) ${YELLOW}📋 List Templates${NC}"
    echo -e "  4) ${YELLOW}📄 List Documents${NC}"
    echo -e "  5) ${WHITE}🔧 Test Custom Endpoint${NC}"
    echo -e "  6) ${GRAY}ℹ️  Show API Endpoints${NC}"
    echo ""
    echo -e "  b) ${GRAY}Back to Main Menu${NC}"
    echo ""

    read -p "Select option: " choice

    case "$choice" in
        1) do_api_health_check ;;
        2) do_api_open_swagger ;;
        3) do_api_request "GET" "/api/templates" "List Templates" ;;
        4) do_api_request "GET" "/api/documents" "List Documents" ;;
        5) do_api_custom_endpoint ;;
        6) do_api_show_endpoints ;;
        b|B) return ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            sleep 1
            ;;
    esac

    # Loop back to playground menu unless going back
    if [[ "$choice" != "b" && "$choice" != "B" ]]; then
        do_api_playground
    fi
}

do_api_health_check() {
    echo ""
    echo -e "${CYAN}❤️  Checking API Health...${NC}"
    echo ""

    local base_url="http://localhost:$API_PORT"
    local endpoints=(
        "/health|Health Endpoint"
        "/api/templates|Templates API"
        "/swagger|Swagger UI"
    )

    for entry in "${endpoints[@]}"; do
        local path="${entry%%|*}"
        local name="${entry##*|}"
        local url="$base_url$path"

        echo -n "  Testing $name... "

        if command -v curl >/dev/null 2>&1; then
            local http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null)

            if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
                echo -e "${GREEN}OK ($http_code)${NC}"
            elif [[ "$http_code" == "000" ]]; then
                echo -e "${RED}UNREACHABLE${NC}"
            else
                echo -e "${YELLOW}WARN ($http_code)${NC}"
            fi
        else
            echo -e "${YELLOW}SKIP (curl not found)${NC}"
        fi
    done

    echo ""
    wait_for_enter
}

do_api_open_swagger() {
    local url="http://localhost:$API_PORT/swagger"
    echo ""
    echo -e "${CYAN}📖 Opening Swagger UI...${NC}"
    echo -e "   URL: $url"

    # Try to open browser
    if grep -q Microsoft /proc/version 2>/dev/null; then
        # WSL
        explorer.exe "$url" 2>/dev/null && echo -e "${GREEN}✅ Browser opened${NC}" || echo -e "${YELLOW}⚠️  Could not open browser${NC}"
    elif command -v xdg-open >/dev/null 2>&1; then
        # Linux
        xdg-open "$url" 2>/dev/null && echo -e "${GREEN}✅ Browser opened${NC}" || echo -e "${YELLOW}⚠️  Could not open browser${NC}"
    elif command -v open >/dev/null 2>&1; then
        # macOS
        open "$url" 2>/dev/null && echo -e "${GREEN}✅ Browser opened${NC}" || echo -e "${YELLOW}⚠️  Could not open browser${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not open browser automatically${NC}"
        echo -e "   Please open $url manually"
    fi

    wait_for_enter
}

do_api_request() {
    local method="$1"
    local endpoint="$2"
    local description="$3"

    local url="http://localhost:$API_PORT$endpoint"
    echo ""
    echo -e "${CYAN}[$method] $description${NC}"
    echo -e "${GRAY}   URL: $url${NC}"
    echo ""

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}❌ curl is not installed${NC}"
        echo -e "${YELLOW}   Please install curl to use this feature${NC}"
        wait_for_enter
        return
    fi

    local response
    local http_code

    response=$(curl -s -w "\n%{http_code}" --connect-timeout 10 -X "$method" "$url" -H "Content-Type: application/json" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "000" ]]; then
        echo -e "${RED}❌ Could not connect to API${NC}"
        echo -e "${YELLOW}   Make sure the API is running (option 2)${NC}"
    elif [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        echo -e "${GREEN}[RESPONSE] Status: $http_code${NC}"
        echo ""

        # Try to format JSON with jq if available
        if command -v jq >/dev/null 2>&1; then
            echo "$body" | jq '.' 2>/dev/null || echo "$body"
        else
            # Truncate if too long
            if [[ ${#body} -gt 2000 ]]; then
                echo "${body:0:2000}"
                echo "... (truncated)"
            else
                echo "$body"
            fi
        fi
    else
        echo -e "${RED}[ERROR] Status: $http_code${NC}"
        echo ""
        echo "$body"
    fi

    echo ""
    wait_for_enter
}

do_api_custom_endpoint() {
    echo ""
    echo -e "${CYAN}🔧 Custom Endpoint Test${NC}"
    echo ""
    echo -e "${GRAY}Base URL: http://localhost:$API_PORT${NC}"
    echo ""

    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}❌ curl is not installed${NC}"
        echo -e "${YELLOW}   Please install curl to use this feature${NC}"
        wait_for_enter
        return
    fi

    # Method selection
    echo -e "${WHITE}HTTP Method:${NC}"
    echo "  1) GET"
    echo "  2) POST"
    echo "  3) PUT"
    echo "  4) DELETE"
    echo ""

    while true; do
        read -p "Select method (1-4): " method_choice
        case "$method_choice" in
            1|2|3|4) break ;;
            *) echo "Please enter 1, 2, 3, or 4" ;;
        esac
    done

    local method
    case "$method_choice" in
        1) method="GET" ;;
        2) method="POST" ;;
        3) method="PUT" ;;
        4) method="DELETE" ;;
    esac

    echo ""
    read -p "Enter endpoint path (e.g., /api/templates): " endpoint

    # Ensure endpoint starts with /
    if [[ ! "$endpoint" =~ ^/ ]]; then
        endpoint="/$endpoint"
    fi

    local body=""
    if [[ "$method" == "POST" || "$method" == "PUT" ]]; then
        echo ""
        echo -e "${GRAY}Enter JSON body (or press Enter to skip):${NC}"
        read body_input
        if [[ -n "$body_input" ]]; then
            body="$body_input"
        fi
    fi

    local url="http://localhost:$API_PORT$endpoint"
    echo ""
    echo -e "${CYAN}[$method] $url${NC}"
    echo ""

    local response
    local http_code
    local curl_opts=(-s -w "\n%{http_code}" --connect-timeout 10 -X "$method" "$url" -H "Content-Type: application/json")

    if [[ -n "$body" ]]; then
        curl_opts+=(-d "$body")
    fi

    response=$(curl "${curl_opts[@]}" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "000" ]]; then
        echo -e "${RED}❌ Could not connect to API${NC}"
        echo -e "${YELLOW}   Make sure the API is running${NC}"
    elif [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        echo -e "${GREEN}[RESPONSE] Status: $http_code${NC}"
        echo ""

        if command -v jq >/dev/null 2>&1; then
            echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
        else
            if [[ ${#response_body} -gt 2000 ]]; then
                echo "${response_body:0:2000}"
                echo "... (truncated)"
            else
                echo "$response_body"
            fi
        fi
    else
        echo -e "${RED}[ERROR] Status: $http_code${NC}"
        echo ""
        echo "$response_body"
    fi

    echo ""
    wait_for_enter
}

do_api_show_endpoints() {
    echo ""
    echo -e "${CYAN}ℹ️  Available API Endpoints${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo ""
    echo -e "${WHITE}Base URL: http://localhost:$API_PORT${NC}"
    echo ""
    echo -e "${YELLOW}Health & Status:${NC}"
    echo "  GET  /health              - Health check endpoint"
    echo "  GET  /swagger             - Swagger UI (API documentation)"
    echo ""
    echo -e "${YELLOW}Templates:${NC}"
    echo "  GET    /api/templates     - List all templates"
    echo "  GET    /api/templates/{id} - Get template by ID"
    echo "  POST   /api/templates     - Create new template"
    echo "  PUT    /api/templates/{id} - Update template"
    echo "  DELETE /api/templates/{id} - Delete template"
    echo ""
    echo -e "${YELLOW}Documents:${NC}"
    echo "  GET    /api/documents     - List all documents"
    echo "  GET    /api/documents/{id} - Get document by ID"
    echo "  POST   /api/documents     - Generate new document"
    echo "  DELETE /api/documents/{id} - Delete document"
    echo ""
    echo -e "${CYAN}[TIP] Use Swagger UI (option 2) for interactive API testing${NC}"
    echo -e "${CYAN}      with full request/response documentation.${NC}"
    echo ""
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
        echo -e "${YELLOW}[TIP] Having dependency issues? Try Docker setup (option 0) instead!${NC}"
        echo ""
    fi

    echo -e "${BOLD}Core Actions:${NC}"
    echo -e "  0) ${GREEN}🐳 Docker Quick Start${NC}"
    echo "  1) 🔧 Setup Dependencies (Native)"
    echo "  2) 🚀 Start Backend"
    echo "  3) 🌐 Start Frontend"
    echo "  4) ⚡ Start Both Services"
    echo "  5) 🛑 Stop All Services"
    echo ""
    echo -e "${BOLD}Tools:${NC}"
    echo "  6) 📄 View Backend Logs"
    echo "  7) 📑 View Frontend Logs"
    echo "  8) 🌍 Open App in Browser"
    echo "  9) 🧪 Run Tests"
    echo ""
    echo -e "  a) ${CYAN}🔌 API Playground (Test Endpoints)${NC}"
    echo "  r) 🔄 Refresh Status"
    echo "  c) 🗑️  Clear All Data"
    echo "  d) 🔍 Dependencies Status"
    echo "  q) 👋 Quit"
    echo ""
    read -p "Select an option: " option

    case $option in
        0)
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
        1)
            do_setup
            # Re-check dependencies after setup
            proactive_dependency_check
            ;;
        2)
            do_start_backend
            ;;
        3)
            do_start_frontend
            ;;
        4)
            do_start_backend
            do_start_frontend
            ;;
        5)
            do_stop_all
            ;;
        6)
            do_view_logs "api.log" "Backend"
            ;;
        7)
            do_view_logs "client.log" "Frontend"
            ;;
        8)
            do_open_browser
            ;;
        9)
            do_test
            ;;
        a|A)
            do_api_playground
            ;;
        r)
            # Just loop to refresh
            ;;
        c)
            do_clear_data
            ;;
        d)
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
        q)
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please select 0-9, a, r, c, d, or q.${NC}"
            sleep 1
            ;;
    esac
done
