{ config, pkgs, ... }:

{
  imports = [
    ./tools/bat.nix
    ./tools/lsd.nix
  ];

  programs.zsh = {
    enable = true;
    # TODO: check this: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enableCompletion
    enableCompletion = true;

    initExtra = ''
      export PATH="$PATH:${config.home.homeDirectory}/.local/bin"
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
        "command-not-found"
        "git"
        "git-flow"
        "rust"
        "nvm"
      ];
    };

    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.8.0";
          sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
        };
      }
    ];

    shellAliases = {
      # TODO: should these reference the package names?
      cat = "bat";
      ls = "lsd";
    };
  };
}
