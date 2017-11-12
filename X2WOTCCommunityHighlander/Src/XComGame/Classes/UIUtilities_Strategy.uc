//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities_Strategy.uc
//  AUTHOR:  bsteiner
//  PURPOSE: Container of static helper functions.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities_Strategy extends Object
	dependson(UIDialogueBox);

struct TWeaponUpgradeAvailabilityData
{
	var bool bHasModularWeapons;
	var bool bHasWeaponUpgrades;
	var bool bHasWeaponUpgradeSlotsAvailable;
	var bool bCanWeaponBeUpgraded;
};

struct TPCSAvailabilityData
{
	var bool bHasGTS;
	var bool bHasAchievedCombatSimsRank;
	var bool bHasNeurochipImplantsInInventory;
	var bool bHasCombatSimsSlotsAvailable;
	var bool bCanEquipCombatSims;
};

var localized string m_strCreditsPrefix;
var localized string m_arrStaffTypes[EStaffType.EnumCount]<BoundEnum=EStaffType>;
var localized string m_strUnassignedPersonnelLocation;
var localized string m_strUnassignedSoldierLocation;
var localized string m_strOnMissionStatus;
var localized string m_strAvailableStatus;
var localized string m_strShakenStatus;
var localized string m_strWoundedStatus;
var localized string m_strBoostedStatus;
var localized string m_strRequiredLabel;

var localized string m_strResearching;

var localized string m_strReassignStaffTitle;
var localized string m_strReassignStaffBody;

var localized string m_strMissionType_AdventOp;
var localized string m_strMissionType_AlienBase;
var localized string m_strMissionType_Retaliation;
var localized string m_strMissionType_LandedUFO;
var localized string m_strMissionType_RemoteAlienFacility;
var localized string m_strMissionBuilding;
var localized string m_strNotEnoughResistance;

var localized String m_strOR;
var localized String m_strScienceSkill;
var localized String m_strEngineeringSkill;
var localized String m_strSoldierRank;
var localized String m_strSoldierClass;
var localized String m_strSoldierRankClassCombo;

var localized String m_strEngineeringDiscountLabel;

var localized String m_strFast;
var localized String m_strNormal;
var localized String m_strSlow;
var localized String m_strVerySlow;

var localized string m_strAbilityListTitle;
var localized string m_strTraitListTitle;

var localized string m_strEmptyStaff;
var localized string m_strStaffStatus[EStaffStatus.EnumCount]<BoundEnum=EStaffStatus>;

var localized string m_strObjectiveReqsNotMet;
var localized string m_strCompleteAllShadowProjects;

// mirrors callback type in UIDialogueBox, used for staff reassignment
delegate ActionCallback(Name eAction);
delegate static bool IsSoldierEligible(XComGameState_Unit Soldier);

static function bool IsInTutorial(optional bool AllowNULL)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local bool bInTutorial; 

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', AllowNULL));
	if( XComHQ != none )
		bInTutorial = XComHQ.AnyTutorialObjectivesInProgress();
	
	return bInTutorial;
}

static function XComGameState_GameTime GetGameTime(optional bool AllowNULL)
{
	local XComGameState_GameTime GameTime;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	GameTime = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime', AllowNULL));
	return GameTime;	
}

static function XComGameState_HeadquartersXCom GetXComHQ(optional bool AllowNULL)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', AllowNULL));
	return XComHQ;	
}

static function XComGameState_HeadquartersResistance GetResistanceHQ()
{
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	return ResistanceHQ;
}

static function XComGameState_HeadquartersAlien GetAlienHQ(optional bool AllowNULL)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien', AllowNULL));
	return AlienHQ;
}

static function XComGameState_BlackMarket GetBlackMarket()
{
	local XComGameState_BlackMarket BlackMarketState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	return BlackMarketState;
}

static function String GetStrategyCostString(StrategyCost StratCost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent)
{
	local int iResource, iArtifact, Quantity;
	local String strCost, strResourceCost, strArtifactCost;
	local StrategyCost ScaledStratCost;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetXComHQ();

	ScaledStratCost = XComHQ.GetScaledStrategyCost(StratCost, CostScalars, DiscountPercent);

	for (iArtifact = 0; iArtifact < ScaledStratCost.ArtifactCosts.Length; iArtifact++)
	{
		Quantity = ScaledStratCost.ArtifactCosts[iArtifact].Quantity;
		strArtifactCost = String(Quantity) @ GetResourceDisplayName(ScaledStratCost.ArtifactCosts[iArtifact].ItemTemplateName, Quantity);

		if (!XComHQ.CanAffordResourceCost(ScaledStratCost.ArtifactCosts[iArtifact].ItemTemplateName, ScaledStratCost.ArtifactCosts[iArtifact].Quantity))
		{
			strArtifactCost = class'UIUtilities_Text'.static.GetColoredText(strArtifactCost, eUIState_Bad);
		}
		else
			strArtifactCost = class'UIUtilities_Text'.static.GetColoredText(strArtifactCost, eUIState_Good);

		if (iArtifact < ScaledStratCost.ArtifactCosts.Length - 1)
		{
			strArtifactCost $= ",";
		}
		else if (ScaledStratCost.ResourceCosts.Length > 0)
		{
			strArtifactCost $= ",";
		}

		if (strCost == "")
		{
			strCost $= strArtifactCost; 
		}
		else
		{
			strCost @= strArtifactCost;
		}
	}

	for (iResource = 0; iResource < ScaledStratCost.ResourceCosts.Length; iResource++)
	{
		Quantity = ScaledStratCost.ResourceCosts[iResource].Quantity;
		strResourceCost = String(Quantity) @ GetResourceDisplayName(ScaledStratCost.ResourceCosts[iResource].ItemTemplateName, Quantity);

		if (!XComHQ.CanAffordResourceCost(ScaledStratCost.ResourceCosts[iResource].ItemTemplateName, ScaledStratCost.ResourceCosts[iResource].Quantity))
		{
			strResourceCost = class'UIUtilities_Text'.static.GetColoredText(strResourceCost, eUIState_Bad);
		}
		else
			strResourceCost = class'UIUtilities_Text'.static.GetColoredText(strResourceCost, eUIState_Good);

		if (iResource < ScaledStratCost.ResourceCosts.Length - 1)
		{
			strResourceCost $= ",";
		}

		if (strCost == "")
		{
			strCost $= strResourceCost;
		}
		else
		{
			strCost @= strResourceCost;
		}
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strCost);
}

