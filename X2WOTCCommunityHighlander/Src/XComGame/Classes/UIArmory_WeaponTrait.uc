//---------------------------------------------------------------------------------------
//  FILE:    UIArmory_WeaponTrait.uc
//  AUTHOR:  Sam Batista --  11/4/2015
//  PURPOSE: Copy of UICustomize_Trait, for use in Weapon Upgrade screen
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIArmory_WeaponTrait extends UIArmory_WeaponUpgrade
	dependson(UICustomize);

//----------------------------------------------------------------------------
// MEMBERS

// UI
var array<string> Data; 
var public string Title;
var public string Subtitle;
var public int StartingIndex;
var bool bAllowedToCycleSoldiers; 

var delegate<OnItemSelectedCallback> OnSelectionChanged;
var delegate<OnItemSelectedCallback> OnItemClicked;
var delegate<OnItemSelectedCallback> OnConfirmButtonClicked;

delegate OnItemSelectedCallback(UIList _list, int itemIndex);

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	if(`ScreenStack.IsInStack(class'UIArmory_WeaponUpgrade'))
		`ScreenStack.GetScreen(class'UIArmory_WeaponUpgrade').Hide();
}

simulated function OnRemoved()
{
	if(`ScreenStack.IsInStack(class'UIArmory_WeaponUpgrade'))
		`ScreenStack.GetScreen(class'UIArmory_WeaponUpgrade').Show();
}

simulated function UpdateSlots()
{
	//do nothing
}

simulated function InterpolateWeapon()
{
	// do nothing
}

simulated function UpdateCustomization(UIPanel DummyParam)
{
	//do nothing
}

simulated function CreateWeaponPawn(XComGameState_Item Weapon, optional Rotator DesiredRotation)
{
	if(`ScreenStack.IsInStack(class'UIArmory_WeaponUpgrade'))
		ActorPawn = UIArmory_WeaponUpgrade(`ScreenStack.GetScreen(class'UIArmory_WeaponUpgrade')).ActorPawn;
}

simulated function UpdateTrait( string _Title, 
							  array<string> _Data, 
							  delegate<OnItemSelectedCallback> _onSelectionChanged,
							  delegate<OnItemSelectedCallback> _onItemClicked,
							  optional delegate<UICustomize.IsSoldierEligible> _checkSoldierEligibility,
							  optional int _startingIndex = -1, 
							  optional string _ConfirmButtonLabel,
							  optional delegate<OnItemSelectedCallback> _onConfirmButtonClicked)
{
	local int i;
	local UIListItemString ListItemString;

	Data = _Data;
	SetSlotsListTitle(Caps(_Title));
	SlotsList.bAutosizeItems = true;
	SlotsList.OnSelectionChanged = _onSelectionChanged;
	SlotsList.OnItemClicked = OnClickLocal;
	SlotsList.OnItemDoubleClicked = OnDoubleClickLocal;
	SlotsList.ItemPadding = 0; // SlotsList item height already accounts for padding
	SlotsListContainer.GetChildByName('BG').ProcessMouseEvents(SlotsList.OnChildMouseEvent);
	OnItemClicked = _onItemClicked;
	IsSoldierEligible = _checkSoldierEligibility;
	StartingIndex = _startingIndex;
	OnConfirmButtonClicked = _onConfirmButtonClicked;
	
	if(SlotsList.itemCount > Data.length)
		SlotsList.ClearItems();

	while(SlotsList.itemCount < Data.length)
		Spawn(class'UIListItemString', SlotsList.itemContainer).InitListItem();
	
	SlotsList.SetSelectedIndex(StartingIndex);

	SlotsList.bLoopSelection = true;
	SlotsList.Navigator.LoopSelection = true;
	CustomizeList.DisableNavigation(); 
	for( i = 0; i < Data.Length; i++ )
	{
		ListItemString = UIListItemString(SlotsList.GetItem(i));
		if(ListItemString != none)
		{
			ListItemString.SetText(Data[i]);
			if(_ConfirmButtonLabel != "")
				ListItemString.SetConfirmButtonStyle(eUIConfirmButtonStyle_Default, _ConfirmButtonLabel,,, ConfirmButtonClicked);
		}
	}
}

simulated function ConfirmButtonClicked(UIButton Button)
{
	if(SlotsList.SelectedIndex != -1 && OnConfirmButtonClicked != none)
		OnConfirmButtonClicked(SlotsList, SlotsList.SelectedIndex);
}

simulated function OnCancel()
{
	if(StartingIndex != -1 && OnItemClicked != none)
		OnItemClicked(SlotsList, StartingIndex);
	CloseScreen();
}

simulated function OnClickLocal(UIList _list, int itemIndex)
{
	OnItemClicked(_list, itemIndex);
	CloseScreen();
}

simulated function OnDoubleClickLocal(UIList _list, int itemIndex)
{
	OnItemClicked(_list, itemIndex);
	CloseScreen();
}

simulated function bool IsAllowedToCycleSoldiers()
{
	return bAllowedToCycleSoldiers;
}

simulated function OnAccept()
{
	//Because of UScript inheritance rules, we need to call OnItemClicked from within UIArmory_WeaponTrait (it's a delegate here, and not in the parent)
	if(SlotsList.SelectedIndex != -1 && OnItemClicked != none)
		OnItemClicked(SlotsList, SlotsList.SelectedIndex);

	CloseScreen();
}
//==============================================================================

defaultproperties
{
	bAllowedToCycleSoldiers = true;
	bConsumeMouseEvents = false;
}
