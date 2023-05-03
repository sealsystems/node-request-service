@echo off
setlocal

if not defined SERVICE_NAME (
  echo Error: Environment variable SERVICE_NAME is not defined. Abort.
  exit 1
)

"%~dp0node.exe" "%~dp0bin\app.js"
goto :eof