static function String GetStrategyReqString(StrategyRequirement StratReq)
{
	local int iReq;
	local String strReqList, strReq;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetXComHQ();

	/*struct native StrategyRequirement
	{
		var array<Name>			RequiredTechs;
		var bool				bVisibleIfTechsNotMet;
		var array<Name>			RequiredItems;
		var array<Name>         AlternateRequiredItems;
		var bool				bVisibleIfItemsNotMet;
		var array<Name>			RequiredFacilities;
		var bool				bVisibleIfFacilitiesNotMet;
		var array<Name>			RequiredUpgrades;
		var bool				bVisibleIfUpgradesNotMet;
		var int					RequiredEngineeringScore;
		var int					RequiredScienceScore;
		var bool				bVisibleIfPersonnelGatesNotMet;
	};*/

	// Items
	for( iReq = 0; iReq < StratReq.RequiredItems.Length; iReq++ )
	{
		if( !XComHQ.HasItemByName(StratReq.RequiredItems[iReq]) )
		{
			if( strReqList != "" )
			{
				strReq = ", ";
			}
			strReq = strReq $ GetResourceDisplayName(StratReq.RequiredItems[iReq]);
		}
		strReqList = strReqList $ strReq;
	}

	strReqList = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strReqList);

	// Call the generic req string to fill in the rest
	return GetReqString(strReqList, StratReq);
}

static function String GetTechReqString(StrategyRequirement StratReq, StrategyCost StratCost)
{
	local int iReq, iArtifact;
	local String strReqList, strReq;
	local X2StrategyElementTemplateManager StratMgr;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2TechTemplate AvatarAutopsyTemplate, TechTemplate;
	local bool bIsCost, bOr, bIsFinalTech;

	XComHQ = GetXComHQ();
	bOr = false;
	bIsFinalTech = true;

	// Special check for Avatar autopsy
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	AvatarAutopsyTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('AutopsyAdventPsiWitch'));

	if(StratReq.RequiredTechs.Length == AvatarAutopsyTemplate.Requirements.RequiredTechs.Length)
	{
		for(iReq = 0; iReq < StratReq.RequiredTechs.Length; iReq++)
		{
			if(AvatarAutopsyTemplate.Requirements.RequiredTechs.Find(StratReq.RequiredTechs[iReq]) == INDEX_NONE)
			{
				bIsFinalTech = false;
				break;
			}
		}
	}
	else
	{
		bIsFinalTech = false;
	}
	
	for(iReq = 0; iReq < StratReq.RequiredTechs.Length; iReq++)
	{
		if(!XComHQ.IsTechResearched(StratReq.RequiredTechs[iReq]))
		{
			if (bIsFinalTech)
			{
				return default.m_strCompleteAllShadowProjects;
			}
			else
			{
				if (strReq != "")
				{
					strReq $= ", ";
				}

				TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate(StratReq.RequiredTechs[iReq]));
				strReq = strReq $ TechTemplate.DisplayName;
			}
		}
	}
	strReq = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strReq);

	// Items - do a special check for not displaying costs and resources twice
	for (iReq = 0; iReq < StratReq.RequiredItems.Length; iReq++)
	{
		strReq = "";
		if (!XComHQ.HasItemByName(StratReq.RequiredItems[iReq]))
		{
			bIsCost = false;
			for (iArtifact = 0; iArtifact < StratCost.ArtifactCosts.Length; iArtifact++)
			{
				if (StratCost.ArtifactCosts[iArtifact].ItemTemplateName == StratReq.RequiredItems[iReq])
				{
					bIsCost = true;
					break;
				}
			}

			if (!bIsCost)	// Don't display an artifact as both a cost and a requirement (even though that may be the functional truth)
			{
				if (strReq != "")
				{
					strReq = ", ";
				}
				strReq = strReq $ GetResourceDisplayName(StratReq.RequiredItems[iReq]);
			}
		}
	}

	strReq = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strReq);
	if (strReq != "") // Only display alternate required items if the original required item was not found
	{
		for (iReq = 0; iReq < StratReq.AlternateRequiredItems.Length; iReq++)
		{
			if (!XComHQ.HasItemByName(StratReq.AlternateRequiredItems[iReq]))
			{
				bIsCost = false;
				for (iArtifact = 0; iArtifact < StratCost.ArtifactCosts.Length; iArtifact++)
				{
					if (StratCost.ArtifactCosts[iArtifact].ItemTemplateName == StratReq.RequiredItems[iReq])
					{
						bIsCost = true;
						break;
					}
				}

				if (!bIsCost)	// Don't display an artifact as both a cost and a requirement (even though that may be the functional truth)
				{
					if (!bOr)
					{
						strReq = " " $ default.m_strOR $ " ";
						bOr = true;
					}
					else
					{
						strReq = ", ";
					}
					strReq = strReq $ GetResourceDisplayName(StratReq.AlternateRequiredItems[iReq]);
				}				
			}
			else // If any of the alternate req items are in the inventory, the req is fulfilled and should not be displayed
			{
				strReq = "";
				break;
			}
		}
	}
	
	strReqList = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strReqList $ strReq);

	// Then call the generic req string to fill in the rest
	return GetReqString(strReqList, StratReq);
}

static function String GetReqString(String strReqList, StrategyRequirement StratReq)
{
	local String strReq;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2SoldierClassTemplateManager TemplateManager;
	local X2SoldierClassTemplate ReqClassTemplate;

	XComHQ = GetXComHQ();

	if (StratReq.RequiredScienceScore > 0 && !XComHQ.MeetsScienceGates(StratReq.RequiredScienceScore))
	{
		if (strReqList != "")
		{
			strReqList = strReqList $ ", ";
		}

		strReq = default.m_strScienceSkill @ ((StratReq.RequiredScienceScore / 5) - 1);
		strReqList = strReqList $ strReq;
	}

	if (StratReq.RequiredEngineeringScore > 0 && !XComHQ.MeetsEngineeringGates(StratReq.RequiredEngineeringScore))
	{
		if (strReqList != "")
		{
			strReqList = strReqList $ ", ";
		}

		strReq = default.m_strEngineeringSkill @ ((StratReq.RequiredEngineeringScore / 5) - 1);
		strReqList = strReqList $ strReq;
	}

	if (StratReq.RequiredSoldierRankClassCombo && !XComHQ.MeetsSoldierGates(StratReq.RequiredHighestSoldierRank, StratReq.RequiredSoldierClass, StratReq.RequiredSoldierRankClassCombo))
	{
		if (strReqList != "")
		{
			strReqList = strReqList $ ", ";
		}
		TemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		ReqClassTemplate = TemplateManager.FindSoldierClassTemplate(StratReq.RequiredSoldierClass);

		strReq = default.m_strSoldierRankClassCombo @ ReqClassTemplate.DisplayName @ `GET_RANK_STR(StratReq.RequiredHighestSoldierRank, StratReq.RequiredSoldierClass);
		strReqList = strReqList $ strReq;
	}
	else
	{
		if (StratReq.RequiredHighestSoldierRank > 0 && !XComHQ.MeetsSoldierRankGates(StratReq.RequiredHighestSoldierRank))
		{
			if (strReqList != "")
			{
				strReqList = strReqList $ ", ";
			}

			strReq = default.m_strSoldierRank @ `GET_RANK_STR(StratReq.RequiredHighestSoldierRank, '');
			strReqList = strReqList $ strReq;
		}

		if (StratReq.RequiredSoldierClass != '' && !XComHQ.MeetsSoldierClassGates(StratReq.RequiredSoldierClass))
		{
			if (strReqList != "")
			{
				strReqList = strReqList $ ", ";
			}
		
			TemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
			ReqClassTemplate = TemplateManager.FindSoldierClassTemplate(StratReq.RequiredSoldierClass);

			strReq = default.m_strSoldierClass @ ReqClassTemplate.DisplayName;
			strReqList = strReqList $ strReq;
		}
	}

	// Objective Requirements override everything
	if (StratReq.RequiredObjectives.Length > 0)
	{
		if (!XComHQ.MeetsObjectiveRequirements(StratReq.RequiredObjectives))
		{
			strReqList = default.m_strObjectiveReqsNotMet;
		}
	}

	strReqList = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strReqList);
	return strReqList;
}

