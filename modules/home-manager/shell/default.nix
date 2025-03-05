{ ... }:

{
  home.shell = {
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  imports = [
    # Set up shell related things
    ./bash.nix
    ./zsh.nix

    # Set up prompt
    ./starship.nix

    # Set up tools
    ./tools.nix
  ];
}
