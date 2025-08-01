{ work, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Matt Provost";
    userEmail = if work then "mprovost@cloudflare.com" else "mattprovost6@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