static function int GetCostQuantity(StrategyCost StratCost, Name ResourceName)
{
	local int iResource, iArtifact;
	
	for (iArtifact = 0; iArtifact < StratCost.ArtifactCosts.Length; iArtifact++)
	{
		if (StratCost.ArtifactCosts[iArtifact].ItemTemplateName == ResourceName)
		{
			return StratCost.ArtifactCosts[iArtifact].Quantity;
		}
	}
	
	for (iResource = 0; iResource < StratCost.ResourceCosts.Length; iResource++)
	{
		if (StratCost.ResourceCosts[iResource].ItemTemplateName == ResourceName)
		{
			return StratCost.ResourceCosts[iResource].Quantity;
		}
	}

	return -1;
}

static function String GetResearchProgressString(EResearchProgress eProgress)
{
	switch( eProgress )
	{
	case eResearchProgress_Fast:
		return default.m_strFast;
	case eResearchProgress_Normal:
		return default.m_strNormal;
	case eResearchProgress_Slow:
		return default.m_strSlow;
	case eResearchProgress_VerySlow:
		return default.m_strVerySlow;
	default:
		return "";
		break;
	}
}

static function EUIState GetResearchProgressColor(EResearchProgress eProgress)
{
	switch( eProgress )
	{
	case eResearchProgress_Fast:
		return eUIState_Good;
	case eResearchProgress_Normal:
		return eUIState_Warning;
	case eResearchProgress_Slow:
		return eUIState_Bad;
	case eResearchProgress_VerySlow:
		return eUIState_Bad;
	default:
		return eUIState_Disabled;
		break;
	}
}

static function float GetEngineeringDiscount(int iItemReqEngScore)
{
	local float fEngBonus, fEngScore;

	fEngScore = GetXComHQ().GetEngineeringScore(true);

	// If the requirement is higher than the current score, there is no discount
	if (iItemReqEngScore >= fEngScore)
	{
		return 0.0;
	}
	
	// First check if the item has a required eng score
	if (iItemReqEngScore > 0)
	{
		fEngBonus = fEngScore / iItemReqEngScore;
	}
	else
	{
		fEngBonus = fEngScore / 5.0; // 5 is the base starting Eng Score for all items with no specific eng requirement
	}

	// The farther the eng score is above the requirement, the higher the bonus. Eng score at 2X the requirement gives 25% off, 3X the requirement gives 50% off.
	fEngBonus = min(((fEngBonus - 1) / 2.0) * 50.0, 50.0); // Maximum discount bonus is 50
	
	// Design change to give no discount bonus
	return 0.0;
}

static function String GetEngineeringDiscountString(int iItemReqEngScore)
{
	local String strEngBonus;
	local float iEngBonus;

	iEngBonus = GetEngineeringDiscount(iItemReqEngScore);

	if (iEngBonus > 0)
	{
		strEngBonus = default.m_strEngineeringDiscountLabel;
		strEngBonus = Repl(strEngBonus, "%BONUS", string(int(iEngBonus)));
		strEngBonus = class'UIUtilities_Text'.static.GetColoredText(strEngBonus, eUIState_Good);
		strEngBonus = class'UIUtilities_Text'.static.GetSizedText(strEngBonus, 20);
	}

	return strEngBonus;
}

static function String GetResourceDisplayName(name ResourceName, int Quantity = 1)
{
	local X2ItemTemplateManager ItemMgr;
	local X2ItemTemplate ItemTemplate;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemMgr.FindItemTemplate(ResourceName);

	if(ItemTemplate != none)
	{
		if( Quantity == 1 )
		{
			return ItemTemplate.GetItemFriendlyName();
		}
		else
		{
			return ItemTemplate.GetItemFriendlyNamePlural();
		}
	}

	return "";
}

static function int GetResource(name ResourceName)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetXComHQ();

	switch(ResourceName)
	{
	case 'Supplies':
		return XComHQ.GetSupplies();
	case 'Intel':
		return XComHQ.GetIntel();
	case 'AlienAlloy':
		return XComHQ.GetAlienAlloys();
	case 'EleriumDust':
		return XComHQ.GetEleriumDust();
	case 'EleriumCore':
		return XComHQ.GetEleriumCores();
	}

	return 0;
}

static function bool DisplayLocation( XComGameState_Unit Unit )
{
	// always display location for soldiers
	if(Unit.IsSoldier())
		return true;

	if (Unit.StaffingSlot.ObjectID != 0)
		return true;

	return false;
}

