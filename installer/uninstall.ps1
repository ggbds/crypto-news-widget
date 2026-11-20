# 幣圈美股快訊 — 解除安裝
Add-Type -AssemblyName System.Windows.Forms
$AppName = '幣圈美股快訊'
$AppId   = 'CryptoNewsWidget'
$Dest    = Split-Path -Parent $MyInvocation.MyCommand.Path

$ok = [System.Windows.Forms.MessageBox]::Show("確定要移除「$AppName」嗎？", "$AppName", 'YesNo', 'Question')
if ($ok -ne 'Yes') { exit }

# 關閉執行中的小工具
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -and $_.CommandLine -like "*$Dest*news-widget.ps1*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500

# 刪除捷徑、登錄資訊、程式資料夾
foreach ($d in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs')) {
    Remove-Item (Join-Path $d "$AppName.lnk") -Force -ErrorAction SilentlyContinue
}
Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppId" -Recurse -Force -ErrorAction SilentlyContinue
Set-Location $env:TEMP
Remove-Item $Dest -Recurse -Force -ErrorAction SilentlyContinue

[System.Windows.Forms.MessageBox]::Show("「$AppName」已移除。", "$AppName", 'OK', 'Information') | Out-Null
