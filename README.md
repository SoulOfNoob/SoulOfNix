# SoulOfNix

Nix-based ZSH environment manager using home-manager. Provides a reproducible, declarative shell configuration across Linux and macOS.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/SoulOfNoob/SoulOfNix.git
cd SoulOfNix

# Run the interactive installer
./install.sh
```

### Headless Installation

```bash
# Set environment variables and run
NIX_ZSH_PROFILE=remote GITHUB_USER=your-username ./install.sh

# Or use the dedicated headless script
NIX_ZSH_PROFILE=work ./install-headless.sh
```

## Profiles

| Profile | Description | Use Case |
|---------|-------------|----------|
| `remote` | Minimal configuration | Servers, containers, CI/CD |
| `local` | Enhanced with dev tools | Personal machines |
| `work` | Local + Docker/AWS tools | Work environment |

## Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| macOS (Apple Silicon) | ✅ | Uses 1Password SSH agent |
| macOS (Intel) | ✅ | Uses 1Password SSH agent |
| Debian/Ubuntu | ✅ | Full systemd support |
| Arch Linux | ✅ | Full systemd support |
| Alpine Linux | ✅ | OpenRC (--init none) |
| Slackware/UnRAID | ✅ | Single-user Nix mode |

## Features

- **ZSH** with oh-my-zsh and PowerLevel10k theme
- **Plugins**: git, node, npm, docker, vscode, yarn, ssh-agent
- **Autosuggestions** and **syntax highlighting**
- **Tmux** with sensible defaults and vim keybindings
- **Git** configuration with aliases and delta (local/work profiles)
- **SSH** config with 1Password integration (macOS)
- **Platform-specific** optimizations

## Manual Usage

If you already have Nix and home-manager installed:

```bash
# Apply a profile directly
home-manager switch --flake .#local-darwin  # macOS Apple Silicon
home-manager switch --flake .#local         # Linux x86_64
home-manager switch --flake .#remote        # Minimal Linux
home-manager switch --flake .#work          # Work profile
```

## Configuration

### Customizing Your Setup

1. Fork this repository
2. Edit the profile modules in `modules/profiles/`
3. Add your git identity:

```nix
# In modules/profiles/local.nix or a new module
programs.git = {
  userName = "Your Name";
  userEmail = "your.email@example.com";
};
```

### Available Flake Configurations

- `remote` - Linux x86_64, minimal
- `remote-aarch64` - Linux ARM64, minimal
- `local` - Linux x86_64, enhanced
- `local-darwin` - macOS ARM64, enhanced
- `local-darwin-x86` - macOS Intel, enhanced
- `work` - Linux x86_64, work tools
- `work-darwin` - macOS ARM64, work tools

## Project Structure

```
SoulOfNix/
├── flake.nix                 # Main entry point
├── install.sh                # Interactive installer
├── install-headless.sh       # Non-interactive installer
├── lib/
│   └── mkHome.nix            # Helper function
├── modules/
│   ├── home/                 # Core configuration
│   │   ├── default.nix       # Common packages
│   │   ├── zsh.nix           # ZSH + oh-my-zsh + p10k
│   │   ├── git.nix           # Git configuration
│   │   ├── ssh.nix           # SSH configuration
│   │   └── tmux.nix          # Tmux configuration
│   ├── profiles/             # Environment profiles
│   │   ├── base.nix
│   │   ├── remote.nix
│   │   ├── local.nix
│   │   └── work.nix
│   └── platforms/            # Platform-specific (hierarchical)
│       ├── base.nix          # Common to all platforms
│       ├── darwin.nix        # macOS-specific
│       ├── linux-base.nix    # Common to all Linux
│       ├── linux-systemd.nix # Systemd-based Linux
│       ├── alpine.nix        # Alpine/OpenRC
│       └── slackware.nix     # Slackware/UnRAID
├── config/
│   └── p10k/
│       └── base.zsh          # PowerLevel10k theme
└── tests/
    ├── Makefile
    └── docker/               # Test containers
```

## Testing

### Local Testing (Docker)

```bash
# Run all Docker tests (Linux platforms)
make -C tests test

# Test specific platform
make -C tests test-alpine
make -C tests test-debian
make -C tests test-arch
make -C tests test-slackware

# Quick syntax check (no Nix installation)
make -C tests test-syntax

# Test shared library functions
make -C tests test-lib

# Validate flake
nix flake check
```

### GitHub Actions (Automated CI/CD)

**✅ Automatic testing on every push to main and all pull requests!**

**12 tests run in parallel:**

**Linux (8 tests via Docker):**
- Debian × `remote`, `local`
- Alpine × `remote`, `local`
- Arch × `remote`, `local`
- Slackware × `remote`, `local`

**macOS (4 tests via GitHub runners):**
- macOS 14 (Sonoma) × `local`, `work`
- macOS 15 (Sequoia) × `local`, `work`

View test results: **Actions** tab in GitHub

Manual trigger: **Actions** → **Tests** → **Run workflow**

## Updating

```bash
# Update flake inputs
nix flake update

# Re-apply configuration
home-manager switch --flake .#<your-profile>
```

## Rollback

Home-manager keeps previous generations. To rollback:

```bash
# List generations
home-manager generations

# Rollback to previous
home-manager switch --rollback
```

## Troubleshooting

### Fonts look broken

Install a [Nerd Font](https://www.nerdfonts.com/) and configure your terminal to use it.

### ZSH not set as default shell

```bash
# Add zsh to /etc/shells if needed
echo "$(which zsh)" | sudo tee -a /etc/shells

# Change shell
chsh -s $(which zsh)
```

### Nix command not found after installation

```bash
# Source Nix profile
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
# or for single-user
. ~/.nix-profile/etc/profile.d/nix.sh
```

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for implementation notes, gotchas, and lessons learned.

## Documentation

- **[CI_IMPLEMENTATION.md](CI_IMPLEMENTATION.md)** - GitHub Actions CI/CD implementation and fixes ⭐
- **[.github/TESTING.md](.github/TESTING.md)** - Testing guide and current status
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - Complete refactoring history and improvements
- **[OPTIMIZATIONS.md](OPTIMIZATIONS.md)** - Low-hanging fruit optimizations
- **[NIX_BEST_PRACTICES.md](NIX_BEST_PRACTICES.md)** - Comprehensive Nix best practices guide
- **[DEVELOPMENT.md](DEVELOPMENT.md)** - Implementation notes and lessons learned
- **[MIGRATION.md](MIGRATION.md)** - Migration guide from other setups

## License

MIT
