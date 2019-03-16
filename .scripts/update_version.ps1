Param(
	[string]$ps, # path to the script containing the relevant definition
	[string]$srcDirectory, # the directory containing relevant .uc files
	[switch]$use_commit
)

. ($ps)

$version_commit = ""

if ($use_commit) {
	$version_commit = (git rev-parse HEAD).Substring(0,6)
}

# Optimization: Only consider .uc files with `Version` in their name
$fileNames = Get-ChildItem -Path $srcDirectory -Recurse -Include "*Version*.uc"

for ($i = 0; $i -lt $fileNames.Length; $i++) {
	$target_file = $fileNames[$i]
	$content = Get-Content $target_file | Out-String
	if ($content -match '// AUTO-CODEGEN: Version-Info\s*defaultproperties\s*{[^}]*}') {
		Write-Host $target_file
		((($content) -replace '// AUTO-CODEGEN: Version-Info\s*defaultproperties\s*{[^}]*}', $version_block) -replace "%COMMIT%", $version_commit) | Set-Content $target_file -NoNewline
	}
}
