# Git configuration
{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # User info should be set per profile/user or via per-repo config
    # Not setting defaults here to avoid git errors with empty strings
    # userName = "Your Name";  # Set in profile or extraConfig
    # userEmail = "you@example.com";  # Set in profile or extraConfig

    # Core settings
    extraConfig = {
      core = {
        editor = "nano";
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
      };

      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = true;
      };

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      fetch = {
        prune = true;
      };

      diff = {
        colorMoved = "default";
      };

      merge = {
        conflictStyle = "diff3";
      };

      rebase = {
        autoStash = true;
      };

      # Better diff algorithm
      diff.algorithm = "histogram";

      # Remember merge conflict resolutions
      rerere.enabled = true;

      # Color settings
      color = {
        ui = "auto";
        branch = "auto";
        diff = "auto";
        status = "auto";
      };
    };

    # Git aliases
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      undo = "reset --soft HEAD~1";
      amend = "commit --amend --no-edit";
      wip = "!git add -A && git commit -m 'WIP'";
    };

    # Delta for better diffs (optional, can be enabled per profile)
    delta = {
      enable = lib.mkDefault false;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
      };
    };

    # Ignore patterns
    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"

      # Editor
      "*.swp"
      "*.swo"
      "*~"
      ".idea/"
      ".vscode/"

      # Environment
      ".env.local"
      ".env.*.local"

      # Dependencies
      "node_modules/"
      "vendor/"

      # Build outputs
      "dist/"
      "build/"
      "*.log"
    ];
  };
}
