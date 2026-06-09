@echo off
setlocal enabledelayedexpansion

REM ==========================================
REM Godot .NET MCP - Deploy script
REM Deploy this addon to the target Godot project and build dotnet_bridge
REM Usage: double click this file or run .\deploy.bat in terminal
REM ==========================================

REM ===== Change this to your target Godot project path =====
REM set TARGET_PROJECT=J:\Godot_Projects\forage-1\forage-demo
set TARGET_PROJECT=E:\godot_space\forage_1\forage-demo
REM ==========================================

set SOURCE_ADDON=%~dp0addons\godot_dotnet_mcp
set TARGET_ADDON=%TARGET_PROJECT%\addons\godot_dotnet_mcp

cls
echo ==========================================
echo  Godot .NET MCP deploy script
echo ==========================================
echo.
echo Source: %SOURCE_ADDON%
echo Target: %TARGET_PROJECT%
echo.

REM ---- Check source directory ----
if not exist "%SOURCE_ADDON%" (
    echo [ERROR] Source addon directory does not exist.
    echo        %SOURCE_ADDON%
    pause
    exit /b 1
)

REM ---- Check target project directory ----
if not exist "%TARGET_PROJECT%" (
    echo [ERROR] Target project directory does not exist.
    echo        %TARGET_PROJECT%
    pause
    exit /b 1
)

REM ---- Back up custom_tools if it exists ----
set CUSTOM_TOOLS_BACKUP=%TEMP%\godot_mcp_custom_tools_backup
if exist "%TARGET_ADDON%\custom_tools" (
    echo [INFO] Backing up custom_tools...
    if exist "%CUSTOM_TOOLS_BACKUP%" rmdir /s /q "%CUSTOM_TOOLS_BACKUP%"
    xcopy /E /I "%TARGET_ADDON%\custom_tools" "%CUSTOM_TOOLS_BACKUP%" >nul
    if !errorlevel! geq 4 (
        echo [WARN] Failed to back up custom_tools. Continuing...
    ) else (
        echo [OK] custom_tools backed up.
    )
)

REM ---- Delete old target addon first to avoid stale files ----
echo [STEP] Removing old target addon...
if exist "%TARGET_ADDON%" (
    rmdir /s /q "%TARGET_ADDON%"
    echo [OK] Old addon removed.
) else (
    echo [INFO] No existing addon found. Skipping removal.
)

REM ---- Copy addon files, excluding bin and obj ----
echo [STEP] Copying addon files, excluding bin and obj...
robocopy "%SOURCE_ADDON%" "%TARGET_ADDON%" /E /XD bin obj /NDL /NFL /NJH /NJS >nul
if !errorlevel! geq 8 (
    echo [ERROR] File copy failed. Please check permissions.
    pause
    exit /b 1
)
echo [OK] Addon files copied.
if exist "%CUSTOM_TOOLS_BACKUP%" (
    echo [INFO] Restoring custom_tools...
    if not exist "%TARGET_ADDON%\custom_tools" mkdir "%TARGET_ADDON%\custom_tools"
    xcopy /E /I /Y "%CUSTOM_TOOLS_BACKUP%" "%TARGET_ADDON%\custom_tools" >nul
    rmdir /s /q "%CUSTOM_TOOLS_BACKUP%"
    echo [OK] custom_tools restored.
)

REM ---- Build dotnet_bridge ----
echo [STEP] Building dotnet_bridge...
cd /d "%TARGET_PROJECT%"
dotnet build "addons/godot_dotnet_mcp/dotnet_bridge/DotnetBridge.csproj"
if !errorlevel! neq 0 (
    echo [WARN] dotnet_bridge build may have issues. Check the output above.
    echo        If the target project is not a Godot .NET project, this warning can be ignored.
) else (
    echo [OK] dotnet_bridge build succeeded.
)

echo.
echo ==========================================
echo  Deploy complete.
echo ==========================================
echo.
echo Next steps:
echo 1. In Godot, run Project ^> Reload Current Project
echo 2. Or restart the Godot editor
echo.
pause
