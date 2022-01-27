//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalQuickLaunch_UnitSlot
//  AUTHOR:  Sam Batista --  02/26/14
//  PURPOSE: Contains all the options and logic to outfit a unit (DEBUG ONLY)
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

// TODO: Add Utility, Mission, then Backpack dropdowns / selectors

class UITacticalQuickLaunch_UnitSlot extends UIPanel;

// Copied from UISoldierCustomize.uc
const FIRST_NAME_MAX_CHARS = 11;
const NICKNAME_NAME_MAX_CHARS = 11;
const LAST_NAME_MAX_CHARS = 15;

// GAME Vars
var name m_nCharacterTemplate;
var name m_nSoldierClassTemplate;
var int  m_iSoldierRank;
var name m_nPrimaryWeaponTemplate;
var name m_nSecondaryWeaponTemplate;
var name m_nHeavyWeaponTemplate;
var name m_nGrenadeSlotTemplate;
var name m_nArmorTemplate;
var name m_nUtilityItem1Template;
var name m_nUtilityItem2Template;
var int  m_iCharacterPoolSelection;
var array<SCATProgression> m_arrSoldierProgression;
var array<SoldierClassAbilityType> m_arrAbilityTree;

var StateObjectReference UnitRef; 

var string m_FirstName;
var string m_LastName;
var string m_NickName;

// UI Vars
var bool m_bMPSlot;

var int m_iDropdownWidth;
var int m_iXPositionHelper;

var string m_FirstNameButtonLabel;
var string m_LastNameButtonLabel;
var string m_NickNameButtonLabel;

var UIButton m_FirstNameButton;
var UIButton m_LastNameButton;
var UIButton m_NickNameButton;
var UIButton m_NameBeingSet; // so we know which button was clicked when the input dialog is closed
var UIButton m_AbilitiesButton;

var UIDropdown m_CharacterTypeDropdown;
var UIDropdown m_SoldierClassDropdown;
var UIDropdown m_SoldierRankDropdown;
var UIDropdown m_PrimaryWeaponDropdown;
var UIDropdown m_SecondaryWeaponDropdown;
var UIDropdown m_HeavyWeaponDropdown;
var UIDropdown m_GrenadeSlotDropdown;
var UIDropdown m_ArmorDropdown;
var UIDropdown m_UtilityItem1Dropdown;
var UIDropdown m_UtilityItem2Dropdown;
var UIDropdown m_CharacterPoolDropdown;

//----------------------------------------------------------------------------

simulated function UITacticalQuickLaunch_UnitSlot InitSlot(optional bool bMPSlot=false)
{
	InitPanel();

	Navigator.LoopSelection = false; 

	m_bMPSlot = bMPSlot;

	// Spawn divider under everything else
	Spawn(class'UIPanel', self).InitPanel(, class'UIUtilities_Controls'.const.MC_GenericPixel).SetPosition(5, 200).SetSize(1830, 2).SetAlpha(50);

	// create ui dropdowns
	m_CharacterTypeDropdown = CreateDropdown();
	m_CharacterTypeDropdown.SetY(170);
	m_SoldierRankDropdown = CreateDropdown("Rank", false);
	m_CharacterPoolDropdown = CreateDropdown("Character Pool", false);
	m_CharacterPoolDropdown.SetY(105);
	m_SoldierClassDropdown = CreateDropdown("Class");
	m_SoldierClassDropdown.SetY(40);	
	m_SecondaryWeaponDropdown = CreateDropdown("Secondary", false);
	m_HeavyWeaponDropdown = CreateDropdown("Heavy Weapon", false);
	m_HeavyWeaponDropdown.SetY(105);
	m_PrimaryWeaponDropdown = CreateDropdown("Primary");
	m_PrimaryWeaponDropdown.SetY(40); // position it above Secondary Weapon dropdown
	m_ArmorDropdown = CreateDropdown("Armor");
	m_ArmorDropdown.SetY(40);
	m_GrenadeSlotDropdown = CreateDropdown("Grenade Slot", false);
	m_GrenadeSlotDropdown.SetY(170);
	m_UtilityItem2Dropdown = CreateDropdown("Utility Item 2", false);
	m_UtilityItem2Dropdown.SetY(105);
	m_UtilityItem1Dropdown = CreateDropdown("Utility Item 1", false);
	m_UtilityItem1Dropdown.SetY(40); 	
	
	// create name buttons (after dropdowns so buttons have priority over mouse picking)
	m_FirstNameButton = Spawn(class'UIButton', self).InitButton('', m_FirstName != "" ? m_FirstName : m_FirstNameButtonLabel, SetName, eUIButtonStyle_NONE);
	m_FirstNameButton.SetPosition(20, 0).SetWidth(300);
	m_LastNameButton = Spawn(class'UIButton', self).InitButton('', m_LastName != "" ? m_LastName : m_LastNameButtonLabel, SetName, eUIButtonStyle_NONE);
	m_LastNameButton.SetPosition(20, 36).SetWidth(300);
	m_NickNameButton = Spawn(class'UIButton', self).InitButton('', m_NickName != "" ? m_NickName : m_NickNameButtonLabel, SetName, eUIButtonStyle_NONE);
	m_NickNameButton.SetPosition(20, 72).SetWidth(300);

	m_AbilitiesButton = Spawn(class'UIButton', self).InitButton('', "Edit Abilities", EditAbilities, eUIButtonStyle_NONE);
	m_AbilitiesButton.SetPosition(20, 108).SetWidth(200);

	// text scales when we resize the button (after setting text), calling realize forces the TextField to be recreated
	m_FirstNameButton.mc.FunctionVoid("realize");
	m_LastNameButton.mc.FunctionVoid("realize");
	m_NickNameButton.mc.FunctionVoid("realize");
	m_AbilitiesButton.mc.FunctionVoid("realize");

	if (!bMPSlot)
	{
		// populate ui controls with data
		RefreshDropdowns();
	}
	RefreshNavigation();

	return self;
}

