# Godot MCP 错误诊断

用于用户说“有报错”“Output/Debugger 有错误”“编译失败”“运行时报错”时。

## 首要原则

不要为了查看报错先重启项目。重启可能清空或覆盖当前现场。

优先顺序：
1. `system_project_state`
2. `system_runtime_diagnose`
3. `system_editor_log` 或 `debug_editor_log`
4. `debug_runtime_bridge`
5. Godot 日志文件
6. 必要时 `dap_debugger`

## 快速项目状态

```json
{
  "summary": true,
  "include_runtime_health": true,
  "error_limit": 10
}
```
工具：`system_project_state`

需要更完整信息：
```json
{
  "sections": ["summary", "project", "runtime", "capabilities", "health"],
  "error_limit": 20
}
```
工具：`system_project_state`

## 获取错误详情

```json
{
  "include_gd_errors": true,
  "include_compile_errors": true,
  "include_performance": false,
  "tail": 50
}
```
工具：`system_runtime_diagnose`

说明：
- `include_gd_errors: true` 读取 Output 面板中的 GDScript 错误/警告。
- 这不保证覆盖全部 Debugger 面板内部错误。

## Output 面板

读取错误：
```json
{
  "action": "get_errors",
  "limit": 50,
  "include_warnings": true
}
```
工具：`system_editor_log`

读取全部输出：
```json
{
  "action": "get_output",
  "limit": 100
}
```
工具：`system_editor_log`

清空 Output：
```json
{
  "action": "clear_output"
}
```
工具：`system_editor_log`

原子调试工具也可用：`debug_editor_log`，但清空动作名是 `clear`。

## Runtime bridge

摘要：
```json
{
  "action": "get_summary"
}
```
工具：`debug_runtime_bridge`

错误上下文：
```json
{
  "action": "get_errors_context",
  "limit": 20
}
```
工具：`debug_runtime_bridge`

最近事件：
```json
{
  "action": "get_recent",
  "limit": 50
}
```
工具：`debug_runtime_bridge`

调试会话：
```json
{
  "action": "get_sessions"
}
```
工具：`debug_runtime_bridge`

## Godot 日志文件

优先尝试：
```json
{
  "action": "read_file",
  "path": "user://logs/godot.log"
}
```
工具：`system_project_files`

若失败，在 Windows 检查：`%APPDATA%/Godot/app_userdata/<project_name>/logs/`。

## Debugger 面板有错但文字工具看不到

按顺序：
1. `system_runtime_diagnose`
2. `system_editor_log`
3. `debug_runtime_bridge` 的 `get_summary` / `get_errors_context` / `get_sessions`
4. Godot 日志文件
5. `dap_debugger`
6. 仅需 UI 证据时再用 `system_editor_control` 截图；纯文本模型不要把截图作为首选诊断手段。

## C# 编译错误

1. `system_runtime_diagnose` 查看 `compile_errors`
2. 必要时 `debug_dotnet` → `restore`
3. `debug_dotnet` → `build`

```json
{
  "action": "build",
  "path": "res://YourGame.csproj",
  "timeout_sec": 45
}
```
工具：`debug_dotnet`
