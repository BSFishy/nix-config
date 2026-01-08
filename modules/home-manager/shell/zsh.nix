{
  config,
  pkgs,
  ...
}:

{
  home.packages = [
    pkgs.nix-your-shell
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    dotDir = config.home.homeDirectory;

    sessionVariables = {
      KEYTIMEOUT = "1";
    };

    initContent = ''
      export PATH="$PATH:${config.home.homeDirectory}/.local/bin"
      ${pkgs.nix-your-shell}/bin/nix-your-shell ${pkgs.zsh}/bin/zsh | source /dev/stdin

      ### --- Vi mode for ZLE ---
      set -o vi
      bindkey -v

      # Edit the current command line in $EDITOR with `v` (press Esc first)
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey -M vicmd 'v' edit-command-line

      # Prefix-aware history on Up/Down
      bindkey '^[[A' history-beginning-search-backward
      bindkey '^[[B' history-beginning-search-forward

      # Optional: word-wise moves in insert mode (Alt-b / Alt-f)
      bindkey '^[b' backward-word
      bindkey '^[f' forward-word

      # Optional: nicer line kills
      bindkey '^U' backward-kill-line
      bindkey '^K' kill-line
    '';

    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "colored-man-pages"

        # NOTE: flake setups don't currently generate the database that this
        # uses for command recommendations. I would like to use it if flakes
        # ever do generate it tho
        # "command-not-found"

        "git"
        "git-flow"
        "rust"
        "nvm"
      ];
    };

    shellAliases = {
      cat = "${pkgs.bat}/bin/bat";
      ls = "${pkgs.lsd}/bin/lsd";
    };
  };
}
