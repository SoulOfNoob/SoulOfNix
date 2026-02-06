# Base platform configuration - common to all platforms
# Each platform imports this and adds platform-specific configuration
{ config, lib, pkgs, ... }:

{
  # Common packages needed on all platforms
  # Platform-specific packages should be added in platform files
  home.packages = [
    # Add truly common packages here if any
    # Currently, all package needs are platform-specific
  ];

  # Common ZSH configuration for all platforms
  programs.zsh = {
    # Base oh-my-zsh plugins used on all platforms
    # Platform-specific plugins (systemd, macos, brew, etc.) should be added in platform files
    oh-my-zsh.plugins = lib.mkDefault [
      "git"
      "node"
      "npm"
      "docker"
      "github"
      "vscode"
      "yarn"
    ];
  };

  # XDG directories (may be overridden per platform)
  xdg = {
    enable = lib.mkDefault true;
  };
}
