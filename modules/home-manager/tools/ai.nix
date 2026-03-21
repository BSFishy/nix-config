_:

{
  programs = {
    codex = {
      enable = true;
      settings = {
        check_for_update_on_startup = false;

        features = {
          web_search_request = true;
          tui2 = true;
        };

        projects."*".trust_level = "trusted";
      };
    };

    opencode = {
      enable = true;
      rules = builtins.readFile ./AGENTS.md;
      settings = {
        theme = "gruvbox";
        autoshare = false;
        autoupdate = false;

        permissions = {
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
      };
    };

    claude-code = {
      enable = true;
    };
  };
}
