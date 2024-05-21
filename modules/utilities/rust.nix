{ config, lib, pkgs, ... }:

let
  cfg = config.distro.utilities;
in
{
  options.distro.utilities.rust = {
    enable = lib.mkEnableOption "rust";
  };

  config = lib.mkIf (cfg.enable && cfg.rust.enable) {
    home.packages = [ pkgs.rustup ];
  };
}
