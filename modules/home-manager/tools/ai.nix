{ inputs, ... }:

let
  opencode = inputs.opencode.packages.default;
in
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
      package = opencode;

      settings = {
        theme = "gruvbox";
        autoshare = false;
        autoupdate = false;
      };
    };

    claude-code = {
      enable = true;
    };
  };
}
