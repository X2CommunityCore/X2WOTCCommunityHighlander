class X2WeaponTemplate extends X2EquipmentTemplate
	native(Core) 
	dependson(XGInventoryNativeBase, UIQueryInterfaceItem)
	config(WeaponTuning);

struct native AbilityIconOverride
{
	var() name AbilityName;
	var() string OverrideIcon;
};

struct native AbilityAnimationOverride
{
	var() Name AbilityName;
	var() Name AnimationName;
};

var name            WeaponCat					<ToolTip="must match one of the entries in X2ItemTemplateManager's WeaponCategories">;
var name            WeaponTech					<ToolTip="must match one of the entires in X2ItemTemplateManager's WeaponTechCategories">;
var() Name			UIArmoryCameraPointTag		<ToolTip="The tag of the point in space in the UI armory map where this weapon should be located by default">;
var() ELocation     StowedLocation				<ToolTip="physical attach point to model when not in-hands">;
var() string        WeaponPanelImage			<ToolTip="UI resource for weapon image">;
var bool            bMergeAmmo					<ToolTip="If this item is in the unit's inventory multiple times, the ammo will be consolidated.">;
var() name          ArmorTechCatForAltArchetype <ToolTip="If this field is set, it will load the AltGameArchetype when the unit is wearing armor that matches it.">;
var() EGender		GenderForAltArchetype		<ToolTip ="If this field is set, it will load the AltGameArchetype when the units gender matches.">;

//  Combat related stuff
var config int      iEnvironmentDamage     <ToolTip = "damage to environmental effects; should be 50, 100, or 150.">;
var int             iRange                 <ToolTip = "-1 will mean within the unit's sight, 0 means melee">;
var int             iRadius                <ToolTip = "radius in METERS for AOE range">;
var float           fCoverage              <ToolTip = "percentage of tiles within the radius to affect">;
var int             iTypicalActionCost     <ToolTip = "typical cost in action points to fire the weapon (only used by some abilities)">;
var config int      iClipSize              <ToolTip="ammo amount before a reload is required">;
var config bool     InfiniteAmmo           <ToolTip="no reloading required!">;
var config int      Aim;
var config int      CritChance;
var name            DamageTypeTemplateName				<ToolTip = "Template name for the type of ENVIRONMENT damage this weapon does">;
var array<int>      RangeAccuracy						<ToolTip = "Array of accuracy modifiers, where index is tiles distant from target.">;
var int             iSoundRange							<ToolTip="Range in Meters, for alerting enemies.  (Yellow alert)">;
var bool			bSoundOriginatesFromOwnerLocation   <ToolTip="True for all except grenades(?)">;
var bool			bIsLargeWeapon						<ToolTip="Used in Weapon Upgrade UI to determine distance from camera.">;
var name            OverwatchActionPoint				<ToolTip="Action point type to reserve when using Overwatch with this weapon.">;
var int             iIdealRange                         <ToolTip="the unit's ideal range when using this weapon; only used by the AI. (NYI)">;
var bool            bCanBeDodged;
var bool			bUseArmorAppearance					<ToolTip = "This weapon will use the armor tinting values instead of the weapons">;
var bool			bIgnoreRadialBlockingCover;

var config WeaponDamageValue BaseDamage;  
var config array<WeaponDamageValue> ExtraDamage;

var bool              bOverrideConcealmentRule;
var EConcealmentRule  OverrideConcealmentRule;  //  this is only used if bOverrideConcealmentRule is true

var array<X2Effect> BonusWeaponEffects          <ToolTip="These effects will be applied to single target attacks, in addition to the ability's normal effects.">;

//  Upgrades
var int             NumUpgradeSlots             <ToolTip="Number of weapon slots available">;

// Cosmetic data
var() int             iPhysicsImpulse           <ToolTip="Determines the force within the physics system to apply to objects struck by this weapon">;

var float           fKnockbackDamageAmount		<ToolTip = "Damage amount applied to the environment on knock back.">;
var float           fKnockbackDamageRadius		<ToolTip = "Radius of the affected area at hit tile locations.">;

