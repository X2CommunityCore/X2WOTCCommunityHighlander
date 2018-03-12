Param(
    [string]$mod, # your mod's name - this shouldn't have spaces or special characters, and it's usually the name of the first directory inside your mod's source dir
    [string]$srcDirectory, # the path that contains your mod's .XCOM_sln
    [string]$sdkPath, # the path to your SDK installation ending in "XCOM 2 War of the Chosen SDK"
    [string]$gamePath, # the path to your XCOM 2 installation ending in "XCOM2-WaroftheChosen"
    [switch]$final_release
)

function WriteModMetadata([string]$mod, [string]$sdkPath, [int]$publishedId, [string]$title, [string]$description) {
    Set-Content "$sdkPath/XComGame/Mods/$mod/$mod.XComMod" "[mod]`npublishedFileId=$publishedId`nTitle=$title`nDescription=$description`nRequiresXPACK=true"
}

# Helper for invoking the make cmdlet. Captures stdout/stderr and rewrites error and warning lines to fix up the
# source paths. Since make operates on a copy of the sources copied to the SDK folder, diagnostics print the paths
# to the copies. If you try to jump to these files (e.g. by tying this output to the build commands in your editor)
# you'll be editting the copies, which will then be overwritten the next time you build with the sources in your mod folder
# that haven't been changed.
function Invoke-Make([string] $makeCmd, [string] $makeFlags, [string] $sdkPath, [string] $modSrcRoot) {
    # Create a ProcessStartInfo object to hold the details of the make command, its arguments, and set up
    # stdout/stderr redirection.
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $makeCmd
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $makeFlags

    # Create an object to hold the paths we want to rewrite: the path to the SDK 'Development' folder
    # and the 'modSrcRoot' (the directory that holds the .x2proj file). This is needed because the output
    # is read in an action block that is a separate scope and has no access to local vars/parameters of this
    # function.
    $developmentDirectory = Join-Path -Path $sdkPath 'Development'
    $messageData = New-Object psobject -property @{
        developmentDirectory = $developmentDirectory
        modSrcRoot = $modSrcRoot
    }

    # We need another object for the Exited event to set a flag we can monitor from this function.
    $exitData = New-Object psobject -property @{ exited = $false }

    # An action for handling data written to stdout. The make cmdlet writes all warning and error info to
    # stdout, so we look for it here.
    $outAction = {
        $outTxt = $Event.SourceEventArgs.Data
        # Match warning/error lines
        $messagePattern = "^(.*)\(([0-9]*)\) : (.*)$"
        if (($outTxt -Match "Error|Warning") -And ($outTxt -Match $messagePattern)) {
            # And just do a regex replace on the sdk Development directory with the mod src directory.
            # The pattern needs escaping to avoid backslashes in the path being interpreted as regex escapes, etc.
            $pattern = [regex]::Escape($event.MessageData.developmentDirectory)
            # n.b. -Replace is case insensitive
            $replacementTxt = $outtxt -Replace $pattern, $event.MessageData.modSrcRoot
            $outTxt = $replacementTxt -Replace $messagePattern, '$1:$2 : $3'
        }

        $summPattern = "^(Success|Failure) - ([0-9]+) error\(s\), ([0-9]+) warning\(s\) \(([0-9]+) Unique Errors, ([0-9]+) Unique Warnings\)"
        if (-Not ($outTxt -Match "Warning/Error Summary") -And $outTxt -Match "Warning|Error") {
            if ($outTxt -Match $summPattern) {
                $numErr = $outTxt -Replace $summPattern, '$2'
                $numWarn = $outTxt -Replace $summPattern, '$3'
                if (([int]$numErr) -gt 0) {
                    $clr = "Red"
                } elseif (([int]$numWarn) -gt 0) {
                    $clr = "Yellow"
                } else {
                    $clr = "Green"
                }
            } else {
                if ($outTxt -Match "Error") {
                    $clr = "Red"
                } else {
                    $clr = "Yellow"
                }
            }
            Write-Host $outTxt -ForegroundColor $clr
        } else {
            Write-Host $outTxt
        }
    }

    # An action for handling data written to stderr. The make cmdlet doesn't seem to write anything here,
    # or at least not diagnostics, so we can just pass it through.
    $errAction = {
        $errTxt = $Event.SourceEventArgs.Data
        Write-Host $errTxt
    }

    # Set the exited flag on our exit object on process exit.
    $exitAction = {
        $event.MessageData.exited = $true
    }

    # Create the process and register for the various events we care about.
    $process = New-Object System.Diagnostics.Process
    Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action $outAction -MessageData $messageData | Out-Null
    Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action $errAction | Out-Null
    Register-ObjectEvent -InputObject $process -EventName Exited -Action $exitAction -MessageData $exitData | Out-Null
    $process.StartInfo = $pinfo

    # All systems go!
    $process.Start() | Out-Null
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()   

    # Wait for the process to exit. This is horrible, but using $process.WaitForExit() blocks
    # the powershell thread so we get no output from make echoed to the screen until the process finishes.
    # By polling we get regular output as it goes.
    while (!$exitData.exited) {
        Start-Sleep -m 50
    }

    # Explicitly set LASTEXITCODE from the process exit code so the rest of the script
    # doesn't need to care if we launched the process in the background or via "&".
    $global:LASTEXITCODE = $process.ExitCode
}

