@echo off
title Tsukimi Yachiyo 3D Motion Studio Launcher
cd /d "%~dp0"
echo Starting Tsukimi Yachiyo 3D Motion Studio on http://localhost:8088 ...
start "" "http://localhost:8088"
python -m http.server 8088
pause
