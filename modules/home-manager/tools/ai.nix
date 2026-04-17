{
  config,
  lib,
  pkgs,
  work,
  flakePkgs,
  llmPkgs,
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
  age.secrets.github-mcp-pat.file = ../../../secrets/github-mcp-pat.age;
  programs.zsh.initContent = ''
    export GITHUB_PERSONAL_ACCESS_TOKEN="''$(cat ${config.age.secrets.github-mcp-pat.path})"
  '';

  programs = {
    mcp = {
      enable = true;
      servers = {
        "github" = {
          command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
          args = [ "stdio" ];
        };
        "nixos" = {
          command = "nix";
          args = [
            "run"
            "github:utensils/mcp-nixos"
            "--"
          ];
        };
        "qmd" = {
          command = "${llmPkgs.qmd}/bin/qmd";
          args = [ "mcp" ];
        };
      };
    };

    opencode = {
      enable = true;
      enableMcpIntegration = true;
      rules = builtins.readFile ./AGENTS.md;

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
          webfetch = "ask";
          websearch = "ask";
          codesearch = "ask";
          doom_loop = "ask";

          edit = {
            "*" = "ask";
            "~/notebook/**" = "allow";
          };

          external_directory = {
            "*" = "ask";
            "~/notebook/**" = "allow";
            "~/projects/**" = "allow";
            "~/Projects/**" = "allow";
          };

          bash = {
            "*" = "ask";
            "head*" = "allow";
            "tail*" = "allow";
            "grep*" = "allow";
            "rg*" = "allow";
            "ls*" = "allow";

            "git diff*" = "allow";
            "git log*" = "allow";
            "git status*" = "allow";
            "git branch --show-current" = "allow";

            "glab mr view" = "allow";
            "glab mr diff" = "allow";

            "find*" = "allow";
            "wc*" = "allow";
            "cat*" = "allow";
            "echo*" = "allow";
            "sort*" = "allow";
            "uniq*" = "allow";
          };
        };
      }
      // lib.optionalAttrs (!work) {
        plugin = [
          "opencode-openai-codex-auth"
        ];

        provider = (builtins.fromJSON (builtins.readFile ./opencode-modern.json)).provider;
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
          (builtins.readFile ./opencode-tools/qmd-notes.js);
    };
  };

  home.packages = [
    llmPkgs.qmd
  ];

  xdg.configFile."opencode/plugins/memory.js".source = ./opencode-plugins/memory.js;
  xdg.configFile."opencode/plugins/openpeon.js".text =
    builtins.replaceStrings [ "__OPENPEON_PACK_PATH__" ] [ "${tf2-pyro-pack}" ]
      (builtins.readFile ./opencode-plugins/openpeon.js);
}
