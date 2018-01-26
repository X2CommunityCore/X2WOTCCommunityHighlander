//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2SoldierClassTemplate.uc
//  AUTHOR:  Timothy Talley  --  01/18/2014
//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2SoldierClassTemplate extends X2DataTemplate
	dependson(X2TacticalGameRulesetDataStructures)
	config(ClassData)
	native(Core);

var config protected array<SoldierClassRank> SoldierRanks;
var config array<SoldierClassWeaponType>    AllowedWeapons;
var config array<name>						AllowedArmors;
var config array<name>                      ExcludedAbilities;  //  Abilities that are not eligible to roll from AWC for this calss
var config array<name>						AcceptedCharacterTemplates;		//	Some classes may be limited to specific templates, not just those marked bIsSoldier
var config name					SquaddieLoadout;
var config string				IconImage;
var config int					NumInForcedDeck;
var config int					NumInDeck;
var config int					ClassPoints;    // Number of "points" associated with using this class type, i.e. Multiplayer or Daily Challenge
var config int                  KillAssistsPerKill;     //  Number of kill assists that count as a kill for ranking up
var config int                  PsiCreditsPerKill;      //  Number of psi credits that count as a kill for ranking up
var config bool					bAllowAWCAbilities; // If this class should receive or share AWC abilities
var config bool					bUniqueTacticalToStrategyTransfer; // If this class has unique tactical to strategy transfer code, used for DLC and modding
var config bool					bIgnoreInjuries; // This class can go on missions even if they are wounded
var config bool					bBlockRankingUp; // Do not let soldiers of this class rank up in the normal way from XP
var config bool					bNoSecondaryWeapon;
var config array<EInventorySlot> CannotEditSlots; // Slots which cannot be edited in the armory loadout
var config protectedwrite bool  bMultiplayerOnly;
var config protectedwrite bool	bHideInCharacterPool;
var config name					RequiredCharacterClass; // Used in the character pool if this class has a required character template
var config bool					bHasClassMovie; // Does this class show a class movie upon first time getting a unit of this class
var config bool					bCanHaveBonds; // Can this class type have bonds with other soldiers and engage with that system
var config array<name>			FavoredClasses; // Will usually have higher compatibility with these classes in the bond system
var config array<name>			UnfavoredClasses; // Will usually have lower compatibility with these classes in the bond system
var config float				ForcedCompatibiliy; // If greater than zero, this is used as compatibility score with all other soldiers (if you want to force zero set bCanHaveBonds to false)
var config array<SoldierClassRandomAbilityDeck> RandomAbilityDecks; // Needed if slots in the ability tree pick a random ability
var config float				MinSuperConcealedDistance;	//	used by GetConcealmentDetectionDistance
var config int					BaseAbilityPointsPerPromotion; // The amount of ability points granted each time a unit of this class ranks up
var config int					AbilityPointsIncrementPerPromotion; // The amount a soldiers ability point reward is incremented each successive time they rank up

var localized string			DisplayName;
var localized string			ClassSummary;
var localized string			LeftAbilityTreeTitle;	//  don't use for all future classes
var localized string			RightAbilityTreeTitle;  //  don't use for all future classes
var localized array<string>		AbilityTreeTitles;		//  need one for each tree (base game classes have 2, xpack classes have 4)
var localized array<string>		RankNames;				//  there should be one name for each rank; e.g. Rookie, Squaddie, etc.
var localized array<string>		ShortNames;				//  the abbreviated rank name; e.g. Rk., Sq., etc.
var localized array<string>		RankIcons;				//  strings of image names for specialized rank icons
var localized array<String>     RandomNickNames;        //  Selected randomly when the soldier hits a certain rank, if the player has not set one already.
var localized array<String>     RandomNickNames_Female; //  Female only nicknames.
var localized array<String>     RandomNickNames_Male;   //  Male only nicknames.
var localized array<String>     PhotoboothSoloBLines_Female; //  Female only photobooth solo lines.
var localized array<String>     PhotoboothSoloBLines_Male;   //  Male only photobooth solo lines.

var delegate<CheckSpecialGuaranteedHitDelegate> CheckSpecialGuaranteedHitFn;
var delegate<CheckSpecialCritLabelDelegate> CheckSpecialCritLabelFn;
var delegate<GetTargetingMethodPostProcessDelegate> GetTargetingMethodPostProcessFn;

delegate name CheckSpecialGuaranteedHitDelegate(XComGameState_Unit UnitState, XComGameState_Ability AbilityState, XComGameState_Item WeaponState, XComGameState_Unit TargetState);
delegate string CheckSpecialCritLabelDelegate(XComGameState_Unit UnitState, XComGameState_Ability AbilityState, XComGameState_Item WeaponState, XComGameState_Unit TargetState);
delegate bool GetTargetingMethodPostProcessDelegate(XComGameState_Unit UnitState, XComGameState_Ability AbilityState, XComGameState_Item WeaponState, XComGameState_Unit TargetState, out name EnabledPostProcess, out name DisabledPostProcess);

function int GetMaxConfiguredRank()
{
	return SoldierRanks.Length;
}

