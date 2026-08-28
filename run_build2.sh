#!/bin/bash
set -e

echo "Building Android APKs..."
flutter build apk --split-per-abi

echo "Building macOS app..."
flutter build macos --release || {
    echo "macOS build with signing failed. Retrying without signing..."
    chmod +x ./scripts/macos_nosign.sh
    ./scripts/macos_nosign.sh
    flutter build macos --release
}

echo "Packaging macOS DMG..."
cd build/macos/Build/Products/Release
mkdir -p "Anx Reader"
rm -rf "Anx Reader/AnxReader.app"
cp -r "Anx Reader.app" "Anx Reader/AnxReader.app"
rm -f "Anx Reader/Applications"
ln -s /Applications "Anx Reader/Applications"
rm -f Anx-Reader.dmg
hdiutil create -volname "Anx Reader" -srcfolder "Anx Reader" -ov -format UDZO Anx-Reader.dmg
echo "Build completed successfully!"
