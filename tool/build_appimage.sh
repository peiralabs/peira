#!/bin/bash
# Build Peira-x86_64.AppImage from the Linux release bundle.
#
# Portable and CI-capable: no root-only paths, appimagetool is self-acquired
# when absent, every host library copy fails loudly, and the full link closure
# is audited against tool/appimage_system_deps.txt — the build fails on any
# external library that is neither bundled nor declared there, so a new plugin
# quietly linking something breaks THIS build, not a user's machine.
#
# Usage: tool/build_appimage.sh [OUT]
#   OUT defaults to dist/Peira-x86_64.AppImage under the repo root.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="$REPO/build/linux/x64/release/bundle"
OUT="${1:-$REPO/dist/Peira-x86_64.AppImage}"
MANIFEST="$REPO/tool/appimage_system_deps.txt"

die() { echo "build_appimage: $*" >&2; exit 1; }

[ -x "$BUNDLE/peira" ] || die "no release bundle — run 'flutter build linux --release' first"
[ -f "$MANIFEST" ] || die "missing $MANIFEST"
command -v objdump >/dev/null || die "objdump (binutils) is required for the closure audit"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
APPDIR="$WORK/Peira.AppDir"
mkdir -p "$APPDIR/usr/bin"
cp -r "$BUNDLE"/* "$APPDIR/usr/bin/"

# ldconfig lives in /sbin on several distros and /sbin is not on non-root
# PATHs (openSUSE, some CI images) — resolve it, with a plain directory scan
# as the fallback so the script still works where ldconfig is absent.
resolve_lib() {
  local so="$1" c d p
  for c in ldconfig /sbin/ldconfig /usr/sbin/ldconfig; do
    command -v "$c" >/dev/null 2>&1 || continue
    p="$("$c" -p 2>/dev/null | awk -v l="$so" '$1==l && /x86-64/ {print $NF; exit}')"
    [ -n "$p" ] && { echo "$p"; return 0; }
    break
  done
  for d in /usr/lib/x86_64-linux-gnu /usr/lib64 /lib64 /usr/lib /lib; do
    [ -e "$d/$so" ] && { echo "$d/$so"; return 0; }
  done
  return 1
}

# Leaf client libraries a target distro may not have installed, copied from
# the build host into the binary's $ORIGIN/lib RUNPATH:
#   libgthread-2.0   glib stub Debian links but e.g. openSUSE no longer ships
#   libsecret-1      flutter_secure_storage's client library — without it the
#                    app cannot read ANY stored token (the Secret Service
#                    daemon itself stays a system requirement, see manifest)
#   libXi/libXrandr/libXcomposite/libXdamage/libXfixes/libXrender
#                    X client libraries CEF links (libXrender via libXrandr);
#                    absent on lean installs
# Everything else external is a declared system dependency in the manifest.
BUNDLE_LIBS=(
  libgthread-2.0.so.0
  libsecret-1.so.0
  libXi.so.6
  libXrandr.so.2
  libXcomposite.so.1
  libXdamage.so.1
  libXfixes.so.3
  libXrender.so.1
)
for lib in "${BUNDLE_LIBS[@]}"; do
  if [ -e "$APPDIR/usr/bin/lib/$lib" ]; then
    echo "  $lib: already present in bundle"
    continue
  fi
  src="$(resolve_lib "$lib")" || die "$lib not found on the build host — install it or build elsewhere"
  cp "$src" "$APPDIR/usr/bin/lib/" || die "failed to bundle $lib from $src"
  echo "  $lib: bundled from $src"
done

# Closure audit: every NEEDED soname across the main binary and all bundled
# libraries must be either bundled or declared in the manifest.
externals="$( { objdump -p "$APPDIR/usr/bin/peira"
                find "$APPDIR/usr/bin/lib" -name '*.so*' -exec objdump -p {} + ; } 2>/dev/null \
              | awk '/NEEDED/{print $2}' | sort -u )"
declared="$(awk '$1 !~ /^#/ && NF {print $1}' "$MANIFEST")"
undeclared=""
while IFS= read -r so; do
  [ -e "$APPDIR/usr/bin/lib/$so" ] && continue
  printf '%s\n' "$declared" | grep -qxF "$so" || undeclared="$undeclared $so"
done <<< "$externals"
[ -z "$undeclared" ] || die "undeclared external libraries:$undeclared — bundle them or declare them in $MANIFEST"
echo "  closure audit: OK ($(printf '%s\n' "$externals" | wc -l) NEEDED sonames)"

cp "$REPO/assets/icon/homelab-512.png" "$APPDIR/homelab.png" || die "app icon missing"

cat > "$APPDIR/homelab.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Peira
Comment=Peira control panel
Exec=peira
Icon=homelab
Categories=Utility;System;
StartupWMClass=dev.peira.app
EOF

cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
# The main binary's RUNPATH does not apply transitively: a plugin .so's own
# dependencies (e.g. flutter_secure_storage -> libsecret) never search
# usr/bin/lib through it. Export the path for the whole process tree —
# found the hard way on a Fedora box whose gnome-keyring did not pull
# libsecret (Ubuntu's does, which masked it there).
export LD_LIBRARY_PATH="$HERE/usr/bin/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$HERE/usr/bin/peira" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# appimagetool: PATH first, else a cached download of the upstream release.
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/homelab-build"
if command -v appimagetool >/dev/null 2>&1; then
  AIT=appimagetool
else
  AIT="$CACHE/appimagetool-x86_64.AppImage"
  if [ ! -x "$AIT" ]; then
    mkdir -p "$CACHE"
    URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    echo "  downloading appimagetool -> $AIT"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL -o "$AIT" "$URL" || die "appimagetool download failed"
    else
      wget -qO "$AIT" "$URL" || die "appimagetool download failed"
    fi
    chmod +x "$AIT"
  fi
fi

mkdir -p "$(dirname "$OUT")"
# Pin the AppImage runtime to a cached copy when present: without this,
# appimagetool fetches the runtime from GitHub on every build, and its
# download thread has no timeout — a stalled connection hangs the build
# indefinitely (observed 2026-08-28). A cached runtime makes the build
# network-independent and hang-proof.
RT_FLAG=()
if [ -f "$CACHE/runtime-x86_64" ]; then
  RT_FLAG=(--runtime-file "$CACHE/runtime-x86_64")
  echo "  using cached runtime: $CACHE/runtime-x86_64"
fi
# --appimage-extract-and-run avoids a FUSE requirement when appimagetool is
# itself an AppImage; a native appimagetool rejects the flag, hence the retry.
ARCH=x86_64 "$AIT" "${RT_FLAG[@]}" --appimage-extract-and-run "$APPDIR" "$OUT" 2>/dev/null ||
  ARCH=x86_64 "$AIT" "${RT_FLAG[@]}" "$APPDIR" "$OUT"
ls -lh "$OUT"
