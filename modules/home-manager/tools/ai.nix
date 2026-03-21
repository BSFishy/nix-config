{ lib, work, ... }:

{
  programs.opencode = {
    enable = true;
    rules = builtins.readFile ./AGENTS.md;
    settings = {
      theme = "gruvbox";
      autoshare = false;
      autoupdate = false;

      permission = {
        bash = {
          "head*" = "allow";
          "tail*" = "allow";
          "grep*" = "allow";
          "rg*" = "allow";
          "ls*" = "allow";
          "git diff*" = "allow";
          "git log*" = "allow";
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
      ];

      provider = (builtins.fromJSON (builtins.readFile ./opencode-modern.json)).provider;
    };
  };
}
