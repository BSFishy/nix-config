{ pkgs, ... }:

let
  incus-connect = pkgs.writeShellScriptBin "incus-connect" (builtins.readFile ./incus-connect.sh);
in
{
  virtualisation.incus.enable = true;

  environment.defaultPackages = [
    incus-connect
  ];
}
