#!/usr/bin/env bash
set -e

# Get project root directory (assuming script is run from project root or tests/)
if [ -f "./lib/install-common.sh" ]; then
    # Running from project root
    PROJECT_ROOT="."
elif [ -f "../lib/install-common.sh" ]; then
    # Running from tests/ directory
    PROJECT_ROOT=".."
else
    echo "ERROR: Cannot find lib/install-common.sh"
    echo "Please run this script from the project root: ./tests/test-install.sh"
    exit 1
fi

# Source shared library
# shellcheck source=../lib/install-common.sh
source "${PROJECT_ROOT}/lib/install-common.sh"

echo "Testing SoulOfNix on $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || uname -s)..."

# Detect system using shared functions
ARCH=$(detect_arch)
OS_INFO=$(detect_os)
OS=$(echo "$OS_INFO" | cut -d: -f1)
PLATFORM=$(echo "$OS_INFO" | cut -d: -f2)

echo "Detected OS: $OS ($PLATFORM)"
echo "Detected architecture: $ARCH"

# Default to remote profile for testing (minimal dependencies)
PROFILE=${TEST_PROFILE:-remote}

# Get flake config name using shared function
FLAKE_CONFIG=$(get_flake_config "$PROFILE" "$PLATFORM" "$ARCH")
echo "Testing profile: $FLAKE_CONFIG"

# Install Nix (Docker-specific: no init system)
echo ""
echo "Installing Nix..."
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install linux --no-confirm --init none

# Start nix-daemon manually (Docker has no init system)
echo "Starting nix-daemon..."
if [ "$USER" = "root" ]; then
  /nix/var/nix/profiles/default/bin/nix-daemon &
else
  sudo /nix/var/nix/profiles/default/bin/nix-daemon &
fi
sleep 2

# Source nix profile using shared function
export USER=$(whoami)
source_nix_profile

# Verify Nix is available
echo "Nix version: $(nix --version)"

# Navigate to SoulOfNix directory (if not already there)
if [ -f "./flake.nix" ]; then
  # Already in SoulOfNix directory
  echo "Already in project directory: $(pwd)"
elif [ -d ~/SoulOfNix ]; then
  cd ~/SoulOfNix
elif [ -d /root/SoulOfNix ]; then
  cd /root/SoulOfNix
else
  echo "ERROR: SoulOfNix directory not found"
  exit 1
fi

# Check flake
echo ""
echo "Checking flake..."
nix flake check --no-build

# Apply profile
echo ""
echo "Applying home-manager profile: $FLAKE_CONFIG"
nix run home-manager -- switch --flake ".#${FLAKE_CONFIG}" --impure

# Verify installation using shared function
echo ""
if verify_installation; then
  echo ""
  echo "=========================================="
  echo "✓ All tests passed!"
  echo "=========================================="
  exit 0
else
  echo ""
  echo "=========================================="
  echo "✗ Tests failed!"
  echo "=========================================="
  exit 1
fi
