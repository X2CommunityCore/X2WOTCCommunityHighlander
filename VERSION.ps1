# Used by updateVersion.ps1

$version_block = @'
// AUTO-CODEGEN: Version-Info
defaultproperties
{
	MajorVersion = 1;
	MinorVersion = 30;
	PatchVersion = 1;
	Commit = "%COMMIT%";
}
'@
