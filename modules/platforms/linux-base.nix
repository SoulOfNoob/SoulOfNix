# Base Linux platform configuration
# Common to all Linux platforms (systemd, Alpine, Slackware)
# Platform-specific Linux variants should import this
{ config, lib, pkgs, ... }:

{
  imports = [ ./base.nix ];

  # Common Linux packages
  home.packages = [
    pkgs.procps        # ps, top, etc. (needed on all Linux)
    pkgs.coreutils     # GNU core utilities
  ];

  # Common Linux ZSH configuration
  programs.zsh = {
    # Add ssh-agent plugin (used by all Linux platforms)
    oh-my-zsh.plugins = lib.mkAfter [
      "ssh-agent"
    ];

    # Common SSH agent configuration for all Linux platforms
    initContent = lib.mkAfter ''
      # SSH agent configuration (common to all Linux platforms)
      zstyle :omz:plugins:ssh-agent agent-forwarding on
      zstyle :omz:plugins:ssh-agent ssh-add-args -q
      zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519
    '';
  };

  # XDG directories (may be overridden per platform)
  xdg = {
    enable = true;
  };
}
