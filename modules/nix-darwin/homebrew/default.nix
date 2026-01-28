_:

{
  homebrew = {
    enable = true;

    global = {
      autoUpdate = false;
      brewfile = true;
      lockfiles = true;
    };

    onActivation = {
      autoUpdate = false;
      cleanup = "none";
    };
  };
}
