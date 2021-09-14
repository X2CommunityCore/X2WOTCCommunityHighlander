# Used by updateVersion.ps1

$version_block = @'
// AUTO-CODEGEN: Version-Info
defaultproperties
{
	MajorVersion = 1;
	MinorVersion = 22;
	PatchVersion = 5;
	Commit = "%COMMIT%";
}
'@
