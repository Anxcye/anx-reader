#!/bin/bash

APP_PATH="build/macos/Build/Products/Release/Anx Reader.app"

OPT_APP_FORMAT=""
OPT_DEPLOYMENT=""
BUILD_RESULT=0

for optname in "$@"
do
    case $optname in
        macos)
            OPT_APP_FORMAT="macos"
            ;;
        -d)
            OPT_DEPLOYMENT="-d"
            ;;
        -h)
            echo "usage: $0 macos [-d]"
            exit 0
            ;;
        *)
            echo "Invalid argument: $optname"
            echo "usage: $0 macos [-d]"
            exit 1
            ;;
    esac
done
# 如果没有传递任何参数,显示帮助信息
if [ -z "$OPT_APP_FORMAT" ] && [ -z "$OPT_DEPLOYMENT" ]; then
    echo "usage: $0 macos [-d]"
    exit 1
fi

clrecho() {
    printf "\e[38;5;196m$1\e[0m\n"
}

if [[ "$OPT_APP_FORMAT" == "macos" ]]; then
    # if [[ $OPT_DEPLOYMENT == "-d" ]]; then
    #     fvm flutter clean
    # fi

    fvm flutter build macos --release
    BUILD_RESULT=$?

    if [[ $BUILD_RESULT != 0 ]]; then
        clrecho "Failed to build the $OPT_APP_FORMAT"
    fi
fi

if [[ $BUILD_RESULT == 0 && $OPT_DEPLOYMENT == "-d" ]]; then
    echo "deploy to /Applications/"
    rm -rf /Applications/AnxReader.app
    cp -rf "$APP_PATH" /Applications/AnxReader.app
fi
