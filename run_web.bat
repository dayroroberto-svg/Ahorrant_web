@echo off
title Ahorrant Web - Aplicacion Financiera Gamificada (Version Web)

echo.
echo ==========================================
echo   Ahorrant Web - Finanzas Personales
echo ==========================================
echo.

REM Detectar comando flutter
set FLUTTER_CMD=flutter
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    if exist "C:\Users\%USERNAME%\develops\flutter_windows_3.47.9-stable\flutter\bin\flutter.bat" (
        set "FLUTTER_CMD=C:\Users\%USERNAME%\develops\flutter_windows_3.47.9-stable\flutter\bin\flutter.bat"
    ) else (
        echo ERROR: No se encontro Flutter en el PATH ni en la ruta por defecto.
        echo Asegurate de que Flutter este instalado y agregado al PATH del sistema.
        pause
        exit /b 1
    )
)

echo [1/4] Verificando dependencias...
call %FLUTTER_CMD% pub get

echo.
echo [2/4] Verificando archivos de SQLite para web...
if not exist "web\sqlite3.wasm" (
    echo Generando sqlite3.wasm y sqflite_sw.js...
    call dart run sqflite_common_ffi_web:setup
) else (
    echo OK - web\sqlite3.wasm ya existe.
)

echo.
echo [3/4] Compilando la version web...
call %FLUTTER_CMD% build web --release

echo.
echo [4/4] Resultado:
echo     %CD%\build\web
echo.
echo Para probarlo en el navegador ejecuta:  flutter run -d chrome
echo.

pause
