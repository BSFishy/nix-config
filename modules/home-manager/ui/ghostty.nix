{
  config,
  lib,
  pkgs,
  ...
}:

let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  config = lib.mkIf (!isDarwin) {
    programs.ghostty = {
      enable = true;

      package = config.lib.nixGL.wrap pkgs.ghostty;

      settings = {
        theme = "GruvboxDark";
        font-size = 13;
        adjust-font-baseline = "20%";
      };
    };
  };
}
