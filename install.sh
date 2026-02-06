#!/usr/bin/env bash
#
# SoulOfNix Installer
# Interactive installer for Nix-based ZSH environment
#
# Usage:
#   ./install.sh                    # Interactive mode
#   NIX_ZSH_PROFILE=remote ./install.sh  # Headless mode with env vars
#
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Banner
print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
  ____              _    ___   __ _   _ _
 / ___|  ___  _   _| |  / _ \ / _| \ | (_)_  __
 \___ \ / _ \| | | | | | | | | |_|  \| | \ \/ /
  ___) | (_) | |_| | | | |_| |  _| |\  | |>  <
 |____/ \___/ \__,_|_|  \___/|_| |_| \_|_/_/\_\

 Nix-based ZSH Environment Manager
EOF
    echo -e "${NC}"
}

# Detect operating system
detect_os() {
    local os=""
    local platform=""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        os="macos"
        platform="darwin"
    elif [[ -f /etc/alpine-release ]]; then
        os="alpine"
        platform="alpine"
    elif [[ -f /etc/unraid-version ]] || [[ -f /etc/slackware-version ]]; then
        os="slackware"
        platform="slackware"
    elif [[ -f /etc/arch-release ]]; then
        os="arch"
        platform="linux-systemd"
    elif [[ -f /etc/debian_version ]]; then
        os="debian"
        platform="linux-systemd"
    elif [[ -f /etc/redhat-release ]]; then
        os="redhat"
        platform="linux-systemd"
    elif [[ -f /etc/os-release ]]; then
        os=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
        platform="linux-systemd"
    else
        os="unknown"
        platform="linux-systemd"
    fi

    echo "$os:$platform"
}

# Detect architecture
detect_arch() {
    local arch
    arch=$(uname -m)

    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
}

# Check if Nix is installed
is_nix_installed() {
    command -v nix &>/dev/null
}

# Install Nix using Determinate installer
install_nix() {
    log_info "Installing Nix using Determinate Systems installer..."

    local install_args="--no-confirm"

    # For Slackware/UnRAID, use single-user mode
    if [[ "${PLATFORM:-}" == "slackware" ]]; then
        log_warn "Slackware/UnRAID detected - using single-user Nix mode"
        install_args="$install_args --init none"
    fi

    # Alpine needs --init none as well
    if [[ "${PLATFORM:-}" == "alpine" ]]; then
        log_warn "Alpine detected - using --init none"
        install_args="$install_args --init none"
    fi

    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install $install_args

    # Source Nix profile
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck source=/dev/null
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
        # shellcheck source=/dev/null
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi

    log_success "Nix installed successfully"
}

# Check if home-manager is available
is_home_manager_available() {
    nix run home-manager -- --version &>/dev/null 2>&1
}

# Fetch GitHub public keys
fetch_github_keys() {
    local github_user="$1"
    local keys_url="https://github.com/${github_user}.keys"

    log_info "Fetching SSH public keys from GitHub for user: $github_user"

    local keys
    if keys=$(curl -fsSL "$keys_url" 2>/dev/null); then
        if [[ -n "$keys" ]]; then
            echo "$keys"
            return 0
        fi
    fi

    log_warn "No public keys found for GitHub user: $github_user"
    return 1
}

# Interactive wizard
run_wizard() {
    local os_info platform arch

    print_banner

    # Detect system
    os_info=$(detect_os)
    OS=$(echo "$os_info" | cut -d: -f1)
    PLATFORM=$(echo "$os_info" | cut -d: -f2)
    ARCH=$(detect_arch)

    log_info "Detected OS: $OS ($PLATFORM)"
    log_info "Detected architecture: $ARCH"
    echo

    # Profile selection
    echo -e "${BOLD}Select a profile:${NC}"
    echo "  1) remote  - Minimal for servers (recommended for remote machines)"
    echo "  2) local   - Personal machines with enhanced tools"
    echo "  3) work    - Work environment with Docker/AWS tools"
    echo

    while true; do
        read -rp "Enter choice [1-3]: " choice
        case $choice in
            1) PROFILE="remote"; break ;;
            2) PROFILE="local"; break ;;
            3) PROFILE="work"; break ;;
            *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
        esac
    done

    log_info "Selected profile: $PROFILE"
    echo

    # Username
    local default_user
    default_user=$(whoami)
    read -rp "Username [$default_user]: " USERNAME
    USERNAME="${USERNAME:-$default_user}"
    log_info "Username: $USERNAME"
    echo

    # GitHub user for remote profile (to fetch SSH keys)
    if [[ "$PROFILE" == "remote" ]]; then
        echo -e "${BOLD}GitHub username (to fetch SSH authorized_keys):${NC}"
        read -rp "GitHub username (leave empty to skip): " GITHUB_USER
        if [[ -n "$GITHUB_USER" ]]; then
            log_info "Will fetch SSH keys from: https://github.com/${GITHUB_USER}.keys"
        fi
        echo
    fi

    # Confirmation
    echo -e "${BOLD}Configuration Summary:${NC}"
    echo "  OS:       $OS"
    echo "  Platform: $PLATFORM"
    echo "  Arch:     $ARCH"
    echo "  Profile:  $PROFILE"
    echo "  Username: $USERNAME"
    [[ -n "${GITHUB_USER:-}" ]] && echo "  GitHub:   $GITHUB_USER"
    echo

    read -rp "Proceed with installation? [Y/n]: " confirm
    if [[ "${confirm,,}" == "n" ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
}

# Build flake configuration name
get_flake_config() {
    local profile="$1"
    local platform="$2"
    local arch="$3"

    # Map to flake configuration names
    case "$platform" in
        darwin)
            if [[ "$arch" == "aarch64" ]]; then
                echo "${profile}-darwin"
            else
                echo "${profile}-darwin-x86"
            fi
            ;;
        *)
            if [[ "$arch" == "aarch64" ]]; then
                echo "${profile}-aarch64"
            else
                echo "${profile}"
            fi
            ;;
    esac
}

