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
    context = builtins.readFile ../AGENTS.md;

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
          "~/.cargo/registry/**" = "allow";
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
    };
  };

  xdg.configFile."opencode/skills/documentation".source = ./skills/documentation;
  xdg.configFile."opencode/skills/command-not-found".source = ./skills/command-not-found;
  xdg.configFile."opencode/skills/ship".source = ./skills/ship;
  xdg.configFile."opencode/skills/fetch-project".source = ./skills/fetch-project;
  xdg.configFile."opencode/skills/open-code-review-delegate".source =
    ./skills/open-code-review-delegate;
  xdg.configFile."opencode/skills/stateful-k8s-recovery".source = ./skills/stateful-k8s-recovery;
  xdg.configFile."opencode/commands/catalog.md".source = ./commands/catalog.md;
  xdg.configFile."opencode/commands/learn.md".source = ./commands/learn.md;
  xdg.configFile."opencode/commands/rebase-base.md".source = ./commands/rebase-base.md;
  xdg.configFile."opencode/commands/ship.md".source = ./commands/ship.md;
  xdg.configFile."opencode/plugins/docs.js".source = ../opencode-plugins/docs.js;
  xdg.configFile."opencode/plugins/openpeon.js".text =
    builtins.replaceStrings [ "__OPENPEON_PACK_PATH__" ] [ "${tf2-pyro-pack}" ]
      (builtins.readFile ../opencode-plugins/openpeon.js);
}
