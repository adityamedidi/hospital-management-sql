@echo off
REM =====================================================================
REM File:    run_all.bat
REM Purpose: Run all HMS SQL files in numeric order via sqlplus (Windows).
REM Usage:   run_all.bat username/password@//host:port/service
REM Example: run_all.bat hms_user/secret@//localhost:1521/XEPDB1
REM Author:  HMS Project
REM Date:    2025
REM =====================================================================

setlocal enabledelayedexpansion

REM ---- Validate args ---------------------------------------------------
if "%~1"=="" (
  echo Usage: %0 ^<username/password@//host:port/service^>
  echo Example: %0 hms_user/secret@//localhost:1521/XEPDB1
  exit /b 2
)

set "CONNECTION=%~1"

REM ---- Resolve the sql\ directory relative to this script -------------
set "SCRIPT_DIR=%~dp0"
set "SQL_DIR=%SCRIPT_DIR%..\sql"

if not exist "%SQL_DIR%" (
  echo ERROR: sql directory not found at %SQL_DIR% 1>&2
  exit /b 2
)

REM ---- Verify sqlplus is available ------------------------------------
where sqlplus >nul 2>&1
if errorlevel 1 (
  echo ERROR: sqlplus not found on PATH. Install Oracle Instant Client. 1>&2
  exit /b 2
)

echo =================================================================
echo   Hospital Management System - full schema load
echo   Connection: %CONNECTION%
echo   SQL dir:    %SQL_DIR%
echo =================================================================

pushd "%SQL_DIR%"

set "GLOBAL_RC=0"

REM ---- Run every .sql file in numeric order ---------------------------
REM WHENEVER SQLERROR EXIT SQL.SQLCODE  -> abort on the first error
REM SET DEFINE OFF                       -> don't interpret & as substitution
for /f "delims=" %%F in ('dir /b /a:-d *.sql ^| sort') do (
  echo.
  echo ----------------------------------------------------------------
  echo   Running %%F
  echo ----------------------------------------------------------------
  (
    echo WHENEVER SQLERROR EXIT SQL.SQLCODE;
    echo SET DEFINE OFF;
    echo SET SERVEROUTPUT ON;
    echo PROMPT ^>^>^> %%F
    echo @%%F
    echo COMMIT;
  ) | sqlplus -S -L "%CONNECTION%"
  if errorlevel 1 (
    set "GLOBAL_RC=!ERRORLEVEL!"
    echo   [FAIL] %%F ^(sqlplus exit code !GLOBAL_RC!^) 1>&2
    goto :done
  ) else (
    echo   [OK] %%F
  )
)

:done
popd

echo.
echo =================================================================
if "%GLOBAL_RC%"=="0" (
  echo   All SQL files executed successfully.
) else (
  echo   Run aborted with exit code %GLOBAL_RC%.
)
echo =================================================================
exit /b %GLOBAL_RC%
