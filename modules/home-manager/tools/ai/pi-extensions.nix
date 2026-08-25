{ lib, pkgs, ... }:

{
  home.file.".pi/agent/extensions/verification.ts".source = ./extensions/verification.ts;
}
