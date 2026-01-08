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
in
{
  home.packages = [ sessionizer ] ++ packages;

  programs.tmux = {
    enable = true;

    sensibleOnTop = false;
    terminal = "tmux-256color";
    escapeTime = 10;
    mouse = false;
    keyMode = "vi";
    baseIndex = 1;
    shell = "${pkgs.zsh}/bin/zsh";

    plugins = [
      {
        plugin = pkgs.tmuxPlugins.gruvbox;
        extraConfig = ''
          set -g @tmux-gruvbox-right-status-x '#T'
          set -g @tmux-gruvbox-right-status-y '%Y-%m-%d'
        '';
      }

      {
        plugin = pkgs.tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }

      {
        plugin = pkgs.tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
    ];

    extraConfig = ''
      # Color support
      set -ga terminal-overrides ",xterm-256color:Tc"

      # For Neovim
      set-option -g focus-events on

      # Reload config file with prefix R
      bind-key -N "Reload the tmux configuration" r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "Config reloaded.."

      # Open sessionizer with C-b + ;
      bind-key -N "Open sessionizer" \; display-popup -E "${sessionizer}/bin/tmux-sessionizer"

      # Vi-like bindings for copy mode
      bind-key -T copy-mode-vi v send -X begin-selection

      # Vi-like bindings for copy mode with universal clipboard support
      # bind-key -T copy-mode-vi y send -X copy-pipe "tmux save-buffer - | sh -c 'if [ -n \"\$WAYLAND_DISPLAY\" ]; then wl-copy; else xclip -selection clipboard; fi'"
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
