{ pkgs, ... }:

let
  insert-license = pkgs.writeShellScriptBin "insert-license" (builtins.readFile ./insert-license.sh);
in
{
  home.packages = [
    insert-license
  ];
}
