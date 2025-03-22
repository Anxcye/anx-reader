#!/bin/bash
# Path to your project.pbxproj file
PROJECT_FILE="macos/Runner.xcodeproj/project.pbxproj"

echo "Disabling code signing for CI build..."

# Remove code signing identity
sed -i '' 's/"CODE_SIGN_IDENTITY\[sdk=macosx\*\]" = "Apple Development"/"CODE_SIGN_IDENTITY\[sdk=macosx\*\]" = "-"/g' "$PROJECT_FILE"

# Change code sign style to Manual
sed -i '' 's/CODE_SIGN_STYLE = Automatic/CODE_SIGN_STYLE = Manual/g' "$PROJECT_FILE"

# Remove development team
sed -i '' 's/DEVELOPMENT_TEAM = 28W956D5K8;//g' "$PROJECT_FILE"

# Add additional code signing settings - fixed for macOS
sed -i '' '/MACOSX_DEPLOYMENT_TARGET/a\
                CODE_SIGNING_REQUIRED = NO;\
                CODE_SIGNING_ALLOWED = NO;' "$PROJECT_FILE"

echo "Code signing disabled successfully!"