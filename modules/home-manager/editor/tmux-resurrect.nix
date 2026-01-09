{ pkgs }:

pkgs.tmuxPlugins.mkTmuxPlugin {
  pluginName = "resurrect";
  version = "unstable-2022-05-01";

  src = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tmux-resurrect";
    rev = "cff343cf9e81983d3da0c8562b01616f12e8d548";
    hash = "sha256-wl9/5XvFq+AjV8CwYgIZjPOE0/kIuEYBNQqNDidjNFo=";
    fetchSubmodules = true;
  };

  patches = [
    ./folke-persistence.diff
  ];
}
