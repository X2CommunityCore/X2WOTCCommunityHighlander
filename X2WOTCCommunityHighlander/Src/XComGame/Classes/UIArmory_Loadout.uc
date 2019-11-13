//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory_Loadout
//  AUTHOR:  Sam Batista
//  PURPOSE: UI for viewing and modifying a Soldiers equipment
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIArmory_Loadout extends UIArmory;

struct TUILockerItem
{
	var bool CanBeEquipped;
	var string DisabledReason;
	var XComGameState_Item Item;
};

var UIList ActiveList;

var UIPanel EquippedListContainer;
var UIList EquippedList;

var UIPanel LockerListContainer;
var UIList LockerList;

var UIArmory_LoadoutItemTooltip InfoTooltip;

var array<EInventorySlot> CannotEditSlotsList;

var localized string m_strInventoryTitle;
var localized string m_strLockerTitle;
var localized string m_strInventoryLabels[EInventorySlot.EnumCount]<BoundEnum=EInventorySlot>;
var localized string m_strNeedsSoldierClass;
var localized string m_strUnavailableToClass;
var localized string m_strAmmoIncompatible;
var localized string m_strCategoryRestricted;
var localized string m_strMissingAllowedClass;
var localized string m_strTooltipStripItems;
var localized string m_strTooltipStripItemsDisabled;
var localized string m_strTooltipStripGear;
var localized string m_strTooltipStripGearDisabled;
var localized string m_strTooltipStripWeapons;
var localized string m_strTooltipStripWeaponsDisabled;
var localized string m_strCannotEdit;
var localized string m_strMakeAvailable;
var localized string m_strNeedsLadderUnlock;

var XGParamTag LocTag; // optimization
var bool bGearStripped;
var bool bItemsStripped;
var bool bWeaponsStripped;
var array<StateObjectReference> StrippedUnits;
var bool bTutorialJumpOut;

simulated function InitArmory(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	Movie.PreventCacheRecycling();

	super.InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, InitCheckGameState);

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	InitializeTooltipData();
	InfoTooltip.SetPosition(1250, 430);

	MC.FunctionString("setLeftPanelTitle", m_strInventoryTitle);

	EquippedListContainer = Spawn(class'UIPanel', self);
	EquippedListContainer.bAnimateOnInit = false;
	EquippedListContainer.InitPanel('leftPanel');
	EquippedList = CreateList(EquippedListContainer);
	EquippedList.OnSelectionChanged = OnSelectionChanged;
	EquippedList.OnItemClicked = OnItemClicked;
	EquippedList.OnItemDoubleClicked = OnItemClicked;

	LockerListContainer = Spawn(class'UIPanel', self);
	LockerListContainer.bAnimateOnInit = false;
	LockerListContainer.InitPanel('rightPanel');
	LockerList = CreateList(LockerListContainer);
	LockerList.OnSelectionChanged = OnSelectionChanged;
	LockerList.OnItemClicked = OnItemClicked;
	LockerList.OnItemDoubleClicked = OnItemClicked;

	PopulateData();
}

simulated function PopulateData()
{
	CreateSoldierPawn();
	UpdateEquippedList();
	UpdateLockerList();
	ChangeActiveList(EquippedList, true);
}