static function string GetPersonnelLocation( XComGameState_Unit Unit, optional int FontSize = -1 )
{
	local XComGameState_StaffSlot StaffSlot;
	
	if (Unit.StaffingSlot.ObjectID != 0)
	{
		StaffSlot = XComGameState_StaffSlot(`XCOMHistory.GetGameStateForObjectID(Unit.StaffingSlot.ObjectID));
		return class'UIUtilities_Text'.static.GetSizedText(StaffSlot.GetLocationDisplayString(), FontSize);
	}
	
	// no location found
	if(Unit.IsSoldier())
		return class'UIUtilities_Text'.static.GetSizedText(default.m_strUnassignedSoldierLocation, FontSize);
	else
		return class'UIUtilities_Text'.static.GetSizedText(default.m_strUnassignedPersonnelLocation, FontSize);
}

static function string GetPersonnelStatus( XComGameState_Unit Unit, optional int FontSize = -1 )
{
	local string ShakenStr;

	if (Unit.IsScientist() || Unit.IsEngineer())
	{
		if (Unit.IsInjured())
		{
			return class'UIUtilities_Text'.static.GetColoredText(Unit.GetStatusString(), eUIState_Bad, FontSize);
		}
		else if (Unit.IsOnCovertAction())
		{
			return class'UIUtilities_Text'.static.GetColoredText(Unit.GetStatusString(), eUIState_Warning, FontSize);
		}

		return class'UIUtilities_Text'.static.GetSizedText(Unit.GetLocation(), FontSize);
	}
	else if (Unit.IsSoldier())
	{
		// soldiers get put into the hangar to indicate they are getting ready to go on a mission
		if (`HQPRES.ScreenStack.IsInStack(class'UISquadSelect') && GetXComHQ().IsUnitInSquad(Unit.GetReference()))
			return class'UIUtilities_Text'.static.GetColoredText(default.m_strOnMissionStatus, eUIState_Highlight, FontSize);
		else if (Unit.bRecoveryBoosted)
			return class'UIUtilities_Text'.static.GetColoredText(default.m_strBoostedStatus, eUIState_Warning, FontSize);
		else if (Unit.IsInjured() || Unit.IsDead())
			return class'UIUtilities_Text'.static.GetColoredText(Unit.GetStatusString(), eUIState_Bad, FontSize);
		else if (Unit.IsPsiTraining()  || Unit.IsPsiAbilityTraining())
			return class'UIUtilities_Text'.static.GetColoredText(Unit.GetStatusString(), eUIState_Psyonic, FontSize);
		else if (Unit.IsTraining() || Unit.IsOnCovertAction())
			return class'UIUtilities_Text'.static.GetColoredText(Unit.GetStatusString(), eUIState_Warning, FontSize);
		else if (Unit.bIsShaken) 
		{
			ShakenStr = class'UIUtilities_Text'.static.GetColoredText(default.m_strShakenStatus, eUIState_Bad, FontSize);
			return class'UIUtilities_Text'.static.GetColoredText(default.m_strAvailableStatus @ ShakenStr, eUIState_Good, FontSize);
		}
		else
			return class'UIUtilities_Text'.static.GetColoredText(default.m_strAvailableStatus, eUIState_Good, FontSize);
	}

	return "MISSING DATA";
}

static function GetPersonnelStatusSeparate(XComGameState_Unit Unit, out string Status, out string TimeLabel, out string TimeValue, optional int FontSize = -1, optional bool bIncludeMentalState = false)
{
	local EUIState eState; 
	local int TimeNum;
	local bool bHideZeroDays;

	bHideZeroDays = true;

	if(Unit.IsMPCharacter())
	{
		Status = default.m_strAvailableStatus;
		eState = eUIState_Good;
		TimeNum = 0;
		Status = class'UIUtilities_Text'.static.GetColoredText(Status, eState, FontSize);
		return;
	}

	// template names are set in X2Character_DefaultCharacters.uc
	if (Unit.IsScientist() || Unit.IsEngineer())
	{
		Status = class'UIUtilities_Text'.static.GetSizedText(Unit.GetLocation(), FontSize);
	}
	else if (Unit.IsSoldier())
	{
		// soldiers get put into the hangar to indicate they are getting ready to go on a mission
		if(`HQPRES != none &&  `HQPRES.ScreenStack.IsInStack(class'UISquadSelect') && GetXComHQ().IsUnitInSquad(Unit.GetReference()) )
		{
			Status = default.m_strOnMissionStatus;
			eState = eUIState_Highlight;
		}
		else if (Unit.bRecoveryBoosted)
		{
			Status = default.m_strBoostedStatus;
			eState = eUIState_Warning;
		}
		else if( Unit.IsInjured() || Unit.IsDead() )
		{
			Unit.GetStatusStringsSeparate(Status, TimeLabel, TimeNum);
			eState = eUIState_Bad;
		}
		else if(Unit.GetMentalState() == eMentalState_Shaken)
		{
			Unit.GetMentalStateStringsSeparate(Status, TimeLabel, TimeNum);
			eState = Unit.GetMentalStateUIState();
		}
		else if( Unit.IsPsiTraining() || Unit.IsPsiAbilityTraining() )
		{
			Unit.GetStatusStringsSeparate(Status, TimeLabel, TimeNum);
			eState = eUIState_Psyonic;
		}
		else if( Unit.IsTraining() )
		{
			Unit.GetStatusStringsSeparate(Status, TimeLabel, TimeNum);
			eState = eUIState_Warning;
		}
		else if(  Unit.IsOnCovertAction() )
		{
			Unit.GetStatusStringsSeparate(Status, TimeLabel, TimeNum);
			eState = eUIState_Warning;
			bHideZeroDays = false;
		}
		else if(bIncludeMentalState && Unit.BelowReadyWillState())
		{
			Unit.GetMentalStateStringsSeparate(Status, TimeLabel, TimeNum);
			eState = Unit.GetMentalStateUIState();
		}
		else
		{
			Status = default.m_strAvailableStatus;
			eState = eUIState_Good;
			TimeNum = 0;
		}
	}

	Status = class'UIUtilities_Text'.static.GetColoredText(Status, eState, FontSize);
	TimeLabel = class'UIUtilities_Text'.static.GetColoredText(TimeLabel, eState, FontSize);
	if( TimeNum == 0 && bHideZeroDays )
		TimeValue = "";
	else
		TimeValue = class'UIUtilities_Text'.static.GetColoredText(string(TimeNum), eState, FontSize);

	//Do this after the initial status coloring, since Shaken is colored separately.  
	//if( Unit.bIsShaken )
	//{
	//	Status = class'UIUtilities_Text'.static.GetColoredText(default.m_strShakenStatus, eUIState_Bad, FontSize) @ Status; 
	//}
}

simulated static function array<XComGameState_Item> GetEquippedUtilityItems(XComGameState_Unit Unit, optional XComGameState CheckGameState)
{
	return GetEquippedItemsInSlot(Unit, eInvSlot_Utility, CheckGameState);
}

simulated static function array<XComGameState_Item> GetEquippedItemsInSlot(XComGameState_Unit Unit, EInventorySlot SlotType, optional XComGameState CheckGameState)
{
	local StateObjectReference ItemRef;
	local XComGameState_Item ItemState;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<XComGameState_Item> arrItems;

	foreach Unit.InventoryItems(ItemRef)
	{
		ItemState = Unit.GetItemGameState(ItemRef, CheckGameState);
		EquipmentTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());

		// xpad is only item with size 0, that is always equipped
		if (ItemState.GetItemSize() > 0 && (ItemState.InventorySlot == SlotType || (EquipmentTemplate != None && EquipmentTemplate.InventorySlot == SlotType)))
		{
			// Ignore any items in the grenade pocket when checking for utility items, since otherwise grenades get added as utility items
			if (SlotType == eInvSlot_Utility)
			{
				if (ItemState.InventorySlot != eInvSlot_GrenadePocket
					// Start Issue #99 -- add ammo pocket
					&& ItemState.InventorySlot != eInvSlot_AmmoPocket
					// End Issue #99
					)
					arrItems.AddItem(ItemState);
			}
			else
				arrItems.AddItem(ItemState);
		}
	}
	
	return arrItems;
}

