{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.utilities;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  chimera-flake = builtins.getFlake "github:BSFishy/chimera";
in
{
  config = lib.mkIf (cfg.enable && isLinux) {
    home.packages = [
      chimera-flake.packages.${pkgs.system}.default
    ];

    programs.bash.initExtra = ''
      alias chimera="sudo $(which chimera)"
    '';

    programs.zsh.initExtra = ''
      alias chimera="sudo $(which chimera)"
    '';
  };
}
