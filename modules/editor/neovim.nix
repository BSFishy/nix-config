{ config, lib, pkgs, ... }:

let
  cfg = config.distro.editor;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      # Depdendencies
      pkgs.fd
      pkgs.ripgrep
      pkgs.lazygit
    ];

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      vimdiffAlias = true;

      withNodeJs = true;
      withPython3 = true;
    };
  };
}