function array<SoldierClassAbilitySlot> GetAbilitySlots(int Rank)
{
	if(Rank < 0 || Rank >= SoldierRanks.Length)
	{
		`RedScreen(string(GetFuncName()) @ "called with invalid Rank" @ Rank @ "for template" @ DataName @ DisplayName);
		return SoldierRanks[0].AbilitySlots;
	}

	return SoldierRanks[Rank].AbilitySlots;
}

function array<SoldierClassStatType> GetStatProgression(int Rank)
{
	if (Rank < 0 || Rank >= SoldierRanks.Length)
	{
		`RedScreen(string(GetFuncName()) @ "called with invalid Rank" @ Rank @ "for template" @ DataName @ DisplayName);
		return SoldierRanks[0].aStatProgression;
	}
	return SoldierRanks[Rank].aStatProgression;
}

function array<SoldierClassAbilityType> GetAllPossibleAbilities()
{
	local array<SoldierClassAbilityType> AllPossibleAbilities;
	local int DeckIndex, AbIndex, RankIndex, SlotIndex;

	AllPossibleAbilities.Length = 0;

	// Grab all abilities from the normal slots
	for(RankIndex = 0; RankIndex < SoldierRanks.Length; RankIndex++)
	{
		for(SlotIndex = 0; SlotIndex < SoldierRanks[RankIndex].AbilitySlots.Length; SlotIndex++)
		{
			if(SoldierRanks[RankIndex].AbilitySlots[SlotIndex].AbilityType.AbilityName != '' &&
			   AllPossibleAbilities.Find('AbilityName', SoldierRanks[RankIndex].AbilitySlots[SlotIndex].AbilityType.AbilityName) == INDEX_NONE)
			{
				AllPossibleAbilities.AddItem(SoldierRanks[RankIndex].AbilitySlots[SlotIndex].AbilityType);
			}
		}
	}

	// Grab all abilities from random decks
	for(DeckIndex = 0; DeckIndex < RandomAbilityDecks.Length; DeckIndex++)
	{
		for(AbIndex = 0; AbIndex < RandomAbilityDecks[DeckIndex].Abilities.Length; AbIndex++)
		{
			if(RandomAbilityDecks[DeckIndex].Abilities[AbIndex].AbilityName != '' && 
			   AllPossibleAbilities.Find('AbilityName', RandomAbilityDecks[DeckIndex].Abilities[AbIndex].AbilityName) == INDEX_NONE)
			{
				AllPossibleAbilities.AddItem(RandomAbilityDecks[DeckIndex].Abilities[AbIndex]);
			}
		}
	}

	return AllPossibleAbilities;
}

function bool IsWeaponAllowedByClass(X2WeaponTemplate WeaponTemplate)
{
	local int i;

	switch(WeaponTemplate.InventorySlot)
	{
	case eInvSlot_PrimaryWeapon: break;
	case eInvSlot_SecondaryWeapon: break;
	default:
		return true;
	}

	for (i = 0; i < AllowedWeapons.Length; ++i)
	{
		if (WeaponTemplate.InventorySlot == AllowedWeapons[i].SlotType &&
			WeaponTemplate.WeaponCat == AllowedWeapons[i].WeaponType)
			return true;
	}
	return false;
}

function bool IsArmorAllowedByClass(X2ArmorTemplate ArmorTemplate)
{
	local int i;

	switch (ArmorTemplate.InventorySlot)
	{
	case eInvSlot_Armor: break;
	default:
		return true;
	}
	
	for (i = 0; i < AllowedArmors.Length; ++i)
	{
		if (ArmorTemplate.ArmorCat == AllowedArmors[i])
			return true;
	}
	return false;
}

function string X2SoldierClassTemplate_ToString()
{
	local string str;
	local int rankIdx, subIdx;

	str = " X2SoldierClassTemplate:" @ `ShowVar(DataName) @ `ShowVar(SoldierRanks.Length, 'Num Ranks') @ `ShowVar(SquaddieLoadout) @ `ShowVar(AllowedWeapons.Length, 'Weapons') $ "\n";
	for(subIdx = 0; subIdx < AllowedWeapons.Length; ++subIdx)
	{
		str $= "        Weapon Type(" $ subIdx $ ") - " $ `ShowVar(AllowedWeapons[subIdx].WeaponType, 'Weapon Type') @ `ShowVar(AllowedWeapons[subIdx].SlotType, 'Slot Type') $ "\n";
	}
	for(rankIdx = 0; rankIdx < SoldierRanks.Length; ++rankIdx)
	{
		str $= "    Rank(" $ rankIdx $ ") - " $ `ShowVar(SoldierRanks[rankIdx].AbilitySlots.Length, 'Abilities') @ `ShowVar(SoldierRanks[rankIdx].aStatProgression.Length, 'StatProgressions') $ "\n";
		//for(subIdx = 0; subIdx < SoldierRanks[rankIdx].aAbilityTree.Length; ++subIdx)
		//{
		//	str $= "        Ability(" $ subIdx $ ") - " $ `ShowVar(SoldierRanks[rankIdx].aAbilityTree[subIdx].AbilityName, 'Ability Name') $ "\n";
		//}
		for(subIdx = 0; subIdx < SoldierRanks[rankIdx].aStatProgression.Length; ++subIdx)
		{
			str $= "        Stat Progression(" $ subIdx $ ") - " $ `ShowVar(SoldierRanks[rankIdx].aStatProgression[subIdx].StatType, 'Stat Type') @ `ShowVar(SoldierRanks[rankIdx].aStatProgression[subIdx].StatAmount, 'Stat Amount') $ "\n";
		}
	}
	return str;
}

function int GetPointValue()
{
	return ClassPoints;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = true
}