@echo off
chcp 65001 >nul
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [Система] Запрос прав Администратора...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
set "REPORT_FILE=%USERPROFILE%\Desktop\Aptechka_Report.txt"
set "SCRIPT_DIR=%~dp0"
if not exist "%REPORT_FILE%" echo === ЖУРНАЛ IT-АПТЕЧКИ === > "%REPORT_FILE%"
echo [%DATE% %TIME%] Сессия: %USERNAME% на %COMPUTERNAME% >> "%REPORT_FILE%"

:Menu
cls
title IT-Аптечка v4.3 [Профиль: Игорь]
echo =======================================================================
echo               IT-АПТЕЧКА v4.3 (Tested on TraXtoR)
echo =======================================================================
echo  1. Проверка системы (SFC)         8. Здоровье дисков (S.M.A.R.T.)
echo  2. Восстановление DISM            9. Бэкап драйверов
echo  3. Очистка обновлений            10. Восстановление драйверов
echo  4. Очистка Temp папок            11. Ремонт Центра Обновлений
echo  5. Точка восстановления          12. Сводная информация о железе ПК
echo  6. Сброс и ремонт сети           13. Оптимизация (Телеметрия + Твики)
echo  7. Проверка диска (CHKDSK)       14. Выход (Лог на Рабочий стол)
echo =======================================================================
set "choice=" & set /p choice="Выберите пункт (1-14): "
for %%i in (1 2 3 4 5 6 7 8 9 10 11 12 13 14) do if "%choice%"=="%%i" goto Mod_%%i
goto Menu

