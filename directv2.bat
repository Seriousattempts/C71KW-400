@echo off
setlocal enabledelayedexpansion
color 0A

echo ========================================
echo  DirecTV C71KW-400 Setup
echo  - Bloatware Removal
echo  - APK Install from Subfolder
echo  - Projectivy Launcher Setup
echo ========================================
echo.

REM ===== STEP 1: UNINSTALL AND DISABLE BLOATWARE =====
echo [STEP 1] Uninstalling and disabling bloatware...
echo ========================================

REM AT&T / DirecTV (keeping remote and network services)
adb shell pm uninstall -k --user 0 com.att.tv.openvideo 2>nul
adb shell pm disable-user --user 0 com.att.tv.openvideo 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.core 2>nul
adb shell pm disable-user --user 0 com.att.ngc.core 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.overlay 2>nul
adb shell pm disable-user --user 0 com.att.ngc.overlay 2>nul
adb shell pm uninstall -k --user 0 com.glance.tv.directv 2>nul
adb shell pm disable-user --user 0 com.glance.tv.directv 2>nul
adb shell pm uninstall -k --user 0 com.directv.tv.vplinstaller 2>nul
adb shell pm disable-user --user 0 com.directv.tv.vplinstaller 2>nul
adb shell pm uninstall -k --user 0 com.directv.rvuhalservice 2>nul
adb shell pm disable-user --user 0 com.directv.rvuhalservice 2>nul
adb shell pm uninstall -k --user 0 com.directv.ngc.electionhq 2>nul
adb shell pm disable-user --user 0 com.directv.ngc.electionhq 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.ngc_hwmonitor 2>nul
adb shell pm disable-user --user 0 com.att.ngc.ngc_hwmonitor 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.report.error 2>nul
adb shell pm disable-user --user 0 com.att.ngc.report.error 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.log 2>nul
adb shell pm disable-user --user 0 com.att.ngc.log 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.logreporting 2>nul
adb shell pm disable-user --user 0 com.att.ngc.logreporting 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc_swmonitor 2>nul
adb shell pm disable-user --user 0 com.att.ngc_swmonitor 2>nul
adb shell pm uninstall -k --user 0 com.att.oskservice 2>nul
adb shell pm disable-user --user 0 com.att.oskservice 2>nul
adb shell pm uninstall -k --user 0 com.att.shm.atl 2>nul
adb shell pm disable-user --user 0 com.att.shm.atl 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.ledmanagerservice 2>nul
adb shell pm disable-user --user 0 com.att.ngc.ledmanagerservice 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.notificationservice 2>nul
adb shell pm disable-user --user 0 com.att.ngc.notificationservice 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.security.securityservice 2>nul
adb shell pm disable-user --user 0 com.att.ngc.security.securityservice 2>nul
adb shell pm uninstall -k --user 0 com.att.gem.security.securityservice 2>nul
adb shell pm disable-user --user 0 com.att.gem.security.securityservice 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.securestore.service 2>nul
adb shell pm disable-user --user 0 com.att.ngc.securestore.service 2>nul
adb shell pm uninstall -k --user 0 com.att.ngc.uspservice 2>nul
adb shell pm disable-user --user 0 com.att.ngc.uspservice 2>nul
adb shell pm uninstall -k --user 0 android.autoinstalls.config.att 2>nul
adb shell pm disable-user --user 0 android.autoinstalls.config.att 2>nul

echo [+] ATT/DirecTV services uninstalled and disabled

