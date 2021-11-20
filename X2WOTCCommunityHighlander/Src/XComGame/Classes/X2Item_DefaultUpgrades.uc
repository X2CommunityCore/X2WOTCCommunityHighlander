class X2Item_DefaultUpgrades extends X2Item config(GameCore);

var config int CRIT_UPGRADE_BSC;
var config int CRIT_UPGRADE_ADV;
var config int CRIT_UPGRADE_SUP;
var config int CRIT_UPGRADE_EMPOWER_BONUS;

var config int AIM_UPGRADE_BSC;
var config int AIM_UPGRADE_ADV;
var config int AIM_UPGRADE_SUP;
var config int AIM_UPGRADE_NOCOVER_BONUS;
var config int AIM_UPGRADE_EMPOWER_BONUS;

var config int CLIP_SIZE_BSC;
var config int CLIP_SIZE_ADV;
var config int CLIP_SIZE_SUP;
var config int CLIP_SIZE_EMPOWER_BONUS;

var config int FREE_FIRE_BSC;
var config int FREE_FIRE_ADV;
var config int FREE_FIRE_SUP;
var config int FREE_FIRE_EMPOWER_BONUS;

var config int FREE_RELOADS_BSC;
var config int FREE_RELOADS_ADV;
var config int FREE_RELOADS_SUP;
var config int FREE_RELOADS_EMPOWER_BONUS;

var config WeaponDamageValue MISS_DAMAGE_BSC;
var config WeaponDamageValue MISS_DAMAGE_ADV;
var config WeaponDamageValue MISS_DAMAGE_SUP;
var config int MISS_DAMAGE_EMPOWER_BONUS;

var config int FREE_KILL_BSC;
var config int FREE_KILL_ADV;
var config int FREE_KILL_SUP;
var config int FREE_KILL_EMPOWER_BONUS;

var localized string FreeReloadAbilityName;
var localized array<string> UpgradeBlackMarketTexts;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;

	Items.AddItem(CreateBasicCritUpgrade());
	Items.AddItem(CreateAdvancedCritUpgrade());
	Items.AddItem(CreateSuperiorCritUpgrade());
	
	Items.AddItem(CreateBasicAimUpgrade());
	Items.AddItem(CreateAdvancedAimUpgrade());
	Items.AddItem(CreateSuperiorAimUpgrade());
	
	Items.AddItem(CreateBasicClipSizeUpgrade());
	Items.AddItem(CreateAdvancedClipSizeUpgrade());
	Items.AddItem(CreateSuperiorClipSizeUpgrade());
	
	Items.AddItem(CreateBasicFreeFireUpgrade());
	Items.AddItem(CreateAdvancedFreeFireUpgrade());
	Items.AddItem(CreateSuperiorFreeFireUpgrade());
	
	Items.AddItem(CreateBasicReloadUpgrade());
	Items.AddItem(CreateAdvancedReloadUpgrade());
	Items.AddItem(CreateSuperiorReloadUpgrade());
	
	Items.AddItem(CreateBasicMissDamageUpgrade());
	Items.AddItem(CreateAdvancedMissDamageUpgrade());
	Items.AddItem(CreateSuperiorMissDamageUpgrade());

	Items.AddItem(CreateBasicFreeKillUpgrade());
	Items.AddItem(CreateAdvancedFreeKillUpgrade());
	Items.AddItem(CreateSuperiorFreeKillUpgrade());
	
	return Items;
}

// #######################################################################################
// -------------------- GENERIC SETUP FUNCTIONS ------------------------------------------
// #######################################################################################

static function SetUpWeaponUpgrade(out X2WeaponUpgradeTemplate Template)
{
	Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeapon;
	
	Template.CanBeBuilt = false;
	Template.MaxQuantity = 1;

	Template.BlackMarketTexts = default.UpgradeBlackMarketTexts;
}

static function SetUpTier1Upgrade(out X2WeaponUpgradeTemplate Template)
{
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.TradingPostValue = 10;
	Template.Tier = 0;
}

static function SetUpTier2Upgrade(out X2WeaponUpgradeTemplate Template)
{
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentB';
	Template.TradingPostValue = 20;
	Template.Tier = 1;
}

static function SetUpTier3Upgrade(out X2WeaponUpgradeTemplate Template)
{
	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';
	Template.TradingPostValue = 30;
	Template.Tier = 2;
}

// #######################################################################################
// -------------------- CRIT UPGRADES ----------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateBasicCritUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'CritUpgrade_Bsc');

	SetUpCritUpgrade(Template);
	SetUpTier1Upgrade(Template);

	Template.BonusAbilities.AddItem('LaserSight_Bsc');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_OpticB_inv";
	Template.CritBonus = default.CRIT_UPGRADE_BSC;
	
	return Template;
}

static function X2DataTemplate CreateAdvancedCritUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'CritUpgrade_Adv');

	SetUpCritUpgrade(Template);
	SetUpTier2Upgrade(Template);

	Template.BonusAbilities.AddItem('LaserSight_Adv');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_OpticB_inv";
	Template.CritBonus = default.CRIT_UPGRADE_ADV;

	return Template;
}

static function X2DataTemplate CreateSuperiorCritUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'CritUpgrade_Sup');

	SetUpCritUpgrade(Template);
	SetUpTier3Upgrade(Template);

	Template.BonusAbilities.AddItem('LaserSight_Sup');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_OpticB_inv";
	Template.CritBonus = default.CRIT_UPGRADE_SUP;
	
	return Template;
}

