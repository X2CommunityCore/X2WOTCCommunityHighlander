//--------------------------------------------------------------------------------------- 
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISoldierHeader
//  AUTHOR:  Sam Batista
//  PURPOSE: UIPanel that shows Unit information in Armory screens.
//--------------------------------------------------------------------------------------- 
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISoldierHeader extends UIPanel
	config(UI);

var localized string m_strStatusLabel;
var localized string m_strMissionsLabel;
var localized string m_strKillsLabel;

var localized string m_strWillLabel;
var localized string m_strAimLabel;
var localized string m_strHealthLabel;
var localized string m_strMobilityLabel;
var localized string m_strTechLabel;
var localized string m_strArmorLabel;
var localized string m_strDodgeLabel;
var localized string m_strPsiLabel;
var localized string m_strDateKilledLabel;
var localized string m_strPCSLabelOpen;
var localized string m_strPCSLabelLocked;
var localized string m_strCombatIntel;
var localized string m_strBondStatus;
var localized string m_strUnbondedLabel;
var localized string m_strCannotBondLabel;
var localized string m_strSoldierAP;
var localized string m_strSoldierAPNotUnlocked;
var localized string m_strTooltipBondMate;
var localized string m_strTooltipNoBond;
var localized string m_strTooltipCannotBond;
var localized string m_strTooltipCombatIntel;
var localized string m_strTooltipAP;
var localized string m_strTooltipAPNoTrainingCenter;
var localized string m_strTooltipAPHero;

var UIImage PsiMarkup;
var bool bSoldierStatsHidden;
var bool bHideFlag;
var bool bAlwaysHideXPackPanel;
var bool bShowsBondInfo;
var string strMPForceName;

var UIPanel XPanel;
var UIPanel BondMatePanel;
var UIPanel CombatIntelligencePanel;
var UIPanel APPanel;
var bool bShowXpackPanel;

var StateObjectReference UnitRef;
var XComGameState CheckGameState;

var config array<Name> EquipmentExcludedFromStatBoosts;

//----------------------------------------------------------------------------
// MEMBERS

simulated function UISoldierHeader InitSoldierHeader(optional StateObjectReference initUnitRef, optional XComGameState InitCheckGameState)
{
	InitPanel();

	UnitRef = initUnitRef;
	CheckGameState = InitCheckGameState;

	PsiMarkup = Spawn(class'UIImage', self).InitImage(, class'UIUtilities_Image'.const.PsiMarkupIcon);
	PsiMarkup.SetScale(0.7).SetPosition(-50, 10).Hide(); // starts off hidden until needed
	
	BuildSpecialTooltips();

	if(UnitRef.ObjectID > 0)
		PopulateData();
	else
		Hide();

	return self;
}

