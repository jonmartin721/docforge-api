#!/bin/bash
# DocForge Dependency Checker for Linux/macOS
# This script checks for and optionally installs required dependencies

# Enable strict error handling (but not as strict to avoid hanging)
set -uo pipefail

# Color output functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if we're on macOS
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# Function to check if we're on Linux
is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Output functions
write_success() {
    [[ "${QUIET:-0}" != "1" ]] && echo -e "${GREEN}✓ $1${NC}"
}

write_warning() {
    [[ "${QUIET:-0}" != "1" ]] && echo -e "${YELLOW}⚠ $1${NC}"
}

write_error() {
    [[ "${QUIET:-0}" != "1" ]] && echo -e "${RED}✗ $1${NC}"
}

write_info() {
    [[ "${QUIET:-0}" != "1" ]] && echo -e "${CYAN}$1${NC}"
}

write_progress() {
    if [[ "${QUIET:-0}" != "1" ]]; then
        local percent=${2:-0}
        echo -ne "${BLUE}$1... (${percent}%)${NC}\r"
    fi
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPENDENCIES_FILE="$SCRIPT_DIR/dependencies.json"
PLATFORM_FILE="$SCRIPT_DIR/platform-config.json"

# Parse JSON using basic tools (fallback if jq is not available)
parse_json() {
    local file="$1"
    local path="$2"

    if command -v jq >/dev/null 2>&1; then
        jq -r "$path" "$file" 2>/dev/null
    else
        # Basic JSON parsing fallback using sed and awk
        # This is simplified and may not work for complex JSON
        grep -o "\"$path\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" | sed 's/.*: *"\([^"]*\)".*/\1/' | head -1
    fi
}

# Detect platform and package manager
detect_platform() {
    if is_macos; then
        echo "macos"
    elif is_linux; then
        # Try to detect distribution
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            case "$ID" in
                ubuntu|debian|linuxmint) echo "linux" ;;
                fedora) echo "linux" ;;
                centos|rhel) echo "linux" ;;
                arch) echo "linux" ;;
                *) echo "linux" ;;
            esac
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

detect_package_manager() {
    if command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v snap >/dev/null 2>&1; then
        echo "snap"
    else
        echo "none"
    fi
}

# Version extraction and validation
extract_version_from_output() {
    local output="$1"

    if [[ -z "$output" ]]; then
        echo ""
        return
    fi

    # Common version patterns
    local patterns=(
        '[0-9]+\.[0-9]+\.[0-9]+'
        '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
        'v([0-9]+\.[0-9]+\.[0-9]+)'
        'version ([0-9]+\.[0-9]+\.[0-9]+)'
    )

    for pattern in "${patterns[@]}"; do
        if [[ "$output" =~ $pattern ]]; then
            local version="${BASH_REMATCH[1]:-${BASH_REMATCH[0]}}"
            echo "$version"
            return
        fi
    done

    # Return first line if no pattern matches
    echo "$output" | head -n1 | tr -d '\r\n'
}

validate_version_requirement() {
    local installed="$1"
    local required_pattern="$2"
    local min_version="$3"

    if [[ -z "$installed" ]]; then
        return 1
    fi

    # Try regex pattern match first
    if [[ -n "$required_pattern" ]]; then
        if [[ "$installed" =~ $required_pattern ]]; then
            return 0
        fi
    fi

    # Try version comparison (basic)
    if [[ -n "$min_version" ]]; then
        # Try sort -V (GNU coreutils) - not available on older macOS
        if printf '%s\n%s\n' "$min_version" "$installed" | sort -V -C 2>/dev/null; then
            return 0
        fi

        # Fallback: simple numeric comparison for major.minor.patch
        # This handles most common version formats
        local min_major min_minor min_patch inst_major inst_minor inst_patch
        IFS='.' read -r min_major min_minor min_patch <<< "${min_version%%[^0-9.]*}"
        IFS='.' read -r inst_major inst_minor inst_patch <<< "${installed%%[^0-9.]*}"

        # Default to 0 if not present
        min_major=${min_major:-0}
        min_minor=${min_minor:-0}
        min_patch=${min_patch:-0}
        inst_major=${inst_major:-0}
        inst_minor=${inst_minor:-0}
        inst_patch=${inst_patch:-0}

        # Compare major.minor.patch
        if (( inst_major > min_major )); then
            return 0
        elif (( inst_major == min_major )); then
            if (( inst_minor > min_minor )); then
                return 0
            elif (( inst_minor == min_minor )); then
                if (( inst_patch >= min_patch )); then
                    return 0
                fi
            fi
        fi
    fi

    # Default to true if we can't validate
    return 0
}

