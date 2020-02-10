class X2DLC2CH_CHXComGameVersion extends X2StrategyElement;

var int MajorVersion;
var int MinorVersion;
var int PatchVersion;
var string Commit;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2StrategyElementTemplate XComGameVersion;

	`log("CreateTemplates",, 'DLC2CommunityHighlander');

	if (class'CHXComGameVersionTemplate' != none)
	{
		`log("Creating CHDLC2Version with version" @ default.MajorVersion $ "." $ default.MinorVersion $ "." $ default.PatchVersion,, 'DLC2CommunityHighlander');

		`CREATE_X2TEMPLATE(class'CHXComGameVersionTemplate', XComGameVersion, 'CHDLC2Version');
		CHXComGameVersionTemplate(XComGameVersion).MajorVersion = default.MajorVersion;
		CHXComGameVersionTemplate(XComGameVersion).MinorVersion = default.MinorVersion;
		CHXComGameVersionTemplate(XComGameVersion).PatchVersion = default.PatchVersion;
		CHXComGameVersionTemplate(XComGameVersion).Commit = default.Commit;

		Templates.AddItem(XComGameVersion);
	}

	return Templates;
}

// AUTO-CODEGEN: Version-Info
defaultproperties
{
    MajorVersion = 1;
    MinorVersion = 20;
    PatchVersion = 0;
    Commit = "RC1";
}
