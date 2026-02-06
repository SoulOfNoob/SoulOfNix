# Tmux configuration
{ config, lib, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    # Terminal settings
    terminal = "screen-256color";

    # History
    historyLimit = 50000;

    # Start windows and panes at 1, not 0
    baseIndex = 1;

    # Mouse support
    mouse = true;

    # Use vim keybindings in copy mode
    keyMode = "vi";

    # Shorter escape time
    escapeTime = 10;

    # Aggressive resize
    aggressiveResize = true;

    # Focus events
    focusEvents = true;

    # Clock mode
    clock24 = true;

    # Prefix key (Ctrl+a like screen, instead of Ctrl+b)
    prefix = "C-a";

    # Plugins
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
    ];

    # Extra configuration
    extraConfig = ''
      # Better splitting
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # New window in current path
      bind c new-window -c "#{pane_current_path}"

      # Easy config reload
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Resize panes with Prefix + Alt + hjkl
      bind -r M-h resize-pane -L 5
      bind -r M-j resize-pane -D 5
      bind -r M-k resize-pane -U 5
      bind -r M-l resize-pane -R 5

      # Quick window navigation
      bind -r C-h previous-window
      bind -r C-l next-window

      # Send prefix to nested tmux
      bind a send-prefix

      # Status bar
      set -g status-position bottom
      set -g status-interval 5

      # Colors (simple theme, override in profiles if needed)
      set -g status-style 'bg=colour235 fg=colour255'
      set -g window-status-current-style 'bg=colour39 fg=colour232 bold'
      set -g pane-border-style 'fg=colour238'
      set -g pane-active-border-style 'fg=colour39'

      # Status bar content
      set -g status-left '#[fg=colour232,bg=colour39,bold] #S #[fg=colour39,bg=colour235,nobold]'
      set -g status-right '#[fg=colour255,bg=colour235] %H:%M #[fg=colour232,bg=colour39,bold] #H '
      set -g status-left-length 30
      set -g status-right-length 50

      # Window status format
      setw -g window-status-format ' #I:#W#F '
      setw -g window-status-current-format ' #I:#W#F '

      # Activity monitoring
      setw -g monitor-activity on
      set -g visual-activity off

      # Don't rename windows automatically
      set -g allow-rename off

      # Increase display time for messages
      set -g display-time 2000
      set -g display-panes-time 3000
    '';
  };
}
