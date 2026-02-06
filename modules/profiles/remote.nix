# Remote profile - minimal configuration for servers
{ config, lib, pkgs, authorizedKeys ? [ ], ... }:

{
  imports = [ ./base.nix ];

  # Minimal package set for servers
  home.packages = [
    # Keep it minimal - core tools only
    # Additional tools from home/default.nix are still included
  ];

  # Simpler prompt for remote servers
  programs.zsh = {
    # Override some settings for remote
    initContent = lib.mkAfter ''
      # Indicate this is a remote session
      export SOUL_OF_NIX_PROFILE="remote"
    '';
  };

  # Git - minimal config, user should set their own identity
  programs.git = {
    extraConfig = {
      # Don't set user identity on servers - use per-repo config
      user.useConfigOnly = true;
    };
  };

  # SSH authorized keys from GitHub
  home.file.".ssh/authorized_keys" = lib.mkIf (authorizedKeys != [ ]) {
    text = lib.concatStringsSep "\n" authorizedKeys + "\n";
  };

  # Disable some heavier features
  programs.tmux.plugins = lib.mkForce [
    pkgs.tmuxPlugins.sensible
    pkgs.tmuxPlugins.yank
  ];
}
