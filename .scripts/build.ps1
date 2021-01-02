Param(
    [string]$mod, # your mod's name - this shouldn't have spaces or special characters, and it's usually the name of the first directory inside your mod's source dir
    [string]$srcDirectory, # the path that contains your mod's .XCOM_sln
    [string]$sdkPath, # the path to your SDK installation ending in "XCOM 2 War of the Chosen SDK"
    [string]$gamePath, # the path to your XCOM 2 installation ending in "XCOM2-WaroftheChosen"
    [switch]$final_release,
    [switch]$debug,
    [switch]$include_compiletest,
    [switch]$stableModId
)

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$common = Join-Path -Path $ScriptDirectory "build_common.ps1"
Write-Host $common
. ($common)

# This doesn't work yet, but it might at some point
#Clear-Host

$builder = [BuildProject]::new($mod, $srcDirectory, $sdkPath, $gamePath)

if ($include_compiletest) {
    $builder.EnableCompileTest()
}

if ($debug) {
    $builder.EnableDebug()
}

if ($final_release) {
    $builder.EnableFinalRelease()
}

if (Test-Path "$srcDirectory\WorkshopID")
{
    if ($stableModId -eq $true)
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
    if ($final_release) {
        Write-Host "Updating version..."
        & "$srcDirectory\.scripts\update_version.ps1" -ps "$srcDirectory\VERSION.ps1" -srcDirectory "$sdkPath\Development\Src\"
    } else {
        Write-Host "Updating version and commit..."
        & "$srcDirectory\.scripts\update_version.ps1" -ps "$srcDirectory\VERSION.ps1" -srcDirectory "$sdkPath\Development\Src\" -use_commit
    }
    
    Write-Host "Updated."
})

$builder.InvokeBuild()

# we made it!
SuccessMessage("*** SUCCESS! ***", $modNameCanonical)