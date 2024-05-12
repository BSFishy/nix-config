{ ... }:

{
  imports = [
    # Install shell tools
    ./modules/zsh.nix
    ./modules/starship.nix

    # Install development tools
    ./modules/tmux.nix
    ./modules/neovim.nix
  ];
}
