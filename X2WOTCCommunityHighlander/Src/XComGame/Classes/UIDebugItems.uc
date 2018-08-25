//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDebugItems
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: Provides an interface allowing the currently selected unit's load out to be
//			 arbitrarily modified
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDebugItems extends UIScreen dependson(XGTacticalGameCore);

var private UIPanel GeneralContainer;
var private UIBGBox BackgroundPanel;
var private UIButton CloseButton;
var private UIButton GiveItemButton;
var private UIButton GiveUpgradeButton;
var private UIButton ClearUpgradesButton;
var private UIDropdown TypeDropdown;
var private UIDropdown ItemDropdown;
var private UIDropdown UpgradeDropdown;

var name StoredInputState;
var bool bStoredMouseIsActive;

var bool bClearUpgradeMode;

var X2Camera_Fixed LookatWeapon;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	super.InitScreen(InitController, InitMovie, InitName);

	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();

	StoredInputState = XComTacticalController(GetALocalPlayerController()).GetInputState();
	XComTacticalController(GetALocalPlayerController()).SetInputState('InTransition');

	GeneralContainer = Spawn(class'UIPanel', self);
	GeneralContainer.SetPosition(0, 0);
	GeneralContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);	

	BackgroundPanel = Spawn(class'UIBGBox', self);
	BackgroundPanel.InitBG('', 10, 300, 1280, 400);
	
	UpgradeDropdown = Spawn(class'UIDropdown', self).InitDropdown('', "", DropdownSelectionChange);
	UpgradeDropdown.SetPosition(50, 520);	
	PopulateUpgradeDropdown(UpgradeDropdown);

	ItemDropdown = Spawn(class'UIDropdown', self).InitDropdown('', "", DropdownSelectionChange);
	ItemDropdown.SetPosition(50, 460);		
	PopulateItemDropdown(ItemDropdown, eInvSlot_PrimaryWeapon);	

	TypeDropdown = Spawn(class'UIDropdown', self).InitDropdown('', "", DropdownSelectionChange);
	TypeDropdown.SetPosition(50, 400);	
	PopulateTypeDropdown(TypeDropdown);	

	// Close Button
	CloseButton = Spawn(class'UIButton', self);
	CloseButton.InitButton('closeButton', "CLOSE", OnCloseButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	CloseButton.SetPosition(50, 310);

	GiveItemButton = Spawn(class'UIButton', self);
	GiveItemButton.InitButton('giveItemButton', "GIVE ITEM", OnGiveItemButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	GiveItemButton.SetPosition(400, 450);	

	GiveUpgradeButton = Spawn(class'UIButton', self);
	GiveUpgradeButton.InitButton('giveUpgradeButton', "GIVE UPGRADE", OnGiveUpgradeButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	GiveUpgradeButton.SetPosition(400, 510);	

	ClearUpgradesButton = Spawn(class'UIButton', self);
	ClearUpgradesButton.InitButton('clearUpgradeButton', "CLEAR UPGRADES", OnClearUpgradesButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	ClearUpgradesButton.SetPosition(400, 560);	
}

simulated function OnCloseButtonClicked(UIButton button)
{	
	if( !bStoredMouseIsActive )
	{
		Movie.DeactivateMouse();
	}

	if( LookatWeapon != none )
	{
		`CAMERASTACK.RemoveCamera(LookatWeapon);
	}

	XComTacticalController(GetALocalPlayerController()).SetInputState(StoredInputState);
	Movie.Stack.Pop(self);
}

simulated function OnGiveItemButtonClicked(UIButton button)
{	
	local XComTacticalCheatManager TacticalCheatManager;	

	TacticalCheatManager = `CHEATMGR;	
	TacticalCheatManager.GiveItem( ItemDropdown.GetSelectedItemText() );

	PopulateUpgradeDropdown(UpgradeDropdown);
}

function SaveIntoProfile(int SoldierIndex)
{
	local XComOnlineProfileSettings Profile;		
	local XComGameState ManipulateState;
	local XComGameState_Unit UpdateUnit;
	local int InventoryIndex;
	local int Index;

	Profile = `XPROFILESETTINGS;
	ManipulateState = `PRES.TacticalStartState;
	
	// Grab the start state from the profile
	ManipulateState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Singleplayer();	
	Profile.ReadTacticalGameStartState(ManipulateState);

	Index = 0;
	foreach ManipulateState.IterateByClassType(class'XComGameState_Unit', UpdateUnit)
	{
		if( Index == SoldierIndex )
		{
			//Remove this unit from the game state
			for( InventoryIndex = 0; InventoryIndex < UpdateUnit.InventoryItems.Length; ++InventoryIndex )
			{
				ManipulateState.PurgeGameStateForObjectID(UpdateUnit.InventoryItems[InventoryIndex].ObjectID);
			}
			ManipulateState.PurgeGameStateForObjectID(UpdateUnit.ObjectID);

			//Add a copy of the passed in unit
		}
	}
}

simulated function OnClearUpgradesButtonClicked(UIButton button)
{
	bClearUpgradeMode = true;
	OnGiveUpgradeButtonClicked(button);
	bClearUpgradeMode = false;
}

simulated function OnGiveUpgradeButtonClicked(UIButton button)
{	
	local XComGameStateHistory History;
	local XComGameState_Item WeaponStateObject;	
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState ChangeState;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local StateObjectReference ActiveUnitRef;
	local XComGameState_Unit UnitState;
	local XGWeapon WeaponVisualizer;
	local XGUnit UnitVisualizer;	

	History = `XCOMHISTORY;
	
	ActiveUnitRef = XComTacticalController(PC).GetActiveUnitStateRef();
	if( ActiveUnitRef.ObjectID > 0 && UpgradeDropdown.SelectedItem > -1 )
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActiveUnitRef.ObjectID));
		WeaponStateObject = UnitState.GetItemInSlot( eInvSlot_PrimaryWeapon );	
		
		UpgradeTemplate = X2WeaponUpgradeTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(UpgradeDropdown.GetSelectedItemData())));
		if (bClearUpgradeMode || (UpgradeTemplate != none && UpgradeTemplate.CanApplyUpgradeToWeapon(WeaponStateObject)))
		{
			// Create change context
			ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Weapon Upgrade");
			ChangeState = History.CreateNewGameState(true, ChangeContainer);

			// Apply upgrade to weapon
			WeaponStateObject = XComGameState_Item(ChangeState.ModifyStateObject(class'XComGameState_Item', WeaponStateObject.ObjectID));
			if( bClearUpgradeMode )
			{
				WeaponStateObject.WipeUpgradeTemplates();
			}
			else
			{
				WeaponStateObject.ApplyWeaponUpgradeTemplate(UpgradeTemplate);
			}

			`GAMERULES.SubmitGameState(ChangeState);

			UnitVisualizer = XGUnit(History.GetVisualizer(UnitState.ObjectID));
			WeaponVisualizer = XGWeapon(History.GetVisualizer(WeaponStateObject.ObjectID));
			if( WeaponVisualizer != none )
			{
				//Kill the weapon's visualizer then recreate it
				WeaponVisualizer.Destroy();
				History.SetVisualizer(WeaponStateObject.ObjectID, none);
				UnitVisualizer.ApplyLoadoutFromGameState(UnitState, ChangeState);								
			}
		}
	}

	PopulateUpgradeDropdown(UpgradeDropdown);
}

simulated function DropdownSelectionChange(UIDropdown kDropdown)
{
	switch(kDropdown)
	{
	case TypeDropdown:
		PopulateItemDropdown(ItemDropdown, EInventorySlot(TypeDropdown.SelectedItem));
		break;
	case ItemDropdown:			
		break;
	}
}

simulated function PopulateUpgradeDropdown(UIDropdown kDropdown)
{
	local int Index;
	local StateObjectReference ActiveUnitRef;
	local XComGameState_Unit UnitState;
	local XComGameState_Item WeaponStateObject;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;

	kDropdown.Clear(); // empty dropdown	

	WeaponUpgrades = class'X2ItemTemplateManager'.static.GetItemTemplateManager().GetAllUpgradeTemplates();	

	ActiveUnitRef = XComTacticalController(PC).GetActiveUnitStateRef();
	if( ActiveUnitRef.ObjectID > 0 )
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnitRef.ObjectID));
		WeaponStateObject = UnitState.GetItemInSlot( eInvSlot_PrimaryWeapon );
	}

	for( Index = 0; Index < WeaponUpgrades.Length; ++Index )
	{
		//If there is a primary weapon on this unit, limit the upgrades to those which are valid for this weapon
	if( WeaponStateObject != none && WeaponStateObject.ObjectID > 0 && !WeaponUpgrades[Index].CanApplyUpgradeToWeapon(WeaponStateObject) && !WeaponStateObject.CanWeaponApplyUpgrade(WeaponUpgrades[Index]) ) // Issue #260
		{
			continue;
		}

		kDropdown.AddItem(WeaponUpgrades[Index].GetItemFriendlyName(), string(WeaponUpgrades[Index].DataName));
	}

	if( kDropdown.Items.Length > 0 )
	{
		kDropdown.SetSelected( 0 );
	}	
	else
	{
		kDropdown.AddItem("Upgrades Full", "Upgrades Full");
		kDropdown.SetSelected( 0 );
	}
}

