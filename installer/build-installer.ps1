<#
.SYNOPSIS
    Builds and packages LocalLoop Host binaries for distribution.
.DESCRIPTION
    Compiles LocalLoop.Service and LocalLoop.Bridge into unified output directories,
    and optionally invokes Inno Setup (iscc) to generate LocalLoopSetup.exe.
#>

[CmdletBinding()]
param(
    [string]$Configuration = "Release",
    [string]$OutputDirectory = "$PSScriptRoot\dist"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Building LocalLoop Host for Windows Distribution" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$Root = Resolve-Path "$PSScriptRoot\.."
$PublishDir = "$PSScriptRoot\publish"

# Clean old artifacts
if (Test-Path $PublishDir) { Remove-Item -Recurse -Force $PublishDir }
if (Test-Path $OutputDirectory) { Remove-Item -Recurse -Force $OutputDirectory }
New-Item -ItemType Directory -Path "$PublishDir\service" -Force | Out-Null
New-Item -ItemType Directory -Path "$PublishDir\bridge" -Force | Out-Null
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

# 1. Publish LocalLoop.Service (Background Worker)
Write-Host "`n[1/3] Publishing LocalLoop.Service..." -ForegroundColor Yellow
dotnet publish "$Root\src\LocalLoop.Service\LocalLoop.Service.csproj" `
    -c $Configuration `
    -r win-x64 `
    --self-contained false `
    -o "$PublishDir\service"

# 2. Publish LocalLoop.Bridge (WinForms Systray & QR Pop-up)
Write-Host "`n[2/3] Publishing LocalLoop.Bridge..." -ForegroundColor Yellow
dotnet publish "$Root\src\LocalLoop.Bridge\LocalLoop.Bridge.csproj" `
    -c $Configuration `
    -r win-x64 `
    --self-contained false `
    -o "$PublishDir\bridge"

Write-Host "`n[3/3] Preparing Inno Setup package configuration..." -ForegroundColor Yellow
$InnoScript = "$PSScriptRoot\localloop.iss"

# Check if Inno Setup Compiler (ISCC.exe) is available in common paths
$IsccPaths = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    (Get-Command iscc.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
)

$Iscc = $IsccPaths | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if ($Iscc) {
    Write-Host "Compiling installer using $Iscc..." -ForegroundColor Green
    & $Iscc $InnoScript
    Write-Host "`nInstaller generated at: $OutputDirectory\LocalLoopSetup.exe" -ForegroundColor Green
} else {
    Write-Host "Inno Setup compiler (ISCC.exe) not found on system." -ForegroundColor DarkYellow
    Write-Host "Binaries are published at: $PublishDir" -ForegroundColor Green
    Write-Host "Install Inno Setup 6 and compile '$InnoScript' to build LocalLoopSetup.exe." -ForegroundColor Gray
}

Write-Host "`nHost build completed successfully!" -ForegroundColor Cyan
