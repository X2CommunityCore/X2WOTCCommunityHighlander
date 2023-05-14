//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPSquadSelect_ListItem
//  AUTHOR:  Joe Cortese -- 9/16/2015
//  PURPOSE: Displays information pertaining to a single soldier in the MPSquad Select screen
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPSquadSelect_ListItem extends UISquadSelect_ListItem;

var XCOMGameState_Unit m_kEditUnit;
var XComGameState m_kSquadLoadout;
var UIButton InfoButton;

var X2MPShellManager m_kMPShellManager;
var bool m_bEditable;
var bool bIsDirty;

var localized string m_strRename;
var localized string m_strAlien;
var localized string m_strAdvent;

var localized string m_strInfoEmptySlotText;
var localized string m_strInfoEmptySlotAccept;
simulated function InitSquadListItem(X2MPShellManager ShellManager)
{
	InitPanel();

	InfoButton = Spawn(class'UIButton', self).InitButton('MPInfoButton',, OnClickedInfoButton);
	InfoButton.bAnimateOnInit = false;
	InfoButton.Hide(); // starts hidden
	
	m_kMPShellManager = ShellManager;
}

simulated function OnInit()
{
	super.OnInit();

	if(m_kEditUnit != none && m_kSquadLoadout != none)
		UpdateData();
}

simulated function XCOMGameState_Unit GetUnit()
{
	return m_kEditUnit;
}

simulated function SetUnit(XCOMGameState_Unit editUnit)
{
	bIsDirty = false;
	m_kEditUnit = editUnit;

	if(bIsInited && m_kSquadLoadout != none && editUnit != none)
		UpdateData();
}

simulated function SetLoadout(XComGameState squadLoadout)
{
	m_kSquadLoadout = squadLoadout;

	if(bIsInited && m_kEditUnit != none && squadLoadout != none)
		UpdateData();
}

function StateObjectReference GetUnitRef()
{
	local StateObjectReference UnitRef;
	if (m_kEditUnit != none)
	{
		UnitRef = m_kEditUnit.GetReference();
	}
	return UnitRef;
}

simulated function XComGameState_Item GetEquippedHeavyWeapon()
{
	return m_kEditUnit.GetItemInSlot(eInvSlot_HeavyWeapon, m_kSquadLoadout);
}

function bool HasHeavyWeapon()
{
	if(m_kEditUnit.ObjectID > 0)
		return m_kEditUnit.HasHeavyWeapon(m_kSquadLoadout);
	return false;
}

simulated function string GetHeavyWeaponName()
{
	if(GetEquippedHeavyWeapon() != none)
		return GetEquippedHeavyWeapon().GetMyTemplate().GetItemFriendlyName();
	else
		return "";
}

simulated function SetEditable(bool bIsEditable)
{
	m_bEditable = bIsEditable;
}

//------------------------------------------------------

simulated function OnUtilItemClicked(EInventorySlot itemSlotType, int itemSlotIndex )
{
	local UIArmory_Loadout_MP armoryScreen;
	local UIMPShell_SquadEditor SquadScreen;
	if(m_bEditable)
	{
		bIsDirty = true;
		SquadScreen = UIMPShell_SquadEditor(Movie.Stack.GetCurrentScreen());
		if(GetUnitRef().ObjectID > 0 && m_kEditUnit.IsSoldier())
		{
			if(`SCREENSTACK.IsNotInStack(class'UIArmory_Loadout_MP'))
			{
				armoryScreen = UIArmory_Loadout_MP(`SCREENSTACK.Push(Spawn(class'UIArmory_Loadout_MP', self), Movie.Pres.Get3DMovie()));
				armoryScreen.InitArmory_MP(m_kMPShellManager, m_kSquadLoadout, GetUnitRef(), , , , , , true);
			}
			else
			{
				armoryScreen = UIArmory_Loadout_MP(Movie.Stack.GetScreen(class'UIArmory_Loadout_MP'));
			}
		
			armoryScreen.SelectItemSlot(itemSlotType, m_kEditUnit.GetMPCharacterTemplate().NumUtilitySlots - 1);
		}
		SquadScreen.OnUnitDirtied(m_kEditUnit);
	}
}

