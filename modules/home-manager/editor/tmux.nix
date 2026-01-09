{
  config,
  pkgs,
  ...
}:

let
  # some additional packages for clipboard support on linux
  packages =
    if pkgs.stdenv.hostPlatform.isLinux then
      [
        pkgs.wl-clipboard
        pkgs.xclip
      ]
    else
      [ ];

  # add sessionizer
  sessionizer = pkgs.writeShellScriptBin "tmux-sessionizer" (builtins.readFile ./tmux-sessionizer.sh);

  # patched tmux-resurrect plugin
  tmux-resurrect = import ./tmux-resurrect.nix { inherit pkgs; };
in
{
  home.packages = [ sessionizer ] ++ packages;

  programs.tmux = {
    enable = true;

    sensibleOnTop = true;
    terminal = "tmux-256color";
    mouse = false;
    keyMode = "vi";
    baseIndex = 1;
    shell = "${pkgs.zsh}/bin/zsh";

    plugins = [
      # gruvbox theme
      {
        plugin = pkgs.tmuxPlugins.gruvbox;
        extraConfig = ''
          set -g @tmux-gruvbox-right-status-x '#T'
          set -g @tmux-gruvbox-right-status-y '%Y-%m-%d'
          set -g @tmux-gruvbox-right-status-z '%H:%M '
        '';
      }

      # save and restore all sessions
      {
        plugin = tmux-resurrect;
        extraConfig = ''
          set -g @resurrect-processes '"~nvim->nvim"'
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }

      # continuously save sessions and automatically restore them
      {
        plugin = pkgs.tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
    ];

    extraConfig = ''
      # Set statusbar redraw interval to every second
      set -g status-interval 1

      # Reload config file with prefix R
      bind-key -N "Reload the tmux configuration" r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "Config reloaded.."

      # Open sessionizer with C-b + ;
      bind-key -N "Open sessionizer" \; display-popup -E "${sessionizer}/bin/tmux-sessionizer"

      # Vi-like bindings for copy mode
      bind-key -T copy-mode-vi v send -X begin-selection

      # Vi-like bindings for copy mode with universal clipboard support
      bind-key -T copy-mode-vi y send -X copy-selection

      # Vi-like bindings for copy line
      bind-key -T copy-mode-vi Y send -X copy-line

      # Vi-like bindings for paste in pane
      bind-key -T copy-mode-vi p paste-buffer

      # Fix vi-mode mouse binds
      unbind -T root MouseDragEnd1Pane
      bind -T copy-mode-vi MouseDragEnd1Pane send -X stop-selection
    '';
  };
}
