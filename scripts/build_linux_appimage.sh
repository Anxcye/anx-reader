#!/usr/bin/env bash
# Build Linux release packages: AppImage + tar.gz of the Flutter bundle.
# Naming matches other platforms: Anx-Reader-<platform>-<version>[-<arch>].<ext>
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="Anx Reader"
APP_ID="com.anxcye.anx_reader"
BINARY_NAME="anx_reader"
ICON_NAME="anx-reader"
ARCH="${ARCH:-x86_64}"
VERSION="${VERSION:-$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)}"

BUILD_DIR="$ROOT_DIR/build/linux/x64/release"
BUNDLE_DIR="$BUILD_DIR/bundle"
DIST_DIR="$ROOT_DIR/build/linux/dist"
APPDIR="$DIST_DIR/AnxReader.AppDir"
APPIMAGETOOL="${APPIMAGETOOL:-$DIST_DIR/appimagetool-$ARCH.AppImage}"
PKG_BASENAME="Anx-Reader-linux-${VERSION}-${ARCH}"
APPIMAGE_OUTPUT="$DIST_DIR/${PKG_BASENAME}.AppImage"
TARBALL_OUTPUT="$DIST_DIR/${PKG_BASENAME}.tar.gz"
# Final copies next to other platform artifact layouts (build/linux/*.…)
FINAL_DIR="$ROOT_DIR/build/linux"

if command -v flutter >/dev/null 2>&1; then
  FLUTTER_CMD=(flutter)
  DART_CMD=(dart)
elif command -v fvm >/dev/null 2>&1; then
  FLUTTER_CMD=(fvm flutter)
  DART_CMD=(fvm dart)
else
  FLUTTER_CMD=()
  DART_CMD=()
fi

if [[ "${SKIP_FLUTTER_BUILD:-0}" != "1" ]]; then
  if [[ ${#FLUTTER_CMD[@]} -eq 0 ]]; then
    echo "flutter was not found in PATH, and fvm was not found either" >&2
    exit 1
  fi

  "${FLUTTER_CMD[@]}" config --enable-linux-desktop
  "${FLUTTER_CMD[@]}" gen-l10n
  "${DART_CMD[@]}" run build_runner build --delete-conflicting-outputs
  "${FLUTTER_CMD[@]}" build linux --release
fi

if [[ ! -x "$BUNDLE_DIR/$BINARY_NAME" ]]; then
  echo "Linux bundle binary not found at $BUNDLE_DIR/$BINARY_NAME" >&2
  exit 1
fi

mkdir -p "$DIST_DIR" "$FINAL_DIR"

# --- tar.gz of the release bundle (stripped CEF already applied by post_install) ---
STAGING="$DIST_DIR/staging"
rm -rf "$STAGING"
mkdir -p "$STAGING/$PKG_BASENAME"
cp -a "$BUNDLE_DIR/." "$STAGING/$PKG_BASENAME/"
tar -C "$STAGING" -czf "$TARBALL_OUTPUT" "$PKG_BASENAME"
rm -rf "$STAGING"

# --- AppImage ---
rm -rf "$APPDIR"
mkdir -p \
  "$APPDIR/usr/bin" \
  "$APPDIR/usr/share/applications" \
  "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
  "$APPDIR/usr/share/icons/hicolor/512x512/apps"

cp -a "$BUNDLE_DIR/." "$APPDIR/usr/bin/"
cp "assets/icon/anx-reader-256.png" "$APPDIR/$ICON_NAME.png"
cp "assets/icon/anx-reader-256.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/$ICON_NAME.png"
cp "assets/icon/anx-reader-512.png" "$APPDIR/usr/share/icons/hicolor/512x512/apps/$ICON_NAME.png"

cat > "$APPDIR/AppRun" <<APPRUN
#!/usr/bin/env bash
set -e
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export LD_LIBRARY_PATH="\$HERE/usr/bin/lib:\${LD_LIBRARY_PATH:-}"
exec "\$HERE/usr/bin/$BINARY_NAME" "\$@"
APPRUN
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/$APP_ID.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=An e-book reader
Exec=AppRun %U
Icon=$ICON_NAME
Terminal=false
Categories=Office;Viewer;
MimeType=application/epub+zip;application/pdf;text/plain;text/html;
StartupWMClass=$BINARY_NAME
DESKTOP
cp "$APPDIR/$APP_ID.desktop" "$APPDIR/usr/share/applications/$APP_ID.desktop"

if [[ ! -x "$APPIMAGETOOL" ]]; then
  echo "Downloading appimagetool to $APPIMAGETOOL"
  curl -L \
    "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$ARCH.AppImage" \
    -o "$APPIMAGETOOL"
  chmod +x "$APPIMAGETOOL"
fi

rm -f "$APPIMAGE_OUTPUT"
ARCH="$ARCH" APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" "$APPIMAGE_OUTPUT"
chmod +x "$APPIMAGE_OUTPUT"

cp -f "$APPIMAGE_OUTPUT" "$FINAL_DIR/"
cp -f "$TARBALL_OUTPUT" "$FINAL_DIR/"

echo "$FINAL_DIR/${PKG_BASENAME}.AppImage"
echo "$FINAL_DIR/${PKG_BASENAME}.tar.gz"
