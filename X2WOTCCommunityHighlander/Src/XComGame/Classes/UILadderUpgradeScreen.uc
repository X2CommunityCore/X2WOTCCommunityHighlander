//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UILadderUpgradeScreen.uc
//  AUTHOR:  Joe Cortese
//----------------------------------------------------------------------------
//  Copyright (c) 2018 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UILadderUpgradeScreen extends UIScreen;

var UIButton	 Upgrade0Button;
var UIButton	 Upgrade1Button;

var int SelectedColumn; 
var XComGameState_HeadquartersXCom XComHQ;

var localized string m_strChooseUpgrade;
var localized string m_strEquipUpgrade;
var localized string m_strUpgradeFormat;
var localized string m_strReplaceFormat;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	Upgrade0Button = Spawn(class'UIButton', self);
	Upgrade1Button = Spawn(class'UIButton', self);
	
	Upgrade0Button.InitButton('Upgrade00', m_strChooseUpgrade, ChooseUpgrade0);
	Upgrade1Button.InitButton('Upgrade01', m_strChooseUpgrade, ChooseUpgrade1);

	if( `ISCONTROLLERACTIVE )
	{
		SelectColumn(SelectedColumn);
	}
}

simulated function OnInit()
{
	local XComGameState_LadderProgress LadderData;
	local X2LadderUpgradeTemplateManager TemplateManager;
	local X2LadderUpgradeTemplate Upgrade;
	local X2SoldierClassTemplateManager ClassManager;
	local X2ItemTemplateManager ItemManager;
	local array<name> SquadProgressionNames;
	local XComNarrativeMoment NarrativeMoment;
	local name NextNarrativeSquadName;
	
	super.OnInit();

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (LadderData.SquadProgressionName != "")
		SquadProgressionNames = class'XComGameState_LadderProgress'.static.GetSquadProgressionMembers( LadderData.SquadProgressionName, LadderData.LadderRung + 1 );
	if (LadderData.LadderSquadName != '')
	{
		NextNarrativeSquadName = class'XComGameState_LadderProgress'.static.GetNarrativeSquadName( LadderData.LadderIndex, LadderData.LadderRung + 1 );
		class'UITacticalQuickLaunch_MapData'.static.GetSqaudMemberNames( NextNarrativeSquadName, SquadProgressionNames );
	}

	`assert( SquadProgressionNames.Length > 0 );

	MC.BeginFunctionOp("SetScreenTitle");
	MC.QueueString(class'UIMissionSummary'.default.m_strMissionComplete); // Title
	if (LadderData.LadderIndex < 10)
	{
		MC.QueueString(LadderData.NarrativeLadderNames[LadderData.LadderIndex]);//Mission Name
	}
	else
	{
		MC.QueueString(LadderData.LadderName);//Mission Name
	}
	MC.QueueString(class'UILadderSoldierInfo'.default.m_MissionLabel);//Mission Label
	MC.QueueString(String(LadderData.LadderRung) $ "/" $ String(LadderData.LadderSize));//Mission Count
	MC.QueueString(m_strChooseUpgrade);//Upgrade sub title
	MC.EndOp();

	TemplateManager = class'X2LadderUpgradeTemplateManager'.static.GetLadderUpgradeTemplateManager();
	ClassManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	Upgrade = TemplateManager.FindUpgradeTemplate(LadderData.ProgressionChoices1[LadderData.LadderRung - 1]);
	PopulateUpgradePanel( 0, Upgrade, SquadProgressionNames, ClassManager, ItemManager );

	Upgrade = TemplateManager.FindUpgradeTemplate(LadderData.ProgressionChoices2[LadderData.LadderRung - 1]);
	PopulateUpgradePanel( 1, Upgrade, SquadProgressionNames, ClassManager, ItemManager );

	if (`XPROFILESETTINGS.Data.m_bLadderNarrativesOn)
	{
		if ((LadderData.LootSelectNarrative.Length >= LadderData.LadderRung) && (LadderData.LootSelectNarrative[ LadderData.LadderRung - 1 ] != ""))
		{
			NarrativeMoment = XComNarrativeMoment(DynamicLoadObject(LadderData.LootSelectNarrative[ LadderData.LadderRung - 1 ], class'XComNarrativeMoment'));
			if (NarrativeMoment != none)
			{
				`PRESBASE.UINarrative( NarrativeMoment );
			}
		}
	}
}

