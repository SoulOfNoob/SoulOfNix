# macOS (Darwin) platform configuration
{ config, lib, pkgs, ... }:

{
  imports = [ ./base.nix ];

  # macOS-specific packages (GNU tools)
  home.packages = [
    pkgs.coreutils      # GNU coreutils (prefixed with 'g')
    pkgs.gnused         # GNU sed
    pkgs.gnugrep        # GNU grep
  ];

  # macOS-specific ZSH configuration
  programs.zsh = {
    # Add macOS-specific plugins to base plugins
    oh-my-zsh.plugins = lib.mkAfter [
      "macos"        # macOS-specific plugin
      "brew"         # Homebrew integration
    ];

    initContent = lib.mkAfter ''
      # macOS-specific settings

      # Homebrew paths (if installed)
      if [[ -d /opt/homebrew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -d /usr/local/Homebrew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi

      # Use GNU tools without 'g' prefix (use fixed paths to avoid slow brew --prefix calls)
      if [[ -d /opt/homebrew/opt/coreutils/libexec/gnubin ]]; then
        export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
      elif [[ -d /usr/local/opt/coreutils/libexec/gnubin ]]; then
        export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
      fi

      if [[ -d /opt/homebrew/opt/gnu-sed/libexec/gnubin ]]; then
        export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
      elif [[ -d /usr/local/opt/gnu-sed/libexec/gnubin ]]; then
        export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
      fi

      # macOS-specific aliases
      alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES && killall Finder"
      alias hidefiles="defaults write com.apple.finder AppleShowAllFiles NO && killall Finder"
      alias flushdns="sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder"

      # Open current directory in Finder
      alias finder="open ."

      # Quick Look from terminal
      alias ql="qlmanage -p"

      # Copy/paste from terminal
      alias pbp="pbpaste"
      alias pbc="pbcopy"
    '';

    shellAliases = {
      # Use GNU ls with color by default (can be overridden by profiles)
      ls = lib.mkDefault "ls --color=auto";
    };
  };

  # Git configuration for macOS
  programs.git = {
    extraConfig = {
      credential = {
        # Use macOS Keychain for credentials
        helper = "osxkeychain";
      };
    };
  };

  # Tmux adjustments for macOS
  programs.tmux = {
    extraConfig = lib.mkAfter ''
      # macOS clipboard integration
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
    '';
  };

  # Environment variables
  home.sessionVariables = {
    # Prefer Homebrew OpenSSL
    LDFLAGS = "-L/opt/homebrew/opt/openssl@3/lib";
    CPPFLAGS = "-I/opt/homebrew/opt/openssl@3/include";
  };
}
