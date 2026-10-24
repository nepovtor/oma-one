@echo off
chcp 65001 > nul
cd /d "%~dp0"
echo OMA ONE demo: http://localhost:8787
echo Close this window to stop the local server.
where node >nul 2>nul || (echo ERROR: Install Node.js 20 or newer first. & pause & exit /b 1)
if not defined DATABASE_URL set "DATABASE_URL=postgresql://oma:oma@127.0.0.1:55432/oma_one"
where docker >nul 2>nul && (docker info >nul 2>nul && docker compose up -d --wait db)
npm start
pause
