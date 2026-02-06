# Slackware / UnRAID platform configuration
# Uses single-user Nix mode (no daemon)
{ config, lib, pkgs, ... }:

{
  imports = [ ./linux-base.nix ];

  # No additional packages needed (inherits procps, coreutils from linux-base)

  # Slackware-specific ZSH configuration
  programs.zsh = {
    initContent = lib.mkAfter ''
      # Slackware-specific: Nix single-user mode
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
  xdg.userDirs.enable = lib.mkDefault false;

  # Special activation for UnRAID persistent storage
  home.activation.unraidPersistence = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Create persistent directory on UnRAID's /boot partition
    if [ -d /boot/config ] && [ -w /boot/config ]; then
      $DRY_RUN_CMD mkdir -p /boot/config/extra
    fi
  '';
}
