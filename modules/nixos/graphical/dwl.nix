{
  config,
  pkgs,
  username,
  ...
}:

let
  rofiSource =
    builtins.replaceStrings
      [ "rofi-power" "rofi" ]
      [ "${../../home-manager/graphical/rofi-power.sh}" "${pkgs.rofi}/bin/rofi" ]
      (builtins.readFile ../../home-manager/graphical/rofi.sh);
  rofiLauncher = pkgs.writeShellScriptBin "rofi" rofiSource;
  somebar = (pkgs.somebar.override { conf = ./dwl/somebar-config.hpp; }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./dwl/somebar.patch
      ./dwl/somebar-wayland-version.patch
      ./dwl/somebar-persistent.patch
    ];
  });
  attentionBin = "${config.home-manager.users.${username}.home.profileDirectory}/bin/pi-attention";
  statusScript = pkgs.writeShellScriptBin "dwl-status" (
    builtins.replaceStrings [ "@SOMEBAR@" "@ATTENTION@" ] [ "${somebar}/bin/somebar" attentionBin ] (
      builtins.readFile ./dwl/status.sh
    )
  );
  screenshotScript = pkgs.writeShellScriptBin "dwl-screenshot" (
    builtins.replaceStrings
      [ "@SLURP@" "@GRIM@" "@NOTIFY@" ]
      [ "${pkgs.slurp}/bin/slurp" "${pkgs.grim}/bin/grim" "${pkgs.libnotify}/bin/notify-send" ]
      (builtins.readFile ./dwl/screenshot.sh)
  );
  dwlConfig = pkgs.writeText "dwl-config.h" (
    builtins.replaceStrings
      [ "@ROFI@" "@LOCK@" "@SCREENSHOT@" "@BRIGHTNESS@" ]
      [
        "${rofiLauncher}/bin/rofi"
        "${pkgs.gtklock}/bin/gtklock"
        "${screenshotScript}/bin/dwl-screenshot"
        "${pkgs.brightnessctl}/bin/brightnessctl"
      ]
      (builtins.readFile ./dwl/config.h)
  );
  dwlBase = (pkgs.dwl.override { configH = dwlConfig; }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./dwl/unique-workspaces.patch
      ./dwl/adwaita-cursor.patch
      ./dwl/ghostty-fullscreen.patch
    ];
  });
  dwlBin = pkgs.writeShellScriptBin "dwl" ''
    exec ${dwlBase}/bin/dwl -s ${statusScript}/bin/dwl-status "$@"
  '';
  dwlSession = pkgs.writeShellScriptBin "dwl-session" ''
    set -u
    export XDG_CURRENT_DESKTOP=dwl
    export XDG_SESSION_TYPE=wayland
    export XCURSOR_THEME=Adwaita
    export XCURSOR_SIZE=24
    before_sockets="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' -printf '%f %i\n' 2>/dev/null | sort)"
    ${dwlBin}/bin/dwl "$@" &
    dwl_pid=$!
    trap 'kill "$dwl_pid" 2>/dev/null || true' EXIT INT TERM

    WAYLAND_DISPLAY=""
    for _ in {1..200}; do
      if ! kill -0 "$dwl_pid" 2>/dev/null; then
        wait "$dwl_pid"
        exit $?
      fi
      while read -r socket inode; do
        if ! grep -Fxq "$socket $inode" <<<"$before_sockets"; then
          WAYLAND_DISPLAY="$socket"
          break
        fi
      done < <(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' -printf '%f %i\n' 2>/dev/null | sort)
      [[ -n "$WAYLAND_DISPLAY" ]] && break
      sleep 0.05
    done

    if [[ -z "$WAYLAND_DISPLAY" ]]; then
      printf 'dwl-session: timed out waiting for the Wayland socket\n' >&2
      exit 1
    fi
    export WAYLAND_DISPLAY
    printf 'dwl-session: compositor socket is %s\n' "$WAYLAND_DISPLAY" >&2
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_THEME XCURSOR_SIZE
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XCURSOR_THEME XCURSOR_SIZE
    systemctl --user start dwl-session.target
    systemctl --user reset-failed xdg-desktop-portal-wlr.service || true
    systemctl --user restart xdg-desktop-portal.service
    wait "$dwl_pid"
  '';
  sessionEntry = pkgs.writeTextFile {
    name = "dwl-desktop-entry";
    destination = "/share/wayland-sessions/dwl.desktop";
    text = ''
      [Desktop Entry]
      Name=dwl
      Comment=Dynamic window manager for Wayland
      Exec=${dwlSession}/bin/dwl-session
      TryExec=${dwlBin}/bin/dwl
      Type=Application
      DesktopNames=dwl
    '';
  };
  dwl = pkgs.symlinkJoin {
    name = "dwl";
    paths = [
      dwlBin
      dwlSession
      sessionEntry
    ];
    passthru.providedSessions = [ "dwl" ];
  };
in
{
  services.fprintd.enable = true;
  security.pam.services.gtklock = {
    enable = true;
    fprintAuth = true;
  };

  systemd.user.targets.dwl-session = {
    description = "dwl compositor session";
    documentation = [ "man:systemd.special(7)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  xdg.portal.wlr = {
    enable = true;
    settings.screencast = {
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
    };
  };
  xdg.portal.config.dwl = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.ScreenCast" = "wlr";
    "org.freedesktop.impl.portal.Screenshot" = "wlr";
    "org.freedesktop.impl.portal.Inhibit" = "none";
  };

  services.displayManager.sessionPackages = [ dwl ];

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  environment.systemPackages = [
    dwl
    somebar
    pkgs.gtklock
    pkgs.brightnessctl
    pkgs.grim
    pkgs.slurp
    pkgs.libnotify
    rofiLauncher
  ];

}
