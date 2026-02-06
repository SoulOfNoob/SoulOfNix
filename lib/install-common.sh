#!/usr/bin/env bash
#
# SoulOfNix Common Installation Library
# Shared functions used by install.sh and test scripts
#
# Exported functions:
#   detect_arch()                - Detect and normalize architecture (x86_64/aarch64)
#   detect_os()                  - Detect OS and platform (returns: os:platform format)
#   get_flake_config()           - Build flake configuration name from profile/platform/arch
#   verify_installation()        - Verify home-manager installation succeeded
#   is_nix_installed()           - Check if Nix is installed
#   is_home_manager_available()  - Check if home-manager command is available
#   source_nix_profile()         - Source Nix environment (multi-user or single-user)
#   get_script_dir()             - Get directory containing the calling script
#

# Detect architecture (normalized to x86_64 or aarch64)
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
            echo "ERROR: Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac
}

# Detect operating system and platform
# Returns: "os:platform" (e.g., "debian:linux-systemd")
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
        os=$(grep -oP '(?<=^ID=).+' /etc/os-release 2>/dev/null | tr -d '"' || echo "linux")
        platform="linux-systemd"
    else
        os="unknown"
        platform="linux-systemd"
    fi

    echo "$os:$platform"
}

# Build flake configuration name from profile, platform, and arch
# Args: profile platform arch
# Returns: flake config name (e.g., "local-darwin", "remote-aarch64", "work")
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
            # Linux platforms
            if [[ "$arch" == "aarch64" ]]; then
                echo "${profile}-aarch64"
            else
                echo "${profile}"
            fi
            ;;
    esac
}

# Verify home-manager installation was successful
# Returns: 0 if successful, 1 if verification failed
verify_installation() {
    local errors=0

    echo "Verifying installation..."

    # Check ZSH configuration
    if [[ -f ~/.config/zsh/.zshrc ]]; then
        echo "✓ ZSH configuration exists"
    else
        echo "✗ ZSH configuration missing: ~/.config/zsh/.zshrc"
        errors=$((errors + 1))
    fi

    # Check tmux configuration
    if [[ -f ~/.config/tmux/tmux.conf ]]; then
        echo "✓ Tmux configuration exists"
    else
        echo "✗ Tmux configuration missing: ~/.config/tmux/tmux.conf"
        errors=$((errors + 1))
    fi

    # Test ZSH syntax
    if command -v zsh &>/dev/null; then
        if zsh -n ~/.config/zsh/.zshrc 2>/dev/null; then
            echo "✓ ZSH configuration syntax is valid"
        else
            echo "✗ ZSH configuration has syntax errors"
            errors=$((errors + 1))
        fi
    fi

    # Platform-specific checks
    if [[ -f /etc/slackware-version ]] && [[ -d /boot/config ]]; then
        if grep -q "boot/config" ~/.config/zsh/.zshrc 2>/dev/null; then
            echo "✓ UnRAID persistent history path configured"
        else
            echo "⚠ Warning: UnRAID persistent history path not found in config"
        fi
    fi

    # Check git configuration
    if [[ -f ~/.gitconfig ]]; then
        echo "✓ Git configuration exists"
    else
        echo "⚠ Warning: Git configuration missing (may be normal)"
    fi

    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "Verification completed with $errors error(s)"
        return 1
    else
        echo ""
        echo "✓ All verifications passed!"
        return 0
    fi
}

# Check if Nix is installed
is_nix_installed() {
    command -v nix &>/dev/null
}

# Check if home-manager is available
is_home_manager_available() {
    nix run home-manager -- --version &>/dev/null 2>&1
}

# Source Nix profile (multi-user or single-user)
source_nix_profile() {
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # Multi-user installation
        # shellcheck source=/dev/null
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        return 0
    elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
        # Single-user installation
        # shellcheck source=/dev/null
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
        return 0
    else
        echo "ERROR: Could not find Nix profile script" >&2
        return 1
    fi
}

# Get the directory containing this script
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}
