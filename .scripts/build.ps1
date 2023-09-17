Param(
    [string]$srcDirectory, # the path that contains your mod's .XCOM_sln
    [string]$sdkPath, # the path to your SDK installation ending in "XCOM 2 War of the Chosen SDK"
    [string]$gamePath, # the path to your XCOM 2 installation ending in "XCOM2-WaroftheChosen"
    [string]$config # build configuration
)

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$common = Join-Path -Path $ScriptDirectory "X2ModBuildCommon\build_common.ps1"
Write-Host "Sourcing $common"
. ($common)

$builder = [BuildProject]::new("X2WOTCCommunityHighlander", $srcDirectory, $sdkPath, $gamePath)

$compiletest = $false

Write-Host "Configuration: $($config)"

switch ($config)
{
    "debug" {
        $builder.EnableDebug()
    }
    "compiletest" {
        $builder.EnableDebug()
        $compiletest = $true
    }
    "default" { }
    "final_release" {
        $builder.EnableFinalRelease()
    }
    "stable" {
        $builder.EnableFinalRelease()
    }
    "" { ThrowFailure "Missing build configuration" }
    default { ThrowFailure "Unknown build configuration $config" }
}

$builder.IncludeSrc("$srcDirectory\Components\DLC2CommunityHighlander\DLC2CommunityHighlander\Src")

if (Test-Path "$srcDirectory\WorkshopID")
{
    if ($config -eq "stable")
    {
        Write-Host "Setting workshop ID for stable mod"
        $modPublishedId = Get-Content -Path "$srcDirectory\WorkshopID\stable\PublishedFileId.ID"
    }
    else 
    {
        Write-Host "Setting workshop ID for beta mod"
        $modPublishedId = Get-Content -Path "$srcDirectory\WorkshopID\beta\PublishedFileId.ID"
    }
    $builder.SetWorkshopID($modPublishedId)
}

$builder.AddPreMakeHook({
    if ($config -ne "stable") {
        Write-Host "Updating version and commit..."
        & "$srcDirectory\.scripts\update_version.ps1" -ps "$srcDirectory\VERSION.ps1" -srcDirectory "$sdkPath\Development\Src\" -use_commit
    } else {
        Write-Host "Updating version..."
        & "$srcDirectory\.scripts\update_version.ps1" -ps "$srcDirectory\VERSION.ps1" -srcDirectory "$sdkPath\Development\Src\"
    }
    
    Write-Host "Updated."
})

if ($compiletest) {
    $builder.AddPreMakeHook({
        Write-Host "Including CHL_Event_Compiletest"
        # n.b. this copies from the `target` directory where it is generated into, see tasks.json
        Copy-Item ".\target\CHL_Event_Compiletest.uc" "$sdkPath\Development\Src\X2WOTCCommunityHighlander\Classes\" -Force -WarningAction SilentlyContinue
    })
}

$builder.InvokeBuild()
