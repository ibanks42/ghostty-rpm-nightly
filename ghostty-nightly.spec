# Nightly ("tip") build of Ghostty, packaged for Fedora.
#
# This is a template: make-spec.sh prepends %%global lines for
#   upstream_version  Ghostty's own version string, e.g. 1.4.1-main+393a3a7
#   rpm_version       the part before the first '-', e.g. 1.4.1
#   snapshot          <commit UTC timestamp>.git<short sha>, e.g. 20261109121141.git393a3a7
#   changelog_date    commit date in %%changelog format
#   zig_version, zig_sha256_x86_64, zig_sha256_aarch64
#                     the Zig release Ghostty requires, downloaded in %%prep
#
# The build needs network access (Zig itself and Zig package dependencies);
# the COPR project has "enable internet access during builds" turned on.
#
# Release starts with "0." so a nightly always sorts below the matching stable
# release (1.4.1-0.2026... < 1.4.1-1), and the timestamp makes nightlies sort
# in commit order.

%{!?upstream_version: %{error: generate with make-spec.sh, missing "upstream_version ..."}}
%{!?rpm_version: %{error: generate with make-spec.sh, missing "rpm_version ..."}}
%{!?snapshot: %{error: generate with make-spec.sh, missing "snapshot ..."}}
%{!?changelog_date: %{error: generate with make-spec.sh, missing "changelog_date ..."}}
%{!?zig_version: %{error: generate with make-spec.sh, missing "zig_version ..."}}

# Built with -Dstrip, so there is no debuginfo to extract.
%global debug_package %{nil}

%global zig_flags -Doptimize=ReleaseFast -Dcpu=baseline -Dpie=true -Dstrip=true -Dversion-string=%{upstream_version} -Dinstalled-exe-path=%{_bindir}/ghostty

Name:           ghostty-nightly
Version:        %{rpm_version}
Release:        0.%{snapshot}%{?dist}
Summary:        Fast, native, feature-rich terminal emulator (nightly tip build)
License:        MIT
URL:            https://ghostty.org
Source0:        ghostty-source.tar.gz

ExclusiveArch:  x86_64 aarch64

BuildRequires:  gtk4-devel
BuildRequires:  libadwaita-devel
BuildRequires:  gtk4-layer-shell-devel
BuildRequires:  gettext
BuildRequires:  pandoc-cli
BuildRequires:  glib2-devel
BuildRequires:  pkgconfig(egl)
BuildRequires:  pkgconfig(vulkan)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(x11)
BuildRequires:  pkgconfig(harfbuzz)
BuildRequires:  desktop-file-utils
BuildRequires:  curl
BuildRequires:  tar
BuildRequires:  xz

# Same files as the stable package, so only one can be installed.
Conflicts:      ghostty

%description
Ghostty is a fast, feature-rich, and cross-platform terminal emulator that
uses platform-native UI and GPU acceleration.

This package is built automatically from the upstream "tip" release
(the main branch). Version: %{upstream_version}.

%prep
%autosetup -n ghostty-%{upstream_version}

# Ghostty needs a newer Zig than Fedora usually ships; use the upstream build.
curl -fsSL https://ziglang.org/download/%{zig_version}/zig-%{_target_cpu}-linux-%{zig_version}.tar.xz -o zig.tar.xz
echo "%{expand:%%{zig_sha256_%{_target_cpu}}}  zig.tar.xz" | sha256sum -c -
mkdir zig-toolchain
tar -xJf zig.tar.xz -C zig-toolchain --strip-components=1
rm zig.tar.xz

%build
# Fetch Zig dependencies (into ZIG_GLOBAL_CACHE_DIR when set). Compiling
# happens in %%install, because `zig build` builds and installs in one step.
./zig-toolchain/zig build --fetch=all %{zig_flags}

%install
DESTDIR=%{buildroot} ./zig-toolchain/zig build --prefix %{_prefix} %{zig_flags}

# Upstream adds and moves data files often on main, so list whatever got
# installed instead of maintaining a %%files list by hand.
(
  cd %{buildroot}
  # Quoted because some theme names contain spaces. Man pages are left out
  # here and globbed below, since rpm compresses them after %%install.
  find . \( -type f -o -type l \) -not -path './usr/share/man/*' | sed 's|^\.\(.*\)|"\1"|'
  echo '%{_mandir}/man*/*'
  # Own the directories that belong only to Ghostty.
  find . -type d \( -path ./usr/share/ghostty -o -path './usr/share/ghostty/*' \
                   -o -path './usr/lib*/ghostty*' \) | sed 's|^\.\(.*\)|%dir "\1"|'
) | sort -u > %{_builddir}/ghostty-files.list

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/*.desktop

%files -f %{_builddir}/ghostty-files.list

%changelog
* %{changelog_date} ghostty-rpm-nightly CI - %{rpm_version}-0.%{snapshot}
- Automated nightly build of Ghostty %{upstream_version}
