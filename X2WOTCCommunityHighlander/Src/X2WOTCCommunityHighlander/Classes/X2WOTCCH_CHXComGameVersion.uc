class X2WOTCCH_CHXComGameVersion extends X2StrategyElement;

var int MajorVersion;
var int MinorVersion;
var int PatchVersion;
var string Commit;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2StrategyElementTemplate XComGameVersion;

	// Created for legacy reasons
	if (class'CHXComGameVersionTemplate' != none)
	{
		`CREATE_X2TEMPLATE(class'CHXComGameVersionTemplate', XComGameVersion, 'CHWOTCVersion');
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
	MinorVersion = 22;
	PatchVersion = 3;
	Commit = "";
}
