// CHL: We can't create templates in Core, so we use this to create the template in XComGame
class CHCoreVersion extends Object;

var int MajorVersion;
var int MinorVersion;
var int PatchVersion;
var string Commit;

// AUTO-CODEGEN: Version-Info
defaultproperties
{
    MajorVersion = 1;
    MinorVersion = 20;
    PatchVersion = 0;
    Commit = "RC1";
}
