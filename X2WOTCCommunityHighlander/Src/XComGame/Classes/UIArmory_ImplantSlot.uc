//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory_ImplantSlot.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: List item slot for Soldier Implants.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIArmory_ImplantSlot extends UIPanel;

var int SlotIndex;
var bool bIsLocked;

var XComGameState_Item ImplantItem;

var UIButton Button;
var UIScrollingText Label;
var UIScrollingText Description;
var UIImage Icon;

var localized string m_strAvailableLabel;
var localized string m_strAvailableDescription;

var localized string m_strLockedLabel;
var localized string m_strLockedDescription;

simulated function UIArmory_ImplantSlot InitImplantSlot(int InitIndex)
{
	SlotIndex = InitIndex;

	InitPanel();

	Width = UIArmory_Implants(Screen).List.Width;

	Button = Spawn(class'UIButton', self).InitButton();
	Button.SetSize(Width, Height);
	Button.OnMouseEventDelegate = OnChildMouseEvent;
	
	Label = Spawn(class'UIScrollingText', self).InitScrollingText(,, Width - 110, 100, 15, true);
	Description = Spawn(class'UIScrollingText', self).InitScrollingText(,, Width - 110, 100, 50, false);

	Icon = Spawn(class'UIImage', self).InitImage();
	Icon.SetPosition(18, 15);

	return self;
}

simulated function SetAvailable(optional XComGameState_Item Item, optional eUIState TextState = eUIState_Normal)
{
	local X2ItemTemplate ItemTemplate;

	ImplantItem = Item;

	if(ImplantItem != none)
	{
		ItemTemplate = ImplantItem.GetMyTemplate();
		Label.SetTitle(class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyName(ImplantItem.ObjectID), TextState));
		Icon.LoadImage(class'UIUtilities_Image'.static.GetPCSImage(Item));
		Description.SetText();
	}
	else
	{
		Label.SetTitle(class'UIUtilities_Text'.static.GetColoredText(m_strAvailableLabel, TextState));
		Description.SetText(class'UIUtilities_Text'.static.GetColoredText(m_strAvailableDescription, TextState));
		Icon.LoadImage(class'UIUtilities_Image'.const.PersonalCombatSim_Empty);
	}

	Button.EnableButton();
	bIsLocked = false;
}

simulated function SetLocked(XComGameState_Unit Unit)
{
	local XGParamTag LocTag;
	local array<int> UnlockRanks;

	UnlockRanks = Unit.GetPCSRanks();

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	// Start Issue #408
	LocTag.StrValue0 = Unit.GetSoldierRankName(UnlockRanks[SlotIndex]);
	// End Issue #408

	Label.SetTitle(class'UIUtilities_Text'.static.GetColoredText(m_strLockedLabel, eUIState_Disabled));
	Description.SetText(class'UIUtilities_Text'.static.GetColoredText(`XEXPAND.ExpandString(m_strLockedDescription), eUIState_Disabled));
	Icon.LoadImage(class'UIUtilities_Image'.const.PersonalCombatSim_Locked);
	Button.DisableButton();

	ImplantItem = none;
	bIsLocked = true;
}

simulated function OnChildMouseEvent(UIPanel Control, int Cmd)
{
	switch(Cmd)
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			if(!bIsLocked)
				`HQPRES.UIInventory_Implants();
			else
				`HQPRES.PlayUISound(eSUISound_MenuClickNegative);
		break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			if(!bIsLocked)
				SetAvailable(ImplantItem, -1);
		break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			if(!bIsLocked)
				SetAvailable(ImplantItem);
		break;
	}
}

defaultproperties
{
	// Width is derived from the list this item is contained in
	Height = 95;
}