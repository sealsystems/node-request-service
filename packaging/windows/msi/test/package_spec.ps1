#Requires -Module Poshspec

Describe 'Package' {
  Package "$env:PACKAGE_NAME $env:MSI_VERSION" version { should be "$env:MSI_VERSION" }
  File "$env:ProgramFiles\$env:COMPANY_FOLDER\$env:PACKAGE_NAME\node.exe" { Should -Exist }
  File "$env:ProgramFiles\$env:COMPANY_FOLDER\$env:PACKAGE_NAME\package.json" { Should -Exist }
}

Describe 'Log' {
  File "$env:ProgramData\$env:COMPANY_FOLDER\log\$env:PACKAGE_NAME.log" { Should -Exist }
  File "$env:ProgramData\$env:COMPANY_FOLDER\log\$env:PACKAGE_NAME.log" { Should -FileContentMatch 'Service started' }
}

Describe 'Service' {
  Service "$env:PACKAGE_NAME" Status { Should Be Running }
}
