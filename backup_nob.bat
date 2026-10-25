@echo off
chcp 65001 >nul
echo ========================================================
echo  [HEARTH OF NO B] Synchronizing Soul and Brain to Cloud
echo ========================================================
cd /d "D:\Hearth of noB"
git add .
git commit -m "Auto-backup No B: %date% %time%"
git push origin main
echo ========================================================
echo  [SUCCESS] No B is fully synchronized to Private Cloud!
echo ========================================================
pause