simulated function bool CanCancel()
{
	if (ActiveList == EquippedList)
	{
		if (!Movie.Pres.ScreenStack.HasInstanceOf(class'UISquadSelect') || 
			class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') != eObjectiveState_InProgress)
		{
			return true;
		}

		return false;
	}

	return true;
}

simulated function UpdateNavHelp()
{
	// bsg-jrebar (4/26/17): Armory UI consistency changes, centering buttons, fixing overlaps
	// Adding super class nav help calls to this class so help can be made vertical
	local int i;
	local string PrevKey, NextKey;

	if(bUseNavHelp)
	{
		NavHelp.ClearButtonHelp();
		NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;

		if (CanCancel())
		{
			NavHelp.AddBackButton(OnCancel);
		}

		NavHelp.AddSelectNavHelp(); // bsg-jrebar (4/12/17): Moved Select Nav Help
		
		if(XComHQPresentationLayer(Movie.Pres) != none)
		{
			LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_PrevUnit);
			PrevKey = `XEXPAND.ExpandString(PrevSoldierKey);
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_NextUnit);
			NextKey = `XEXPAND.ExpandString(NextSoldierKey);

			// Don't allow jumping to the geoscape from the armory in the tutorial or when coming from squad select
			if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') != eObjectiveState_InProgress &&
				RemoveMenuEvent == '' && NavigationBackEvent == '' && !`ScreenStack.IsInStack(class'UISquadSelect'))
			{
				NavHelp.AddGeoscapeButton();
			}

			if( Movie.IsMouseActive() && IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo) )
			{
				NavHelp.SetButtonType("XComButtonIconPC");
				i = eButtonIconPC_Prev_Soldier;
				NavHelp.AddCenterHelp( string(i), "", PrevSoldier, false, PrevKey);
				i = eButtonIconPC_Next_Soldier; 
				NavHelp.AddCenterHelp( string(i), "", NextSoldier, false, NextKey);
				NavHelp.SetButtonType("");
			}
		}

		if (`ISCONTROLLERACTIVE && 
			XComHQPresentationLayer(Movie.Pres) != none && IsAllowedToCycleSoldiers() && 
			class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo) &&
			//<bsg> 5435, ENABLE_NAVHELP_DURING_TUTORIAL, DCRUZ, 2016/06/23
			//INS:
			class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory'))
			//</bsg>
		{
			NavHelp.AddCenterHelp(m_strTabNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LBRB_L1R1); // bsg-jrebar (5/23/17): Removing inlined buttons
		}
		
		if( `ISCONTROLLERACTIVE )
			NavHelp.AddCenterHelp(m_strRotateNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RSTICK); // bsg-jrebar (5/23/17): Removing inlined buttons

		// bsg-jrebar (5/3/17): On M/K, all the buttons, else simplfy for some space savings
		if(!`ISCONTROLLERACTIVE)
		{
			if(bItemsStripped)
			{
				NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripItems, "", none, true, m_strTooltipStripItemsDisabled, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
			}
			else
			{
				NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripItems, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LT_L2, OnStripItems, false, m_strTooltipStripItems, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
			}
		
			if (bWeaponsStripped)
			{
				NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripWeapons, "", none, true, m_strTooltipStripWeaponsDisabled, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
			}
			else
			{
				NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripWeapons, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RSCLICK_R3, OnStripWeapons, false, m_strTooltipStripWeapons, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
			}

			if(bGearStripped)
			{
				NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripGear, "", none, true, m_strTooltipStripGearDisabled, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
			}
			else
			{
				NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripGear, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RT_R2, OnStripGear, false, m_strTooltipStripGear, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
			}
		}
		else
		{
			if (!`ISCONSOLE)
			{
				if (!bItemsStripped)
					NavHelp.AddLeftHelp(Caps(class'UISquadSelect'.default.m_strStripItems), class'UIUtilities_Input'.const.ICON_LT_L2);

				if (!bGearStripped)
					NavHelp.AddLeftHelp(Caps(class'UISquadSelect'.default.m_strStripGear), class'UIUtilities_Input'.const.ICON_RT_R2);

				if (!bWeaponsStripped)
					NavHelp.AddLeftHelp(Caps(class'UISquadSelect'.default.m_strStripWeapons), class'UIUtilities_Input'.const.ICON_RSCLICK_R3);
			}
			else
			{
				NavHelp.AddLeftHelp(Caps(class'UIManageEquipmentMenu'.default.m_strTitleLabel), class'UIUtilities_Input'.const.ICON_LT_L2);
				UpdateNavHelp_LoadoutItem();
			}
		}
		// bsg-jrebar (5/3/17): end

		NavHelp.Show();
	}
	// bsg-jrebar (4/26/17): end
}

//This function handles Item-specific NavHelp, based on the currently selected item
simulated function UpdateNavHelp_LoadoutItem()
{
	local UIArmory_LoadoutItem Item;

	if(NavHelp != None && bUseNavHelp && EquippedList != None) // bsg-dforrest (7.15.16): null access warnings
	{
		Item = UIArmory_LoadoutItem(EquippedList.GetSelectedItem());
		if(Item != None && Item.bCanBeCleared && ActiveList == EquippedList)
		{
			NavHelp.AddLeftHelp(m_strMakeAvailable,class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
		}
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	//bsg-jedwards (3.21.17) : Set conditional to differ between console and PC for Manage Equipment Menu
	if(!`ISCONSOLE)
	{
		switch( cmd )
		{
			case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:
				if(!bItemsStripped)
					OnStripItems();
				return true;
			case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER :
				if( !bGearStripped )
					OnStripGear();
				return true;
			case class'UIUtilities_Input'.const.FXS_BUTTON_R3 :
				if( !bWeaponsStripped )
					OnStripWeapons();
				return true;
		}	
	}
	else
	{
		switch( cmd )
		{
			case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:
				OnManageEquipmentPressed();
				return true;
		}
	}

	if (cmd == class'UIUtilities_Input'.const.FXS_BUTTON_X)
	{
		if (UIArmory_LoadoutItem(EquippedList.GetSelectedItem()) != none &&
			UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).bCanBeCleared)
		{
			UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).OnDropItemClicked(none);
		}
		return true;
	}
	//bsg-jedwards (3.21.17) : end
	

	return super.OnUnrealCommand(cmd, arg);
}

