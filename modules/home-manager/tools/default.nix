{
  inputs,
  pkgs,
  system,
  ...
}:

{
  imports = [
    ./ai.nix
  ];

  home.packages = [
    pkgs.go
    pkgs.lazydocker
    pkgs.vault

    inputs.agenix.packages.${system}.agenix
  ];
}
