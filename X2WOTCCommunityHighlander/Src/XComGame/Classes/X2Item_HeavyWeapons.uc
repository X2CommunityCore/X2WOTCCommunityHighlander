class X2Item_HeavyWeapons extends X2Item config(GameData_WeaponData);

// Variables from config - GameData_WeaponData.ini
var config WeaponDamageValue ROCKETLAUNCHER_BASEDAMAGE;
var config WeaponDamageValue SHREDDERGUN_BASEDAMAGE;
var config WeaponDamageValue FLAMETHROWER_BASEDAMAGE;
var config WeaponDamageValue FLAMETHROWERMK2_BASEDAMAGE;
var config WeaponDamageValue BLASTERLAUNCHER_BASEDAMAGE;
var config WeaponDamageValue PLASMABLASTER_BASEDAMAGE;
var config WeaponDamageValue SHREDSTORMCANNON_BASEDAMAGE;

var config int ROCKETLAUNCHER_ISOUNDRANGE;
var config int ROCKETLAUNCHER_IENVIRONMENTDAMAGE;
var config int ROCKETLAUNCHER_ISUPPLIES;
var config int ROCKETLAUNCHER_TRADINGPOSTVALUE;
var config int ROCKETLAUNCHER_IPOINTS;
var config int ROCKETLAUNCHER_ICLIPSIZE;
var config int ROCKETLAUNCHER_RANGE;
var config int ROCKETLAUNCHER_RADIUS;

var config int SHREDDERGUN_ISOUNDRANGE;
var config int SHREDDERGUN_IENVIRONMENTDAMAGE;
var config int SHREDDERGUN_ISUPPLIES;
var config int SHREDDERGUN_TRADINGPOSTVALUE;
var config int SHREDDERGUN_IPOINTS;
var config int SHREDDERGUN_ICLIPSIZE;
var config int SHREDDERGUN_RANGE;
var config int SHREDDERGUN_RADIUS;

var config int FLAMETHROWER_ISOUNDRANGE;
var config int FLAMETHROWER_IENVIRONMENTDAMAGE;
var config int FLAMETHROWER_ISUPPLIES;
var config int FLAMETHROWER_TRADINGPOSTVALUE;
var config int FLAMETHROWER_IPOINTS;
var config int FLAMETHROWER_ICLIPSIZE;
var config int FLAMETHROWER_RANGE;
var config int FLAMETHROWER_RADIUS;

var config int FLAMETHROWERMK2_ISOUNDRANGE;
var config int FLAMETHROWERMK2_IENVIRONMENTDAMAGE;
var config int FLAMETHROWERMK2_ISUPPLIES;
var config int FLAMETHROWERMK2_TRADINGPOSTVALUE;
var config int FLAMETHROWERMK2_IPOINTS;
var config int FLAMETHROWERMK2_ICLIPSIZE;
var config int FLAMETHROWERMK2_RANGE;
var config int FLAMETHROWERMK2_RADIUS;

var config int BLASTERLAUNCHER_ISOUNDRANGE;
var config int BLASTERLAUNCHER_IENVIRONMENTDAMAGE;
var config int BLASTERLAUNCHER_ISUPPLIES;
var config int BLASTERLAUNCHER_TRADINGPOSTVALUE;
var config int BLASTERLAUNCHER_IPOINTS;
var config int BLASTERLAUNCHER_ICLIPSIZE;
var config int BLASTERLAUNCHER_RANGE;
var config int BLASTERLAUNCHER_RADIUS;

var config int PLASMABLASTER_ISOUNDRANGE;
var config int PLASMABLASTER_IENVIRONMENTDAMAGE;
var config int PLASMABLASTER_ISUPPLIES;
var config int PLASMABLASTER_TRADINGPOSTVALUE;
var config int PLASMABLASTER_IPOINTS;
var config int PLASMABLASTER_ICLIPSIZE;
var config int PLASMABLASTER_RANGE;
var config int PLASMABLASTER_RADIUS;

