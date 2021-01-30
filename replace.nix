{
  pkgs ? import <nixpkgs> {}
, fail-if-not-found ? true
}:
pkgs.writeShellScriptBin "replace"
  ''
    ${pkgs.gnused}/bin/sed -i \
      "s/''${2//\//\\\/}/''${3//\//\\\/}/g;"'
      ${ pkgs.lib.optionalString fail-if-not-found ''
        tm;''${x;/1/{x;q};x;q1};b;:m;x;s/.*/1/;x
      ''}
    ' "$1" 
  ''
