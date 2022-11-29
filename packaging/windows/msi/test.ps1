$ErrorActionPreference = "Stop"

# Install PoshSpec

Write-Host "Installing PoshSpec..."
Install-Module -Name Pester -Force -SkipPublisherCheck
Install-Module -Name poshspec -Force -AllowClobber

# Start Consul

Write-Host "Starting Consul..."
Start-Process -NoNewWindow "C:\consul\consul.exe" -ArgumentList "agent -config-file `"C:\consul\config.json`" -data-dir `"C:\consul\data`""  | Out-Null

# Install MSI

Write-Host "Installing $msi_file ..."
$msi_file = (get-childitem -path output -filter *.msi).name
msiexec.exe /passive /i output\$msi_file | Out-Null

# Test MSI

$packageJson = (Get-Content package.json) -join "`n" | ConvertFrom-Json
$env:SERVICE_NAME = $packageJson.seal.service.name
$env:SERVICE_TAGS = $packageJson.seal.service.tags
$env:PACKAGE_VERSION = $packageJson.version
$env:PACKAGE_NAME = $packageJson.name
$env:PACKAGE_DESCRIPTION = $packageJson.description
$env:MSI_VERSION = "$env:PACKAGE_VERSION.$env:BUILD_NUMBER"
$env:UPGRADE_CODE = $packageJson.seal.packaging.msi.upgradeCode
$env:AUTHOR_NAME = $packageJson.author.name
$env:AUTHOR_URL = $packageJson.author.url
$env:COMPANY_FOLDER = $packageJson.author.name -Replace " AG$",""

Write-Host "Running MSI PoshSpec tests..."
powershell -File "packaging\windows\msi\test\package_spec.ps1" |
  Tee-Object -FilePath "temp\test-results.out"

# Check test output since we get no error or exit code if run failed
$FailMarks = Select-String -Path "temp\test-results.out" -SimpleMatch -Pattern " [-] "
if ($FailMarks -ne $null)
{
  throw "PoshSpec tests failed."
}
