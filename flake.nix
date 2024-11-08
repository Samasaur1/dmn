{
  description = "Run arbitrary commands on system theme changes.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = gen:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
        (system: gen nixpkgs.legacyPackages.${system});
    in {
      packages = forAllSystems (pkgs: { default = pkgs.callPackage ./. { }; });

      homeManagerModules.default = import ./module.nix;
    };
}
