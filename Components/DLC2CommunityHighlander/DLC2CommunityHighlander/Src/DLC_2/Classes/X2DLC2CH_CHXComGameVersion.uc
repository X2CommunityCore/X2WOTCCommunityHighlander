class X2DLC2CH_CHXComGameVersion extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2StrategyElementTemplate XComGameVersion;

	if (class'CHXComGameVersionTemplate' != none)
	{
		`CREATE_X2TEMPLATE(class'CHXComGameVersionTemplate', XComGameVersion, 'CHDLC2Version');
		CHXComGameVersionTemplate(XComGameVersion).MajorVersion = 1;
		CHXComGameVersionTemplate(XComGameVersion).MinorVersion = 16;
		CHXComGameVersionTemplate(XComGameVersion).PatchVersion = 0;

		Templates.AddItem(XComGameVersion);
	}

	return Templates;
}
