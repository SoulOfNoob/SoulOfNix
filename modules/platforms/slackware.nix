# Slackware / UnRAID platform configuration
# Uses single-user Nix mode (no daemon)
{ config, lib, pkgs, ... }:

{
  # Minimal additional packages
  home.packages = [
    # Basic utilities
    pkgs.procps
    pkgs.coreutils
  ];

  # ZSH configuration for Slackware/UnRAID
  programs.zsh = {
    oh-my-zsh.plugins = [
      "git"
      "node"
      "npm"
      "docker" # Docker is common on UnRAID
      "github"
      "yarn"
      "ssh-agent"
      # No systemd - Slackware uses SysV init
    ];

    initContent = lib.mkAfter ''
      # Slackware / UnRAID specific settings

      # SSH agent configuration
      zstyle :omz:plugins:ssh-agent agent-forwarding on
      zstyle :omz:plugins:ssh-agent ssh-add-args -q
      zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519

      # Nix single-user mode - ensure profile is sourced
      if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
      fi

      # UnRAID-specific: Use persistent history location
      # /boot is persistent across reboots, /root is not
      if [ -d /boot/config ]; then
        export HISTFILE="/boot/config/extra/.zsh_history"
        mkdir -p "$(dirname "$HISTFILE")"
      fi

      # Slackware service management aliases
      alias slackpkg="sudo slackpkg"

      # UnRAID-specific aliases (if running on UnRAID)
      if [ -f /etc/unraid-version ]; then
        alias unraid-version="cat /etc/unraid-version"
        alias unraid-logs="tail -f /var/log/syslog"
        alias docker-info="docker info"
      fi

      # SysV init service management
      svc() {
        if [ -z "$1" ] || [ -z "$2" ]; then
          echo "Usage: svc <action> <service>"
          echo "Actions: start, stop, restart, status"
          return 1
        fi
        sudo /etc/rc.d/rc."$2" "$1"
      }
    '';
  };

  # XDG directories (minimal for Slackware)
  xdg = {
    enable = true;
    userDirs.enable = lib.mkDefault false;
  };

  # Special activation for UnRAID persistent storage
  home.activation.unraidPersistence = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Create persistent directory on UnRAID's /boot partition
    if [ -d /boot/config ] && [ -w /boot/config ]; then
      $DRY_RUN_CMD mkdir -p /boot/config/extra
    fi
  '';
}
