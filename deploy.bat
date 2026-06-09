@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ==========================================
REM Godot .NET MCP - 部署脚本
REM 将本插件部署到目标 Godot 项目并编译 dotnet_bridge
REM 用法：双击运行或在终端中执行
REM ==========================================

REM ===== 请修改为目标 Godot 项目路径 =====
REM set TARGET_PROJECT=J:\Godot_Projects\forage-1\forage-demo
set TARGET_PROJECT=E:\godot_space\forage_1\forage-demo
REM ==========================================

set SOURCE_ADDON=%~dp0addons\godot_dotnet_mcp
set TARGET_ADDON=%TARGET_PROJECT%\addons\godot_dotnet_mcp

cls
echo ==========================================
echo  Godot .NET MCP 部署脚本
echo ==========================================
echo.
echo 源目录: %SOURCE_ADDON%
echo 目标项目: %TARGET_PROJECT%
echo.

REM ---- 检查源目录 ----
if not exist "%SOURCE_ADDON%" (
    echo [错误] 源插件目录不存在!
    echo        %SOURCE_ADDON%
    pause
    exit /b 1
)

REM ---- 检查目标项目目录 ----
if not exist "%TARGET_PROJECT%" (
    echo [错误] 目标项目目录不存在!
    echo        %TARGET_PROJECT%
    pause
    exit /b 1
)

REM ---- 备份 custom_tools（如果存在） ----
set CUSTOM_TOOLS_BACKUP=%TEMP%\godot_mcp_custom_tools_backup
if exist "%TARGET_ADDON%\custom_tools" (
    echo [信息] 检测到 custom_tools（用户自定义工具），正在备份...
    if exist "%CUSTOM_TOOLS_BACKUP%" rmdir /s /q "%CUSTOM_TOOLS_BACKUP%"
    xcopy /E /I "%TARGET_ADDON%\custom_tools" "%CUSTOM_TOOLS_BACKUP%" >nul
    if !errorlevel! geq 4 (
        echo [警告] custom_tools 备份失败，将继续执行
    ) else (
        echo [完成] custom_tools 已备份
    )
)

REM ---- 删除目标旧版插件（先删后拷，确保无残留文件） ----
echo [操作] 正在删除目标位置的旧版插件...
if exist "%TARGET_ADDON%" (
    rmdir /s /q "%TARGET_ADDON%"
    echo [完成] 旧版插件已删除
) else (
    echo [信息] 目标位置尚无插件，跳过删除
)

REM ---- 拷贝插件文件（排除 bin/obj 构建产物） ----
echo [操作] 正在拷贝插件文件（排除 bin/obj 目录）...
if not exist "%TARGET_ADDON%" mkdir "%TARGET_ADDON%"
robocopy "%SOURCE_ADDON%" "%TARGET_ADDON%" /E /XD bin obj /NDL /NFL /NJH /NJS >nul
if !errorlevel! geq 8 (
    echo [错误] 文件拷贝失败，请检查权限
    pause
    exit /b 1
)
echo [完成] 插件文件已拷贝
if exist "%CUSTOM_TOOLS_BACKUP%" (
    echo [信息] 正在恢复 custom_tools...
    if not exist "%TARGET_ADDON%\custom_tools" mkdir "%TARGET_ADDON%\custom_tools"
    xcopy /E /I /Y "%CUSTOM_TOOLS_BACKUP%" "%TARGET_ADDON%\custom_tools" >nul
    rmdir /s /q "%CUSTOM_TOOLS_BACKUP%"
    echo [完成] custom_tools 已恢复
)

REM ---- 编译 dotnet_bridge ----
echo [操作] 正在编译 dotnet_bridge...
cd /d "%TARGET_PROJECT%"
dotnet build "addons/godot_dotnet_mcp/dotnet_bridge/DotnetBridge.csproj"
if !errorlevel! neq 0 (
    echo [警告] dotnet_bridge 编译可能存在问题，请检查上方输出
    echo        如果目标项目不是 Godot .NET 项目，可忽略此警告
) else (
    echo [完成] dotnet_bridge 编译成功
)

echo.
echo ==========================================
echo  部署完成!
echo ==========================================
echo.
echo 下一步：
echo 1. 在 Godot 中执行 Project > Reload Current Project
echo 2. 或直接重启 Godot 编辑器
echo.
pause