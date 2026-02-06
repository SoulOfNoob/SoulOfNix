# Migration Guide: ZSH-Environment to SoulOfNix

This guide helps you migrate from the bash-based ZSH-Environment to the Nix-based SoulOfNix.

## Overview

| Aspect | ZSH-Environment | SoulOfNix |
|--------|-----------------|-----------|
| Package management | apt/pacman/brew | Nix + home-manager |
| Configuration | Bash scripts | Nix expressions |
| Reproducibility | Manual | Automatic (flake.lock) |
| Rollback | Manual | Built-in (home-manager generations) |
| Cross-platform | Scripts per OS | Unified Nix config |

## Step-by-Step Migration

### 1. Backup Current Configuration

```bash
# Backup your current ZSH config
cp -r ~/.zshrc ~/.zshrc.backup
cp -r ~/.oh-my-zsh ~/.oh-my-zsh.backup
cp -r ~/.p10k.zsh ~/.p10k.zsh.backup
cp -r ~/.tmux.conf ~/.tmux.conf.backup
```

### 2. Note Your Custom Configurations

Before migrating, document any customizations:

- Custom aliases in `~/.oh-my-zsh/custom/`
- Custom plugins
- Environment variables
- SSH configurations
- Git config (username, email, signing keys)

### 3. Install SoulOfNix

```bash
# Clone SoulOfNix
git clone https://github.com/jappyjan/SoulOfNix.git
cd SoulOfNix

# Run installer
./install.sh
```

### 4. Transfer Custom Configurations

#### Custom Aliases

Add to `modules/profiles/local.nix` or create a new module:

```nix
programs.zsh.shellAliases = {
  myalias = "my-command --with-flags";
};
```

#### Custom Environment Variables

```nix
home.sessionVariables = {
  MY_VAR = "value";
};
```

#### Git Identity

```nix
programs.git = {
  userName = "Your Name";
  userEmail = "your.email@example.com";
};
```

#### Additional Packages

```nix
home.packages = with pkgs; [
  your-package
  another-package
];
```

### 5. Apply and Test

```bash
# Rebuild configuration
home-manager switch --flake .#local-darwin  # or your profile

# Start new shell
exec zsh

# Test your configuration
echo $SOUL_OF_NIX_PROFILE
```

## Feature Mapping

### ZSH-Environment Features → SoulOfNix

| ZSH-Environment | SoulOfNix Location |
|-----------------|-------------------|
| `etc/dependencies/debian.sh` | `modules/home/default.nix` |
| `config/all/.zshrc` | `modules/home/zsh.nix` |
| `config/all/.p10k.zsh` | `config/p10k/base.zsh` |
| `config/all/.oh-my-zsh/custom_scripts/` | `programs.zsh.initExtra` |
| `config/work/` | `modules/profiles/work.nix` |
| `config/local/` | `modules/profiles/local.nix` |
| `etc/shell/wizard.sh` | `install.sh` |

### Oh-My-Zsh Plugins

ZSH-Environment plugins are mapped in `modules/home/zsh.nix`:

```nix
oh-my-zsh.plugins = [
  "git"
  "node"
  "npm"
  "docker"
  "github"
  "vscode"
  "yarn"
  "ssh-agent"  # Linux only
];
```

### Custom Scripts

ZSH-Environment custom scripts like `git_alias.zsh` are now shell aliases:

```nix
# Before (bash script)
# gcb() { git checkout -b "$1" }

# After (Nix)
programs.zsh.shellAliases = {
  gcb = "git checkout -b";
};
```

## Platform-Specific Notes

### macOS

SoulOfNix uses 1Password SSH agent instead of the zsh ssh-agent plugin:

```nix
# Configured in modules/platforms/darwin.nix
programs.ssh.extraConfig = ''
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
'';
```

### Alpine Linux

Uses `--init none` for Nix installation (no systemd):

```bash
curl ... | sh -s -- install --no-confirm --init none
```

### UnRAID/Slackware

- History file moved to persistent storage: `/boot/config/extra/.zsh_history`
- Single-user Nix mode
- Add to `/boot/config/go` for persistence:
  ```bash
  [ -f /root/.nix-profile/etc/profile.d/nix.sh ] && . /root/.nix-profile/etc/profile.d/nix.sh
  ```

## Keeping Both Systems

During migration, you can keep both systems:

1. SoulOfNix installs to `~/.nix-profile`
2. Original ZSH config can remain in place
3. Toggle by changing your shell or sourcing different configs

To fully switch:
```bash
# Remove old oh-my-zsh
rm -rf ~/.oh-my-zsh.backup  # only after confirming SoulOfNix works

# Remove old configs
rm ~/.zshrc.backup ~/.p10k.zsh.backup ~/.tmux.conf.backup
```

## Rollback to ZSH-Environment

If you need to go back:

```bash
# Restore backups
cp ~/.zshrc.backup ~/.zshrc
cp -r ~/.oh-my-zsh.backup ~/.oh-my-zsh
cp ~/.p10k.zsh.backup ~/.p10k.zsh
cp ~/.tmux.conf.backup ~/.tmux.conf

# Restart shell
exec zsh
```

## Updating SoulOfNix

Unlike ZSH-Environment which required manual updates, SoulOfNix uses Nix flakes:

```bash
cd ~/SoulOfNix

# Update all inputs
nix flake update

# Apply updates
home-manager switch --flake .#your-profile
```

## Getting Help

- Check existing modules for patterns
- Run `nix flake check` to validate configuration
- Use `home-manager generations` to see/rollback changes
- Read the [Home Manager manual](https://nix-community.github.io/home-manager/)