static function SetUpCritUpgrade(out X2WeaponUpgradeTemplate Template)
{
	SetUpWeaponUpgrade(Template);

	Template.AddCritChanceModifierFn = CritUpgradeModifier;
	Template.GetBonusAmountFn = GetCritBonusAmount;

	Template.MutuallyExclusiveUpgrades.AddItem('AimBetterUpgrade');
	Template.MutuallyExclusiveUpgrades.AddItem('CritUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('CritUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('CritUpgrade_Sup');
	Template.MutuallyExclusiveUpgrades.AddItem('AimUpgrade');
	Template.MutuallyExclusiveUpgrades.AddItem('AimUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('AimUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('AimUpgrade_Sup');

	// Assault Rifles
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Optic', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_OpticB", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Optic', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_OpticB", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Optic', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_OpticB", "", 'AssaultRifle_BM', , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_OpticA", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_OpticA_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'AssaultRifle_Central', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	
	// Shotguns
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "ConvShotgun.Meshes.SM_ConvShotgun_OpticB", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvShotgun_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "MagShotgun.Meshes.SM_MagShotgun_OpticB", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagShotgun_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "BeamShotgun.Meshes.SM_BeamShotgun_OpticB", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_OpticA", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_OpticA_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Sniper Rifles
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "ConvSniper.Meshes.SM_ConvSniper_OpticB", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvSniper.ConvSniper_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvSniper_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "MagSniper.Meshes.SM_MagSniper_OpticB", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "BeamSniper.Meshes.SM_BeamSniper_OpticB", "", 'SniperRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Cannons
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Cannon_Optic', "ConvCannon.Meshes.SM_ConvCannon_OpticB", "", 'Cannon_CV', , "img:///UILibrary_Common.ConvCannon.ConvCannon_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvCannon_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Cannon_Optic', "MagCannon.Meshes.SM_MagCannon_OpticB", "", 'Cannon_MG', , "img:///UILibrary_Common.UI_MagCannon.MagCannon_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagCannon_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Cannon_Optic', "BeamCannon.Meshes.SM_BeamCannon_OpticB", "", 'Cannon_BM', , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_OpticA", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamCannon_OpticA_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Bullpups
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_OpticB", "", 'Bullpup_CV', , "img:///UILibrary_XPACK_Common.ConvSMG_OpticB", "img:///UILibrary_XPACK_StrategyImages.ConvSMG_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "MagSMG.Meshes.SM_HOR_Mag_SMG_OpticB", "", 'Bullpup_MG', , "img:///UILibrary_XPACK_Common.MagSMG_OpticB", "img:///UILibrary_XPACK_StrategyImages.MagSMG_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "BemSMG.Meshes.SM_HOR_Bem_SMG_OpticB", "", 'Bullpup_BM', , "img:///UILibrary_XPACK_Common.BeamSMG_OpticB", "img:///UILibrary_XPACK_StrategyImages.BeamSMG_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Vektor Rifles
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_OpticB", "", 'VektorRifle_CV', , "img:///UILibrary_XPACK_Common.ConvVektor_OpticB", "img:///UILibrary_XPACK_StrategyImages.ConvVektor_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "MagReaperRifle.Meshes.SM_HOR_Mag_ReaperRifle_OpticB", "", 'VektorRifle_MG', , "img:///UILibrary_XPACK_Common.MagVektor_OpticB", "img:///UILibrary_XPACK_StrategyImages.MagVektor_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "BemReaperRifle.Meshes.SM_HOR_Bem_ReaperRifle_OpticB", "", 'VektorRifle_BM', , "img:///UILibrary_XPACK_Common.BeamVektor_OpticB", "img:///UILibrary_XPACK_StrategyImages.BeamVektor_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Chosen Weapons
	Template.AddUpgradeAttachment('Optic', '', "", "", 'ChosenRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'ChosenSniperRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'ChosenShotgun_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	//TLP Weapons
	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_Shotgun_BM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_Shotgun_MG', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_Shotgun_CV', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	
}

static function int GetCritBonusAmount(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	return UpgradeTemplate.CritBonus + (AreUpgradesEmpowered() ? default.CRIT_UPGRADE_EMPOWER_BONUS : 0);
}

// #######################################################################################
// --------------------- AIM UPGRADES ----------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateBasicAimUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'AimUpgrade_Bsc');

	SetUpAimBonusUpgrade(Template);
	SetUpTier1Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_OpticC_inv";
	Template.AimBonus = default.AIM_UPGRADE_BSC;
	
	return Template;
}

static function X2DataTemplate CreateAdvancedAimUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'AimUpgrade_Adv');

	SetUpAimBonusUpgrade(Template);
	SetUpTier2Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_OpticC_inv";
	Template.AimBonus = default.AIM_UPGRADE_ADV;
	
	return Template;
}

static function X2DataTemplate CreateSuperiorAimUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'AimUpgrade_Sup');

	SetUpAimBonusUpgrade(Template);
	SetUpTier3Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_OpticC_inv";
	Template.AimBonus = default.AIM_UPGRADE_SUP;
	
	return Template;
}

static function SetUpAimBonusUpgrade(out X2WeaponUpgradeTemplate Template)
{
	SetUpWeaponUpgrade(Template);

	Template.AddHitChanceModifierFn = AimUpgradeHitModifier;
	Template.GetBonusAmountFn = GetAimBonusAmount;

	Template.MutuallyExclusiveUpgrades.AddItem('AimUpgrade');
	Template.MutuallyExclusiveUpgrades.AddItem('AimUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('AimUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('AimUpgrade_Sup');
	Template.MutuallyExclusiveUpgrades.AddItem('AimBetterUpgrade');
	Template.MutuallyExclusiveUpgrades.AddItem('CritUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('CritUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('CritUpgrade_Sup');
	
	// Assault Rifles
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Optic', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_OpticC", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_OpticC", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Optic', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_OpticC", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_OpticC", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Optic', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_OpticC", "", 'AssaultRifle_BM', , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'AssaultRifle_Central', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Shotguns
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "ConvShotgun.Meshes.SM_ConvShotgun_OpticC", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_OpticC", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvShotgun_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "MagShotgun.Meshes.SM_MagShotgun_OpticC", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_OpticC", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagShotgun_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "BeamShotgun.Meshes.SM_BeamShotgun_OpticC", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	
	// Sniper Rifles
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "ConvSniper.Meshes.SM_ConvSniper_OpticC", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvSniper.ConvSniper_OpticC", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvSniper_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "MagSniper.Meshes.SM_MagSniper_OpticC", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_OpticC", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "BeamSniper.Meshes.SM_BeamSniper_OpticC", "", 'SniperRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_OpticC", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Cannons
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Cannon_Optic', "ConvCannon.Meshes.SM_ConvCannon_OpticC", "", 'Cannon_CV', , "img:///UILibrary_Common.ConvCannon.ConvCannon_OpticsC", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvCannon_OpticsC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Cannon_Optic', "MagCannon.Meshes.SM_MagCannon_OpticC", "", 'Cannon_MG', , "img:///UILibrary_Common.UI_MagCannon.MagCannon_OpticC", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagCannon_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Cannon_Optic', "BeamCannon.Meshes.SM_BeamCannon_OpticC", "", 'Cannon_BM', , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_OpticB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamCannon_OpticB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Bullpups
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_OpticC", "", 'Bullpup_CV', , "img:///UILibrary_XPACK_Common.ConvSMG_OpticC", "img:///UILibrary_XPACK_StrategyImages.ConvSMG_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "MagSMG.Meshes.SM_HOR_Mag_SMG_OpticC", "", 'Bullpup_MG', , "img:///UILibrary_XPACK_Common.MagSMG_OpticC", "img:///UILibrary_XPACK_StrategyImages.MagSMG_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "BemSMG.Meshes.SM_HOR_Bem_SMG_OpticC", "", 'Bullpup_BM', , "img:///UILibrary_XPACK_Common.BeamSMG_OpticC", "img:///UILibrary_XPACK_StrategyImages.BeamSMG_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Vektor Rifles
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_OpticC", "", 'VektorRifle_CV', , "img:///UILibrary_XPACK_Common.ConvVektor_OpticC", "img:///UILibrary_XPACK_StrategyImages.ConvVektor_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "MagReaperRifle.Meshes.SM_HOR_Mag_ReaperRifle_OpticC", "", 'VektorRifle_MG', , "img:///UILibrary_XPACK_Common.MagVektor_OpticC", "img:///UILibrary_XPACK_StrategyImages.MagVektor_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "BemReaperRifle.Meshes.SM_HOR_Bem_ReaperRifle_OpticC", "", 'VektorRifle_BM', , "img:///UILibrary_XPACK_Common.BeamVektor_OpticC", "img:///UILibrary_XPACK_StrategyImages.BeamVektor_OpticC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	// Chosen Weapons
	Template.AddUpgradeAttachment('Optic', '', "", "", 'ChosenRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'ChosenSniperRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'ChosenShotgun_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	//TLP Weapons
	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_AssaultRifle_BM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_AssaultRifle_MG', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_AssaultRifle_CV', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_SniperRifle_BM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_SniperRifle_MG', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");
	Template.AddUpgradeAttachment('Optic', '', "", "", 'TLE_SniperRifle_CV', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_scope");

}

static function int GetAimBonusAmount(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	return UpgradeTemplate.AimBonus + (AreUpgradesEmpowered() ? default.AIM_UPGRADE_EMPOWER_BONUS : 0);
}

// #######################################################################################
// -------------------- EXPANDED MAG UPGRADES --------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateBasicClipSizeUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'ClipSizeUpgrade_Bsc');

	SetUpClipSizeBonusUpgrade(Template);
	SetUpTier1Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_MagB_inv";
	Template.ClipSizeBonus = default.CLIP_SIZE_BSC;
	
	return Template;
}

static function X2DataTemplate CreateAdvancedClipSizeUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'ClipSizeUpgrade_Adv');
	
	SetUpClipSizeBonusUpgrade(Template);
	SetUpTier2Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_MagB_inv";
	Template.ClipSizeBonus = default.CLIP_SIZE_ADV;
	
	return Template;
}

static function X2DataTemplate CreateSuperiorClipSizeUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'ClipSizeUpgrade_Sup');

	SetUpClipSizeBonusUpgrade(Template);
	SetUpTier3Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_MagB_inv";
	Template.ClipSizeBonus = default.CLIP_SIZE_SUP;
	
	return Template;
}