# Run home-manager switch
apply_configuration() {
    local flake_config="$1"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    log_info "Applying home-manager configuration: $flake_config"

    # Run home-manager switch
    nix run home-manager -- switch \
        --flake "${script_dir}#${flake_config}" \
        --impure

    log_success "Configuration applied successfully!"

    # Add authorized keys if provided (for remote profile)
    if [[ -n "${AUTHORIZED_KEYS:-}" ]]; then
        log_info "Adding SSH authorized keys..."
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh

        # Append keys, avoiding duplicates
        while IFS= read -r key; do
            if [[ -n "$key" ]] && ! grep -qF "$key" ~/.ssh/authorized_keys 2>/dev/null; then
                echo "$key" >> ~/.ssh/authorized_keys
            fi
        done <<< "$AUTHORIZED_KEYS"

        chmod 600 ~/.ssh/authorized_keys
        log_success "SSH authorized keys added"
    fi
}

# Change default shell to ZSH
set_default_shell() {
    local zsh_path
    zsh_path=$(command -v zsh || echo "/usr/bin/zsh")

    # Check if zsh is in /etc/shells
    if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
        log_info "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    # Change shell
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)

    if [[ "$current_shell" != "$zsh_path" ]]; then
        log_info "Changing default shell to ZSH..."
        if command -v chsh &>/dev/null; then
            chsh -s "$zsh_path" || {
                log_warn "Could not change shell automatically. Run: chsh -s $zsh_path"
            }
        else
            log_warn "chsh not found. Please change your shell manually to: $zsh_path"
        fi
    else
        log_info "Default shell is already ZSH"
    fi
}

# Main installation
main() {
    # Check if running interactively or headless
    if [[ -n "${NIX_ZSH_PROFILE:-}" ]]; then
        # Headless mode
        log_info "Running in headless mode"

        PROFILE="${NIX_ZSH_PROFILE}"
        USERNAME="${NIX_ZSH_USER:-$(whoami)}"
        GITHUB_USER="${GITHUB_USER:-}"

        os_info=$(detect_os)
        OS=$(echo "$os_info" | cut -d: -f1)
        PLATFORM=$(echo "$os_info" | cut -d: -f2)
        ARCH=$(detect_arch)
    else
        # Interactive mode
        run_wizard
    fi

    # Install Nix if needed
    if ! is_nix_installed; then
        install_nix
    else
        log_success "Nix is already installed"
    fi

    # Fetch GitHub SSH keys for remote profile
    if [[ "$PROFILE" == "remote" ]] && [[ -n "${GITHUB_USER:-}" ]]; then
        AUTHORIZED_KEYS=$(fetch_github_keys "$GITHUB_USER") || true
    fi

    # Get flake configuration name
    FLAKE_CONFIG=$(get_flake_config "$PROFILE" "$PLATFORM" "$ARCH")

    # Apply configuration
    apply_configuration "$FLAKE_CONFIG"

    # Set default shell
    set_default_shell

    # Final message
    echo
    log_success "Installation complete!"
    echo
    echo -e "${BOLD}Next steps:${NC}"
    echo "  1. Start a new terminal session or run: exec zsh"
    echo "  2. If fonts look broken, install a Nerd Font:"
    echo "     https://www.nerdfonts.com/"
    echo
    echo -e "${BOLD}Configuration location:${NC}"
    echo "  Flake: $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "  Profile: $PROFILE"
    echo
    echo -e "${CYAN}Enjoy your new shell! 🚀${NC}"
}

# Run main
main "$@"
