---
name: "MCP-programer"
description: "Provides guidelines for modifying the godot-dotnet-mcp project to ensure changes take effect smoothly. Invoke when user wants to modify GDScript/C# files in this project or deploy changes to a target Godot project."
---

# MCP-programer

本技能记录了修改 `godot-dotnet-mcp` 项目时的关键经验和最佳实践，确保修改能够顺利生效。

## 项目结构

- **项目根目录**: 当前工作区中的 `godot-dotnet-mcp` 仓库根目录
- **源代码位置**: `<godot-dotnet-mcp>/addons/godot_dotnet_mcp/`
- **部署目标**: 通过 `deploy.bat` 部署到目标 Godot 项目；目标路径以脚本配置或用户当前环境为准
- **部署脚本**: `<godot-dotnet-mcp>/deploy.bat`

## 修改代码后的标准流程

### AI 执行的步骤
#### 1. 修改源代码
在当前工作区的 `godot-dotnet-mcp` 仓库下修改源文件。
### 用户手动执行的步骤
> **注意**：以下步骤需要用户手动操作，AI 无法直接完成。
#### 2. 运行 deploy.bat 部署
在文件资源管理器中双击运行 `deploy.bat`，或在终端中执行：
```batch
.\deploy.bat
```
部署脚本会：
- 备份目标项目的 `custom_tools`
- 删除目标位置的旧版插件
- 拷贝新版插件文件（排除 bin/obj）
- 恢复 `custom_tools`
- 编译 `dotnet_bridge`

#### 3. 使修改生效
在 Godot 编辑器的 MCP 面板中点击 **"Reload Plugin"** 按钮。

如果 Reload Plugin 后仍然报错，建议：
1. 完全关闭 Godot 编辑器
2. 删除目标项目的 `.godot` 缓存目录
3. 重新打开 Godot 编辑器

## GDScript 语法注意事项

本项目使用 Godot 4.6，修改 GDScript 时需要特别注意以下语法限制：

### 禁止的语法
1. **`not` 不能用于 `Array` 类型**
   ```gdscript
   # 非法！会导致脚本编译失败
   if not _my_array:
       _my_array = []
   
   # 正确写法
   if _my_array.size() == 0:
       _my_array = []
   # 或直接使用（变量声明时已初始化）
   _my_array.append(item)
   ```

2. **Lambda 匿名函数谨慎使用**
   ```gdscript
   # 可能有问题（取决于 Godot 版本和上下文）
   array.sort_custom(func(a, b): return a < b)
   
   # 更安全的写法：使用普通类方法
   array.sort_custom(_compare_items)
   
   func _compare_items(a, b) -> bool:
       return a < b
   ```

3. **`await` 在 `RefCounted` 中的限制**
   `RefCounted` 脚本中不能直接使用 `get_tree().process_frame`，因为没有场景树访问权限。

### 推荐的语法
- 使用显式的 `.size() == 0` 或 `.is_empty()` 检查数组/字典为空
- 使用普通方法代替 lambda 进行排序和过滤
- 在需要延迟操作时，通过回调或信号机制实现，而非 `await`

## 调试技巧

### 验证文件已正确部署
```powershell
# 将 <target-godot-project> 替换为当前目标 Godot 项目路径
Select-String -Path "<target-godot-project>\addons\godot_dotnet_mcp\plugin\runtime\*.gd" -Pattern "if not _.*:"
```

### 检查 Godot 编译缓存
如果修改后仍然报错旧错误，可能是 `.godot` 目录缓存了旧编译结果：
- 删除目标项目的 `.godot` 目录
- 重启 Godot 编辑器

### 查看运行时错误
通过 MCP 工具获取详细错误信息：
```json
{
  "include_gd_errors": true,
  "tail": 50,
  "include_compile_errors": true
}
```

## 最小修改原则
- 只修改必要的内容
- 避免引入复杂的语法特性
- 每次修改后先验证基本功能正常，再添加新功能
- 优先使用 Godot 官方文档确认语法兼容性

## 常见报错及解决
| 报错 | 原因 | 解决 |
|------|------|------|
| `Invalid call. Nonexistent function 'new' in base 'GDScript'` | 某个脚本编译失败，导致预加载为无效状态 | 检查该脚本及其依赖的脚本是否有语法错误 |
| `Invalid call. Nonexistent function 'xxx' in base 'Nil'` | 服务对象为 null，通常因为初始化脚本失败 | 检查服务对象是否正确初始化 |
| 连接数无限增长 | HTTP 响应头使用 `Connection: keep-alive` | 改为 `Connection: close` |