function RefreshNavigation()
{

	Navigator.Clear();
	// bsg-nlong (1.10.17): Adding the name and ability buttons to the navigator for controll access
	Navigator.AddControl(m_FirstNameButton);
	Navigator.AddControl(m_LastNameButton);
	Navigator.AddControl(m_NickNameButton);
	Navigator.AddControl(m_AbilitiesButton);
	// bsg-nlong (1.10.17): end 
	Navigator.AddControl(m_CharacterTypeDropdown);
	Navigator.AddControl(m_SoldierClassDropdown);
	Navigator.AddControl(m_CharacterPoolDropdown);
	Navigator.AddControl(m_SoldierRankDropdown);
	Navigator.AddControl(m_PrimaryWeaponDropdown);
	Navigator.AddControl(m_HeavyWeaponDropdown);
	Navigator.AddControl(m_SecondaryWeaponDropdown);
	Navigator.AddControl(m_ArmorDropdown);
	Navigator.AddControl(m_UtilityItem1Dropdown);
	Navigator.AddControl(m_UtilityItem2Dropdown);

	Navigator.SetSelected(m_LastNameButton); // bsg-nlong (1.10.17): prevents recursive loop by allowing prev and next movement in navigator. The loop happens when parent.prev
											 // calls this.prev and then since this is on the first item it wil call parent.prev resulting in a recursive loop
				                             // This is also avoided by moving focus to the last name button (which can do prev and next) when losing focus.
											 // Kind of a hacky solution, but hey, it's a debug menu	
}

simulated function bool CanHaveHeavyWeapon()
{
	local name CheckAbility;
	local int BranchIndex;

	//  this has to mimic the functionality in XComGameState_Unit:HasHeavyWeapon because we have no state objects to operate on

	if ((m_nArmorTemplate != '') && X2ArmorTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(m_nArmorTemplate)).bHeavyWeapon)
		return true;

	if (m_nSoldierClassTemplate != '')
	{
		foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksHeavyWeapon(CheckAbility)
		{
			BranchIndex = m_arrAbilityTree.Find('AbilityName', CheckAbility);
			if(BranchIndex != INDEX_NONE)
			{
				if(m_arrSoldierProgression.Find('iBranch', BranchIndex) != INDEX_NONE)
				{
					return true;
				}
			}
		}
	}
	return false;
}

simulated function bool CanHaveGrenadeSlot()
{
	local name CheckAbility;
	local int BranchIndex;

	//  this has to mimic the functionality in XComGameState_Unit:HasGrenadePocket because we have no state objects to operate on

	if (m_nSoldierClassTemplate != '')
	{
		foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksGrenadePocket(CheckAbility)
		{
			BranchIndex = m_arrAbilityTree.Find('AbilityName', CheckAbility);
			if (BranchIndex != INDEX_NONE)
			{
				if(m_arrSoldierProgression.Find('iBranch', BranchIndex) != INDEX_NONE)
				{
					return true;
				}
			}
		}
	}
	return false;
}

simulated function string GetStringFormatPoints(int points)
{
	return "[" $ points $ "pts. ]";
}

simulated private function UIDropdown CreateDropdown(optional string label, optional bool shiftColumn = true)
{
	local UIDropdown kDropdown;
	kDropdown = Spawn(class'UIDropdown', self).InitDropdown('', label, DropdownSelectionChange);
	kDropdown.SetPosition(m_iXPositionHelper + 40, 170);
	if(shiftColumn) m_iXPositionHelper += m_iDropdownWidth;
	return kDropdown;
}

