{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.editor;
  extraPkgs = if pkgs.stdenv.hostPlatform.isLinux then [ pkgs.gcc ] else [ ];
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      # LazyVim depdendencies
      pkgs.fd
      pkgs.fzf
      pkgs.ripgrep
      pkgs.lazygit
      pkgs.lua54Packages.luarocks

      # Mason dependencies
      pkgs.curl
      pkgs.unzip
      pkgs.wget
      pkgs.gzip
      pkgs.gnutar

      # Tree sitter binary
      pkgs.tree-sitter
    ] ++ extraPkgs;

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
