{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.ui;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      # Supporting packages
      pkgs.clipse # Clipboad manager
      pkgs.wl-clipboard

      # Screencast support
      pkgs.pipewire
      pkgs.wireplumber
    ];

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;

      extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

      config.common.default = [ "hyprland" ];
    };

    wayland.windowManager.hyprland = {
      enable = true;

      systemd.enableXdgAutostart = true;

      settings = {
        # TODO: make this configurable?
        monitor = [ ",highres,auto,1" ];

        "$terminal" = "${pkgs.wezterm}/bin/wezterm start --always-new-process";
        "$browser" = "${pkgs.google-chrome}/bin/google-chrome-stable";

        exec-once = [
          "${pkgs.clipse}/bin/clispe -listen"
          "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "${pkgs.waybar}/bin/waybar"
        ];

        env = [
          "XCURSOR_SIZE,24"
          "XCURSOR_THEME,Vanilla-DMZ"
          "HYPRCURSOR_SIZE,24"
          "HYPRCURSOR_THEME,Vanilla-DMZ"
          "GDK_SCALE,1"
          "GDK_DPI_SCALE,1"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 20;

          border_size = 2;

          "col.active_border" = "rgba(458588ee) rgba(98971aee) 45deg";
          "col.inactive_border" = "rgba(928374aa)";

          resize_on_border = false;

          allow_tearing = false;

          layout = "dwindle";
        };

        decoration = {
          rounding = 18;

          active_opacity = 1.0;
          inactive_opacity = 1.0;

          drop_shadow = true;
          shadow_range = 4;
          shadow_render_power = 3;
          "col.shadow" = "rgba(282828ee)";

          blur = {
            enabled = true;
            size = 3;
            passes = 1;

            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = true;

          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        misc = {
          disable_hyprland_logo = true;
        };

        xwayland = {
          force_zero_scaling = true;
        };

        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";

          follow_mouse = 1;

          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

          touchpad = {
            natural_scroll = false;
          };
        };

        gestures = {
          workspace_swipe = false;
        };

        # See https://wiki.hyprland.org/Configuring/Keywords/
        "$mainMod" = "SUPER"; # Sets "Windows" key as main modifier

        bind = [
          # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
          "$mainMod, Q, exec, [float;tile] $terminal"
          "$mainMod, C, killactive,"
          "$mainMod, M, exit,"
          # "$mainMod, E, exec, $fileManager"
          "$mainMod, V, togglefloating,"
          # "$mainMod, R, exec, $menu"
          "$mainMod, B, exec, $browser"
          "$mainMod, P, pseudo," # dwindle
          "$mainMod, J, togglesplit," # dwindle

          # Move focus with mainMod + arrow keys
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"

          # Switch workspaces with mainMod + [0-9]
          "$mainMod, 1, workspace, 1"
          "$mainMod, 2, workspace, 2"
          "$mainMod, 3, workspace, 3"
          "$mainMod, 4, workspace, 4"
          "$mainMod, 5, workspace, 5"
          "$mainMod, 6, workspace, 6"
          "$mainMod, 7, workspace, 7"
          "$mainMod, 8, workspace, 8"
          "$mainMod, 9, workspace, 9"
          "$mainMod, 0, workspace, 10"

          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$mainMod SHIFT, 1, movetoworkspace, 1"
          "$mainMod SHIFT, 2, movetoworkspace, 2"
          "$mainMod SHIFT, 3, movetoworkspace, 3"
          "$mainMod SHIFT, 4, movetoworkspace, 4"
          "$mainMod SHIFT, 5, movetoworkspace, 5"
          "$mainMod SHIFT, 6, movetoworkspace, 6"
          "$mainMod SHIFT, 7, movetoworkspace, 7"
          "$mainMod SHIFT, 8, movetoworkspace, 8"
          "$mainMod SHIFT, 9, movetoworkspace, 9"
          "$mainMod SHIFT, 0, movetoworkspace, 10"

          # Example special workspace (scratchpad)
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"

          # Scroll through existing workspaces with mainMod + scroll
          "$mainMod, mouse_down, workspace, e+1"
          "$mainMod, mouse_up, workspace, e-1"
        ];

        # Move/resize windows with mainMod + LMB/RMB and dragging
        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];

        windowrulev2 = "suppressevent maximize, class:.*"; # You'll probably like this.
      };
    };
  };
}
