flutter clean
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter build windows

Remove-Item "D:\inno" -Force  -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "D:\inno"
Copy-Item -Path "build\windows\x64\runner\Release\*" -Destination "D:\inno" -Recurse
Copy-Item -Path "windows\runner\resources\app_icon.ico" -Destination "D:\inno\logo.ico"

Copy-Item -Path "scripts\windows\x64\*" -Destination "D:\inno" -Recurse -ErrorAction SilentlyContinue
Remove-Item "D:\inno-result" -Force  -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "D:\inno-result"

7z a -tzip "D:\inno-result\app.zip" "D:\inno\*"

New-Item -ItemType Directory -Force -Path "build\windows\unsigned"
Copy-Item "D:\inno-result\app.zip" "build\windows\unsigned\app.zip"

Write-Output 'Generated Windows zip!'