# Dependency checking functions
check_dependency() {
    local dep_id="$1"
    local dep_name="$2"
    local platform="$3"
    local package_manager="$4"

    write_progress "Checking $dep_name" 0 >&2

    # Get platform-specific configuration
    local check_cmd=""
    local version_pattern=""
    local install_cmd=""
    local manual_url=""

    if [[ ! -f "$DEPENDENCIES_FILE" ]]; then
        echo "UNKNOWN||Dependencies file not found: $DEPENDENCIES_FILE"
        return
    fi

    if command -v jq >/dev/null 2>&1; then
        check_cmd=$(jq -r ".dependencies.\"$dep_id\".\"$platform\".checkCommand // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
        version_pattern=$(jq -r ".dependencies.\"$dep_id\".\"$platform\".versionPattern // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
        install_cmd=$(jq -r ".dependencies.\"$dep_id\".\"$platform\".installCommand // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
        manual_url=$(jq -r ".dependencies.\"$dep_id\".\"$platform\".manualInstallUrl // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
    fi

    if [[ -z "$check_cmd" ]]; then
        echo "UNKNOWN||No check command specified for $dep_id on $platform"
        return
    fi

    # Execute check command
    local result
    local status="UNKNOWN"
    local version=""
    local message=""

    if result=$(eval "$check_cmd" 2>/dev/null); then
        version=$(extract_version_from_output "$result")

        # Get version requirements from JSON
        local required_version=""
        local min_version=""
        if command -v jq >/dev/null 2>&1; then
            required_version=$(jq -r ".dependencies.\"$dep_id\".version // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
            min_version=$(jq -r ".dependencies.\"$dep_id\".minVersion // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
        fi

        if validate_version_requirement "$version" "$version_pattern" "$min_version"; then
            status="OK"
            message="Installed and valid"
            write_success "$dep_name ($version)" >&2
        else
            status="WRONG_VERSION"
            message="Version incompatible"
            write_warning "$dep_name ($version) - version incompatible" >&2
        fi
    else
        status="MISSING"
        message="Not installed"
        write_error "$dep_name - not found" >&2
    fi

    # Output the result in the expected format
    echo "$status|$version|$message"
}

install_dependency() {
    local dep_id="$1"
    local dep_name="$2"
    local platform="$3"
    local package_manager="$4"
    local current_status="$5"
    local current_version="$6"

    if [[ "$current_status" == "OK" && "${FORCE:-0}" != "1" ]]; then
        write_info "$dep_name is already installed and valid"
        return 0
    fi

    # Get platform-specific installation command
    local install_cmd=""
    local manual_url=""
    local notes=""

    if command -v jq >/dev/null 2>&1; then
        install_cmd=$(jq -r ".dependencies.\"$dep_id\".\"$platform\".installCommand // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
        manual_url=$(jq -r ".dependencies.\"$dep_id\".\"$platform\".manualInstallUrl // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
        notes=$(jq -r ".dependencies.\"$dep_id\".\"$platform\".notes // empty" "$DEPENDENCIES_FILE" 2>/dev/null || echo "")
    fi

    # Try alternative installation methods based on platform
    if [[ -z "$install_cmd" ]]; then
        case "$dep_id" in
            "dotnet-8")
                if is_linux; then
                    case "$package_manager" in
                        "apt") install_cmd="sudo apt-get update && sudo apt-get install -y dotnet-sdk-8.0" ;;
                        "snap") install_cmd="sudo snap install dotnet-sdk --classic" ;;
                        "dnf") install_cmd="sudo dnf install dotnet-sdk-8.0" ;;
                        "yum") install_cmd="sudo yum install dotnet-sdk-8.0" ;;
                    esac
                elif is_macos; then
                    if [[ "$package_manager" == "brew" ]]; then
                        install_cmd="brew install dotnet"
                    fi
                fi
                ;;
            "nodejs")
                if is_linux; then
                    case "$package_manager" in
                        "apt") install_cmd="curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs" ;;
                        "snap") install_cmd="sudo snap install node --classic" ;;
                        "dnf") install_cmd="sudo dnf install nodejs npm" ;;
                        "yum") install_cmd="sudo yum install nodejs npm" ;;
                    esac
                elif is_macos; then
                    if [[ "$package_manager" == "brew" ]]; then
                        install_cmd="brew install node@18"
                    fi
                fi
                ;;
        esac
    fi

    if [[ -z "$install_cmd" ]]; then
        write_error "No automatic installation available for $dep_name"
        show_manual_installation_instructions "$dep_name" "$manual_url" "$notes"
        return 1
    fi

    write_info "Installing $dep_name..."
    write_progress "Installing $dep_name" 50

    # Check for sudo access if needed
    if [[ "$install_cmd" == sudo* ]] && [[ "$EUID" -ne 0 ]]; then
        if ! sudo -n true 2>/dev/null; then
            write_warning "This installation requires sudo privileges"
            write_info "You may be prompted for your password"
        fi
    fi

    if eval "$install_cmd"; then
        write_success "$dep_name installed successfully"

        # Verify installation
        sleep 2
        local check_result=$(check_dependency "$dep_id" "$dep_name" "$platform" "$package_manager")
        local status=$(echo "$check_result" | cut -d'|' -f1)
        local version=$(echo "$check_result" | cut -d'|' -f2)

        if [[ "$status" == "OK" ]]; then
            write_success "$dep_name verified: $version"
            return 0
        else
            write_warning "$dep_name installed but verification failed"
            return 1
        fi
    else
        local install_error=$?
        write_error "Installation failed for $dep_name (exit code: $install_error)"
        show_manual_installation_instructions "$dep_name" "$manual_url" "$notes"
        return 1
    fi
}

