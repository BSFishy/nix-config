{
  inputs,
  pkgs,
  system,
  ...
}:

{
  system.defaults = {
    dock = {
      # Hide Dock automatically
      autohide = true;

      # Optional. Remove Dock delay and animation.
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;

      # Optional. Make Dock invisible when shown.
      show-recents = false;
      tilesize = 1;
    };

    # Hide menu bar automatically
    NSGlobalDomain._HIHideMenuBar = true;
  };

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  launchd.user.agents.mofi = {
    serviceConfig = {
      Label = "com.user.mofi";
      ProgramArguments = [
        "${inputs.mofi.packages.${system}.default}/Applications/mofi.app/Contents/MacOS/mofi"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  services.sketchybar = {
    enable = true;

    config = ''
      # DEFAULT SETTINGS

      FONT="JetBrainsMono Nerd Font"

      defaults=(
        icon.font="$FONT:Bold:14.0"
        icon.color=0xffebdbb2
        label.font="$FONT:Semibold:13.0"
        label.color=0xffebdbb2
      )

      sketchybar --default "''${defaults[@]}"

      sketchybar --bar position=top height=32 blur_radius=30 color=0xa0282828

      # CLOCK

      sketchybar --add item clock right \
        --set clock \
        update_freq=1 \
        icon= \
        icon.color=0xffd79921 \
        icon.padding_right=5 \
        script="${./plugins/clock.sh}"

      sketchybar --add item date right \
        --set date \
        update_freq=15 \
        background.padding_right=10 \
        icon=󰃭 \
        icon.color=0xffd65d0e \
        icon.padding_right=5 \
        script="${./plugins/date.sh}"

      # AEROSPACE

      sketchybar --add event aerospace_workspace_change \
                --add event window_focus

      sketchybar --add item workspace left \
        --subscribe workspace aerospace_workspace_change window_focus \
        --set workspace \
        background.drawing=on \
        background.color=0xA0458588 \
        background.corner_radius=5 \
        background.height=20 \
        background.padding_right=5 \
        background.padding_left=5 \
        label.padding_left=5 \
        label.padding_right=5 \
        script="${./plugins/aerospace.sh}"

      # FINISHED

      sketchybar --update
      echo "sketchybar config loaded..."
    '';
  };

  services.aerospace = {
    enable = true;

    settings = {
      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "${pkgs.sketchybar}/bin/sketchybar --trigger aerospace_workspace_change AEROSPACE_FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE AEROSPACE_PREV_WORKSPACE=$AEROSPACE_PREV_WORKSPACE"
      ];

      on-window-detected = [
        # always move ghostty to workspace 9
        {
          check-further-callbacks = false;
          "if" = {
            app-id = "com.mitchellh.ghostty";
          };
          run = [
            "move-node-to-workspace 9"
          ];
        }
      ];

      workspace-to-monitor-force-assignment = {
        # keep ghostty workspace on the second monitor if it exists
        "9" = "secondary";
      };

      gaps = {
        outer = {
          left = 8;
          bottom = 8;
          top = 8;
          right = 8;
        };
      };

      mode.main.binding = {
        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        ctrl-1 = "workspace 1";
        ctrl-2 = "workspace 2";
        ctrl-3 = "workspace 3";
        ctrl-4 = "workspace 4";
        ctrl-5 = "workspace 5";
        ctrl-6 = "workspace 6";
        ctrl-7 = "workspace 7";
        ctrl-8 = "workspace 8";
        ctrl-9 = "workspace 9";

        ctrl-shift-1 = "move-node-to-workspace 1";
        ctrl-shift-2 = "move-node-to-workspace 2";
        ctrl-shift-3 = "move-node-to-workspace 3";
        ctrl-shift-4 = "move-node-to-workspace 4";
        ctrl-shift-5 = "move-node-to-workspace 5";
        ctrl-shift-6 = "move-node-to-workspace 6";
        ctrl-shift-7 = "move-node-to-workspace 7";
        ctrl-shift-8 = "move-node-to-workspace 8";
        ctrl-shift-9 = "move-node-to-workspace 9";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        ctrl-tab = "focus-monitor --wrap-around next";
        ctrl-shift-tab = "focus-monitor --wrap-around prev";
      };
    };
  };
}
