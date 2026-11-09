#!/usr/bin/env bash
# Build the ghostty-nightly RPM. Runs as root inside a fedora:<N> container.
#
# usage: build.sh <ghostty-source.tar.gz> <out-dir>
#
# The source tarball must already be verified (see the prepare job).
set -euo pipefail

src=$(realpath "$1")
out=$(realpath -m "$2")
here=$(dirname "$(realpath "$0")")

dnf -y install --setopt=install_weak_deps=False \
    rpm-build dnf-plugins-core curl jq tar gzip

top=$(mktemp -d)
mkdir -p "$top/SOURCES" "$top/SPECS"
cp "$src" "$top/SOURCES/ghostty-source.tar.gz"
"$here/make-spec.sh" "$here/ghostty-nightly.spec" "$src" >"$top/SPECS/ghostty-nightly.spec"
head -n 7 "$top/SPECS/ghostty-nightly.spec"

dnf -y builddep "$top/SPECS/ghostty-nightly.spec"
rpmbuild -bb "$top/SPECS/ghostty-nightly.spec" --define "_topdir $top"

mkdir -p "$out"
find "$top/RPMS" -name '*.rpm' -exec cp -v {} "$out/" \;
