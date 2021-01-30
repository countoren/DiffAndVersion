{ 
 pkgs ?  tmpkgs.nixpkgs.consulting {}
, tmpkgs ? (import ( fetchTarball "https://code.topmanage.com/rest/api/latest/projects/DEVUTILS/repos/tmpkgs/archive?format=tgz&prefix=tmpkgs" ) { inherit pkgs; })
}:
with pkgs;
with builtins;
let
  global-config = import ../global-config.nix;

  firstDefaultNixFilesInDir  = tmpkgs.lib.firstFilesInDir { fileName = "default.nix"; dir = ../src; };
  
  platformDrvs = map (f: import f global-config ) firstDefaultNixFilesInDir;

  linkCmds = lib.concatMapStrings (platformDrv: ''
    ln -sf ${platformDrv} $out/${platformDrv.name}
    '') platformDrvs;

# prepare-release = pkgs.writeShellScriptBin "prepare-release"

  #     ''
  #         [ -e .remote ] && remote=$( head .remote ) || remote=origin
  #         git fetch --tags "$remote"
  #         git tag "$version"
  #         git push "$remote" "$version"
  #     '';
in
stdenv.mkDerivation rec {
  name =  with pkgs.lib; last (strings.splitString "/" (toString ../.));
  phases = [ "buildPhase" "installPhase" ];

  installPhase = ''
    mkdir $out
    ${linkCmds}
  '';

  buildPhase = ''
    echo -e "platform results: 
    ${ 
      lib.concatMapStrings (platformDrv: ''
      ${platformDrv}
      '') platformDrvs
    }" 1>&2
    '';
}
