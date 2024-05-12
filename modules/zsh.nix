{ ... }:

{
  imports = [ ./bat.nix ./lsd.nix ];

  programs.zsh = {
    enable = true;
    # TODO: check this: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.zsh.enableCompletion
    enableCompletion = true;

    autosuggestion.enable = true;

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

    shellAliases = {
      cat = "bat";
      ls = "lsd";
    };
  };
}