REM Streaming apps
adb shell pm uninstall -k --user 0 com.netflix.ninja 2>nul
adb shell pm disable-user --user 0 com.netflix.ninja 2>nul
adb shell pm uninstall -k --user 0 com.peacocktv.peacockandroid 2>nul
adb shell pm disable-user --user 0 com.peacocktv.peacockandroid 2>nul
adb shell pm uninstall -k --user 0 com.weathergroup.localnow 2>nul
adb shell pm disable-user --user 0 com.weathergroup.localnow 2>nul
adb shell pm uninstall -k --user 0 com.pandora.android.atv 2>nul
adb shell pm disable-user --user 0 com.pandora.android.atv 2>nul
adb shell pm uninstall -k --user 0 com.espn.score_center 2>nul
adb shell pm disable-user --user 0 com.espn.score_center 2>nul
adb shell pm uninstall -k --user 0 com.playworks.freegames 2>nul
adb shell pm disable-user --user 0 com.playworks.freegames 2>nul
adb shell pm uninstall -k --user 0 com.amazon.amazonvideo.livingroom 2>nul
adb shell pm disable-user --user 0 com.amazon.amazonvideo.livingroom 2>nul
adb shell pm uninstall -k --user 0 com.discovery.discoveryplus.mobile 2>nul
adb shell pm disable-user --user 0 com.discovery.discoveryplus.mobile 2>nul
adb shell pm uninstall -k --user 0 com.hulu.livingroomplus 2>nul
adb shell pm disable-user --user 0 com.hulu.livingroomplus 2>nul
adb shell pm uninstall -k --user 0 com.wbd.stream 2>nul
adb shell pm disable-user --user 0 com.wbd.stream 2>nul
adb shell pm uninstall -k --user 0 com.disney.disneyplus 2>nul
adb shell pm disable-user --user 0 com.disney.disneyplus 2>nul
adb shell pm uninstall -k --user 0 com.apple.atve.androidtv.appletv 2>nul
adb shell pm disable-user --user 0 com.apple.atve.androidtv.appletv 2>nul

echo [+] Streaming apps uninstalled and disabled

REM Google bloat (keeping core services, YouTube kept)
adb shell pm uninstall -k --user 0 com.google.android.katniss 2>nul
adb shell pm disable-user --user 0 com.google.android.katniss 2>nul
adb shell pm uninstall -k --user 0 com.google.android.apps.mediashell 2>nul
adb shell pm disable-user --user 0 com.google.android.apps.mediashell 2>nul
adb shell pm uninstall -k --user 0 com.google.android.tvrecommendations 2>nul
adb shell pm disable-user --user 0 com.google.android.tvrecommendations 2>nul
adb shell pm uninstall -k --user 0 com.google.android.backdrop 2>nul
adb shell pm disable-user --user 0 com.google.android.backdrop 2>nul
adb shell pm uninstall -k --user 0 com.google.android.play.games 2>nul
adb shell pm disable-user --user 0 com.google.android.play.games 2>nul
adb shell pm uninstall -k --user 0 com.google.android.feedback 2>nul
adb shell pm disable-user --user 0 com.google.android.feedback 2>nul
adb shell pm uninstall -k --user 0 com.google.android.marvin.talkback 2>nul
adb shell pm disable-user --user 0 com.google.android.marvin.talkback 2>nul
adb shell pm uninstall -k --user 0 com.google.android.tungsten.setupwraith 2>nul
adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith 2>nul

echo [+] Google extras uninstalled and disabled

REM System updates
adb shell pm uninstall -k --user 0 com.android.dynsystem 2>nul
adb shell pm disable-user --user 0 com.android.dynsystem 2>nul
adb shell pm uninstall -k --user 0 com.android.managedprovisioning 2>nul
adb shell pm disable-user --user 0 com.android.managedprovisioning 2>nul
adb shell settings put global ota_disable_automatic_update 1 2>nul

echo [+] System update packages uninstalled and disabled
echo.

REM ===== STEP 2: FIND APK SUBFOLDER =====
echo [STEP 2] Locating APK files...
echo ========================================
echo.
echo Current directory: %cd%
echo.

set "apk_subfolder="
set "skip_apks=0"
set "apk_count=0"

set /p apk_subfolder="Enter subfolder name containing APKs (press Enter to skip): "

if "!apk_subfolder!"=="" (
    echo [~] Skipping APK installation
    set "skip_apks=1"
    goto step3
)

set "apk_dir=%cd%\!apk_subfolder!"

if not exist "!apk_dir!" (
    echo [!] Folder "!apk_dir!" not found - skipping APK installation
    set "skip_apks=1"
    goto step3
)

for /f "delims=" %%f in ('dir /b /a-d "!apk_dir!\*.apk" 2^>nul') do set /a apk_count+=1

if !apk_count!==0 (
    echo [!] No .apk files found in "!apk_dir!" - skipping APK installation
    set "skip_apks=1"
    goto step3
)

echo [+] Found !apk_count! APK file(s):
for /f "delims=" %%f in ('dir /b /a-d "!apk_dir!\*.apk" 2^>nul') do echo     - %%f
echo.

:step3
REM ===== STEP 3: DISABLE VERIFIER =====
echo [STEP 3] Disabling package verifier...
echo ========================================
adb shell settings put global verifier_verify_adb_installs 0 2>nul
adb shell settings put global package_verifier_enable 0 2>nul
echo [+] Verifier disabled
echo.