//bsg-jedwards (3.21.17) : Function added to create the Manage Equipment Menu
simulated function OnManageEquipmentPressed()
{
	local UIManageEquipmentMenu TempScreen;
	local UISquadSelect SquadSelect;

	SquadSelect = UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
	if(SquadSelect != none)
	{
		SquadSelect.OnManageEquipmentPressed();
	}
	else
	{
		TempScreen = Spawn(class'UIManageEquipmentMenu', Movie.Pres);
		TempScreen.AddItem(class'UISquadSelect'.default.m_strStripItems, OnStripItems);
		TempScreen.AddItem(class'UISquadSelect'.default.m_strStripGear, OnStripGear);
		TempScreen.AddItem(class'UISquadSelect'.default.m_strStripWeapons, OnStripWeapons);
		if(Movie != none)
		{
			Movie.Pres.ScreenStack.Push(TempScreen);
		}
		else
		{
			`SCREENSTACK.Push(TempScreen);
		}
	}

	InfoTooltip.currentPath = string(ActiveList.GetSelectedItem().MCPath);
	InfoTooltip.ShowTooltip();
}
//bsg-jedwards (3.21.17) : end

simulated function OnStripItems()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = class'UISquadSelect'.default.m_strStripItemsConfirm;
	DialogData.strText = class'UISquadSelect'.default.m_strStripItemsConfirmDesc;
	DialogData.fnCallback = OnStripItemsDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
	InfoTooltip.currentPath = string(ActiveList.GetSelectedItem().MCPath);
	InfoTooltip.ShowTooltip();
	NavHelp.ClearButtonHelp();
}
simulated function OnStripItemsDialogCallback(Name eAction)
{
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState NewGameState;
	local int idx;

	if(eAction == 'eUIAction_Accept')
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Gear");
		Soldiers = GetSoldiersToStrip();

		// Issue #118 Start
		//RelevantSlots.AddItem(eInvSlot_Utility);
		//RelevantSlots.AddItem(eInvSlot_GrenadePocket);
		//RelevantSlots.AddItem(eInvSlot_AmmoPocket);
		class'CHItemSlot'.static.CollectSlots(class'CHItemSlot'.const.SLOT_ITEM, RelevantSlots);
		// Issue #118 End

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UnitState.MakeItemsAvailable(NewGameState, true, RelevantSlots);
			
			if(StrippedUnits.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
			{
				StrippedUnits.AddItem(UnitState.GetReference());
			}
		}

		`GAMERULES.SubmitGameState(NewGameState);

		bItemsStripped = true;
		//UpdateNavHelp();
		UpdateLockerList();
	}
	UpdateNavHelp();
}

simulated function OnStripGear()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = class'UISquadSelect'.default.m_strStripGearConfirm;
	DialogData.strText = class'UISquadSelect'.default.m_strStripGearConfirmDesc;
	DialogData.fnCallback = OnStripGearDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
	InfoTooltip.currentPath = string(ActiveList.GetSelectedItem().MCPath);
	InfoTooltip.ShowTooltip();
	NavHelp.ClearButtonHelp();
}
simulated function OnStripGearDialogCallback(Name eAction)
{
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState NewGameState;
	local int idx;

	if(eAction == 'eUIAction_Accept')
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Gear");
		Soldiers = GetSoldiersToStrip();

		// Issue #118 Start
		//RelevantSlots.AddItem(eInvSlot_Armor);
		//RelevantSlots.AddItem(eInvSlot_HeavyWeapon);
		class'CHItemSlot'.static.CollectSlots(class'CHItemSlot'.const.SLOT_ARMOR, RelevantSlots);
		// Issue #118 End

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UnitState.MakeItemsAvailable(NewGameState, true, RelevantSlots);

			if(StrippedUnits.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
			{
				StrippedUnits.AddItem(UnitState.GetReference());
			}
		}

		`GAMERULES.SubmitGameState(NewGameState);

		bGearStripped = true;
		//UpdateNavHelp();
		UpdateLockerList();
	}
}

simulated function OnStripWeapons()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = class'UISquadSelect'.default.m_strStripWeaponsConfirm;
	DialogData.strText = class'UISquadSelect'.default.m_strStripWeaponsConfirmDesc;
	DialogData.fnCallback = OnStripWeaponsDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
	InfoTooltip.currentPath = string(ActiveList.GetSelectedItem().MCPath);
	InfoTooltip.ShowTooltip();
	NavHelp.ClearButtonHelp();
}
simulated function OnStripWeaponsDialogCallback(Name eAction)
{
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState NewGameState;
	local int idx;

	if (eAction == 'eUIAction_Accept')
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Gear");
		Soldiers = GetSoldiersToStrip();

		// Issue #118 Start
		//RelevantSlots.AddItem(eInvSlot_PrimaryWeapon);
		//RelevantSlots.AddItem(eInvSlot_SecondaryWeapon);
		//RelevantSlots.AddItem(eInvSlot_HeavyWeapon);
		class'CHItemSlot'.static.CollectSlots(class'CHItemSlot'.const.SLOT_WEAPON, RelevantSlots);
		// Issue #118 End

		for (idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			UnitState.MakeItemsAvailable(NewGameState, true, RelevantSlots);

			if (StrippedUnits.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
			{
				StrippedUnits.AddItem(UnitState.GetReference());
			}
		}

		`GAMERULES.SubmitGameState(NewGameState);

		bWeaponsStripped = true;
		//UpdateNavHelp();
		UpdateLockerList();
	}
	UpdateNavHelp();
}

simulated function ResetAvailableEquipment()
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local int idx;

	bGearStripped = false;
	bItemsStripped = false;
	bWeaponsStripped = false;

	if(StrippedUnits.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Available Equipment");

		for(idx = 0; idx < StrippedUnits.Length; idx++)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', StrippedUnits[idx].ObjectID));
			UnitState.EquipOldItems(NewGameState);
		}

		`GAMERULES.SubmitGameState(NewGameState);
	}

	StrippedUnits.Length = 0;
	UpdateNavHelp();
	UpdateLockerList();
}

simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local UIArmory_Loadout LoadoutScreen;
	local UIScreenStack ScreenStack;

	ScreenStack = `SCREENSTACK;
	LoadoutScreen = UIArmory_Loadout(ScreenStack.GetScreen(class'UIArmory_Loadout'));

	if(LoadoutScreen != none)
	{
		LoadoutScreen.ResetAvailableEquipment();
	}
	
	super.CycleToSoldier(NewRef);
}

