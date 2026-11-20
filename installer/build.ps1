# 產生安裝檔：用 Windows 內建的 IExpress 打包成單一 .exe
# 用法：powershell -ExecutionPolicy Bypass -File installer\build.ps1
$ErrorActionPreference = 'Stop'
$Here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root    = Split-Path -Parent $Here
$OutDir  = Join-Path $Root '安裝檔'
$OutName = '幣圈美股快訊-安裝程式.exe'

# IExpress 只認得 ANSI 路徑，所以先在純英文路徑的暫存資料夾組裝
$Stage = Join-Path $env:TEMP ('cnw_build_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $Stage | Out-Null

$files = [ordered]@{
    'news-widget.ps1' = Join-Path $Root 'news-widget.ps1'
    'icon.ico'        = Join-Path $Root 'icon.ico'
    'launch.vbs'      = Join-Path $Here 'launch.vbs'
    'install.ps1'     = Join-Path $Here 'install.ps1'
    'uninstall.ps1'   = Join-Path $Here 'uninstall.ps1'
    'setup.cmd'       = Join-Path $Here 'setup.cmd'
}
$utf8Bom = New-Object Text.UTF8Encoding $true
foreach ($name in $files.Keys) {
    $src = $files[$name]; $dst = Join-Path $Stage $name
    if ($name -like '*.ps1') {
        # Windows PowerShell 5.1 需要 UTF-8 with BOM 才能正確讀中文
        [IO.File]::WriteAllText($dst, [IO.File]::ReadAllText($src, [Text.Encoding]::UTF8), $utf8Bom)
    } else { Copy-Item $src $dst }
}

$target = Join-Path $Stage 'setup.exe'
$i = 0
$fileLines   = ($files.Keys | ForEach-Object { "FILE$i=`"$_`""; $i++ }) -join "`r`n"
$i = 0
$sourceLines = ($files.Keys | ForEach-Object { "%FILE$i%="; $i++ }) -join "`r`n"

$sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$target
FriendlyName=Crypto and US Stock News Widget Setup
AppLaunched=cmd.exe /c setup.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
$fileLines
[SourceFiles]
SourceFiles0=$Stage\
[SourceFiles0]
$sourceLines
"@
$sedPath = Join-Path $Stage 'package.sed'
[IO.File]::WriteAllText($sedPath, $sed, [Text.Encoding]::Default)

$p = Start-Process (Join-Path $env:WINDIR 'System32\iexpress.exe') -ArgumentList '/N', '/Q', $sedPath -Wait -PassThru
if (-not (Test-Path $target)) { throw "IExpress 打包失敗（exit $($p.ExitCode)）" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$out = Join-Path $OutDir $OutName
Copy-Item $target $out -Force
# 英文檔名的副本：上傳到 GitHub Release 用（GitHub 不支援中文檔名），小工具的自動更新也是找這個檔名
$outEn = Join-Path $OutDir 'CryptoNewsWidget-Setup.exe'
Copy-Item $target $outEn -Force
Remove-Item $Stage -Recurse -Force
Write-Output ("完成：{0}  ({1:N0} KB)" -f $out, ((Get-Item $out).Length / 1KB))
Write-Output ("　　　{0}（上傳 GitHub Release 用）" -f $outEn)
