{ pkgs ? import <nixpkgs> {}
  ,after
  ,before
}:
pkgs.stdenv.mkDerivation {
  name = with pkgs;''${lib.concatStringsSep "-" (lib.drop 1 (lib.splitString "-" after))}-changed'';
  buildInputs = [ pkgs.rsync ];
  buildPhase = ''
			echo "BEFORE: ${before}" 1>&2
			echo "AFTER:  ${after}" 1>&2
    '';
  installPhase = ''
    mkdir -p $out
    rsync -L --recursive --checksum --prune-empty-dirs --quiet --compare-dest="${before}"/ "${after}"/ $out/
  '';
  phases = [ "buildPhase" "installPhase" ];
}
