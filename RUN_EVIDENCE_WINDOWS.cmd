@echo off
cd /d "%~dp0"
npm run test:proof
if errorlevel 1 exit /b 1
npm run evidence:report
if errorlevel 1 exit /b 1
start http://localhost:8790/
npm run evidence
