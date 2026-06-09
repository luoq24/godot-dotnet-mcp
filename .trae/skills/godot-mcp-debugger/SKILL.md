---
name: godot-mcp-debugger
description: 使用 Godot .NET MCP 插件进行项目调试 - 查看报错、分析问题、运行项目。Invoke when user needs to debug Godot project, view errors, or diagnose issues.
---

# Godot MCP 调试技能
专门用于使用 Godot .NET MCP 插件调试 Godot 项目的技能。

## 调试核心原则

### 不要重启场景来查看报错！
**当用户说有报错时，绝不应该运行 `system_project_run` 来重启场景。**
重启场景会：
- 清除当前运行时的报错状态
- 导致无法复现用户遇到的问题
- 浪费调试时间

**正确的做法：**
1. 先使用 `system_runtime_diagnose`（设置 `include_gd_errors: true`）查看当前运行时的报错
2. 如果 MCP 工具看不到，检查 Godot 日志文件（`%APPDATA%/Godot/app_userdata/<project>/logs/`）
3. 只有在**已修复错误、需要验证验证**时，才使用 `system_project_run` 重启场景

## Godot 错误来源的本质区别（关键！）

Godot 编辑器中存在**三种完全不同的错误来源**，MCP 工具对它们的覆盖能力差异极大。

| 错误来源 | 显示位置 | MCP 能否直接读取 | 对应工具 |
|---------|---------|-----------------|---------|
| **LSP 静态诊断** | 脚本编辑器左侧小红叉 | 能 | `system_runtime_diagnose` (gd_errors) |
| **Output 面板输出** | 底部 Output / 终端 | 能 | `system_editor_log` |
| **Debugger 面板运行时错误** | 底部 Debugger > Errors | **不能直接读取** | 需截图或 DAP |

### 为什么 Debugger 面板的错误 MCP 看不到？
- `system_runtime_diagnose` 的 `gd_errors` 来自 **Godot LSP 静态分析**，不是运行时的 Debugger 错误
- `system_editor_log` 读取的是 **Output 面板**，Debugger 面板的错误通常不走 Output 通道
- `runtime_bridge` 只能捕获项目中通过 `MCPRuntimeBridge` autoload **显式上报**的消息
- Godot 标准的运行时错误（null instance、方法不存在等）通过**内部调试协议**传输，**没有公开 API** 供 EditorPlugin 直接读取

**结论：当用户明确说"Debugger 面板有 N 条错误"时，文字工具大概率看不到，必须启用截图或 DAP 方案。**

## 核心调试功能

### 1. 查看报错信息

#### 方法一：使用 `system_runtime_diagnose`（查看 LSP 静态错误 + 编译错误）
```json
{
  "include_gd_errors": true,
  "tail": 50,
  "include_compile_errors": true,
  "include_performance": false
}
```
- **必须设置** `include_gd_errors: true` 才能看到 LSP 静态诊断错误
- **注意：** 这看不到 Debugger 面板的运行时错误

#### 方法二：使用 `system_editor_log`（查看 Output 面板）
```json
{
  "action": "get_errors",
  "limit": 50,
  "include_warnings": true
}
```
- 读取编辑器 Output 面板的 `print()` / `push_error()` / `push_warning()` 输出
- Debugger 面板的内部错误通常不会出现在这里

#### 方法三：使用 `system_project_state`（快速检查项目状态）
```json
{
  "error_limit": 20,
  "include_runtime_health": true
}
```

---

### 2. Debugger 面板错误的专门诊断路径（重要！）

当用户明确说 "Debugger 中有 N 条错误" 而上述文字工具看不到时，按以下顺序操作。

**核心原则：优先文字手段，避免对无视觉能力的 LLM 使用截图。**

#### 步骤 1：读取 Godot 日志文件（最可靠，优先）
Godot 引擎原生将所有运行时错误写入日志文件，不依赖任何插件状态。
路径规律：
- Windows: `%APPDATA%/Godot/app_userdata/<project_name>/logs/godot.log`
- 项目目录下也可能存在日志

