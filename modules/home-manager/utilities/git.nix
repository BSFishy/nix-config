{ ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Matt Provost";
    userEmail = "mattprovost6@gmail.com";

    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
