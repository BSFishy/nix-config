{ ... }:

{
  home.shell = {
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  imports = [
    # Set up shell related things
    ./zsh.nix

    # Set up prompt
    ./starship.nix

    # Set up tools
    ./tools.nix

    # Set up Nix command-not-found replacement
    ./nix-index.nix
  ];
}
