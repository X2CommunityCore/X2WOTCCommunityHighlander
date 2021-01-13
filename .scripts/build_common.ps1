Write-Host "Build Common Loading"

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3.0

$global:def_robocopy_args = @("/S", "/E", "/DCOPY:DA", "/COPY:DAT", "/PURGE", "/MIR", "/NP", "/R:1000000", "/W:30")
# list of all native script packages
$global:nativescriptpackages = @("XComGame", "Core", "Engine", "GFxUI", "AkAudio", "GameFramework", "UnrealEd", "GFxUIEditor", "IpDrv", "OnlineSubsystemPC", "OnlineSubsystemLive", "OnlineSubsystemSteamworks", "OnlineSubsystemPSN")

class BuildProject {
	[string]$modNameCanonical
	[string]$projectRoot
	[string]$sdkPath
	[string]$gamePath
	[int] $publishID = -1
	[bool] $compileTest = $false
	[bool] $debug = $false
	[bool] $final_release = $false
	[string[]] $include = @()
	[string[]] $clean = @()
	[object[]] $preMakeHooks = @()

	# lazily set
	[string] $modSrcRoot
	[string] $devSrcRoot
	[string] $stagingPath
	[string] $modcookdir
	[string[]] $thismodpackages
	[bool] $isHl
	[bool] $cook


	BuildProject(
		[string]$mod,
		[string]$projectRoot,
		[string]$sdkPath,
		[string]$gamePath
	){
		$this.modNameCanonical = $mod
		$this.projectRoot = $projectRoot
		$this.sdkPath = $sdkPath
		$this.gamePath = $gamePath
	}

	[void]SetWorkshopID([int] $publishID) {
		if ($publishID -le 0) { ThrowFailure "publishID must be >0" }
		$this.publishID = $publishID
	}

	[void]EnableCompileTest() {
		$this.compileTest = $true
	}

	[void]EnableFinalRelease() {
		$this.final_release = $true
		$this._CheckFlags()
	}

	[void]EnableDebug() {
		$this.debug = $true
		$this._CheckFlags()
	}

	[void]AddPreMakeHook([Action[]] $action) {
		$this.preMakeHooks += $action
	}

	[void]AddToClean([string] $modName) {
		$this.clean += $modName
	}

	[void]IncludeSrc([string] $src) {
		if (!(Test-Path $src)) { ThrowFailure "include path $src doesn't exist" }
		$this.include += $src
	}

	[void]InvokeBuild() {
		$this._ConfirmPaths()
		$this._SetupUtils()
		$this._ValidateProjectFiles()
		$this._Clean()
		$this._CopyModToSdk()
		$this._ConvertLocalization()
		$this._CopyToSrc()
		$this._RunPreMakeHooks()
		$this._RunMakeBase()
		$this._RunMakeMod()
		if ($this.isHl) {
			if (-not $this.debug) {
				$this._RunCook()
			} else {
				Write-Host "Skipping cooking as debug build"
			}
		}
		$this._CopyScriptPackages()
		$this._PrecompileShaders()
		$this._FinalCopy()
	}

	[void]_CheckFlags() {
		if ($this.debug -eq $true -and $this.final_release -eq $true)
		{
			ThrowFailure "-debug and -final_release cannot be used together"
		}
	}

	[void]_ConfirmPaths() {
		Write-Host "SDK Path: $($this.sdkPath)"
		Write-Host "Game Path: $($this.gamePath)"
	
		# Check if the user config is set up correctly
		if (([string]::IsNullOrEmpty($this.sdkPath) -or $this.sdkPath -eq '${config:xcom.highlander.sdkroot}') -or ([string]::IsNullOrEmpty($this.gamePath) -or $this.gamePath -eq '${config:xcom.highlander.gameroot}'))
		{
			ThrowFailure "Please set up user config xcom.highlander.sdkroot and xcom.highlander.gameroot"
		}
		elseif (!(Test-Path $this.sdkPath)) # Verify the SDK and game paths exist before proceeding
		{
			ThrowFailure ("The path '{}' doesn't exist. Please adjust the xcom.highlander.sdkroot variable in your user config and retry." -f $this.sdkPath)
		}
		elseif (!(Test-Path $this.gamePath)) 
		{
			ThrowFailure ("The path '{}' doesn't exist. Please adjust the xcom.highlander.gameroot variable in your user config and retry." -f $this.gamePath)
		}
	}

