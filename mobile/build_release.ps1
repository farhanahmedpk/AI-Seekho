$ErrorActionPreference = "Stop"

# Try to find Flutter
$flutterBin = "flutter"
if (Test-Path "C:\src\flutter\bin\flutter.bat") {
    $flutterBin = "C:\src\flutter\bin\flutter.bat"
} elseif (Test-Path "D:\New folder (3)\flutter\bin\flutter.bat") {
    $flutterBin = "D:\New folder (3)\flutter\bin\flutter.bat"
}

Write-Host "Using Flutter at: $flutterBin"
Set-Location "D:\New folder (3)\cold_guard"

Write-Host "1. Generating native Android/iOS files (required for build)..."
& $flutterBin create . --platforms android,ios

Write-Host "2. Updating AndroidManifest.xml app name..."
$manifest = "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
    (Get-Content $manifest) -replace 'android:label=".*?"', 'android:label="ColdGuard"' | Set-Content $manifest
}

Write-Host "3. Updating Info.plist app name..."
$plist = "ios\Runner\Info.plist"
if (Test-Path $plist) {
    (Get-Content $plist) -replace '<key>CFBundleName</key>\s*<string>.*?</string>', "<key>CFBundleName</key>`n`t<string>ColdGuard</string>" | Set-Content $plist
}

Write-Host "4. Running Flutter Analyze..."
& $flutterBin analyze

Write-Host "5. Building Release APK..."
& $flutterBin build apk --release

Write-Host "Build complete! Opening APK directory..."
if (Test-Path "build\app\outputs\flutter-apk\") {
    Invoke-Item "build\app\outputs\flutter-apk\"
}
