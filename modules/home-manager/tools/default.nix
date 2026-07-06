{
  inputs,
  pkgs,
  system,
  ...
}:

{
  imports = [
    ./ai
    ./codiff.nix
    ./shell.nix
  ];

  home.packages = [
    pkgs.go
    pkgs.lazydocker
    pkgs.vault
    pkgs.zotero

    inputs.agenix.packages.${system}.agenix
  ];

  programs.mise.enable = true;
}
