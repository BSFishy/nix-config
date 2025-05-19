{ ... }:

{
  # set basic home configuration
  home.username = "mprovost";
  home.homeDirectory = "/home/mprovost";

  # set home manager state version
  home.stateVersion = "24.11";

  # allow home manager to manage itself
  programs.home-manager.enable = true;
}
