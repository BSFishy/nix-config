{ config, lib, ... }:

let
  cfg = config.distro.utilities;
in
{
  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;

      userName = "Matt Provost";
      userEmail = "mattprovost6@gmail.com";
    };
  };
}
