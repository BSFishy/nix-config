{
  config,
  lib,
  pkgs,
  chimera-flake,
  ...
}:

let
  cfg = config.distro.utilities;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  pkg = chimera-flake.packages.${pkgs.system}.default;
in
{
  config = lib.mkIf (cfg.enable && isLinux) {
    home.packages = [
      pkg
    ];

    programs.bash.initExtra = ''
      alias chimera="sudo ${pkg}/bin/chimera"
    '';

    programs.zsh.initExtra = ''
      alias chimera="sudo ${pkg}/bin/chimera"
    '';
  };
}