	[void]_SetupUtils() {
		$this.modSrcRoot = "$($this.projectRoot)\$($this.modNameCanonical)"
		$this.stagingPath = "$($this.sdkPath)\XComGame\Mods\$($this.modNameCanonical)"
		$this.devSrcRoot = "$($this.sdkPath)\Development\Src"

		# build package lists we'll need later and delete as appropriate
		# the mod's packages
		$this.thismodpackages = Get-ChildItem "$($this.modSrcRoot)/Src" -Directory

		$this.isHl = $this._HasNativePackages()
		$this.cook = $this.isHl -and -not $this.debug

		if (-not $this.isHl -and $this.final_release) {
			ThrowFailure "-final_release only makes sense if the mod in question is a Highlander"
		}

		$this.modcookdir = [io.path]::combine($this.sdkPath, 'XComGame', 'Published', 'CookedPCConsole')

	}

	[void]_CopyModToSdk() {
		$xf = @("*.x2proj")
		if (-not $this.compileTest) {
			$xf += "*_Compiletest.uc"
		}
		
		Write-Host "Copying mod project to staging..."
		Robocopy.exe "$($this.modSrcRoot)" "$($this.sdkPath)\XComGame\Mods\$($this.modNameCanonical)" *.* $global:def_robocopy_args /XF @xf
		Write-Host "Copied project to staging."

		New-Item "$($this.stagingPath)/Script" -ItemType Directory

		# read mod metadata from the x2proj file
		Write-Host "Reading mod metadata from $($this.modSrcRoot)\$($this.modNameCanonical).x2proj..."
		[xml]$x2projXml = Get-Content -Path "$($this.modSrcRoot)\$($this.modNameCanonical).x2proj"
		$modProperties = $x2projXml.Project.PropertyGroup[0]
		$publishedId = $modProperties.SteamPublishID
		if ($this.publishID -ne -1) {
			$publishedId = $this.publishID
			Write-Host "Using override workshop ID of $publishedId"
		}
		$title = $modProperties.Name
		$description = $modProperties.Description
		Write-Host "Read."

		Write-Host "Writing mod metadata..."
		Set-Content "$($this.sdkPath)/XComGame/Mods/$($this.modNameCanonical)/$($this.modNameCanonical).XComMod" "[mod]`npublishedFileId=$publishedId`nTitle=$title`nDescription=$description`nRequiresXPACK=true"
		Write-Host "Written."

		# Create CookedPCConsole folder for the mod
		if ($this.cook) {
			New-Item "$($this.stagingPath)/CookedPCConsole" -ItemType Directory
		}
	}

	# This function verifies that all project files in the mod subdirectories actually exist in the .x2proj file
	[void]_ValidateProjectFiles()
	{
		Write-Host "Checking for missing entries in .x2proj file..."
		$projFilepath = "$($this.modSrcRoot)\$($this.modNameCanonical).x2proj"
		if(Test-Path $projFilepath)
		{
			$missingFiles = New-Object System.Collections.Generic.List[System.Object]
			$projContent = Get-Content $projFilepath
			# Loop through all files in subdirectories and fail the build if any filenames are missing inside the project file
			Get-ChildItem $this.modSrcRoot -Directory | Get-ChildItem -File -Recurse |
			ForEach-Object {
				# Compiletest file is allowed to be missing because it's not commited and manually edited
				If (!($_.Name -Match "_Compiletest\.uc$") -and !($projContent | Select-String -Pattern $_.Name)) {
					$missingFiles.Add($_.Name)
				}
			}

			if ($missingFiles.Count -gt 0)
			{
				ThrowFailure "Filenames missing in the .x2proj file: $missingFiles"
			}
		}
		else
		{
			ThrowFailure "The project file '$projFilepath' doesn't exist"
		}
	}

	
	[void]_Clean() {
		Write-Host "Cleaning mod project at $($this.stagingPath)..."
		if (Test-Path $this.stagingPath) {
			Remove-Item $this.stagingPath -Recurse -WarningAction SilentlyContinue
		}
		Write-Host "Cleaned."

		Write-Host "Cleaning additional mods..."
		# clean
		foreach ($modName in $this.clean) {
			$cleanDir = "$($this.sdkPath)/XComGame/Mods/$($modName)"
    		if (Test-Path $cleanDir) {
				Write-Host "Cleaning $($modName)..."
				Remove-Item -Recurse -Force $cleanDir
			}
    	}
		Write-Host "Cleaned."
	}

	[void]_ConvertLocalization() {
		Write-Host "Converting the localization file encoding..."
		Get-ChildItem "$($this.stagingPath)\Localization" -Recurse -File | 
		Foreach-Object {
			$content = Get-Content $_.FullName
			$content | Out-File $_.FullName -Encoding Unicode
		}
	}

