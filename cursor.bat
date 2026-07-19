@echo off
setlocal enabledelayedexpansion

set "STORAGE_PATH=%APPDATA%\Cursor\User\globalStorage\storage.json"

:: Generate 64-hex machine IDs via PowerShell (SHA256 hash of GUIDs)
for /f %%i in ('powershell -c "[Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([guid]::NewGuid().ToByteArray())) | ForEach-Object { $_ -replace '[^a-f0-9]','' } | Select-Object -First 64"') do set "MACHINE_ID=%%i"
for /f %%i in ('powershell -c "[Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([guid]::NewGuid().ToByteArray())) | ForEach-Object { $_ -replace '[^a-f0-9]','' } | Select-Object -First 64"') do set "MAC_MACHINE_ID=%%i"

:: sqmId: Uppercase braced GUID
for /f %%i in ('powershell -c "(New-Guid).Guid.ToUpper() | ForEach-Object { '{{' + $_ + '}}' }"') do set "SQM_ID=%%i"

:: devDeviceId: Lowercase GUID
for /f %%i in ('powershell -c "(New-Guid).Guid.ToLower()"') do set "DEV_ID=%%i"

echo Generated:
echo   telemetry.machineId: !MACHINE_ID!
echo   telemetry.macMachineId: !MAC_MACHINE_ID!
echo   telemetry.sqmId: !SQM_ID!
echo   telemetry.devDeviceId: !DEV_ID!

:: Update storage.json - simple find/replace (assumes JSON allows; for robustness, use PowerShell JSON)
powershell -c "
$path = '%STORAGE_PATH%';
$content = Get-Content $path -Raw;
$content = $content -replace '\"telemetry\.machineId\" *: *\"[^\"]*\"', '\"telemetry.machineId\": \"!MACHINE_ID!\"';
$content = $content -replace '\"telemetry\.macMachineId\" *: *\"[^\"]*\"', '\"telemetry.macMachineId\": \"!MAC_MACHINE_ID!\"';
$content = $content -replace '\"telemetry\.sqmId\" *: *\"[^\"]*\"', '\"telemetry.sqmId\": \"!SQM_ID!\"';
$content = $content -replace '\"telemetry\.devDeviceId\" *: *\"[^\"]*\"', '\"telemetry.devDeviceId\": \"!DEV_ID!\"';
Set-Content $path $content -Encoding UTF8
"

echo Updated %STORAGE_PATH%.
echo.
set /p "DELETE_USER=Delete %APPDATA%\Cursor\User folder now? (y/n): "
if /i "!DELETE_USER!"=="y" (
    taskkill /f /im Cursor.exe >nul 2>&1
    rmdir /s /q "%APPDATA%\Cursor\User"
    echo User folder deleted. Restart Cursor.
) else (
    echo Skipping folder delete. Close Cursor manually, restart.
)
pause
