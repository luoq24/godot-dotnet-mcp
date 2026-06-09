# Godot MCP 高级调试

用于基础错误日志不足、需要 DAP、运行时会话、截图/输入、工具目录查询或编辑器 UI 证据时。

## 工具目录查询

不确定工具是否存在或参数如何调用时：
```json
{
  "action": "search",
  "query": "runtime errors",
  "visibility": "exposed"
}
```
工具：`system_tool_catalog`

MCP 暴露工具名一般为：`<category>_<tool>`，例如：
- `system_project_state`
- `debug_runtime_bridge`
- `dap_debugger`
- `runtime_control`

## Runtime bridge 能力边界

`debug_runtime_bridge` 能读取运行项目通过 MCP bridge 上报的结构化事件，也能读取调试会话状态。

不要假设它能完整读取所有 Godot Debugger 面板内部错误。看不到时应转向 Output、Godot 日志或 DAP。

常用调用：
```json
{
  "action": "get_summary"
}
```
工具：`debug_runtime_bridge`

```json
{
  "action": "get_errors_context",
  "limit": 20
}
```
工具：`debug_runtime_bridge`

```json
{
  "action": "get_sessions"
}
```
工具：`debug_runtime_bridge`

## DAP 调试器

`dap_debugger` 默认连接 `127.0.0.1:6006`。适合 GDScript DAP 调试；托管 C# 断点通常需要 .NET 调试器。

状态：
```json
{
  "action": "status"
}
```
工具：`dap_debugger`

标准会话顺序：
1. `initialize`
2. `launch` 或 `attach`
3. `configuration_done`
4. `threads` / `set_breakpoint` / `stack_trace` / `output`
5. `disconnect` 或 `terminate`

读取输出：
```json
{
  "action": "output",
  "include_raw": true,
  "timeout_ms": 5000
}
```
工具：`dap_debugger`

## 编辑器 UI 证据

需要确认面板或控件状态时，优先语义动作，再用截图。

可用 `system_editor_control`：
- `activate_ui`
- `capture_editor`
- `capture_control`
- `list_controls`
- `wait_for_ui`

纯文本模型无法可靠解析截图内容时，不要把截图作为首选诊断手段。

## MCP 内部日志

读取 MCP 内部 warning/error：
```json
{
  "action": "get_errors",
  "limit": 20
}
```
工具：`debug_log_buffer`

读取最近内部事件：
```json
{
  "action": "get_recent",
  "limit": 50
}
```
工具：`debug_log_buffer`
