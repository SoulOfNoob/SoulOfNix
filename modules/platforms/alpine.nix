# Alpine Linux platform configuration
# Alpine uses OpenRC, not systemd
{ config, lib, pkgs, ... }:

{
  # Alpine-specific packages
  home.packages = with pkgs; [
    # Basic utilities that might not be present
    procps
    coreutils
  ];

  # ZSH configuration for Alpine
  programs.zsh = {
    oh-my-zsh.plugins = [
      "git"
      "node"
      "npm"
      "docker"
      "github"
      "yarn"
      "ssh-agent"
      # No systemd plugin - Alpine uses OpenRC
    ];

    initExtra = lib.mkAfter ''
      # Alpine Linux specific settings

      # SSH agent configuration
      zstyle :omz:plugins:ssh-agent agent-forwarding on
      zstyle :omz:plugins:ssh-agent ssh-add-args -q
      zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519

      # Set locale if not set (Alpine often doesn't have full locale support)
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
  xdg = {
    enable = true;
    userDirs.enable = lib.mkDefault false;  # Alpine might not have xdg-user-dirs
  };
}
