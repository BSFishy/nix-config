{ inputs, pkgs, ... }:

{
  home.packages = [
    pkgs.go
    pkgs.lazydocker

    inputs.agenix.packages.${pkgs.system}.agenix
  ];
}