simulated function OnClickedPrimaryWeapon()
{
	//This function is empty on purpose, you are only able to edit 1 utility item in MP
}

simulated function OnClickedHeavyWeapon()
{
	//This function is empty on purpose, you are only able to edit 1 utility item in MP
}

simulated function OnClickedDismissButton()
{
	local UIMPShell_SquadEditor SquadScreen;
	if(m_bEditable)
	{
		SquadScreen = UIMPShell_SquadEditor(Movie.Stack.GetCurrentScreen());
		SquadScreen.ClearPawn(m_kEditUnit.MPSquadLoadoutIndex);
		
		if(m_kEditUnit != none)
		{
			m_kSquadLoadout.PurgeGameStateForObjectID(m_kEditUnit.ObjectID);
		}
		
		MC.FunctionBool("setEditDisabled", false);
		
		SetUnit(none);
		SquadScreen.OnUnitDirtied(none); //bsg-cballinger (7.10.16): Removing a unit from the loadout dirties the loadout, so the user can be prompted to save the changes.
		UpdateData();
		SquadScreen.UpdateData();
		SquadScreen.SelectFirstListItem(); // bsg-jrebar (5/30/17): Adding SelectFirst to select the old item slot 
	}
}

simulated function OnClickedEditUnitButton()
{
	if(m_bEditable)
	{
		bIsDirty = true;
		if(!m_kEditUnit.IsSoldier())
		{
			OpenNicknameInputBox();
		}
		else
		{
			Movie.Pres.UICustomize_Menu(m_kEditUnit, none, m_kSquadLoadout);
		}
	}
}

simulated function OpenNicknameInputBox() 
{
	local TInputDialogData kData;

	//if(!`GAMECORE.WorldInfo.IsConsoleBuild() || `ISCONTROLLERACTIVE )
	//{
		kData.strTitle = class'XComCharacterCustomization'.default.CustomizeNickName;
		kData.iMaxChars = class'XComCharacterCustomization'.const.NICKNAME_NAME_MAX_CHARS;
		kData.strInputBoxText = m_kEditUnit.GetNickName(true);
		kData.fnCallback = OnNicknameInputBoxClosed;
		kData.DialogType = eDialogType_SingleLine;

		Movie.Pres.UIInputDialog(kData);
/*	}
	else
	{
		Movie.Pres.UIKeyboard( class'XComCharacterCustomization'.default.CustomizeNickName, 
			m_kEditUnit.GetNickName(true), 
			VirtualKeyboard_OnNicknameInputBoxAccepted, 
			VirtualKeyboard_OnNicknameInputBoxCancelled,
			false, 
			class'XComCharacterCustomization'.const.NICKNAME_NAME_MAX_CHARS
		);
	}*/

	UIMPShell_SquadEditor(Screen).NavHelp.Hide();
}

function OnNicknameInputBoxClosed(string text)
{
	if(text != "")
	{
		m_kEditUnit.SetUnitName(m_kEditUnit.GetFirstName(), m_kEditUnit.GetLastName(), text);
		UIMPShell_SquadEditor(Screen).OnUnitDirtied(m_kEditUnit);
	}
	UpdateData();

	UIMPShell_SquadEditor(Screen).NavHelp.Show();
}
function VirtualKeyboard_OnNicknameInputBoxAccepted(string text, bool bWasSuccessful)
{
	OnNicknameInputBoxClosed(bWasSuccessful ? text : "");
}

function VirtualKeyboard_OnNicknameInputBoxCancelled()
{
	OnNicknameInputBoxClosed("");
}

