{ config, lib, ... }:

let
  cfg = config.distro.utilities;
in
{
  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;

      nix-direnv.enable = true;
    };
  };
}