simulated function PopulateUpgradePanel( int Index, X2LadderUpgradeTemplate Upgrade, array<name> SquadMembers, X2SoldierClassTemplateManager ClassManager, X2ItemTemplateManager ItemManager )
{
	local int i, j, k, DescIdx;
	local XGParamTag ParamTag;
	local string ExpandedString;
	local X2SoldierClassTemplate ClassTemplate;
	local X2EquipmentTemplate ItemTemplate;
	local X2WeaponUpgradeTemplate ItemUpgradeTemplate;
	local array<X2WeaponUpgradeTemplate> equippedUpgrades;
	local name FilterName;
	local array<name> DisplayedClasses;
	local XComGameState_Item primaryWeaponItem, replacementItem;
	local array<XComGameState_Item> utilItems;
	local bool bReplace, bAddLine, bAdded;
	local XComGameState_Unit Soldier;
	local X2WeaponTemplate WeaponTemplate;
	
	mc.BeginFunctionOp("SetUpgradePanel");
	mc.QueueNumber(Index); // index
	mc.QueueString(Upgrade.ImagePath); //upgrade image
	mc.QueueString(Upgrade.ShortDescription); // upgrade title
	mc.QueueString(Upgrade.FullDescription); // upgrade info
	mc.QueueString(GetEquipButtonText(Index)); // choose this button text
	mc.EndOp();

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	mc.BeginFunctionOp("SetUpgradeDetailRow");
	mc.QueueNumber(Index); // index

	DescIdx = 0;

	for (i = 0; (i < Upgrade.Upgrades.Length) && (DescIdx < 6); ++i)
	{
		bAddLine = true;
		
		FilterName = name(Upgrade.Upgrades[i].ClassGroup != "" ? Upgrade.Upgrades[i].ClassGroup : Upgrade.Upgrades[i].ClassFilter);

		// determine if we already saw this class (because of a story character class probably)
		if (DisplayedClasses.Find( FilterName ) != INDEX_NONE)
			continue;
		
		bAdded = false;
		for (j = 0; j < XComHQ.Squad.Length && !bAdded; j++)
		{
			Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Squad[j].ObjectID));
			if (Soldier != none && Soldier.GetSoldierClassTemplateName() == name(Upgrade.Upgrades[i].ClassFilter))
			{
				bAdded = true;
				ClassTemplate = ClassManager.FindSoldierClassTemplate(FilterName);
				DisplayedClasses.AddItem(FilterName);

				ItemTemplate = X2EquipmentTemplate(ItemManager.FindItemTemplate(Upgrade.Upgrades[i].EquipmentNames[0]));

				bReplace = false;
				if (ItemTemplate != none)
				{
					if (ItemTemplate.InventorySlot != eInvSlot_Utility)
					{
						if (ItemTemplate.InventorySlot == eInvSlot_HeavyWeapon)
						{
							bAddLine = Soldier.HasHeavyWeapon();
						}
						replacementItem = Soldier.GetItemInSlot(ItemTemplate.InventorySlot);

						//Issue #295 - Add a 'none' check before accessing replacementItem
						if (replacementItem != none)
						{
							bReplace = true;
							ParamTag.StrValue2 = replacementItem.GetMyTemplate().GetItemFriendlyNameNoStats();
						}
						else 
						{
							ParamTag.StrValue2 = ""; // Set string to empty to when replacementItem is 'none'.
						}
					}
					else
					{
						utilItems = Soldier.GetAllItemsInSlot(eInvSlot_Utility);
						for (k = 0; k < utilItems.Length; k++)
						{
							if ((utilItems[k].GetMyTemplate().ItemCat == 'grenade' && ItemTemplate.ItemCat == 'grenade') ||
								(utilItems[k].GetMyTemplate().ItemCat == 'pcs'     && ItemTemplate.ItemCat == 'pcs'    ) ||
								(utilItems[k].GetMyTemplate().ItemCat != 'grenade' && ItemTemplate.ItemCat != 'grenade' && utilItems[k].GetMyTemplateName() != 'XPad' && utilItems[k].GetMyTemplate().ItemCat != 'heal' ))
							{
								bReplace = true;
								ParamTag.StrValue2 = utilItems[k].GetMyTemplate().GetItemFriendlyNameNoStats();
							}
						}
					}

					//
					ParamTag.StrValue0 = ClassTemplate.DisplayName;
					ParamTag.StrValue1 = ItemTemplate.GetItemFriendlyNameNoStats();
				}
				else
				{
					ItemUpgradeTemplate = X2WeaponUpgradeTemplate(ItemManager.FindItemTemplate(Upgrade.Upgrades[i].EquipmentNames[0]));

					primaryWeaponItem = Soldier.GetItemInSlot(eInvSlot_PrimaryWeapon);
					equippedUpgrades = primaryWeaponItem.GetMyWeaponUpgradeTemplates();
					if (equippedUpgrades.Length > 0)
					{
						bReplace = true;
						ParamTag.StrValue2 = equippedUpgrades[0].GetItemFriendlyNameNoStats();
					}
					WeaponTemplate = X2WeaponTemplate(primaryWeaponItem.GetMyTemplate());

					// Single line for Issue #93
					bAddLine = WeaponTemplate != none && primaryWeaponItem.GetNumUpgradeSlots() > 0 && ItemUpgradeTemplate.CanApplyUpgradeToWeapon(primaryWeaponItem);

					//
					ParamTag.StrValue0 = ClassTemplate.DisplayName;
					ParamTag.StrValue1 = ItemUpgradeTemplate.GetItemFriendlyNameNoStats();
				}

				if (bReplace)
				{
					ExpandedString = `XEXPAND.ExpandString(m_strReplaceFormat);
					ExpandedString = class'UIUtilities_Text'.static.InjectImage("warning_icon", 26, 26, -4) $ " " $ ExpandedString;
				}
				else
				{
					ExpandedString = `XEXPAND.ExpandString(m_strUpgradeFormat);
				}

				if (bAddLine)
				{
					MC.QueueString(ExpandedString);

					++DescIdx;
				}
			}
		}
	}

	// Fill up any unused parameters
	while (DescIdx < 6)
	{
		MC.QueueString("");
		++DescIdx;
	}
	mc.EndOp();
}

