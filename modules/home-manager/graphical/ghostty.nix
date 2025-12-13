{
  config,
  pkgs,
  ...
}:

let
  # allow ghostty to be configured on darwin but dont actually install the
  # package while it's broken
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  pkg = if isDarwin then pkgs.ghostty-bin else config.lib.nixGL.wrap pkgs.ghostty;
in
{
  programs.ghostty = {
    enable = true;

    package = pkg;

    settings = {
      theme = "Gruvbox Dark";
      font-size = 13;
      adjust-font-baseline = "20%";
    };
  };
}
