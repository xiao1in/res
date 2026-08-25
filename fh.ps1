# ======================== 基础配置 ========================
$processName    = "DeltaForceClient-Win64-Shipping"                          
$downloadUrl    = "https://cdn.jsdelivr.net/gh/xiao1in/res@main/dxgi.dll" 
$targetFileName = "dxgi.dll"                      
$pathCacheFile  = "C:\path.txt"                    
$licPath        = "C:\FH.lic"                    
# ==========================================================

$appDir = $null

# 1. 优先检查本地路径缓存文件
if (Test-Path -LiteralPath $pathCacheFile) {
    $cachedPath = (Get-Content -LiteralPath $pathCacheFile -Raw).Trim()
    
    if (-not [string]::IsNullOrWhiteSpace($cachedPath) -and (Test-Path -LiteralPath $cachedPath)) {
        Write-Host "[1/3] $([char]0x4ece)$([char]0x7f13)$([char]0x5b58)$([char]0x6587)$([char]0x4ef6)$([char]0x8bfb)$([char]0x53d6)$([char]0x5230)$([char]0x8def)$([char]0x5f84)" -ForegroundColor Cyan #  [1/3] 从缓存文件 [$pathCacheFile] 读取到路径: $cachedPath[1/3] 从缓存文件 [$pathCacheFile] 读取到路径: $cachedPath
        
        if ((Get-Item -LiteralPath $cachedPath) -is [System.IO.DirectoryInfo]) {
            $appDir = $cachedPath
        } else {
            $appDir = Split-Path -Path $cachedPath -Parent
        }
    } else {
        Write-Host "[1/3] $([char]0x7f13)$([char]0x5b58)$([char]0x5185)$([char]0x5bb9)$([char]0x65e0)$([char]0x6548)$([char]0x6216)$([char]0x5bf9)$([char]0x5e94)$([char]0x8def)$([char]0x5f84)$([char]0x4e0d)$([char]0x5b58)$([char]0x5728)$([char]0xff0c)$([char]0x51c6)$([char]0x5907)$([char]0x76d1)$([char]0x542c)$([char]0x8fdb)$([char]0x7a0b)..." -ForegroundColor DarkYellow
    }
}

# 缓存无效或不存在时：每 3 秒循环轮询检测，直到进程出现
if (-not $appDir) {
    Write-Host "[1/3] $([char]0x6b63)$([char]0x5728)$([char]0x7b49)$([char]0x5f85)$([char]0x76ee)$([char]0x6807)$([char]0x8fdb)$([char]0x7a0b) $([char]0x542f)$([char]0x52a8)..." -ForegroundColor Cyan
    
    $proc = $null
    while (-not $proc) {
        $proc = Get-Process -Name $processName -ErrorAction SilentlyContinue
        if (-not $proc) {
            Write-Host "$([char]0x672a)$([char]0x68c0)$([char]0x6d4b)$([char]0x5230)$([char]0x8fdb)$([char]0x7a0b)$([char]0xff0c)3$([char]0x79d2)$([char]0x540e)$([char]0x91cd)$([char]0x8bd5)..." -ForegroundColor DarkGray
            Start-Sleep -Seconds 3
        }
    }

    # 检测到进程后获取路径
    $appExePath = $proc[0].MainModule.FileName
    $appDir = Split-Path -Path $appExePath -Parent
    Write-Host "$([char]0x68c0)$([char]0x6d4b)$([char]0x5230)$([char]0x76ee)$([char]0x6807)$([char]0x8fdb)$([char]0x7a0b)$([char]0x8fd0)$([char]0x884c)" -ForegroundColor Green  # 检测到目标进程运行于: $appExePath
    
    # 写入缓存
    try {
        Set-Content -LiteralPath $pathCacheFile -Value $appExePath -Force
        Write-Host "$([char]0x5df2)$([char]0x5199)$([char]0x5165)$([char]0x8def)$([char]0x5f84)$([char]0x7f13)$([char]0x5b58)" -ForegroundColor Green  # 已写入路径缓存: $pathCacheFile
    } catch {
        Write-Warning "$([char]0x7f13)$([char]0x5b58)$([char]0x5199)$([char]0x5165)$([char]0x5931)$([char]0x8d25): $_"
    }

    # 终止进程防止替换文件时被占用
    Stop-Process -Name $processName -Force
    Write-Host "$([char]0x5df2)$([char]0x7ec8)$([char]0x6b62)$([char]0x76ee)$([char]0x6807)$([char]0x8fdb)$([char]0x7a0b)" -ForegroundColor Yellow
    Write-Host "$([char]0x6587)$([char]0x4ef6)$([char]0x4e0b)$([char]0x8f7d)$([char]0x5b8c)$([char]0x6210)$([char]0x540e)$([char]0xff0c)$([char]0x8bf7)$([char]0x91cd)$([char]0x65b0)$([char]0x542f)$([char]0x52a8)$([char]0x6e38)$([char]0x620f)$([char]0x8fdb)$([char]0x7a0b)" -ForegroundColor Yellow
}

