{ inputs, pkgs, ... }:

{
  programs.ags = {
    enable = true;

    configDir = ./ags;

    extraPackages = [
      inputs.astal.packages.${pkgs.stdenv.system}.battery
      inputs.astal.packages.${pkgs.stdenv.system}.powerprofiles
    ];
  };
}
