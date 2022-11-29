@echo off
setlocal

if not defined SERVICE_NAME (
  echo Error: Environment variable SERVICE_NAME is not defined. Abort.
  exit 1
)

set kv_start=dc/home/env
set prefix_any=-prefix %kv_start%/service/any/tag/any/
set prefix_service=-prefix %kv_start%/service/%SERVICE_NAME%/tag/any/

for %%t in (%SERVICE_TAGS%) do call :addprefix %%t

goto :envconsul

:addprefix
set prefix_any=%prefix_any% -prefix %kv_start%/service/any/tag/%1/
set prefix_service=%prefix_service% -prefix %kv_start%/service/%SERVICE_NAME%/tag/%1/
goto :eof

:envconsul
REM Please note: The different quotes are needed to make Windows and Envconsul happy.
"%~dp0envconsul.exe" -config "[CONFIGDIR]envconsul.json" %prefix_any% %prefix_service% '%~dp0node.exe' '%~dp0bin\app.js'
goto :eof
