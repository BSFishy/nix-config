{ pkgs, ... }:

{
  home.packages = [
    # man pages
    pkgs.man-db
    pkgs.man-pages
  ];

  imports = [
    ./direnv.nix
    ./git.nix
    ./insert-license.nix
    ./nixfmt.nix
    ./ssh.nix
    ./switch-shell.nix
  ];
}