:Mod_1
cls & echo [Запуск] SFC /scannow... & sfc /scannow
echo [%DATE% %TIME%] Выполнена проверка SFC. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_2
cls & echo [Запуск] DISM RestoreHealth... & dism /online /cleanup-image /restorehealth
echo [%DATE% %TIME%] Выполнено восстановление DISM. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_3
cls & echo [Запуск] DISM ResetBase... & dism /online /Cleanup-Image /StartComponentCleanup /ResetBase
echo [%DATE% %TIME%] Очистка обновлений DISM. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_4
cls & echo [Запуск] Полная очистка Temp...
mkdir "%TEMP%\_empty" 2>nul
del /f /q /s "%TEMP%\*.*" >nul 2>&1
robocopy "%TEMP%\_empty" "%TEMP%" /mir /w:0 /r:0 >nul 2>&1
del /f /q /s "%SystemRoot%\Temp\*.*" >nul 2>&1
robocopy "%TEMP%\_empty" "%SystemRoot%\Temp" /mir /w:0 /r:0 >nul 2>&1
rmdir /s /q "%TEMP%\_empty" 2>nul
echo [%DATE% %TIME%] Очистка временных папок Temp и пустых catalogs. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_5
cls & echo [Запуск] Создание точки восстановления...
sc query winmgmt | findstr RUNNING >nul || net start winmgmt
sc query vss | findstr RUNNING >nul || net start vss
powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-ComputerRestore -Drive 'C:\'" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference = 'SilentlyContinue'; Checkpoint-Computer -Description 'IT_Aptechka_AutoPoint' -RestorePointType MODIFY_SETTINGS" 2>nul
echo [%DATE% %TIME%] Создана точка восстановления. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_6
cls & echo [Запуск] Ремонт сети...
ipconfig /flushdns & netsh int ip reset & netsh winsock reset
echo [%DATE% %TIME%] Сброс сети и кэша DNS. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_7
cls & echo [Запуск] CHKDSK /scan... & chkdsk C: /scan
echo [%DATE% %TIME%] Проверка диска CHKDSK. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_8
cls & echo [Запуск] S.M.A.R.T. дисков...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-PhysicalDisk | Select-Object DeviceId, FriendlyName, MediaType, OperationalStatus, HealthStatus | Format-Table -AutoSize"
echo [%DATE% %TIME%] Проверка здоровья дисков S.M.A.R.T. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_9
cls & echo [Запуск] Бэкап драйверов...
if /i "%SCRIPT_DIR:~0,3%"=="C:\" (set "BACKUP_PATH=%USERPROFILE%\Desktop\Drivers_Backup_%COMPUTERNAME%") else (set "BACKUP_PATH=%SCRIPT_DIR%Drivers_Backup_%COMPUTERNAME%")
if not exist "%BACKUP_PATH%" mkdir "%BACKUP_PATH%"
dism /online /export-driver /destination:"%BACKUP_PATH%"
echo [%DATE% %TIME%] Бэкап драйверов в %BACKUP_PATH%. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_10
cls & echo [Запуск] Восстановление драйверов...
set "RESTORE_PATH="
if exist "%SCRIPT_DIR%Drivers_Backup_%COMPUTERNAME%" set "RESTORE_PATH=%SCRIPT_DIR%Drivers_Backup_%COMPUTERNAME%"
if exist "%USERPROFILE%\Desktop\Drivers_Backup_%COMPUTERNAME%" set "RESTORE_PATH=%USERPROFILE%\Desktop\Drivers_Backup_%COMPUTERNAME%"
if not defined RESTORE_PATH for /d %%d in ("%SCRIPT_DIR%Drivers_Backup_*") do set "RESTORE_PATH=%%d"
if not defined RESTORE_PATH set /p RESTORE_PATH="Укажите путь к папке бэкапа: "
if not exist "%RESTORE_PATH%\" echo [ОШИБКА] Папка не найдена! & pause & goto Menu
pnputil /add-driver "%RESTORE_PATH%\*.inf" /subdirs /install
echo [%DATE% %TIME%] Восстановление драйверов из %RESTORE_PATH%. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_11
cls
echo [Запуск] Ремонт Центра Обновлений...
echo 1. Принудительно отключаем и глушим службы...
sc config wuauserv start= disabled >nul 2>&1
sc config bits start= disabled >nul 2>&1
sc config cryptSvc start= disabled >nul 2>&1
sc config msiserver start= disabled >nul 2>&1
taskkill /f /fi "SERVICES eq wuauserv" >nul 2>&1
taskkill /f /fi "SERVICES eq bits" >nul 2>&1
taskkill /f /fi "SERVICES eq cryptSvc" >nul 2>&1
taskkill /f /fi "SERVICES eq msiserver" >nul 2>&1
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop msiserver >nul 2>&1
echo 2. Ожидаем освобождения системных файлов (3 сек)...
timeout /t 3 /nobreak >nul
echo 3. Сбрасываем кэш обновлений...
if exist "%SystemRoot%\SoftwareDistribution" (
    rmdir /s /q "%SystemRoot%\SoftwareDistribution" >nul 2>&1 || move "%SystemRoot%\SoftwareDistribution" "%SystemRoot%\SoftwareDistribution.old" >nul 2>&1
)
if exist "%SystemRoot%\System32\catroot2" (
    rmdir /s /q "%SystemRoot%\System32\catroot2" >nul 2>&1 || move "%SystemRoot%\System32\catroot2" "%SystemRoot%\catroot2.old" >nul 2>&1
)
echo 4. Возвращаем службы в авторежим и запускаем...
sc config wuauserv start= demand >nul 2>&1 || sc config wuauserv start= auto >nul 2>&1
sc config bits start= auto >nul 2>&1
sc config cryptSvc start= auto >nul 2>&1
sc config msiserver start= demand >nul 2>&1
net start msiserver >nul 2>&1
net start cryptSvc >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
echo [УСПЕШНО] Центр обновлений полностью сброшен и реанимирован!
echo [%DATE% %TIME%] Жесткий сброс Центра Обновлений Windows. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_12
cls
echo [Запуск] Сбор информации о системе...
echo -----------------------------------------------------------------------
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cpu = (Get-CimInstance Win32_Processor).Name; $gpus = (Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join ' / '; $ram = [Math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB); Write-Host 'Процессор:  ' $cpu; Write-Host 'Видеокарта: ' $gpus; Write-Host 'ОЗУ (RAM):  ' $ram 'GB'"
echo -----------------------------------------------------------------------
echo [%DATE% %TIME%] Выгружена сводная информация о железе ПК. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_13
cls
echo [Запуск] Оптимизация Windows (Телеметрия + Твики)...
echo 1. Отключение гибернации (Освобождение места на диске C)...
powercfg -h off >nul 2>&1
echo 2. Блокировка служб телеметрии и слежки...
sc config DiagTrack start= disabled >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
net stop DiagTrack >nul 2>&1
net stop dmwappushservice >nul 2>&1
echo 3. Очистка мусорной автозагрузки в реестре...
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "BrowserAssistant" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "BrowserAssistant" /f >nul 2>&1
echo [УСПЕШНО] Система успешно оптимизирована!
echo [%DATE% %TIME%] Выполнено отключение телеметрии, гибернации и чистка автозагрузки. >> "%REPORT_FILE%"
pause & goto Menu

:Mod_14
cls & echo Сессия завершена. Лог: %REPORT_FILE%
echo [%DATE% %TIME%] Работа завершена. >> "%REPORT_FILE%"
echo --------------------------------- >> "%REPORT_FILE%"
pause & exit /b