simulated function RefreshDropdowns()
{
	// always show character type + item dropdowns
	RefreshCharacterTypeDropdown();

	// certain dropdowns only show up for soldiers
	if(IsSoldierSlot())
	{
		m_SoldierClassDropdown.Show();
		m_SoldierRankDropdown.Show();
		m_PrimaryWeaponDropdown.Show();
		m_SecondaryWeaponDropdown.Show();
		m_ArmorDropdown.Show();
		m_CharacterPoolDropdown.Show();
		m_UtilityItem1Dropdown.Show();
		m_UtilityItem2Dropdown.Show();

		RefreshSoldierClassDropdown();
		RefreshSoldierRankDropdown();
		RefreshPrimaryWeaponDropdown();
		RefreshSecondaryWeaponDropdown();
		RefreshArmorDropdown();
		PopulateCharacterPoolDropdown(m_CharacterPoolDropdown);
		RefreshUtilityItemDropdowns();

		if(CanHaveHeavyWeapon())
		{
			m_HeavyWeaponDropdown.Show();
			RefreshHeavyWeaponDropdown();
		}
		else
		{
			m_nHeavyWeaponTemplate = '';
			m_HeavyWeaponDropdown.Hide();
		}

		if (CanHaveGrenadeSlot())
		{
			m_GrenadeSlotDropdown.Show();
			RefreshGrenadeSlotDropdown();
		}
		else
		{
			m_nGrenadeSlotTemplate = '';
			m_GrenadeSlotDropdown.Hide();
		}
	}
	else
	{
		m_SoldierClassDropdown.Hide();
		m_SoldierRankDropdown.Hide();
		m_PrimaryWeaponDropdown.Hide();
		m_SecondaryWeaponDropdown.Hide();
		m_HeavyWeaponDropdown.Hide();
		m_GrenadeSlotDropdown.Hide();
		m_ArmorDropdown.Hide();
		m_CharacterPoolDropdown.Hide();
		m_UtilityItem1Dropdown.Hide();
		m_UtilityItem2Dropdown.Hide();
	}
	RefreshNavigation();
}

function int SortCharacterTemplates(name Template1, name Template2)
{
	local bool Template1IsSoldier;
	local bool Template2IsSoldier;

	// soldier and sparks go to the top of the list, as a convienience
	Template1IsSoldier = Template1 == 'Soldier' || Template1 == 'SparkSoldier';
	Template2IsSoldier = Template2 == 'Soldier' || Template2 == 'SparkSoldier';
	if(Template1IsSoldier && !Template2IsSoldier)
	{
		return 1;
	}
	else if(!Template1IsSoldier && Template2IsSoldier)
	{
		return -1;
	}

	// and everything else gets sorted normally
	return string(Template1) > string(Template2) ? -1 : 1;
}

simulated function RefreshCharacterTypeDropdown()
{
	local int i, CharCount;
	local array<name> arrNames;
	local X2CharacterTemplate CharTemplate;
	local X2CharacterTemplateManager CharTemplateManager;
	local string strDisplayText;

	m_CharacterTypeDropdown.Clear(); // empty dropdown
	
	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharTemplateManager.GetTemplateNames(arrNames);

	// sort the templates by alphabetical order, to make searching them faster.
	arrNames.Sort(SortCharacterTemplates);

	CharCount = 0;
	for (i = 0; i < arrNames.Length; ++i)
	{
		CharTemplate = CharTemplateManager.FindCharacterTemplate(arrNames[i]);
		if (CharTemplate == none 
			|| (m_bMPSlot && (!CharTemplate.IsTemplateAvailableToAnyArea(CharTemplate.BITFIELD_GAMEAREA_Multiplayer)))
			|| CharTemplate.CharacterGroupName == 'Speaker') // remove speaker templates from TQL, since they aren't meant to be playable
			continue;

		strDisplayText = string(arrNames[i]);
		if (m_bMPSlot)
		{
			strDisplayText @= GetStringFormatPoints(CharTemplate.MPPointValue);
		}
		m_CharacterTypeDropdown.AddItem(strDisplayText, string(arrNames[i]));

		if(m_nCharacterTemplate == '')
			m_nCharacterTemplate = arrNames[i];
		if (arrNames[i] == m_nCharacterTemplate)
			m_CharacterTypeDropdown.SetSelected(CharCount);

		++CharCount;
	}
}

simulated function RefreshSoldierClassDropdown() // only for Soldiers
{
	local int i;
	local array<name> arrNames;
	local X2SoldierClassTemplateManager TemplateManager;
	local X2SoldierClassTemplate Template;
	local string strDisplayText;
	local X2SoldierClassTemplate ClassTemplate;

	m_SoldierClassDropdown.Clear(); // empty dropdown

	TemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	TemplateManager.GetTemplateNames(arrNames);

	for (i = 0; i < arrNames.Length; ++i)
	{
		strDisplayText = string(arrNames[i]);
		if (m_bMPSlot)
		{
			Template = TemplateManager.FindSoldierClassTemplate(arrNames[i]);
			strDisplayText @= GetStringFormatPoints(Template.ClassPoints);
		}
		m_SoldierClassDropdown.AddItem(strDisplayText, string(arrNames[i]));

		if(m_nSoldierClassTemplate == '')
			m_nSoldierClassTemplate = arrNames[i];
		 if (arrNames[i] == m_nSoldierClassTemplate)
			m_SoldierClassDropdown.SetSelected(i);
	}

	ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(m_nSoldierClassTemplate);

	if(ClassTemplate != none)
	{
		m_arrAbilityTree = ClassTemplate.GetAllPossibleAbilities();
	}
}