static function SetUpClipSizeBonusUpgrade(X2WeaponUpgradeTemplate Template)
{
	SetUpWeaponUpgrade(Template);

	Template.AdjustClipSizeFn = AdjustClipSize;
	Template.GetBonusAmountFn = GetClipSizeBonusAmount;

	Template.MutuallyExclusiveUpgrades.AddItem('ClipSizeUpgrade');
	Template.MutuallyExclusiveUpgrades.AddItem('ClipSizeUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('ClipSizeUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('ClipSizeUpgrade_Sup');

	// Assault Rifles
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_MagB", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_MagB", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_MagB", "", 'AssaultRifle_BM', , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	Template.AddUpgradeAttachment('Mag', '', "", "", 'AssaultRifle_Central', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	// Shotguns
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "ConvShotgun.Meshes.SM_ConvShotgun_MagB", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvShotgun_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Foregrip', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "ConvShotgun.Meshes.SM_ConvShotgun_ForegripB", "", 'Shotgun_CV');
	
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "MagShotgun.Meshes.SM_MagShotgun_MagB", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagShotgun_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Foregrip', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "MagShotgun.Meshes.SM_MagShotgun_ForegripB", "", 'Shotgun_MG');
	
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "BeamShotgun.Meshes.SM_BeamShotgun_MagB", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);

	// Sniper Rifles
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "ConvSniper.Meshes.SM_ConvSniper_MagB", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvSniper.ConvSniper_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvSniper_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "MagSniper.Meshes.SM_MagSniper_MagB", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "BeamSniper.Meshes.SM_BeamSniper_MagB", "", 'SniperRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	// Cannons
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Cannon_Mag', "ConvCannon.Meshes.SM_ConvCannon_MagB", "", 'Cannon_CV', , "img:///UILibrary_Common.ConvCannon.ConvCannon_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvCannon_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Cannon_Mag', "MagCannon.Meshes.SM_MagCannon_MagB", "", 'Cannon_MG', , "img:///UILibrary_Common.UI_MagCannon.MagCannon_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagCannon_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Cannon_Mag', "BeamCannon.Meshes.SM_BeamCannon_MagB", "", 'Cannon_BM', , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_MagB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamCannon_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	// Bullpups
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_MagB", "", 'Bullpup_CV', , "img:///UILibrary_XPACK_Common.ConvSMG_MagazineB", "img:///UILibrary_XPACK_StrategyImages.ConvSMG_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "MagSMG.Meshes.SM_HOR_Mag_SMG_MagB", "", 'Bullpup_MG', , "img:///UILibrary_XPACK_Common.MagSMG_MagazineB", "img:///UILibrary_XPACK_StrategyImages.MagSMG_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "BemSMG.Meshes.SM_HOR_Bem_SMG_MagB", "", 'Bullpup_BM', , "img:///UILibrary_XPACK_Common.BeamSMG_MagazineB", "img:///UILibrary_XPACK_StrategyImages.BeamSMG_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	// Vektor Rifles
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_MagB", "", 'VektorRifle_CV', , "img:///UILibrary_XPACK_Common.ConvVektor_MagazineB", "img:///UILibrary_XPACK_StrategyImages.ConvVektor_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "MagReaperRifle.Meshes.SM_HOR_Mag_ReaperRifle_MagB", "", 'VektorRifle_MG', , "img:///UILibrary_XPACK_Common.MagVektor_MagazineB", "img:///UILibrary_XPACK_StrategyImages.MagVektor_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoReloadUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "BemReaperRifle.Meshes.SM_HOR_Bem_ReaperRifle_MagB", "", 'VektorRifle_BM', , "img:///UILibrary_XPACK_Common.BeamVektor_MagazineB", "img:///UILibrary_XPACK_StrategyImages.BeamVektor_MagB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	// Chosen Weapons
	Template.AddUpgradeAttachment('Mag', '', "", "", 'ChosenRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	Template.AddUpgradeAttachment('Mag', '', "", "", 'ChosenSniperRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	Template.AddUpgradeAttachment('Mag', '', "", "", 'ChosenShotgun_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	//TLP Weapons
	Template.AddUpgradeAttachment('Mag', '', "", "", 'TLE_Cannon_BM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	Template.AddUpgradeAttachment('Mag', '', "", "", 'TLE_Cannon_MG', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
}

static function int GetClipSizeBonusAmount(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	return UpgradeTemplate.ClipSizeBonus + (AreUpgradesEmpowered() ? default.CLIP_SIZE_EMPOWER_BONUS : 0);
}

static function bool NoReloadUpgradePresent(array<X2WeaponUpgradeTemplate> AllUpgradeTemplates)
{
	return !ReloadUpgradePresent(AllUpgradeTemplates);
}

static function bool ReloadUpgradePresent(array<X2WeaponUpgradeTemplate> AllUpgradeTemplates)
{
	local X2WeaponUpgradeTemplate TestTemplate;

	foreach AllUpgradeTemplates(TestTemplate)
	{
		if (TestTemplate.DataName == 'ReloadUpgrade' ||
			TestTemplate.DataName == 'ReloadUpgrade_Bsc' ||
			TestTemplate.DataName == 'ReloadUpgrade_Adv' ||
			TestTemplate.DataName == 'ReloadUpgrade_Sup')
		{
			return true;
		}
	}

	return false;
}

// #######################################################################################
// -------------------- FREE FIRE UPGRADES -----------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateBasicFreeFireUpgrade()
{
	local X2WeaponUpgradeTemplate Template;
	
	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'FreeFireUpgrade_Bsc');

	SetUpFreeFireBonusUpgrade(Template);
	SetUpTier1Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_ReargripB_inv";
	Template.FreeFireChance = default.FREE_FIRE_BSC;
	
	return Template;
}

static function X2DataTemplate CreateAdvancedFreeFireUpgrade()
{
	local X2WeaponUpgradeTemplate Template;
	
	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'FreeFireUpgrade_Adv');

	SetUpFreeFireBonusUpgrade(Template);
	SetUpTier2Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_TriggerB_inv";
	Template.FreeFireChance = default.FREE_FIRE_ADV;
	
	return Template;
}

static function X2DataTemplate CreateSuperiorFreeFireUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'FreeFireUpgrade_Sup');

	SetUpFreeFireBonusUpgrade(Template);
	SetUpTier3Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_TriggerB_inv";
	Template.FreeFireChance = default.FREE_FIRE_SUP;
	
	return Template;
}

