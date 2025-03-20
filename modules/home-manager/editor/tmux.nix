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

      # Vi-like bindings for copy mode with universal clipboard support
      bind-key -T copy-mode-vi y send -X copy-pipe "tmux save-buffer - | sh -c 'if [ -n \"\$WAYLAND_DISPLAY\" ]; then wl-copy; else xclip -selection clipboard; fi'"
    '';
  };
}
