# Flow.Launcher.Plugin.Template
## 特性
- .net 8.0
- Claude Code commands
  - check_log.md 检查Flow Launcher的log文件
  - debug.md 编译并安装插件到Flow Launcher
- Github Actions
  - build dotnet.yml 编译插件
  - publish.yml 发布插件

## 使用方法
- 执行
  ```powershell
  ./CreatePlugin.ps1 -Name "TemplatePlugin" -Author "TemplateAuthor" -Description "TemplateDescription" -Keyword "TemplateKeyword"
  ```

- 从output获得生成后的插件工程