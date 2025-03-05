{
  config,
  pkgs,
  ...
}:

{
  # wezterm uses jetbrains mono, so let's make sure it's installed
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  programs.wezterm = {
    enable = true;

    package = config.lib.nixGL.wrap pkgs.wezterm;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
}
