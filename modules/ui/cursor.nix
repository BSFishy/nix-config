{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.ui;

  package = pkgs.vanilla-dmz;
  name = "Vanilla-DMZ";
  size = 24;
in
{
  config = lib.mkIf cfg.enable {
    home.pointerCursor = {
      package = package;
      name = name;
      size = size;

      gtk.enable = true;
      x11 = {
        enable = true;
        defaultCursor = name;
      };
    };

    gtk.cursorTheme = {
      package = package;
      name = name;
      size = size;
    };

    xresources.properties = {
      "Xcursor.theme" = name;
      "Xcursor.size" = size;
    };
  };
}
