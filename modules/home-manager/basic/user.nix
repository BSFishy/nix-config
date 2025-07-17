{ pkgs, username, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  # set basic home configuration
  home.username = username;
  home.homeDirectory = builtins.trace "home directory" (
    if isLinux then "/home/${username}" else "/Users/${username}"
  );
}
