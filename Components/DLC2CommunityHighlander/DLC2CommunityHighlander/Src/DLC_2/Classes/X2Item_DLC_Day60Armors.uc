//---------------------------------------------------------------------------------------
//  FILE:    X2Item_DLC_Day60Armors.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Item_DLC_Day60Armors extends X2Item;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Armors;

	Armors.AddItem(CreateMediumAlienArmor());
	Armors.AddItem(CreateHeavyAlienArmor());
	Armors.AddItem(CreateHeavyAlienArmorMk2());
	Armors.AddItem(CreateLightAlienArmor());
	Armors.AddItem(CreateLightAlienArmorMk2());
	return Armors;
}

static function X2DataTemplate CreateMediumAlienArmor()
{
	local X2ArmorTemplate Template;
			
	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'MediumAlienArmor');
	Template.strImage = "img:///UILibrary_DLC2Images.Inv_IcarusArmor";
	Template.ItemCat = 'armor';
	Template.bAddsUtilitySlot = true;
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.PointsToComplete = 0;
	Template.Abilities.AddItem('MediumAlienArmorStats');
	Template.Abilities.AddItem('VaultAbility');
	Template.Abilities.AddItem('VaultAbilityPassive');
	Template.Abilities.AddItem('IcarusPanic');
	Template.Abilities.AddItem('IcarusJump');
	Template.ArmorTechCat = 'powered';
	Template.Tier = 5;
	Template.AkAudioSoldierArmorSwitch = 'Icarus_Suit';
	Template.EquipNarrative = "DLC_60_NarrativeMoments.CIN_ArmorIntro_AlienMedium";
	Template.EquipSound = "StrategyUI_Armor_Equip_Powered";

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.MEDIUM_ALIEN_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.MEDIUM_ALIEN_MOBILITY_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.MEDIUM_ALIEN_MITIGATION_AMOUNT);

	Template.OnEquippedFn = SetIcarusSuitArmorTint;
	Template.OnUnequippedFn = ClearHelmet;

	return Template;
}

static function SetIcarusSuitArmorTint(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ArmorTemplate ArmorTemplate;
	local XComNarrativeMoment EquipNarrativeMoment;

	ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());
	
	if (ArmorTemplate != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		EquipNarrativeMoment = XComNarrativeMoment(`CONTENT.RequestGameArchetype(ArmorTemplate.EquipNarrative));

		// If the armor intro for this armor hasn't been played yet, set the appearance for this armor
		if (XComHQ.CanPlayArmorIntroNarrativeMoment(EquipNarrativeMoment))
		{
			UnitState.kAppearance.iArmorTint = 72;
			UnitState.kAppearance.iArmorTintSecondary = 85;
			UnitState.kAppearance.nmPatterns = 'Pat_Nothing';
		}
	}
}

static function X2DataTemplate CreateHeavyAlienArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'HeavyAlienArmor');
	Template.strImage = "img:///UILibrary_DLC2Images.Inv_RageSuit";
	Template.ItemCat = 'armor';
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.PointsToComplete = 0;
	Template.bHeavyWeapon = true;
	Template.Abilities.AddItem('HeavyAlienArmorStats');
	Template.Abilities.AddItem('Ragestrike');
	Template.Abilities.AddItem('RagePanic');
	Template.ArmorTechCat = 'plated';
	Template.Tier = 3;
	Template.AkAudioSoldierArmorSwitch = 'RAGE_Suit';
	Template.EquipNarrative = "DLC_60_NarrativeMoments.CIN_ArmorIntro_AlienHeavy";
	Template.EquipSound = "StrategyUI_Armor_Equip_Plated";
	
	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.HEAVY_ALIEN_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.HEAVY_ALIEN_MOBILITY_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.HEAVY_ALIEN_MITIGATION_AMOUNT);

	Template.OnEquippedFn = SetRageSuitArmorTint;

	return Template;
}

static function X2DataTemplate CreateHeavyAlienArmorMk2()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'HeavyAlienArmorMk2');
	Template.strImage = "img:///UILibrary_DLC2Images.Inv_RageSuit";
	Template.ItemCat = 'armor';
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.PointsToComplete = 0;
	Template.bHeavyWeapon = true;
	Template.Abilities.AddItem('HeavyAlienArmorMk2Stats');
	Template.Abilities.AddItem('Ragestrike');
	Template.Abilities.AddItem('RagePanic');
	Template.ArmorTechCat = 'plated';
	Template.Tier = 5;
	Template.AkAudioSoldierArmorSwitch = 'RAGE_Suit';
	Template.EquipNarrative = "DLC_60_NarrativeMoments.CIN_ArmorIntro_AlienHeavy";
	Template.EquipSound = "StrategyUI_Armor_Equip_Powered";

	Template.CreatorTemplateName = 'HeavyAlienArmorMk2_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'HeavyAlienArmor'; // Which item this will be upgraded from
	
	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.HEAVY_ALIEN_MK2_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.HEAVY_ALIEN_MK2_MOBILITY_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.HEAVY_ALIEN_MK2_MITIGATION_AMOUNT);

	Template.OnEquippedFn = SetRageSuitArmorTint;

	return Template;
}

static function SetRageSuitArmorTint(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ArmorTemplate ArmorTemplate;
	local XComNarrativeMoment EquipNarrativeMoment;

	ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

	if (ArmorTemplate != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		EquipNarrativeMoment = XComNarrativeMoment(`CONTENT.RequestGameArchetype(ArmorTemplate.EquipNarrative));

		// If the armor intro for this armor hasn't been played yet, set the appearance for this armor
		if (XComHQ.CanPlayArmorIntroNarrativeMoment(EquipNarrativeMoment))
		{
			UnitState.kAppearance.iArmorTint = 72;
			UnitState.kAppearance.iArmorTintSecondary = 95;
			UnitState.kAppearance.nmPatterns = 'Pat_Nothing';
		}
	}
}

