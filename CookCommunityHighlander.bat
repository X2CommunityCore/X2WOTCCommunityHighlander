@echo off
pushd "%~dp0"
SetLocal EnableDelayedExpansion

REM Set the variables below with your game and SDK filepaths, then run the script. Each value should end with double quotes
REM Each variable should be formatted like this "SDKLocation=.\steamapps\common\XCOM 2 War of the Chosen SDK"
SET "SDKLocation=.\steamapps\common\XCOM 2 War of the Chosen SDK"
SET "GameLocation=.\steamapps\common\XCOM 2\XCom2-WarOfTheChosen"

REM Verify folders exist before proceeding
echo Verifying SDK and game folders exist...
if not exist "%SDKLocation%" GOTO MissingSDKFolder
if not exist "%GameLocation%" GOTO MissingGameFolder

REM One time only: Create the CookedPCConsole folders in the SDK and output mod directory
echo.
if not exist "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole" (
echo. 
echo Creating CookedPCConsole Mod directory... 
mkdir "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole"
)
if not exist "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole" (
echo. 
echo Creating CookedPCConsole SDK directory... 
mkdir "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole" 
)
if not exist "%SDKLocation%\XComGame\Published" (
echo. 
echo Creating Published SDK directory... 
mkdir "%SDKLocation%\XComGame\Published" 
)
if not exist "%SDKLocation%\XComGame\Published\CookedPCConsole" (
echo. 
echo Creating Published\CookedPCConsole SDK directory... 
mkdir "%SDKLocation%\XComGame\Published\CookedPCConsole" 
)

REM One time only: Copy specific CookedPCConsole files from vanilla to the SDK, if they don't exist. These are required for a successful cook.
if not exist "%SDKLocation%\XComGame\Published\CookedPCConsole\GuidCache.upk" (
echo.
echo Copying GuidCache.upk to CookedPCConsole folder...
copy /Y "%GameLocation%\XComGame\CookedPCConsole\GuidCache.upk" "%SDKLocation%\XComGame\Published\CookedPCConsole\GuidCache.upk"
)
if not exist "%SDKLocation%\XComGame\Published\CookedPCConsole\GlobalPersistentCookerData.upk" (
echo.
echo Copying GlobalPersistentCookerData.upk to CookedPCConsole folder...
copy /Y "%GameLocation%\XComGame\CookedPCConsole\GlobalPersistentCookerData.upk" "%SDKLocation%\XComGame\Published\CookedPCConsole\GlobalPersistentCookerData.upk"
)
if not exist "%SDKLocation%\XComGame\Published\CookedPCConsole\PersistentCookerShaderData.bin" (
echo.
echo Copying PersistentCookerShaderData.bin to CookedPCConsole folder...
copy /Y "%GameLocation%\XComGame\CookedPCConsole\PersistentCookerShaderData.bin" "%SDKLocation%\XComGame\Published\CookedPCConsole\PersistentCookerShaderData.bin"
)
if not exist "%SDKLocation%\XComGame\Published\CookedPCConsole\*.tfc" (
echo.
echo Copying .tfc files to CookedPCConsole folder...
robocopy "%GameLocation%\XComGame\CookedPCConsole" "%SDKLocation%\XComGame\Published\CookedPCConsole" *.tfc /njh
)

echo.
echo Making final release...
"%SDKLocation%\Binaries\Win64\XComGame.exe" make -final_release -full -nopause
if %ERRORLEVEL% NEQ 0 GOTO BUILD_ERROR

echo.
echo Cooking packages...
"%SDKLocation%\Binaries\Win64\XComGame.exe" CookPackages -platform=pcconsole -final_release -quickanddirty -modcook -sha -multilanguagecook=INT+FRA+ITA+DEU+RUS+POL+KOR+ESN -singlethread -nopause
if %ERRORLEVEL% NEQ 0 GOTO BUILD_ERROR

echo.
echo Copying XComGame.upk to local Highlander mod folder...
copy /Y "%SDKLocation%\XComGame\Published\CookedPCConsole\XComGame.upk" "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\XComGame.upk"
copy /Y "%SDKLocation%\XComGame\Published\CookedPCConsole\XComGame.upk.uncompressed_size" "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\XComGame.upk.uncompressed_size"

echo.
echo Copying XComGame.upk to SDK Highlander mod folder...
copy /Y "%SDKLocation%\XComGame\Published\CookedPCConsole\XComGame.upk" "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\XComGame.upk"
copy /Y "%SDKLocation%\XComGame\Published\CookedPCConsole\XComGame.upk.uncompressed_size" "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\XComGame.upk.uncompressed_size"

echo.
echo Copying Engine.upk to local Highlander mod folder...
copy /Y "%SDKLocation%\XComGame\Published\CookedPCConsole\Engine.upk" "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\Engine.upk"
copy /Y "%SDKLocation%\XComGame\Published\CookedPCConsole\Engine.upk.uncompressed_size" "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\Engine.upk.uncompressed_size"

echo.
echo Copying Engine.upk to SDK Highlander mod folder...
copy /Y "%SDKLocation%\XComGame\Published\CookedPCConsole\Engine.upk" "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\Engine.upk"
copy /Y "%SDKLocation%\XComGame\Published\CookedPCConsole\Engine.upk.uncompressed_size" "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\Engine.upk.uncompressed_size"

echo.
echo Cleaning up...
if exist "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\Script\XComGame.u" del "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\Script\XComGame.u"
if exist "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\Script\XComGame.u" del "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\Script\XComGame.u"
if exist "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\Script\Engine.u" del "%GameLocation%\XComGame\Mods\X2WOTCCommunityHighlander\Script\Engine.u"
if exist "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\Script\Engine.u" del "%SDKLocation%\XComGame\Mods\X2WOTCCommunityHighlander\Script\Engine.u"

echo.
echo.
echo Done.
GOTO END

:MissingSDKFolder
echo The folder '%SDKLocation%' does not exist. Please edit the SDKLocation variable in the script and retry.
GOTO END

:MissingGameFolder
echo The folder '%GameLocation%' does not exist. Please edit the GameLocation variable in the script and retry.
GOTO END

:BUILD_ERROR
echo Errors occured^^! Exit Code: %ERRORLEVEL%
echo.
set /p OpenLogfile=Open the build logfile to review errors [y/n]?: 
if !OpenLogfile!==y "%SDKLocation%\XComGame\Logs\Launch.log"
GOTO END


:END

popd
pause