function BuildSpecialTooltips()
{
	local UITooltip Tooltip;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;

	XPanel = Spawn(class'UIPanel', self);
	XPanel.InitPanel('XpackPanel');

	BondMatePanel = Spawn(class'UIPanel', XPanel);
	BondMatePanel.InitPanel('bondMateMC');
	BondMatePanel.ProcessMouseEvents(OnChildMouseEvent);
	BondMatePanel.SetTooltipText(m_strTooltipNoBond, , , , , , , 0.0);
	Tooltip = Movie.Pres.m_kTooltipMgr.GetTooltipByID(BondMatePanel.CachedTooltipId);
	Tooltip.bUsePartialPath = true;

	CombatIntelligencePanel = Spawn(class'UIPanel', XPanel);
	CombatIntelligencePanel.InitPanel('combatIntelMC');
	CombatIntelligencePanel.ProcessMouseEvents(OnChildMouseEvent);
	CombatIntelligencePanel.SetTooltipText(m_strTooltipCombatIntel, , , , , , , 0.0);
	Tooltip = Movie.Pres.m_kTooltipMgr.GetTooltipByID(CombatIntelligencePanel.CachedTooltipId);
	Tooltip.bUsePartialPath = true;
	
	APPanel = Spawn(class'UIPanel', XPanel);
	APPanel.InitPanel('APPanel');
	APPanel.ProcessMouseEvents(OnChildMouseEvent);
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	if (Unit.IsResistanceHero())
	{
		APPanel.SetTooltipText(m_strTooltipAPHero, , , , , class'UIUtilities'.const.ANCHOR_TOP_RIGHT, , 0.0);
	}
	else
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
		if (XComHQ != None && XComHQ.HasFacilityByName('RecoveryCenter'))
		{
			APPanel.SetTooltipText(m_strTooltipAP, , , , , class'UIUtilities'.const.ANCHOR_TOP_RIGHT, , 0.0);
		}
		else
		{
			APPanel.SetTooltipText(m_strTooltipAPNoTrainingCenter, , , , , class'UIUtilities'.const.ANCHOR_TOP_RIGHT, , 0.0);
		}
	}
	Tooltip = Movie.Pres.m_kTooltipMgr.GetTooltipByID(APPanel.CachedTooltipId);
	Tooltip.bUsePartialPath = true;
}
simulated function OnChildMouseEvent(UIPanel Control, int cmd)
{
	local XComGameState_Unit Unit;
		
	if (Control == BondMatePanel)
	{
		switch (cmd)
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED :
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
			if (!Movie.Stack.HasInstanceOf(class'UIAfterAction') && Unit.GetSoldierClassTemplate().bCanHaveBonds)
			{
				// If the bond screen is accessed in the Armory from somewhere other than the main menu, pop down to it to avoid screen overlap
				Movie.Stack.PopUntilClass(class'UIArmory_MainMenu', false);
				
				`HQPRES.UISoldierBonds(UnitRef);
			}
			else
			{
				Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
			}
			break;
		}
	}

}

public function PositionTopLeft()
{
	SetPosition(855, 90);
}

public function PositionTopRight()
{
	SetPosition(1755, 90);
}

public function PopulateData(optional XComGameState_Unit Unit, optional StateObjectReference NewItem, optional StateObjectReference ReplacedItem, optional XComGameState NewCheckGameState)
{
	local int iRank, WillBonus, AimBonus, HealthBonus, MobilityBonus, TechBonus, PsiBonus, ArmorBonus, DodgeBonus;
	local string classIcon, rankIcon, flagIcon, Will, Aim, Health, Mobility, Tech, Psi, Armor, Dodge;
	local X2SoldierClassTemplate SoldierClass;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item TmpItem;
	local XComGameStateHistory History;
	local string StatusValue, StatusLabel, StatusDesc, StatusTimeLabel, StatusTimeValue, DaysValue;
	local XComGameState_ResistanceFaction FactionState;
	local bool bShouldShowWill;

	History = `XCOMHISTORY;
	CheckGameState = NewCheckGameState;

	if(Unit == none)
	{
		if(CheckGameState != none)
			Unit = XComGameState_Unit(CheckGameState.GetGameStateForObjectID(UnitRef.ObjectID));
		else
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
	}
	
	iRank = Unit.GetRank();

	SoldierClass = Unit.GetSoldierClassTemplate();

	FactionState = Unit.GetResistanceFaction();

	flagIcon  = (Unit.IsSoldier() && !bHideFlag) ? Unit.GetCountryTemplate().FlagImage : "";
	rankIcon  = Unit.IsSoldier() ? class'UIUtilities_Image'.static.GetRankIcon(iRank, Unit.GetSoldierClassTemplateName()) : Unit.GetMPCharacterTemplate().IconImage;
	classIcon = Unit.IsSoldier() ? SoldierClass.IconImage : Unit.GetMPCharacterTemplate().IconImage;

	if (classIcon == rankIcon)
		rankIcon = "";

	if (Unit.IsAlive())
	{
		StatusLabel = m_strStatusLabel;
		class'UIUtilities_Strategy'.static.GetPersonnelStatusSeparate(Unit, StatusDesc, StatusTimeLabel, StatusTimeValue, , true); 
		StatusValue = StatusDesc;
		DaysValue = StatusTimeValue @ StatusTimeLabel;
	}
	else
	{
		StatusLabel = m_strDateKilledLabel;
		StatusValue = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Unit.GetKIADate());
	}

	if(Unit.IsMPCharacter())
	{
		SetSoldierInfo( Caps(strMPForceName == "" ? Unit.GetName( eNameType_FullNick ) : strMPForceName),
							  StatusLabel, StatusValue,
							  class'XGBuildUI'.default.m_strLabelCost, 
							  string(Unit.GetUnitPointValue()),
							  "", "",
							  classIcon, Caps(SoldierClass != None ? SoldierClass.DisplayName : ""),
							  rankIcon, Caps(Unit.IsSoldier() ? `GET_RANK_STR(Unit.GetRank(), Unit.GetSoldierClassTemplateName()) : Unit.IsAlien() ? class'UIHackingScreen'.default.m_strAlienInfoTitle : class'UIHackingScreen'.default.m_strAdventInfoTitle),
							  flagIcon, false, DaysValue);
	}
	else
	{
		SetSoldierInfo( Caps(Unit.GetName( eNameType_FullNick )),
							  StatusLabel, StatusValue,
							  m_strMissionsLabel, string(Unit.GetNumMissions()),
							  m_strKillsLabel, string(Unit.GetNumKills()),
							  classIcon, Caps(SoldierClass != None ? SoldierClass.DisplayName : ""),
							  rankIcon, Caps(`GET_RANK_STR(Unit.GetRank(), Unit.GetSoldierClassTemplateName())),
							  flagIcon, (Unit.ShowPromoteIcon()), DaysValue);
	}

	SetFactionIcon(FactionState.GetFactionIcon());

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
	WillBonus = Unit.GetUIStatFromInventory(eStat_Will, CheckGameState);
	AimBonus = Unit.GetUIStatFromInventory(eStat_Offense, CheckGameState);
	HealthBonus = Unit.GetUIStatFromInventory(eStat_HP, CheckGameState);
	MobilityBonus = Unit.GetUIStatFromInventory(eStat_Mobility, CheckGameState);
	TechBonus = Unit.GetUIStatFromInventory(eStat_Hacking, CheckGameState);
	ArmorBonus = Unit.GetUIStatFromInventory(eStat_ArmorMitigation, CheckGameState);
	DodgeBonus = Unit.GetUIStatFromInventory(eStat_Dodge, CheckGameState);

	if(Unit.IsPsiOperative())
	{
		Psi = string(int(Unit.GetCurrentStat(eStat_PsiOffense)) + Unit.GetUIStatFromAbilities(eStat_PsiOffense));
		PsiBonus = Unit.GetUIStatFromInventory(eStat_PsiOffense, CheckGameState);
	}

	// Add bonus stats from an item that is about to be equipped
	if(NewItem.ObjectID > 0)
	{
		if(CheckGameState != None)
			TmpItem = XComGameState_Item(CheckGameState.GetGameStateForObjectID(NewItem.ObjectID));
		else
			TmpItem = XComGameState_Item(History.GetGameStateForObjectID(NewItem.ObjectID));
		EquipmentTemplate = X2EquipmentTemplate(TmpItem.GetMyTemplate());
		
		// Don't include sword boosts or any other equipment in the EquipmentExcludedFromStatBoosts array
		if (EquipmentTemplate != none && EquipmentExcludedFromStatBoosts.Find(EquipmentTemplate.DataName) == INDEX_NONE)
		{
			WillBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Will, TmpItem);
			AimBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Offense, TmpItem);
			HealthBonus += EquipmentTemplate.GetUIStatMarkup(eStat_HP, TmpItem);
			MobilityBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Mobility, TmpItem);
			TechBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Hacking, TmpItem);
			ArmorBonus += EquipmentTemplate.GetUIStatMarkup(eStat_ArmorMitigation, TmpItem);
			DodgeBonus += EquipmentTemplate.GetUIStatMarkup(eStat_Dodge, TmpItem);
		
			if(Unit.IsPsiOperative())
				PsiBonus += EquipmentTemplate.GetUIStatMarkup(eStat_PsiOffense, TmpItem);
		}
	}

	// Subtract stats from an item that is about to be replaced
	if(ReplacedItem.ObjectID > 0)
	{
		if(CheckGameState != None)
			TmpItem = XComGameState_Item(CheckGameState.GetGameStateForObjectID(ReplacedItem.ObjectID));
		else
			TmpItem = XComGameState_Item(History.GetGameStateForObjectID(ReplacedItem.ObjectID));
		EquipmentTemplate = X2EquipmentTemplate(TmpItem.GetMyTemplate());
		
		// Don't include sword boosts or any other equipment in the EquipmentExcludedFromStatBoosts array
		if (EquipmentTemplate != none && EquipmentExcludedFromStatBoosts.Find(EquipmentTemplate.DataName) == INDEX_NONE)
		{
			WillBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Will, TmpItem);
			AimBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Offense, TmpItem);
			HealthBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_HP, TmpItem);
			MobilityBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Mobility, TmpItem);
			TechBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Hacking, TmpItem);
			ArmorBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_ArmorMitigation, TmpItem);
			DodgeBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_Dodge, TmpItem);
		
			if(Unit.IsPsiOperative())
				PsiBonus -= EquipmentTemplate.GetUIStatMarkup(eStat_PsiOffense, TmpItem);
		}
	}

	if( WillBonus > 0 )
		 Will $= class'UIUtilities_Text'.static.GetColoredText("+"$WillBonus,	eUIState_Good);
	else if (WillBonus < 0)
		Will $= class'UIUtilities_Text'.static.GetColoredText(""$WillBonus,	eUIState_Bad);

	if( AimBonus > 0 )
		Aim $= class'UIUtilities_Text'.static.GetColoredText("+"$AimBonus, eUIState_Good);
	else if (AimBonus < 0)
		Aim $= class'UIUtilities_Text'.static.GetColoredText(""$AimBonus, eUIState_Bad);

	if( HealthBonus > 0 )
		Health $= class'UIUtilities_Text'.static.GetColoredText("+"$HealthBonus, eUIState_Good);
	else if (HealthBonus < 0)
		Health $= class'UIUtilities_Text'.static.GetColoredText(""$HealthBonus, eUIState_Bad);

	if( MobilityBonus > 0 )
		Mobility $= class'UIUtilities_Text'.static.GetColoredText("+"$MobilityBonus, eUIState_Good);
	else if (MobilityBonus < 0)
		Mobility $= class'UIUtilities_Text'.static.GetColoredText(""$MobilityBonus, eUIState_Bad);

	if( TechBonus > 0 )
		Tech $= class'UIUtilities_Text'.static.GetColoredText("+"$TechBonus, eUIState_Good);
	else if (TechBonus < 0)
		Tech $= class'UIUtilities_Text'.static.GetColoredText(""$TechBonus, eUIState_Bad);
	
	if( ArmorBonus > 0 )
		Armor $= class'UIUtilities_Text'.static.GetColoredText("+"$ArmorBonus, eUIState_Good);
	else if (ArmorBonus < 0)
		Armor $= class'UIUtilities_Text'.static.GetColoredText(""$ArmorBonus, eUIState_Bad);

	if( DodgeBonus > 0 )
		Dodge $= class'UIUtilities_Text'.static.GetColoredText("+"$DodgeBonus, eUIState_Good);
	else if (DodgeBonus < 0)
		Dodge $= class'UIUtilities_Text'.static.GetColoredText(""$DodgeBonus, eUIState_Bad);

	if( PsiBonus > 0 )
		Psi $= class'UIUtilities_Text'.static.GetColoredText("+"$PsiBonus, eUIState_Good);
	else if (PsiBonus < 0)
		Psi $= class'UIUtilities_Text'.static.GetColoredText(""$PsiBonus, eUIState_Bad);

	if(Unit.HasPsiGift())
		PsiMarkup.Show();
	else
		PsiMarkup.Hide();

	if(!bSoldierStatsHidden)
	{
		bShouldShowWill = Unit.UsesWillSystem();
		SetSoldierStats(Health, Mobility, Aim, Will, Armor, Dodge, Tech, Psi, bShouldShowWill);
		RefreshCombatSim(Unit);
	}

	// if the XPanel is currently visible then we need to update the data on it
	if( XPanel.bIsVisible )
	{
		ShowExtendedData(Unit);
	}
}
function HideExtendedData()
{
	XPanel.Hide();
}

