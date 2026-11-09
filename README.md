# ghostty-rpm-nightly

Nightly RPMs of [Ghostty](https://ghostty.org) for Fedora, built on
[COPR](https://copr.fedorainfracloud.org/coprs/ibanks/ghostty-nightly/) from
the upstream [`tip`](https://github.com/ghostty-org/ghostty/releases/tag/tip) release.

## Install

```sh
sudo dnf copr enable ibanks/ghostty-nightly
sudo dnf install ghostty-nightly
```

Updates arrive through the usual `sudo dnf upgrade`. The package is called
`ghostty-nightly` and conflicts with any other package named `ghostty` (e.g. a
stable build from another COPR).

## How it works

- `.github/workflows/nightly.yml` runs daily (or by hand from the Actions tab).
  It compares upstream's tip commit with COPR's latest successful build and, if
  there's a new commit, calls the COPR custom webhook.
- COPR runs `copr/sources.sh`, which downloads the tip tarball, verifies its
  minisign signature, pulls `make-spec.sh` and the spec from this repo's `main`
  branch, and generates the spec COPR builds.
- `ghostty-nightly.spec` is a template. `make-spec.sh` reads the tarball and
  prepends the version, commit timestamp and required Zig release. The spec
  downloads that Zig release itself, so builds need network access (the COPR
  project has it enabled; Zig also fetches Ghostty's dependencies).