var config int SHREDSTORMCANNON_ISOUNDRANGE;
var config int SHREDSTORMCANNON_IENVIRONMENTDAMAGE;
var config int SHREDSTORMCANNON_ISUPPLIES;
var config int SHREDSTORMCANNON_TRADINGPOSTVALUE;
var config int SHREDSTORMCANNON_IPOINTS;
var config int SHREDSTORMCANNON_ICLIPSIZE;
var config int SHREDSTORMCANNON_RANGE;
var config int SHREDSTORMCANNON_RADIUS;

var config name FreeHeavyWeaponToEquip;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Weapons;

	Weapons.AddItem(RocketLauncher());
	Weapons.AddItem(ShredderGun());
	Weapons.AddItem(Flamethrower());
	Weapons.AddItem(FlamethrowerMk2());
	Weapons.AddItem(BlasterLauncher());
	Weapons.AddItem(PlasmaBlaster());
	Weapons.AddItem(ShredstormCannon());

	return Weapons;
}

static function X2WeaponTemplate RocketLauncher()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'RocketLauncher');
	Template.WeaponCat = 'heavy';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Rocket_Launcher";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";

	Template.BaseDamage = default.ROCKETLAUNCHER_BASEDAMAGE;
	Template.iSoundRange = default.ROCKETLAUNCHER_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ROCKETLAUNCHER_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.ROCKETLAUNCHER_ICLIPSIZE;
	Template.iRange = default.ROCKETLAUNCHER_RANGE;
	Template.iRadius = default.ROCKETLAUNCHER_RADIUS;
	
	Template.PointsToComplete = default.ROCKETLAUNCHER_IPOINTS;
	Template.TradingPostValue = default.ROCKETLAUNCHER_TRADINGPOSTVALUE;
	
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.GameArchetype = "WP_Heavy_RocketLauncher.WP_Heavy_RocketLauncher";
	Template.AltGameArchetype = "WP_Heavy_RocketLauncher.WP_Heavy_RocketLauncher_Powered";
	Template.ArmorTechCatForAltArchetype = 'powered';
	Template.bMergeAmmo = true;
	Template.DamageTypeTemplateName = 'Explosion';

	Template.Abilities.AddItem('RocketLauncher');
	Template.Abilities.AddItem('RocketFuse');

	Template.CanBeBuilt = false;
	Template.StartingItem = true;
	Template.bInfiniteItem = true;
		
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.ROCKETLAUNCHER_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.ROCKETLAUNCHER_RADIUS);
	
	return Template;
}

static function X2WeaponTemplate ShredderGun()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'ShredderGun');
	Template.WeaponCat = 'heavy';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Shredder_Gun";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";

	Template.BaseDamage = default.SHREDDERGUN_BASEDAMAGE;
	Template.iSoundRange = default.SHREDDERGUN_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SHREDDERGUN_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.SHREDDERGUN_ICLIPSIZE;
	Template.iRange = default.SHREDDERGUN_RANGE;
	Template.iRadius = default.SHREDDERGUN_RADIUS;
	Template.PointsToComplete = 0;
	
	Template.PointsToComplete = default.SHREDDERGUN_IPOINTS;
	Template.TradingPostValue = default.SHREDDERGUN_TRADINGPOSTVALUE;
	
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.GameArchetype = "WP_Heavy_ShredderGun.WP_Heavy_ShredderGun";
	Template.AltGameArchetype = "WP_Heavy_ShredderGun.WP_Heavy_ShredderGun_Powered";
	Template.ArmorTechCatForAltArchetype = 'powered';
	Template.bMergeAmmo = true;

	Template.Abilities.AddItem('ShredderGun');

	Template.CanBeBuilt = false;

	Template.RewardDecks.AddItem('ExperimentalHeavyWeaponRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.SHREDDERGUN_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.SHREDDERGUN_RADIUS);

	return Template;
}

