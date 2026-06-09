# Godot MCP 内容与配置诊断

用于场景加载失败、资源引用/UID 异常、脚本结构问题、Autoload 或项目设置问题。

## 场景诊断

快速校验：
```json
{
  "scene": "res://scenes/main.tscn"
}
```
工具：`system_scene_validate`

深度分析：
```json
{
  "scene": "res://scenes/main.tscn"
}
```
工具：`system_scene_analyze`

场景树读取：
```json
{
  "action": "get_tree",
  "depth": 5,
  "include_internal": false
}
```
工具：`system_scene_tree`

## 资源引用审计

全项目：
```json
{
  "include_warnings": true
}
```
工具：`system_resource_reference_audit`

单文件：
```json
{
  "path": "res://scenes/main.tscn",
  "include_warnings": true
}
```
工具：`system_resource_reference_audit`

资源/UID 问题建议顺序：
1. `system_resource_reference_audit`
2. `system_project_files` → `scan`
3. 对相关资源 `reimport`
4. 再次审计

## 脚本分析

```json
{
  "script": "res://scripts/player.gd",
  "include_diagnostics": true
}
```
工具：`system_script_analyze`

说明：
- GDScript 诊断来自 Godot LSP。
- 第一次调用可能返回 pending。
- 诊断基于磁盘中已保存内容，不包含未保存编辑器缓冲。

## Autoload 配置

列出：
```json
{
  "action": "list_autoloads"
}
```
工具：`system_project_configure`

添加：
```json
{
  "action": "add_autoload",
  "name": "GameManager",
  "path": "res://scripts/game_manager.gd"
}
```
工具：`system_project_configure`

删除：
```json
{
  "action": "remove_autoload",
  "name": "GameManager"
}
```
工具：`system_project_configure`

## 项目设置

```json
{
  "action": "get_settings",
  "setting": "application/config/name"
}
```
工具：`system_project_configure`

## 文件系统刷新与重导入

扫描：
```json
{
  "action": "scan"
}
```
工具：`system_project_files`

重导入：
```json
{
  "action": "reimport",
  "paths": ["res://scenes/main.tscn"]
}
```
工具：`system_project_files`

## 常见流程

### 场景加载失败
1. `system_scene_validate`
2. `system_resource_reference_audit`
3. `system_editor_log`
4. `system_scene_analyze`

### Autoload 报错
1. `system_project_configure` → `list_autoloads`
2. 删除无效 autoload
3. 必要时重新添加正确 autoload
4. `system_project_state` 检查错误是否消失
