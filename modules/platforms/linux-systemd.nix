# Linux with systemd (Debian, Arch, Fedora, etc.)
{ config, lib, pkgs, ... }:

{
  imports = [ ./linux-base.nix ];

  # Additional systemd-specific packages
  home.packages = [
    pkgs.util-linux    # Linux utilities (systemd-specific tools)
  ];

  # Systemd-specific ZSH configuration
  programs.zsh = {
    # Add systemd plugin
    oh-my-zsh.plugins = lib.mkAfter [
      "systemd"      # Systemd shortcuts
    ];

    initContent = lib.mkAfter ''
      # Systemd-specific aliases
      alias jctl="journalctl"
      alias jctlu="journalctl --user"
      alias sctl="systemctl"
      alias sctlu="systemctl --user"
    '';
  };

  # XDG user directories (full support on systemd systems)
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
