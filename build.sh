#!/usr/bin/env bash

 . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || . ~/.nix-profile/etc/profile.d/nix.sh
buildFolder=`git rev-parse --show-toplevel`/build
cd $buildFolder
REMOTE="$4"
[ -z "$REMOTE" ] || git fetch --tags "$REMOTE"
nix-shell --run "build-changed `git describe --abbrev=0 --tags || echo "_"` \"${1:-"0.0.0"}\" \"${2:-"0000"}\" \"$3\" \"$REMOTE\""

# Deployment (if exists)
# for any deploy/auto file in the result folder execute this script.
echo 'Pre-deploy phase'
nix-shell --run "deploy"
