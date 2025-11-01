@echo off
REM Build APK helper for Bookala Bulk SMS app
REM Adjust FLUTTER variable if Flutter is installed elsewhere
set FLUTTER=%~dp0..\..\src\flutter\bin\flutter.bat
n
REM If flutter not found at above path, fallback to system PATH
echo Checking for flutter...
where flutter >nul 2>nul
if %errorlevel%==0 (
  set FLUTTER=flutter
) else (
  if exist "C:\src\flutter\bin\flutter.bat" (
    set FLUTTER=C:\src\flutter\bin\flutter.bat
  )
)
echo Using %FLUTTER%

echo Running flutter clean...
%FLUTTER% clean

echo Getting packages...
%FLUTTER% pub get

echo Building release APK (may take a few minutes)...
%FLUTTER% build apk --release

echo Build finished. APK will be under: build\app\outputs\flutter-apk\
echo If you want an App Bundle (recommended for Play Store):
echo %FLUTTER% build appbundle --release
echo.
echo To build a signed release, create a keystore and add signing config as explained in HOW_TO_BUILD_APK.md
echo.
pause
