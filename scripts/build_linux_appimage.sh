#!/usr/bin/env bash
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
DIST_DIR="$ROOT_DIR/build/linux/appimage"
APPDIR="$DIST_DIR/AnxReader.AppDir"
APPIMAGETOOL="${APPIMAGETOOL:-$DIST_DIR/appimagetool-$ARCH.AppImage}"
OUTPUT="$DIST_DIR/Anx-Reader-linux-$ARCH-$VERSION.AppImage"

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

rm -rf "$APPDIR"
mkdir -p \
  "$APPDIR/usr/bin" \
  "$APPDIR/usr/share/applications" \
  "$APPDIR/usr/share/icons/hicolor/256x256/apps"

cp -a "$BUNDLE_DIR/." "$APPDIR/usr/bin/"
cp "assets/icon/Anx-logo.png" "$APPDIR/$ICON_NAME.png"
cp "assets/icon/Anx-logo.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/$ICON_NAME.png"

cat > "$APPDIR/AppRun" <<EOF
#!/usr/bin/env bash
set -e
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export LD_LIBRARY_PATH="\$HERE/usr/bin/lib:\${LD_LIBRARY_PATH:-}"
exec "\$HERE/usr/bin/$BINARY_NAME" "\$@"
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/$APP_ID.desktop" <<EOF
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
EOF
cp "$APPDIR/$APP_ID.desktop" "$APPDIR/usr/share/applications/$APP_ID.desktop"

if [[ ! -x "$APPIMAGETOOL" ]]; then
  mkdir -p "$DIST_DIR"
  echo "Downloading appimagetool to $APPIMAGETOOL"
  curl -L \
    "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$ARCH.AppImage" \
    -o "$APPIMAGETOOL"
  chmod +x "$APPIMAGETOOL"
fi

rm -f "$OUTPUT"
ARCH="$ARCH" APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" "$OUTPUT"
chmod +x "$OUTPUT"

echo "$OUTPUT"
