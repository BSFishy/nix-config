{ pkgs, config, ... }:

let
nixGL = import ./nixGL.nix { inherit pkgs config; };
in {
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;

    package = (nixGL pkgs.wezterm);

    extraConfig = builtins.readFile ./wezterm.lua;
  };
}
