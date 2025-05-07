{ pkgs, ... }:

{
  home.packages = [
    pkgs.go
    pkgs.lazydocker
  ];
}