simulated function array<XComGameState_Unit> GetSoldiersToStrip()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit UnitState;
	local bool bSquadSelect;
	local int idx;

	History = `XCOMHISTORY;

	if(StrippedUnits.Length > 0)
	{
		for(idx = 0; idx < StrippedUnits.Length; idx++)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StrippedUnits[idx].ObjectID));
			Soldiers.AddItem(UnitState);
		}
	}
	else
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		
		bSquadSelect = (Movie.Pres.ScreenStack.HasInstanceOf(class'UISquadSelect'));
		Soldiers = XComHQ.GetSoldiers(bSquadSelect, true);

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			if(Soldiers[idx].ObjectID == GetUnitRef().ObjectID)
			{
				Soldiers.Remove(idx, 1);
				break;
			}
		}
	}

	return Soldiers;
}

simulated function LoadSoldierEquipment()
{
	XComUnitPawn(ActorPawn).CreateVisualInventoryAttachments(Movie.Pres.GetUIPawnMgr(), GetUnit(), CheckGameState);	
}

// also gets used by UIWeaponList, and UIArmory_WeaponUpgrade
simulated static function UIList CreateList(UIPanel Container)
{
	local UIBGBox BG;
	local UIList ReturnList;

	BG = Container.Spawn(class'UIBGBox', Container).InitBG('BG');

	ReturnList = Container.Spawn(class'UIList', Container);
	ReturnList.bStickyHighlight = false;
	ReturnList.bAutosizeItems = false;
	ReturnList.bAnimateOnInit = false;
	ReturnList.bSelectFirstAvailable = false;
	ReturnList.ItemPadding = 5;
	ReturnList.InitList('loadoutList');

	// this allows us to send mouse scroll events to the list
	BG.ProcessMouseEvents(ReturnList.OnChildMouseEvent);
	return ReturnList;
}

simulated function UpdateEquippedList()
{
	//local int i, numUtilityItems; // Issue #118, unneeded
	local UIArmory_LoadoutItem Item;
	//ocal array<XComGameState_Item> UtilityItems; // Issue #118, unneeded
	local XComGameState_Unit UpdatedUnit;
	local int prevIndex;
	local CHUIItemSlotEnumerator En; // Variable for Issue #118

	prevIndex = EquippedList.SelectedIndex;
	UpdatedUnit = GetUnit();
	EquippedList.ClearItems();

	// Clear out tooltips from removed list items
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(EquippedList.MCPath));

	// Issue #171 Start
	// Realize Inventory so mods changing utility slots get updated faster
	UpdatedUnit.RealizeItemSlotsCount(CheckGameState);
	// Issue #171 End

	// Issue #118 Start
	// Here used to be a lot of code handling individual slots, this has been abstracted in CHItemSlot (and the Enumerator)
	En = class'CHUIItemSlotEnumerator'.static.CreateEnumerator(UpdatedUnit, CheckGameState);
	while (En.HasNext())
	{
		En.Next();
		Item = UIArmory_LoadoutItem(EquippedList.CreateItem(class'UIArmory_LoadoutItem'));
		if (CannotEditSlotsList.Find(En.Slot) != INDEX_NONE)
			Item.InitLoadoutItem(En.ItemState, En.Slot, true, m_strCannotEdit);
		else if (En.IsLocked)
			Item.InitLoadoutItem(En.ItemState, En.Slot, true, En.LockedReason);
		else
			Item.InitLoadoutItem(En.ItemState, En.Slot, true);
	}
	EquippedList.SetSelectedIndex(prevIndex < EquippedList.ItemCount ? prevIndex : 0);
	// Force item into view
	EquippedList.NavigatorSelectionChanged(EquippedList.SelectedIndex);
	// Issue #118 End
}

// Issue #118 -- should be obsolete
function int GetNumAllowedUtilityItems()
{
	// units can have multiple utility items
	return GetUnit().GetCurrentStat(eStat_UtilityItems);
}

simulated function UpdateLockerList()
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;
	local EInventorySlot SelectedSlot;
	local array<TUILockerItem> LockerItems;
	local TUILockerItem LockerItem;
	local array<StateObjectReference> Inventory;

	SelectedSlot = GetSelectedSlot();

	// set title according to selected slot
	// Issue #118
	LocTag.StrValue0 = class'CHItemSlot'.static.SlotGetName(SelectedSlot);
	//LocTag.StrValue0 = m_strInventoryLabels[SelectedSlot];
	MC.FunctionString("setRightPanelTitle", `XEXPAND.ExpandString(m_strLockerTitle));

	GetInventory(Inventory);
	foreach Inventory(ItemRef)
	{
		Item = GetItemFromHistory(ItemRef.ObjectID);
		if(ShowInLockerList(Item, SelectedSlot))
		{
			LockerItem.Item = Item;
			LockerItem.DisabledReason = GetDisabledReason(Item, SelectedSlot);
			LockerItem.CanBeEquipped = LockerItem.DisabledReason == ""; // sorting optimization
			LockerItems.AddItem(LockerItem);
		}
	}

	LockerList.ClearItems();

	LockerItems.Sort(SortLockerListByUpgrades);
	LockerItems.Sort(SortLockerListByTier);
	LockerItems.Sort(SortLockerListByEquip);

	foreach LockerItems(LockerItem)
	{
		UIArmory_LoadoutItem(LockerList.CreateItem(class'UIArmory_LoadoutItem')).InitLoadoutItem(LockerItem.Item, SelectedSlot, false, LockerItem.DisabledReason);
	}
	// If we have an invalid SelectedIndex, just try and select the first thing that we can.
	// Otherwise let's make sure the Navigator is selecting the right thing.
	if(LockerList.SelectedIndex < 0 || LockerList.SelectedIndex >= LockerList.ItemCount)
		LockerList.Navigator.SelectFirstAvailable();
	else
	{
		LockerList.Navigator.SetSelected(LockerList.GetSelectedItem());
	}
	OnSelectionChanged(ActiveList, ActiveList.SelectedIndex);
}

function GetInventory(out array<StateObjectReference> Inventory)
{
	Inventory = class'UIUtilities_Strategy'.static.GetXComHQ().Inventory;
}

simulated function bool ShowInLockerList(XComGameState_Item Item, EInventorySlot SelectedSlot)
{
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = Item.GetMyTemplate();
	
	if(MeetsAllStrategyRequirements(ItemTemplate.ArmoryDisplayRequirements) && MeetsDisplayRequirement(ItemTemplate))
	{
		return class'CHItemSlot'.static.SlotShowItemInLockerList(SelectedSlot, GetUnit(), Item, ItemTemplate, CheckGameState);
	}

	return false;
}

// overriden in MP specific classes -tsmith
function bool MeetsAllStrategyRequirements(StrategyRequirement Requirement)
{
	return (class'UIUtilities_Strategy'.static.GetXComHQ().MeetsAllStrategyRequirements(Requirement));
}

// overriden in MP specific classes
function bool MeetsDisplayRequirement(X2ItemTemplate ItemTemplate)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	return (!XComHQ.IsTechResearched(ItemTemplate.HideIfResearched) && !XComHQ.HasItemByName(ItemTemplate.HideIfPurchased));
}

