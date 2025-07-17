{ pkgs, username, ... }:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  # set basic home configuration
  home.username = username;
  home.homeDirectory = if isLinux then "/home/${username}" else "/Users/${username}";
}
