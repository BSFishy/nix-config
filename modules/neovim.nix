{ pkgs, ... }:

{
  # TODO: download config from github
  home.packages = [
    pkgs.neovim

    # Depdendencies
    pkgs.fd
    pkgs.ripgrep
    pkgs.lazygit
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
