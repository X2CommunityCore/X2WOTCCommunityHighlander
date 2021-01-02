Param(
    [string]$srcDirectory, # the path that contains your mod's .XCOM_sln
    [string]$sdkPath, # the path to your SDK installation ending in "XCOM 2 War of the Chosen SDK"
    [string]$gamePath, # the path to your XCOM 2 installation ending in "XCOM 2"
    [string]$config # build configuration
)

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$common = Join-Path -Path $ScriptDirectory "..\..\..\.scripts\build_common.ps1"
Write-Host $common
. ($common)

try {
    $builder = [BuildProject]::new("DLC2CommunityHighlander", $srcDirectory, $sdkPath, $gamePath)

    switch ($config)
    {
        "debug" {
            $builder.EnableDebug()
        }
        "default" {
        }
        "" { ThrowFailure "Missing build configuration" }
        default { ThrowFailure "Unknown build configuration $config" }
    }

    $builder.IncludeSrc("$srcDirectory\..\..\X2WOTCCommunityHighlander\Src")
    $builder.InvokeBuild()
    # we made it!
    SuccessMessage "*** SUCCESS! ***" "DLC2CommunityHighlander"
} catch {
    FailureMessage $_
    exit
}