可以通过 `system_project_files` 读取：
```json
{
  "action": "read_file",
  "path": "user://logs/godot.log"
}
```

如果没有 `user://` 写入权限，或需要找磁盘路径，先通过 `system_project_state` 获取 `project_name`，再拼接 `%APPDATA%/Godot/app_userdata/<project_name>/logs/` 路径。

#### 步骤 2：检查 runtime_bridge（轻量备选）
`runtime_bridge` 只能捕获通过 `MCPRuntimeBridge` autoload 显式上报的错误。先确认是否安装，避免无效查询：

```json
{
  "action": "get_summary"
}
```
工具：`runtime_bridge`

如果 `bridge_status.installed == true`，再查错误：
```json
{
  "action": "get_errors",
  "limit": 20
}
```

**注意：** 如果 `installed == false`，直接跳过此步骤。

#### 步骤 3：使用 DAP 调试器（重备选）
DAP 需要完整的调试会话握手（initialize → launch/attach → configuration_done），较重且不一定能捕获所有运行时错误。仅在日志和 runtime_bridge 都无效时尝试：
```json
{
  "action": "output",
  "include_raw": true,
  "timeout_ms": 5000
}
```
工具：`dap_debugger`

#### 关于截图
如果用户（或具有视觉能力的工具）需要直接查看 Debugger 面板外观，可以使用 `system_editor_control` 的 `activate_ui` + `capture_control` 截图。
**但对于纯文字 LLM，截图无法解析内容，不应作为诊断路径的正式步骤。**

---

### 3. 运行和停止项目
#### 运行项目
```json
{
  "scene": "res://scenes/main.tscn"
}
```

#### 停止项目
```json
{}
```

### 4. 场景验证和分析
#### 验证场景是否有问题
```json
{
  "scene": "res://scenes/main.tscn"
}
```

#### 深入分析场景
```json
{
  "scene": "res://scenes/main.tscn"
}
```

#### 场景树操作
```json
{
  "action": "get_tree",
  "scene": "res://scenes/main.tscn"
}
```

### 5. 项目配置检查
#### 检查 Autoload 配置
```json
{
  "action": "list_autoloads"
}
```

#### 添加 Autoload
```json
{
  "action": "add_autoload",
  "name": "MySingleton",
  "path": "res://scripts/my_singleton.gd"
}
```

#### 删除 Autoload
```json
{
  "action": "remove_autoload",
  "name": "MySingleton"
}
```

#### 检查项目设置
```json
{
  "action": "get_settings",
  "setting": "application/config/name"
}
```

### 6. 资源引用检查
#### 全局资源引用审计
```json
{
  "include_warnings": true
}
```

#### 特定场景/资源的引用检查
```json
{
  "path": "res://scenes/main.tscn",
  "include_warnings": true
}
```

### 7. 脚本分析

#### 分析 GDScript 或 C# 脚本
```json
{
  "script": "res://scripts/main.gd",
  "include_diagnostics": true
}
```

### 8. 编辑器状态和控制

#### 获取编辑器当前状态
```json
{}
```

#### 获取编辑器输出
```json
{
  "action": "get_output",
  "limit": 100
}
```

#### 清空编辑器输出
```json
{
  "action": "clear"
}
```

## 常见问题排查

### 问题 1：用户说 Debugger 面板有错误，但 MCP 文字工具看不到
**原因：** Debugger 面板的运行时错误通过 Godot 内部调试协议传输，EditorPlugin 没有公开 API 直接读取。
**解决方案（按优先级）：**
1. **读取 Godot 日志文件**（最可靠）：`system_project_files` → `action: read_file`，路径 `user://logs/godot.log` 或 `%APPDATA%/Godot/app_userdata/<project_name>/logs/godot.log`
2. **检查 Output 面板**：`system_editor_log` → `action: get_errors`
3. **检查 runtime_bridge**：先 `get_summary` 确认 `bridge_status.installed == true`，再 `get_errors`
4. **尝试 DAP**：`dap_debugger` → `action: output`（较重，需 DAP 会话）
5. **截图（仅人类辅助）**：如果上述手段都无效，可使用 `system_editor_control` 截图 Debugger 面板供人类查看

