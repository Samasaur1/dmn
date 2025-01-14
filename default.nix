{ lib, swiftPackages, swift, swiftpm, swiftpm2nix, ... }:

let
  # Pass the generated files to the helper.
  generated = swiftpm2nix.helpers ./nix;
in

swiftPackages.stdenv.mkDerivation {
  pname = "dmn";
  version = "1.3.0";

  src = ./.;

  # Including SwiftPM as a nativeBuildInput provides a buildPhase for you.
  # This by default performs a release build using SwiftPM, essentially:
  #   swift build -c release
  nativeBuildInputs = [ swift swiftpm ];

  # The helper provides a configure snippet that will prepare all dependencies
  # in the correct place, where SwiftPM expects them.
  configurePhase = generated.configure;

  installPhase = ''
    # This is a special function that invokes swiftpm to find the location
    # of the binaries it produced.
    binPath="$(swiftpmBinPath)"
    # Now perform any installation steps.
    mkdir -p $out/bin
    cp $binPath/dmn $out/bin/
    cp $binPath/current $out/bin/
  '';
  
  meta = with lib; {
    description = "run arbitrary commands on system theme changes";
    homepage = "https://github.com/Samasaur1/dmn";
    platforms = platforms.darwin;
  };
}
