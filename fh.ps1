# ======================== 基础配置 ========================
$processName    = "DeltaForceClient-Win64-Shipping"                           # 目标进程名（不带 .exe）
$downloadUrl    = "https://cdn.jsdelivr.net/gh/xiao1in/res@main/dxgi.dll" # 远程文件下载链接
$targetFileName = "dxgi.dll"                        # 需落地/替换的目标文件名
$pathCacheFile  = "C:\path.txt"                       # 缓存进程路径的文件
$licPath        = "C:\FH.lic"                         # 授权/配置文件路径
# ==========================================================

$appDir = $null

# 1. 优先检查本地路径缓存文件
if (Test-Path -LiteralPath $pathCacheFile) {
    $cachedPath = (Get-Content -LiteralPath $pathCacheFile -Raw).Trim()
    
    if (-not [string]::IsNullOrWhiteSpace($cachedPath) -and (Test-Path -LiteralPath $cachedPath)) {
        Write-Host "[1/3] 从缓存文件读取到路径" -ForegroundColor Cyan #  [1/3] 从缓存文件 [$pathCacheFile] 读取到路径: $cachedPath[1/3] 从缓存文件 [$pathCacheFile] 读取到路径: $cachedPath
        
        if ((Get-Item -LiteralPath $cachedPath) -is [System.IO.DirectoryInfo]) {
            $appDir = $cachedPath
        } else {
            $appDir = Split-Path -Path $cachedPath -Parent
        }
    } else {
        Write-Host "[1/3] 缓存内容无效或对应路径不存在，准备监听进程..." -ForegroundColor DarkYellow
    }
}

# 缓存无效或不存在时：每 3 秒循环轮询检测，直到进程出现
if (-not $appDir) {
    Write-Host "[1/3] 正在等待目标进程 [$processName] 启动..." -ForegroundColor Cyan
    
    $proc = $null
    while (-not $proc) {
        $proc = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if (-not $proc) {
            Write-Host "未检测到进程，3秒后重试..." -ForegroundColor DarkGray
            Start-Sleep -Seconds 3
        }
    }

    # 检测到进程后获取路径
    $appExePath = $proc[0].MainModule.FileName
    $appDir = Split-Path -Path $appExePath -Parent
    Write-Host "检测到目标进程运行" -ForegroundColor Green  # 检测到目标进程运行于: $appExePath
    
    # 写入缓存
    try {
        Set-Content -LiteralPath $pathCacheFile -Value $appExePath -Force
        Write-Host "已写入路径缓存" -ForegroundColor Green  # 已写入路径缓存: $pathCacheFile
    } catch {
        Write-Warning "缓存写入失败: $_"
    }

    # 终止进程防止替换文件时被占用
    Stop-Process -Name $processName -Force
    Write-Host "已终止目标进程: $processName" -ForegroundColor Yellow
}

# 2. 下载远程文件至目标路径
$destination = Join-Path -Path $appDir -ChildPath $targetFileName
Write-Host "`n[2/3] 正在下载文件" -ForegroundColor Cyan  # n[2/3] 准备下载文件至: $destination

try {
    $destFolder = Split-Path -Path $destination -Parent
    if (-not (Test-Path -LiteralPath $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }

    Invoke-WebRequest -Uri $downloadUrl -OutFile $destination -UseBasicParsing
    Write-Host "文件下载完成" -ForegroundColor Green  # 文件下载完成: $destination
} catch {
    Write-Error "下载失败，请检查网络或权限: $_"
}

# 3. 交互式读取与修改配置（终端直接打印）
Write-Host "`n[3/3] 卡密配置管理" -ForegroundColor Cyan

$previousKey = ""
if (Test-Path -LiteralPath $licPath) {
    $previousKey = (Get-Content -LiteralPath $licPath -Raw).Trim()
    Write-Host "当前Key: " -NoNewline
    Write-Host "$previousKey" -ForegroundColor Yellow
} else {
    Write-Host "Key暂不存在，将要写入。" -ForegroundColor Yellow  # Key文件 [$licPath] 暂不存在，将新建。
}

# 交互输入
$promptMsg = if ($previousKey) { "请输入新Key (直接回车保留原内容): " } else { "请输入Key: " }
$userInput = Read-Host -Prompt $promptMsg

$finalKey = if ([string]::IsNullOrWhiteSpace($userInput)) { $previousKey } else { $userInput }

if (-not [string]::IsNullOrWhiteSpace($finalKey)) {
    $licFolder = Split-Path -Path $licPath -Parent
    if (-not (Test-Path -LiteralPath $licFolder)) {
        New-Item -ItemType Directory -Path $licFolder -Force | Out-Null
    }
    
    Set-Content -LiteralPath $licPath -Value $finalKey -Force
    Write-Host "`n配置保存成功！当前Key:" -ForegroundColor Green
    Get-Content -LiteralPath $licPath | Write-Host -ForegroundColor Cyan
} else {
    Write-Host "未输入有效Key，跳过保存。" -ForegroundColor DarkGray
}