# This doesn't work yet, but it might at some point
Clear-Host

Write-Host "SDK Path: $sdkPath"
Write-Host "Game Path: $gamePath"

# Check if the user config is set up correctly
if ([string]::IsNullOrEmpty($sdkPath) -or [string]::IsNullOrEmpty($gamePath))
{
    throw "Please set up user config xcom.highlander.sdkroot and xcom.highlander.gameroot"
}

# list of all native script packages
[System.String[]]$basegamescriptpackages = "XComGame", "Core", "Engine", "GFxUI", "AkAudio", "GameFramework", "UnrealEd", "GFxUIEditor", "IpDrv", "OnlineSubsystemPC", "OnlineSubsystemLive", "OnlineSubsystemSteamworks", "OnlineSubsystemPSN"

# alias params for clarity in the script (we don't want the person invoking this script to have to type the name -modNameCanonical)
$modNameCanonical = $mod
# we're going to ask that people specify the folder that has their .XCOM_sln in it as the -srcDirectory argument, but a lot of the time all we care about is
# the folder below that that contains Config, Localization, Src, etc...
$modSrcRoot = "$srcDirectory\$modNameCanonical"

# clean
$stagingPath = "{0}\XComGame\Mods\{1}\" -f $sdkPath, $modNameCanonical
Write-Host "Cleaning mod project at $stagingPath...";
if (Test-Path $stagingPath) {
    Remove-Item $stagingPath -Recurse -WarningAction SilentlyContinue;
}
Write-Host "Cleaned."

# copy source to staging
#StageDirectory "Config" $modSrcRoot $stagingPath
#StageDirectory "Content" $modSrcRoot $stagingPath
#StageDirectory "Localization" $modSrcRoot $stagingPath
#StageDirectory "Src" $modSrcRoot $stagingPath
#Copy-Item "$modSrcRoot" "$sdkPath\XComGame\Mods" -Force -Recurse -WarningAction SilentlyContinue

Robocopy.exe "$modSrcRoot" "$sdkPath\XComGame\Mods\$modNameCanonical" *.* /XD Assets /S /E /DCOPY:DA /COPY:DAT /PURGE /MIR /NP /R:1000000 /W:30
if (Test-Path "$stagingPath\$modNameCanonical.x2proj") {
    Remove-Item "$stagingPath\$modNameCanonical.x2proj"
}

New-Item "$stagingPath/Script" -ItemType Directory

# read mod metadata from the x2proj file
Write-Host "Reading mod metadata from $modSrcRoot\$modNameCanonical.x2proj..."
[xml]$x2projXml = Get-Content -Path "$modSrcRoot\$modNameCanonical.x2proj"
$modProperties = $x2projXml.Project.PropertyGroup
$modPublishedId = $modProperties.SteamPublishID[0]
$modTitle = $modProperties.Name
$modDescription = $modProperties.Description
Write-Host "Read."

# write mod metadata - used by Firaxis' "make" tooling
Write-Host "Writing mod metadata..."
WriteModMetadata -mod $modNameCanonical -sdkPath $sdkPath -publishedId $modPublishedId -title $modTitle -description $modDescription
Write-Host "Written."

# mirror the SDK's SrcOrig to its Src
Write-Host "Mirroring SrcOrig to Src..."
Robocopy.exe "$sdkPath\Development\SrcOrig" "$sdkPath\Development\Src" *.uc *.uci /S /E /DCOPY:DA /COPY:DAT /PURGE /MIR /NP /R:1000000 /W:30
Write-Host "Mirrored."

# copying the mod's scripts to the script staging location
Write-Host "Copying the mod's scripts to Src..."
Copy-Item "$stagingPath\Src\*" "$sdkPath\Development\Src\" -Force -Recurse -WarningAction SilentlyContinue
Write-Host "Copied."

# build package lists we'll need later and delete as appropriate
# all packages we are about to compile
[System.String[]]$allpackages = Get-ChildItem "$sdkPath/Development/Src" -Directory
# the mod's packages
[System.String[]]$thismodpackages = Get-ChildItem "$modSrcRoot/Src" -Directory


Write-Host "Full build requested. Cleaning all compiled scripts from $sdkPath/XComGame/Script..."
Remove-Item "$sdkPath/XComGame/Script/*.u"
Write-Host "Cleaned."

# build the base game scripts
Write-Host "Compiling base game scripts..."
if ($final_release -eq $true)
{
    Invoke-Make "$sdkPath/binaries/Win64/XComGame.com" "make -nopause -unattended -final_release -mods $modNameCanonical $stagingPath" $sdkPath $modSrcRoot
} else {
    Invoke-Make "$sdkPath/binaries/Win64/XComGame.com" "make -nopause -unattended  -mods $modNameCanonical $stagingPath" $sdkPath $modSrcRoot
}
if ($LASTEXITCODE -ne 0)
{
    throw "Failed to compile base game scripts!"
}
Write-Host "Compiled base game scripts."

