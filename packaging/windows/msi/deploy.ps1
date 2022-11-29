$ErrorActionPreference = "Stop"
#Set-PSDebug -Trace 1

# Extract values from package.json
$packageJson = (Get-Content package.json) -join "`n" | ConvertFrom-Json
$packageName = $packageJson.name
$packageVersion = $packageJson.version

# Get name of first msi in output directory
$filename = (get-childitem -path output -filter *.msi).name
$sourceFile = "output\$filename"
$targetFile = "/SEAL Development/workspace/$packageName/$packageVersion/$filename"

Write-Host "Copying $sourceFile to $targetFile ..."
node .github/scripts/webdav.js push "$sourceFile" "$targetFile"
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }
