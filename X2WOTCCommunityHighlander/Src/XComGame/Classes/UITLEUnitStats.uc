//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPUnitStats.uc
//  AUTHOR:  sbatista - 10/21/15
//  PURPOSE: A popup with unit's statistics and abilities that is shown during MP Squad Selection
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITLEUnitStats extends UITLEScreen;

var UISoldierHeader SoldierHeader;
var UINavigationHelp NavHelp;

var UIPanel LeftArrow;
var UIPanel RightArrow;

var array<XComGameState_Unit> m_UnitArray;
var XComGameState m_CheckGameState;
var int m_CurrentIndex;

var localized string m_ScreenTitle;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	SoldierHeader = Spawn(class'UISoldierHeader', self).InitSoldierHeader();
	SoldierHeader.bAlwaysHideXPackPanel = true;

	NavHelp = GetNavHelp();
	if( NavHelp != none )
	{
		NavHelp.ClearButtonHelp();
		NavHelp.AddBackButton(CloseScreen);

		if( `ISCONTROLLERACTIVE )
		{
			NavHelp.AddCenterHelp(class'UITacticalHUD_MouseControls'.default.m_strNextSoldier, class'UIUtilities_Input'.const.ICON_LB_L1, PrevSoldier);
			NavHelp.AddCenterHelp(class'UITacticalHUD_MouseControls'.default.m_strPrevSoldier, class'UIUtilities_Input'.const.ICON_RB_R1, NextSoldier);
		}
		else
		{
			LeftArrow = Spawn(class'UIPanel', self);
			LeftArrow.InitPanel('LeftArrow', 'ArrowButton');
			LeftArrow.ProcessMouseEvents(OnArrowMouseEvent);
			RightArrow = Spawn(class'UIPanel', self);
			RightArrow.InitPanel('RightArrow', 'ArrowButton');
			RightArrow.ProcessMouseEvents(OnArrowMouseEvent);
		}
		NavHelp.Show();
	}
}

simulated function PrevSoldier()
{
	m_CurrentIndex -= 1;
	if( m_CurrentIndex < 0 )
	{
		m_CurrentIndex = m_UnitArray.Length - 1;
	}
	UpdateData(m_UnitArray[m_CurrentIndex], m_CheckGameState);
}
simulated function NextSoldier()
{
	m_CurrentIndex += 1;
	if( m_CurrentIndex >= m_UnitArray.Length )
	{
		m_CurrentIndex = 0;
	}
	UpdateData(m_UnitArray[m_CurrentIndex], m_CheckGameState);
}

simulated function OnArrowMouseEvent(UIPanel Panel, int Cmd)
{
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		if (Panel == LeftArrow)
		{
			PrevSoldier();			
		}
		else if (Panel == RightArrow)
		{
			NextSoldier();
		}		
		break;
	}
}

simulated function UpdateData(XComGameState_Unit Unit, XComGameState CheckGameState)
{
	local StateObjectReference UnitStateRef;
	local X2SoldierClassTemplate SoldierClass;
	local XComGameState_CampaignSettings CurrentCampaign;
	local Texture2D SoldierPicture;
	local XComGameStateHistory History;
	local XComGameState_LadderProgress LadderData;

	History = class'XComGameStateHistory'.static.GetGameStateHistory();

	LadderData = XComGameState_LadderProgress(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));

	CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	UnitStateRef = Unit.GetReference();
	SoldierClass = Unit.GetSoldierClassTemplate();
	
	MC.FunctionString("SetScreenTitle", m_ScreenTitle);

	MC.FunctionString("SetScreenSubtitle", class'XLocalizedData'.default.AbilityListHeader);

	mc.FunctionVoid("ClearSoldierAbilities");

	MC.BeginFunctionOp("SetSoldierData");

	SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(CurrentCampaign.GameIndex, UnitStateRef.ObjectID, 128, 128);
	if (SoldierPicture != none)
	{
		MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture))); // Picture Image
	}
	else
	{
		if (LadderData != none && LadderData.LadderIndex < 10)
		{
			MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath("UILibrary_TLE_Common.TLE_Ladder_" $ LadderData.LadderIndex $ "_" $ LadderData.FixedNarrativeUnits[LadderData.LadderIndex - 1].LastNames[m_CurrentIndex]));
		}
		else
		{
			MC.QueueString(""); // Picture Image
		}
	}

	MC.QueueString(SoldierClass.IconImage); //Class Icon Image
	MC.QueueString(class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName())); //Rank image
	MC.QueueString(class'X2ExperienceConfig'.static.GetRankName(Unit.GetSoldierRank(), Unit.GetSoldierClassTemplateName()));
	
	if (LadderData.LadderIndex < 10)
	{
		MC.QueueString(class'XComGameState_LadderProgress'.static.GetUnitName(m_CurrentIndex, LadderData.LadderIndex)); //Unit Name
	}
	else
	{
		MC.QueueString(Unit.GetFullName());
	}
	
	MC.QueueString(SoldierClass.DisplayName); //Class Name
	MC.EndOp();

	PopulateAbilities( Unit, CheckGameState);
	PopulateStats(Unit, CheckGameState);
	PopulateSoldierGear(Unit, CheckGameState);
}

simulated function PopulateAbilities(XComGameState_Unit Unit, XComGameState CheckGameState)
{
	local int i, Index;
	local X2AbilityTemplate AbilityTemplate;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2CharacterTemplate CharacterTemplate;
	local name AbilityName;
	local string TmpStr;

	AbilityTree = Unit.GetEarnedSoldierAbilities();
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	for (i = 0; i < AbilityTree.Length; ++i)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[i].AbilityName);
		if (!AbilityTemplate.bDontDisplayInAbilitySummary)
		{
			MC.BeginFunctionOp("SetSoldierAbility");
			MC.QueueNumber(Index++);
			MC.QueueString(AbilityTemplate.IconImage);

			// Ability Name
			TmpStr = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for '" $ AbilityTemplate.DataName $ "'");
			MC.QueueString(TmpStr);

			// Ability Description
			TmpStr = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, Unit, CheckGameState) : ("Missing 'LocLongDescription' for " $ AbilityTemplate.DataName $ "'");
			MC.QueueString(TmpStr);

			MC.EndOp();
		}
	}

	CharacterTemplate = Unit.GetMyTemplate();

	foreach CharacterTemplate.Abilities(AbilityName)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);
		if (AbilityTemplate != none &&
			!AbilityTemplate.bDontDisplayInAbilitySummary &&
			AbilityTemplate.ConditionsEverValidForUnit(Unit, true))
		{
			MC.BeginFunctionOp("SetSoldierAbility");
			MC.QueueNumber(Index++);
			MC.QueueString(AbilityTemplate.IconImage);

			// Ability Name
			TmpStr = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for '" $ AbilityTemplate.DataName $ "'");
			MC.QueueString(TmpStr);

			// Ability Description
			TmpStr = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, Unit, CheckGameState) : ("Missing 'LocLongDescription' for " $ AbilityTemplate.DataName $ "'");
			MC.QueueString(TmpStr);

			MC.EndOp();
		}
	}

}

public function PopulateStats(XComGameState_Unit Unit, optional XComGameState NewCheckGameState)
{
	local int  WillBonus, AimBonus, HealthBonus, MobilityBonus, TechBonus, PsiBonus, ArmorBonus, DodgeBonus;
	local string Will, Aim, Health, Mobility, Tech, Psi, Armor, Dodge;

	// Get Unit base stats and any stat modifications from abilities
	Will = string(int(Unit.GetCurrentStat(eStat_Will)) + Unit.GetUIStatFromAbilities(eStat_Will)) $ "/" $ string(int(Unit.GetMaxStat(eStat_Will)));
	Will = class'UIUtilities_Text'.static.GetColoredText(Will, Unit.GetMentalStateUIState());
	Aim = string(int(Unit.GetCurrentStat(eStat_Offense)) + Unit.GetUIStatFromAbilities(eStat_Offense));
	Health = string(int(Unit.GetCurrentStat(eStat_HP)) + Unit.GetUIStatFromAbilities(eStat_HP));
	Mobility = string(int(Unit.GetCurrentStat(eStat_Mobility)) + Unit.GetUIStatFromAbilities(eStat_Mobility));
	Tech = string(int(Unit.GetCurrentStat(eStat_Hacking)) + Unit.GetUIStatFromAbilities(eStat_Hacking));
	Armor = string(int(Unit.GetCurrentStat(eStat_ArmorMitigation)) + Unit.GetUIStatFromAbilities(eStat_ArmorMitigation));
	Dodge = string(int(Unit.GetCurrentStat(eStat_Dodge)) + Unit.GetUIStatFromAbilities(eStat_Dodge));

	// Get bonus stats for the Unit from items
	WillBonus = Unit.GetUIStatFromInventory(eStat_Will, NewCheckGameState);
	AimBonus = Unit.GetUIStatFromInventory(eStat_Offense, NewCheckGameState);
	HealthBonus = Unit.GetUIStatFromInventory(eStat_HP, NewCheckGameState);
	MobilityBonus = Unit.GetUIStatFromInventory(eStat_Mobility, NewCheckGameState);
	TechBonus = Unit.GetUIStatFromInventory(eStat_Hacking, NewCheckGameState);
	ArmorBonus = Unit.GetUIStatFromInventory(eStat_ArmorMitigation, NewCheckGameState);
	DodgeBonus = Unit.GetUIStatFromInventory(eStat_Dodge, NewCheckGameState);

	if (Unit.IsPsiOperative())
	{
		Psi = string(int(Unit.GetCurrentStat(eStat_PsiOffense)) + Unit.GetUIStatFromAbilities(eStat_PsiOffense));
		PsiBonus = Unit.GetUIStatFromInventory(eStat_PsiOffense, NewCheckGameState);
	}

	if (WillBonus > 0)
		Will $= class'UIUtilities_Text'.static.GetColoredText("+"$WillBonus, eUIState_Good);
	else if (WillBonus < 0)
		Will $= class'UIUtilities_Text'.static.GetColoredText(""$WillBonus, eUIState_Bad);

	if (AimBonus > 0)
		Aim $= class'UIUtilities_Text'.static.GetColoredText("+"$AimBonus, eUIState_Good);
	else if (AimBonus < 0)
		Aim $= class'UIUtilities_Text'.static.GetColoredText(""$AimBonus, eUIState_Bad);

	if (HealthBonus > 0)
		Health $= class'UIUtilities_Text'.static.GetColoredText("+"$HealthBonus, eUIState_Good);
	else if (HealthBonus < 0)
		Health $= class'UIUtilities_Text'.static.GetColoredText(""$HealthBonus, eUIState_Bad);

	if (MobilityBonus > 0)
		Mobility $= class'UIUtilities_Text'.static.GetColoredText("+"$MobilityBonus, eUIState_Good);
	else if (MobilityBonus < 0)
		Mobility $= class'UIUtilities_Text'.static.GetColoredText(""$MobilityBonus, eUIState_Bad);

	if (TechBonus > 0)
		Tech $= class'UIUtilities_Text'.static.GetColoredText("+"$TechBonus, eUIState_Good);
	else if (TechBonus < 0)
		Tech $= class'UIUtilities_Text'.static.GetColoredText(""$TechBonus, eUIState_Bad);

	if (ArmorBonus > 0)
		Armor $= class'UIUtilities_Text'.static.GetColoredText("+"$ArmorBonus, eUIState_Good);
	else if (ArmorBonus < 0)
		Armor $= class'UIUtilities_Text'.static.GetColoredText(""$ArmorBonus, eUIState_Bad);

	if (DodgeBonus > 0)
		Dodge $= class'UIUtilities_Text'.static.GetColoredText("+"$DodgeBonus, eUIState_Good);
	else if (DodgeBonus < 0)
		Dodge $= class'UIUtilities_Text'.static.GetColoredText(""$DodgeBonus, eUIState_Bad);

	if (PsiBonus > 0)
		Psi $= class'UIUtilities_Text'.static.GetColoredText("+"$PsiBonus, eUIState_Good);
	else if (PsiBonus < 0)
		Psi $= class'UIUtilities_Text'.static.GetColoredText(""$PsiBonus, eUIState_Bad);

	mc.BeginFunctionOp("SetSoldierStats");
	
	if (Health != "")
	{
		mc.QueueString(class'UISoldierHeader'.default.m_strHealthLabel);
		mc.QueueString(Health);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	if (Mobility != "")
	{
		mc.QueueString(class'UISoldierHeader'.default.m_strMobilityLabel);
		mc.QueueString(Mobility);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	if (Aim != "")
	{
		mc.QueueString(class'UISoldierHeader'.default.m_strAimLabel);
		mc.QueueString(Aim);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}
	
	if (Will != "")
	{
		mc.QueueString(class'UISoldierHeader'.default.m_strWillLabel);
		mc.QueueString(Will);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	if (Armor != "")
	{
		mc.QueueString(class'UISoldierHeader'.default.m_strArmorLabel);
		mc.QueueString(Armor);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	if (Dodge != "")
	{
		mc.QueueString(class'UISoldierHeader'.default.m_strDodgeLabel);
		mc.QueueString(Dodge);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	if (Tech != "")
	{
		mc.QueueString(class'UISoldierHeader'.default.m_strTechLabel);
		mc.QueueString(Tech);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	if (Psi != "")
	{
		mc.QueueString(class'UIUtilities_Text'.static.GetColoredText(class'UISoldierHeader'.default.m_strPsiLabel, eUIState_Psyonic));
		mc.QueueString(class'UIUtilities_Text'.static.GetColoredText(Psi, eUIState_Psyonic));
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	mc.EndOp();

}

simulated function PopulateSoldierGear( XComGameState_Unit Unit, optional XComGameState NewCheckGameState)
{
	local XComGameState_Item equippedItem;
	local array<XComGameState_Item> utilItems;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<string> weaponImages;
	local int i;

	mc.BeginFunctionOp("SetSoldierGear");

	equippedItem = Unit.GetItemInSlot(eInvSlot_Armor, NewCheckGameState, true);
	mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strArmorLabel);//armor
	mc.QueueString(equippedItem.GetMyTemplate().strImage);
	mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());

	equippedItem = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon, NewCheckGameState, true);
	mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strPrimaryLabel);//primary
	mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());

	mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strSecondaryLabel);//secondary

	//we need to handle the reaper claymore
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Unit.GetSoldierClassTemplateName());
	if (SoldierClassTemplate.DataName == 'Reaper')
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('Reaper_Claymore'));
		mc.QueueString(EquipmentTemplate.strImage);
		mc.QueueString(EquipmentTemplate.GetItemFriendlyName());
	}
	else
	{

		equippedItem = Unit.GetItemInSlot(eInvSlot_SecondaryWeapon, NewCheckGameState, true);
		mc.QueueString(equippedItem.GetMyTemplate().strImage);
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());
	}

	utilItems = Unit.GetAllItemsInSlot(eInvSlot_Utility, NewCheckGameState, , true);
	mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strUtilLabel);//util 1
	mc.QueueString(utilItems[0].GetMyTemplate().strImage);
	mc.QueueString(utilItems[0].GetMyTemplate().GetItemFriendlyNameNoStats());
	mc.QueueString(utilItems[1].GetMyTemplate().strImage);// util 2 and 3
	mc.QueueString(utilItems[1].GetMyTemplate().GetItemFriendlyNameNoStats());

	equippedItem = Unit.GetItemInSlot(eInvSlot_GrenadePocket, NewCheckGameState, true);
	mc.QueueString(equippedItem.GetMyTemplate().strImage);
	mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());

	mc.EndOp();

	mc.BeginFunctionOp("SetSoldierPCS");
	equippedItem = Unit.GetItemInSlot(eInvSlot_CombatSim, NewCheckGameState, true);
	if (equippedItem != none)
	{
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyName(equippedItem.ObjectID));
		mc.QueueString(class'UIUtilities_Image'.static.GetPCSImage(equippedItem));
		mc.QueueString(class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
		mc.QueueString(class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR);
	}
	
	mc.EndOp();

	mc.BeginFunctionOp("SetPrimaryWeapon");
	equippedItem = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon, NewCheckGameState, true);
	weaponImages = equippedItem.GetWeaponPanelImages();

	for (i = 0; i < weaponImages.Length; i++)
	{
		mc.QueueString(weaponImages[i]);
	}

	mc.EndOp();
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{	
	// Only pay attention to presses or repeats; ignoring other input types
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch( cmd )
	{
		// Back out
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:	
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			CloseScreen();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER :
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT :
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT :
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT :
		case class'UIUtilities_Input'.const.FXS_KEY_D :
			NextSoldier();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER :
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT :
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT :
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT :
		case class'UIUtilities_Input'.const.FXS_KEY_A :
			PrevSoldier();
			break;
		default:
			break;
	}

	return true; // consume all input
}

simulated function CloseScreen()
{
	super.CloseScreen();
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function UINavigationHelp GetNavHelp()
{
	local UINavigationHelp Result;

	Result = PC.Pres.GetNavHelp();
	if (Result == None)
	{
		if (`PRES != none) // Tactical
		{
			Result = Spawn(class'UINavigationHelp', self).InitNavHelp();
		}
	}
	return Result;
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	m_CurrentIndex = 0;
	Package = "/ package/gfxTLE_SoldierInfo/TLE_SoldierInfo";
	LibID = "TLE_SoldierInfo";
	InputState = eInputState_Consume;
}
