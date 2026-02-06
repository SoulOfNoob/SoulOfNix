# Linux with systemd (Debian, Arch, Fedora, etc.)
{ config, lib, pkgs, ... }:

{
  # Linux-specific packages
  home.packages = with pkgs; [
    # System utilities
    procps        # ps, top, etc.
    util-linux    # Various Linux utilities
  ];

  # ZSH configuration for Linux
  programs.zsh = {
    oh-my-zsh.plugins = [
      "git"
      "node"
      "npm"
      "docker"
      "github"
      "vscode"
      "yarn"
      "ssh-agent"    # Linux uses ssh-agent plugin
      "systemd"      # Systemd shortcuts
    ];

    initExtra = lib.mkAfter ''
      # Linux-specific settings

      # SSH agent configuration
      zstyle :omz:plugins:ssh-agent agent-forwarding on
      zstyle :omz:plugins:ssh-agent ssh-add-args -q
      zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519

      # Systemd aliases are provided by the plugin, but add more
      alias jctl="journalctl"
      alias jctlu="journalctl --user"
      alias sctl="systemctl"
      alias sctlu="systemctl --user"
    '';
  };

  # Systemd user services (if you want home-manager to manage any)
  # systemd.user.services = { };

  # XDG directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