	[void]_CopyToSrc() {
		# mirror the SDK's SrcOrig to its Src
		Write-Host "Mirroring SrcOrig to Src..."
		Robocopy.exe "$($this.sdkPath)\Development\SrcOrig" "$($this.devSrcRoot)" *.uc *.uci $global:def_robocopy_args
		Write-Host "Mirrored SrcOrig to Src."

		# Copy dependencies
		Write-Host "Copying dependency sources to Src..."
		foreach ($depfolder in $this.include) {
			Get-ChildItem "$($depfolder)" -Directory -Name | Write-Host
			$this._CopySrcFolder($depfolder)
		}
		Write-Host "Copied dependency sources to Src."

		# copying the mod's scripts to the script staging location
		Write-Host "Copying the mod's sources to Src..."
		$this._CopySrcFolder("$($this.stagingPath)\Src")
		Write-Host "Copied mod sources to Src."
	}

	[void]_CopySrcFolder([string] $includeDir) {
		Copy-Item "$($includeDir)\*" "$($this.devSrcRoot)\" -Force -Recurse -WarningAction SilentlyContinue
		if (Test-Path "$($includeDir)\extra_globals.uci") {
			# append extra_globals.uci to globals.uci
			Get-Content "$($includeDir)\extra_globals.uci" | Add-Content "$($this.devSrcRoot)\Core\Globals.uci"
		}
	}

	[void]_RunPreMakeHooks() {
		Write-Host "Invoking pre-Make hooks"
		foreach ($hook in $this.preMakeHooks) {
			$hook.Invoke()
		}
	}

	[void]_RunMakeBase() {
		# build the base game scripts
		Write-Host "Compiling base game scripts..."
		$scriptsMakeArguments = "make -nopause -unattended"
		if ($this.final_release -eq $true)
		{
			$scriptsMakeArguments = "$scriptsMakeArguments -final_release"
		}
		if ($this.debug -eq $true)
		{
			$scriptsMakeArguments = "$scriptsMakeArguments -debug"
		}
		Invoke-Make "$($this.sdkPath)/binaries/Win64/XComGame.com" $scriptsMakeArguments $this.sdkPath $this.modSrcRoot
		if ($LASTEXITCODE -ne 0)
		{
			ThrowFailure "Failed to compile base game scripts!"
		}
		Write-Host "Compiled base game scripts."

		# If we build in final release, we must build the normal scripts too
		if ($this.final_release -eq $true)
		{
			Write-Host "Compiling base game scripts without final_release..."
			Invoke-Make "$($this.sdkPath)/binaries/Win64/XComGame.com" "make -nopause -unattended" $this.sdkPath $this.modSrcRoot
			if ($LASTEXITCODE -ne 0)
			{
				ThrowFailure "Failed to compile base game scripts without final_release!"
			}
		}
	}

	[void]_RunMakeMod() {
		# build the mod's scripts
		Write-Host "Compiling mod scripts..."
		$scriptsMakeArguments = "make -nopause -mods $($this.modNameCanonical) $($this.stagingPath)"
		if ($this.debug -eq $true)
		{
			$scriptsMakeArguments = "$scriptsMakeArguments -debug"
		}
		Invoke-Make "$($this.sdkPath)/binaries/Win64/XComGame.com" $scriptsMakeArguments $this.sdkPath $this.modSrcRoot
		if ($LASTEXITCODE -ne 0)
		{
			ThrowFailure "Failed to compile mod scripts!"
		}
		Write-Host "Compiled mod scripts."
	}

	[bool]_HasNativePackages() {
		# Check if this is a Highlander and we need to cook things
		$anynative = $false
		foreach ($name in $this.thismodpackages) 
		{
			if ($global:nativescriptpackages.Contains($name)) {
				$anynative = $true
				break
			}
		}
		return $anynative
	}

	[void]_CopyScriptPackages() {
		# copy packages to staging
		Write-Host "Copying the compiled or cooked packages to staging..."
		foreach ($name in $this.thismodpackages) {
			if ($this.cook -and $global:nativescriptpackages.Contains($name))
			{
				# This is a native (cooked) script package -- copy important upks
				Copy-Item "$($this.modcookdir)\$name.upk" "$($this.stagingPath)\CookedPCConsole" -Force -WarningAction SilentlyContinue
				Copy-Item "$($this.modcookdir)\$name.upk.uncompressed_size" "$($this.stagingPath)\CookedPCConsole" -Force -WarningAction SilentlyContinue
				Write-Host "$($this.modcookdir)\$name.upk"
			}
			else
			{
				# Or this is a non-native package
				Copy-Item "$($this.sdkPath)\XComGame\Script\$name.u" "$($this.stagingPath)\Script" -Force -WarningAction SilentlyContinue
				Write-Host "$($this.sdkPath)\XComGame\Script\$name.u"        
			}
		}
		Write-Host "Copied compiled and cooked script packages."
	}

