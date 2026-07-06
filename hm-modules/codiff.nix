{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.codiff;
  jsonFormat = pkgs.formats.json { };
in
{
  options.programs.codiff = {
    enable = lib.mkEnableOption "codiff, a fast local diff viewer";

    package = lib.mkPackageOption pkgs "codiff" { };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Settings for codiff. These are placed under the `settings` key
        in `~/.codiff/codiff.jsonc`.

        See <https://github.com/nkzw-tech/codiff> for available options.
      '';
      example = lib.literalExpression ''
        {
          agentBackend = "opencode";
          theme = "dark";
          diffStyle = "unified";
          codeFontSize = 14;
        }
      '';
    };

    keymap = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = ''
        Keymap overrides for codiff. These are placed under the `keymap`
        key in `~/.codiff/codiff.jsonc`.
      '';
      example = lib.literalExpression ''
        {
          nextHunk = [ "Ctrl+ArrowDown" "j" ];
          prevHunk = [ "Ctrl+ArrowUp" "k" ];
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".codiff/codiff.jsonc" = lib.mkIf (cfg.settings != { } || cfg.keymap != { }) {
      source = jsonFormat.generate "codiff-config.json" (
        lib.filterAttrs (_: v: v != { }) {
          settings = cfg.settings;
          keymap = cfg.keymap;
        }
      );
    };
  };
}