show_manual_installation_instructions() {
    local dep_name="$1"
    local manual_url="$2"
    local notes="$3"

    echo
    write_info "Manual installation required for $dep_name:"
    write_info "----------------------------------------------------"

    if [[ -n "$manual_url" ]]; then
        write_info "Download URL: $manual_url"
    fi

    if [[ -n "$notes" ]]; then
        write_info "Notes: $notes"
    fi

    echo
}

show_dependency_summary() {
    local -a results=("$@")

    echo
    write_info "Dependency Summary:"
    write_info "==================="

    local total=0
    local ok=0
    local issues=0

    
    for result in "${results[@]}"; do
        IFS='|' read -r dep_id status version message <<< "$result"
        ((total++))

        
        case "$status" in
            "OK")
                write_success "$dep_id: $version"
                ((ok++))
                ;;
            "MISSING")
                write_error "$dep_id: Not installed"
                ((issues++))
                ;;
            "WRONG_VERSION")
                write_warning "$dep_id: Wrong version ($version)"
                ((issues++))
                ;;
            *)
                write_warning "$dep_id: $message"
                ((issues++))
                ;;
        esac
    done

    echo
    write_info "Total: $total, OK: $ok, Issues: $issues"

    if [[ $issues -eq 0 ]]; then
        write_success "All dependencies are satisfied!"
    else
        write_warning "Found $issues dependency issue(s)"
    fi
}

# Install package managers if needed
install_brew() {
    write_info "Installing Homebrew..."
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        write_success "Homebrew installed successfully"
        # Add to PATH for current session
        if [[ -d "/opt/homebrew" ]]; then
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -d "$HOME/.brew" ]]; then
            export PATH="$HOME/.brew/bin:$PATH"
        fi
        return 0
    else
        write_error "Failed to install Homebrew"
        return 1
    fi
}

