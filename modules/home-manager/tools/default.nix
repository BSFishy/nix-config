{ inputs, pkgs, ... }:

{
  home.packages = [
    pkgs.go
    pkgs.lazydocker
    pkgs.vault

    inputs.agenix.packages.${pkgs.system}.agenix
  ];
}
