{ inputs, pkgs, ... }:

{
  environment.systemPackages = [
    inputs.wlctl.packages.${pkgs.stdenv.system}.wlctl
    pkgs.bluetui
  ];
}
