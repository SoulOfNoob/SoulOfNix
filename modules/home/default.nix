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
  home.packages = with pkgs; [
    # Core utilities
    git
    wget
    curl
    tree
    htop
    nano

    # Shell utilities
    zsh
    tmux

    # Network utilities
    openssh

    # Additional useful tools
    jq
    ripgrep
    fd
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
