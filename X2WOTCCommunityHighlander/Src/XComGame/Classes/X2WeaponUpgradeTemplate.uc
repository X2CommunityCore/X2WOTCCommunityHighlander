class X2WeaponUpgradeTemplate extends X2ItemTemplate;

var array<WeaponAttachment>    UpgradeAttachments;

var localized string TinySummary;

var int	AimBonus;			// hit chance modifier
var int CritBonus;			// crit chance modifier
var int ClipSizeBonus;		// extra ammo
var int FreeFireChance;		// chance out of 100 that the action will be free
var int NumFreeReloads;		// setting to 0 or less will mean no limit
var WeaponDamageValue BonusDamage;			// amount of bonus damage on shots that allow for it
var WeaponDamageValue CHBonusDamage;		// Issue #237 - secondary amount of bonus damage, more general purpose than the miss-damage-only BonusDamage
var array<name> UpgradeCats;		// Issue #260
var int FreeKillChance;		// chance out of 100 that a damaging shot will become an automatic kill

var array<name> MutuallyExclusiveUpgrades; // upgrades which cannot be equipped at the same time as any of the others
							
var array<name> BonusAbilities;         //  abilities granted to the unit when this upgrade is on an item in its inventory

var delegate<CanApplyUpgradeToWeaponDelegate>			CanApplyUpgradeToWeaponFn;
var delegate<AddCritChanceModifierDelegate>				AddCritChanceModifierFn;
var delegate<AddHitChanceModifierDelegate>				AddHitChanceModifierFn;
var delegate<AdjustClipSizeDelegate>					AdjustClipSizeFn;
var delegate<FreeFireCostDelegate>						FreeFireCostFn;
var delegate<FreeReloadCostDelegate>					FreeReloadCostFn;
var delegate<FreeKillDelegate>							FreeKillFn;
var delegate<FriendlyRenameAbilityDelegate>             FriendlyRenameFn;
var delegate<GetBonusAmountDelegate>					GetBonusAmountFn;
var delegate<AddCHDamageModifierDelegate>				AddCHDamageModifierFn; // Issue #237

delegate bool CanApplyUpgradeToWeaponDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, int SlotIndex);
delegate bool AddCritChanceModifierDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, out int CritChanceMod);
delegate bool AddHitChanceModifierDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, const GameRulesCache_VisibilityInfo VisInfo, out int HitChanceMod);
delegate bool AdjustClipSizeDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, const int CurrentClipSize, out int AdjustedClipSize);
delegate bool FreeFireCostDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Ability FireAbility);
delegate bool FreeReloadCostDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Ability ReloadAbility, XComGameState_Unit UnitState);
delegate bool FreeKillDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Unit TargetUnit);
delegate string FriendlyRenameAbilityDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Ability AbilityState);
delegate int GetBonusAmountDelegate(X2WeaponUpgradeTemplate UpgradeTemplate);
delegate bool AddCHDamageModifierDelegate(X2WeaponUpgradeTemplate UpgradeTemplate, out int StatMod, name StatType); // Issue #237

function AddUpgradeAttachment(
	Name AttachSocket, 
	Name UIArmoryCameraPointTag, 
	string MeshName, 
	string ProjectileName, 
	name MatchWeaponTemplate, 
	optional bool AttachToPawn, 
	optional string IconName, 
	optional string InventoryIconName, 
	optional string InventoryCategoryIcon,
	optional delegate<X2TacticalGameRulesetDataStructures.CheckUpgradeStatus> ValidateAttachmentFn)
{
	local WeaponAttachment Attach;

	Attach.AttachSocket = AttachSocket;
	Attach.UIArmoryCameraPointTag = UIArmoryCameraPointTag;
	Attach.AttachMeshName = MeshName;
	Attach.AttachProjectileName = ProjectileName;
	Attach.ApplyToWeaponTemplate = MatchWeaponTemplate;
	Attach.AttachToPawn = AttachToPawn;
	Attach.AttachIconName = IconName;
	Attach.InventoryIconName = InventoryIconName;
	Attach.InventoryCategoryIcon = InventoryCategoryIcon;
	Attach.ValidateAttachmentFn = ValidateAttachmentFn;
	UpgradeAttachments.AddItem(Attach);
}

function bool CanApplyUpgradeToWeapon(XComGameState_Item Weapon, optional int SlotIndex = 0)
{
	if (CanApplyUpgradeToWeaponFn != none)
		return CanApplyUpgradeToWeaponFn(self, Weapon, SlotIndex);
	return true;
}

/**
 * Gets the socket name that is used to identify location of upgrade on weapon, used by UIArmory_WeaponUpgrade
 * 
 * IMPORTANT: Assumes one socket per weapon - sbatista
 */
function name GetAttachmentSocketName(XComGameState_Item Weapon)
{
	local WeaponAttachment Attach;

	foreach UpgradeAttachments(Attach)
	{
		if(Attach.ApplyToWeaponTemplate == Weapon.GetMyTemplateName())
			return Attach.AttachSocket;
	}

	return '';
}


/**
* Gets the image name of the attachment for the specified weapon, used by UIArmory_WeaponUpgrade
*
* IMPORTANT: Assumes one valid attachment per weapon - bsteiner
*/
function string GetAttachmentInventoryImage(XComGameState_Item Weapon)
{
	local WeaponAttachment Attach;

	foreach UpgradeAttachments(Attach)
	{
		if( Attach.ApplyToWeaponTemplate == Weapon.GetMyTemplateName() )
			return Attach.InventoryIconName;
	}

	return "";
}


/**
* Gets the category image names of the attachment for the specified weapon, used by UIArmory_WeaponUpgrade
*
*/
function array<string> GetAttachmentInventoryCategoryImages(XComGameState_Item Weapon)
{
	local WeaponAttachment Attach;
	local array<string> Images;

	foreach UpgradeAttachments(Attach)
	{
		if( Attach.InventoryCategoryIcon != "" &&
			Attach.ApplyToWeaponTemplate == Weapon.GetMyTemplateName() && 
			Images.Find(Attach.InventoryCategoryIcon) == INDEX_NONE )
			Images.AddItem(Attach.InventoryCategoryIcon);
	}

	return Images;
}

/**
* Gets the renamed friendly-name for an ability that we alter.
*
*/
function string GetRenamedAbilityFriendlyName(XComGameState_Ability AbilityState)
{
	if (FriendlyRenameFn != none)
		return FriendlyRenameFn(self, AbilityState);

	return "";
}

DefaultProperties
{
	ItemCat="upgrade"
	MaxQuantity=3
}
