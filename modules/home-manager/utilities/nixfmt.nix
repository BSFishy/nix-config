{
  pkgs,
  ...
}:

{
  home.packages = [
    pkgs.nixfmt
    pkgs.statix
  ];
}
