@echo off
REM Import Encar quotidien depuis le PC (IP autorisee).
REM Encar bloque les IP serveur (407) depuis ~19/08/2026 -> l'import tourne ici.
REM Config (cle service_role) : %USERPROFILE%\.teranga\import_config.json
setlocal
set "SB_CONFIG=%USERPROFILE%\.teranga\import_config.json"
set "REPO=%~dp0.."
set "LOG=%USERPROFILE%\.teranga\import.log"
echo. >> "%LOG%"
echo ===== %DATE% %TIME% ===== >> "%LOG%"
"C:\Program Files\nodejs\node.exe" "%REPO%\tools\encar_import_local.js" 200 >> "%LOG%" 2>&1
endlocal
