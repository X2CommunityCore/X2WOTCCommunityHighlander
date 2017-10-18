".\steamapps\common\XCOM 2 War of the Chosen SDK\Binaries\Win64\XComGame.exe" make -final_release -full
".\steamapps\common\XCOM 2 War of the Chosen SDK\Binaries\Win64\XComGame.exe" CookPackages -platform=pcconsole -final_release -quickanddirty -modcook -sha -multilanguagecook=INT+FRA+ITA+DEU+RUS+POL+KOR+ESN -singlethread -tfcsuffix=_XPACK_
if not exist ".\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole" mkdir ".\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole" 
if not exist ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole" mkdir ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole" 
copy /Y ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole\XComGame.upk" ".\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\XComGame.upk"
copy /Y ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole\XComGame.upk.uncompressed_size" ".\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\XComGame.upk.uncompressed_size"
copy /Y ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole\XComGame.upk" ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\XComGame.upk"
copy /Y ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole\XComGame.upk.uncompressed_size" ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\XComGame.upk.uncompressed_size"
del ".\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\X2WOTCCommunityHighlander\Script\XComGame.u"
del ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Mods\X2WOTCCommunityHighlander\Script\XComGame.u"

copy /Y ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole\Engine.upk" ".\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\Engine.upk"
copy /Y ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole\Engine.upk.uncompressed_size" ".\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\Engine.upk.uncompressed_size"
copy /Y ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole\Engine.upk" ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\Engine.upk"
copy /Y ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Published\CookedPCConsole\Engine.upk.uncompressed_size" ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Mods\X2WOTCCommunityHighlander\CookedPCConsole\Engine.upk.uncompressed_size"
del ".\steamapps\common\XCOM 2\XCom2-WarOfTheChosen\XComGame\Mods\X2WOTCCommunityHighlander\Script\Engine.u"
del ".\steamapps\common\XCOM 2 War of the Chosen SDK\XComGame\Mods\X2WOTCCommunityHighlander\Script\Engine.u"

pause
