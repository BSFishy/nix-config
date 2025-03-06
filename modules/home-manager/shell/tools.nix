{ pkgs, ... }:

{
  home.packages = [
    pkgs.bat
    pkgs.lsd
  ];

  programs.bash = {
    enable = true;
  };
}