static function bool CanReassignStaff(StaffUnitInfo UnitInfo, string NewLocation, delegate<ActionCallback> ReassignConfirmedCallback)
{
	if(IsUnitBusy(UnitInfo))
	{
		ConfirmReassignStaff(UnitInfo, NewLocation, ReassignConfirmedCallback);
		return false;
	}
	else
	{
		return true;
	}
}

// Is unit busy in the strategy layer
static function bool IsUnitBusy(StaffUnitInfo UnitInfo)
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot StaffSlotState;

	History = `XCOMHISTORY;

	if (UnitInfo.bGhostUnit)
	{
		StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(UnitInfo.GhostLocation.ObjectID));
	}
	else
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
		StaffSlotState = Unit.GetStaffSlot();
	}

	if (StaffSlotState != none)
	{
		return StaffSlotState.IsStaffSlotBusy();
	}

	return false;
}

static function ConfirmReassignStaff(StaffUnitInfo UnitInfo, string NewLocation, delegate<ActionCallback> ReassignConfirmedCallback)
{
	local XGParamTag kTag;
	local TDialogueBoxData kDialogData;
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot StaffSlot;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (UnitInfo.bGhostUnit)
	{
		StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.GhostLocation.ObjectID));

		kTag.StrValue0 = Repl(Unit.GetStaffSlot().GetMyTemplate().GhostName, "%UNITNAME", Unit.GetFullName());
		kTag.StrValue1 = class'UIUtilities_Text'.static.GetSizedText(StaffSlot.GetLocationDisplayString(), -1);
	}
	else
	{
		kTag.StrValue0 = Unit.GetName(eNameType_Full);

		// if personnel is not staffed, show status instead of location
		if (class'UIUtilities_Strategy'.static.DisplayLocation(Unit))
			kTag.StrValue1 = class'UIUtilities_Strategy'.static.GetPersonnelLocation(Unit);
		else
			kTag.StrValue1 = class'UIUtilities_Strategy'.static.GetPersonnelStatus(Unit);
	}

	kTag.StrValue2 = NewLocation;

	// Warn before deleting save
	kDialogData.eType     = eDialog_Alert;
	kDialogData.strTitle  = default.m_strReassignStaffTitle;
	kDialogData.strText   = `XEXPAND.ExpandString(default.m_strReassignStaffBody);
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;

	kDialogData.fnCallback  = ReassignConfirmedCallback;
	`HQPRES.UIRaiseDialog( kDialogData );
}

static function SelectRoom(StateObjectReference RoomRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersRoom Room;
	local bool bInstantInterp;
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local XComSoundManager SoundMgr;
	local name RoomEnteredEventName;

	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomRef.ObjectID));
	bInstantInterp = false;

	if (Room != none)
	{
		SoundMgr = `XSTRATEGYSOUNDMGR;
		SoundMgr.PlaySoundEvent("Stop_AvengerAmbience");

		if( Room.UnderConstruction || Room.ClearingRoom )
		{
			SoundMgr.PlaySoundEvent("Play_AvengerRoomConstruction");
		}
		else
		{
			SpecialFeature = Room.GetSpecialFeature();

			if( SpecialFeature != None )
			{
				SoundMgr.PlaySoundEvent(SpecialFeature.RoomAmbientAkEvent);

				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entered Room");
				RoomEnteredEventName = Name("OnEnteredRoom_" $ SpecialFeature.DataName);
				`XEVENTMGR.TriggerEvent(RoomEnteredEventName, Room, Room, NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
		
		if (`HQPRES.ScreenStack.IsInStack(class'UIStrategyMap'))
		{
			`HQPRES.ClearUIToHUD();
			bInstantInterp = true;
		}

		`HQPRES.UIRoom(RoomRef, bInstantInterp);
	}
}

static function SelectFacility(StateObjectReference FacilityRef, optional bool bForceInstant = false)
{
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersRoom Room;
	local StateObjectReference RoomRef; 
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;

	History = `XCOMHISTORY;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectBuildFacility', FacilityProject)
	{
		if( FacilityProject.ProjectFocus.ObjectID == Facility.ObjectID )
		{
			RoomRef = FacilityProject.AuxilaryReference;
			Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomRef.ObjectID));
			continue;
		}
	}

	if( Facility != none && Facility.GetMyTemplate() != none )
	{
		if( Room != none && (Room.ClearingRoom || Room.UnderConstruction) )
		{
			class'UIUtilities_Strategy'.static.SelectRoom(RoomRef);
		}
		else if( !Facility.IsUnderConstruction() && Facility.GetMyTemplate().SelectFacilityFn != None )
		{
			Facility.GetMyTemplate().SelectFacilityFn(FacilityRef, bForceInstant);
		}
	}
}

static function OnPersonnelSelected(StateObjectReference selectedUnitRef)
{
	`HQPRES.UIArmory_MainMenu(selectedUnitRef);
}

static function XComGameState_HeadquartersProjectUpgradeFacility GetUpgradeProject(StateObjectReference FacilityRef)
{
	local int i;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;

	if(FacilityRef.ObjectID > 0)
	{
		XComHQ = static.GetXComHQ();
		for(i = 0; i < XComHQ.Projects.Length; ++i)
		{
			UpgradeProject = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Projects[i].ObjectID));
			if(UpgradeProject != None && UpgradeProject.AuxilaryReference == FacilityRef)
				return UpgradeProject;
		}
	}
	return none;
}

simulated static function StatBoost GetStatBoost(XComGameState_Item Item)
{
	local int i;
	local StatBoost NoBoost;

	for(i = 0; i < Item.StatBoosts.Length; ++i)
	{
		if(Item.StatBoosts[i].Boost > 0)
		{
			return Item.StatBoosts[i];
		}
	}

	return NoBoost;
}

simulated static function X2SoldierClassTemplate GetAllowedClassForWeapon(X2WeaponTemplate WeaponTemplate)
{
	local X2DataTemplate DataTemplate;
	local X2SoldierClassTemplate SoldierClassTemplate;
	
	foreach class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().IterateTemplates(DataTemplate, none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(DataTemplate);
		if(SoldierClassTemplate.IsWeaponAllowedByClass(WeaponTemplate))
			return SoldierClassTemplate;
	}
}

simulated static function X2SoldierClassTemplate GetAllowedClassForArmor(X2ArmorTemplate ArmorTemplate)
{
	local X2DataTemplate DataTemplate;
	local X2SoldierClassTemplate SoldierClassTemplate;

	foreach class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().IterateTemplates(DataTemplate, none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(DataTemplate);
		if (SoldierClassTemplate.IsArmorAllowedByClass(ArmorTemplate))
			return SoldierClassTemplate;
	}
}

