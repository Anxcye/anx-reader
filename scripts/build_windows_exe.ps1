$innoSetupDir = "C:\Program Files (x86)\Inno Setup 6"

# Inno Setup should already be installed by the CI workflow
if (!(Test-Path "$innoSetupDir\ISCC.exe")) {
    Write-Error "Inno Setup not found at $innoSetupDir. Please ensure it's installed."
    exit 1
}

Remove-Item "D:\inno" -Force  -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "D:\inno"

# unzip signed zip file
Expand-Archive -Path "build\windows\app.zip" -DestinationPath "D:\inno"

Remove-Item "D:\inno-result" -Force  -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "D:\inno-result"

# copy language file
Copy-Item "scripts\ChineseSimplified.isl" "$innoSetupDir\Languages\"
Copy-Item "scripts\ChineseTraditional.isl" "$innoSetupDir\Languages\"
& "$innoSetupDir\ISCC.exe" ".\scripts\compile_windows_setup-inno.iss"

Copy-Item "D:\inno-result\app.exe" "build\windows\unsigned\app.exe"

Write-Output 'Generated Windows exe installer!'

