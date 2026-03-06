{ ... }:

{
  imports = [
    ./neovim.nix
    ./tmux.nix
  ];

  home.file.".lldbinit".source = ./.lldbinit;
}
