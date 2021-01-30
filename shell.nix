{ pkgs ? import <nixpkgs> {}
}:
pkgs.mkShell {
	buildInputs = [
	pkgs.git
    (pkgs.writeShellScriptBin "deploy" 
      ''
          for file in $(find -L result -executable -wholename '*deploy/auto')
          do
            pushd $(dirname $file);
            ./auto
            popd 
          done
      '')
	(pkgs.writeShellScriptBin "build-changed"
		''
                    REF="$1"
                    VERSION="$2"
                    # bamboo.buildNumber or bamboo.buildResultKey
                    BUILD_NUMBER="$3"
                    TAG="$4"
                    # bamboo.planRepository.<position>.repositoryUrl (position is optional)
                    REMOTE="$5"
                    currentBranch=`git rev-parse --abbrev-ref HEAD`
                    after=`nix-build --no-out-link` &&
                    afterWithVersion=`nix-build \
                      --out-link result \
                      --argstr input "$after" \
                      --argstr version "$VERSION" \
                      --argstr build-number "$BUILD_NUMBER" \
                      --argstr branch "$currentBranch" \
                      ./put-version.nix` &&
                    [ -z "$REF" ] || [ $REF = "_" ] && exit 0
                    git stash --include-untracked --quiet
                    git -c advice.detachedHead=false checkout --quiet "$REF"
                    before=`nix-build --no-out-link`
                    git checkout --quiet "$currentBranch"
                    git stash pop --quiet
                    changed=`nix-build --no-out-link --argstr after "$after" --argstr before "$before" diff.nix` &&
                    changedWithVersion=`nix-build --out-link changed \
                      --argstr input "$changed" \
                      --argstr version "$VERSION" \
                      --argstr build-number "$BUILD_NUMBER" \
                      --argstr branch "$currentBranch" \
                      ./put-version.nix` &&
                    echo "CHANGED: ''${changedWithVersion}" 1>&2 &&
                    [ -z "$TAG" ] && exit 0
                    echo "Creating tag: ''${TAG}"
                    git tag "$TAG"
                    [ -z "$REMOTE" ] && exit 0
                    echo "Pushing tag: ''${TAG} to ''${REMOTE}"
                    git push "$REMOTE" "$TAG"
		'')
	];
}