simulated function RefreshSoldierRankDropdown()
{
	local int i, MaxRank;

	m_SoldierRankDropdown.Clear();

	MaxRank = `GET_MAX_RANK;
	for (i = 0; i < MaxRank; ++i)
	{
		m_SoldierRankDropdown.AddItem(`GET_RANK_STR(i, m_nSoldierClassTemplate));
		if (m_iSoldierRank == i)
			m_SoldierRankDropdown.SetSelected(i);
	}
}

simulated function RefreshPrimaryWeaponDropdown()
{
	m_nPrimaryWeaponTemplate = PopulateItemDropdown(m_PrimaryWeaponDropdown, m_nPrimaryWeaponTemplate, eInvSlot_PrimaryWeapon);
}

simulated function RefreshSecondaryWeaponDropdown()
{
	m_nSecondaryWeaponTemplate = PopulateItemDropdown(m_SecondaryWeaponDropdown, m_nSecondaryWeaponTemplate, eInvSlot_SecondaryWeapon);
}

simulated function RefreshHeavyWeaponDropdown()
{
	m_nHeavyWeaponTemplate = PopulateItemDropdown(m_HeavyWeaponDropdown, m_nHeavyWeaponTemplate, eInvSlot_HeavyWeapon);
}

simulated function RefreshGrenadeSlotDropdown()
{
	m_nGrenadeSlotTemplate = PopulateItemDropdown(m_GrenadeSlotDropdown, m_nGrenadeSlotTemplate, eInvSlot_GrenadePocket);
}

simulated function RefreshArmorDropdown()
{
	m_nArmorTemplate = PopulateItemDropdown(m_ArmorDropdown, m_nArmorTemplate, eInvSlot_Armor);
}

simulated private function RefreshUtilityItemDropdowns()
{
	m_nUtilityItem1Template = PopulateItemDropdown(m_UtilityItem1Dropdown, m_nUtilityItem1Template, eInvSlot_Utility);
	m_nUtilityItem2Template = PopulateItemDropdown(m_UtilityItem2Dropdown, m_nUtilityItem2Template, eInvSlot_Utility);
}

//-----------------------------------------------------------------------------

