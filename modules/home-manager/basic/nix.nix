{ ... }:

{
  programs.nh = {
    enable = true;
  };

  programs.zsh.initContent = ''
    eval "$(nh completions zsh)"
  '';
}
