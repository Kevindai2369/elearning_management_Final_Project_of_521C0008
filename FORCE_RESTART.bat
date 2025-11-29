@echo off
echo ========================================
echo FORCE RESTART FLUTTER APP
echo ========================================
echo.

echo [1/5] Stopping all Flutter/Dart processes...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM dartaotruntime.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
echo Done!
echo.

echo [2/5] Cleaning build cache...
flutter clean
echo Done!
echo.

echo [3/5] Getting dependencies...
flutter pub get
echo Done!
echo.

echo [4/5] Starting app on Chrome...
echo Please wait...
start cmd /k "flutter run -d chrome"
echo.

echo [5/5] Complete!
echo ========================================
echo NEXT STEPS:
echo 1. Wait for app to load (30 seconds)
echo 2. Refresh browser (F5)
echo 3. Test file picker
echo ========================================
pause
