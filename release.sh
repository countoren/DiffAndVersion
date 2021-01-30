#!/usr/bin/env bash

 . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || . ~/.nix-profile/etc/profile.d/nix.sh
version="$1"
[ -z $version ] && echo "Release needs a version. Please supply it as an argument." >&2 && exit 1

nix-shell --run prepare-release --argstr version "$version"
nix-build --argstr version "$version"
