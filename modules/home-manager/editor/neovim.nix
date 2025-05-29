{
  pkgs,
  ...
}:

let
  extraPkgs = if pkgs.stdenv.hostPlatform.isLinux then [ pkgs.gcc ] else [ ];
in
{
  home.packages = [
    # LazyVim depdendencies
    pkgs.fd
    pkgs.fzf
    pkgs.ripgrep
    pkgs.lazygit

    pkgs.lua51Packages.lua
    pkgs.lua51Packages.luarocks
    pkgs.lua-language-server
    pkgs.ast-grep

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
}