// Used for Popular Support and Alert meters in UIStrategyMap and UIStrategyMapItem_LandingPin
simulated static function array<int> GetMeterBlockTypes(int NumBlocks, int NumFilled, int NumPreview, array<int> ThresholdIndicies)
{
	local int i, ThresholdIndex;
	local array<int> BlockTypes;

	for(i = 0; i <= NumBlocks; ++i)
	{
		if(ThresholdIndicies[ThresholdIndex] == i)
		{
			ThresholdIndex++;
			BlockTypes.AddItem(-1); // -1 == threshold block

			// include the last threshold
			if(i < NumBlocks) i--;
		}
		else if(NumPreview > 0 && i >= NumFilled && (i - NumFilled) < NumPreview)
			BlockTypes.AddItem(2); // 2 == preview block
		else
			BlockTypes.AddItem(i < NumFilled ? 1 : 0); // 1 == filled block, 0 == empty block
	}

	return BlockTypes;
}

// If StaffSlotRef is invalid, we must loop through all PsiChamber slots and pick the best one
//simulated static function TrainPsiOperative(StateObjectReference UnitRef, optional StateObjectReference StaffSlotRef)
//{
//	local StateObjectReference EmptyRef;
//	local XComGameState NewGameState;
//	local XComGameState_StaffSlot StaffSlot;
//	local XComGameStateHistory History;
//	local XComGameState_HeadquartersXCom XComHQ;
//	local StaffUnitInfo UnitInfo;
//
//	History = `XCOMHISTORY;
//	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
//
//	if (StaffSlotRef == EmptyRef)
//	{
//		// If the StaffSlotRef provided is empty, get the best slot
//		StaffSlotRef = GetBestValidPsiLabSlot();
//	}
//
//	// If an available training slot is provided or has been found
//	StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID));
//
//	if (StaffSlot != none)
//	{
//		UnitInfo.UnitRef = UnitRef;
//
//		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Psi Training Slot");
//		StaffSlot.FillSlot(NewGameState, UnitInfo, true);
//		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
//
//		XComHQ.HandlePowerOrStaffingChange();
//	}		
//}
//
//simulated static function bool CanTrainPsiOperative(StateObjectReference UnitRef)
//{
//	local XComGameStateHistory History;
//	local XComGameState_FacilityXCom FacilityState;
//	local XComGameState_StaffSlot StaffSlot;
//	local array<XComGameState_FacilityXCom> PsiLabs;
//	local int i, j;
//
//	History = `XCOMHISTORY;
//
//	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
//	{
//		if(FacilityState.GetMyTemplateName() == 'PsiChamber')
//		{
//			PsiLabs.AddItem(FacilityState);
//		}
//	}
//
//	for(i = 0; i < PsiLabs.Length; i++)
//	{
//		for(j = 0; j < PsiLabs[i].StaffSlots.Length; j++)
//		{
//			StaffSlot = PsiLabs[i].GetStaffSlot(j);
//			if (StaffSlot.IsSoldierSlot() && !StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty())
//			{
//				return true;
//			}
//		}
//	}
//
//	return false;
//}
//
//static function StateObjectReference GetBestValidPsiLabSlot()
//{
//	local XComGameStateHistory History;
//	local XComGameState_FacilityXCom FacilityState;
//	local XComGameState_Unit UnitState;
//	local XComGameState_StaffSlot StaffSlot;
//	local array<XComGameState_FacilityXCom> PsiLabs, ValidPsiLabs;
//	local StateObjectReference SlotRef;
//	local int i, j, MaxSkill, FacilityIndex;
//
//	History = `XCOMHISTORY;
//	MaxSkill = 0;
//	FacilityIndex = 0;
//
//	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
//	{
//		if(FacilityState.GetMyTemplateName() == 'PsiChamber')
//		{
//			PsiLabs.AddItem(FacilityState);
//		}
//	}
//
//	// Get Psi Labs with available soldier slot
//	for(i = 0; i < PsiLabs.Length; i++)
//	{
//		for(j = 0; j < PsiLabs[i].StaffSlots.Length; j++)
//		{
//			StaffSlot = PsiLabs[i].GetStaffSlot(j);
//			if (StaffSlot.IsSoldierSlot() && StaffSlot.IsSlotEmpty())
//			{
//				ValidPsiLabs.AddItem(PsiLabs[i]);
//			}
//		}
//	}
//
//	if(ValidPsiLabs.Length > 0)
//	{
//		// Find Highest rated scientist in psi lab staffing slot
//		for(i = 0; i < ValidPsiLabs.Length; i++)
//		{
//			for(j = 0; j < ValidPsiLabs[i].StaffSlots.Length; j++)
//			{
//				StaffSlot = ValidPsiLabs[i].GetStaffSlot(j);
//				if (StaffSlot.IsScientistSlot() && StaffSlot.IsSlotFilled())
//				{
//					UnitState = StaffSlot.GetAssignedStaff();
//
//					if(UnitState != none && UnitState.GetSkillLevel() > MaxSkill)
//					{
//						MaxSkill = UnitState.GetSkillLevel();
//						FacilityIndex = i;
//					}
//				}
//			}
//		}
//
//		// Grab valid slot reference in Psi Lab with highest rated scientist
//		for(j = 0; j < ValidPsiLabs[FacilityIndex].StaffSlots.Length; j++)
//		{
//			StaffSlot = ValidPsiLabs[FacilityIndex].GetStaffSlot(j);
//			if (StaffSlot.IsSoldierSlot() && !StaffSlot.IsLocked() && StaffSlot.IsSlotEmpty())
//			{
//				SlotRef = StaffSlot.GetReference();
//				break;
//			}
//		}	
//	}
//
//	return SlotRef;
//}

//---------------------------------------------------------------------------------------
simulated static function XComGameState_Continent GetRandomContinent(optional StateObjectReference ContinentRef)
{
	local XComGameStateHistory History;
	local array<XComGameState_Continent> Continents;
	local XComGameState_Continent ContinentState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Continent', ContinentState)
	{
		Continents.AddItem(ContinentState);
	}

	do
	{
		ContinentState = Continents[`SYNC_RAND_STATIC(Continents.Length)];
	} until(ContinentState.ObjectID != ContinentRef.ObjectID);

	return ContinentState;
}

simulated static function int GetSoldierIndex(StateObjectReference SoldierRef, XComGameState_HeadquartersXCom XComHQ)
{
	local int i;
	for( i = 0; i < XComHQ.Crew.Length; i++ )
	{
		if(XComHQ.Crew[i] == SoldierRef)
			return i;
	}
}

simulated static function bool HasSoldiersToCycleThrough(StateObjectReference SoldierRef, delegate<IsSoldierEligible> CheckEligibilityFunc)
{
	local int Index, Counter;
	local XComGameState_Unit Unit;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetXComHQ();
	History = `XCOMHISTORY;
	Index = GetSoldierIndex(SoldierRef, XComHQ);

	// Loop through the crew array looking for the next suitable soldier
	while( Counter < XComHQ.Crew.Length )
	{
		Index++;
		Counter++;

		if( Index >= XComHQ.Crew.Length )
			Index = 0;
		else if( Index < 0 )
			Index = XComHQ.Crew.Length - 1;

		Unit = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[Index].ObjectID));

		// If we've looped around to the same unit as the one passed in, that means we have no valid soldiers to switch to, return false
		if( Unit.ObjectID == SoldierRef.ObjectID )
			return false;
		else if( CheckEligibilityFunc(Unit) )
			return true;
	}

	return false;
}

