{ config, lib, pkgs, work, ... }:

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
          args = [ "run" "github:utensils/mcp-nixos" "--" ];
        };
      };
    };

    opencode = {
      enable = true;
      enableMcpIntegration = true;
      rules = builtins.readFile ./AGENTS.md;
      settings = {
        theme = "gruvbox";
        autoshare = false;
        autoupdate = false;

        permission = {
          read = "allow";
          edit = "ask";
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
          external_directory = "ask";
          doom_loop = "ask";

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
            "find*" = "allow";
            "wc*" = "allow";
            "cat*" = "allow";
            "echo*" = "allow";
            "sort*" = "allow";
          };
        };
      } // lib.optionalAttrs (!work) {
        plugin = [
          "opencode-openai-codex-auth"
          "opencode-agent-memory"
        ];

        provider = (builtins.fromJSON (builtins.readFile ./opencode-modern.json)).provider;
      } // lib.optionalAttrs work {
        plugins = [
          "opencode-wakelock"
        ];
      };
    };
  };

  xdg.configFile."opencode/agent-memory.json".source = ./agent-memory.json;
}
