# 幣圈美股快訊 — 安裝腳本（由安裝程式自動執行，不需要系統管理員權限）
param(
    [string]$Dest,            # 測試用：指定安裝位置
    [string]$ShortcutDir,     # 測試用：指定捷徑位置（不指定 = 桌面 + 開始功能表）
    [switch]$NoLaunch,        # 測試用：裝完不自動開啟
    [switch]$NoRegistry,      # 測試用：不寫入「應用程式與功能」
    [switch]$Quiet            # 不顯示完成訊息
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

$AppName = '幣圈美股快訊'
$AppId   = 'CryptoNewsWidget'
$Src     = Split-Path -Parent $MyInvocation.MyCommand.Path
# 版本號直接從小工具程式裡讀（$AppVersion），只要改一個地方
$Version = '1.0.0'
$vm = Select-String -Path (Join-Path $Src 'news-widget.ps1') -Pattern "^\`$AppVersion\s*=\s*'([^']+)'" -Encoding UTF8 | Select-Object -First 1
if ($vm) { $Version = $vm.Matches[0].Groups[1].Value }
if (-not $Dest) { $Dest = Join-Path $env:LOCALAPPDATA $AppId }

try {
    # 1. 若已在執行，先關掉（更新安裝時）
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
        Where-Object { $_.CommandLine -and $_.CommandLine -like "*$Dest*news-widget.ps1*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 500

    # 2. 複製程式檔（保留使用者原本的 settings.json）
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null
    foreach ($f in 'news-widget.ps1', 'icon.ico', 'launch.vbs', 'uninstall.ps1') {
        Copy-Item (Join-Path $Src $f) (Join-Path $Dest $f) -Force
    }

    # 3. 建立捷徑（有 VBScript 就用它啟動，完全不會閃黑窗；沒有就直接用 PowerShell 隱藏視窗啟動）
    $useVbs = Test-Path (Join-Path $env:WINDIR 'System32\vbscript.dll')
    $ws = New-Object -ComObject WScript.Shell
    function New-Shortcut([string]$path) {
        $s = $ws.CreateShortcut($path)
        if ($useVbs) {
            $s.TargetPath = Join-Path $env:WINDIR 'System32\wscript.exe'
            $s.Arguments  = '"' + (Join-Path $Dest 'launch.vbs') + '"'
        } else {
            $s.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
            $s.Arguments  = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + (Join-Path $Dest 'news-widget.ps1') + '"'
        }
        $s.WorkingDirectory = $Dest
        $s.IconLocation     = (Join-Path $Dest 'icon.ico') + ',0'
        $s.Description      = '幣圈 & 美股 即時新聞小工具'
        $s.Save()
    }
    if ($ShortcutDir) {
        New-Item -ItemType Directory -Force -Path $ShortcutDir | Out-Null
        New-Shortcut (Join-Path $ShortcutDir "$AppName.lnk")
    } else {
        New-Shortcut (Join-Path ([Environment]::GetFolderPath('Desktop')) "$AppName.lnk")
        New-Shortcut (Join-Path ([Environment]::GetFolderPath('Programs')) "$AppName.lnk")
    }

    # 4. 登錄到「設定 > 應用程式」，可從那裡解除安裝
    if (-not $NoRegistry) {
        $key = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppId"
        New-Item -Path $key -Force | Out-Null
        $uninst = '"' + (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') + '" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path $Dest 'uninstall.ps1') + '"'
        $props = @{
            DisplayName = $AppName; DisplayVersion = $Version; DisplayIcon = (Join-Path $Dest 'icon.ico')
            InstallLocation = $Dest; UninstallString = $uninst; Publisher = $AppName
        }
        foreach ($k in $props.Keys) { New-ItemProperty -Path $key -Name $k -Value $props[$k] -PropertyType String -Force | Out-Null }
        New-ItemProperty -Path $key -Name NoModify -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $key -Name NoRepair -Value 1 -PropertyType DWord -Force | Out-Null
    }

    # 5. 開啟小工具
    if (-not $NoLaunch) {
        if ($useVbs) { Start-Process (Join-Path $env:WINDIR 'System32\wscript.exe') -ArgumentList ('"' + (Join-Path $Dest 'launch.vbs') + '"') }
        else { Start-Process powershell.exe -WindowStyle Hidden -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + (Join-Path $Dest 'news-widget.ps1') + '"') }
    }

    if (-not $Quiet) {
        [System.Windows.Forms.MessageBox]::Show(
            "安裝完成！`n`n桌面和開始功能表都已建立「$AppName」捷徑，小工具也已經開啟（第一次載入約需 10 秒）。`n`n要移除時：設定 > 應用程式 > 已安裝的應用程式 > $AppName > 解除安裝。",
            "$AppName 安裝程式", 'OK', 'Information') | Out-Null
    }
}
catch {
    [System.Windows.Forms.MessageBox]::Show("安裝失敗：`n$($_.Exception.Message)", "$AppName 安裝程式", 'OK', 'Error') | Out-Null
    exit 1
}
