{ inputs, pkgs, ... }:

{
  home.packages = [
    pkgs.go
    pkgs.lazydocker
    pkgs.vault

    inputs.agenix.packages.${pkgs.system}.agenix
  ];

  programs.codex = {
    enable = true;
    settings = {
      tools.web_search = true;
    };
  };
}
