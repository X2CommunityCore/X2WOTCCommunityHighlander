# Run ./.scripts/update_version.ps1 . VERSION.ps1 to update all .uc files with "Version" in their name with the new version

$version_block = @'
// AUTO-CODEGEN: Version-Info
defaultproperties
{
    MajorVersion = 1;
    MinorVersion = 17;
    PatchVersion = 0;
    Commit = "%COMMIT%";
}
'@
