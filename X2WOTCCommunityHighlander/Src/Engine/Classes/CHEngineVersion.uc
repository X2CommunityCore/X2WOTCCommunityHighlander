// CHL: We can't create templates in Engine, so we use this to create the template in XComGame
class CHEngineVersion extends Object;

var int MajorVersion;
var int MinorVersion;
var int PatchVersion;
var string Commit;

// AUTO-CODEGEN: Version-Info
defaultproperties
{
    MajorVersion = 1;
    MinorVersion = 18;
    PatchVersion = 0;
    Commit = "RC1";
}
