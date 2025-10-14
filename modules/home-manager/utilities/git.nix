{ pkgs, work, ... }:

let
  difftastic = pkgs.difftastic;
  delta = pkgs.delta;

  delta-git = builtins.fetchGit {
    url = "https://github.com/dandavison/delta.git";
    rev = "c22adcea90a5f3de2419a058fb92f1ced2a9fd10";
  };
in
{
  home.packages = [
    difftastic
    delta
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Matt Provost";
    userEmail = if work then "mprovost@cloudflare.com" else "mattprovost6@gmail.com";

    includes = [
      { path = "${delta-git}/themes.gitconfig"; }
    ];

    extraConfig = {
      init.defaultBranch = "main";
      core.autocrlf = "input";

      # aliases
      alias = {
        dft = "-c diff.external=${difftastic}/bin/difft diff";
      };

      # pager
      pager =
        let
          delta-bin = "${delta}/bin/delta";
        in
        {
          diff = delta-bin;
          show = delta-bin;
          log = delta-bin;
        };

      # delta diff tool
      delta = {
        side-by-side = true;
        line-numbers = true;
        # syntax-theme = "gruvmax-fang";
      };

      # merge tool
      merge.tool = "nvimdiff";
      mergetool.prompt = false;
    };
  };
}
