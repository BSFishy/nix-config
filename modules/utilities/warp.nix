{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.utilities;
in
{
  config = lib.mkIf cfg.enable { home.packages = [ pkgs.cloudflare-warp ]; };
}
