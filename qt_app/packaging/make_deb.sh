#!/usr/bin/env bash
#
# Build a distributable .deb for the vLearn2 Qt client (Virtual Foreign Language).
#
# Usage:
#   packaging/make_deb.sh [VERSION]
#
# Env overrides:
#   QMAKE   path to qmake        (default: ~/Qt5.12.12/5.12.12/gcc_64/bin/qmake)
#   ARCH    debian arch          (default: amd64)
#   JOBS    parallel make jobs   (default: nproc)
#
# Output:  dist/vlearn-chat_<VERSION>_<ARCH>.deb
#
# The package installs:
#   /usr/bin/vlearn-chat                      the binary (stripped)
#   /etc/vlearn/app_config.json               backend endpoint (a conffile)
#   /usr/share/applications/vlearn.desktop    launcher entry
#   /usr/share/icons/hicolor/*/apps/vlearn-chat.{png,svg}   app icon
#
# The app reads the endpoint from /etc/vlearn/app_config.json (or a per-user
# ~/.config/vlearn/app_config.json). Edit that file on the target to point at
# the right backend before first run.

set -euo pipefail

# ---- locations -------------------------------------------------------------
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../qt_app/packaging
APP_DIR="$(dirname "$HERE")"                            # .../qt_app
cd "$APP_DIR"

VERSION="${1:-1.0.0}"
ARCH="${ARCH:-amd64}"
JOBS="${JOBS:-$(nproc)}"
QMAKE="${QMAKE:-$HOME/Qt5.12.12/5.12.12/gcc_64/bin/qmake}"
PKG="vlearn-chat"

[ -x "$QMAKE" ] || { echo "ERROR: qmake not found at $QMAKE (set QMAKE=...)"; exit 1; }
command -v dpkg-deb >/dev/null || { echo "ERROR: dpkg-deb not found (apt install dpkg-dev)"; exit 1; }

BUILD="$APP_DIR/build-deb"
ROOT="$APP_DIR/pkgroot"
DIST="$APP_DIR/dist"
rm -rf "$BUILD" "$ROOT"
mkdir -p "$BUILD" "$DIST"

# ---- 1. build (release) ----------------------------------------------------
echo "==> Building (release) with $QMAKE"
( cd "$BUILD" && "$QMAKE" "$APP_DIR/qt_app.pro" CONFIG+=release >/dev/null && make -j"$JOBS" >/dev/null )
BIN="$BUILD/vlearn_chat"
[ -f "$BIN" ] || { echo "ERROR: build did not produce $BIN"; exit 1; }
strip --strip-unneeded "$BIN" || true

# ---- 2. assemble package tree ---------------------------------------------
echo "==> Assembling package tree"
install -Dm755 "$BIN"                         "$ROOT/usr/bin/vlearn-chat"
install -Dm644 "$APP_DIR/app_config.json"     "$ROOT/etc/vlearn/app_config.json"
install -Dm644 "$HERE/vlearn.desktop"         "$ROOT/usr/share/applications/vlearn.desktop"
install -Dm644 "$APP_DIR/README.md"           "$ROOT/usr/share/doc/$PKG/README.md"

# App icon — scalable SVG + hicolor PNG sizes (named to match the .desktop Icon=).
install -Dm644 "$HERE/icons/vlearn-chat.svg" \
        "$ROOT/usr/share/icons/hicolor/scalable/apps/vlearn-chat.svg"
for sz in 16 24 32 48 64 128 256 512; do
    png="$HERE/icons/vlearn-chat-$sz.png"
    [ -f "$png" ] && install -Dm644 "$png" \
        "$ROOT/usr/share/icons/hicolor/${sz}x${sz}/apps/vlearn-chat.png"
done

INSTALLED_KB=$(du -ks "$ROOT" | cut -f1)

# ---- 3. control metadata ---------------------------------------------------
mkdir -p "$ROOT/DEBIAN"
cat > "$ROOT/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: education
Priority: optional
Architecture: $ARCH
Maintainer: vLearn2 <noreply@vlearn2.local>
Installed-Size: $INSTALLED_KB
Depends: libc6, libstdc++6, alsa-utils, libqt5core5a (>= 5.12), libqt5gui5 (>= 5.12), libqt5widgets5 (>= 5.12), libqt5network5 (>= 5.12)
Description: Virtual Foreign Language - FreeTalk English speaking client
 Native Qt desktop client for the vLearn2 / FreeTalk English-learning platform.
 Connects to the backend configured in /etc/vlearn/app_config.json.
EOF

# Mark the endpoint config as a conffile so user edits survive upgrades.
echo "/etc/vlearn/app_config.json" > "$ROOT/DEBIAN/conffiles"

# Refresh the desktop database after (un)install, when the tool is present.
cat > "$ROOT/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
EOF
cp "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/postrm"
chmod 755 "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/postrm"

# ---- 4. build the .deb -----------------------------------------------------
OUT="$DIST/${PKG}_${VERSION}_${ARCH}.deb"
echo "==> Building $OUT"
dpkg-deb --root-owner-group --build "$ROOT" "$OUT" >/dev/null

echo
echo "Done: $OUT"
echo
echo "Install:    sudo apt install $OUT      # resolves Qt deps"
echo "         or sudo dpkg -i $OUT && sudo apt -f install"
echo "Configure:  sudo \$EDITOR /etc/vlearn/app_config.json   # set baseUrl"
echo "Run:        vlearn-chat                # or from the app menu"
echo "Remove:     sudo apt remove $PKG"
