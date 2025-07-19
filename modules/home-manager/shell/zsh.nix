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

    initContent = ''
      export PATH="$PATH:${config.home.homeDirectory}/.local/bin"
      ${pkgs.nix-your-shell}/bin/nix-your-shell ${pkgs.zsh}/bin/zsh | source /dev/stdin
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
