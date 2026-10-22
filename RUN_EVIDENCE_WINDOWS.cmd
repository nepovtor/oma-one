@echo off
cd /d "%~dp0"
node --test tests/proof-engine.test.mjs tests/proof-api.test.mjs tests/engine.test.mjs tests/ios-native-static.test.mjs tests/ui-static.test.mjs
if errorlevel 1 exit /b 1
node scripts/generate-evidence.mjs
if errorlevel 1 exit /b 1
start http://localhost:8790/
node proof-server.mjs
