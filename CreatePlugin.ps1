# 功能说明：复制 Flow.Launcher.Plugin.Template 到新目录 Flow.Launcher.Plugin.<Name>，并替换占位符（TemplateID 为 32 位随机十六进制小写）

param(
    [string]$Name,
    [string]$Author,
    [string]$Description,
    [string]$Keyword
)

# 未传参时友好提示输入
if (-not $Name) { $Name = Read-Host "请输入插件名称 (如 MyPlugin)" }
if (-not $Author) { $Author = Read-Host "请输入作者" }
if (-not $Description) { $Description = Read-Host "请输入插件描述" }
if (-not $Keyword) { $Keyword = Read-Host "请输入触发关键词 (在 Flow Launcher 中输入的缩写)" }

$Name = $Name.Trim()
$Author = $Author.Trim()
$Description = $Description.Trim()
$Keyword = $Keyword.Trim()

if ([string]::IsNullOrWhiteSpace($Name))   { Write-Error "插件名称不能为空" }
if ([string]::IsNullOrWhiteSpace($Author)) { Write-Error "作者不能为空" }
if ([string]::IsNullOrWhiteSpace($Description)) { Write-Error "插件描述不能为空" }
if ([string]::IsNullOrWhiteSpace($Keyword)) { Write-Error "触发关键词不能为空" }

$ErrorActionPreference = "Stop"
trap {
    Write-Host "命令行被中止: $_" -ForegroundColor Red
    Write-Host "$($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "$($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    Read-Host "按 Enter 键关闭窗口"
    break
}

# 生成 32 位随机 ID：十六进制，小写字母 (0-9, a-f)
$idChars = [char[]]((48..57) + (97..102))
$NewID = -join (1..32 | ForEach-Object { $idChars | Get-Random })

$TemplateDir = Join-Path $PSScriptRoot "Flow.Launcher.Plugin.Template"
$OutputRoot = Join-Path $PSScriptRoot "output"
$TargetDir = Join-Path $OutputRoot "Flow.Launcher.Plugin.$Name"

if (-not (Test-Path $TemplateDir)) {
    Write-Error "模板目录不存在: $TemplateDir"
}
if (Test-Path $TargetDir) {
    Write-Error "目标目录已存在，请先删除或改用其他名称: $TargetDir"
}

if (-not (Test-Path $OutputRoot)) {
    New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null
}

# 复制模板目录下所有文件到新目录
Write-Host "复制模板到: $TargetDir" -ForegroundColor Yellow
Copy-Item -Path $TemplateDir -Destination $TargetDir -Recurse -Force
$PluginDir = $TargetDir

$Replacements = @{
    'TemplateID'         = $NewID
    'TemplatePlugin'     = $Name
    'TemplateAuthor'     = $Author
    'TemplateDescription' = $Description
    'TemplateKeyword'    = $Keyword
}

$TextExtensions = @('.json', '.md', '.cs', '.csproj', '.ps1', '.yml')
$AllFiles = Get-ChildItem -Path $PluginDir -Recurse -File | Where-Object {
    $_.Extension -in $TextExtensions -and $_.Name -ne 'CreatePlugin.ps1'
}

foreach ($file in $AllFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $changed = $false
    foreach ($key in $Replacements.Keys) {
        if ($content -match [regex]::Escape($key)) {
            $content = $content.Replace($key, $Replacements[$key])
            $changed = $true
        }
    }
    if ($changed) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.UTF8Encoding]::new($true))
        Write-Host "已更新: $($file.FullName)" -ForegroundColor Green
    }
}

# 重命名 .csproj：Flow.Launcher.Plugin.TemplatePlugin.csproj -> Flow.Launcher.Plugin.<Name>.csproj
$OldCsproj = Join-Path $PluginDir "Flow.Launcher.Plugin.TemplatePlugin.csproj"
$NewCsproj = Join-Path $PluginDir "Flow.Launcher.Plugin.$Name.csproj"
if (Test-Path $OldCsproj) {
    if (Test-Path $NewCsproj) {
        Write-Warning "目标已存在，跳过重命名: $NewCsproj"
    } else {
        Rename-Item -Path $OldCsproj -NewName "Flow.Launcher.Plugin.$Name.csproj"
        Write-Host "已重命名: $OldCsproj -> Flow.Launcher.Plugin.$Name.csproj" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "完成。Plugin ID (32 位十六进制): $NewID" -ForegroundColor Cyan
Write-Host "插件名称: $Name | 作者: $Author | 关键词: $Keyword" -ForegroundColor Cyan
Write-Host "新项目目录: $TargetDir" -ForegroundColor Cyan
