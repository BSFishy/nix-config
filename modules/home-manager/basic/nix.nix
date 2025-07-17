{ ... }:

{
  programs.nh = {
    enable = true;
  };

  programs.zsh.initExtra = ''
    eval "$(nh completions --shell zsh)"
  '';
}