simulated function PopulateTypeDropdown(UIDropdown kDropdown)
{
	local int Index;
	local string SlotName;
	local EInventorySlot Slot;
	
	for( Index = 0; Index < eInvSlot_MAX; ++Index )
	{
		Slot = EInventorySlot(Index);
		SlotName = string(Slot);
		kDropdown.AddItem(SlotName, string(Index));
	}

	kDropdown.SetSelected( eInvSlot_PrimaryWeapon );
}

simulated function PopulateItemDropdown(UIDropdown kDropdown, EInventorySlot eEquipmentType)
{
	local X2DataTemplate kEquipmentTemplate;
	local XComGameState_Unit UnitState;
	local XComGameState_Item SlotItem;
	local StateObjectReference ActiveUnitRef;	
	local XComGameStateHistory History;	

	local TPOV CameraView;
	local Rotator CameraRotation;
	local Vector OffsetVector;
	local XGUnit UnitVisualizer;
	local XComUnitPawn Pawn;
	local XGWeapon WeaponVisualizer;
	local XComWeapon WeaponModel;
	local Vector WeaponAttachLocation;
	local Rotator WeaponAttachRotation;

	kDropdown.Clear(); // empty dropdown	

	History = `XCOMHISTORY;

	ActiveUnitRef = XComTacticalController(PC).GetActiveUnitStateRef();
	if( ActiveUnitRef.ObjectID > 0 && 
		(eEquipmentType != eInvSlot_Backpack && eEquipmentType != eInvSlot_Utility) )
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActiveUnitRef.ObjectID));
		SlotItem = UnitState.GetItemInSlot( EInventorySlot(eEquipmentType) );		
		
		UnitVisualizer = XGUnit(History.GetVisualizer(ActiveUnitRef.ObjectID));
		WeaponVisualizer = XGWeapon(History.GetVisualizer(SlotItem.ObjectID));
		if( UnitVisualizer != none && WeaponVisualizer != none )
		{
			LookatWeapon = new class'X2Camera_Fixed';					

			Pawn = UnitVisualizer.GetPawn();

			CameraRotation = Pawn.Rotation;
			CameraRotation.Pitch = 0;
			CameraRotation.Yaw += DegToUnrRot * 220;
			
			OffsetVector = Vector(CameraRotation) * -1.0f;			
			CameraView.Location = Pawn.Location + (OffsetVector * 70.0f);
			WeaponModel = XComWeapon(WeaponVisualizer.m_kEntity);
			if( WeaponModel != none && WeaponModel.DefaultSocket != '' )
			{
				Pawn.Mesh.GetSocketWorldLocationAndRotation(WeaponModel.DefaultSocket, WeaponAttachLocation, WeaponAttachRotation);
				CameraView.Location.Z = WeaponAttachLocation.Z;
			}
			else
			{
				CameraView.Location.Z += 20.0f;
			}
			CameraView.Rotation = CameraRotation;			

			LookatWeapon.SetCameraView( CameraView );
			LookatWeapon.Priority = eCameraPriority_Cinematic;
			`CAMERASTACK.AddCamera(LookatWeapon);
		}
	}

	foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(kEquipmentTemplate, none)
	{
		if( X2EquipmentTemplate(kEquipmentTemplate) != none &&
			X2EquipmentTemplate(kEquipmentTemplate).iItemSize > 0 &&  // xpad is only item with size 0, that is always equipped
			X2EquipmentTemplate(kEquipmentTemplate).InventorySlot == eEquipmentType)
		{
			kDropdown.AddItem(string(kEquipmentTemplate.DataName), string(kEquipmentTemplate.DataName));

			if (kEquipmentTemplate.DataName == SlotItem.GetMyTemplateName())
				kDropdown.SetSelected(kDropdown.items.Length - 1);
		}
	}

	if( kDropdown.SelectedItem < 0 )
	{
		kDropdown.SetSelected(0);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
			//OnButtonClicked(m_kCloseButton);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:		
			//OnUAccept();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

simulated function OnReceiveFocus()
{
	Show();
}

simulated function OnLoseFocus()
{
	Hide();
}

defaultproperties
{
	MCName          = "theScreen";
	InputState    = eInputState_Evaluate;
}