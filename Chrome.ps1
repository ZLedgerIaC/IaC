# -----------------------------------------------------------
# 脚本名称: Firefox 独立调试环境生成器
# 功能: 创建 F01-F16 共16个独立无痕 Firefox 快捷方式
# 原理: 使用 -profile 参数绕过配置管理器，直接指定物理路径
# -----------------------------------------------------------

# 1. 动态查找 Firefox 安装路径
$PossiblePaths = @(
    "${env:ProgramFiles}\Mozilla Firefox\firefox.exe",
    "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe",
    "$env:LOCALAPPDATA\Mozilla Firefox\firefox.exe"
)

$TargetFirefoxPath = $null
foreach ($path in $PossiblePaths) {
    if (Test-Path -Path $path) {
        $TargetFirefoxPath = $path
        break
    }
}

if (-not $TargetFirefoxPath) {
    Write-Error "严重错误：未在标准安装路径中找到 Firefox。请手动修改脚本中的 `$TargetFirefoxPath。"
    exit
}
Write-Host "检测到 Firefox 路径: $TargetFirefoxPath" -ForegroundColor Cyan

# 2. 获取桌面路径
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')

# 3. 配置数据存储的基础目录 (注意：Firefox 和 Chrome 分开存放)
$BaseDataDir = "$env:USERPROFILE\Firefox_Isolated_Profiles"

# 确保数据目录存在
if (-not (Test-Path -Path $BaseDataDir)) {
    New-Item -ItemType Directory -Force -Path $BaseDataDir | Out-Null
}

# 4. 创建 WScript Shell 对象
$WshShell = New-Object -ComObject WScript.Shell

Write-Host "正在创建 Firefox 调试环境快捷方式 (F01 - F16)..." -ForegroundColor Cyan

# 循环创建 16 个快捷方式
for ($i = 1; $i -le 16; $i++) {
    # 格式化数字 (01, 02... 16)
    $IdStr = $i.ToString("00")
    
    # 定义数据目录
    $InstanceDir = "$BaseDataDir\Session_$IdStr"
    
    # 自动创建目录 (Firefox 有时对完全不存在的父目录敏感，预创建更稳妥)
    if (-not (Test-Path -Path $InstanceDir)) {
        New-Item -ItemType Directory -Force -Path $InstanceDir | Out-Null
    }

    # 定义快捷方式名称 (F01.lnk)
    $ShortcutName = "F$IdStr"
    $ShortcutFile = "$DesktopPath\$ShortcutName.lnk"
    
    try {
        $Shortcut = $WshShell.CreateShortcut($ShortcutFile)
        
        # 设置目标
        $Shortcut.TargetPath = $TargetFirefoxPath
        
        # 设置关键参数:
        # -no-remote      : 允许同时运行多个独立实例 (核心参数)
        # -profile "Path" : 指定配置文件夹路径 (替代 GUI 创建)
        # -private-window : 启动时进入隐私模式
        $Shortcut.Arguments = "-no-remote -private-window -profile ""$InstanceDir"""
        
        # 设置描述
        $Shortcut.Description = "Firefox Debug Session $IdStr"
        $Shortcut.IconLocation = "$TargetFirefoxPath,0"
        
        # 保存
        $Shortcut.Save()
        
        Write-Host "[$IdStr/16] Created: $ShortcutName" -ForegroundColor Green
    }
    catch {
        Write-Error "[$IdStr/16] Failed: $_"
    }
}

Write-Host "`n全部完成。Firefox 配置目录: $BaseDataDir" -ForegroundColor Gray


# -----------------------------------------------------------
# 脚本名称: Chrome 独立调试环境生成器 (精简版)
# 功能: 创建 C01-C16 共16个独立无痕 Chrome 快捷方式
# -----------------------------------------------------------

# 1. 动态查找 Chrome 安装路径 (优先查找 Program Files，其次查找 AppData)
$PossiblePaths = @(
    "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)

$TargetChromePath = $null
foreach ($path in $PossiblePaths) {
    if (Test-Path -Path $path) {
        $TargetChromePath = $path
        break
    }
}

# 如果找不到 Chrome，报错退出
if (-not $TargetChromePath) {
    Write-Error "严重错误：未在标准安装路径中找到 Google Chrome。请手动修改脚本中的 `$TargetChromePath。"
    exit
}
Write-Host "检测到 Chrome 路径: $TargetChromePath" -ForegroundColor Cyan

# 2. 获取桌面路径
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')

# 3. 配置数据存储的基础目录
$BaseDataDir = "$env:USERPROFILE\Chrome_Isolated_Profiles"

# 确保数据目录存在
if (-not (Test-Path -Path $BaseDataDir)) {
    New-Item -ItemType Directory -Force -Path $BaseDataDir | Out-Null
}

# 4. 创建 WScript Shell 对象
$WshShell = New-Object -ComObject WScript.Shell

Write-Host "正在创建调试环境快捷方式 (C01 - C16)..." -ForegroundColor Cyan

# 循环创建 16 个快捷方式
for ($i = 1; $i -le 16; $i++) {
    # 格式化数字为两位数 (01, 02, ... 16)
    $IdStr = $i.ToString("00")
    
    # 定义数据目录 (Session_01, Session_02...)
    $InstanceDir = "$BaseDataDir\Session_$IdStr"
    
    # 定义精简的快捷方式名称 (C01.lnk, C02.lnk...)
    $ShortcutName = "C$IdStr"
    $ShortcutFile = "$DesktopPath\$ShortcutName.lnk"
    
    try {
        $Shortcut = $WshShell.CreateShortcut($ShortcutFile)
        
        # 设置目标
        $Shortcut.TargetPath = $TargetChromePath
        
        # 设置参数: 
        # --incognito : 无痕模式
        # --user-data-dir : 指定独立的用户配置文件夹
        # --no-first-run : 跳过首次运行向导
        $Shortcut.Arguments = "--incognito --no-first-run --user-data-dir=""$InstanceDir"""
        
        # 设置描述 (鼠标悬停时显示)
        $Shortcut.Description = "Chrome Debug Session $IdStr"
        $Shortcut.IconLocation = "$TargetChromePath,0"
        
        # 保存
        $Shortcut.Save()
        
        Write-Host "[$IdStr/16] Created: $ShortcutName" -ForegroundColor Green
    }
    catch {
        Write-Error "[$IdStr/16] Failed: $_"
    }
}

Write-Host "`n全部完成。配置目录: $BaseDataDir" -ForegroundColor Gray