if "!skip_apks!"=="1" goto step5

REM ===== STEP 4: INSTALL APKs =====
echo [STEP 4] Installing APKs...
echo ========================================
echo.

set "installed=0"
set "failed=0"
set "current=1"
set "projectivy_detected=0"

for /f "delims=" %%f in ('dir /b /a-d "!apk_dir!\*.apk" 2^>nul') do (
    set "apk_filename=%%f"
    set "apk_fullpath=!apk_dir!\%%f"
    set "push_failed=0"

    echo ----------------------------------------
    echo [!current!/!apk_count!] Installing %%f
    echo ----------------------------------------

    adb push "!apk_fullpath!" /data/local/tmp/%%f
    if errorlevel 1 (
        echo [!] Push failed: %%f
        set /a failed+=1
        set "push_failed=1"
    )

    if "!push_failed!"=="0" (
        adb shell pm install -r -d -g /data/local/tmp/%%f
        if errorlevel 1 (
            echo [!] Install failed: %%f
            set /a failed+=1
        ) else (
            echo [+] Installed: %%f
            set /a installed+=1

            echo !apk_filename! | findstr /I "projectiv" >nul 2>&1
            if not errorlevel 1 (
                set "projectivy_detected=1"
                echo [*] Projectivy detected from filename
            )
        )
        adb shell rm /data/local/tmp/%%f >nul 2>&1
    )

    echo.
    set /a current+=1
)

echo ========================================
echo  INSTALL SUMMARY
echo ========================================
echo Total APKs:             !apk_count!
echo Successfully installed: !installed!
echo Failed:                 !failed!
echo.

:step5
REM ===== STEP 5: SET PROJECTIVY AS LAUNCHER =====
if "!projectivy_detected!"=="1" (
    echo [STEP 5] Configuring Projectivy Launcher...
    echo ========================================
    echo.

    adb shell pm list packages > temp_packages.txt 2>nul
    set "projectivy_package="
    for /f "tokens=2 delims=:" %%p in ('findstr /I "projectiv" temp_packages.txt') do set "projectivy_package=%%p"
    del temp_packages.txt >nul 2>&1

    if not "!projectivy_package!"=="" (
        echo [+] Projectivy package: !projectivy_package!
        echo.
        echo [*] Setting Projectivy as HOME...
        adb shell cmd role add-role-holder android.app.role.HOME !projectivy_package! 2>nul
        adb shell cmd package set-home-activity !projectivy_package! 2>nul
        timeout /t 2 /nobreak >nul
        adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME 2>nul

        echo [+] Projectivy Launcher configured
        echo.
        echo [*] Uninstalling and disabling stock launchers...
        adb shell pm uninstall -k --user 0 com.directv.tv.dtvlauncher 2>nul
        adb shell pm disable-user --user 0 com.directv.tv.dtvlauncher 2>nul
        adb shell pm uninstall -k --user 0 com.att.ngc.fallbackhome 2>nul
        adb shell pm disable-user --user 0 com.att.ngc.fallbackhome 2>nul
        adb shell pm uninstall -k --user 0 com.google.android.tvlauncher 2>nul
        adb shell pm disable-user --user 0 com.google.android.tvlauncher 2>nul
        echo [+] Stock launchers uninstalled and disabled
    ) else (
        echo [!] Could not resolve Projectivy package
        echo [*] Set it manually by pressing HOME button
    )
    echo.
) else (
    echo [STEP 5] Projectivy not detected, skipping launcher setup
    echo.
)

echo ========================================
echo  ALL DONE
echo ========================================
echo.
echo Summary:
echo - Bloatware uninstalled and disabled: 34 packages
echo - YouTube: KEPT ENABLED
echo - Remote services: KEPT ENABLED
echo - Network services: KEPT ENABLED for ADB
if "!skip_apks!"=="1" (
    echo - APK installation: SKIPPED
) else (
    echo - APKs installed: !installed!/!apk_count!
)
echo - System updates: DISABLED
echo.
echo Press HOME button to select Projectivy Launcher if needed.
echo.
set /p reboot_choice="Reboot now? (Y/N): "
if /i "!reboot_choice!"=="Y" (
    echo.
    echo [*] Rebooting device...
    adb reboot
    echo Device is rebooting...
) else (
    echo.
    echo [*] Reboot skipped
    echo     Run "adb reboot" when ready
)
echo.
pause
