{
  config,
  pkgs,
  llmPkgs,
  flakePkgs,
  ...
}:

{
  imports = [
    ./opencode.nix
    ./pi.nix
  ];

  age.secrets.github-mcp-pat.file = ../../../../secrets/github-mcp-pat.age;

  programs.zsh.initContent = ''
    export GITHUB_PERSONAL_ACCESS_TOKEN="''$(cat ${config.age.secrets.github-mcp-pat.path})"
  '';

  programs.mcp = {
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

  home.packages = [
    llmPkgs.qmd
    flakePkgs.open-code-review
  ];
}
