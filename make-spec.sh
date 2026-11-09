#!/bin/sh
# Turn the ghostty-nightly.spec template into a buildable spec for one Ghostty
# tip tarball, by prepending the version and Zig details as %global lines.
#
# usage: make-spec.sh <template.spec> <ghostty-source.tar.gz> > ghostty-nightly.spec
#
# Shared by build.sh (GitHub Actions) and the COPR custom build script, so both
# produce identical version numbers. Needs: tar, gzip, curl, jq.
set -eu

template=$1
src=$2

# Ghostty's VERSION file looks like "1.4.1-main+393a3a7".
upstream_version=$(tar -xOzf "$src" --wildcards --no-wildcards-match-slash '*/VERSION' | head -n1 | tr -d '[:space:]')
rpm_version=${upstream_version%%-*}
sha=${upstream_version##*+}
if [ -z "$rpm_version" ] || [ "$sha" = "$upstream_version" ]; then
    echo "unexpected Ghostty version: '$upstream_version'" >&2
    exit 1
fi

# The tarball's file mtimes are the commit time (it's made with git archive).
commit_time=$(TZ=UTC tar -tvzf "$src" --full-time | head -n1 | awk '{print $4" "$5}')
snapshot="$(date -u -d "$commit_time" +%Y%m%d%H%M%S).git$sha"
changelog_date=$(date -u -d "$commit_time" '+%a %b %d %Y')

zig_version=$(tar -xOzf "$src" --wildcards --no-wildcards-match-slash '*/build.zig.zon' |
    sed -n 's/.*\.minimum_zig_version *= *"\([^"]*\)".*/\1/p')
zig_index=$(curl -fsSL https://ziglang.org/download/index.json)
zig_sha() {
    sum=$(printf '%s' "$zig_index" | jq -r --arg v "$zig_version" --arg a "$1-linux" '.[$v][$a].shasum // empty')
    [ -n "$sum" ] || { echo "no Zig $zig_version for $1-linux" >&2; exit 1; }
    echo "$sum"
}

cat <<EOF
%global upstream_version $upstream_version
%global rpm_version $rpm_version
%global snapshot $snapshot
%global changelog_date $changelog_date
%global zig_version $zig_version
%global zig_sha256_x86_64 $(zig_sha x86_64)
%global zig_sha256_aarch64 $(zig_sha aarch64)

EOF
cat "$template"
