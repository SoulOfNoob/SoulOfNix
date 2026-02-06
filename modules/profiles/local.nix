# Local profile - personal machines configuration
{ config, lib, pkgs, ... }:

{
  imports = [ ./base.nix ];

  # Additional packages for local development
  home.packages = [
    # Development tools
    pkgs.gh # GitHub CLI
    pkgs.lazygit # Terminal UI for git
    pkgs.delta # Better git diffs

    # File utilities
    pkgs.bat # Better cat
    pkgs.eza # Better ls
    pkgs.fzf # Fuzzy finder
    pkgs.zoxide # Smarter cd

    # Process utilities
    pkgs.btop # Better htop

    # Network utilities
    pkgs.httpie # Better curl for APIs

    # Archive utilities
    pkgs.unzip
    pkgs.p7zip
  ];

  # Enhanced ZSH for local
  programs.zsh = {
    shellAliases = {
      # Use enhanced tools
      cat = "bat --style=plain";
      ls = "eza --icons";
      ll = "eza -la --icons --git";
      la = "eza -a --icons";
      lt = "eza --tree --icons --level=2";

      # Lazy git
      lg = "lazygit";
    };

    initContent = lib.mkAfter ''
      # Profile indicator
      export SOUL_OF_NIX_PROFILE="local"

      # Initialize zoxide
      if command -v zoxide 1>/dev/null 2>&1; then
        eval "$(zoxide init zsh)"
      fi

      # Initialize fzf
      if command -v fzf 1>/dev/null 2>&1; then
        source <(fzf --zsh)
      fi
    '';
  };

  # Git with delta for better diffs
  programs.delta.enable = true;

  # FZF configuration
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
  };

  # Bat configuration
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
    };
  };
}
