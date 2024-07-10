{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.editor;
in
{
  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      terminal = "tmux-256color";
      escapeTime = 10;
      mouse = true;
      keyMode = "vi";
      baseIndex = 1;
      shell = "${pkgs.zsh}/bin/zsh";

      extraConfig = ''
        # Color support
        set -ga terminal-overrides ",xterm-256color:Tc"

        # For Neovim
        set-option -g focus-events on

        # Reload config file with prefix R
        bind r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "Config reloaded.."

        # Vi-like bindings for copy mode
        bind-key -T copy-mode-vi 'v' send -X begin-selection
        bind -T copy-mode-vi y send-keys -X copy-pipe "xclip -selection clipboard"
      '';
    };
  };
}
