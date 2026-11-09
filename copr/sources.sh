#!/bin/sh
# COPR "custom" source script for ibanks/ghostty-nightly.
#
# COPR runs this (with internet access, as an unprivileged user) to produce the
# spec + sources it then builds into RPMs. It pulls the build logic from this
# repo's main branch, so changes here reach COPR without re-uploading the script.
#
# Registered once with:
#   copr-cli add-package-custom ghostty-nightly --name ghostty-nightly \
#     --script copr/sources.sh --script-builddeps "curl jq tar gzip minisign"
# Re-run that (as edit-package-custom) only if this file itself changes.
set -eu

repo=https://raw.githubusercontent.com/ibanks42/ghostty-rpm-nightly/main
tip=https://github.com/ghostty-org/ghostty/releases/download/tip

curl -fsSLO "$tip/ghostty-source.tar.gz"
curl -fsSLO "$tip/ghostty-source.tar.gz.minisig"
# Ghostty's release signing key (https://ghostty.org/docs/install/build)
minisign -V -m ghostty-source.tar.gz -P RWQlAjJC23149WL2sEpT/l0QKy7hMIFhYdQOFy0Z7z7PbneUgvlsnYcV
rm ghostty-source.tar.gz.minisig

curl -fsSL "$repo/make-spec.sh" -o /tmp/make-spec.sh
curl -fsSL "$repo/ghostty-nightly.spec" -o /tmp/template.spec
sh /tmp/make-spec.sh /tmp/template.spec ghostty-source.tar.gz > ghostty-nightly.spec
head -n 7 ghostty-nightly.spec
