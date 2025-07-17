{
  config,
  pkgs,
  username,
  ...
}:

let
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  value = builtins.trace "Final home.homeDirectory: ${toString config.home-manager.users.mprovost.home.homeDirectory}" "/Users/mprovost";
in
{
  # set basic home configuration
  home.username = builtins.trace value username;
  home.homeDirectory = builtins.trace "home directory" (
    if isLinux then "/home/${username}" else "/Users/${username}"
  );
}
