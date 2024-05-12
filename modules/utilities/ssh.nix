{ config, lib, ... }:

let
  cfg = config.distro.utilities;
in
{
  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
    };
  };
}
