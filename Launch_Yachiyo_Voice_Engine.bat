@echo off
title Tsukimi Yachiyo Voice Engine (RTX 4070 Accelerated)
cd /d "D:\Hearth of noB\NoB_Vault\02_Arsenal_and_RE\Voice_Cloning\Applio"
echo ========================================================
echo   Tsukimi Yachiyo Voice Cloning Engine (Applio RVC v2)
echo   Hardware Acceleration: NVIDIA GeForce RTX 4070
echo ========================================================
echo.
start "" "http://127.0.0.1:6969"
env\python.exe app.py
pause
