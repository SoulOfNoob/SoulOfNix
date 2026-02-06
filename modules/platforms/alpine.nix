# Alpine Linux platform configuration
# Alpine uses OpenRC, not systemd
{ config, lib, pkgs, ... }:

{
  imports = [ ./linux-base.nix ];

  # No additional packages needed (inherits procps, coreutils from linux-base)

  # Alpine-specific ZSH configuration
  programs.zsh = {
    initContent = lib.mkAfter ''
      # Alpine-specific: Set locale (Alpine often doesn't have full locale support)
      export LANG="''${LANG:-C.UTF-8}"
      export LC_ALL="''${LC_ALL:-C.UTF-8}"

      # OpenRC service aliases (instead of systemd)
      alias rcstatus="rc-status"
      alias rcservice="rc-service"
      alias rcupdate="rc-update"

      # Service management shortcuts
      svc() {
        if [ -z "$1" ] || [ -z "$2" ]; then
          echo "Usage: svc <action> <service>"
          echo "Actions: start, stop, restart, status"
          return 1
        fi
        sudo rc-service "$2" "$1"
      }
    '';
  };

  # XDG directories (simpler setup for Alpine)
  xdg.userDirs.enable = lib.mkDefault false;  # Alpine might not have xdg-user-dirs
}
