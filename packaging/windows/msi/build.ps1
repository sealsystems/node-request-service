$ErrorActionPreference = "Stop"
#Set-PSDebug -Trace 1

# Try multiple timstamp server if one is down
$serverList = @('http://timestamp.comodoca.com/authenticode', 'http://timestamp.globalsign.com/scripts/timestamp.dll', 'http://tsa.starfieldtech.com')

function SignFile($description, $fileName) {
  $ErrorActionPreference ="SilentlyContinue"
  foreach ($server in $serverList) {
    write-host "Try server $server"
    . "$env:SignTool" sign /f "$env:KeyFile" /p "$env:SIGNING_PASSWORD" /d "$description" /du "$env:AUTHOR_URL" /t "$server" "$fileName"
    if($LASTEXITCODE -eq 0) {
      break
    }
  }
  $ErrorActionPreference = "Stop"
  if($LASTEXITCODE -ne 0) {
    throw "Connecting timestamp servers failed."
  }
}

# Create a folder for files to package
$content_dir = "temp\content"
mkdir $content_dir

# Copy excluding .git and installer
Write-Host "Copying bin folder"
robocopy bin\ $content_dir\bin /COPYALL /S /NFL /NDL /NS /NC /NJH /NJS /XF *.sh
if ($LASTEXITCODE -gt 1) { throw "Exit code is $LASTEXITCODE" } # Note: robocopy returns code = 1 if all files have been copied!
Write-Host "Copying lib folder"
robocopy lib\ $content_dir\lib /COPYALL /S /NFL /NDL /NS /NC /NJH /NJS
if ($LASTEXITCODE -gt 1) { throw "Exit code is $LASTEXITCODE" } # Note: robocopy returns code = 1 if all files have been copied!
Write-Host "Copying package.json"
cp package.json $content_dir

# Create archive of all Node.js modules in order to extract it during install. This dramatically improves install time.
Write-Host "Archiving node_modules dir"
.\temp\7za.exe a -tzip "$content_dir\node_modules.zip" node_modules
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }
# Calculate size of node_modules folder in order to add the amount to the estimated required disk space.
$env:NODE_MODULES_SIZE = (Get-ChildItem -Recurse node_modules\ | Measure-Object -Property Length -Sum).Sum
Write-Host "Adding $env:NODE_MODULES_SIZE bytes to estimated required disk space."

# Extract values from package.json
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
$env:DISABLE_ENVCONSUL = $packageJson.seal.packaging.disableEnvconsul

# Find name of bin/*.js file to start the Node.js application
$env:MAIN_JS_FILE = (get-childitem -path bin -filter *.js).name

# Add empty SERVICE_TAGS variable, if nothing defined in package.json
if (! ($env:SERVICE_TAGS)) {
  $env:SERVICE_TAGS = " "
}

if ($env:DISABLE_ENVCONSUL) {
  # overwrite run.bat with run_no_envconsul.bat
  Write-Host "Disabling envconsul"
  cp "packaging\windows\msi\resource\run_no_envconsul.bat" "packaging\windows\msi\resource\run.bat"
}

# Code sign the envconsul.exe file
SignFile "envconsul.exe" "temp\envconsul.exe"

# Code sign the nssm.exe file
SignFile "nssm.exe" "temp\nssm.exe"

# Generate the installer
$msi_name="$($env:PACKAGE_NAME)-$($env:MSI_VERSION).msi"

Write-Host "Running heat.exe"
. "$env:WIX\bin\heat.exe" dir $content_dir -dr INSTALLDIR -cg MainComponentGroup -out temp\directory.wxs -var var.SourceDir -ag -ke -scom -sfrag -srd -sreg -suid
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }

Write-Host "Running candle.exe"
. "$env:WIX\bin\candle.exe" "-dSourceDir=$content_dir" -arch x64 packaging\windows\msi\*.wxs temp\*.wxs -o temp\ -ext WiXUtilExtension -ext temp\msiext-1.5\WixExtensions\WixSystemToolsExtension.dll
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }

Write-Host "Running light.exe"
. "$env:WIX\bin\light.exe" -o "output\$msi_name" temp\*.wixobj -cultures:en-US -loc packaging\windows\msi\en-US.wxl -ext WixUIExtension.dll -ext WiXUtilExtension -ext temp\msiext-1.5\WixExtensions\WixSystemToolsExtension.dll
if ($LASTEXITCODE -ne 0) { throw "Exit code is $LASTEXITCODE" }

# Code sign the MSI file
SignFile "$env:PACKAGE_NAME $env:MSI_VERSION Setup" "output\$msi_name"

# Remove the package folder
Remove-Item -Recurse -Force $content_dir
