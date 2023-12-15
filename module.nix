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
      default = [];
    };
    ignoreUserCommandsFile = mkOption {
      type = types.bool;
      default = true;
    };
  };
  config = mkIf cfg.enable {
    launchd.user.agents.dmn.serviceConfig = {
      Label = "com.gauck.sam.dmn";
      KeepAlive = true;
      ProgramArguments =
        let
          file = pkgs.writeText "dmn-commands.json" (builtins.toJSON cfg.commands);
          package = pkgs.callPackage ./. {};
        in
        [
          "${package}/bin/dmn"
          "--extra-commands-file"
          "${file}"
        ] ++ lib.optionals cfg.ignoreUserCommandsFile [ "--ignore-user-commands-file" ];
      # Theoretically you can view logs directly with
      # `sudo launchctl debug <service> --stdout --stderr`
      # As is typical for launchd, this has never worked for me,
      # so possibly include an option to enable log files in the future?
      # Or just expect people to set
      # `launchd.user.agents.dmn.serviceConfig.StandardOutPath = "/tmp/out";`
      # on their own.
      # StandardOutPath = "/tmp/nix-dmn-stdout.log";
      # StandardErrorPath = "/tmp/nix-dmn-stderr.log";
    };
  };
}