simulated static function bool CycleSoldiers(int Direction, StateObjectReference SoldierRef, delegate<IsSoldierEligible> CheckEligibilityFunc, out StateObjectReference NewSoldier)
{
	local int Index, Counter;
	local XComGameState_Unit Unit;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = GetXComHQ();
	History = `XCOMHISTORY;
	Index = GetSoldierIndex(SoldierRef, XComHQ);

	// Loop through the crew array looking for the next suitable soldier
	while( Counter < XComHQ.Crew.Length )
	{
		Index += Direction;
		Counter++;

		if( Index >= XComHQ.Crew.Length )
			Index = 0;
		else if( Index < 0 )
			Index = XComHQ.Crew.Length - 1;

		Unit = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[Index].ObjectID));

		// If we've looped around to the same unit as the one passed in, that means we have no valid soldiers to switch to, return false
		if( Unit.ObjectID == SoldierRef.ObjectID )
		{
			return false;
		}
		else if( CheckEligibilityFunc(Unit) )
		{
			NewSoldier = Unit.GetReference();
			return true;
		}
	}

	return false;
}

simulated static function GetWeaponUpgradeAvailability(XComGameState_Unit Unit, out TWeaponUpgradeAvailabilityData WeaponUpgradeAvailabilityData)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item PrimaryWeapon;
	local X2WeaponTemplate WeaponTemplate;
	local int AvailableSlots, EquippedUpgrades;

	XComHQ = GetXComHQ();

	PrimaryWeapon = Unit.GetPrimaryWeapon();
	if (PrimaryWeapon == none)
		return;

	WeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
	EquippedUpgrades = PrimaryWeapon.GetMyWeaponUpgradeTemplateNames().Length;
	AvailableSlots = WeaponTemplate.NumUpgradeSlots;

	// Only add extra slots if the weapon had some to begin with
	if (AvailableSlots > 0)
	{
		if (XComHQ.bExtraWeaponUpgrade)
			AvailableSlots++;

		if (XComHQ.ExtraUpgradeWeaponCats.Find(WeaponTemplate.WeaponCat) != INDEX_NONE)
			AvailableSlots++;
	}

	WeaponUpgradeAvailabilityData.bCanWeaponBeUpgraded = (AvailableSlots > 0);
	WeaponUpgradeAvailabilityData.bHasWeaponUpgradeSlotsAvailable = (AvailableSlots > EquippedUpgrades);
	WeaponUpgradeAvailabilityData.bHasWeaponUpgrades = XComHQ.HasWeaponUpgradesInInventory();
	WeaponUpgradeAvailabilityData.bHasModularWeapons = XComHQ.bModularWeapons;
}

simulated static function GetPCSAvailability(XComGameState_Unit Unit, out TPCSAvailabilityData PCSAvailabilityData)
{
	local int AvailableSlots;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Item> EquippedImplants;

	XComHQ = GetXComHQ();

	EquippedImplants = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
	AvailableSlots = Unit.GetCurrentStat(eStat_CombatSims);
	PCSAvailabilityData.bHasCombatSimsSlotsAvailable = ( AvailableSlots > EquippedImplants.Length ) || XComHQ.bReusePCS;
	PCSAvailabilityData.bHasNeurochipImplantsInInventory = XComHQ.HasCombatSimsInInventory();
	PCSAvailabilityData.bHasAchievedCombatSimsRank = Unit.IsSufficientRankToEquipPCS();
	PCSAvailabilityData.bHasGTS = XComHQ.HasFacilityByName('OfficerTrainingSchool');
	PCSAvailabilityData.bCanEquipCombatSims = (AvailableSlots > 0);
}

// Used in UIArmory_MainMenu and UIArmory_Promotion
simulated static function bool PopulateAbilitySummary(UIScreen Screen, XComGameState_Unit Unit, optional bool bSkipRankCheck, optional XComGameState CheckGameState)
{
	local int i, Index;
	local XComGameState_Item InventoryItem;
	local X2AbilityTemplate AbilityTemplate;
	local array<AbilitySetupData> AbilitySetupList;
	local array<XComGameState_Item> PCSItems;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2CharacterTemplate CharacterTemplate;
	local name AbilityName;

	class'UIUtilities_Strategy'.static.NotifyAbilityListBondInfo(Screen, UIArmory(Screen).Header.bShowXpackPanel);

	Screen.Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(Screen.MCPath) $ ".abilitySummaryList");

	if( Unit.GetRank() == 0 && !bSkipRankCheck )
	{
		Screen.MC.FunctionVoid("hideAbilityList");
		class'UIUtilities_Strategy'.static.NotifyAbilityListBondInfo(Screen, false);
		return false;
	}

	Screen.MC.FunctionString("setSummaryTitle", default.m_strAbilityListTitle);

	// Populate ability list (multiple param function call: image then title then description)
	Screen.MC.BeginFunctionOp("setAbilitySummaryList");

	PCSItems = Unit.GetAllItemsInSlot(eInvSlot_CombatSim);
			
	Index = 0;

	foreach PCSItems(InventoryItem)
	{
		AddPCSToSummary(Screen, InventoryItem, Index++);
	}

	if(Unit.IsSoldier())
	{
		AbilityTree = Unit.GetEarnedSoldierAbilities();
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

		for(i = 0; i < AbilityTree.Length; ++i)
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[i].AbilityName);
			if( !AbilityTemplate.bDontDisplayInAbilitySummary )
			{
				AddAbilityToSummary(Screen, AbilityTemplate, Index++, Unit, CheckGameState);
			}
		}

		CharacterTemplate = Unit.GetMyTemplate();

		foreach CharacterTemplate.Abilities(AbilityName)
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);
			if( AbilityTemplate != none &&
			   !AbilityTemplate.bDontDisplayInAbilitySummary &&
			   AbilityTemplate.ConditionsEverValidForUnit(Unit, true) )
			{
				AddAbilityToSummary(Screen, AbilityTemplate, Index++, Unit, CheckGameState);
			}
		}
	}
	else
	{
		AbilitySetupList = Unit.GatherUnitAbilitiesForInit(CheckGameState,,true);

		for(i = 0; i < AbilitySetupList.Length; ++i)
		{
			AbilityTemplate = AbilitySetupList[i].Template;
			if( !AbilityTemplate.bDontDisplayInAbilitySummary )
			{
				AddAbilityToSummary(Screen, AbilityTemplate, Index++, Unit, CheckGameState);
			}
		}
	}

	Screen.MC.EndOp();

	return (Index > 0);
}
simulated static function bool PopulateAbilitySummary_Traits(UIScreen Screen, XComGameState_Unit Unit, optional bool bSkipRankCheck, optional XComGameState CheckGameState)
{
	local int Index;
	local X2EventListenerTemplateManager EventTemplateManager;
	local X2TraitTemplate TraitTemplate;
	local name TraitName;
	
	class'UIUtilities_Strategy'.static.NotifyAbilityListBondInfo(Screen, UIArmory(Screen).Header.bShowXpackPanel);

	Screen.Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(Screen.MCPath) $ ".abilitySummaryList");

	if( Unit.GetRank() == 0 && !bSkipRankCheck )
	{
		Screen.MC.FunctionVoid("hideAbilityList");
		class'UIUtilities_Strategy'.static.NotifyAbilityListBondInfo(Screen, false);
		return false;
	}

	Screen.MC.FunctionString("setSummaryTitle", default.m_strTraitListTitle);

	// Populate ability list (multiple param function call: image then title then description)
	Screen.MC.BeginFunctionOp("setAbilitySummaryList");

	Index = 0;

	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

	foreach Unit.AcquiredTraits(TraitName)
	{
		TraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(TraitName));

		if( TraitTemplate != none )
		{
			AddTraitToSummary(Screen, TraitTemplate, Index++);
		}
	}

	Screen.MC.EndOp();

	return (Index > 0);
}
simulated static function NotifyAbilityListBondInfo(UIScreen Screen, bool bShowingBondInfo)
{
	Screen.MC.FunctionBool("ShowingBondInfo", bShowingBondInfo);
}
simulated static function AddPCSToSummary(UIScreen Screen, XComGameState_Item Item, int index)
{
	local string TmpStr;
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = Item.GetMyTemplate();
	Screen.MC.QueueString(class'UIUtilities_Image'.static.GetPCSImage(Item)); 

	// Name
	TmpStr = ItemTemplate.GetItemFriendlyName(Item.ObjectID);
	Screen.MC.QueueString(TmpStr);

	// Description
	TmpStr = ItemTemplate.GetItemBriefSummary(Item.ObjectID);
	Screen.MC.QueueString(TmpStr);

	AddAbilitySummaryTooltip(Screen, TmpStr, index);
}

simulated static function AddTraitToSummary(UIScreen Screen, X2TraitTemplate TraitTemplate, int index)
{
	local string TmpStr;

	Screen.MC.QueueString(TraitTemplate.IconImage);

	// Trait Name
	TmpStr = TraitTemplate.TraitFriendlyName != "" ? TraitTemplate.TraitFriendlyName : ("Missing 'TraitFriendlyName' for '" $ TraitTemplate.DataName $ "'");
	Screen.MC.QueueString(TmpStr);

	// Trait Description
	TmpStr = TraitTemplate.TraitDescription != "" ? TraitTemplate.TraitDescription : ("Missing 'TraitDescription' for " $ TraitTemplate.DataName $ "'");
	Screen.MC.QueueString(TmpStr);

	AddAbilitySummaryTooltip(Screen, TmpStr, index);
}

simulated static function AddAbilityToSummary(UIScreen Screen, X2AbilityTemplate AbilityTemplate, int index, XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	local string TmpStr;

	Screen.MC.QueueString(AbilityTemplate.IconImage);

	// Ability Name
	TmpStr = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for '" $ AbilityTemplate.DataName $ "'");
	Screen.MC.QueueString(TmpStr);

	// Ability Description
	TmpStr = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState, CheckGameState) : ("Missing 'LocLongDescription' for " $ AbilityTemplate.DataName $ "'");
	Screen.MC.QueueString(TmpStr);

	AddAbilitySummaryTooltip(Screen, TmpStr, index);
}

simulated static function AddAbilitySummaryTooltip(UIScreen Screen, string TooltipText, int index)
{
	Screen.Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(TooltipText, 0, 0,
		string(Screen.MCPath) $ ".abilitySummaryList.theObject.AbilitySummaryItem" $ index,,
		false, class'UIUtilities'.const.ANCHOR_TOP_RIGHT, true,,,,,, 0);
}

simulated static function int GetMinimumContactCost()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local int MinContactCost, RegionContactCost;

	History = `XCOMHISTORY;
	MinContactCost = 9999;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if (!RegionState.HaveMadeContact())
		{
			RegionContactCost = RegionState.GetContactCostAmount();
			if (RegionContactCost < MinContactCost)
			{
				MinContactCost = RegionContactCost;
			}
		}
	}

	return MinContactCost;
}

