{ pkgs, ... }:

{
  home.packages = [
    pkgs.bat
    pkgs.lsd
  ];
}
