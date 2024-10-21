{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dmn;
in

{
  options.services.dmn = {
    enable = mkEnableOption "dmn";
    commands = mkOption {
      type = with types; listOf (submodule {
        options = {
          executable = mkOption {
            type = str;
          };
          arguments = mkOption {
            type = listOf str;
          };
        };
      });
    };
  };
  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "targets.darwin.defaults" pkgs platforms.darwin)
    ];
    launchd.agents.dmn = {
      enable = true;
      config = {
        Label = "com.gauck.sam.dmn";
        KeepAlive = true;
        ProgramArguments =
          let
            package = pkgs.callPackage ./. {};
          in
          [
            "/bin/sh"
            "-c"
            "/bin/wait4path /nix/store &amp;&amp; exec ${package}/bin/dmn"
          ];
        # Theoretically you can view logs directly with
        # `sudo launchctl debug <service> --stdout --stderr`
        # As is typical for launchd, this has never worked for me,
        # so possibly include an option to enable log files in the future?
        # Or just expect people to set
        # `launchd.agents.dmn.config.StandardOutPath = "/tmp/out";`
        # on their own.
        # StandardOutPath = "/tmp/nix-dmn-stdout.log";
        # StandardErrorPath = "/tmp/nix-dmn-stderr.log";
      };
    };
    xdg.configFile."dmn/commands.json".text = (builtins.toJSON cfg.commands);
  };
}