	[void]_PrecompileShaders() {
		if(Test-Path "$($this.modSrcRoot)/Content") {
			$contentfiles = Get-ChildItem "$($this.modSrcRoot)/Content\*"  -Include *.upk, *.umap -Recurse -File

			if ($contentfiles.length -eq 0) {
				Write-Host "No content files, skipping PrecompileShaders."
			}

			$shader_cache_path = "$($this.gamePath)/XComGame/Mods/$($this.modNameCanonical)/Content/$($this.modNameCanonical)_ModShaderCache.upk"
			$need_shader_precompile = $false
			
			# Try to find a reason to precompile the shaders
			if (!(Test-Path -Path $shader_cache_path))
			{
				$need_shader_precompile = $true
			} 
			elseif ($contentfiles.length -gt 0)
			{
				$shader_cache = Get-Item $shader_cache_path
				
				foreach ($file in $contentfiles)
				{
					if ($file.LastWriteTime -gt $shader_cache.LastWriteTime -Or $file.CreationTime -gt $shader_cache.LastWriteTime)
					{
						$need_shader_precompile = $true
						break
					}
				}
			}
			
			if ($need_shader_precompile)
			{
				# build the mod's shader cache
				Write-Host "Precompiling Shaders..."
				&"$($this.sdkPath)/binaries/Win64/XComGame.com" precompileshaders -nopause platform=pc_sm4 DLC=$($this.modNameCanonical)
				if ($LASTEXITCODE -ne 0)
				{
					ThrowFailure "Failed to compile mod shader cache!"
				}
				Write-Host "Generated Shader Cache."
			}
			else
			{
				Write-Host "Copying existing shader cache..."
				Copy-Item "$shader_cache_path" "$($this.stagingPath)\Content" -Force -WarningAction SilentlyContinue
				Write-Host "Copied existing shader cache."
			}
		}
	}

	[void]_RunCook() {
		Invoke-Cook $this.sdkPath $this.gamePath $this.modcookdir $this.final_release
	}

	[void]_FinalCopy() {
		# copy all staged files to the actual game's mods folder
		Write-Host "Copying all staging files to production..."
		Robocopy.exe "$($this.stagingPath)" "$($this.gamePath)\XComGame\Mods\$($this.modNameCanonical)" *.* $global:def_robocopy_args
		Write-Host "Copied mod to game directory."
	}
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


function FailureMessage($message)
{
	[System.Media.SystemSounds]::Hand.Play()
	Write-Host $message -ForegroundColor "Red"
}

function ThrowFailure($message)
{
	throw $message
}

function SuccessMessage($message, $modNameCanonical)
{
    [System.Media.SystemSounds]::Asterisk.Play()
    Write-Host $message -ForegroundColor "Green"
    Write-Host "$modNameCanonical ready to run." -ForegroundColor "Green"
}

function Invoke-Cook([string] $sdkPath, [string] $gamePath, [string] $modcookdir, [bool] $final_release) {
    # Cook it
    # Normally, the mod tools create a symlink in the SDK directory to the game CookedPCConsole directory,
    # but we'll just be using the game one to make it more robust
    $cookedpcconsoledir = [io.path]::combine($gamePath, 'XComGame', 'CookedPCConsole')
    if(-not(Test-Path $modcookdir))
    {
        Write-Host "Creating Published/CookedPCConsole directory..."
        New-Item $modcookdir -ItemType Directory
    }

    [System.String[]]$files = "GuidCache.upk", "GlobalPersistentCookerData.upk", "PersistentCookerShaderData.bin"
    foreach ($name in $files) {
        if(-not(Test-Path ([io.path]::combine($modcookdir, $name))))
        {
            Write-Host "Copying $name..."
            Copy-Item ([io.path]::combine($cookedpcconsoledir, $name)) $modcookdir
        }
    }

    # Ideally, the cooking process wouldn't modify the big *.tfc files, but it does, so we don't overwrite existing ones (/XC /XN /XO)
    # In order to "reset" the cooking direcory, just delete it and let the script recreate them
    Write-Host "Copying Texture File Caches..."
	Robocopy.exe "$cookedpcconsoledir" "$modcookdir" *.tfc /NJH /XC /XN /XO
	Write-Host "Copied Texture File Caches."

    # Cook it!
    # The CookPackages commandlet generally is super unhelpful. The output is basically always the same and errors
    # don't occur -- it rather just crashes the game. Hence, we just pipe the output to $null
	Write-Host "Invoking CookPackages (this may take a while)"
	$cook_args = @("-platform=pcconsole", "-quickanddirty", "-modcook", "-sha", "-multilanguagecook=INT+FRA+ITA+DEU+RUS+POL+KOR+ESN", "-singlethread", "-nopause")
    if ($final_release -eq $true)
    {
		$cook_args += "-final_release"
	}
	
	& "$sdkPath/binaries/Win64/XComGame.com" CookPackages @cook_args >$null 2>&1

    if ($LASTEXITCODE -ne 0)
    {
        ThrowFailure "Failed to cook packages!"
    }

    Write-Host "Cooked packages."
}