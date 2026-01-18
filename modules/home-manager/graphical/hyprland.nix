{ lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  rofi-source =
    builtins.replaceStrings [ "rofi-power" "rofi" ] [ "${./rofi-power.sh}" "${pkgs.rofi}/bin/rofi" ]
      (builtins.readFile ./rofi.sh);
  rofi = pkgs.writeShellScriptBin "rofi" rofi-source;
in
{
  config = lib.mkIf isLinux {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        env = [
          "HYPRCURSOR_THEME,Adwaita"
          "HYPRCURSOR_SIZE,24"
          "XCURSOR_THEME,Adwaita"
          "XCURSOR_SIZE,24"
        ];

        input = {
          sensitivity = 0.0;
          accel_profile = "flat";
          follow_mouse = 2;
        };

        monitor = [
          "eDP-1,preferred,auto,1"
        ];

        windowrulev2 = [
          "workspace 9, class:^(com\\.mitchellh\\.ghostty)$"
        ];

        workspace = [
          "9, monitor:DP-11, default:true"
        ];

        "$mainMod" = "CTRL";

        bind = [
          "$mainMod,Space,exec,${rofi}/bin/rofi"

          # control + shift + &
          # NOTE: no workspace 7 because of this
          "$mainMod SHIFT,7,closewindow,activewindow"

          "ALT SHIFT,H,movewindow,l"
          "ALT SHIFT,L,movewindow,r"
          "ALT SHIFT,K,movewindow,u"
          "ALT SHIFT,J,movewindow,d"

          "ALT,H,movefocus,l"
          "ALT,L,movefocus,r"
          "ALT,K,movefocus,u"
          "ALT,J,movefocus,d"

          "$mainMod,Tab,focusmonitor,+1"
          "$mainMod SHIFT,Tab,focusmonitor,-1"

          "$mainMod,1,workspace,1"
          "$mainMod,2,workspace,2"
          "$mainMod,3,workspace,3"
          "$mainMod,4,workspace,4"
          "$mainMod,5,workspace,5"
          "$mainMod,6,workspace,6"
          "$mainMod,8,workspace,8"
          "$mainMod,9,workspace,9"

          "$mainMod SHIFT,1,movetoworkspace,1"
          "$mainMod SHIFT,2,movetoworkspace,2"
          "$mainMod SHIFT,3,movetoworkspace,3"
          "$mainMod SHIFT,4,movetoworkspace,4"
          "$mainMod SHIFT,5,movetoworkspace,5"
          "$mainMod SHIFT,6,movetoworkspace,6"
          "$mainMod SHIFT,8,movetoworkspace,8"
          "$mainMod SHIFT,9,movetoworkspace,9"
        ];
      };
    };
  };
}
