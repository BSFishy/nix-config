{ ... }:

{
  programs.codiff = {
    enable = true;

    settings = {
      agentBackend = "opencode";
      theme = "system";
      diffStyle = "split";
    };
  };
}
