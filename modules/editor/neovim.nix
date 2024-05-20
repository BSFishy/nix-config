{ config, lib, pkgs, ... }:

let
  cfg = config.distro.editor;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      # LazyVim depdendencies
      pkgs.fd
      pkgs.ripgrep
      pkgs.lazygit

      # Mason dependencies
      pkgs.curl
      pkgs.unzip
      pkgs.wget
      pkgs.gzip
      pkgs.gnutar

      # Tree sitter binary
      pkgs.tree-sitter
    ];

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      withNodeJs = true;
      withPython3 = true;
    };
  };
}
