{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.distro.utilities;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
  chimeraFlake = import (
    builtins.fetchGit {
      url = "https://github.com/BSFishy/chimera.git";
      ref = "main";
      rev = "dc8588bccb7a2f77bac4172d095acbc0d2dde15a";
    }
  );
in
{
  config = lib.mkIf (cfg.enable && isLinux) {
    home.packages = [
      chimeraFlake.packages.${pkgs.system}.default
    ];

    programs.bash.initExtra = ''
      alias chimera="sudo $(which chimera)"
    '';

    programs.zsh.initExtra = ''
      alias chimera="sudo $(which chimera)"
    '';
  };
}
