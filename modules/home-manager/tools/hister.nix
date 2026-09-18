{
  config,
  lib,
  pkgs,
  ...
}:

let
  histerWithAccessToken = pkgs.writeShellApplication {
    name = "hister";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      HISTER__APP__ACCESS_TOKEN="$(cat "${config.age.secrets.hister-access-token.path}")"
      export HISTER__APP__ACCESS_TOKEN
      exec ${pkgs.hister}/bin/hister "$@"
    '';
  };
in
{
  age.secrets.hister-access-token.file = ../../../secrets/hister-access-token.age;

  home.packages = [ histerWithAccessToken ];

  xdg.configFile = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
    "hister/config.yml".source = ./hister.yml;
  };

  home.file = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    "Library/Preferences/hister/config.yml".source = ./hister.yml;
  };
}
