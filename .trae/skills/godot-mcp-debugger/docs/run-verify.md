# Godot MCP 运行与验证

用于修复后验证、运行项目、停止项目、等待运行时 marker、截图或发送运行时输入。

## 运行前原则

用户只是说“有报错”时，不要先运行或重启。先用错误诊断流程保留现场。

## 推荐：项目生命周期工具

启动主场景：
```json
{
  "action": "start"
}
```
工具：`system_project_lifecycle`

启动指定场景：
```json
{
  "action": "start",
  "scene": "res://scenes/main.tscn"
}
```
工具：`system_project_lifecycle`

停止运行：
```json
{
  "action": "stop"
}
```
工具：`system_project_lifecycle`

## Marker 验证

运行并等待结构化 runtime bridge marker：
```json
{
  "action": "start",
  "scene": "res://scenes/main.tscn",
  "success_markers": ["TEST_OK"],
  "failure_markers": ["TEST_FAIL", "ERROR"],
  "timeout_ms": 10000,
  "auto_stop": true
}
```
工具：`system_project_lifecycle`

注意：`background` / `minimized` / `no_focus` 当前不支持；请求这些参数会返回 `requires_foreground_window`。

## 兼容：场景运行工具

运行指定场景：
```json
{
  "action": "play_custom",
  "path": "res://scenes/main.tscn"
}
```
工具：`scene_run`

停止：
```json
{
  "action": "stop"
}
```
工具：`scene_run`

## Runtime control

要求存在可命令的运行时调试会话。

查看状态：
```json
{
  "action": "status"
}
```
工具：`runtime_control`

启用控制：
```json
{
  "action": "enable",
  "timeout_ms": 5000
}
```
工具：`runtime_control`

执行一步并截图：
```json
{
  "wait_frames": 1,
  "capture": true,
  "capture_label": "after_fix"
}
```
工具：`runtime_step`

截图：
```json
{
  "frame_count": 1,
  "capture_label": "runtime"
}
```
工具：`runtime_capture`

发送输入：
```json
{
  "inputs": [
    {"type": "action", "action": "ui_accept", "pressed": true},
    {"type": "action", "action": "ui_accept", "pressed": false}
  ]
}
```
工具：`runtime_input`

## 修改文件后的验证流程

1. 修改并保存文件。
2. 如 Godot 未识别外部修改，调用 `system_project_files` → `scan`。
3. 先静态验证场景/资源。
4. 需要运行验证时，用 `system_project_lifecycle` → `start`。
5. 用 `system_runtime_diagnose`、`system_editor_log`、`debug_runtime_bridge` 查看结果。
6. 用 `system_project_lifecycle` → `stop` 停止项目。