static function SetUpFreeFireBonusUpgrade(out X2WeaponUpgradeTemplate Template)
{
	SetUpWeaponUpgrade(Template);

	Template.FreeFireCostFn = FreeFireCost;
	Template.GetBonusAmountFn = GetFreeFireBonusAmount;

	Template.MutuallyExclusiveUpgrades.AddItem('FreeFireUpgrade');
	Template.MutuallyExclusiveUpgrades.AddItem('FreeFireUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('FreeFireUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('FreeFireUpgrade_Sup');

	// Assault Rifles
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "ConvAttachments.Meshes.SM_ConvReargripB", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_ReargripB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_ReargripB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "ConvAttachments.Meshes.SM_ConvTriggerB", "", 'AssaultRifle_CV');
	
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "MagAttachments.Meshes.SM_MagReargripB", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_TriggerB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "MagAttachments.Meshes.SM_MagTriggerB", "", 'AssaultRifle_MG');
	
	Template.AddUpgradeAttachment('Core', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Optic', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_CoreB", "", 'AssaultRifle_BM', , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_CoreB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_CoreB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Core_Teeth', '', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_TeethA", "", 'AssaultRifle_BM', , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_Teeth", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_Teeth_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Reargrip', '', "", "", 'AssaultRifle_Central', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
		
	// Shotguns
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "ConvAttachments.Meshes.SM_ConvReargripB", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_TriggerB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvShotgun_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "ConvAttachments.Meshes.SM_ConvTriggerB", "", 'Shotgun_CV');
	
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "MagAttachments.Meshes.SM_MagReargripB", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_TriggerB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagShotgun_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "MagAttachments.Meshes.SM_MagTriggerB", "", 'Shotgun_MG');
	
	Template.AddUpgradeAttachment('Core_Left', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "BeamShotgun.Meshes.SM_BeamShotgun_CoreB", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_CoreB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_CoreB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Core_Right', '', "BeamShotgun.Meshes.SM_BeamShotgun_CoreB", "", 'Shotgun_BM');
	Template.AddUpgradeAttachment('Core_Teeth', '', "BeamShotgun.Meshes.SM_BeamShotgun_TeethA", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_Teeth", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_Teeth_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	
	// Sniper Rifles
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "ConvAttachments.Meshes.SM_ConvReargripB", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvSniper.ConvSniper_TriggerB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvSniper_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "ConvAttachments.Meshes.SM_ConvTriggerB", "", 'SniperRifle_CV');
	
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "MagSniper.Meshes.SM_MagSniper_ReargripB", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_TriggerB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "MagAttachments.Meshes.SM_MagTriggerB", "", 'SniperRifle_MG');
	
	Template.AddUpgradeAttachment('Core', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "BeamSniper.Meshes.SM_BeamSniper_CoreB", "", 'SniperRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_CoreB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_CoreB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Core_Teeth', '', "BeamSniper.Meshes.SM_BeamSniper_TeethA", "", 'SniperRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_Teeth", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_Teeth_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");

	// Cannons
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Cannon_Stock', "ConvCannon.Meshes.SM_ConvCannon_ReargripB", "", 'Cannon_CV', , "img:///UILibrary_Common.ConvCannon.ConvCannon_TriggerB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvCannon_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "ConvCannon.Meshes.SM_ConvCannon_TriggerB", "", 'Cannon_CV');
	
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Cannon_Stock', "MagCannon.Meshes.SM_MagCannon_ReargripB", "", 'Cannon_MG', , "img:///UILibrary_Common.UI_MagCannon.MagCannon_TriggerB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagCannon_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "MagCannon.Meshes.SM_MagCannon_TriggerB", "", 'Cannon_MG');
	
	Template.AddUpgradeAttachment('Core', 'UIPawnLocation_WeaponUpgrade_Cannon_Suppressor', "BeamCannon.Meshes.SM_BeamCannon_CoreB", "", 'Cannon_BM', , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_CoreB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamCannon_CoreB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Core_Center', '', "BeamCannon.Meshes.SM_BeamCannon_CoreB_Center", "", 'Cannon_BM');
	Template.AddUpgradeAttachment('Core_Teeth', '', "BeamCannon.Meshes.SM_BeamCannon_TeethA", "", 'Cannon_BM', , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_Teeth", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamCannon_Teeth_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");

	// Bullpups
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_ReargripB", "", 'Bullpup_CV', , "img:///UILibrary_XPACK_Common.ConvSMG_TriggerB", "img:///UILibrary_XPACK_StrategyImages.ConvSMG_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_TriggerB", "", 'Bullpup_CV');

	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_ReargripB", "", 'Bullpup_MG', , "img:///UILibrary_XPACK_Common.MagSMG_TriggerB", "img:///UILibrary_XPACK_StrategyImages.MagSMG_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_TriggerB", "", 'Bullpup_MG');

	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Shotgun_Optic', "BemSMG.Meshes.SM_HOR_Bem_SMG_ReargripB", "", 'Bullpup_BM', , "img:///UILibrary_XPACK_Common.BeamSMG_TriggerB", "img:///UILibrary_XPACK_StrategyImages.BeamSMG_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_TriggerB", "", 'Bullpup_BM');

	// Vektor Rifles
	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Sniper_Stock', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_ReargripB", "", 'VektorRifle_CV', , "img:///UILibrary_XPACK_Common.ConvVektor_TriggerB", "img:///UILibrary_XPACK_StrategyImages.ConvVektor_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_TriggerB", "", 'VektorRifle_CV');

	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Sniper_Stock', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_ReargripB", "", 'VektorRifle_MG', , "img:///UILibrary_XPACK_Common.MagVektor_TriggerB", "img:///UILibrary_XPACK_StrategyImages.MagVektor_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_TriggerB", "", 'VektorRifle_MG');

	Template.AddUpgradeAttachment('Reargrip', 'UIPawnLocation_WeaponUpgrade_Sniper_Optic', "BemReaperRifle.Meshes.SM_HOR_Bem_ReaperRifle_ReargripB", "", 'VektorRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_CoreB", "img:///UILibrary_XPACK_StrategyImages.BeamVektor_TriggerB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Trigger', '', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_TriggerB", "", 'VektorRifle_BM');

	// Chosen Weapons
	Template.AddUpgradeAttachment('Reargrip', '', "", "", 'ChosenRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Reargrip', '', "", "", 'ChosenSniperRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
	Template.AddUpgradeAttachment('Reargrip', '', "", "", 'ChosenShotgun_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");

	//TLP Weapons
	Template.AddUpgradeAttachment('Trigger', '', "", "", 'TLE_Shotgun_MG', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_trigger");
}

static function int GetFreeFireBonusAmount(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	return UpgradeTemplate.FreeFireChance + (AreUpgradesEmpowered() ? default.FREE_FIRE_EMPOWER_BONUS : 0);
}

// #######################################################################################
// -------------------- RELOAD UPGRADES --------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateBasicReloadUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'ReloadUpgrade_Bsc');

	SetUpReloadUpgrade(Template);
	SetUpTier1Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_MagC_inv";
	Template.NumFreeReloads = default.FREE_RELOADS_BSC;
	
	return Template;
}

static function X2DataTemplate CreateAdvancedReloadUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'ReloadUpgrade_Adv');

	SetUpReloadUpgrade(Template);
	SetUpTier2Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_MagC_inv";
	Template.NumFreeReloads = default.FREE_RELOADS_ADV;
	
	return Template;
}

static function X2DataTemplate CreateSuperiorReloadUpgrade()
{
	local X2WeaponUpgradeTemplate Template;
	
	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'ReloadUpgrade_Sup');

	SetUpReloadUpgrade(Template);
	SetUpTier3Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_AutoLoader_inv";
	Template.NumFreeReloads = default.FREE_RELOADS_SUP;
	
	return Template;
}

static function SetUpReloadUpgrade(out X2WeaponUpgradeTemplate Template)
{
	SetUpWeaponUpgrade(Template);

	Template.FreeReloadCostFn = FreeReloadCost;
	Template.FriendlyRenameFn = Reload_FriendlyRenameAbilityDelegate;
	Template.GetBonusAmountFn = GetReloadBonusAmount;

	Template.MutuallyExclusiveUpgrades.AddItem('ReloadUpgrade');
	Template.MutuallyExclusiveUpgrades.AddItem('ReloadUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('ReloadUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('ReloadUpgrade_Sup');

	// Assault Rifles
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_MagC", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_MagD", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_MagC", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_MagD", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('AutoLoader', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Mag', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_MagC", "", 'AssaultRifle_BM', , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_AutoLoader", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_AutoLoader_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	Template.AddUpgradeAttachment('Mag', '', "", "", 'AssaultRifle_Central', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	
	// Shotguns
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "ConvShotgun.Meshes.SM_ConvShotgun_MagC", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvShotgun_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "ConvShotgun.Meshes.SM_ConvShotgun_MagD", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvShotgun_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "MagShotgun.Meshes.SM_MagShotgun_MagC", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagShotgun_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "MagShotgun.Meshes.SM_MagShotgun_MagD", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagShotgun_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "BeamShotgun.Meshes.SM_BeamShotgun_MagC", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_AutoLoader_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "BeamShotgun.Meshes.SM_BeamShotgun_MagD", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);

	// Sniper Rifles
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "ConvSniper.Meshes.SM_ConvSniper_MagC", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvSniper.ConvSniper_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvSniper_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "ConvSniper.Meshes.SM_ConvSniper_MagD", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvSniper.ConvSniper_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvSniper_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "MagSniper.Meshes.SM_MagSniper_MagC", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "MagSniper.Meshes.SM_MagSniper_MagD", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('AutoLoader', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "BeamSniper.Meshes.SM_BeamSniper_MagC", "", 'SniperRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_AutoLoader", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_AutoLoader_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	
	// Cannons
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Cannon_Mag', "ConvCannon.Meshes.SM_ConvCannon_MagC", "", 'Cannon_CV', , "img:///UILibrary_Common.ConvCannon.ConvCannon_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvCannon_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Cannon_Mag', "ConvCannon.Meshes.SM_ConvCannon_MagD", "", 'Cannon_CV', , "img:///UILibrary_Common.ConvCannon.ConvCannon_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvCannon_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Cannon_Mag', "MagCannon.Meshes.SM_MagCannon_MagC", "", 'Cannon_MG', , "img:///UILibrary_Common.UI_MagCannon.MagCannon_MagC", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagCannon_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Cannon_Mag', "MagCannon.Meshes.SM_MagCannon_MagD", "", 'Cannon_MG', , "img:///UILibrary_Common.UI_MagCannon.MagCannon_MagD", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagCannon_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('AutoLoader', 'UIPawnLocation_WeaponUpgrade_Cannon_Mag', "BeamCannon.Meshes.SM_BeamCannon_MagC", "", 'Cannon_BM', , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_AutoLoader", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamCannon_AutoLoader_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	// Bullpups
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_MagC", "", 'Bullpup_CV', , "img:///UILibrary_XPACK_Common.ConvSMG_MagazineC", "img:///UILibrary_XPACK_StrategyImages.ConvSMG_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_MagD", "", 'Bullpup_CV', , "img:///UILibrary_XPACK_Common.ConvSMG_MagazineD", "img:///UILibrary_XPACK_StrategyImages.ConvSMG_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "MagSMG.Meshes.SM_HOR_Mag_SMG_MagC", "", 'Bullpup_MG', , "img:///UILibrary_XPACK_Common.MagSMG_MagazineC", "img:///UILibrary_XPACK_StrategyImages.MagSMG_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "MagSMG.Meshes.SM_HOR_Mag_SMG_MagD", "", 'Bullpup_MG', , "img:///UILibrary_XPACK_Common.MagSMG_MagazineD", "img:///UILibrary_XPACK_StrategyImages.MagSMG_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Autoloader', 'UIPawnLocation_WeaponUpgrade_Shotgun_Mag', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_MagC", "", 'Bullpup_BM', , "img:///UILibrary_XPACK_Common.BeamSMG_MagazineC", "img:///UILibrary_XPACK_StrategyImages.BeamSMG_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	// Vektor Rifles
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_MagC", "", 'VektorRifle_CV', , "img:///UILibrary_XPACK_Common.ConvVektor_MagazineC", "img:///UILibrary_XPACK_StrategyImages.ConvVektor_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_MagD", "", 'VektorRifle_CV', , "img:///UILibrary_XPACK_Common.ConvVektor_MagazineD", "img:///UILibrary_XPACK_StrategyImages.ConvVektor_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "MagReaperRifle.Meshes.SM_HOR_Mag_ReaperRifle_MagC", "", 'VektorRifle_MG', , "img:///UILibrary_XPACK_Common.MagVektor_MagazineC", "img:///UILibrary_XPACK_StrategyImages.MagVektor_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", NoClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('Mag', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "MagReaperRifle.Meshes.SM_HOR_Mag_ReaperRifle_MagD", "", 'VektorRifle_MG', , "img:///UILibrary_XPACK_Common.MagVektor_MagazineD", "img:///UILibrary_XPACK_StrategyImages.MagVektor_MagD_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip", ClipSizeUpgradePresent);
	Template.AddUpgradeAttachment('AutoLoader', 'UIPawnLocation_WeaponUpgrade_Sniper_Mag', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_MagC", "", 'VektorRifle_BM', , "img:///UILibrary_XPACK_Common.BeamVektor_MagazineC", "img:///UILibrary_XPACK_StrategyImages.BeamVektor_MagC_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	// Chosen Weapons
	Template.AddUpgradeAttachment('Mag', '', "", "", 'ChosenRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	Template.AddUpgradeAttachment('Mag', '', "", "", 'ChosenSniperRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	Template.AddUpgradeAttachment('Mag', '', "", "", 'ChosenShotgun_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");

	//TLP Weapons
	Template.AddUpgradeAttachment('Mag', '', "", "", 'TLE_SniperRifle_BM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
	Template.AddUpgradeAttachment('Mag', '', "", "", 'TLE_SniperRifle_MG', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_clip");
}

static function int GetReloadBonusAmount(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	return UpgradeTemplate.NumFreeReloads + (AreUpgradesEmpowered() ? default.FREE_RELOADS_EMPOWER_BONUS : 0);
}

static function bool NoClipSizeUpgradePresent(array<X2WeaponUpgradeTemplate> AllUpgradeTemplates)
{
	return !ClipSizeUpgradePresent(AllUpgradeTemplates);
}

static function bool ClipSizeUpgradePresent(array<X2WeaponUpgradeTemplate> AllUpgradeTemplates)
{
	local X2WeaponUpgradeTemplate TestTemplate;

	foreach AllUpgradeTemplates(TestTemplate)
	{
		if (TestTemplate.DataName == 'ClipSizeUpgrade' ||
			TestTemplate.DataName == 'ClipSizeUpgrade_Bsc' ||
			TestTemplate.DataName == 'ClipSizeUpgrade_Adv' ||
			TestTemplate.DataName == 'ClipSizeUpgrade_Sup')
		{
			return true;
		}
	}

	return false;
}

// #######################################################################################
// -------------------- OVERWATCH UPGRADES -----------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateBasicMissDamageUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'MissDamageUpgrade_Bsc');

	SetUpMissDamageUpgrade(Template);
	SetUpTier1Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_StockB_inv";
	Template.BonusDamage = default.MISS_DAMAGE_BSC;

	return Template;
}

static function X2DataTemplate CreateAdvancedMissDamageUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'MissDamageUpgrade_Adv');

	SetUpMissDamageUpgrade(Template);
	SetUpTier2Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_StockB_inv";
	Template.BonusDamage = default.MISS_DAMAGE_ADV;
	
	return Template;
}

static function X2DataTemplate CreateSuperiorMissDamageUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'MissDamageUpgrade_Sup');

	SetUpMissDamageUpgrade(Template);
	SetUpTier3Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_HeatsinkB_inv";
	Template.BonusDamage = default.MISS_DAMAGE_SUP;
	
	return Template;
}

static function SetUpMissDamageUpgrade(out X2WeaponUpgradeTemplate Template)
{
	SetUpWeaponUpgrade(Template);

	Template.GetBonusAmountFn = GetDamageBonusAmount;

	Template.MutuallyExclusiveUpgrades.AddItem('MissDamageUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('MissDamageUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('MissDamageUpgrade_Sup');

	// Assault Rifles
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Stock', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_StockB", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_StockB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Crossbar', '', "ConvAttachments.Meshes.SM_ConvCrossbar", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_CrossbarA", , , FreeFireUpgradePresent);
	
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Stock', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_StockB", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_StockB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Crossbar', '', "MagAttachments.Meshes.SM_MagCrossbar", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_Crossbar", , , FreeFireUpgradePresent);
	
	Template.AddUpgradeAttachment('HeatSink', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Stock', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_HeatsinkB", "", 'AssaultRifle_BM', , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_HeatsinkB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_HeatsinkB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', '', "", "", 'AssaultRifle_Central', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	
	// Shotguns
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "ConvShotgun.Meshes.SM_ConvShotgun_StockB", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_StockB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvShotgun_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Crossbar', '', "ConvAttachments.Meshes.SM_ConvCrossbar", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_CrossbarA", , , FreeFireUpgradePresent);
	
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "MagShotgun.Meshes.SM_MagShotgun_StockB", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_StockB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagShotgun_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Crossbar', '', "MagAttachments.Meshes.SM_MagCrossbar", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_Crossbar", , , FreeFireUpgradePresent);
	
	Template.AddUpgradeAttachment('HeatSink', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "BeamShotgun.Meshes.SM_BeamShotgun_HeatsinkB", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_HeatsinkB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_HeatsinkB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");

	// Sniper Rifles
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Sniper_Stock', "ConvSniper.Meshes.SM_ConvSniper_StockB", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvSniper.ConvSniper_StockB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvSniper_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Crossbar', '', "ConvAttachments.Meshes.SM_ConvCrossbar", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_CrossbarA", , , FreeFireUpgradePresent);
	
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Sniper_Stock', "MagSniper.Meshes.SM_MagSniper_StockB", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_StockB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Crossbar', '', "MagAttachments.Meshes.SM_MagCrossbar", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_Crossbar", , , FreeFireUpgradePresent);
	
	Template.AddUpgradeAttachment('HeatSink', 'UIPawnLocation_WeaponUpgrade_Sniper_Stock', "BeamSniper.Meshes.SM_BeamSniper_HeatsinkB", "", 'SniperRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_HeatsinkB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_HeatsinkB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");

	// Cannons
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Cannon_Stock', "ConvCannon.Meshes.SM_ConvCannon_StockB", "", 'Cannon_CV', , "img:///UILibrary_Common.ConvCannon.ConvCannon_StockB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvCannon_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('StockSupport', '', "ConvCannon.Meshes.SM_ConvCannon_StockB_Support", "", 'Cannon_CV');
	
	Template.AddUpgradeAttachment('Foregrip', 'UIPawnLocation_WeaponUpgrade_Cannon_Stock', "MagCannon.Meshes.SM_MagCannon_StockB", "", 'Cannon_MG', , "img:///UILibrary_Common.UI_MagCannon.MagCannon_StockB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagCannon_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('StockSupport', '', "MagCannon.Meshes.SM_MagCannon_StockB_Support", "", 'Cannon_MG');
	
	Template.AddUpgradeAttachment('HeatSink', 'UIPawnLocation_WeaponUpgrade_Cannon_Stock', "BeamCannon.Meshes.SM_BeamCannon_HeatsinkB", "", 'Cannon_BM', , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_HeatsinkB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamCannon_HeatsinkB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");

	// Bullpups
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_StockB", "", 'Bullpup_CV', , "img:///UILibrary_XPACK_Common.ConvSMG_StockB", "img:///UILibrary_XPACK_StrategyImages.ConvSMG_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_StockB", "", 'Bullpup_MG', , "img:///UILibrary_XPACK_Common.ConvSMG_StockB", "img:///UILibrary_XPACK_StrategyImages.MagSMG_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Shotgun_Stock', "BemSMG.Meshes.SM_HOR_Bem_SMG_StockB", "", 'Bullpup_BM', , "img:///UILibrary_XPACK_Common.BeamSMG_StockB", "img:///UILibrary_XPACK_StrategyImages.BeamSMG_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");

	// Vektor Rifles
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Sniper_Stock', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_StockB", "", 'VektorRifle_CV', , "img:///UILibrary_XPACK_Common.ConvVektor_StockB", "img:///UILibrary_XPACK_StrategyImages.ConvVektor_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Sniper_Stock', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_StockB", "", 'VektorRifle_MG', , "img:///UILibrary_XPACK_Common.MagVektor_StockB", "img:///UILibrary_XPACK_StrategyImages.MagVektor_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', 'UIPawnLocation_WeaponUpgrade_Sniper_Stock', "BemReaperRifle.Meshes.SM_HOR_Bem_ReaperRifle_StockB", "", 'VektorRifle_BM', , "img:///UILibrary_XPACK_Common.BeamVektor_StockB", "img:///UILibrary_XPACK_StrategyImages.BeamVektor_StockB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");

	// Chosen Weapons
	Template.AddUpgradeAttachment('Stock', '', "", "", 'ChosenRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', '', "", "", 'ChosenSniperRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', '', "", "", 'ChosenShotgun_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");

	//TLP Weapons
	Template.AddUpgradeAttachment('Stock', '', "", "", 'TLE_Cannon_BM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', '', "", "", 'TLE_Cannon_MG', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
	Template.AddUpgradeAttachment('Stock', '', "", "", 'TLE_Cannon_CV', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_stock");
}

static function int GetDamageBonusAmount(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	return UpgradeTemplate.BonusDamage.Damage + (AreUpgradesEmpowered() ? default.MISS_DAMAGE_EMPOWER_BONUS : 0);
}

static function bool NoFreeFireUpgradePresent(array<X2WeaponUpgradeTemplate> AllUpgradeTemplates)
{
	return !FreeFireUpgradePresent(AllUpgradeTemplates);
}

static function bool FreeFireUpgradePresent(array<X2WeaponUpgradeTemplate> AllUpgradeTemplates)
{
	local X2WeaponUpgradeTemplate TestTemplate;

	foreach AllUpgradeTemplates(TestTemplate)
	{
		if (TestTemplate.DataName == 'FreeFireUpgrade' ||
			TestTemplate.DataName == 'FreeFireUpgrade_Bsc' ||
			TestTemplate.DataName == 'FreeFireUpgrade_Adv' ||
			TestTemplate.DataName == 'FreeFireUpgrade_Sup')
		{
			return true;
		}
	}

	return false;
}

// #######################################################################################
// -------------------- FREE KILL UPGRADES -----------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateBasicFreeKillUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'FreeKillUpgrade_Bsc');

	SetUpFreeKillUpgrade(Template);
	SetUpTier1Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_SuppressorB_inv";
	Template.FreeKillChance = default.FREE_KILL_BSC;
	
	return Template;
}

static function X2DataTemplate CreateAdvancedFreeKillUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'FreeKillUpgrade_Adv');
	
	SetUpFreeKillUpgrade(Template);
	SetUpTier2Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_SupressorB_inv";
	Template.FreeKillChance = default.FREE_KILL_ADV;
	
	return Template;
}

static function X2DataTemplate CreateSuperiorFreeKillUpgrade()
{
	local X2WeaponUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, 'FreeKillUpgrade_Sup');

	SetUpFreeKillUpgrade(Template);
	SetUpTier3Upgrade(Template);

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_SupressorB_inv";
	Template.FreeKillChance = default.FREE_KILL_SUP;
	
	return Template;
}

static function SetUpFreeKillUpgrade(out X2WeaponUpgradeTemplate Template)
{
	SetUpWeaponUpgrade(Template);

	Template.FreeKillFn = FreeKillChance;
	Template.GetBonusAmountFn = GetFreeKillBonusAmount;

	Template.MutuallyExclusiveUpgrades.AddItem('FreeKillUpgrade');
	Template.MutuallyExclusiveUpgrades.AddItem('FreeKillUpgrade_Bsc');
	Template.MutuallyExclusiveUpgrades.AddItem('FreeKillUpgrade_Adv');
	Template.MutuallyExclusiveUpgrades.AddItem('FreeKillUpgrade_Sup');
	
	// Assault Rifles
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Suppressor', "ConvAssaultRifle.Meshes.SM_ConvAssaultRifle_SuppressorB", "", 'AssaultRifle_CV', , "img:///UILibrary_Common.ConvAssaultRifle.ConvAssault_SuppressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvAssault_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Suppressor', "MagAssaultRifle.Meshes.SM_MagAssaultRifle_SuppressorB", "", 'AssaultRifle_MG', , "img:///UILibrary_Common.UI_MagAssaultRifle.MagAssaultRifle_SupressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagAssaultRifle_SupressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_AssaultRifle_Suppressor', "BeamAssaultRifle.Meshes.SM_BeamAssaultRifle_SuppressorB", "", 'AssaultRifle_BM', , "img:///UILibrary_Common.UI_BeamAssaultRifle.BeamAssaultRifle_SupressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamAssaultRifle_SupressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', '', "", "", 'AssaultRifle_Central', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");

	// Shotguns
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Shotgun_Suppressor', "ConvShotgun.Meshes.SM_ConvShotgun_SuppressorB", "", 'Shotgun_CV', , "img:///UILibrary_Common.ConvShotgun.ConvShotgun_SuppressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvShotgun_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Shotgun_Suppressor', "MagShotgun.Meshes.SM_MagShotgun_SuppressorB", "", 'Shotgun_MG', , "img:///UILibrary_Common.UI_MagShotgun.MagShotgun_SuppressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagShotgun_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Shotgun_Suppressor', "BeamShotgun.Meshes.SM_BeamShotgun_SuppressorB", "", 'Shotgun_BM', , "img:///UILibrary_Common.UI_BeamShotgun.BeamShotgun_SupressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamShotgun_SupressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");

	// Sniper Rifles
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Sniper_Suppressor', "ConvSniper.Meshes.SM_ConvSniper_SuppressorB", "", 'SniperRifle_CV', , "img:///UILibrary_Common.ConvSniper.ConvSniper_SuppressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvSniper_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Sniper_Suppressor', "MagSniper.Meshes.SM_MagSniper_SuppressorB", "", 'SniperRifle_MG', , "img:///UILibrary_Common.UI_MagSniper.MagSniper_SuppressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagSniper_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Sniper_Suppressor', "BeamSniper.Meshes.SM_BeamSniper_SuppressorB", "", 'SniperRifle_BM', , "img:///UILibrary_Common.UI_BeamSniper.BeamSniper_SupressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamSniper_SupressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");

	// Cannons
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Cannon_Suppressor', "ConvCannon.Meshes.SM_ConvCannon_SuppressorB", "", 'Cannon_CV', , "img:///UILibrary_Common.ConvCannon.ConvCannon_SuppressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.ConvCannon_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Cannon_Suppressor', "MagCannon.Meshes.SM_MagCannon_SuppressorB", "", 'Cannon_MG', , "img:///UILibrary_Common.UI_MagCannon.MagCannon_SuppressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.MagCannon_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Cannon_Suppressor', "BeamCannon.Meshes.SM_BeamCannon_SuppressorB", "", 'Cannon_BM', , "img:///UILibrary_Common.UI_BeamCannon.BeamCannon_SupressorB", "img:///UILibrary_StrategyImages.X2InventoryIcons.BeamCannon_SupressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");

	// Bullpups
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Shotgun_Suppressor', "CnvSMG.Meshes.SM_HOR_Cnv_SMG_SuppressorB", "", 'Bullpup_CV', , "img:///UILibrary_XPACK_Common.ConvSMG_SuppressorB", "img:///UILibrary_XPACK_StrategyImages.ConvSMG_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Shotgun_Suppressor', "MagSMG.Meshes.SM_HOR_Mag_SMG_SuppressorB", "", 'Bullpup_MG', , "img:///UILibrary_XPACK_Common.MagSMG_SuppressorB", "img:///UILibrary_XPACK_StrategyImages.MagSMG_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Shotgun_Suppressor', "BemSMG.Meshes.SM_HOR_Bem_SMG_SuppressorB", "", 'Bullpup_BM', , "img:///UILibrary_XPACK_Common.BeamSMG_SuppressorB", "img:///UILibrary_XPACK_StrategyImages.BeamSMG_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");

	// Vektor Rifles
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Sniper_Suppressor', "CnvReaperRifle.Meshes.SM_HOR_Cnv_ReaperRifle_SuppressorB", "", 'VektorRifle_CV', , "img:///UILibrary_XPACK_Common.ConvVektor_SuppressorB", "img:///UILibrary_XPACK_StrategyImages.ConvVektor_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Sniper_Suppressor', "MagReaperRifle.Meshes.SM_HOR_Mag_ReaperRifle_SuppressorB", "", 'VektorRifle_MG', , "img:///UILibrary_XPACK_Common.MagVektor_SuppressorB", "img:///UILibrary_XPACK_StrategyImages.MagVektor_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', 'UIPawnLocation_WeaponUpgrade_Sniper_Suppressor', "BemReaperRifle.Meshes.SM_HOR_Bem_ReaperRifle_SuppressorB", "", 'VektorRifle_BM', , "img:///UILibrary_XPACK_Common.BeamVektor_SuppressorB", "img:///UILibrary_XPACK_StrategyImages.BeamVektor_SuppressorB_inv", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");

	// Chosen Weapons
	Template.AddUpgradeAttachment('Suppressor', '', "", "", 'ChosenRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', '', "", "", 'ChosenSniperRifle_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', '', "", "", 'ChosenShotgun_XCOM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");

	//TLP weapons
	Template.AddUpgradeAttachment('Suppressor', '', "", "", 'TLE_AssaultRifle_BM', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");
	Template.AddUpgradeAttachment('Suppressor', '', "", "", 'TLE_AssaultRifle_MG', , "", "", "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_weaponIcon_barrel");

}

static function int GetFreeKillBonusAmount(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	return UpgradeTemplate.FreeKillChance + (AreUpgradesEmpowered() ? default.FREE_KILL_EMPOWER_BONUS : 0);
}

// #######################################################################################
// -------------------- UPGRADE FUNCTIONS ------------------------------------------------
// #######################################################################################

static function bool CanApplyUpgradeToWeapon(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, int SlotIndex)
{
	local array<X2WeaponUpgradeTemplate> AttachedUpgradeTemplates;
	local X2WeaponUpgradeTemplate AttachedUpgrade; 
	local int iSlot;
		
	AttachedUpgradeTemplates = Weapon.GetMyWeaponUpgradeTemplates();

	foreach AttachedUpgradeTemplates(AttachedUpgrade, iSlot)
	{
		// Slot Index indicates the upgrade slot the player intends to replace with this new upgrade
		if (iSlot == SlotIndex)
		{
			// The exact upgrade already equipped in a slot cannot be equipped again
			// This allows different versions of the same upgrade type to be swapped into the slot
			if (AttachedUpgrade == UpgradeTemplate)
			{
				return false;
			}
		}
		else if (UpgradeTemplate.MutuallyExclusiveUpgrades.Find(AttachedUpgrade.DataName) != INDEX_NONE)
		{
			// If the new upgrade is mutually exclusive with any of the other currently equipped upgrades, it is not allowed
			return false;
		}
	}

	return true;
}

static function bool AdjustClipSize(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, const int CurrentClipSize, out int AdjustedClipSize)
{
	AdjustedClipSize = CurrentClipSize + UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate);
	return true;
}

static function bool CritUpgradeModifier(X2WeaponUpgradeTemplate UpgradeTemplate, out int CritChanceMod)
{
	CritChanceMod = UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate);
	return true;
}

static function bool AimUpgradeHitModifier(X2WeaponUpgradeTemplate UpgradeTemplate, const GameRulesCache_VisibilityInfo VisInfo, out int HitChanceMod)
{
	HitChanceMod = UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate);
	if (VisInfo.TargetCover == CT_None)
	{
		HitChanceMod += default.AIM_UPGRADE_NOCOVER_BONUS;
	}
	return true;
}

static function bool FreeReloadCost(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Ability ReloadAbility, XComGameState_Unit UnitState)
{
	local UnitValue FreeReloadValue;

	if (UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate) > 0)
	{
		UnitState.GetUnitValue('FreeReload', FreeReloadValue);
		if (FreeReloadValue.fValue >= UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate))
		{
			return false;
		}
		UnitState.SetUnitFloatValue('FreeReload', FreeReloadValue.fValue + 1, eCleanup_BeginTactical);
	}

	return true;
}

function string Reload_FriendlyRenameAbilityDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Ability AbilityState)
{
	local XComGameState_Unit UnitState;
	local UnitValue FreeReloadValue;

	if (AbilityState.GetMyTemplateName() == 'Reload')
	{
		if (UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate) > 0)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
			UnitState.GetUnitValue('FreeReload', FreeReloadValue);
			if (FreeReloadValue.fValue >= UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate))
				return "";
		}
		return default.FreeReloadAbilityName;
	}
	return "";
}

static function bool FreeFireCost(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Ability FireAbility)
{
	local int Chance;

	if (!FireAbility.AllowFreeFireWeaponUpgrade())
		return false;

	Chance = `SYNC_RAND_STATIC(100);
	return Chance <= UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate);
}

function bool FreeKillChance(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Unit TargetUnit)
{
	local int Chance;

	Chance = `SYNC_RAND_STATIC(100);
	return Chance <= UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate);
}

static function bool AreUpgradesEmpowered()
{
	local XComGameState_HeadquartersXCom XComHQ;

	// Start Issue #1086
	// Pass "true" as second argument to GetSingleGameStateObjectForClass() to prevent the redscreen and log warning if XComHQ doesn't exist.
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	// Add "none" check for XComHQ before accessing bEmpoweredUpgrades.
	return XComHQ != none && XComHQ.bEmpoweredUpgrades;
	// End Issue #1086
}
