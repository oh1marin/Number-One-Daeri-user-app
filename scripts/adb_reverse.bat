@echo off
REM USB 연결된 실기기에서 PC 로컬 서버(5174) 접근용
set ADB=
if defined ANDROID_HOME set ADB=%ANDROID_HOME%\platform-tools\adb.exe
if not exist "%ADB%" set ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
if not exist "%ADB%" (
  echo adb not found. ANDROID_HOME or %LOCALAPPDATA%\Android\Sdk\platform-tools
  pause
  exit /b 1
)
"%ADB%" reverse tcp:5174 tcp:5174
if %errorlevel% equ 0 (
  echo adb reverse OK - device 127.0.0.1:5174 -^> PC :5174
) else (
  echo adb reverse FAIL - USB 연결 확인
  pause
)
