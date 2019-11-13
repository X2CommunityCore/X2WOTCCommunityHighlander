Param(
	[string]$ps, # path to the script containing the relevant definition
	[string]$srcDirectory, # the directory containing relevant .uc files
	[switch]$use_commit
)

. ($ps)

$version_commit = ""

if ($use_commit) {
	# Force git to run inside the current directory.
	# This is needed when CHL is used as git submodule
	# otherwise the commit hash of outer git repo is used

	# https://stackoverflow.com/a/5466355/2588539
	$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
	
	# https://stackoverflow.com/a/8762068/2588539
	$pinfo = New-Object System.Diagnostics.ProcessStartInfo
	$pinfo.FileName = "git"
	$pinfo.RedirectStandardOutput = $true
	$pinfo.UseShellExecute = $false
	$pinfo.Arguments = "rev-parse HEAD"
	$pinfo.WorkingDirectory = $scriptPath
	$p = New-Object System.Diagnostics.Process
	$p.StartInfo = $pinfo
	$p.Start() | Out-Null
	
	$version_commit = ($p.StandardOutput.ReadToEnd()).Substring(0,6)
	Write-Host "Using commit $version_commit"
}

# Optimization: Only consider .uc files with `Version` in their name
$fileNames = Get-ChildItem -Path $srcDirectory -Recurse -Include "*Version*.uc"

for ($i = 0; $i -lt $fileNames.Length; $i++) {
	$target_file = $fileNames[$i]
	$content = Get-Content $target_file | Out-String
	
	if ($content -match '// AUTO-CODEGEN: Version-Info\s*defaultproperties\s*{[^}]*}') {
		$new_content = (($content) -replace '// AUTO-CODEGEN: Version-Info\s*defaultproperties\s*{[^}]*}', $version_block) -replace "%COMMIT%", $version_commit;
		$cached_file_path = "$($target_file).cached";
		$found_cached = $false;

		if (Test-Path -Path $cached_file_path) {
			$cached_content = Get-Content $cached_file_path | Out-String;

			if ($cached_content -eq $new_content) {
				Write-Host "$target_file replacing with cached version"
				
				Remove-Item $target_file
				Copy-Item $cached_file_path -Destination $target_file
				$found_cached = $true;
			}
		}

		if (!$found_cached) {
			Write-Host "$target_file no cached version, or it is not up-to-date - replacing (will trigger package recompile)"

			$new_content | Set-Content $target_file -NoNewline;
			$new_content | Set-Content $cached_file_path -NoNewline;
		}
	}
}
