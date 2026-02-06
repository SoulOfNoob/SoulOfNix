# Base profile - shared configuration for all profiles
{ config, lib, pkgs, ... }:

{
  # Base is imported by all profiles, so minimal configuration here
  # Profile-specific settings should go in their respective files

  # Ensure basic programs are enabled
  programs.zsh.enable = lib.mkDefault true;
  programs.git.enable = lib.mkDefault true;
  programs.tmux.enable = lib.mkDefault true;
}
