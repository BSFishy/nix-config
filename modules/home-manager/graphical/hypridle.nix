{ lib, pkgs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
in
{
  config = lib.mkIf isLinux {
    services.hypridle = {
      enable = true;

      settings = {
        general = {
          # prevent startin multiple hyprlock instances
          lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";

          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };

        listener = [
          # dim screen after 2.5min
          {
            timeout = 150;
            on-timeout = "bightnessctl -s set 10";
            on-resume = "bightnessctl -r";
          }

          # dim keyboard backlight after 2.5min
          {
            timeout = 150;
            on-timeout = "bightnessctl -sd rgb:kbd_backlight set 0";
            on-resume = "brightnessctl -rd rgb:kbd_backlight";
          }

          # lock screen after 5min
          {
            timeout = 300;
            on-timeout = "loginctl lock-session";
          }

          # turn screen off after 5.5min
          {
            timeout = 330;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
          }

          # suspend pc after 30min
          {
            timeout = 1800;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
