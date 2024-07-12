#!/bin/bash

# check if version number is provided
if [ $# -eq 0 ]; then
    echo "Please provide a version number."
    echo "Usage: $0 <Version>"
    exit 1
fi

VERSION=$1
APP_NAME="Anx-Reader"
BUILD_DIR="build/app/outputs/flutter-apk"

# rename_apk(old_name, arch)
rename_apk() {
    local old_name=$1
    local arch=$2
    local new_name="${APP_NAME}-${VERSION}-${arch}.apk"

    mv "$BUILD_DIR/$old_name" "$BUILD_DIR/$new_name"
    echo "Renamed: $old_name -> $new_name"
}

# rename APK files
rename_apk "app-armeabi-v7a-release.apk" "armeabi-v7a"
rename_apk "app-arm64-v8a-release.apk" "arm64-v8a"
rename_apk "app-x86_64-release.apk" "x86_64"
rename_apk "app-release.apk" "universal"

echo "Rename successful!"