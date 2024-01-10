@echo off
setlocal EnableDelayedExpansion

set "DB_FILE=database.yml"

:generate_random_mac
set "random_mac="
for /L %%i in (1,1,12) do (
    set /A "rand=0x!random! %% 16"
    set "random_mac=!random_mac!!rand!"
)

:display_interface_info
echo Um fortzufahren, benötigst du Informationen über deine Netzwerkschnittstelle (z.B., Ethernet oder WLAN).
ipconfig /all

:set_interface
set /p "interface=Gib den Namen der Schnittstelle ein: "
ipconfig | find "!interface!:" >nul
if errorlevel 1 (
    echo Schnittelle %interface% nicht gefunden. Das Skript wird beendet.
    exit /b 1
)

:read_original_mac
set "original_mac="
for /f "tokens=2 delims=:" %%a in ('ipconfig /all ^| find "!interface!:"') do (
    for /f "tokens=*" %%b in ("%%a") do set "original_mac=%%b"
)

:read_previous_mac
set "previous_mac="
for /f "tokens=2 delims=: " %%a in ('findstr /C:"previous_mac:" "%DB_FILE%"') do set "previous_mac=%%a"

:update_db_file
(
    echo original_mac: !original_mac!
    echo previous_mac: !previous_mac!
    echo interface: !interface!
) >"%DB_FILE%"

:restore_original_mac
set /p "restore_original_mac=Möchtest du die ursprüngliche MAC-Adresse wiederherstellen? (ja/nein): "
if /i "!restore_original_mac!" equ "ja" (
    set "new_mac=!original_mac!"
) else (
    :generate_or_input_mac
    set /p "random_mac_choice=Möchtest du eine zufällige MAC-Adresse generieren? (ja/nein): "
    if /i "!random_mac_choice!" equ "ja" (
        set "new_mac=!random_mac!"
    ) else (
        set /p "new_mac=Gib die gewünschte MAC-Adresse ein (Format: XX:XX:XX:XX:XX:XX): "
    )
)

:change_mac
netsh interface set interface "!interface!" admin=disable
netsh interface set interface "!interface!" newmac=!new_mac!
netsh interface set interface "!interface!" admin=enable

:update_previous_mac
echo previous_mac: !new_mac! >>"%DB_FILE%"

:display_result
echo Neue MAC-Adresse wurde für !interface! gesetzt.
exit /b 0