static function X2WeaponTemplate Flamethrower()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'Flamethrower');
	Template.WeaponCat = 'heavy';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_FlameThrower";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";

	Template.BaseDamage = default.FLAMETHROWER_BASEDAMAGE;
	Template.iSoundRange = default.FLAMETHROWER_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.FLAMETHROWER_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.FLAMETHROWER_ICLIPSIZE;
	Template.iRange = default.FLAMETHROWER_RANGE;
	Template.iRadius = default.FLAMETHROWER_RADIUS;
	Template.PointsToComplete = 0;
	Template.DamageTypeTemplateName = 'Fire';
	Template.fCoverage = 33.0f;

	Template.PointsToComplete = default.FLAMETHROWER_IPOINTS;
	Template.TradingPostValue = default.FLAMETHROWER_TRADINGPOSTVALUE;
	
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.GameArchetype = "WP_HeavyFlamethrower.WP_Heavy_Flamethrower";
	Template.AltGameArchetype = "WP_HeavyFlamethrower.WP_Heavy_Flamethrower_Powered";
	Template.ArmorTechCatForAltArchetype = 'powered';
	Template.bMergeAmmo = true;

	Template.Abilities.AddItem('Flamethrower');

	Template.CanBeBuilt = false;

	Template.RewardDecks.AddItem('ExperimentalHeavyWeaponRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.FLAMETHROWER_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.FLAMETHROWER_RADIUS);

	return Template;
}

static function X2WeaponTemplate FlamethrowerMk2()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'FlamethrowerMk2');
	Template.WeaponCat = 'heavy';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_FlameThrowerMK2";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";

	Template.BaseDamage = default.FLAMETHROWERMK2_BASEDAMAGE;
	Template.iSoundRange = default.FLAMETHROWERMK2_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.FLAMETHROWERMK2_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.FLAMETHROWERMK2_ICLIPSIZE;
	Template.iRange = default.FLAMETHROWERMK2_RANGE;
	Template.iRadius = default.FLAMETHROWERMK2_RADIUS;
	Template.PointsToComplete = 0;
	Template.DamageTypeTemplateName = 'Fire';
	Template.fCoverage = 50.0f;

	Template.PointsToComplete = default.FLAMETHROWERMK2_IPOINTS;
	Template.TradingPostValue = default.FLAMETHROWERMK2_TRADINGPOSTVALUE;
	
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.GameArchetype = "WP_HeavyFlamethrower.WP_Heavy_Flamethrower_Lv2";
	Template.AltGameArchetype = "WP_HeavyFlamethrower.WP_Heavy_Flamethrower_Powered_Lv2";
	Template.ArmorTechCatForAltArchetype = 'powered';
	Template.bMergeAmmo = true;

	Template.Abilities.AddItem('FlamethrowerMk2');

	Template.CanBeBuilt = false;

	Template.RewardDecks.AddItem('ExperimentalPoweredWeaponRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.FLAMETHROWERMK2_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.FLAMETHROWERMK2_RADIUS);

	return Template;
}

static function X2WeaponTemplate BlasterLauncher()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'BlasterLauncher');
	Template.WeaponCat = 'heavy';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Blaster_Launcher";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";

	Template.BaseDamage = default.BLASTERLAUNCHER_BASEDAMAGE;
	Template.iSoundRange = default.BLASTERLAUNCHER_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.BLASTERLAUNCHER_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.BLASTERLAUNCHER_ICLIPSIZE;
	Template.iRange = default.BLASTERLAUNCHER_RANGE;
	Template.iRadius = default.BLASTERLAUNCHER_RADIUS;
	Template.PointsToComplete = 0;

	Template.PointsToComplete = default.BLASTERLAUNCHER_IPOINTS;
	Template.TradingPostValue = default.BLASTERLAUNCHER_TRADINGPOSTVALUE;
	
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.GameArchetype = "WP_Heavy_BlasterLauncher.WP_Heavy_BlasterLauncher";
	Template.AltGameArchetype = "WP_Heavy_BlasterLauncher.WP_Heavy_BlasterLauncher_Powered";
	Template.ArmorTechCatForAltArchetype = 'powered';
	Template.bMergeAmmo = true;
	Template.DamageTypeTemplateName = 'Explosion';

	Template.Abilities.AddItem('BlasterLauncher');
	Template.Abilities.AddItem('RocketFuse');

	Template.CanBeBuilt = false;

	Template.WeaponPrecomputedPathData.InitialPathTime = 0.5;
	Template.WeaponPrecomputedPathData.MaxPathTime = 1.0;
	Template.WeaponPrecomputedPathData.MaxNumberOfBounces = 0;

	Template.RewardDecks.AddItem('ExperimentalPoweredWeaponRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.BLASTERLAUNCHER_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.BLASTERLAUNCHER_RADIUS);

	return Template;
}

