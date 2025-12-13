{
  inputs,
  pkgs,
  system,
  ...
}:

{
  imports = [
    ./ai.nix
    ./shell.nix
  ];

  home.packages = [
    pkgs.go
    pkgs.lazydocker
    pkgs.vault

    inputs.agenix.packages.${system}.agenix
  ];
}
