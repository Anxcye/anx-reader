$innoSetupDir = "C:\Program Files (x86)\Inno Setup 6"

winget install -e --id JRSoftware.InnoSetup --location $innoSetupDir --accept-source-agreements

flutter clean
flutter pub get
flutter gen-l10n
flutter build windows

Remove-Item "D:\inno" -Force  -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "D:\inno"
Copy-Item -Path "build\windows\x64\runner\Release\*" -Destination "D:\inno" -Recurse
Copy-Item -Path "windows\runner\resources\app_icon.ico" -Destination "D:\inno\logo.ico"

Copy-Item -Path "scripts\windows\x64\*" -Destination "D:\inno" -Recurse -ErrorAction SilentlyContinue
Remove-Item "D:\inno-result" -Force  -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "D:\inno-result"

7z a -tzip "D:\inno-result\app.zip" "D:\inno\*"

Copy-Item "scripts\ChineseSimplified.isl" "$innoSetupDir\Languages\"
Copy-Item "scripts\ChineseTraditional.isl" "$innoSetupDir\Languages\"
& "$innoSetupDir\ISCC.exe" ".\scripts\compile_windows_setup-inno.iss"

Copy-Item "D:\inno-result\app.exe" "build\windows\app.exe"
Copy-Item "D:\inno-result\app.zip" "build\windows\app.zip"
ls "D:\inno-result\app.exe"
ls "build\windows"

Write-Output 'Generated Windows exe installer!'

