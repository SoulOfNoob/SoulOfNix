# Development Notes

Lessons learned during the implementation of SoulOfNix.

## Nix / Home-Manager

### Flake Configuration

1. **Architecture-specific profiles required**: Each profile needs variants for different architectures:
   - `local` for x86_64-linux
   - `local-aarch64` for aarch64-linux (ARM64)
   - `local-darwin` for aarch64-darwin (Apple Silicon)
   - `local-darwin-x86` for x86_64-darwin (Intel Mac)

2. **Dynamic username detection**: Use `builtins.getEnv "USER"` with `--impure` flag to detect the current user at evaluation time. This allows the same flake to work for different users without hardcoding.

3. **Home directory for root**: Linux root user's home is `/root`, not `/home/root`.

### Deprecated Options (Home-Manager 24.x)

The following options are deprecated and should be avoided:

| Deprecated | Replacement |
|------------|-------------|
| `programs.zsh.initExtra` | `programs.zsh.initContent` |
| `programs.ssh.extraConfig` | `programs.ssh.matchBlocks."*".extraOptions` |
| Default `programs.zsh.dotDir` | Set explicitly: `programs.zsh.dotDir = ".config/zsh"` |
| Implicit `programs.ssh` defaults | Set `programs.ssh.enableDefaultConfig = false` and configure manually |
| `programs.delta.enableGitIntegration` | Option doesn't exist - delta integrates automatically when enabled |

### Module Priorities

Use `lib.mkDefault` for base configuration values that profiles should be able to override:

```nix
# In base module
shellAliases = lib.mapAttrs (name: lib.mkDefault) {
  ls = "ls --color=auto";
  la = "ls -A";
};

# In profile (can override without conflict)
shellAliases = {
  ls = "eza --icons";
  la = "eza -a --icons";
};
```

### File Permissions

Home-manager creates symlinks to the Nix store for managed files. Don't try to `chmod` symlinks - the store is read-only:

```nix
# Wrong - will fail on symlinks
[ -f "$HOME/.ssh/config" ] && chmod 600 "$HOME/.ssh/config"

# Correct - skip symlinks
[ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ] && chmod 600 "$HOME/.ssh/config"
```

## Docker Testing

### No Systemd in Containers

Docker containers don't have systemd. Use `--init none` with the Nix installer and manually start the daemon:

```bash
# Install without init system
curl ... | sh -s -- install linux --no-confirm --init none

# Start daemon manually
sudo /nix/var/nix/profiles/default/bin/nix-daemon &
sleep 2

# Source profile
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### Environment Variables

Home-manager requires `USER` environment variable. Set it before running:

```bash
export USER=$(whoami)
```

### Architecture Detection

Docker on Apple Silicon runs ARM64 Linux containers. Detect and use the correct profile:

```bash
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  PROFILE_SUFFIX="-aarch64"
else
  PROFILE_SUFFIX=""
fi
nix run home-manager -- switch --flake ".#local${PROFILE_SUFFIX}" --impure
```

## Makefile

### Tabs Required

Makefile recipes MUST use tabs, not spaces. When writing Makefiles programmatically, ensure proper tab characters.

### Pattern Rules

Explicit targets are more reliable than pattern rules (`build-%:`) in some Make versions. Consider using explicit targets for critical operations.

## SSH Configuration

### matchBlocks vs extraConfig

Use `matchBlocks` for structured SSH configuration:

```nix
programs.ssh.matchBlocks = {
  "*" = {
    identitiesOnly = true;
    serverAliveInterval = 60;
    extraOptions = {
      ControlMaster = "auto";
      ControlPath = "~/.ssh/sockets/%r@%h-%p";
    };
  };
};
```

### Platform-Specific Options

Use `lib.optionalAttrs` for platform-specific SSH options:

```nix
extraOptions = {
  # Common options
} // lib.optionalAttrs pkgs.stdenv.isDarwin {
  # macOS-only options
  IdentityAgent = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
};
```

## ZSH Configuration

### dotDir Setting

Setting `programs.zsh.dotDir = ".config/zsh"` moves `.zshrc` to `~/.config/zsh/.zshrc`. Update any references accordingly.

### Plugin Overrides

Use `lib.mkForce` to completely replace plugin lists in platform modules:

```nix
programs.zsh.oh-my-zsh.plugins = lib.mkForce [
  "git"
  "macos"  # Platform-specific
];
```

## Testing Checklist

Before releasing:

1. Run `nix flake check --all-systems`
2. Test Docker containers: `make -C tests test`
3. Test on real hardware for each target platform
4. Verify ZSH loads correctly: `zsh -n ~/.config/zsh/.zshrc`
5. Check for deprecation warnings in build output
