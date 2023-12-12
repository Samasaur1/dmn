{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.dmn;
in

{
  options.services.dmn = {
    enable = mkEnableOption "dmn";
  };
  config = {
  };
}
