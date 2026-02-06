# ZSH configuration with oh-my-zsh and PowerLevel10k
{ config, lib, pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin isLinux;

  # P10k configuration file
  p10kConfig = ../../config/p10k/base.zsh;
in
{
  programs.zsh = {
    enable = true;

    # Set dotDir to silence deprecation warning
    dotDir = ".config/zsh";

    # Enable completion
    enableCompletion = true;

    # History settings
    history = {
      size = 50000;
      save = 50000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    # Oh-my-zsh configuration
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "node"
        "npm"
        "docker"
        "github"
        "vscode"
        "yarn"
      ] ++ lib.optionals isLinux [
        "ssh-agent"  # Linux only - macOS uses 1Password SSH agent
      ];
    };

    # Built-in home-manager ZSH features
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Shell aliases - use mkDefault so profiles can override
    shellAliases = lib.mapAttrs (name: lib.mkDefault) {
      # Git aliases
      gcb = "git checkout -b";
      gco = "git checkout";
      gm = "git merge";
      gf = "git fetch";
      gst = "git status";
      gd = "git diff";
      gds = "git diff --staged";
      gl = "git log --oneline -20";
      gp = "git push";
      gpl = "git pull";

      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Common commands with better defaults
      ls = "ls --color=auto";
      ll = "ls -lah";
      la = "ls -A";
      l = "ls -CF";

      # Safety aliases
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";

      # Shortcuts
      h = "history";
      c = "clear";

      # Docker aliases (base - extended in work profile)
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
    };

    # PowerLevel10k theme
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    # Init content - loaded at the end of .zshrc
    initContent = ''
      # Enable Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # SSH agent settings (Linux only - macOS uses 1Password agent)
      ${lib.optionalString isLinux ''
        zstyle :omz:plugins:ssh-agent agent-forwarding on
        zstyle :omz:plugins:ssh-agent ssh-add-args -q
        zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519
      ''}

      # pyenv initialization
      if command -v pyenv 1>/dev/null 2>&1; then
        export PYENV_ROOT="$HOME/.pyenv"
        [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
      fi

      # NVM initialization
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Load PowerLevel10k configuration
      [[ -f ${p10kConfig} ]] && source ${p10kConfig}
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

      # Custom functions
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Extract any archive
      extract() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.tar.xz)    tar xJf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.rar)       unrar x "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
    '';

    # Profile extra - loaded in .zprofile
    profileExtra = ''
      # Ensure PATH includes common locations
      export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
    '';
  };
}
