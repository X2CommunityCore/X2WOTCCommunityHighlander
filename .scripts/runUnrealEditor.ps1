Param(
    [string]$sdkPath # the path to your XCOM 2 installation ending in "XCOM 2 War of the Chosen SDK"
)

& "$sdkPath/Binaries/Win64/XComGame.exe" editor -noscriptcompile -nogadwarning