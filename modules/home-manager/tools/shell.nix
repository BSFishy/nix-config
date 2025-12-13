{ ... }:

{
  programs.zsh.initContent = ''
    source ${./number-utilities.sh}
  '';
}
