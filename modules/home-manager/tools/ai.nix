{ ... }:

{
  programs.codex = {
    enable = true;
    settings = {
      tools.web_search = true;
    };
  };

  programs.opencode = {
    enable = true;
    settings = {
      theme = "gruvbox";
      autoshare = false;
      autoupdate = false;
    };
  };

  programs.claude-code = {
    enable = true;
  };
}
