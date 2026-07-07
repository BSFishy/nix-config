{
  config,
  lib,
  pkgs,
  work,
  ...
}:

let
  tf2-pyro-pack = pkgs.fetchFromGitHub {
    owner = "thebreadcat";
    repo = "tf2-pyro-pack";
    rev = "ef318365121da7c4ba870c8419437d681430a9d0";
    hash = "sha256-R30ri29DnolWWLvt1m6deX40ZLQ4+eDTNPRuzK+iVWA=";
  };
in
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    rules = builtins.readFile ../AGENTS.md;

    tui.theme = "gruvbox";

    settings = {
      autoshare = false;
      autoupdate = false;

      permission = {
        read = "allow";
        glob = "allow";
        grep = "allow";
        list = "allow";
        task = "allow";
        skill = "allow";
        lsp = "allow";
        todoread = "allow";
        todowrite = "allow";
        webfetch = "allow";
        websearch = "allow";
        codesearch = "allow";
        doom_loop = "ask";
        edit = "allow";

        external_directory = {
          "*" = "ask";
          "~/notebook/**" = "allow";
          "~/projects/**" = "allow";
          "~/Projects/**" = "allow";
        };

        bash = {
          "*" = "allow";
          "rm*" = "ask";
          "git push*" = "ask";
          "git commit*" = "ask";
        };
      };
    }
    // lib.optionalAttrs (!work) {
      plugin = [
        "opencode-openai-codex-auth"
      ];

      provider = (builtins.fromJSON (builtins.readFile ../opencode-modern.json)).provider;
    }
    // lib.optionalAttrs work {
      plugin = [
        "opencode-wakelock"
      ];
    };

    tools.qmd-notes =
      builtins.replaceStrings
        [ "@opencode-ai/plugin" ]
        [ "${config.xdg.configHome}/opencode/node_modules/@opencode-ai/plugin/dist/index.js" ]
        (builtins.readFile ../opencode-tools/qmd-notes.js);
  };

  xdg.configFile."opencode/plugins/memory.js".source = ../opencode-plugins/memory.js;
  xdg.configFile."opencode/plugins/openpeon.js".text =
    builtins.replaceStrings [ "__OPENPEON_PACK_PATH__" ] [ "${tf2-pyro-pack}" ]
      (builtins.readFile ../opencode-plugins/openpeon.js);
}
