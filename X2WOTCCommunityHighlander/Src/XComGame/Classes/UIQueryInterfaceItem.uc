//---------------------------------------------------------------------------------------
//  FILE:    UIQueryInterfaceItem.uc
 //  AUTHOR:  Brit Steiner --  6/25/2014
 //  PURPOSE: Define data needed in the UI item info tooltips. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

interface UIQueryInterfaceItem
	dependson(UIUtilities_Text); 

struct EUISummary_WeaponStats
{
	var int Damage;
	var WeaponDamageValue DamageValue; // Issue #237
	var int Crit;
	var int Aim;
	var int ClipSize;
	var int Range;
	var int FreeFirePct;
	var int FreeReloads;
	var int MissDamage;
	var int FreeKillPct;
	var X2ItemTemplate SpecialAmmo;

	//Is the stat modified by any upgrades? 
	var bool bIsDamageModified;
	var bool bIsSpreadModified; // Issue #237
	var bool bIsCritDamageModified; // Issue #237
	var bool bIsCritModified;
	var bool bIsAimModified;
	var bool bIsPierceModified; // Issue #237
	var bool bIsRuptureModified; // Issue #237
	var bool bIsShredModified; // Issue #237
	var bool bIsClipSizeModified;
	var bool bIsAmmoModified;
	var bool bIsRangeModified;
	var bool bIsFreeFirePctModified;
	var bool bIsFreeReloadsModified;
	var bool bIsMissDamageModified;
	var bool bIsFreeKillPctModified;

	// Can contain any sort of special or modded information
	var array<string> SpecialNotesLabels;
	var array<string> SpecialNotesValues;

	structdefaultproperties
	{
		bIsDamageModified=false;
		bIsSpreadModified=false; // Issue #237
		bIsCritDamageModified=false; // Issue #237
		bIsCritModified=false;
		bIsAimModified=false;
		bIsPierceModified=false; // Issue #237
		bIsRuptureModified=false; // Issue #237
		bIsShredModified=false; // Issue #237
		bIsClipSizeModified=false;
		bIsAmmoModified=false;
		bIsFreeFirePctModified=false;
		bIsFreeReloadsModified=false;
		bIsMissDamageModified=false;
		bIsFreeKillPctModified=false;
	}
};

struct EUISummary_WeaponUpgrade
{
	var X2WeaponUpgradeTemplate UpgradeTemplate;
	//The label/values of the stats that this upgrade modifies. 
	var array<string> Labels;
	var array<string> Values; 
};

struct UISummary_TacaticalText
{
	var string Name; 
	var string Description; 
	var string Icon;
};

simulated function EUISummary_WeaponStats GetWeaponStatsForUI();
simulated function EUISummary_WeaponStats GetUpgradeModifiersForUI(X2WeaponUpgradeTemplate UpgradeTemplate);
simulated function array<EUISummary_WeaponUpgrade> GetWeaponUpgradesForTooltipUI();


simulated function array<UISummary_ItemStat> GetUISummary_ItemBasicStats(); 
simulated function array<UISummary_ItemStat> GetUISummary_ItemSecondaryStats(); 
simulated function array<UISummary_ItemStat> GetUISummary_AmmoStats();

simulated function array<UISummary_TacaticalText> GetUISummary_TacticalTextAbilities();
simulated function array<UISummary_TacaticalText> GetUISummary_TacticalTextUpgrades();
simulated function array<UISummary_TacaticalText> GetUISummary_TacticalText();
