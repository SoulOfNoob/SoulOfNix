# Git configuration
{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # User info should be set per profile/user or via per-repo config
    # Not setting defaults here to avoid git errors with empty strings
    # userName = "Your Name";  # Set in profile or extraConfig
    # userEmail = "you@example.com";  # Set in profile or extraConfig

    # Core settings (using new 'settings' option name)
    settings = {
      core = {
        # Default editor - can be overridden per profile
        editor = lib.mkDefault "nano";
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

      # Color settings - enable auto coloring for all components
      color = lib.genAttrs [ "ui" "branch" "diff" "status" ] (_: "auto");
    };

    # Git aliases (using new 'settings.alias' option name)
    settings.alias = {
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

  # Delta for better diffs (optional, can be enabled per profile)
  programs.delta = {
    enable = lib.mkDefault false;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
    };
  };
}
