---
name: godot-mcp-debugger
description: Godot MCP 调试入口和路由。Invoke when user needs to debug Godot projects, inspect errors, run verification, or choose focused guidance.
---

# Godot MCP 调试入口

这是轻量入口技能，只保留通用原则和按需文档路由。详细流程放在本技能目录下的普通 Markdown 文档中，不作为独立 Skill 暴露。

## 核心原则

用户说“有报错”时，不要先运行或重启项目。先保留现场并读取已有状态/日志。

基础定位顺序：
1. `system_project_state`
2. `system_runtime_diagnose`
3. `system_editor_log`
4. `debug_runtime_bridge`
5. 必要时 Godot 日志文件或 `dap_debugger`

## 当前工具命名规则

MCP 暴露工具名通常为：`<category>_<tool>`。

常见入口：
- `system_project_state`
- `system_runtime_diagnose`
- `system_editor_log`
- `system_project_lifecycle`
- `system_scene_validate`
- `system_script_analyze`
- `system_resource_reference_audit`
- `debug_runtime_bridge`
- `debug_dotnet`
- `dap_debugger`
- `runtime_control`

不确定工具名或参数时：
```json
{
  "action": "search",
  "query": "runtime errors",
  "visibility": "exposed"
}
```
工具：`system_tool_catalog`

## 按需读取文档

当任务需要更多细节时，读取本技能目录下对应文档：

- 报错、日志、编译失败：`docs/error-diagnosis.md`
- 运行、停止、修复后验证：`docs/run-verify.md`
- 场景、资源、脚本、配置问题：`docs/content-diagnosis.md`
- DAP、Runtime Bridge、工具目录、UI 证据：`docs/advanced-debug.md`

读取规则：
- 只读取当前任务需要的文档。
- 不要一次性读取全部文档，除非用户明确要求全面审查调试流程。
- 如果主流程已足够解决问题，不必读取子文档。

## 最小快速流程

当用户没有给出更具体方向时：

```json
{
  "summary": true,
  "include_runtime_health": true,
  "error_limit": 10
}
```
工具：`system_project_state`

若发现错误：
```json
{
  "include_gd_errors": true,
  "include_compile_errors": true,
  "tail": 50
}
```
工具：`system_runtime_diagnose`

随后根据错误类型读取对应文档。
