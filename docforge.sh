#!/bin/bash

# docforge.sh - CLI for DocForge API
# Usage: ./docforge.sh

# Colors and Formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
API_PORT=5257
CLIENT_PORT=5173
API_DIR="./DocumentGenerator.API"
CLIENT_DIR="./DocumentGenerator.Client"

# Helper Functions
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo -e "${GREEN}🟢 UP${NC}"
    else
        echo -e "${RED}🔴 DOWN${NC}"
    fi
}

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "   DOCFORGE"
    echo -e "${NC}"
    echo "==============================================="
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
    echo -e "${YELLOW}Running Setup...${NC}"
    echo ""
    echo -e "${CYAN}Note: The Linux setup script requires sudo to install system dependencies.${NC}"
    echo -e "${CYAN}Please run it separately before using this TUI:${NC}"
    echo -e "${CYAN}  sudo ./scripts/setup-linux.sh${NC}"
    echo ""

    echo "1. Restoring Backend..."
    dotnet restore

    echo "2. Installing Frontend Dependencies..."
    cd "$CLIENT_DIR" && npm install
    cd ..

    echo -e "${GREEN}Setup Complete!${NC}"
    wait_for_enter
}

do_start_backend() {
    echo -e "${YELLOW}Starting Backend...${NC}"
    echo "Starting API in background..."
    dotnet run --project "$API_DIR" > api.log 2>&1 &
    API_PID=$!
    echo "API started with PID $API_PID. Logs: api.log"
    
    # Wait for API to be ready (with timeout)
    echo "Waiting for API to be ready..."
    for i in {1..15}; do
        if lsof -Pi :$API_PORT -sTCP:LISTEN -t > /dev/null 2>&1; then
            echo -e "${GREEN}✓ API is up and running!${NC}"
            wait_for_enter
            return
        fi
        sleep 1
    done
    
    echo -e "${RED}⚠ API may not have started. Check api.log for errors.${NC}"
    wait_for_enter
}

do_start_frontend() {
    echo -e "${YELLOW}Starting Frontend...${NC}"
    echo "Starting Vite in background..."
    cd "$CLIENT_DIR"
    npm run dev > ../client.log 2>&1 &
    CLIENT_PID=$!
    cd ..
    echo "Client started with PID $CLIENT_PID. Logs: client.log"
    
    # Wait for Vite to be ready (with timeout)
    echo "Waiting for Vite to be ready..."
    for i in {1..15}; do
        if lsof -Pi :$CLIENT_PORT -sTCP:LISTEN -t > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Frontend is up and running!${NC}"
            wait_for_enter
            return
        fi
        sleep 1
    done
    
    echo -e "${RED}⚠ Frontend may not have started. Check client.log for errors.${NC}"
    wait_for_enter
}

do_stop_all() {
    echo -e "${YELLOW}Stopping all services...${NC}"
    # Kill by port is safer than PID tracking in a simple script
    fuser -k $API_PORT/tcp >/dev/null 2>&1
    fuser -k $CLIENT_PORT/tcp >/dev/null 2>&1
    echo -e "${GREEN}Stopped.${NC}"
    sleep 1
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
    if ! lsof -Pi :$CLIENT_PORT -sTCP:LISTEN -t >/dev/null ; then
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

# Main Loop
while true; do
    print_header
    echo -e "${BOLD}Core Actions:${NC}"
    echo "  1) 🔧 Setup Dependencies"
    echo "  2) 🚀 Start Backend"
    echo "  3) 🌐 Start Frontend"
    echo "  4) ⚡ Start Both"
    echo "  5) 🛑 Stop All Services"
    echo ""
    echo -e "${BOLD}Tools:${NC}"
    echo "  6) 📄 View Backend Logs"
    echo "  7) 📑 View Frontend Logs"
    echo "  8) 🌍 Open App in Browser"
    echo "  9) 🧪 Run Tests"
    echo ""
    echo "  q) Quit"
    echo ""
    read -p "Select an option: " option

    case $option in
        1) do_setup ;;
        2) do_start_backend ;;
        3) do_start_frontend ;;
        4) do_start_backend; do_start_frontend ;;
        5) do_stop_all ;;
        6) do_view_logs "api.log" "Backend" ;;
        7) do_view_logs "client.log" "Frontend" ;;
        8) do_open_browser ;;
        9) do_test ;;
        q) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
done
