{ pkgs, ... }:

let
  switch-shell = pkgs.writeShellScriptBin "switch-shell" (builtins.readFile ./switch-shell.sh);
in
{
  home.packages = [
    switch-shell
  ];
}