simulated function PopulateCharacterPoolDropdown(UIDropdown kDropdown)
{
	local CharacterPoolManager CharacterPool;
	local XComGameState_Unit CharacterPoolUnit;
	local int Index;

	CharacterPool = `CHARACTERPOOLMGR;

	kDropDown.AddItem("No Selection");
	for(Index = 0; Index < CharacterPool.CharacterPool.Length; ++Index)
	{
		CharacterPoolUnit = CharacterPool.CharacterPool[Index];		
		kDropDown.AddItem(CharacterPoolUnit.GetName(eNameType_Full));
	}
}

simulated function name PopulateItemDropdown(UIDropdown kDropdown, name nCurrentEquipped, EInventorySlot eEquipmentType)
{
	local X2SoldierClassTemplate kSoldierClassTemplate;
	local X2DataTemplate kEquipmentTemplate;
	local bool bFoundCurrent, bHaveNothing;

	kDropdown.Clear(); // empty dropdown

	kSoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(m_nSoldierClassTemplate);

	if (eEquipmentType != eInvSlot_Armor && kSoldierClassTemplate != none)
	{
		bHaveNothing = true;
		kDropdown.AddItem("(nothing)");
		if (nCurrentEquipped == '')
			kDropdown.SetSelected(0);
	}	
	
	foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(kEquipmentTemplate, none)
	{
		if (kEquipmentTemplate == none || (m_bMPSlot && (!kEquipmentTemplate.IsTemplateAvailableToAnyArea(kEquipmentTemplate.BITFIELD_GAMEAREA_Multiplayer))))
			continue;
		if( X2EquipmentTemplate(kEquipmentTemplate) != none &&
			X2EquipmentTemplate(kEquipmentTemplate).iItemSize > 0 &&  // xpad is only item with size 0, that is always equipped
			((X2EquipmentTemplate(kEquipmentTemplate).InventorySlot == eEquipmentType) || (X2EquipmentTemplate(kEquipmentTemplate).InventorySlot == eInvSlot_Utility && eEquipmentType == eInvSlot_GrenadePocket)))
		{
			if (kSoldierClassTemplate != None && kEquipmentTemplate.IsA('X2WeaponTemplate'))
			{
				if (!kSoldierClassTemplate.IsWeaponAllowedByClass(X2WeaponTemplate(kEquipmentTemplate)))
				{
					if (nCurrentEquipped == kEquipmentTemplate.DataName)
						nCurrentEquipped = '';
					continue;
				}
			}

			if (kSoldierClassTemplate != None && kEquipmentTemplate.IsA('X2ArmorTemplate'))
			{
				if (!kSoldierClassTemplate.IsArmorAllowedByClass(X2ArmorTemplate(kEquipmentTemplate)))
				{
					if (nCurrentEquipped == kEquipmentTemplate.DataName)
						nCurrentEquipped = '';
					continue;
				}
			}

			if (eEquipmentType == eInvSlot_GrenadePocket)
			{
				if (X2GrenadeTemplate(kEquipmentTemplate) == None)
				{
					if (nCurrentEquipped == kEquipmentTemplate.DataName)
						nCurrentEquipped = '';
					continue;
				}
			}

			kDropdown.AddItem(X2EquipmentTemplate(kEquipmentTemplate).GetItemFriendlyName() @ GetStringFormatPoints(X2EquipmentTemplate(kEquipmentTemplate).GetPointsToComplete()), string(kEquipmentTemplate.DataName));

			if (kEquipmentTemplate.DataName == nCurrentEquipped)
			{
				kDropdown.SetSelected(kDropdown.items.Length - 1);
				bFoundCurrent = true;
			}
		}
	}
	if (eEquipmentType == eInvSlot_PrimaryWeapon || eEquipmentType == eInvSlot_SecondaryWeapon || eEquipmentType == eInvSlot_GrenadePocket)
	{
		if (!bFoundCurrent)
		{
			if (bHaveNothing && kDropdown.Items.Length > 1)
			{			
				kDropdown.SetSelected(1);			
			}
			else
			{
				kDropdown.SetSelected(0);
			}
			nCurrentEquipped = name(kDropdown.GetSelectedItemData());
		}
	}
	return nCurrentEquipped;
}

simulated function bool IsSoldierSlot()
{
	return m_nCharacterTemplate == '' || class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(m_nCharacterTemplate).bIsSoldier;
}

//-----------------------------------------------------------------------------

simulated function SoldierClassTemplateChanged(name NewSoldierClassTemplate)
{
	local X2SoldierClassTemplate		SoldierClassTemplate;

	if (m_nSoldierClassTemplate == NewSoldierClassTemplate)
		return;

	m_nSoldierClassTemplate = NewSoldierClassTemplate;
	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(NewSoldierClassTemplate);
	if (SoldierClassTemplate == none)
	{
		return;
	}
	if (SoldierClassTemplate.AcceptedCharacterTemplates.Length > 0)
	{
		if (SoldierClassTemplate.AcceptedCharacterTemplates.Find(NewSoldierClassTemplate) == INDEX_NONE)
		{
			//	need to change character template for this soldier class
			//	just pick the first allowable one
			CharacterTemplateChanged(SoldierClassTemplate.AcceptedCharacterTemplates[0]);
		}
	}
}

simulated function CharacterTemplateChanged(name NewCharacterTemplateName)
{
	local XComGameState_Unit Unit;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState TempGameState;
	local XComGameStateHistory History;
	local XComGameStateContext_ChangeContainer ChangeContainer;

	if (m_nCharacterTemplate == NewCharacterTemplateName)
		return; // No Change ...

	m_nCharacterTemplate = NewCharacterTemplateName;
	CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(m_nCharacterTemplate);
	if(CharacterTemplate == none)
	{
		`warn(`location @ "'" $ CharacterTemplate $ "' is not a valid template.");
		return;
	}

	History = `XCOMHISTORY;
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Character Template Change");
	TempGameState = History.CreateNewGameState(true, ChangeContainer);

	Unit = CharacterTemplate.CreateInstanceFromTemplate(TempGameState);
	Unit.ApplyInventoryLoadout(TempGameState);
	LoadTemplatesFromCharacter(Unit, TempGameState); // Update the rest of the dropdowns based on the default character template.

	// Revert the Game State ...
	History.CleanupPendingGameState(TempGameState);
}

simulated function DropdownSelectionChange(UIDropdown kDropdown)
{
	switch(kDropdown)
	{
	case m_CharacterTypeDropdown:   CharacterTemplateChanged(name(kDropdown.GetSelectedItemData()));    break;
	case m_SoldierClassDropdown:    SoldierClassTemplateChanged(name(kDropdown.GetSelectedItemData()));    break;
	case m_SoldierRankDropdown:     m_iSoldierRank = kDropDown.selectedItem;                            break;
	case m_PrimaryWeaponDropdown:   m_nPrimaryWeaponTemplate = name(kDropdown.GetSelectedItemData());   break;
	case m_SecondaryWeaponDropdown: m_nSecondaryWeaponTemplate = name(kDropdown.GetSelectedItemData()); break;
	case m_HeavyWeaponDropdown:     m_nHeavyWeaponTemplate = name(kDropdown.GetSelectedItemData());     break;
	case m_GrenadeSlotDropdown:     m_nGrenadeSlotTemplate = name(kDropdown.GetSelectedItemData());     break;
	case m_ArmorDropdown:           m_nArmorTemplate = name(kDropdown.GetSelectedItemData());           break;
	case m_UtilityItem1Dropdown:    m_nUtilityItem1Template = name(kDropdown.GetSelectedItemData());    break;
	case m_UtilityItem2Dropdown:    m_nUtilityItem2Template = name(kDropdown.GetSelectedItemData());    break;
	case m_CharacterPoolDropdown:   
		m_iCharacterPoolSelection = kDropdown.SelectedItem;
		OnCharacterPoolSelection();
		break;
	}
	RefreshDropdowns();
	Navigator.SetSelected(kDropdown); // bsg-nlong (1.10.17): Ensure we are on the right dropdown on the Navigator
}

simulated function OnCharacterPoolSelection()
{
	local CharacterPoolManager CharacterPool;
	local XComGameState_Unit CharacterPoolUnit;	

	CharacterPool = `CHARACTERPOOLMGR;
	CharacterPoolUnit = CharacterPool.CharacterPool[m_iCharacterPoolSelection - 1];

	if(CharacterPoolUnit.GetFirstName() != "")
	{
		m_FirstNameButton.SetText(CharacterPoolUnit.GetFirstName());
	}
	
	if(CharacterPoolUnit.GetLastName() != "")
	{
		m_LastNameButton.SetText(CharacterPoolUnit.GetLastName());
	}

	if(CharacterPoolUnit.GetNickName() != "")
	{
		m_NickNameButton.SetText(CharacterPoolUnit.GetNickName());
	}
}

simulated function SetName(UIButton kButton)
{
	local TInputDialogData kData;

	m_NameBeingSet = kButton;
	kData.fnCallback = OnNameInputBoxClosed;

	switch(kButton) 
	{
	// bsg-nlong (1.10.17): Adding virtual keyboard prompts and delegates for console versions
	case m_FirstNameButton:
		if( `ISCONSOLE )
		{
			Movie.Pres.UIKeyboard( m_FirstNameButtonLabel, 
				m_FirstNameButton.text != m_FirstNameButtonLabel ? m_FirstNameButton.text : "", 
				VirtualKeyboard_OnNameInputBoxAccepted, 
				VirtualKeyboard_OnNameInputBoxCancelled,
				false, 
				FIRST_NAME_MAX_CHARS
			);
			break;
		}

		kData.iMaxChars = FIRST_NAME_MAX_CHARS;
		kData.strTitle = m_FirstNameButtonLabel;
		kData.strInputBoxText = m_FirstNameButton.text != m_FirstNameButtonLabel ? m_FirstNameButton.text : "";
		Movie.Pres.UIInputDialog(kData);
		break;
	case m_LastNameButton:
		if( `ISCONSOLE )
		{
			Movie.Pres.UIKeyboard( m_LastNameButtonLabel, 
				m_LastNameButton.text != m_LastNameButtonLabel ? m_LastNameButton.text : "", 
				VirtualKeyboard_OnNameInputBoxAccepted, 
				VirtualKeyboard_OnNameInputBoxCancelled,
				false, 
				LAST_NAME_MAX_CHARS
			);
			break;
		}

		kData.iMaxChars = LAST_NAME_MAX_CHARS;
		kData.strTitle = m_LastNameButtonLabel;
		kData.strInputBoxText = m_LastNameButton.text != m_LastNameButtonLabel ? m_LastNameButton.text : "";
		Movie.Pres.UIInputDialog(kData);
		break;
	case m_NickNameButton:
		if( `ISCONSOLE )
		{
			Movie.Pres.UIKeyboard( m_NickNameButtonLabel, 
				m_NickNameButton.text != m_NickNameButtonLabel ? m_NickNameButton.text : "", 
				VirtualKeyboard_OnNameInputBoxAccepted, 
				VirtualKeyboard_OnNameInputBoxCancelled,
				false, 
				NICKNAME_NAME_MAX_CHARS
			);
			break;
		}

		kData.iMaxChars = NICKNAME_NAME_MAX_CHARS;
		kData.strTitle = m_NickNameButtonLabel;
		kData.strInputBoxText = m_NickNameButton.text != m_NickNameButtonLabel ? m_NickNameButton.text : "";
		Movie.Pres.UIInputDialog(kData);
		break;
	}
}