### 问题 2：Autoload 配置报错
**症状：** "Unrecognized UID" 或 "Failed to create an autoload"
**排查：**
1. 先使用 `system_project_configure` 列出 autoloads
2. 删除无效的 autoload
3. 让插件重新自动配置正确的 autoload

### 问题 3：场景加载失败
**排查流程：**
1. 用 `system_scene_validate` 验证场景
2. 用 `system_resource_reference_audit` 检查资源引用
3. 查看编辑器输出获取详细错误
4. 用 `system_scene_analyze` 深入分析场景结构

### 问题 4：资源引用丢失
**症状：** "Resource not found" 或 "UID invalid"
**排查：**
1. 使用 `system_resource_reference_audit` 进行全项目扫描
2. 检查资源路径是否正确
3. 验证资源是否存在

### 问题 5：编译错误
**排查：**
1. 使用 `system_runtime_diagnose`，确保 `include_compile_errors: true`
2. 查看 `compile_errors` 字段获取详细编译错误
3. 检查相关脚本文件

## 调试工具使用建议

| 任务 | 优先工具 | 备选工具 |
|------|----------|----------|
| 查看 LSP 静态错误 | `system_runtime_diagnose` (include_gd_errors=true) | - |
| 查看 Output 面板 | `system_editor_log` | - |
| **查看 Debugger 面板错误** | **截图 `system_editor_control`** | `dap_debugger` output |
| 项目健康检查 | `system_project_state` | - |
| 运行项目 | `system_project_run` | - |
| 场景问题 | `system_scene_validate` → `system_scene_analyze` → `system_scene_tree` | - |
| 资源问题 | `system_resource_reference_audit` | - |
| 配置检查 | `system_project_configure` (list_autoloads) | - |
| 脚本问题 | `system_script_analyze` | `system_bindings_audit` |
| 编辑器状态 | `system_editor_state` | `system_editor_log` |

## 快速参考 - 最少必需参数

### 查看 LSP 静态错误（最少）
```json
{
  "include_gd_errors": true,
  "tail": 20
}
```

### 查看 Output 面板错误（最少）
```json
{
  "action": "get_errors",
  "limit": 30
}
```

### 检查项目状态（最少）
```json
{
  "error_limit": 10,
  "include_runtime_health": true
}
```

### 验证场景（最少）
```json
{
  "scene": "res://scenes/main.tscn"
}
```

### 读取 Godot 日志文件（最少）
```json
{
  "action": "read_file",
  "path": "user://logs/godot.log"
}
```
如果 `user://` 路径不可用，使用 `system_project_state` 获取 `project_name`，再读取 `%APPDATA%/Godot/app_userdata/<project_name>/logs/godot.log`。

### 扫描文件系统（检测外部修改）
```json
{
  "action": "scan"
}
```

### 重载资源
```json
{
  "action": "reload",
  "path": "res://scenes/main.tscn"
}
```

### 重载场景
```json
{
  "action": "reload"
}
```

## 标准调试流程模板

当用户遇到问题时，按以下步骤操作：
1. **首先检查项目状态** - 使用 `system_project_state`
2. **区分错误来源**：
   - 用户说"脚本有红叉" → `system_runtime_diagnose` (include_gd_errors=true)
   - 用户说"Output 有报错" → `system_editor_log`
   - 用户说"Debugger 有报错" → **读取 Godot 日志文件** (`system_project_files` → `read_file` → `user://logs/godot.log`)
3. **根据问题类型深入分析**：
   - 场景问题 → 验证、分析场景
   - 资源问题 → 资源引用审计
   - 脚本问题 → 脚本分析
   - 配置问题 → 项目配置检查
4. **提供修复方案**

## 修改文件后运行场景的标准工作流程

1. 修改文件
2. 保存文件（Godot 会自动重载）
3. 如需手动重载：`system_project_files` → `action: reload`
4. 运行场景验证：`system_project_run`
5. 查看结果：按错误来源选择对应工具