simulated static function int GetUnitCurrentHealth(XComGameState_Unit UnitState, optional bool bUseLowestHP)
{
	if (bUseLowestHP)
	{
		return UnitState.LowestHP;
	}

	if(UnitState.bRecoveryBoosted)
	{
		return GetUnitMaxHealth(UnitState);
	}

	return (UnitState.GetCurrentStat(eStat_HP) + UnitState.GetUIStatFromInventory(eStat_HP) + UnitState.GetUIStatFromAbilities(eStat_HP));
}

simulated static function int GetUnitMaxHealth(XComGameState_Unit UnitState)
{
	return (UnitState.GetMaxStat(eStat_HP) + UnitState.GetUIStatFromInventory(eStat_HP) + UnitState.GetUIStatFromAbilities(eStat_HP));
}

simulated static function int GetUnitWillPercent(XComGameState_Unit UnitState)
{
	if(UnitState.bRecoveryBoosted)
	{
		return 100;
	}

	return int((UnitState.GetCurrentStat(eStat_Will) / UnitState.GetMaxStat(eStat_Will)) * 100.0f);
}

simulated static function string GetUnitWillColorString(XComGameState_Unit UnitState, optional bool bIgnoreBoost)
{
	switch(UnitState.GetMentalState())
	{
	case eMentalState_Ready:
		return class'UIUtilities_Colors'.static.GetHexColorFromState(eUIState_Good);
	case eMentalState_Tired:
		return class'UIUtilities_Colors'.static.GetHexColorFromState(eUIState_Warning);
	case eMentalState_Shaken:
		return class'UIUtilities_Colors'.static.GetHexColorFromState(eUIState_Warning2);
	}

	return class'UIUtilities_Colors'.static.GetHexColorFromState(eUIState_Normal);
}
