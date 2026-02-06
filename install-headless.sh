#!/usr/bin/env bash
#
# SoulOfNix Headless Installer
# Non-interactive installer for automation and CI/CD
#
# Environment variables:
#   NIX_ZSH_PROFILE  - Profile to install (remote, local, work) [required]
#   NIX_ZSH_USER     - Username (defaults to current user)
#   GITHUB_USER      - GitHub username for SSH key fetch (remote profile)
#   SKIP_NIX_INSTALL - Skip Nix installation if set to "1"
#   SKIP_SHELL_CHANGE - Skip changing default shell if set to "1"
#
# Usage:
#   NIX_ZSH_PROFILE=remote GITHUB_USER=SoulOfNoob ./install-headless.sh
#
set -euo pipefail

# Export required variable for main installer
export NIX_ZSH_PROFILE="${NIX_ZSH_PROFILE:?NIX_ZSH_PROFILE is required (remote, local, or work)}"

# Validate profile
case "$NIX_ZSH_PROFILE" in
    remote|local|work)
        ;;
    *)
        echo "Error: Invalid profile '$NIX_ZSH_PROFILE'. Must be: remote, local, or work"
        exit 1
        ;;
esac

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run main installer
exec "$SCRIPT_DIR/install.sh"
