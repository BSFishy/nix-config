{ work, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Matt Provost";
    userEmail = if work then "mprovost@cloudflare.com" else "mattprovost6@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";

      # merge tool
      merge.tool = "nvimdiff";
      mergetool.nvimdiff.cmd = ''nvim -d "$LOCAL" "$REMOTE" "$MERGED"'';
      mergetool.prompt = false;
    };
  };
}