simulated function ChooseUpgrade0(UIButton button)
{
	local XComGameState_LadderProgress LadderData;
	local XComGameState_CampaignSettings CampaignSettings;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));
	LadderData.OnComplete('eUIAction_Accept');

	CampaignSettings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	`FXSLIVE.BizAnalyticsLadderUpgrade( CampaignSettings.BizAnalyticsCampaignID, 
											string(LadderData.ProgressionChoices1[LadderData.LadderRung - 1]),
											string(LadderData.ProgressionChoices2[LadderData.LadderRung - 1]),
											1 );
}
simulated function ChooseUpgrade1(UIButton button)
{
	local XComGameState_LadderProgress LadderData;
	local XComGameState_CampaignSettings CampaignSettings;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));
	LadderData.OnComplete('eUIAction_Decline');

	CampaignSettings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	`FXSLIVE.BizAnalyticsLadderUpgrade( CampaignSettings.BizAnalyticsCampaignID, 
											string(LadderData.ProgressionChoices1[LadderData.LadderRung - 1]),
											string(LadderData.ProgressionChoices2[LadderData.LadderRung - 1]),
											2 );
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		//TODO : confirm column selection 
		if( SelectedColumn == 0 )
			ChooseUpgrade0(none);
		else if( SelectedColumn == 1 )
			ChooseUpgrade1(none);
		return true;

	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT :
	case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT :
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT :
	case class'UIUtilities_Input'.const.FXS_KEY_D :
		SelectColumn(1);
		return true;

	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT :
	case class'UIUtilities_Input'.const.FXS_ARROW_LEFT :
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT :
	case class'UIUtilities_Input'.const.FXS_KEY_A :
		SelectColumn(0);
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function SelectColumn(int iCol)
{
	SelectedColumn = iCol; 
	MC.FunctionNum("SelectColumn", SelectedColumn); 

	RefreshContinueText(0);
	RefreshContinueText(1);
}

simulated function RefreshContinueText(int iCol)
{
	mc.BeginFunctionOp("SetContinueText");
	mc.QueueNumber(iCol); // index
	mc.QueueString(GetEquipButtonText(iCol)); // choose this button text
	mc.EndOp();
}

simulated function string GetEquipButtonText(int iCol)
{
	if( `ISCONTROLLERACTIVE && SelectedColumn == iCol )
	{
		return class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetAdvanceButtonIcon(), 26, 26, -10) @ m_strEquipUpgrade;
	}
	else
	{
		return m_strEquipUpgrade;
	}
}

defaultproperties
{
	Package = "/ package/gfxTLE_LadderLevelUp/TLE_LadderLevelUp";
	LibID = "UpgradeScreen";
	InputState = eInputState_Consume;

	bHideOnLoseFocus = false;

	SelectedColumn = 0; 
}
