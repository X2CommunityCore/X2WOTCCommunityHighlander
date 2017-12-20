//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory_Loadout_MP.uc
//  AUTHOR:  Todd Smith  --  7/17/2015
//  PURPOSE: This file is used for the following stuff..blah
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIArmory_Loadout_MP extends UIArmory_Loadout;

var X2MPShellManager m_kMPShellManager;
var UIMPShell_SquadCostPanel_LocalPlayer m_kLocalPlayerInfo;

var localized string m_strStripItemsConfirm;
var localized string m_strStripItemsConfirmDesc;

simulated function InitArmory_MP(X2MPShellManager ShellManager, XComGameState StartState, StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false)
{
	local int i;
	local UIArmory_LoadoutItem Item;
	
	m_kMPShellManager = ShellManager;
	super.InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, StartState);
	m_kMPShellManager.PopulateInventoryForSoldier(UnitRef, CheckGameState);
	
	m_kLocalPlayerInfo = Spawn(class'UIMPShell_SquadCostPanel_LocalPlayer', Movie.Pres.m_kNavHelpScreen);
	m_kLocalPlayerInfo.InitLocalPlayerSquadCostPanel(m_kMPShellManager, CheckGameState);
	m_kLocalPlayerInfo.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_CENTER);
	m_kLocalPlayerInfo.SetPosition(-250, 0);

	for(i = 0; i < EquippedList.ItemCount; ++i)
	{
		Item = UIArmory_LoadoutItem(EquippedList.GetItem(i));
		if(Item.EquipmentSlot == eInvSlot_Utility && !GetUnit().ItemIsInMPBaseLoadout(Item.ItemTemplate.DataName))
			bItemsStripped = Item.ItemRef.ObjectID <= 0;	
	}

	m_strMakeAvailable = class'UIArmory_LoadoutItem'.default.m_strDropItem; //handled in UIArmory_Loadout
	UpdateNavHelp();
}

simulated function OnStripItemsDialogCallback(Name eAction)
{
	local StateObjectReference PrevItemRef;
	local XComGameState_Item PrevItem;
	local XComGameState_Unit UpdatedUnit;
	local int i;
	local UIArmory_LoadoutItem Item;

	if(eAction == 'eUIAction_Accept')
	{
		UpdatedUnit = GetUnit();
		
		for(i = 0; i < EquippedList.ItemCount; ++i)
		{
			Item = UIArmory_LoadoutItem(EquippedList.GetItem(i));
			if(Item.EquipmentSlot == eInvSlot_Utility && !UpdatedUnit.ItemIsInMPBaseLoadout(Item.ItemTemplate.DataName))
				PrevItemRef = Item.ItemRef;	
		}

		PrevItem = XComGameState_Item(CheckGameState.GetGameStateForObjectID(PrevItemRef.ObjectID));
		if(PrevItem != none)
		{
			CheckGameState.RemoveStateObject(PrevItemRef.ObjectID);
			UpdatedUnit.RemoveItemFromInventory(PrevItem, CheckGameState);
		}

		m_kLocalPlayerInfo.SetPlayerLoadout(CheckGameState);

		bItemsStripped = true;
		UpdateNavHelp();
		UpdateLockerList();
		UpdateEquippedList();
		ChangeActiveList(EquippedList);
	}
}

function GetInventory(out array<StateObjectReference> Inventory)
{
	Inventory = m_kMPShellManager.m_arrUnitInventory;
}

function bool GetItemFromInventory(XComGameState AddToGameState, StateObjectReference ItemRef, out XComGameState_Item ItemState)
{
	local XComGameState_Item InventoryItemState;

	InventoryItemState = XComGameState_Item(CheckGameState.GetGameStateForObjectID(ItemRef.ObjectID));
	ItemState = InventoryItemState.GetMyTemplate().CreateInstanceFromTemplate(AddToGameState);

	return true;
}

//---------------------------------------------------------------------------------------
// returns true if HQ has been modified (you need to update the gamestate)
function bool PutItemInInventory(XComGameState AddToGameState, XComGameState_Item ItemState, optional bool bLoot = false)
{
	return true;
}