//  @TODO gameplay - I'd like to see this intermediary class go away, but for now we're stuck with it.
var class<XGItem>   GameplayInstanceClass;

var() array<WeaponAttachment>   DefaultAttachments;

var PrecomputedPathData WeaponPrecomputedPathData;

var() bool            bDisplayWeaponAndAmmo     <ToolTip="If set true, this will display in the lower right corner if set as a primary weapon.">;

// Item stat flags
var() bool			    bHideDamageStat;
var() bool				bHideClipSizeStat;

var protectedwrite array<AbilityIconOverride> AbilityIconOverrides;

var() array<AbilityAnimationOverride>		AbilitySpecificAnimations;
var() bool             bHideWithNoAmmo <ToolTip="If true, the weapon mesh will be hidden upon loading a save if it has no ammo.">;

native function Name GetAnimationNameFromAbilityName(Name AbilityName);
native function SetAnimationNameForAbility(Name AbilityName, Name AnimationName);

function bool ValidateTemplate(out string strError)
{
	local X2ItemTemplateManager ItemTemplateManager;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (!ItemTemplateManager.WeaponCategoryIsValid(WeaponCat))
	{
		strError = "weapon category '" $ WeaponCat $ "' is invalid";
		return false;
	}

	return super.ValidateTemplate(strError);
}

function AddAbilityIconOverride(name AbilityName, string IconImage)
{
	local AbilityIconOverride IconOverride;

	IconOverride.AbilityName = AbilityName;
	IconOverride.OverrideIcon = IconImage;
	AbilityIconOverrides.AddItem(IconOverride);
}

function string GetAbilityIconOverride(name AbilityName)
{
	local int Idx;
	
	if (AbilityIconOverrides.Length > 0)
	{
		Idx = AbilityIconOverrides.Find('AbilityName', AbilityName);
		if (Idx != INDEX_NONE)
			return AbilityIconOverrides[Idx].OverrideIcon;
	}
	return "";
}

function AddExtraDamage(const int _Damage, const int _Spread, const int _PlusOne, const name _Tag)
{
	local WeaponDamageValue NewVal;
	NewVal.Damage = _Damage;
	NewVal.Spread = _Spread;
	NewVal.PlusOne = _PlusOne;
	NewVal.Tag = _Tag;
	ExtraDamage.AddItem(NewVal);
}

function AddDefaultAttachment(name AttachSocket, string MeshName, optional bool AttachToPawn, optional string Icon, optional string InventoryIconName, optional string InventoryCategoryIcon)
{
	local WeaponAttachment Attach;

	Attach.AttachSocket = AttachSocket;
	Attach.AttachMeshName = MeshName;
	Attach.AttachIconName = Icon;
	Attach.InventoryIconName = InventoryIconName;
	Attach.InventoryCategoryIcon = InventoryCategoryIcon;
	Attach.AttachIconName = Icon;
	Attach.AttachToPawn = AttachToPawn;
	DefaultAttachments.AddItem(Attach);
}

function class<XGItem> GetGameplayInstanceClass()
{
	return GameplayInstanceClass;
}

function bool IsLowTech()
{
	return WeaponTech == 'conventional' || WeaponTech == 'magnetic';
}

function bool IsHighTech()
{
	return !IsLowTech();
}

