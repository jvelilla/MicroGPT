<#
.SYNOPSIS
Downloads and installs OpenBLAS binaries for the MicroGPT Eiffel project.

.DESCRIPTION
This script downloads a specific version of OpenBLAS (default 0.3.31) from GitHub or SourceForge, 
extracts the archive, and places the `include`, `lib`, and `bin` folders into the `spec\openblas` directory 
so that the Eiffel compiler can link against them.

.PARAMETER Architecture
The target architecture to download. Options are 'x64' or 'x86'. Default is 'x64'.

.PARAMETER Version
The version of OpenBLAS to download. Default is '0.3.31'.
#>
param(
    [ValidateSet('x64', 'x86')]
    [string]$Architecture = 'x64',

    [string]$Version = '0.3.31'
)

$ErrorActionPreference = "Stop"

# Use the GitHub mirror/releases as it avoids SourceForge redirects and ads
$url = "https://github.com/OpenMathLib/OpenBLAS/releases/download/v$Version/OpenBLAS-$Version-$Architecture.zip"
$zipPath = "OpenBLAS-$Version-$Architecture.zip"
$extractPath = "OpenBLAS-temp_extract"
$targetDir = "spec\openblas"

Write-Host "Downloading OpenBLAS $Version for $Architecture..."
Write-Host "URL: $url"

try {
    Invoke-WebRequest -Uri $url -OutFile $zipPath
} catch {
    Write-Error "Failed to download OpenBLAS from $url. Please check your internet connection or the version number."
    exit 1
}

Write-Host "Extracting to temporary directory $extractPath..."
if (Test-Path $extractPath) {
    Remove-Item -Recurse -Force $extractPath
}
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

Write-Host "Setting up target directory $targetDir..."
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# The zip from OpenBLAS usually extracts into a 'win64' or 'win32' folder inside the temp dir depending on the arch.
if ($Architecture -eq 'x64') {
    $sourceDir = Join-Path $extractPath "win64"
} else {
    $sourceDir = Join-Path $extractPath "win32"
}

if (Test-Path $sourceDir) {
    Write-Host "Copying files from $sourceDir to $targetDir..."
    Copy-Item -Path (Join-Path $sourceDir "*") -Destination $targetDir -Recurse -Force
} else {
    Write-Warning "Expected extracted directory '$sourceDir' not found. Copying directly from extraction root."
    Copy-Item -Path (Join-Path $extractPath "*") -Destination $targetDir -Recurse -Force
}

Write-Host "Cleaning up temporary files..."
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
if (Test-Path $extractPath) { Remove-Item -Recurse -Force $extractPath }

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "OpenBLAS $Version ($Architecture) successfully installed to $targetDir." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