# build the mod's scripts
Write-Host "Compiling mod scripts..."
# &"$sdkPath/binaries/Win64/XComGame.com" make -nopause -mods $modNameCanonical "$stagingPath"
Invoke-Make "$sdkPath/binaries/Win64/XComGame.com" "make -nopause -mods $modNameCanonical $stagingPath" $sdkPath $modSrcRoot
if ($LASTEXITCODE -ne 0)
{
    throw "Failed to compile mod scripts!"
}
Write-Host "Compiled mod scripts."

# Cook it
# First, make sure the cooking directory is set up
$modcookdir = [io.path]::combine($sdkPath, 'XComGame', 'Published', 'CookedPCConsole')
# Normally, the mod tools create a symlink in the SDK directory to the game CookedPCConsole directory,
# but we'll just be using the game one to make it more robust
$cookedpcconsoledir = [io.path]::combine($gamePath, 'XComGame', 'CookedPCConsole')
if(-not(Test-Path $modcookdir))
{
    Write-Host "Creating Published/CookedPCConsole directory"
    New-Item $modcookdir -ItemType Directory
}

[System.String[]]$files = "GuidCache.upk", "GlobalPersistentCookerData.upk", "PersistentCookerShaderData.bin"
for ($i=0; $i -lt $files.length; $i++) {
    $name = $files[$i]
    if(-not(Test-Path ([io.path]::combine($modcookdir, $name))))
    {
        Write-Host "Copying $name"
        Copy-Item ([io.path]::combine($cookedpcconsoledir, $name)) $modcookdir
    }
}

# Ideally, the cooking process wouldn't modify the big *.tfc files, but it does, so we don't overwrite existing ones (/XC /XN /XO)
# In order to "reset" the cooking direcory, just delete it and let the game recreate them
Write-Host "Copying Texture File Caches"
Robocopy.exe "$cookedpcconsoledir" "$modcookdir" *.tfc /NJH /XC /XN /XO

# Cook it!
Write-Host "Invoking CookPackages"
if ($final_release -eq $true)
{
    & "$sdkPath/binaries/Win64/XComGame.com" CookPackages -platform=pcconsole -final_release -unattended -quickanddirty -modcook -sha -multilanguagecook=INT+FRA+ITA+DEU+RUS+POL+KOR+ESN -singlethread -nopause
} else {
    & "$sdkPath/binaries/Win64/XComGame.com" CookPackages -platform=pcconsole -unattended -quickanddirty -modcook -sha -multilanguagecook=INT+FRA+ITA+DEU+RUS+POL+KOR+ESN -singlethread -nopause
}

if ($LASTEXITCODE -ne 0)
{
    throw "Failed to cook packages"
}

# Create CookedPCConsole folder for the mod
New-Item "$stagingPath/CookedPCConsole" -ItemType Directory

# copy packages to staging
Write-Host "Copying the compiled or cooked packages to staging"
for ($i=0; $i -lt $thismodpackages.length; $i++) {
    $name = $thismodpackages[$i]
    if ($basegamescriptpackages.Contains($name))
    {
        # This is a native (cooked) script package -- copy important upks
        Copy-Item "$modcookdir/$name.upk" "$stagingPath/CookedPCConsole" -Force -WarningAction SilentlyContinue
        Copy-Item "$modcookdir/$name.upk.uncompressed_size" "$stagingPath/CookedPCConsole" -Force -WarningAction SilentlyContinue
        Write-Host "$modcookdir/$name.upk"
    } else {
        # This is a normal script package
        Copy-Item "$sdkPath/XComGame/Script/$name.u" "$stagingPath/Script" -Force -WarningAction SilentlyContinue
        Write-Host "$sdkPath/XComGame/Script/$name.u"        
    }
}
Write-Host "Copied compiled and cooked script packages."


if(Test-Path "$modSrcRoot/Content")
{
    $contentfiles = Get-ChildItem "$modSrcRoot/Content\*"  -Include *.upk, *.umap -Recurse -File -Name
    if($contentfiles.length -lt 0)
    {
        # build the mod's shader cache
        Write-Host "Precompiling Shaders..."
        &"$sdkPath/binaries/Win64/XComGame.com" precompileshaders -nopause platform=pc_sm4 DLC=$modNameCanonical
        if ($LASTEXITCODE -ne 0)
        {
            throw "Failed to compile mod shader cache!"
        }
        Write-Host "Generated Shader Cache."
    }
}

# copy all staged files to the actual game's mods folder
Write-Host "Copying all staging files to production..."
Copy-Item $stagingPath "$gamePath/XComGame/Mods/" -Force -Recurse -WarningAction SilentlyContinue
Write-Host "Copied mod to game directory."

# we made it!
Write-Host "*** SUCCESS! ***"
Write-Host "$modNameCanonical ready to run."