function string GetLocalizedCategory()
{
	// Start Issue #125
	// Variables for Issue #125
	local XComLWTuple Tuple;
	local string CategoryLocale;

	switch(WeaponCat)
	{
		case 'grenade':
			CategoryLocale = class'XGLocalizedData'.default.UtilityCatGrenade;
			break;
		case 'heal':
			CategoryLocale = class'XGLocalizedData'.default.UtilityCatHeal;
			break;
		case 'medikit':
			CategoryLocale = class'XGLocalizedData'.default.UtilityCatHeal;
			break;
		case 'skulljack':
			CategoryLocale = class'XGLocalizedData'.default.UtilityCatSkulljack;
			break;
		default:
			CategoryLocale = class'XGLocalizedData'.default.WeaponCatUnknown;
			break;
	}
	
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'GetLocalizedCategory';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVString;
	Tuple.Data[0].s = CategoryLocale;
	`XEVENTMGR.TriggerEvent('GetLocalizedCategory', Tuple, self, none);
	return Tuple.Data[0].s;
	// End Issue #125
}

function int GetUIStatMarkup(ECharStatType Stat, optional XComGameState_Item Weapon)
{
	local int BonusAim, BonusCrit;
	local int BonusPierce; // Issue #237
	local EUISummary_WeaponStats UpgradeBonuses;

	if (Stat == eStat_Offense)
	{
		BonusAim = Aim;
		if(Weapon != none)
		{
			// We don't care about the stats from the template, we only care about the weapon upgrades (hence we pass none here)
			UpgradeBonuses = Weapon.GetUpgradeModifiersForUI(none);
			if(UpgradeBonuses.bIsAimModified)
			{
				BonusAim += UpgradeBonuses.Aim;
			}
		}
		return super.GetUIStatMarkup(Stat) + BonusAim;
	}

	if (Stat == eStat_CritChance)
	{
		BonusCrit = CritChance;
		if (Weapon != none)
		{
			// We don't care about the stats from the template, we only care about the weapon upgrades (hence we pass none here)
			UpgradeBonuses = Weapon.GetUpgradeModifiersForUI(none);
			if (UpgradeBonuses.bIsCritModified)
			{
				BonusCrit += UpgradeBonuses.Crit;
			}
		}
		return super.GetUIStatMarkup(Stat) + BonusCrit;
	}

	// Issue #237 start
	// ECharStatType doesn't have entries for damage, crit damage, or shred. @TODO: fix the enum definition if this proves to be doable
	if (Stat == eStat_ArmorPiercing)
	{
		BonusPierce = BaseDamage.Pierce;
		if (Weapon != none)
		{
			// We don't care about the stats from the template, we only care about the weapon upgrades (hence we pass none here)
			UpgradeBonuses = Weapon.GetUpgradeModifiersForUI(none);
			if (UpgradeBonuses.bIsPierceModified)
			{
				BonusPierce += UpgradeBonuses.DamageValue.Pierce;
			}
		}
		return super.GetUIStatMarkup(Stat) + BonusPierce;
	}
	// Issue #237 end

	return super.GetUIStatMarkup(Stat);
}

function string DetermineGameArchetypeForUnit(XComGameState_Item ItemState, XComGameState_Unit UnitState, optional TAppearance PawnAppearance)
{
	local string UseArchetype;
	local XComGameState_Item ArmorState;
	local X2ArmorTemplate ArmorTemplate;

	UseArchetype = super.DetermineGameArchetypeForUnit(ItemState, UnitState);
	if (ArmorTechCatForAltArchetype != '' && UseArchetype == GameArchetype)
	{
		ArmorState = UnitState.GetItemInSlot(eInvSlot_Armor);
		if (ArmorState != none)
		{
			ArmorTemplate = X2ArmorTemplate(ArmorState.GetMyTemplate());
			if (ArmorTemplate != none)
			{
				if (ArmorTemplate.ArmorTechCat == ArmorTechCatForAltArchetype)
					UseArchetype = AltGameArchetype;
			}
		}
	}
	
	if (GenderForAltArchetype != eGender_None && UseArchetype == GameArchetype)
	{
		if ((UnitState == none && PawnAppearance.iGender == GenderForAltArchetype) || UnitState.kAppearance.iGender == GenderForAltArchetype)
			UseArchetype = AltGameArchetype;
	}
	return UseArchetype;
}

DefaultProperties
{
	ItemCat="weapon"
	iRange=-1
	GameplayInstanceClass=class'XGWeapon'       //  should no longer need to create child classes	
	bSoundOriginatesFromOwnerLocation=true
	fCoverage=100
	DamageTypeTemplateName = "DefaultProjectile"
	OverwatchActionPoint = "overwatch"
	fKnockbackDamageAmount = -1.0f
	fKnockbackDamageRadius = -1.0f
	bDisplayWeaponAndAmmo=true
	iTypicalActionCost=1
	bCanBeDodged=true
}
