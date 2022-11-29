$ErrorActionPreference = "Stop"
#Set-PSDebug -Trace 1

# Clean
@(
    'output'
    'temp'
) |
Where-Object { Test-Path $_ } |
ForEach-Object { Remove-Item $_ -Recurse -Force -ErrorAction Stop }

# Create output and temp dir
mkdir output
mkdir temp

[Net.ServicePointManager]::SecurityProtocol =  [Net.SecurityProtocolType]::Tls12

Write-Host "Copying /SEAL Development/3rd-party/nodejs/$env:NODE_VERSION/windows/node.exe ..."
node .github/scripts/webdav.js pull "/SEAL Development/3rd-party/nodejs/$env:NODE_VERSION/windows/node.exe" ".\temp\node.exe"
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }

Write-Host "Copying /SEAL Development/3rd-party/nssm/$env:NSSM_VERSION/windows/nssm.exe ..."
node .github/scripts/webdav.js pull "/SEAL Development/3rd-party/nssm/$env:NSSM_VERSION/windows/nssm.exe" ".\temp\nssm.exe"
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }

Write-Host "Copying /SEAL Development/3rd-party/7zip/$env:SEVENZIP_VERSION/windows/7za.exe ..."
node .github/scripts/webdav.js pull "/SEAL Development/3rd-party/7zip/$env:SEVENZIP_VERSION/windows/7za.exe" ".\temp\7za.exe"
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }

Write-Host "Copying /SEAL Development/3rd-party/envconsul/$env:ENVCONSUL_VERSION/windows/envconsul_$($env:ENVCONSUL_VERSION)_windows_amd64.zip ..."
node .github/scripts/webdav.js pull "/SEAL Development/3rd-party/envconsul/$env:ENVCONSUL_VERSION/windows/envconsul_$($env:ENVCONSUL_VERSION)_windows_amd64.zip" ".\temp\envconsul.zip"
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }

Write-Host "Copying /SEAL Development/3rd-party/seal/sealcert/SealIECert.pfx ..."
node .github/scripts/webdav.js pull "/SEAL Development/3rd-party/seal/sealcert/SealIECert.pfx" "D:\SealIECert.pfx"
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }

Write-Host "Extracting envconsul.zip ..."
Unzip ".\temp\envconsul.zip" -d ".\temp\"

Write-Host "Downloading https://github.com/dblock/msiext/releases/download/1.5/msiext-1.5.zip ..."
(New-Object Net.WebClient).DownloadFile(
  "https://github.com/dblock/msiext/releases/download/1.5/msiext-1.5.zip",
  ".\temp\msiext-1.5.zip"
)

Write-Host "Extracting msiext.zip ..."
Unzip ".\temp\msiext-1.5.zip" -d ".\temp\"