# Main execution
main() {
    write_info "DocForge Dependency Checker for $(is_macos && echo "macOS" || echo "Linux")"
    write_info "======================================"

    # Check for required tools
    if ! command -v jq >/dev/null 2>&1; then
        write_warning "jq is not installed. JSON parsing will be limited."
        write_info "Install jq for better parsing: apt-get install jq, brew install jq"
    fi

    # Detect platform and package manager
    local platform=$(detect_platform)
    local package_manager=$(detect_package_manager)

    write_info "Platform: $platform"
    write_info "Package Manager: $package_manager"

    # Install package manager if needed and auto-install is requested
    if [[ "${AUTO_INSTALL:-0}" == "1" ]]; then
        if is_macos && [[ "$package_manager" == "none" ]]; then
            install_brew
            package_manager=$(detect_package_manager)
        fi
    fi

    local -a results=()
    local install_issues=0

    # Determine dependencies to check
    local deps_to_check=()
    if [[ -n "${DEPENDENCY_ID:-}" ]]; then
        deps_to_check=("$DEPENDENCY_ID")
    else
        # Get default dependencies for platform
        if command -v jq >/dev/null 2>&1; then
            local jq_output
            jq_output=$(jq -r ".platforms.\"$platform\".dependencies[]?" "$PLATFORM_FILE" 2>/dev/null) || {
                write_warning "Failed to parse dependencies from config file"
                jq_output="git dotnet-8 nodejs chrome"
            }
            while IFS= read -r dep; do
                [[ -n "$dep" ]] && deps_to_check+=("$dep")
            done <<< "$jq_output"
        else
            # Fallback dependencies
            deps_to_check=("git" "dotnet-8" "nodejs" "chrome")
        fi
    fi

    local dep_count=${#deps_to_check[@]}
    local current=0

    # Check each dependency
    for dep_id in "${deps_to_check[@]}"; do
        ((current++))
        local progress=$(( current * 100 / dep_count ))

        # Get dependency name from JSON or use dep_id as fallback
        local dep_name="$dep_id"
        if command -v jq >/dev/null 2>&1; then
            dep_name=$(jq -r ".dependencies.\"$dep_id\".name // \"$dep_id\"" "$DEPENDENCIES_FILE" 2>/dev/null || echo "$dep_id")
        fi

        write_progress "Checking $dep_name" $progress >&2

        # Check dependency
        local check_result=$(check_dependency "$dep_id" "$dep_name" "$platform" "$package_manager")
        local status=$(echo "$check_result" | cut -d'|' -f1)
        local version=$(echo "$check_result" | cut -d'|' -f2)
        local message=$(echo "$check_result" | cut -d'|' -f3)

        results+=("$dep_id|$status|$version|$message")

        # Auto-install if requested and needed
        if [[ "${AUTO_INSTALL:-0}" == "1" ]] && [[ "$status" != "OK" || "${FORCE:-0}" == "1" ]]; then
            if ! install_dependency "$dep_id" "$dep_name" "$platform" "$package_manager" "$status" "$version"; then
                ((install_issues++))
            fi
        fi
    done

    write_progress "Complete" 100 >&2
    echo

    # Show summary
    if [[ "${QUIET:-0}" != "1" ]]; then
        show_dependency_summary "${results[@]}"
    fi

    # Return appropriate exit code
    if [[ $install_issues -gt 0 ]]; then
        write_error "Some dependencies could not be installed"
        exit 1
    fi

    # Check if there are any remaining issues
    local has_issues=0
    for result in "${results[@]}"; do
        local status=$(echo "$result" | cut -d'|' -f2)
        if [[ "$status" != "OK" ]]; then
            ((has_issues++))
        fi
    done

    if [[ $has_issues -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Parse command line arguments
QUIET=0
AUTO_INSTALL=0
FORCE=0
DEPENDENCY_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet)
            QUIET=1
            shift
            ;;
        --auto-install)
            AUTO_INSTALL=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --dependency)
            DEPENDENCY_ID="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --quiet             Suppress output"
            echo "  --auto-install      Automatically install missing dependencies"
            echo "  --force             Reinstall even if already installed"
            echo "  --dependency ID     Check only specific dependency"
            echo "  -h, --help          Show this help"
            exit 0
            ;;
        *)
            write_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main