function VirtualKeyboard_OnNameInputBoxAccepted(string text, bool bWasSuccessful)
{
	if( bWasSuccessful) { OnNameInputBoxClosed(text); }
	return;
}

function VirtualKeyboard_OnNameInputBoxCancelled()
{
	return;
}
// bsg-nlong (1.10.17): end

function OnNameInputBoxClosed(string text)
{
	if(text != "")
	{
		m_NameBeingSet.SetText(text);
	}
}

simulated function EditAbilities(UIButton kButton)
{
	local UITacticalQuickLaunch_UnitAbilities kAbilitiesScreen;

	if(!Movie.Stack.IsInStack(class'UITacticalQuickLaunch_UnitAbilities'))
	{
		kAbilitiesScreen = Spawn(class'UITacticalQuickLaunch_UnitAbilities', self);
		Movie.Stack.Push(kAbilitiesScreen);
		kAbilitiesScreen.InitAbilities(self);
	}
}

//-----------------------------------------------------------------------------
simulated function XComGameState_Unit AddUnitToGameState(XComGameState NewGameState, XComGameState_Player ControllingPlayer)
{
	local XComGameState_Unit Unit;
	local X2CharacterTemplate CharacterTemplate;

	CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(m_nCharacterTemplate);
	if(CharacterTemplate == none)
	{
		`warn("CreateTemplatesFromCharacter: '" $ CharacterTemplate $ "' is not a valid template.");
		return none;
	}

	Unit = CharacterTemplate.CreateInstanceFromTemplate(NewGameState);
	if (ControllingPlayer != none)
	{
		Unit.SetControllingPlayer( ControllingPlayer.GetReference() );	
	}

	// Add Inventory
	Unit.SetSoldierClassTemplate(m_nSoldierClassTemplate); //Inventory needs this to work
	UpdateUnit(Unit, NewGameState); //needs to be before adding to inventory or 2nd util item gets thrown out
	Unit.bIgnoreItemEquipRestrictions = true;
	UpdateUnitItems(Unit, NewGameState);

	// add required loadout items
	if (Unit.GetMyTemplate().RequiredLoadout != '')
		Unit.ApplyInventoryLoadout(NewGameState, Unit.GetMyTemplate().RequiredLoadout);

	return Unit;
}

simulated function AddFullInventory(XComGameState GameState, XComGameState_Unit Unit)
{
	// Add inventory
	AddItemToUnit(GameState, Unit, m_nPrimaryWeaponTemplate);
	AddItemToUnit(GameState, Unit, m_nSecondaryWeaponTemplate);
	AddItemToUnit(GameState, Unit, m_nArmorTemplate);
	AddItemToUnit(GameState, Unit, m_nHeavyWeaponTemplate);
	AddItemToUnit(GameState, Unit, m_nGrenadeSlotTemplate, eInvSlot_GrenadePocket);
	AddItemToUnit(GameState, Unit, m_nUtilityItem1Template);
	AddItemToUnit(GameState, Unit, m_nUtilityItem2Template);
}

simulated function AddItemToUnit(XComGameState NewGameState, XComGameState_Unit Unit, name EquipmentTemplateName, optional EInventorySlot SpecificSlot)
{
	local XComGameState_Item ItemInstance;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(EquipmentTemplateName));

	if(EquipmentTemplate != none)
	{
		ItemInstance = EquipmentTemplate.CreateInstanceFromTemplate(NewGameState);
		Unit.AddItemToInventory(ItemInstance, SpecificSlot == eInvSlot_Unknown ? EquipmentTemplate.InventorySlot : SpecificSlot, NewGameState);
	}
}

simulated function UpdateUnitGameState(XComGameState GameState, XComGameState_Unit Unit)
{	
	UpdateUnitItems(Unit, GameState);
	UpdateUnit(Unit, GameState);
}

simulated function UpdateUnit(XComGameState_Unit Unit, XComGameState UseGameState)
{
	local TSoldier Soldier;    
	local XGCharacterGenerator CharacterGenerator;
	local string firstName, lastName, nickName;
	local CharacterPoolManager CharacterPool;
	local XComGameState_Unit CharacterPoolUnit;
	local SoldierRankAbilities SoldierAbilities;
	local int Index;

	CharacterPool = `CHARACTERPOOLMGR;    

	if (Unit.IsSoldier())
	{
		if(m_iCharacterPoolSelection > 0)
		{
			CharacterPoolUnit = CharacterPool.CharacterPool[m_iCharacterPoolSelection - 1];
			CharacterGenerator = `XCOMGRI.Spawn(CharacterPoolUnit.GetMyTemplate().CharacterGeneratorClass);

			//Generate a charater of the proper gender and race
			Soldier = CharacterGenerator.CreateTSoldierFromUnit(CharacterPoolUnit, UseGameState);
			
			//Fill in the appearance data manually ( it is set below into the unit state object )
			Soldier.kAppearance = CharacterPoolUnit.kAppearance;
			Soldier.nmCountry = CharacterPoolUnit.GetCountry();
		}
		else
		{            
			CharacterGenerator = `XCOMGRI.Spawn(Unit.GetMyTemplate().CharacterGeneratorClass);
			Soldier = CharacterGenerator.CreateTSoldierFromUnit(Unit, UseGameState);            
		}
		CharacterGenerator.Destroy();
		
		Unit.SetTAppearance(Soldier.kAppearance);
		Unit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
		Unit.SetCountry(Soldier.nmCountry);

		Unit.SetSoldierClassTemplate(m_nSoldierClassTemplate);
		Unit.ResetSoldierRank();
		for(Index = 0; Index < m_iSoldierRank; ++Index)
		{
			Unit.RankUpSoldier(UseGameState, m_nSoldierClassTemplate);
		}

		// Units always have list of all possibilities in their tree
		m_arrAbilityTree = Unit.GetSoldierClassTemplate().GetAllPossibleAbilities();
		Unit.AbilityTree.Length = 0;
		SoldierAbilities.Abilities = m_arrAbilityTree;
		Unit.AbilityTree.AddItem(SoldierAbilities);

		Unit.SetSoldierProgression(m_arrSoldierProgression);
		Unit.SetBaseMaxStat(eStat_UtilityItems, 2);
		Unit.SetCurrentStat(eStat_UtilityItems, 2);
	}
	else
	{
		Unit.ClearSoldierClassTemplate();
	}
	
	// Override character names if they were modified
	firstName = m_FirstNameButton.text != m_FirstNameButtonLabel ? m_FirstNameButton.text : Unit.GetFirstName();
	lastName = m_LastNameButton.text != m_LastNameButtonLabel ? m_LastNameButton.text : Unit.GetLastName();
	nickName = m_NickNameButton.text != m_NickNameButtonLabel ? m_NickNameButton.text : Unit.GetNickName();
	Unit.SetCharacterName(firstName, lastName, nickName);
}

simulated function UpdateUnitItems(XComGameState_Unit Unit, XComGameState GameState)
{
	local XComGameState_Item ItemInstance;
	local array<XComGameState_Item> RemoveItems;
	local int i;
	local XComGameStateHistory LocalHistory;
	local XComGameState StartState;

	LocalHistory = `XCOMHISTORY;
	StartState = LocalHistory.GetStartState( );
	`assert( StartState == GameState );

	// Find existing inventory
	foreach GameState.IterateByClassType(class'XComGameState_Item', ItemInstance)
	{
		if (ItemInstance.OwnerStateObject.ObjectID == Unit.ObjectID)
		{
			RemoveItems.AddItem(ItemInstance);
		}
	}

	// Clear out old inventory
	for (i = 0; i < RemoveItems.Length; ++i)
	{
		Unit.RemoveItemFromInventory(RemoveItems[i], GameState);
		LocalHistory.PurgeObjectIDFromStartState(RemoveItems[i].ObjectID, false);
	}

	LocalHistory.UpdateStateObjectCache( );

	// Re-add new
	AddFullInventory(GameState, Unit);
}

simulated function LoadTemplatesFromCharacter(XComGameState_Unit Unit, XComGameState FromGameState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;
	local bool bExcludeHistory;
	local X2SoldierClassTemplate ClassTemplate;

	`assert(Unit != none);

	m_nCharacterTemplate = Unit.GetMyTemplateName();
	m_nSoldierClassTemplate = Unit.GetSoldierClassTemplate() != none ? Unit.GetSoldierClassTemplate().DataName : class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass;
	m_iSoldierRank = Unit.GetRank();
	ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(m_nSoldierClassTemplate);
	m_arrAbilityTree.Length = 0;

	if(ClassTemplate != none)
	{
		m_arrAbilityTree = ClassTemplate.GetAllPossibleAbilities();
	}

	bExcludeHistory = FromGameState != none;

	Item = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon, FromGameState, bExcludeHistory);
	m_nPrimaryWeaponTemplate = (Item == none) ? '' : Item.GetMyTemplateName();

	Item = Unit.GetItemInSlot(eInvSlot_SecondaryWeapon, FromGameState, bExcludeHistory);
	m_nSecondaryWeaponTemplate = (Item == none) ? '' : Item.GetMyTemplateName();

	Item = Unit.GetItemInSlot(eInvSlot_HeavyWeapon, FromGameState, bExcludeHistory);
	m_nHeavyWeaponTemplate = (Item == none) ? '' : Item.GetMyTemplateName();

	Item = Unit.GetItemInSlot(eInvSlot_GrenadePocket, FromGameState, bExcludeHistory);
	m_nGrenadeSlotTemplate = (Item == none) ? '' : Item.GetMyTemplateName();

	Item = Unit.GetItemInSlot(eInvSlot_Armor, FromGameState, bExcludeHistory);
	m_nArmorTemplate = (Item == none) ? '' : Item.GetMyTemplateName();

	m_arrSoldierProgression = Unit.m_SoldierProgressionAbilties;

	// TODO: Add support for multiple utility items + other item types (mission items)
	Items = Unit.GetAllItemsInSlot(eInvSlot_Utility, FromGameState, true /*bExcludeHistory*/);
	if(Items.Length > 0)
	{
		m_nUtilityItem1Template = Items[0].GetMyTemplateName();
		if(Items.Length > 1)
			m_nUtilityItem2Template = Items[1].GetMyTemplateName();
	}
	
	m_FirstName = Unit.GetFirstName();
	m_LastName = Unit.GetLastName();
	m_NickName = Unit.GetNickName();

	UnitRef = Unit.GetReference();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	if (Navigator.GetSelected().OnUnrealCommand(cmd, arg))
	{
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	Navigator.SelectFirstAvailableIfNoCurrentSelection();
}

// bsg-nlong (1.10.17): Adding on OnLoseFocus so that we can manually change the selection to prevent loops
simulated function OnLoseFocus()
{
	Navigator.SetSelected(m_LastNameButton); //prevents recursive loop by allowing prev and next movement in navigator

	super.OnLoseFocus();
	Navigator.GetSelected().OnLoseFocus();
}
// bsg-nlong (1.10.17): end

//==============================================================================

defaultproperties
{
	Height = 220;
	m_iDropdownWidth = 350;
	m_iXPositionHelper = 0;

	m_FirstNameButtonLabel = "First Name";
	m_LastNameButtonLabel = "Last Name";
	m_NickNameButtonLabel = "Nick Name";

	m_iCharacterPoolSelection = 0;
	bCascadeFocus = false
	bCascadeSelection = true; 
}