static function X2WeaponTemplate PlasmaBlaster()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PlasmaBlaster');
	Template.WeaponCat = 'heavy';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Plasma_Blaster";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";

	Template.BaseDamage = default.PLASMABLASTER_BASEDAMAGE;
	Template.iSoundRange = default.PLASMABLASTER_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.PLASMABLASTER_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.PLASMABLASTER_ICLIPSIZE;
	Template.iRange = default.PLASMABLASTER_RANGE;
	Template.iRadius = default.PLASMABLASTER_RADIUS;
	Template.PointsToComplete = 0;

	Template.PointsToComplete = default.PLASMABLASTER_IPOINTS;
	Template.TradingPostValue = default.PLASMABLASTER_TRADINGPOSTVALUE;
	
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.GameArchetype = "WP_Heavy_PlasmaBlaster.WP_Heavy_PlasmaBlaster";
	Template.AltGameArchetype = "WP_Heavy_PlasmaBlaster.WP_Heavy_PlasmaBlaster_Powered";
	Template.ArmorTechCatForAltArchetype = 'powered';
	Template.bMergeAmmo = true;

	Template.Abilities.AddItem('PlasmaBlaster');

	Template.CanBeBuilt = false;

	Template.RewardDecks.AddItem('ExperimentalPoweredWeaponRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.PLASMABLASTER_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.PLASMABLASTER_RADIUS);

	return Template;
}

static function X2WeaponTemplate ShredstormCannon()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'ShredstormCannon');
	Template.WeaponCat = 'heavy';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Shredstorm_Cannon";
	Template.EquipSound = "StrategyUI_Heavy_Weapon_Equip";

	Template.BaseDamage = default.SHREDSTORMCANNON_BASEDAMAGE;
	Template.iSoundRange = default.SHREDSTORMCANNON_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SHREDSTORMCANNON_IENVIRONMENTDAMAGE;
	Template.iClipSize = default.SHREDSTORMCANNON_ICLIPSIZE;
	Template.iRange = default.SHREDSTORMCANNON_RANGE;
	Template.iRadius = default.SHREDSTORMCANNON_RADIUS;
	Template.PointsToComplete = 0;

	Template.PointsToComplete = default.SHREDSTORMCANNON_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.SHREDSTORMCANNON_TRADINGPOSTVALUE;
	
	Template.InventorySlot = eInvSlot_HeavyWeapon;
	Template.StowedLocation = eSlot_HeavyWeapon;
	Template.GameArchetype = "WP_Heavy_ShredstormCannon.WP_Heavy_ShredstormCannon";
	Template.AltGameArchetype = "WP_Heavy_ShredstormCannon.WP_Heavy_ShredstormCannon_Powered";
	Template.ArmorTechCatForAltArchetype = 'powered';
	Template.bMergeAmmo = true;

	Template.Abilities.AddItem('ShredstormCannon');

	Template.CanBeBuilt = false;

	Template.RewardDecks.AddItem('ExperimentalPoweredWeaponRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.SHREDSTORMCANNON_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.SHREDSTORMCANNON_RADIUS);

	return Template;
}


defaultproperties
{
	bShouldCreateDifficultyVariants=true
}