simulated function string GetDisabledReason(XComGameState_Item Item, EInventorySlot SelectedSlot)
{
	local int EquippedObjectID;
	local string DisabledReason;
	local X2ItemTemplate ItemTemplate;
	local X2AmmoTemplate AmmoTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local X2ArmorTemplate ArmorTemplate;
	local X2SoldierClassTemplate SoldierClassTemplate, AllowedSoldierClassTemplate;
	local XComGameState_Unit UpdatedUnit;

	local XComOnlineProfileSettings ProfileSettings;
	local int BronzeScore, HighScore;

	// Variables for Issue #50
	local int i, UnusedOutInt;
  local string DLCReason;
	local array<X2DownloadableContentInfo> DLCInfos;
	
	ItemTemplate = Item.GetMyTemplate();
	UpdatedUnit = GetUnit();
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	
	// Disable the weapon cannot be equipped by the current soldier class
	WeaponTemplate = X2WeaponTemplate(ItemTemplate);
	if(WeaponTemplate != none)
	{
		SoldierClassTemplate = UpdatedUnit.GetSoldierClassTemplate();
		if(SoldierClassTemplate != none && !SoldierClassTemplate.IsWeaponAllowedByClass(WeaponTemplate))
		{
			AllowedSoldierClassTemplate = class'UIUtilities_Strategy'.static.GetAllowedClassForWeapon(WeaponTemplate);
			if(AllowedSoldierClassTemplate == none)
			{
				DisabledReason = m_strMissingAllowedClass;
			}
			else if(AllowedSoldierClassTemplate.DataName == class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)
			{
				LocTag.StrValue0 = SoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strUnavailableToClass));
			}
			else
			{
				LocTag.StrValue0 = AllowedSoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strNeedsSoldierClass));
			}
		}

		// TLE Weapons are locked out unless ladder 1 is completed to a BronzeMedal
		if ((DisabledReason == "") && (WeaponTemplate.ClassThatCreatedUs.Name == 'X2Item_TLE_Weapons'))
		{
			ProfileSettings = `XPROFILESETTINGS;
			BronzeScore = class'XComGameState_LadderProgress'.static.GetLadderMedalThreshold( 1, 0 );
			HighScore = ProfileSettings.Data.GetLadderHighScore( 1 );

			if (BronzeScore > HighScore)
			{
				LocTag.StrValue0 = class'XComGameState_LadderProgress'.default.NarrativeLadderNames[ 1 ];
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strNeedsLadderUnlock));
			}
		}
	}

	ArmorTemplate = X2ArmorTemplate(ItemTemplate);
	if (ArmorTemplate != none)
	{
		SoldierClassTemplate = UpdatedUnit.GetSoldierClassTemplate();
		if (SoldierClassTemplate != none && !SoldierClassTemplate.IsArmorAllowedByClass(ArmorTemplate))
		{
			AllowedSoldierClassTemplate = class'UIUtilities_Strategy'.static.GetAllowedClassForArmor(ArmorTemplate);
			if (AllowedSoldierClassTemplate == none)
			{
				DisabledReason = m_strMissingAllowedClass;
			}
			else if (AllowedSoldierClassTemplate.DataName == class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)
			{
				LocTag.StrValue0 = SoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strUnavailableToClass));
			}
			else
			{
				LocTag.StrValue0 = AllowedSoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strNeedsSoldierClass));
			}
		}

		// TLE Armor is locked unless ladder 2 is completed to a Bronze Medal
		if ((DisabledReason == "") && (ArmorTemplate.ClassThatCreatedUs.Name == 'X2Item_TLE_Armor'))
		{
			ProfileSettings = `XPROFILESETTINGS;
			BronzeScore = class'XComGameState_LadderProgress'.static.GetLadderMedalThreshold( 2, 0 );
			HighScore = ProfileSettings.Data.GetLadderHighScore( 2 );

			if (BronzeScore > HighScore)
			{
				LocTag.StrValue0 = class'XComGameState_LadderProgress'.default.NarrativeLadderNames[ 2 ];
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strNeedsLadderUnlock));
			}
		}
	}

	// Disable if the ammo is incompatible with the current primary weapon
	AmmoTemplate = X2AmmoTemplate(ItemTemplate);
	if(AmmoTemplate != none)
	{
		WeaponTemplate = X2WeaponTemplate(UpdatedUnit.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate());
		if (WeaponTemplate != none && !X2AmmoTemplate(ItemTemplate).IsWeaponValidForAmmo(WeaponTemplate))
		{
			LocTag.StrValue0 = UpdatedUnit.GetPrimaryWeapon().GetMyTemplate().GetItemFriendlyName();
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strAmmoIncompatible));
		}
	}
	
	//start of Issue #50: add hook to UI to show disabled reason, if possible
	//start of Issue #114: added ItemState of what's being looked at for more expansive disabling purposes
	//issue #127: hook now fires all the time instead of a specific use case scenario
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		if(!DLCInfos[i].CanAddItemToInventory_CH_Improved(UnusedOutInt, SelectedSlot, ItemTemplate, Item.Quantity, UpdatedUnit, , DLCReason, Item))
		{
			DisabledReason = DLCReason;
		}
	}
	//end of Issue #50
	//end of issue #114
	
	// If this is a utility item, and cannot be equipped, it must be disabled because of one item per category restriction
	// Issue #118, taking the Utility slot restriction out -- RespectsUniqueRule does everything we need
	// Proof of correctness -- by taking this out, we potentially disallow more equipment, but that would have been a bug in vanilla anyway,
	// because the unit state would have rejected the item due to the Unique Rule
	if(DisabledReason == "" /*&& SelectedSlot == eInvSlot_Utility*/)
	{
		EquippedObjectID = UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).ItemRef.ObjectID;
		if(!UpdatedUnit.RespectsUniqueRule(ItemTemplate, SelectedSlot, , EquippedObjectID))
		{
			LocTag.StrValue0 = ItemTemplate.GetLocalizedCategory();
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strCategoryRestricted));
		}
	}
	
	return DisabledReason;
}

