# Local profile - personal machines configuration
{ config, lib, pkgs, ... }:

{
  imports = [ ./base.nix ];

  # Additional packages for local development
  home.packages = with pkgs; [
    # Development tools
    gh               # GitHub CLI
    lazygit          # Terminal UI for git
    delta            # Better git diffs

    # File utilities
    bat              # Better cat
    eza              # Better ls
    fzf              # Fuzzy finder
    zoxide           # Smarter cd

    # Process utilities
    btop             # Better htop

    # Network utilities
    httpie           # Better curl for APIs

    # Archive utilities
    unzip
    p7zip
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
  programs.git.delta.enable = true;

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