static function X2DataTemplate CreateLightAlienArmor()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'LightAlienArmor');
	Template.strImage = "img:///UILibrary_DLC2Images.Inv_SerpentArmor";
	Template.ItemCat = 'armor';
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.PointsToComplete = 0;
	Template.Abilities.AddItem('LightAlienArmorStats');
	Template.Abilities.AddItem('Grapple');
	Template.Abilities.AddItem('FreezingLash');
	Template.Abilities.AddItem('SerpentPanic');
	Template.ArmorTechCat = 'plated';
	Template.Tier = 3;
	Template.AkAudioSoldierArmorSwitch = 'Serpent_Suit';
	Template.EquipNarrative = "DLC_60_NarrativeMoments.CIN_ArmorIntro_AlienLight";
	Template.EquipSound = "StrategyUI_Armor_Equip_Plated";
	
	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.LIGHT_ALIEN_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.LIGHT_ALIEN_MOBILITY_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.DodgeLabel, eStat_Dodge, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.LIGHT_ALIEN_DODGE_BONUS);

	Template.OnEquippedFn = SetSerpentSuitArmorTint;
	Template.OnUnequippedFn = ClearHelmet;

	return Template;
}

static function X2DataTemplate CreateLightAlienArmorMk2()
{
	local X2ArmorTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ArmorTemplate', Template, 'LightAlienArmorMk2');
	Template.strImage = "img:///UILibrary_DLC2Images.Inv_SerpentArmor";
	Template.ItemCat = 'armor';
	Template.StartingItem = false;
	Template.CanBeBuilt = false;
	Template.PointsToComplete = 0;
	Template.Abilities.AddItem('LightAlienArmorMk2Stats');
	Template.Abilities.AddItem('GrapplePowered');
	Template.Abilities.AddItem('FreezingLash');
	Template.Abilities.AddItem('SerpentPanic');
	Template.ArmorTechCat = 'powered';
	Template.Tier = 5;
	Template.AkAudioSoldierArmorSwitch = 'Serpent_Suit';
	Template.EquipNarrative = "DLC_60_NarrativeMoments.CIN_ArmorIntro_AlienLight";
	Template.EquipSound = "StrategyUI_Armor_Equip_Powered";

	Template.CreatorTemplateName = 'LightAlienArmorMk2_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'LightAlienArmor'; // Which item this will be upgraded from

	Template.SetUIStatMarkup(class'XLocalizedData'.default.HealthLabel, eStat_HP, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.LIGHT_ALIEN_MK2_HEALTH_BONUS, true);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.MobilityLabel, eStat_Mobility, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.LIGHT_ALIEN_MK2_MOBILITY_BONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.DodgeLabel, eStat_Dodge, class'X2Ability_DLC_Day60ItemGrantedAbilitySet'.default.LIGHT_ALIEN_MK2_DODGE_BONUS);

	Template.OnEquippedFn = SetSerpentSuitArmorTint;
	Template.OnUnequippedFn = ClearHelmet;

	return Template;
}

static function SetSerpentSuitArmorTint(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ArmorTemplate ArmorTemplate;
	local XComNarrativeMoment EquipNarrativeMoment;

	ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

	if (ArmorTemplate != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		EquipNarrativeMoment = XComNarrativeMoment(`CONTENT.RequestGameArchetype(ArmorTemplate.EquipNarrative));

		// If the armor intro for this armor hasn't been played yet, set the appearance for this armor
		if (XComHQ.CanPlayArmorIntroNarrativeMoment(EquipNarrativeMoment))
		{
			UnitState.kAppearance.iArmorTint = 84;
			UnitState.kAppearance.iArmorTintSecondary = 96;
			UnitState.kAppearance.nmPatterns = 'DLC_60_Patterns_E';
		}
	}
}

static function ClearHelmet(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	UnitState.kAppearance.nmHelmet = '';
}