function ShowExtendedData(optional XComGameState_Unit Unit)
{
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;
	local XComGameState_Unit Bondmate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local UITooltip Tooltip; 
	local string APString;
	local bool bInTutorial;

	bShowXpackPanel = false;
	bInTutorial = !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory');
	History = `XCOMHISTORY;

	if (Unit == none)
	{
		if (CheckGameState != none)
			Unit = XComGameState_Unit(CheckGameState.GetGameStateForObjectID(UnitRef.ObjectID));
		else
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
	}

	if (Unit == none || Unit.GetSoldierClassTemplate().bCanHaveBonds == false || bAlwaysHideXPackPanel || bInTutorial)
	{
		SetBondStatus(0, ""); //Hide the XPACK panel 
	}
	else
	{
		class'UIUtilities_Strategy'.static.NotifyAbilityListBondInfo(Screen, true);
		if (Unit.HasSoldierBond(BondmateRef, BondData))
		{
			Bondmate = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));
			SetBondStatus(BondData.BondLevel, Caps(Bondmate.GetName(eNameType_Full)));
			BondMatePanel.RemoveTooltip();
			BondMatePanel.SetTooltipText(m_strTooltipBondMate, , , , , , , 0.0);
		}
		else
		{
			if( Unit.GetSoldierClassTemplate().bCanHaveBonds )
			{
				SetBondStatus(0, m_strUnbondedLabel);
				BondMatePanel.RemoveTooltip();
				BondMatePanel.SetTooltipText(m_strTooltipNoBond, , , , , , , 0.0);
			}
			else
			{
				SetBondStatus(0, m_strCannotBondLabel);
				BondMatePanel.RemoveTooltip();
				BondMatePanel.SetTooltipText(m_strTooltipCannotBond, , , , , , , 0.0);
			}
		}

		Tooltip = Movie.Pres.m_kTooltipMgr.GetTooltipByID(BondMatePanel.CachedTooltipId);
		Tooltip.bUsePartialPath = true;
		BondMatePanel.Show();

		SetCombatIntel(Unit.GetCombatIntelligenceLabel());
			
		// Do not show AP value for base game soldiers until Training Center is constructed
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (Unit.IsResistanceHero() || XComHQ.HasFacilityByName('RecoveryCenter'))
		{
			APString = string(Unit.AbilityPoints);
		}
		else
		{
			APString = m_strSoldierAPNotUnlocked;
		}
		
		SetSoldierAP(APString);

		if( !Unit.UsesWillSystem() )
		{
			CombatIntelligencePanel.Hide();
			APPanel.Hide();
		}
		else
		{
			CombatIntelligencePanel.Show();
			APPanel.Show();
		}

		bShowXpackPanel = true;
	}
	XPanel.SetVisible(bShowXpackPanel);
}

function bool SetCombatIntel(string Label)
{
	mc.BeginFunctionOp("SetCombatIntel");

	mc.QueueString(m_strCombatIntel);
	mc.QueueString(Label);
	mc.EndOp();

	return (Label != "");
}
function bool SetBondStatus(int Level, string BondmateName)
{
	mc.BeginFunctionOp("SetBondStatus");

	mc.QueueNumber(Level);
	mc.QueueString(m_strBondStatus);
	mc.QueueString(BondmateName);
	mc.EndOp();

	bShowsBondInfo = (Level > 0);
	return bShowsBondInfo; 
}
function bool SetSoldierAP(string Label)
{
	mc.BeginFunctionOp("SetSoldierAP");

	mc.QueueString(m_strSoldierAP);
	mc.QueueString(Label);
	mc.EndOp();
	return (Label != "");
}

simulated function SetSoldierInfo( string unitName, 
								   string statusLabel, string status,
								   string missionsLabel, string missions,
								   string killsLabel, string kills,
								   string classIcon, string classLabel,
								   string rankIcon, string rankLabel,
								   string flagIcon, bool showPromoteIcon, string statusTime )
{
	mc.BeginFunctionOp("SetSoldierInformation");

	mc.QueueString(unitName);
	mc.QueueString(statusLabel);
	mc.QueueString(status);
	mc.QueueString(missionsLabel);
	mc.QueueString(missions);
	mc.QueueString(killsLabel);
	mc.QueueString(kills);
	mc.QueueString(classIcon);
	mc.QueueString(classLabel);
	mc.QueueString(rankIcon);
	mc.QueueString(rankLabel);
	mc.QueueString(flagIcon);
	mc.QueueBoolean(showPromoteIcon);
	mc.QueueString(statusTime);
	
	mc.EndOp();
}

public function SetSoldierStats(optional string Health	 = "", 
								optional string Mobility = "", 
								optional string Aim	     = "", 
								optional string Will     = "", 
								optional string Armor	 = "", 
								optional string Dodge	 = "", 
								optional string Tech	 = "", 
								optional string Psi		 = "",
								optional bool bShouldShowWill = true)
{
	//Stats will stack to the right, and clear out any unused stats 

	mc.BeginFunctionOp("SetSoldierStats");
	
	if( Health != "" )
	{
		mc.QueueString(m_strHealthLabel);
		mc.QueueString(Health);
	}
	if( Mobility != "" )
	{
		mc.QueueString(m_strMobilityLabel);
		mc.QueueString(Mobility);
	}
	if( Aim != "" )
	{
		mc.QueueString(m_strAimLabel);
		mc.QueueString(Aim);
	}
	if( !bShouldShowWill )
	{
		mc.QueueString("");
		mc.QueueString("");
	}
	else if( Will != "" )
	{
		mc.QueueString(m_strWillLabel);
		mc.QueueString(Will);
	}
	if( Armor != "" )
	{
		mc.QueueString(m_strArmorLabel);
		mc.QueueString(Armor);
	}
	if( Dodge != "" )
	{
		mc.QueueString(m_strDodgeLabel);
		mc.QueueString(Dodge);
	}
	if( Tech != "" )
	{
		mc.QueueString(m_strTechLabel);
		mc.QueueString(Tech);
	}
	if( Psi != "" )
	{
		mc.QueueString( class'UIUtilities_Text'.static.GetColoredText(m_strPsiLabel, eUIState_Psyonic) );
		mc.QueueString( class'UIUtilities_Text'.static.GetColoredText(Psi, eUIState_Psyonic) );
	}

	mc.EndOp();
}
public function HideSoldierStats()
{
	bSoldierStatsHidden = true;
	MC.FunctionVoid("HideSoldierStats");
}

public function RefreshCombatSim(XComGameState_Unit Unit)
{
	local string Label, IconPath, BorderColor;
	local int i, AvailableSlots;
	local XComGameState_Item ImplantItem;
	local array<XComGameState_Item> EquippedImplants;
	
	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
	AvailableSlots = Unit.GetCurrentStat(eStat_CombatSims);

	MC.BeginFunctionOp("SetSoldierCombatSim");
	for(i = 0; i < class'UIArmory_Implants'.default.MaxImplantSlots; ++i)
	{
		if(i < AvailableSlots && i < EquippedImplants.Length)
		{
			ImplantItem = EquippedImplants[i];
			Label = class'UIUtilities_Text'.static.GetColoredText(ImplantItem.GetMyTemplate().GetItemFriendlyName(ImplantItem.ObjectID), eUIState_Normal);
			IconPath = class'UIUtilities_Image'.static.GetPCSImage(ImplantItem);
			BorderColor = class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR;
		}
		else if(i < AvailableSlots)
		{
			Label = m_strPCSLabelOpen;
			BorderColor = class'UIUtilities_Colors'.const.GOOD_HTML_COLOR;
		}
		else
		{
			Label = m_strPCSLabelLocked;
			BorderColor = class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR;
		}

		MC.QueueString(Label);
		MC.QueueString(IconPath);
		MC.QueueString(BorderColor);
	}

	MC.EndOp();
}

public function SetFactionIcon(StackedUIIconData IconInfo)
{
	local int i;

	if (IconInfo.Images.Length > 0)
	{
		MC.BeginFunctionOp("SetFactionIcon");
		MC.QueueBoolean(IconInfo.bInvert);
		for (i = 0; i < IconInfo.Images.Length; i++)
		{
			MC.QueueString("img:///" $ Repl(IconInfo.Images[i], ".tga", "_sm.tga"));
		}

		MC.EndOp();
	}	
}
	
//==============================================================================

defaultproperties
{
	LibID = "SoldierHeader";
	MCName = "theSoldierHeader";
	bIsNavigable = false;
	bShowsBondInfo = false;
	bAlwaysHideXPackPanel = false;
	width = 584;
	height = 250;
}