simulated function OnClickedSelectUnitButton()
{
	local UIMPShell_CharacterTemplateSelector tempScreen;
	local UIMPShell_SquadEditor SquadScreen;
	SquadScreen = UIMPShell_SquadEditor(Movie.Stack.GetFirstInstanceOf(class'UIMPShell_SquadEditor'));

	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(m_kEditUnit == none && m_bEditable)
	{	
		tempScreen = Spawn(class'UIMPShell_CharacterTemplateSelector', self);
		`SCREENSTACK.Push(tempScreen, PC.Pres.Get3DMovie());
		tempScreen.InitCharacterTemplateSelector(OnCharacterTemplateAccept, OnCharacterTemplateCancel, m_kMPShellManager.OnlineGame_GetMaxSquadCost() > 0? m_kMPShellManager.OnlineGame_GetMaxSquadCost() - SquadScreen.m_kLocalPlayerInfo.m_iSquadCost : 999999);
	}
}

simulated function OnClickedInfoButton(UIButton Button)
{
	local UIMPUnitStats MPStatsScreen;

	if(m_kEditUnit != None)
	{
		MPStatsScreen = Spawn(class'UIMPUnitStats', Movie.Pres);
		Movie.Pres.ScreenStack.Push(MPStatsScreen);
		MPStatsScreen.UpdateData(m_kEditUnit, m_kSquadLoadout);
	}
	else
	{
		InfoEmptySlotDialog();
	}
}
simulated function InfoEmptySlotDialog()
{
	local TDialogueBoxData kDialogData;

	kDialogData.strText = m_strInfoEmptySlotText;
	kDialogData.strAccept = m_strInfoEmptySlotAccept;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

function OnCharacterTemplateAccept(X2MPCharacterTemplate kSelectedTemplate)
{
	local UIMPShell_SquadEditor SquadScreen;
	SquadScreen = UIMPShell_SquadEditor(Movie.Stack.GetFirstInstanceOf(class'UIMPShell_SquadEditor'));

	`log(self $ "::" $ GetFuncName() @ "Character=" $ kSelectedTemplate.DisplayName,, 'uixcom_mp');
	`SCREENSTACK.PopFirstInstanceOfClass(class'UIMPShell_CharacterTemplateSelector');

	/*m_kEditUnit = */
	m_kMPShellManager.AddNewUnitToLoadout(kSelectedTemplate, m_kSquadLoadout, SlotIndex);
	SquadScreen.UpdateData();

	SquadScreen.OnUnitDirtied(m_kEditUnit);
}

function OnCharacterTemplateCancel()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	`SCREENSTACK.PopFirstInstanceOfClass(class'UIMPShell_CharacterTemplateSelector');
}

simulated function UpdateData(optional int Index = -1, optional bool bDisableEditAndRemove, optional bool bDisableDismiss, optional bool bDisableLoadout = true, optional array<EInventorySlot> CannotEditItemsList)
{
	local name TmpName;
	local int i, NumUtilitySlots;
	local float UtilityItemWidth, UtilityItemHeight;
	local string NameStr, ClassStr, RankStr, RankIconStr, PrimaryWeaponName;
	local UIMPSquadSelect_UtilityItem UtilityItem;
	local array<XComGameState_Item> EquippedItems;
	local XComGameState_Unit Unit;
	local XComGameState_Item PrimaryWeapon, HeavyWeapon, TmpUtilityItem, ExtraUtilityItem;
	local X2WeaponTemplate PrimaryWeaponTemplate, HeavyWeaponTemplate;
	local X2AbilityTemplate HeavyWeaponAbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;

	if(bDisabled)
		return;

	bDisabledLoadout = bDisableLoadout; // bsg-jrebar (5/30/17): Defaulting disabled loadout unless set otherwise

	SlotIndex = Index != -1 ? Index : SlotIndex;

	if( UtilitySlots == none )
	{
		UtilitySlots = Spawn(class'UIList', DynamicContainer).InitList(, 0, 138, 282, 70, true);
		UtilitySlots.bStickyHighlight = false;
		UtilitySlots.ItemPadding = 5;
	}

	if( AbilityIcons == none )
	{
		AbilityIcons = Spawn(class'UIPanel', DynamicContainer).InitPanel().SetPosition(4, 92);
		AbilityIcons.Hide(); // starts off hidden until needed
	}

	// -------------------------------------------------------------------------------------------------------------

	// empty slot
	if(GetUnitRef().ObjectID <= 0)
	{
		PsiMarkup.Hide();
		
		UtilitySlots.ClearItems();
		UtilitySlots.Hide();

		AS_SetEmpty(m_strSelectUnit);

		AbilityIcons.Remove();
		AbilityIcons = none;

		UtilitySlots.Hide();
		InfoButton.Hide();
	}
	else
	{
		Unit = m_kEditUnit;
		
		if(!m_bEditable)
		{
			bDisableEditAndRemove = true;
			MC.FunctionVoid("disableEdit");
			MC.FunctionVoid("disableDismiss");
		}
		else
		{
			MC.FunctionVoid("enableEdit");
			MC.FunctionVoid("enableDismiss");
		}
		
		UtilitySlots.Show();

		EquippedItems = class'UIUtilities_Strategy'.static.GetEquippedUtilityItems(Unit, m_kSquadLoadout);

		if(Unit.IsSoldier())
			NumUtilitySlots = Unit.GetMPCharacterTemplate().NumUtilitySlots;
		else
			NumUtilitySlots = 1;
		
		UtilityItemWidth = (UtilitySlots.GetTotalWidth() - (UtilitySlots.ItemPadding * (NumUtilitySlots - 1))) / NumUtilitySlots;
		UtilityItemHeight = UtilitySlots.Height;

		if(UtilitySlots.ItemCount != NumUtilitySlots)
			UtilitySlots.ClearItems();

		for(i = 0; i < NumUtilitySlots; ++i)
		{
			if(i >= UtilitySlots.ItemCount)
			{
				UtilityItem = UIMPSquadSelect_UtilityItem(UtilitySlots.CreateItem(class'UIMPSquadSelect_UtilityItem').InitPanel());
				UtilityItem.SetSize(UtilityItemWidth, UtilityItemHeight);
				UtilitySlots.OnItemSizeChanged(UtilityItem);
			}
		}

		if(Unit.IsSoldier())
		{
			for(i = 0; i < EquippedItems.Length; ++i)
			{
				TmpName = EquippedItems[i].GetMyTemplateName();
				if(Unit.ItemIsInMPBaseLoadout(TmpName))
				{
					ExtraUtilityItem = EquippedItems[i];
					
					// If we have two items of the same type, make sure to show them both
					if(Unit.GetNumItemsByTemplateName(TmpName, m_kSquadLoadout) > 1)
						TmpUtilityItem = EquippedItems[i];
				}
				else
					TmpUtilityItem = EquippedItems[i];
			}		
			
			UtilityItem = UIMPSquadSelect_UtilityItem(UtilitySlots.GetItem(0));
			UtilityItem.SetAvailable(TmpUtilityItem, eInvSlot_Utility, 0);	
			
			if(ExtraUtilityItem != none || NumUtilitySlots > 1)
			{
				UtilityItem = UIMPSquadSelect_UtilityItem(UtilitySlots.GetItem(1));
				if(ExtraUtilityItem != none)
					UtilityItem.SetDisabled(ExtraUtilityItem, eInvSlot_Utility, 1);
				else
					UtilityItem.SetLocked();
			}
		}
		else
		{
			UtilityItem = UIMPSquadSelect_UtilityItem(UtilitySlots.GetItem(0));
			UtilityItem.SetBlocked();
		}
		
		// Don't show class label for rookies since their rank is shown which would result in a duplicate string
		if(!unit.IsChampionClass())
			ClassStr = Unit.GetMPCharacterTemplate().DisplayName;

		if(Unit.IsSoldier())
		{
			NameStr = Unit.GetMPName(eNameType_FullNick);
			RankStr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Unit.GetMPCharacterTemplate().SoldierClassTemplateName).DisplayName;
			RankIconStr = class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetMPCharacterTemplate().SoldierClassTemplateName);
		}
		else
		{
			NameStr = Unit.GetNickName(true);
			if(NameStr == "")
				NameStr = " ";//name doesnt update from an empty string
			RankStr = Unit.IsAdvent() ? m_strAdvent : m_strAlien;
			RankIconStr = "";
		}

		PrimaryWeapon = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon, m_kSquadLoadout);
		if(PrimaryWeapon == none)
		{
			PrimaryWeapon = Unit.GetBestPrimaryWeapon(m_kSquadLoadout);
		}
		
		if (PrimaryWeapon != none)
		{
			PrimaryWeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
			PrimaryWeaponName = PrimaryWeaponTemplate.GetItemFriendlyName(PrimaryWeapon.ObjectID);
		}

		AS_SetMPFilled( class'UIUtilities_Text'.static.GetColoredText(NameStr, eUIState_Normal, 18),
						class'UIUtilities_Text'.static.GetColoredText(Caps(RankStr), eUIState_Normal, 22),
						class'UIUtilities_Text'.static.GetColoredText(Caps(ClassStr), eUIState_Header, 28),
						Unit.GetMPCharacterTemplate().IconImage, RankIconStr,
						class'UIUtilities_Text'.static.GetColoredText(Unit.IsSoldier() ? m_strEdit : m_strRename, bDisableEditAndRemove ? eUIState_Disabled : eUIState_Normal),
						class'UIUtilities_Text'.static.GetColoredText(m_strDismiss, bDisableEditAndRemove ? eUIState_Disabled : eUIState_Normal),
						class'UIUtilities_Text'.static.GetColoredText(PrimaryWeaponName, eUIState_Disabled),
						class'UIUtilities_Text'.static.GetColoredText(class'UIArmory_loadout'.default.m_strInventoryLabels[eInvSlot_PrimaryWeapon], eUIState_Disabled),
						class'UIUtilities_Text'.static.GetColoredText(GetHeavyWeaponName(), eUIState_Disabled), 
						class'UIUtilities_Text'.static.GetColoredText(GetHeavyWeaponDesc(), eUIState_Disabled),	"", false, "",
						class'X2MPData_Shell'.default.m_strPoints, string(Unit.GetUnitPointValue()));

		// TUTORIAL: Disable buttons if tutorial is enabled
		if(bDisableEditAndRemove)
			MC.FunctionVoid("disableEditAndRemoveButtons");

		PsiMarkup.SetVisible(Unit.HasPsiGift());

		HeavyWeapon = Unit.GetItemInSlot(eInvSlot_HeavyWeapon, m_kSquadLoadout);
		if(HeavyWeapon != none)
		{
			HeavyWeaponTemplate = X2WeaponTemplate(HeavyWeapon.GetMyTemplate());

			// Only show one icon for heavy weapon abilities
			if(HeavyWeaponTemplate.Abilities.Length > 0)
			{
				AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
				HeavyWeaponAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(HeavyWeaponTemplate.Abilities[0]);
				if(HeavyWeaponAbilityTemplate != none)
					Spawn(class'UIIcon', AbilityIcons).InitIcon(, HeavyWeaponAbilityTemplate.IconImage, false);
			}

			AbilityIcons.Show();
			AS_HasHeavyWeapon(true);
		}
		else
		{
			AbilityIcons.Hide();
			AS_HasHeavyWeapon(false);
		}

		if( `ISCONTROLLERACTIVE == false) 
			InfoButton.Show();
	}
}

simulated function AS_SetMPFilled( string firstName, string lastName, string nickName,
								 string classIcon, string rankIcon, string editLabel, string dismissLabel, 
								 string primaryWeaponLabel, string primaryWeaponDescription,
								 string heavyWeaponLabel, string heavyWeaponDescription,
								 string promoteLabel, bool isPsiPromote, string className,
								 string pointsLabel, string pointsValue )
{
	mc.BeginFunctionOp("setMPFilledSlot");
	mc.QueueString(firstName);
	mc.QueueString(lastName);
	mc.QueueString(nickName);
	mc.QueueString(classIcon);
	mc.QueueString(rankIcon);
	mc.QueueString(editLabel);
	mc.QueueString(dismissLabel);
	mc.QueueString(primaryWeaponLabel);
	mc.QueueString(primaryWeaponDescription);
	mc.QueueString(heavyWeaponLabel);
	mc.QueueString(heavyWeaponDescription);
	mc.QueueString(promoteLabel);
	mc.QueueBoolean(isPsiPromote);
	mc.QueueString(className);
	mc.QueueString(pointsLabel);
	mc.QueueString(pointsValue);
	mc.EndOp();
}