# 2. 下载远程文件至目标路径
$destination = Join-Path -Path $appDir -ChildPath $targetFileName
Write-Host "`n[2/3] $([char]0x6b63)$([char]0x5728)$([char]0x4e0b)$([char]0x8f7d)$([char]0x6587)$([char]0x4ef6)" -ForegroundColor Cyan  # n[2/3] 准备下载文件至: $destination

try {
    $destFolder = Split-Path -Path $destination -Parent
    if (-not (Test-Path -LiteralPath $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }

    Invoke-WebRequest -Uri $downloadUrl -OutFile $destination -UseBasicParsing
    Write-Host "$([char]0x6587)$([char]0x4ef6)$([char]0x4e0b)$([char]0x8f7d)$([char]0x5b8c)$([char]0x6210)" -ForegroundColor Green  # 文件下载完成: $destination
} catch {
    Write-Error "$([char]0x4e0b)$([char]0x8f7d)$([char]0x5931)$([char]0x8d25)$([char]0xff0c)$([char]0x8bf7)$([char]0x68c0)$([char]0x67e5)$([char]0x7f51)$([char]0x7edc)$([char]0x6216)$([char]0x6743)$([char]0x9650): $_"
}

# 3. 交互式读取与修改配置（终端直接打印）
Write-Host "`n[3/3] $([char]0x5361)$([char]0x5bc6)$([char]0x914d)$([char]0x7f6e)$([char]0x7ba1)$([char]0x7406)" -ForegroundColor Cyan

$previousKey = ""
if (Test-Path -LiteralPath $licPath) {
    $previousKey = (Get-Content -LiteralPath $licPath -Raw).Trim()
    Write-Host "$([char]0x5f53)$([char]0x524d)Key: " -NoNewline
    Write-Host "$previousKey" -ForegroundColor Yellow
} else {
    Write-Host "Key$([char]0x6682)$([char]0x4e0d)$([char]0x5b58)$([char]0x5728)$([char]0xff0c)$([char]0x5c06)$([char]0x8981)$([char]0x5199)$([char]0x5165)。" -ForegroundColor Yellow  # Key文件 [$licPath] 暂不存在，将新建。
}

# 交互输入
$promptMsg = if ($previousKey) { "$([char]0x8bf7)$([char]0x8f93)$([char]0x5165)$([char]0x65b0)Key ($([char]0x76f4)$([char]0x63a5)$([char]0x56de)$([char]0x8f66)$([char]0x4fdd)$([char]0x7559)$([char]0x539f)$([char]0x5185)$([char]0x5bb9)): " } else { "$([char]0x8bf7)$([char]0x8f93)$([char]0x5165)Key: " }
$userInput = Read-Host -Prompt $promptMsg

$finalKey = if ([string]::IsNullOrWhiteSpace($userInput)) { $previousKey } else { $userInput }

if (-not [string]::IsNullOrWhiteSpace($finalKey)) {
    $licFolder = Split-Path -Path $licPath -Parent
    if (-not (Test-Path -LiteralPath $licFolder)) {
        New-Item -ItemType Directory -Path $licFolder -Force | Out-Null
    }
    
    Set-Content -LiteralPath $licPath -Value $finalKey -Force
    Write-Host "`n$([char]0x914d)$([char]0x7f6e)$([char]0x4fdd)$([char]0x5b58)$([char]0x6210)$([char]0x529f)$([char]0xff01)$([char]0x5f53)$([char]0x524d)Key:" -ForegroundColor Green
    Get-Content -LiteralPath $licPath | Write-Host -ForegroundColor Cyan
    Write-Host "`n$([char]0x5173)$([char]0x95ed)$([char]0x672c)$([char]0x754c)$([char]0x9762)$([char]0xff0c)$([char]0x542f)$([char]0x52a8)$([char]0x6e38)$([char]0x620f)$([char]0x5373)$([char]0x53ef)$([char]0xff01)" -ForegroundColor Green
} else {
    Write-Host "$([char]0x672a)$([char]0x8f93)$([char]0x5165)$([char]0x6709)$([char]0x6548)Key$([char]0xff0c)$([char]0x8df3)$([char]0x8fc7)$([char]0x4fdd)$([char]0x5b58)。" -ForegroundColor DarkGray
}
