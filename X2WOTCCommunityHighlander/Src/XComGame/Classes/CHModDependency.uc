class CHModDependency extends Object perobjectconfig Config(Game);

var config array<string> IncompatibleMods;
var config array<string> IgnoreIncompatibleMods;
var config array<string> RequiredMods;
var config array<string> IgnoreRequiredMods;
var string DisplayName;

// Start Issue #909
struct CHLVersionStruct
{
    var int MajorVersion;
    var int MinorVersion;
    var int PatchVersion;

    structdefaultproperties
    {
        MajorVersion = -1
        MinorVersion = -1
        PatchVersion = -1
    }
};
var config CHLVersionStruct RequiredHighlanderVersion;
var name DLCIdentifier;
// End Issue #909