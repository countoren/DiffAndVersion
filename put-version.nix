{ version ? "0.0.0"
, build-number ? "0000"
, branch
, pkgs ?  import <nixpkgs>{}
, input
}:
assert pkgs.lib.assertMsg 
  (pkgs.lib.isStorePath "${input}") 
  ''input must be a nix store path or a derivation'';
let
  files-to-replace-version-in = [
    "*.sql"
    "*.fpo"
    "*.asp"
    "*.js"
    "*.css"
    "*.html"
    "*.xml"
    "*.inc"
    "*version.txt"
  ];
in
pkgs.stdenv.mkDerivation rec {
  inherit version;

  name = with pkgs;''${
    lib.getName( 
      lib.concatStringsSep "-" (lib.drop 1 (lib.splitString "-" input))
    )}-${version}_${build-number}'';

    buildInputs = [ 
      pkgs.gnutar
      (import ./replace.nix { inherit pkgs; fail-if-not-found = true; }) 
    ];

  src = input;
  unpackPhase = ''
    echo "input:$src"
    
    mkdir input
    cd input
    cp -va --dereference "$src"/* . || :
    chmod -R +w .
  '';

  buildPhase = ''
    readarray -td "/" pathArr <<< $out && readarray -td "-" nameArr <<< "''${pathArr[-1]}" && outhash="''${nameArr[0]}"
    versionLabel="Version: ${version} - Build: ${build-number} - Branch: ${branch} - Hash: $outhash"
    echo "Adding version to files inside ${input}: ''${versionLabel}"
    find . -type f -not -path '*/.git*' \( ${ 
        pkgs.lib.concatMapStringsSep " -o " (glob: '' -name '${glob}' '') files-to-replace-version-in
        } \) -print0  |
    while IFS= read -r -d "" file; do
          echo "$file" 1>&2
          replace "$file" '__TMVersion__' "$versionLabel" || { 
              echo "ERROR: __TMVersion__ placeholder not found in ''${file}" 1>&2
              exit 1
            }
    done
  '';

  installPhase = ''
    mkdir $out
    cp -av ./* $out/ || :

    tar -cz -f $out/${name}.tar.gz .

    echo "''${versionLabel}" > $out/.version-label
    echo "${version}.${build-number}" > $out/.version
  '';
}
