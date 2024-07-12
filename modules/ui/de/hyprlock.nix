{ config, lib, ... }:

let
  cfg = config.distro.ui;
in
{
  config = lib.mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;

      settings = {
        general = {
          immediate_render = true;
        };

        background = [
          {
            path = "${./wallpaper.jpeg}";
            color = "rgba(152, 151, 26, 1.0)";

            # Taken from Hyprland wiki
            blur_passes = 1;
            blur_size = 7;
            noise = 1.17e-2;
            contrast = 0.8916;
            brightness = 0.8172;
            vibrancy = 0.1696;
            vibrancy_darkness = 0.0;
          }
        ];

        input-field = [
          {
            size = "200, 40";
            outline_thickness = 2;
            dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
            dots_spacing = 0.15; # Scale of dots' absolute size, 0.0 - 1.0
            dots_center = false;
            dots_rounding = -1; # -1 default circle, -2 follow input-field rounding
            outer_color = "rgba(282828b3)";
            inner_color = "rgba(928374b3)";
            font_color = "rgb(ebdbb2)";
            fade_on_empty = false;
            fade_timeout = 1000; # Milliseconds before fade_on_empty is triggered.
            placeholder_text = "Password..."; # Text rendered in the input box when it's empty.
            hide_input = false;
            rounding = -1; # -1 means complete rounding (circle/oval)
            check_color = "rgb(d65d0e)";
            fail_color = "rgb(cc241d)"; # if authentication failed, changes outer_color and fail message color
            fail_text = "$FAIL <b>($ATTEMPTS)</b>"; # can be set to empty
            fail_timeout = 2000; # milliseconds before fail_text and fail_color disappears
            fail_transition = 300; # transition time in ms between normal outer_color and fail_color
            capslock_color = -1;
            numlock_color = -1;
            bothlock_color = -1; # when both locks are active. -1 means don't change outer color (same for above)
            invert_numlock = false; # change color if numlock is off
            swap_font_color = false; # see below

            position = "0, -20";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
