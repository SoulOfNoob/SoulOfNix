# Main home-manager module - common packages and imports
{ config, lib, pkgs, ... }:

{
  imports = [
    ./zsh.nix
    ./git.nix
    ./ssh.nix
    ./tmux.nix
  ];

  # Common packages for all profiles
  home.packages = [
    # Core utilities
    pkgs.git
    pkgs.wget
    pkgs.curl
    pkgs.tree
    pkgs.htop
    pkgs.nano

    # Shell utilities
    pkgs.zsh
    pkgs.tmux

    # Network utilities
    pkgs.openssh

    # Additional useful tools
    pkgs.jq
    pkgs.ripgrep
    pkgs.fd
  ];

  # Enable home-manager to manage itself
  programs.home-manager.enable = true;

  # Session variables
  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
    PAGER = "less";
  };

  # XDG directories
  xdg.enable = true;
}