// MP has no strategry requirements. return true so we can use the calling superclass (singleplayer) functions -tsmith
function bool MeetsAllStrategyRequirements(StrategyRequirement Requirement)
{
	return true;
}

// MP has no display requirements. return true so we can use the calling superclass (singleplayer) functions
function bool MeetsDisplayRequirement(X2ItemTemplate ItemTemplate)
{
	return true;
}

simulated function UpdateNavHelp()
{
	if(bUseNavHelp)
	{
		NavHelp.ClearButtonHelp();
		NavHelp.bIsVerticalHelp = false;
		NavHelp.AddBackButton(OnCancel);
		NavHelp.AddSelectNavHelp();
		
		if(`ISCONTROLLERACTIVE)	
			NavHelp.AddCenterHelp(m_strRotateNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RSTICK); // bsg-jrebar (5/23/17) Removed button inlining
	
		UpdateNavHelp_LoadoutItem(); //(handled in UIArmory_Loadout) ADDING_NAVHELP_DROPITEM JTA 2016/5/28
		NavHelp.Show();
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_X :
		if (UIArmory_LoadoutItem(EquippedList.GetSelectedItem()) != None)
			UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).OnDropItemClicked(None);
		return true;
	}

	return super(UIArmory).OnUnrealCommand(cmd, arg);
}

simulated function OnSelectionChanged(UIList ContainerList, int ItemIndex)
{
	super.OnSelectionChanged(ContainerList, ItemIndex);
	Header.PopulateData(GetUnit(), , , CheckGameState);
}

simulated function ChangeActiveList(UIList kActiveList, optional bool bSkipAnimation)
{
	super.ChangeActiveList(kActiveList, bSkipAnimation);
	Header.PopulateData(GetUnit(), , , CheckGameState);
}

simulated function UpdateEquippedList()
{
	local int i, NumUtilitySlots;
	local UIArmory_LoadoutItem Item;
	local XComGameState_Unit UpdatedUnit;

	super.UpdateEquippedList();

	UpdatedUnit = GetUnit();
	Header.PopulateData(UpdatedUnit, , , CheckGameState);

	// Lock all options except the one editable utility slot
	for(i = 0; i < EquippedList.ItemCount; ++i)
	{
		Item = UIArmory_LoadoutItem(EquippedList.GetItem(i));
		if(Item.EquipmentSlot == eInvSlot_Utility)
		{
			NumUtilitySlots++;
			if(NumUtilitySlots > 1 || !UpdatedUnit.ItemIsInMPBaseLoadout(Item.ItemTemplate.DataName))
				Item.SetDisabled(false);
			else
				Item.SetDisabled(true, m_strCannotEdit);

		}
		else
			Item.SetDisabled(true, m_strCannotEdit);
	}
}

simulated function bool EquipItem(UIArmory_LoadoutItem Item)
{
	local StateObjectReference PrevItemRef, NewItemRef;
	local XComGameState_Item PrevItem, NewItem;
	local bool CanEquip, EquipSucceeded, AddToFront;
	local array<XComGameState_Item> PrevUtilityItems;
	local XComGameState_Unit UpdatedUnit;

	
	UpdatedUnit = XComGameState_Unit(CheckGameState.ModifyStateObject(class'XComGameState_Unit', GetUnit().ObjectID));

	// Issue #118 -- don't use utility items but the actual slot
	if (class'CHItemSlot'.static.SlotIsMultiItem(GetSelectedSlot()))
	{
		PrevUtilityItems = UpdatedUnit.GetAllItemsInSlot(GetSelectedSlot(), CheckGameState);
	}

	NewItemRef = Item.ItemRef;
	PrevItemRef = UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).ItemRef;
	PrevItem = XComGameState_Item(CheckGameState.GetGameStateForObjectID(PrevItemRef.ObjectID));
	if(PrevItem != none)
	{
		PrevItem = XComGameState_Item(CheckGameState.ModifyStateObject(class'XComGameState_Item', PrevItem.ObjectID));
	}

	CanEquip = ((PrevItem == none || UpdatedUnit.RemoveItemFromInventory(PrevItem, CheckGameState)) && UpdatedUnit.CanAddItemToInventory(Item.ItemTemplate, GetSelectedSlot(), CheckGameState));

	if(CanEquip)
	{
		GetItemFromInventory(CheckGameState, NewItemRef, NewItem);
		NewItem = XComGameState_Item(CheckGameState.ModifyStateObject(class'XComGameState_Item', NewItem.ObjectID));

		// Fix for TTP 473, preserve the order of Utility items
		if(PrevUtilityItems.Length > 0)
		{
			AddToFront = PrevItemRef.ObjectID == PrevUtilityItems[0].ObjectID;
		}

		EquipSucceeded = UpdatedUnit.AddItemToInventory(NewItem, GetSelectedSlot(), CheckGameState, AddToFront);

		if(EquipSucceeded)
		{
			if(X2EquipmentTemplate(Item.ItemTemplate) != none)
			{
				if(X2EquipmentTemplate(Item.ItemTemplate).EquipSound != "")
				{
					`XSTRATEGYSOUNDMGR.PlaySoundEvent(X2EquipmentTemplate(Item.ItemTemplate).EquipSound);
				}
			}
			bItemsStripped = false;
			UpdateNavHelp();
		}
		else
		{
			if(PrevItem != none)
			{
				UpdatedUnit.AddItemToInventory(PrevItem, GetSelectedSlot(), CheckGameState);
			}
		}
	}
	
	m_kLocalPlayerInfo.SetPlayerLoadout(CheckGameState);
	return EquipSucceeded;
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	local Rotator CachedSoldierRotation;

	if(ContainerList != ActiveList) return;

	// @JoeC: i'm just disabling click actions on non-utility item slots. as they are the only one that can be changed/equiped. not sure what how you guys want to show this. -tsmith
	if(UIArmory_LoadoutItem(ContainerList.GetItem(ItemIndex)).IsDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}

	if(ContainerList == EquippedList)
	{
		UpdateLockerList();
		ChangeActiveList(LockerList);
	}
	else
	{
		ChangeActiveList(EquippedList);

		if(EquipItem(UIArmory_LoadoutItem(LockerList.GetSelectedItem())))
		{
			CachedSoldierRotation = ActorPawn.Rotation;

			// Release soldier pawn to force it to be re-created when armor changes
			if(GetSelectedSlot() == eInvSlot_Armor)
				ReleasePawn(true);

			UpdateLockerList();
			UpdateEquippedList();
			CreateSoldierPawn(CachedSoldierRotation);
			Header.PopulateData(GetUnit(), , , CheckGameState);

			if(`ScreenStack.GetFirstInstanceOf(class'UIMPShell_SquadEditor') != none)
				UIMPShell_SquadEditor(`ScreenStack.GetFirstInstanceOf(class'UIMPShell_SquadEditor')).OnUnitDirtied(GetUnit());
		}
	}
}

function int GetNumAllowedUtilityItems()
{
	// units can have multiple utility items
	return GetUnit().GetMPCharacterTemplate().NumUtilitySlots;
}

simulated function SetUnitReference(StateObjectReference NewUnitRef)
{
	// NOTE: don't call super functions we are special MP shell code and dont need to muck with gameset rules and history validation. -tsmith
	UnitReference = NewUnitRef;
	MC.FunctionVoid("animateIn");
}

function XComGameState_Item GetItemFromHistory(int ObjectID)
{
	return XComGameState_Item(CheckGameState.GetGameStateForObjectID(ObjectID));
}

simulated function XComGameState_Unit GetUnit()
{
	return XComGameState_Unit(CheckGameState.GetGameStateForObjectID(UnitReference.ObjectID));
}

function XComGameState_Unit GetUnitFromHistory(int ObjectID)
{
	return XComGameState_Unit(CheckGameState.GetGameStateForObjectID(ObjectID));
}

simulated function Remove()
{
	super.Remove();
	m_kLocalPlayerInfo.Remove();
}

defaultproperties
{
	bUseNavHelp = true;
	m_bAllowAbilityToCycle = false;
}