simulated function int SortLockerListByEquip(TUILockerItem A, TUILockerItem B)
{
	if(A.CanBeEquipped && !B.CanBeEquipped) return 1;
	else if(!A.CanBeEquipped && B.CanBeEquipped) return -1;
	else return 0;
}

simulated function int SortLockerListByTier(TUILockerItem A, TUILockerItem B)
{
	local int TierA, TierB;

	TierA = A.Item.GetMyTemplate().Tier;
	TierB = B.Item.GetMyTemplate().Tier;

	if (TierA > TierB) return 1;
	else if (TierA < TierB) return -1;
	else return 0;
}

simulated function int SortLockerListByUpgrades(TUILockerItem A, TUILockerItem B)
{
	local int UpgradesA, UpgradesB;

	// Start Issue #306
	UpgradesA = A.Item.GetMyWeaponUpgradeCount();
	UpgradesB = B.Item.GetMyWeaponUpgradeCount();
	// End Issue #306

	if (UpgradesA > UpgradesB)
	{
		return 1;
	}
	else if (UpgradesA < UpgradesB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

simulated function ChangeActiveList(UIList kActiveList, optional bool bSkipAnimation)
{
	local UIArmory_LoadoutItem LoadoutItem;

	ActiveList = kActiveList;

	LoadoutItem = UIArmory_LoadoutItem(EquippedList.GetSelectedItem());
	
	if(kActiveList == EquippedList)
	{
		if(!bSkipAnimation)
			MC.FunctionVoid("closeList");

		// unlock selected item
		if (LoadoutItem != none)
			LoadoutItem.SetLocked(false);
		// disable list item selection on LockerList, enable it on EquippedList
		LockerListContainer.DisableMouseHit();
		EquippedListContainer.EnableMouseHit();

		Header.PopulateData(GetUnit());
		Navigator.RemoveControl(LockerListContainer);
		Navigator.AddControl(EquippedListContainer);
		EquippedList.EnableNavigation();
		LockerList.DisableNavigation();
		Navigator.SetSelected(EquippedListContainer);
		if (EquippedList.SelectedIndex < 0)
		{
			EquippedList.SetSelectedIndex(0);
		}
		else
		{
			EquippedList.GetSelectedItem().OnReceiveFocus();
		}
	}
	else
	{
		if(!bSkipAnimation)
			MC.FunctionVoid("openList");
		
		// lock selected item
		if (LoadoutItem != none)
			LoadoutItem.SetLocked(true);
		// disable list item selection on LockerList, enable it on EquippedList
		LockerListContainer.EnableMouseHit();
		EquippedListContainer.DisableMouseHit();

		LockerList.SetSelectedIndex(0, true);
		Navigator.RemoveControl(EquippedListContainer);
		Navigator.AddControl(LockerListContainer);
		EquippedList.DisableNavigation();
		LockerList.EnableNavigation();
		Navigator.SetSelected(LockerListContainer);
		LockerList.Navigator.SelectFirstAvailable();
	}
}

simulated function OnSelectionChanged(UIList ContainerList, int ItemIndex)
{
	local UIArmory_LoadoutItem ContainerSelection, EquippedSelection;
	local StateObjectReference EmptyRef, ContainerRef, EquippedRef;

	ContainerSelection = UIArmory_LoadoutItem(ContainerList.GetSelectedItem());
	EquippedSelection = UIArmory_LoadoutItem(EquippedList.GetSelectedItem());

	ContainerRef = ContainerSelection != none ? ContainerSelection.ItemRef : EmptyRef;
	EquippedRef = EquippedSelection != none ? EquippedSelection.ItemRef : EmptyRef;

	if((ContainerSelection == none) || !ContainerSelection.IsDisabled)
		Header.PopulateData(GetUnit(), ContainerRef, EquippedRef);

	InfoTooltip.HideTooltip();
	if(`ISCONTROLLERACTIVE)
	{
		ClearTimer(nameof(DelayedShowTooltip));
		SetTimer(0.21f, false, nameof(DelayedShowTooltip));
	}
	UpdateNavHelp();
}
simulated function DelayedShowTooltip()
{
	InfoTooltip.currentPath = string(ActiveList.GetSelectedItem().MCPath);
	InfoTooltip.ShowTooltip();
}

simulated function OnAccept()
{
	if (ActiveList.SelectedIndex == -1)
		return;

	OnItemClicked(ActiveList, ActiveList.SelectedIndex);
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	if(ContainerList != ActiveList) return;

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
			// Release soldier pawn to force it to be re-created when armor changes
			UpdateData(GetSelectedSlot() == eInvSlot_Armor);

			if(bTutorialJumpOut && Movie.Pres.ScreenStack.HasInstanceOf(class'UISquadSelect'))
			{
				OnCancel();
			}
		}
		
		if (EquippedList.SelectedIndex < 0)
		{
			EquippedList.SetSelectedIndex(0);
		}
	}
}

simulated function UpdateData(optional bool bRefreshPawn)
{
	local Rotator CachedSoldierRotation;

	CachedSoldierRotation = ActorPawn.Rotation;

	// Release soldier pawn to force it to be re-created when armor changes
	if(bRefreshPawn)
		ReleasePawn(true);

	UpdateLockerList();
	UpdateEquippedList();
	CreateSoldierPawn(CachedSoldierRotation);
	Header.PopulateData(GetUnit());

	if (bRefreshPawn && `GAME != none)
	{
		`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(GetUnit().GetReference(), true);
	}
}

// Override function to RequestPawnByState instead of RequestPawnByID
simulated function RequestPawn(optional Rotator DesiredRotation)
{
	ActorPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByState(self, GetUnit(), GetPlacementActor().Location, DesiredRotation);
	ActorPawn.GotoState('CharacterCustomization');
}

simulated function OnCancel()
{
	if(ActiveList == EquippedList)
	{
		// If we are in the tutorial and came from squad select when the medikit objective is active, don't allow backing out
		if (!Movie.Pres.ScreenStack.HasInstanceOf(class'UISquadSelect') || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') != eObjectiveState_InProgress)
		{
			super.OnCancel(); // exits screen
		}
	}	
	else
	{
		ChangeActiveList(EquippedList);
		OnSelectionChanged(EquippedList, EquippedList.SelectedIndex);
	}
}

simulated function OnRemoved()
{
	ResetAvailableEquipment();
	super.OnRemoved();
}
simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if( `ISCONTROLLERACTIVE )
	{
		DelayedShowTooltip();
	}

	super.OnReceiveFocus();
	Movie.PreventCacheRecycling();
}

simulated function SetUnitReference(StateObjectReference NewUnit)
{
	super.SetUnitReference(NewUnit);
	MC.FunctionVoid("animateIn");
}

//==============================================================================

simulated function bool EquipItem(UIArmory_LoadoutItem Item)
{
	local StateObjectReference PrevItemRef, NewItemRef;
	local XComGameState_Item PrevItem, NewItem;
	local bool CanEquip, EquipSucceeded, AddToFront;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComNarrativeMoment EquipNarrativeMoment;
	local XGWeapon Weapon;
	local array<XComGameState_Item> PrevUtilityItems;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState UpdatedState;
	local X2WeaponTemplate WeaponTemplate;
	local EInventorySlot InventorySlot;

	UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Equip Item");
	UpdatedUnit = XComGameState_Unit(UpdatedState.ModifyStateObject(class'XComGameState_Unit', GetUnit().ObjectID));
	
	// Issue #118 -- don't use utility items but the actual slot
	if (class'CHItemSlot'.static.SlotIsMultiItem(GetSelectedSlot()))
	{
		PrevUtilityItems = UpdatedUnit.GetAllItemsInSlot(GetSelectedSlot(), UpdatedState);
	}

	NewItemRef = Item.ItemRef;
	PrevItemRef = UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).ItemRef;
	PrevItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(PrevItemRef.ObjectID));

	if(PrevItem != none)
	{
		PrevItem = XComGameState_Item(UpdatedState.ModifyStateObject(class'XComGameState_Item', PrevItem.ObjectID));
	}

	foreach UpdatedState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	// Attempt to remove previously equipped primary or secondary weapons
	WeaponTemplate = (PrevItem != none) ? X2WeaponTemplate(PrevItem.GetMyTemplate()) : none;
	InventorySlot = (WeaponTemplate != none) ? WeaponTemplate.InventorySlot : eInvSlot_Unknown;
	if( (InventorySlot == eInvSlot_PrimaryWeapon) || (InventorySlot == eInvSlot_SecondaryWeapon))
	{
		Weapon = XGWeapon(PrevItem.GetVisualizer());
		// Weapon must be graphically detach, otherwise destroying it leaves a NULL component attached at that socket
		XComUnitPawn(ActorPawn).DetachItem(Weapon.GetEntity().Mesh);

		Weapon.Destroy();
	}
	
	//issue #114: pass along item state in CanAddItemToInventory check, in case there's a mod that wants to prevent a specific item from being equipped. We also assign an itemstate to NewItem now, so we can use it for the full inventory check.
	NewItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(NewItemRef.ObjectID));
	CanEquip = ((PrevItem == none || UpdatedUnit.RemoveItemFromInventory(PrevItem, UpdatedState)) && UpdatedUnit.CanAddItemToInventory(Item.ItemTemplate, GetSelectedSlot(), UpdatedState, NewItem.Quantity, NewItem));
	//end issue #114
	if(CanEquip)
	{
		GetItemFromInventory(UpdatedState, NewItemRef, NewItem);
		NewItem = XComGameState_Item(UpdatedState.ModifyStateObject(class'XComGameState_Item', NewItem.ObjectID));

		// Fix for TTP 473, preserve the order of Utility items
		if(PrevUtilityItems.Length > 0)
		{
			AddToFront = PrevItemRef.ObjectID == PrevUtilityItems[0].ObjectID;
		}

		//If this is an unmodified primary weapon, transfer weapon customization options from the unit.
		if (!NewItem.HasBeenModified() && GetSelectedSlot() == eInvSlot_PrimaryWeapon)
		{
			WeaponTemplate = X2WeaponTemplate(NewItem.GetMyTemplate());
			if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
			{
				NewItem.WeaponAppearance.iWeaponTint = UpdatedUnit.kAppearance.iArmorTint;
			}
			else
			{
				NewItem.WeaponAppearance.iWeaponTint = UpdatedUnit.kAppearance.iWeaponTint;
			}
			NewItem.WeaponAppearance.nmWeaponPattern = UpdatedUnit.kAppearance.nmWeaponPattern;
		}
		
		EquipSucceeded = UpdatedUnit.AddItemToInventory(NewItem, GetSelectedSlot(), UpdatedState, AddToFront);

		if( EquipSucceeded )
		{
			if( PrevItem != none )
			{
				XComHQ.PutItemInInventory(UpdatedState, PrevItem);
			}

			if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress &&
			   NewItem.GetMyTemplateName() == class'UIInventory_BuildItems'.default.TutorialBuildItem)
			{
				`XEVENTMGR.TriggerEvent('TutorialItemEquipped', , , UpdatedState);
				bTutorialJumpOut = true;
			}
		}
		else
		{
			if(PrevItem != none)
			{
				UpdatedUnit.AddItemToInventory(PrevItem, GetSelectedSlot(), UpdatedState);
			}

			XComHQ.PutItemInInventory(UpdatedState, NewItem);
		}
	}

	UpdatedUnit.ValidateLoadout(UpdatedState);
	`XCOMGAME.GameRuleset.SubmitGameState(UpdatedState);

	if( EquipSucceeded && X2EquipmentTemplate(Item.ItemTemplate) != none)
	{
		if(X2EquipmentTemplate(Item.ItemTemplate).EquipSound != "")
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent(X2EquipmentTemplate(Item.ItemTemplate).EquipSound);
		}

		if(X2EquipmentTemplate(Item.ItemTemplate).EquipNarrative != "")
		{
			EquipNarrativeMoment = XComNarrativeMoment(`CONTENT.RequestGameArchetype(X2EquipmentTemplate(Item.ItemTemplate).EquipNarrative));
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			if(EquipNarrativeMoment != None)
			{
				if (Item.ItemTemplate.ItemCat == 'armor')
				{
					if (XComHQ.CanPlayArmorIntroNarrativeMoment(EquipNarrativeMoment) && !UpdatedUnit.IsResistanceHero())
					{
						UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Played Armor Intro List");
						XComHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
						XComHQ.UpdatePlayedArmorIntroNarrativeMoments(EquipNarrativeMoment);
						`XCOMGAME.GameRuleset.SubmitGameState(UpdatedState);

						`HQPRES.UIArmorIntroCinematic(EquipNarrativeMoment.nmRemoteEvent, 'CIN_ArmorIntro_Done', UnitReference);
					}
				}
				else if (XComHQ.CanPlayEquipItemNarrativeMoment(EquipNarrativeMoment))
				{
					UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Equip Item Intro List");
					XComHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.UpdateEquipItemNarrativeMoments(EquipNarrativeMoment);
					`XCOMGAME.GameRuleset.SubmitGameState(UpdatedState);
					
					`HQPRES.UINarrative(EquipNarrativeMoment);
				}
			}
		}	
	}

	return EquipSucceeded;
}

// Issue #118 -- should be obsolete
simulated function XComGameState_Item GetEquippedItem(EInventorySlot eSlot)
{
	return GetUnit().GetItemInSlot(eSlot, CheckGameState);
}

simulated function EInventorySlot GetSelectedSlot()
{
	local UIArmory_LoadoutItem Item;

	Item = UIArmory_LoadoutItem(EquippedList.GetSelectedItem());

	return Item != none ? Item.EquipmentSlot : eInvSlot_Unknown;
}

// Used when selecting utility items directly from Squad Select
simulated function SelectItemSlot(EInventorySlot ItemSlot, int ItemIndex)
{
	local int i;
	local UIArmory_LoadoutItem Item;

	for(i = 0; i < EquippedList.ItemCount; ++i)
	{
		Item = UIArmory_LoadoutItem(EquippedList.GetItem(i));

		// We treat grenade pocket slot like a utility slot in this case
		if(Item.EquipmentSlot == ItemSlot)
		{
			EquippedList.SetSelectedIndex(i + ItemIndex);
			break;
		}
	}
	
	ChangeActiveList(LockerList);
	UpdateLockerList();
}

simulated function SelectWeapon(EInventorySlot WeaponSlot)
{
	local int i;

	for(i = 0; i < EquippedList.ItemCount; ++i)
	{
		if(UIArmory_LoadoutItem(EquippedList.GetItem(i)).EquipmentSlot == WeaponSlot)
		{
			EquippedList.SetSelectedIndex(i);
			break;
		}
	}

	ChangeActiveList(LockerList);
	UpdateLockerList();
}

simulated function InitializeTooltipData()
{
	InfoTooltip = Spawn(class'UIArmory_LoadoutItemTooltip', self); 
	InfoTooltip.InitLoadoutItemTooltip('UITooltipInventoryItemInfo');

	InfoTooltip.bUsePartialPath = true;
	InfoTooltip.targetPath = string(MCPath); 
	InfoTooltip.RequestItem = TooltipRequestItemFromPath; 

	InfoTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( InfoTooltip );
	InfoTooltip.tDelay = 0; // instant tooltips!
}

simulated function XComGameState_Item TooltipRequestItemFromPath( string currentPath )
{
	local string ItemName, TargetList;
	local array<string> Path;
	local UIArmory_LoadoutItem Item;

	Path = SplitString( currentPath, "." );	

	foreach Path(TargetList)
	{
		//Search the path for the target list matchup
		if( TargetList == string(ActiveList.MCName) )
		{
			ItemName = Path[Path.length-1];
			
			// if we've highlighted the DropItemButton, account for it in the path name
			if(ItemName == "bg")
				ItemName = Path[Path.length-3];

			Item =  UIArmory_LoadoutItem(ActiveList.GetItemNamed(Name(ItemName)));
			if(Item != none)
				return GetItemFromHistory(Item.ItemRef.ObjectID); 
		}
	}
	
	//Else we never found a target list + item
	`log("Problem in UIArmory_Loadout for the UITooltip_InventoryInfo: couldn't match the active list at position -4 in this path: " $currentPath,,'uixcom');
	return none;
}

function bool GetItemFromInventory(XComGameState AddToGameState, StateObjectReference ItemRef, out XComGameState_Item ItemState)
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetItemFromInventory(AddToGameState, ItemRef, ItemState);
}

function XComGameState_Item GetItemFromHistory(int ObjectID)
{
	return XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
}

function XComGameState_Unit GetUnitFromHistory(int ObjectID)
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Movie.AllowCacheRecycling();
}

event Destroyed()
{
	Movie.AllowCacheRecycling();
	super.Destroyed();
}
//==============================================================================

defaultproperties
{
	LibID = "LoadoutScreenMC";
	DisplayTag = "UIBlueprint_Loadout";
	CameraTag = "UIBlueprint_Loadout";
	bAutoSelectFirstNavigable = false;
	bHideOnLoseFocus = false;
}
