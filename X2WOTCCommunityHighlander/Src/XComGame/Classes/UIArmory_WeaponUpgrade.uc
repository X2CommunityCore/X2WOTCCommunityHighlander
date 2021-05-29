//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory_WeaponUpgrade
//  AUTHOR:  Sam Batista
//  PURPOSE: UI for viewing and modifying weapon upgrades
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIArmory_WeaponUpgrade extends UIArmory
	dependson(UIInputDialogue)
	config(UI);

struct TUIAvailableUpgrade
{
	var XComGameState_Item Item;
	var bool bCanBeEquipped;
	var string DisabledReason; // Reason why upgrade cannot be equipped
};

// Start Issue #832
struct WeaponViewOffset
{
	var name Template;
	var float offset_x;
	var float offset_y;
	var float offset_z;
};
var config array<WeaponViewOffset> WeaponViewOffsets;
// End Issue #832

var int FontSize;

var UIList ActiveList;

var UIPanel SlotsListContainer;
var UIList SlotsList;

var UIPanel UpgradesListContainer;
var UIList UpgradesList;

var StateObjectReference WeaponRef;
var XComGameState_Item UpdatedWeapon;
var XComGameState CustomizationState;
var UIArmory_WeaponUpgradeStats WeaponStats;
var UIMouseGuard_RotatePawn MouseGuard;

var Rotator DefaultWeaponRotation;

var config int CustomizationListX;
var config int CustomizationListY;
var config int CustomizationListYPadding;
var UIList CustomizeList;

var config int ColorSelectorX;
var config int ColorSelectorY;
var config int ColorSelectorWidth;
var config int ColorSelectorHeight;
var UIColorSelector ColorSelector;

var localized string m_strTitle;
var localized string m_strEmptySlot;
var localized string m_strUpgradeWeapon;
var localized string m_strSelectUpgrade;
var localized string m_strSlotsAvailable;
var localized string m_strSlotsLocked;
var localized string m_strCost;
var localized string m_strWeaponFullyUpgraded;
var localized string m_strInvalidUpgrade;
var localized string m_strRequiresContinentBonus;
var localized string m_strConfirmDialogTitle;
var localized string m_strConfirmDialogDescription;
var localized string m_strReplaceUpgradeTitle;
var localized string m_strReplaceUpgradeText;
var localized string m_strUpgradeAvailable;
var localized string m_strNoUpgradeAvailable;
var localized string m_strWeaponNotEquipped;
var localized string m_strWeaponEquippedOn;
var localized string m_strCustomizeWeaponTitle;
var localized string m_strCustomizeWeaponName;

simulated function InitArmory(StateObjectReference UnitOrWeaponRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	super.InitArmory(UnitOrWeaponRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, InitCheckGameState);

	`HQPRES.CAMLookAtNamedLocation( CameraTag, 0 );

	FontSize = bIsIn3D ? class'UIUtilities_Text'.const.BODY_FONT_SIZE_3D : class'UIUtilities_Text'.const.BODY_FONT_SIZE_2D;
	
	SlotsListContainer = Spawn(class'UIPanel', self);
	SlotsListContainer.bAnimateOnInit = false;
	SlotsListContainer.InitPanel('leftPanel');
	SlotsList = class'UIArmory_Loadout'.static.CreateList(SlotsListContainer);
	SlotsList.OnChildMouseEventDelegate = OnListChildMouseEvent;
	SlotsList.OnSelectionChanged = PreviewUpgrade;
	SlotsList.OnItemClicked = OnItemClicked;
	SlotsList.Navigator.LoopSelection = false;	
	//INS: - JTA 2016/3/2
	SlotsList.bLoopSelection = false;
	SlotsList.Navigator.LoopOnReceiveFocus = true;
	//INS: WEAPON_UPGRADE_UI_FIXES, BET, 2016-03-23
	SlotsList.bCascadeFocus = true;
	SlotsList.bPermitNavigatorToDefocus = true;

	CustomizeList = Spawn(class'UIList', SlotsListContainer);
	CustomizeList.ItemPadding = 5;
	CustomizeList.bStickyHighlight = false;
	CustomizeList.InitList('customizeListMC');
	CustomizeList.AddOnInitDelegate(UpdateCustomization);
	CustomizeList.Navigator.LoopSelection = false;
	CustomizeList.bLoopSelection = false;
	CustomizeList.Navigator.LoopOnReceiveFocus = true;
	CustomizeList.bCascadeFocus = true;
	CustomizeList.bPermitNavigatorToDefocus = true;

	UpgradesListContainer = Spawn(class'UIPanel', self);
	UpgradesListContainer.bAnimateOnInit = false;
	UpgradesListContainer.InitPanel('rightPanel');
	UpgradesList = class'UIArmory_Loadout'.static.CreateList(UpgradesListContainer);
	UpgradesList.OnChildMouseEventDelegate = OnListChildMouseEvent;
	UpgradesList.OnSelectionChanged = PreviewUpgrade;
	UpgradesList.OnItemClicked = OnItemClicked;

	Navigator.RemoveControl(UpgradesList);

	WeaponStats = Spawn(class'UIArmory_WeaponUpgradeStats', self).InitStats('weaponStatsMC', WeaponRef);
	WeaponStats.DisableNavigation(); 

	if(GetUnit() != none)
		WeaponRef = GetUnit().GetItemInSlot(eInvSlot_PrimaryWeapon).GetReference();
	else
		WeaponRef = UnitOrWeaponRef;

	SetWeaponReference(WeaponRef);

	`XCOMGRI.DoRemoteEvent(EnableWeaponLightingEvent);

	MouseGuard = UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn'));
	MouseGuard.OnMouseEventDelegate = OnMouseGuardMouseEvent;
	MouseGuard.SetActorPawn(ActorPawn, DefaultWeaponRotation);
	PreviewUpgrade(SlotsList, 0); //Force a refresh of the weapon pawn

	if (UIArmory_WeaponTrait(self) != none)
	{
		MouseGuard.OnReceiveFocus();
	}
}

simulated function OnInit()
{
	super.OnInit();
	SetTimer(0.01f, true, nameof(InterpolateWeapon));

	Navigator.Next(); //bsg-jneal (7.12.16): Tell the Navigator to select the initial list item for WeaponUpgrade so the menu has an initial selection when it opens.
}

// Override the soldier cycling behavior since we don't want to spawn soldier pawns on previous armory screens
simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local int i;
	local UIArmory ArmoryScreen;
	local UIArmory_WeaponUpgrade UpgradeScreen;
	local UIScreenStack ScreenStack;
	local Rotator CachedRotation;

	ScreenStack = `SCREENSTACK;

	// Update the weapon in the WeaponUpgrade screen
	UpgradeScreen = UIArmory_WeaponUpgrade(ScreenStack.GetScreen(class'UIArmory_WeaponUpgrade'));
	
	// Close the color selector before switching weapons (canceling any changes not yet confirmed)
	if(UpgradeScreen.ColorSelector != none)
		UpgradeScreen.CloseColorSelector(true);

	if( UpgradeScreen.ActorPawn != none )
		CachedRotation = UpgradeScreen.ActorPawn.Rotation;

	for( i = ScreenStack.Screens.Length - 1; i >= 0; --i )
	{
		ArmoryScreen = UIArmory(ScreenStack.Screens[i]);
		if( ArmoryScreen != none )
		{
			ArmoryScreen.ReleasePawn();
			ArmoryScreen.SetUnitReference(NewRef);
			ArmoryScreen.Header.UnitRef = NewRef;
		}
	}

	UpgradeScreen.SetWeaponReference(UpgradeScreen.GetUnit().GetItemInSlot(eInvSlot_PrimaryWeapon).GetReference());

	if(UpgradeScreen.ActorPawn != none)
		UpgradeScreen.ActorPawn.SetRotation(CachedRotation);
	//Force refresh - otherwise we end up with out-of-date weapon pawn (showing customization from previous soldier)
	UpgradeScreen.PreviewUpgrade(UpgradeScreen.SlotsList, 0);
}

simulated function SetWeaponReference(StateObjectReference NewWeaponRef)
{
	local XComGameState_Item Weapon;

	if(CustomizationState != none)
		SubmitCustomizationChanges();

	WeaponRef = NewWeaponRef;
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

	SetWeaponName(Weapon.GetMyTemplate().GetItemFriendlyName());
	CreateWeaponPawn(Weapon);
	DefaultWeaponRotation = ActorPawn.Rotation;

	ChangeActiveList(SlotsList, true);
	UpdateOwnerSoldier();
	UpdateSlots();

	if(CustomizeList.bIsInited)
		UpdateCustomization(none);

	MC.FunctionVoid("animateIn");
}

simulated function UpdateOwnerSoldier()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_Item Weapon;

	History = `XCOMHISTORY;
	Weapon = XComGameState_Item(History.GetGameStateForObjectID(WeaponRef.ObjectID));
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(Weapon.OwnerStateObject.ObjectID));

	if(Unit != none)
		SetEquippedText(m_strWeaponEquippedOn, Unit.GetName(eNameType_Full));
	else
		SetEquippedText(m_strWeaponNotEquipped, "");
}

simulated function UpdateSlots()
{
	local XGParamTag LocTag;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Weapon;
	local X2WeaponTemplate WeaponTemplate;
	local int i, SlotsAvailable, NumUpgradeSlots;
	local array<X2WeaponUpgradeTemplate> EquippedUpgrades;
	local string EquipSlotLockedStr;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

	LocTag.StrValue0 = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Weapon.GetMyTemplate().GetItemFriendlyName(Weapon.ObjectID));

	// Get equipped upgrades
	EquippedUpgrades = Weapon.GetMyWeaponUpgradeTemplates();
	WeaponTemplate = X2WeaponTemplate(Weapon.GetMyTemplate());
	// Start Issue #93
	//NumUpgradeSlots = WeaponTemplate.NumUpgradeSlots;
	NumUpgradeSlots = Weapon.GetNumUpgradeSlots();
	// End Issue #93

	if (XComHQ.bExtraWeaponUpgrade)
		NumUpgradeSlots++;

	if (XComHQ.ExtraUpgradeWeaponCats.Find(WeaponTemplate.WeaponCat) != INDEX_NONE)
		NumUpgradeSlots++;

	SlotsAvailable = NumUpgradeSlots - EquippedUpgrades.Length;

	SetAvailableSlots(class'UIUtilities_Text'.static.GetColoredText(m_strSlotsAvailable, eUIState_Disabled, 26),
					  class'UIUtilities_Text'.static.GetColoredText(SlotsAvailable $ "/" $ NumUpgradeSlots, eUIState_Highlight, 40));

	SlotsList.ClearItems();
	
	// Add equipped slots
	for (i = 0; i < EquippedUpgrades.Length; ++i)
	{
		// If an upgrade was equipped while the extra slot continent bonus was active, but it is now disabled, don't allow the upgrade to be edited
		EquipSlotLockedStr = (i > (NumUpgradeSlots - 1)) ? class'UIUtilities_Text'.static.GetColoredText(m_strRequiresContinentBonus, eUIState_Bad) : "";
		UIArmory_WeaponUpgradeItem(SlotsList.CreateItem(class'UIArmory_WeaponUpgradeItem')).InitUpgradeItem(Weapon, EquippedUpgrades[i], i, EquipSlotLockedStr);
	}

	// Add available upgrades
	for (i = 0; i < SlotsAvailable; ++i)
	{
		UIArmory_WeaponUpgradeItem(SlotsList.CreateItem(class'UIArmory_WeaponUpgradeItem')).InitUpgradeItem(Weapon, none, i + EquippedUpgrades.Length);
	}

	if(SlotsAvailable == 0)
		SetSlotsListTitle(`XEXPAND.ExpandString(m_strWeaponFullyUpgraded));
	else
		SetSlotsListTitle(`XEXPAND.ExpandString(m_strUpgradeWeapon));

	`XEVENTMGR.TriggerEvent('UIArmory_WeaponUpgrade_SlotsUpdated', SlotsList, self, none);
}

simulated function UpdateUpgrades()
{
	local int i, SlotIndex;
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;
	local XComGameState_Item Weapon;
	local XComGameState_HeadquartersXCom XComHQ;
	local UIArmory_WeaponUpgradeItem UpgradeItem;
	local array<TUIAvailableUpgrade> AvailableUpgrades;
	local TUIAvailableUpgrade Upgrade;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
	SlotIndex = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SlotIndex;

	AvailableUpgrades.Length = 0;
	foreach XComHQ.Inventory(ItemRef)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
		if (Item == none || X2WeaponUpgradeTemplate(Item.GetMyTemplate()) == none)
			continue;
		
		Upgrade.Item = Item;
		Upgrade.bCanBeEquipped = X2WeaponUpgradeTemplate(Item.GetMyTemplate()).CanApplyUpgradeToWeapon(Weapon, SlotIndex) && Weapon.CanWeaponApplyUpgrade(X2WeaponUpgradeTemplate(Item.GetMyTemplate())); // Issue #260
		Upgrade.DisabledReason = Upgrade.bCanBeEquipped ? "" : class'UIUtilities_Text'.static.GetColoredText(m_strInvalidUpgrade, eUIState_Bad);

		AvailableUpgrades.AddItem(Upgrade);
	}

	AvailableUpgrades.Sort(SortUpgradesByTier);
	AvailableUpgrades.Sort(SortUpgradesByEquip);

	UpgradesList.ClearItems();

	for(i = 0; i < AvailableUpgrades.Length; ++i)
	{
		UpgradeItem = UIArmory_WeaponUpgradeItem(UpgradesList.CreateItem(class'UIArmory_WeaponUpgradeItem'));
		UpgradeItem.InitUpgradeItem(Weapon, X2WeaponUpgradeTemplate(AvailableUpgrades[i].Item.GetMyTemplate()), , AvailableUpgrades[i].DisabledReason);
		UpgradeItem.SetCount(AvailableUpgrades[i].Item.Quantity);
	}

	if(AvailableUpgrades.Length == 0)
		SetUpgradeListTitle(m_strNoUpgradeAvailable);
	else
		SetUpgradeListTitle(m_strSelectUpgrade);
}

simulated function int SortUpgradesByEquip(TUIAvailableUpgrade A, TUIAvailableUpgrade B)
{
	if(A.bCanBeEquipped && !B.bCanBeEquipped) return 1;
	else if(!A.bCanBeEquipped && B.bCanBeEquipped) return -1;
	else return 0;
}

simulated function int SortUpgradesByTier(TUIAvailableUpgrade A, TUIAvailableUpgrade B)
{
	local int TierA, TierB;

	TierA = A.Item.GetMyTemplate().Tier;
	TierB = B.Item.GetMyTemplate().Tier;

	if (TierA > TierB) return 1;
	else if (TierA < TierB) return -1;
	else return 0;
}

simulated function ChangeActiveList(UIList kActiveList, optional bool bSkipAnimation)
{
	local Vector PreviousLocation, NoneLocation;
	local XComGameState_Item WeaponItemState;
	local UIArmory_WeaponUpgradeItem SelectedItem;

	ActiveList = kActiveList;

	SelectedItem = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem());
	if (SelectedItem != none)
		SelectedItem.SetLocked(ActiveList != SlotsList);

	ActiveList.SetSelectedIndex(0); //bsg-jneal (7.12.16): Let the start index be 0 for console so the list has an initial selection on opening, having the list init at index -1 is more of a mouse/keyboard style
	
	if(ActiveList == SlotsList)
	{
		if(!bSkipAnimation)
			MC.FunctionVoid("closeList");

		// disable list item selection on LockerList, enable it on EquippedList
		UpgradesListContainer.DisableMouseHit();
		SlotsListContainer.EnableMouseHit();

		//Reset the weapon location tag as it may have changed if we were looking at attachments
		WeaponItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));

		PreviousLocation = ActorPawn.Location;
		CreateWeaponPawn(WeaponItemState, ActorPawn.Rotation);
		WeaponStats.PopulateData(WeaponItemState);
		if(PreviousLocation != NoneLocation)
			ActorPawn.SetLocation(PreviousLocation);

		SetUpgradeText();
		SlotsListContainer.EnableNavigation();
		UpgradesListContainer.DisableNavigation();
		Navigator.SetSelected(SlotsListContainer);

		if(SlotsListContainer.Navigator.SelectedIndex == -1)
			SlotsListContainer.Navigator.SetSelected(SlotsList);

		if(SlotsList.SelectedIndex == -1)
			SlotsList.SetSelectedIndex(0);
		else
			PreviewUpgrade(SlotsList, SlotsList.SelectedIndex); //Reset weapon pawn so it can be rotated
	}
	else
	{
		if(!bSkipAnimation)
			MC.FunctionVoid("openList");
		
		// disable list item selection on LockerList, enable it on EquippedList
		UpgradesListContainer.EnableMouseHit();
		SlotsListContainer.DisableMouseHit();
		SlotsListContainer.DisableNavigation();
		UpgradesListContainer.EnableNavigation();
		Navigator.SetSelected(UpgradesListContainer);
		UpgradesListContainer.Navigator.SetSelected(UpgradesList);
	}

	UpdateNavHelp();
} 

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	local X2WeaponUpgradeTemplate NewUpgradeTemplate;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item Weapon;
	local int SlotIndex;

	if(ContainerList != ActiveList) return;

	if(UIArmory_WeaponUpgradeItem(ContainerList.GetItem(ItemIndex)).bIsDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}

	if(ContainerList == SlotsList)
	{
		UpdateNavHelp();
		UpdateUpgrades();
		ChangeActiveList(UpgradesList);
		//bsg-lsimkin; 07-12-16; TTP 5932: No audio plays when selecting weapon upgrade slot
		Movie.Pres.PlayUISound(eSUISound_MenuOpen);
	}
	else
	{
		Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
		UpgradeTemplates = Weapon.GetMyWeaponUpgradeTemplates();
		NewUpgradeTemplate = UIArmory_WeaponUpgradeItem(ContainerList.GetItem(ItemIndex)).UpgradeTemplate;
		SlotIndex = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SlotIndex;
		
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

		//bsg-hlee (05.10.17): Only let upgrades be selected if there are actually upgrades avail.
		if(ActiveList.ItemCount > 0)
		{
			if (XComHQ.bReuseUpgrades)
			{
				// Skip the popup if the continent bonus for reusing upgrades is active
				EquipUpgradeCallback('eUIAction_Accept');
			}
			else
			{			
				if (SlotIndex < UpgradeTemplates.Length)
					ReplaceUpgrade(UpgradeTemplates[SlotIndex], NewUpgradeTemplate);
				else
					EquipUpgrade(NewUpgradeTemplate);
			}
		}
		//bsg-hlee (05.10.17): End
	}
}

//<workshop> Remove Rotate when in UpgradesList - CN 2016/06/02
simulated function UpdateNavHelp()
{
	local int i;
	local string PrevKey, NextKey;
	local XGParamTag LocTag;

	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnCancel);
	if(!(ActiveList == UpgradesList && ActiveList.ItemCount == 0)) //will not show 'select' if there is nothing to select
	{
		NavHelp.AddSelectNavHelp();
	}
	
	if(`ISCONTROLLERACTIVE)
	{
		if( IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo) )
		{
			NavHelp.AddCenterHelp(m_strTabNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LBRB_L1R1); // bsg-jrebar (5/23/17): Removing inlined buttons
		}
		
		if (ActiveList == SlotsList)
		{
			NavHelp.AddCenterHelp(m_strRotateNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RSTICK); // bsg-jrebar (5/23/17): Removing inlined buttons
		}
	}
	else
	{
		if( XComHQPresentationLayer(Movie.Pres) != none )
		{
			LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_PrevUnit);
			PrevKey = `XEXPAND.ExpandString(PrevSoldierKey);
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_NextUnit);
			NextKey = `XEXPAND.ExpandString(NextSoldierKey);

			if( IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo) )
			{
				NavHelp.SetButtonType("XComButtonIconPC");
				i = eButtonIconPC_Prev_Soldier;
				NavHelp.AddCenterHelp(string(i), "", PrevSoldier, false, PrevKey);
				i = eButtonIconPC_Next_Soldier;
				NavHelp.AddCenterHelp(string(i), "", NextSoldier, false, NextKey);
				NavHelp.SetButtonType("");
			}
		}
	}
	NavHelp.Show();

	`XEVENTMGR.TriggerEvent('UIArmory_WeaponUpgrade_NavHelpUpdated', NavHelp, self, none);
}

simulated function PreviewUpgrade(UIList ContainerList, int ItemIndex)
{
	local XComGameState_Item Weapon;
	local XComGameState ChangeState;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local int WeaponAttachIndex, SlotIndex;
	local Name WeaponTemplateName;
	local Vector PreviousLocation;

	if(ItemIndex == INDEX_NONE)
	{
		SetUpgradeText();
		return;
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Weapon_Attachement_Upgrade");
	ChangeState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Visualize Weapon Upgrade");

	Weapon = XComGameState_Item(ChangeState.ModifyStateObject(class'XComGameState_Item', WeaponRef.ObjectID));

	UpgradeTemplate = UIArmory_WeaponUpgradeItem(ContainerList.GetItem(ItemIndex)).UpgradeTemplate;
	SlotIndex = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SlotIndex;

	Weapon.DeleteWeaponUpgradeTemplate(SlotIndex);
	if (UpgradeTemplate != none)
	{
		Weapon.ApplyWeaponUpgradeTemplate(UpgradeTemplate, SlotIndex);

		// Start Issue #39
		/// HL-Docs: ref:Bugfixes; issue:39
		/// Create weapon pawn before setting PawnLocationTag so that the weapon can rotate when previewing weapon upgrades.
		PreviousLocation = ActorPawn.Location;
		CreateWeaponPawn(Weapon, ActorPawn.Rotation);
		ActorPawn.SetLocation(PreviousLocation);
		MouseGuard.SetActorPawn(ActorPawn, ActorPawn.Rotation);
		// End Issue #39

		//Formulate the attachment specific location tag from the attach socket
		WeaponTemplateName = Weapon.GetMyTemplateName();
		for( WeaponAttachIndex = 0; WeaponAttachIndex < UpgradeTemplate.UpgradeAttachments.Length; ++WeaponAttachIndex )
		{
			if( UpgradeTemplate.UpgradeAttachments[WeaponAttachIndex].ApplyToWeaponTemplate == WeaponTemplateName &&
				UpgradeTemplate.UpgradeAttachments[WeaponAttachIndex].UIArmoryCameraPointTag != '' )
			{
				PawnLocationTag = UpgradeTemplate.UpgradeAttachments[WeaponAttachIndex].UIArmoryCameraPointTag;
				break;
			}
		}

		SetUpgradeText(UpgradeTemplate.GetItemFriendlyName(), UpgradeTemplate.GetItemBriefSummary());

		WeaponStats.PopulateData(Weapon, UpgradeTemplate);
	}
	if(ActiveList != UpgradesList)
	{
		MouseGuard.SetActorPawn(ActorPawn); //When we're not selecting an upgrade, let the user spin the weapon around
		RestoreWeaponLocation();
	}
	else
	{
		MouseGuard.SetActorPawn(None); //Otherwise, grab the rotation to show them the upgrade as they select it
	}
	// Start Issue #39
	// Create weapon pawn if the upgrade template does not exist to preserve the vanilla WOTC behavior
	// in case something goes wrong.
	if (UpgradeTemplate == none)
	{
		PreviousLocation = ActorPawn.Location;
		CreateWeaponPawn(Weapon, ActorPawn.Rotation);
		ActorPawn.SetLocation(PreviousLocation);
		MouseGuard.SetActorPawn(ActorPawn, ActorPawn.Rotation);
	}
	// End Issue #39
	`XCOMHISTORY.CleanupPendingGameState(ChangeState);
}

function EquipUpgrade(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;
		
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = UpgradeTemplate.GetItemFriendlyName();
		
	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strConfirmDialogTitle;
	kDialogData.strText = `XEXPAND.ExpandString(m_strConfirmDialogDescription); 

	kDialogData.fnCallback = EquipUpgradeCallback;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

function ReplaceUpgrade(X2WeaponUpgradeTemplate UpgradeToRemove, X2WeaponUpgradeTemplate UpgradeToInstall)
{
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = UpgradeToRemove.GetItemFriendlyName();
	kTag.StrValue1 = UpgradeToInstall.GetItemFriendlyName();

	kDialogData.eType = eDialog_Alert;
	kDialogData.strTitle = m_strReplaceUpgradeTitle;
	kDialogData.strText = `XEXPAND.ExpandString(m_strReplaceUpgradeText);

	kDialogData.fnCallback = EquipUpgradeCallback;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(kDialogData);
}

simulated public function EquipUpgradeCallback(Name eAction)
{
	local int i, SlotIndex;
	local XComGameState_Item Weapon;
	local XComGameState_Item UpgradeItem;
	local X2WeaponUpgradeTemplate UpgradeTemplate, OldUpgradeTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState ChangeState;
	
	if( eAction == 'eUIAction_Accept' )
	{
		Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
		UpgradeTemplate = UIArmory_WeaponUpgradeItem(UpgradesList.GetSelectedItem()).UpgradeTemplate;
		SlotIndex = UIArmory_WeaponUpgradeItem(SlotsList.GetSelectedItem()).SlotIndex;

		if (UpgradeTemplate != none && UpgradeTemplate.CanApplyUpgradeToWeapon(Weapon, SlotIndex) && Weapon.CanWeaponApplyUpgrade(UpgradeTemplate)) // Issue #260
		{
			// Create change context
			ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Weapon Upgrade");
			ChangeState = `XCOMHISTORY.CreateNewGameState(true, ChangeContainer);

			// Apply upgrade to weapon
			Weapon = XComGameState_Item(ChangeState.ModifyStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
			OldUpgradeTemplate = Weapon.DeleteWeaponUpgradeTemplate(SlotIndex);
			Weapon.ApplyWeaponUpgradeTemplate(UpgradeTemplate, SlotIndex);
			
			// Remove the new upgrade from HQ inventory
			XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
			XComHQ = XComGameState_HeadquartersXCom(ChangeState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

			for(i = 0; i < XComHQ.Inventory.Length; ++i)
			{
				UpgradeItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Inventory[i].ObjectID));
				if (UpgradeItem != none && UpgradeItem.GetMyTemplateName() == UpgradeTemplate.DataName)
					break;
			}

			if(UpgradeItem == none)
			{
				`RedScreen("Failed to find upgrade"@UpgradeTemplate.DataName@"in HQ inventory.");
				return;
			}

			XComHQ.RemoveItemFromInventory(ChangeState, UpgradeItem.GetReference(), 1);

			// If reusing upgrades Continent Bonus is active, create an item for the old upgrade template and add it to the inventory
			if (XComHQ.bReuseUpgrades && OldUpgradeTemplate != none)
			{
				UpgradeItem = OldUpgradeTemplate.CreateInstanceFromTemplate(ChangeState);
				XComHQ.PutItemInInventory(ChangeState, UpgradeItem);
			}
			
			`XEVENTMGR.TriggerEvent('WeaponUpgraded', Weapon, UpgradeItem, ChangeState);
			`GAMERULES.SubmitGameState(ChangeState);

			UpdateSlots();
			WeaponStats.PopulateData(Weapon);

			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Weapon_Attachement_Upgrade_Select");
		}
		else
			Movie.Pres.PlayUISound(eSUISound_MenuClose);

		ChangeActiveList(SlotsList);
		Navigator.SetSelected();
		Navigator.SetSelected(SlotsListContainer);
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function UpdateCustomization(UIPanel DummyParam)
{
	local int i;
	local XGParamTag LocTag;
	local XComLinearColorPalette Palette;
	local LinearColor PaletteColor;

	CreateCustomizationState();

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Caps(UpdatedWeapon.GetMyTemplate().GetItemFriendlyName(UpdatedWeapon.ObjectID));

	SetCustomizeTitle(`XEXPAND.ExpandString(m_strCustomizeWeaponTitle));

	// WEAPON NAME
	//-----------------------------------------------------------------------------------------

	GetCustomizeItem(i++).UpdateDataDescription(m_strCustomizeWeaponName, OpenWeaponNameInputBox);


	// WEAPON PRIMARY COLOR
	//-----------------------------------------------------------------------------------------
	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	if (UpdatedWeapon.WeaponAppearance.iWeaponTint >= 0)
		PaletteColor = Palette.Entries[UpdatedWeapon.WeaponAppearance.iWeaponTint].Primary;

	GetCustomizeItem(i++).UpdateDataColorChip(class'UICustomize_Weapon'.default.m_strWeaponColor,
		class'UIUtilities_Colors'.static.LinearColorToFlashHex(PaletteColor), WeaponColorSelector);

	// WEAPON PATTERN (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------

	GetCustomizeItem(i++).UpdateDataValue(class'UICustomize_Props'.default.m_strWeaponPattern,
		class'UIUtilities_Text'.static.GetColoredText(GetWeaponPatternDisplay(UpdatedWeapon.WeaponAppearance.nmWeaponPattern), eUIState_Normal, FontSize), CustomizeWeaponPattern);
	
	CustomizeList.SetPosition(CustomizationListX, CustomizationListY - CustomizeList.ShrinkToFit() - CustomizationListYPadding);

	CleanupCustomizationState();
}

simulated function bool InShell()
{
	return XComShellPresentationLayer(Movie.Pres) != none;
}

simulated function UIMechaListItem GetCustomizeItem(int ItemIndex)
{
	local UIMechaListItem CustomizeItem;

	if(CustomizeList.ItemCount <= ItemIndex)
	{
		CustomizeItem = Spawn(class'UIMechaListItem', CustomizeList.ItemContainer);
		CustomizeItem.bAnimateOnInit = false;
		CustomizeItem.InitListItem();
	}
	else
		CustomizeItem = UIMechaListItem(CustomizeList.GetItem(ItemIndex));

	return CustomizeItem;
}

simulated function CustomizeWeaponPattern()
{
	XComHQPresentationLayer(Movie.Pres).UIArmory_WeaponTrait(WeaponRef, class'UICustomize_Props'.default.m_strWeaponPattern, GetWeaponPatternList(),
		PreviewWeaponPattern, UpdateWeaponPattern, CanCycleTo, GetWeaponPatternIndex(),,, false);
}

function PreviewWeaponPattern(UIList _list, int itemIndex)
{
	local int newIndex;
	local array<X2BodyPartTemplate> BodyParts;
	local X2BodyPartTemplateManager PartManager;

	CreateCustomizationState();

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);

	newIndex = WrapIndex( itemIndex, 0, BodyParts.Length);
	
	UpdatedWeapon.WeaponAppearance.nmWeaponPattern = BodyParts[newIndex].DataName;
	XComWeapon(ActorPawn).m_kGameWeapon.SetAppearance(UpdatedWeapon.WeaponAppearance);

	CleanupCustomizationState();
}

function UpdateWeaponPattern(UIList _list, int itemIndex)
{
	local int newIndex;
	local array<X2BodyPartTemplate> BodyParts;
	local X2BodyPartTemplateManager PartManager;
	local XComGameState_Unit Unit;

	CreateCustomizationState();

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);

	newIndex = WrapIndex( itemIndex, 0, BodyParts.Length);
	
	UpdatedWeapon.WeaponAppearance.nmWeaponPattern = BodyParts[newIndex].DataName;
	XComWeapon(ActorPawn).m_kGameWeapon.SetAppearance(UpdatedWeapon.WeaponAppearance);
	
	// Transfer the new weapon pattern back to the owner Unit's appearance data ONLY IF the weapon is otherwise unmodified
	Unit = GetUnit();
	if (Unit != none && !UpdatedWeapon.HasBeenModified())
	{
		Unit = XComGameState_Unit(CustomizationState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.kAppearance.nmWeaponPattern = UpdatedWeapon.WeaponAppearance.nmWeaponPattern;
	}

	SubmitCustomizationChanges();
}

function string GetWeaponPatternDisplay( name PartToMatch )
{
	local int PartIndex;
	local array<X2BodyPartTemplate> BodyParts;
	local X2BodyPartTemplateManager PartManager;

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);

	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( PartToMatch == BodyParts[PartIndex].DataName )
		{
			return BodyParts[PartIndex].DisplayName;
		}
	}

	return PartManager.FindUberTemplate("Patterns", 'Pat_Nothing').DisplayName;
}

function array<string> GetWeaponPatternList()
{
	local int i;
	local array<string> Items;
	local array<X2BodyPartTemplate> BodyParts;
	local X2BodyPartTemplateManager PartManager;

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);
	for( i = 0; i < BodyParts.Length; ++i )
	{
		if(BodyParts[i].DisplayName != "")
			Items.AddItem(BodyParts[i].DisplayName);
		else if(class'UICustomize_Props'.default.m_strWeaponPattern != "")
			Items.AddItem(class'UICustomize_Props'.default.m_strWeaponPattern @ i);
		else
			Items.AddItem(string(i));
	}

	return Items;
}

function int GetWeaponPatternIndex()
{
	local array<X2BodyPartTemplate> BodyParts;
	local int PartIndex;
	local int categoryValue;
	local X2BodyPartTemplateManager PartManager;

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartManager.GetFilteredUberTemplates("Patterns", self, `XCOMGAME.SharedBodyPartFilter.FilterAny, BodyParts);
	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( XComWeapon(ActorPawn).m_kGameWeapon.m_kAppearance.nmWeaponPattern == BodyParts[PartIndex].DataName )
		{
			categoryValue = PartIndex;
			break;
		}
	}

	return categoryValue;
}

simulated function array<string> GetWeaponColorList()
{
	local XComLinearColorPalette Palette;
	local array<string> Colors; 
	local int i; 

	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	for(i = 0; i < Palette.Entries.length; i++)
	{
		Colors.AddItem(class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[i].Primary, class'XComCharacterCustomization'.default.UIColorBrightnessAdjust));
	}

	return Colors;
}
reliable client function WeaponColorSelector()
{
	//If an extra click sneaks in, multiple color selectors will be created on top of each other and leak. 
	if( ColorSelector != none ) return; 

	CreateCustomizationState();
	HideListItems();
	CustomizeList.Hide();
	ColorSelector = Spawn(class'UIColorSelector', self);
	ColorSelector.InitColorSelector(, ColorSelectorX, ColorSelectorY, ColorSelectorWidth, ColorSelectorHeight,
		GetWeaponColorList(), PreviewWeaponColor, SetWeaponColor,
		UpdatedWeapon.WeaponAppearance.iWeaponTint);

	SlotsListContainer.GetChildByName('BG').ProcessMouseEvents(ColorSelector.OnChildMouseEvent);
	CleanupCustomizationState();
}
function PreviewWeaponColor(int iColorIndex)
{
	local array<string> Colors;
	Colors = GetWeaponColorList();
	CreateCustomizationState();
	UpdatedWeapon.WeaponAppearance.iWeaponTint = WrapIndex(iColorIndex, 0, Colors.Length);
	XComWeapon(ActorPawn).m_kGameWeapon.SetAppearance(UpdatedWeapon.WeaponAppearance);
	CleanupCustomizationState();
}
function SetWeaponColor(int iColorIndex)
{
	local XComGameState_Unit Unit;
	local array<string> Colors;

	Colors = GetWeaponColorList();
	CreateCustomizationState();
	UpdatedWeapon.WeaponAppearance.iWeaponTint = WrapIndex(iColorIndex, 0, Colors.Length);
	XComWeapon(ActorPawn).m_kGameWeapon.SetAppearance(UpdatedWeapon.WeaponAppearance);

	// Transfer the new weapon color back to the owner Unit's appearance data ONLY IF the weapon is otherwise unmodified
	Unit = GetUnit();
	if (Unit != none && !UpdatedWeapon.HasBeenModified())
	{
		Unit = XComGameState_Unit(CustomizationState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.kAppearance.iWeaponTint = UpdatedWeapon.WeaponAppearance.iWeaponTint;
	}

	SubmitCustomizationChanges();

	CloseColorSelector();
	CustomizeList.Show();
	UpdateCustomization(none);
	ShowListItems();
}

simulated function HideListItems()
{
	local int i;
	for(i = 0; i < ActiveList.ItemCount; ++i)
	{
		ActiveList.GetItem(i).Hide();
	}
}
simulated function ShowListItems()
{
	local int i;
	for(i = 0; i < ActiveList.ItemCount; ++i)
	{
		ActiveList.GetItem(i).Show();
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	
	if (ActiveList != none)
	{
		if (ColorSelector != none && ColorSelector.OnUnrealCommand(cmd, arg))
		{
			return true;
		}
	
		switch (cmd)
		{
			case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
			case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
				if (CustomizeList != none && CustomizeList.OnUnrealCommand(cmd, arg))
				{
					return true;
				}

			break;
		}
	}

	return super.OnUnrealCommand(cmd, arg);
}
simulated function OnAccept()
{
	if (ActiveList.SelectedIndex == -1)
	{
		CustomizeList.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_BUTTON_A, 
			class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
		return;
	}

	OnItemClicked(ActiveList, ActiveList.SelectedIndex);
}

simulated function OnCancel()
{
	if(ColorSelector != none)
	{
		CloseColorSelector(true);
	}
	else if(ActiveList == SlotsList)
	{
		`XCOMGRI.DoRemoteEvent(DisableWeaponLightingEvent);

		super.OnCancel(); // exists screen
	}
	else
	{
		ChangeActiveList(SlotsList);
	}
}

simulated function CloseColorSelector(optional bool bCancelColorSelection)
{
	if( bCancelColorSelection )
	{
		ColorSelector.OnCancelColor();
	}
	else
	{
		ColorSelector.Remove();
		ColorSelector = none;
	}

	// restore mouse events to slot list
	SlotsListContainer.GetChildByName('BG').ProcessMouseEvents(SlotsList.OnChildMouseEvent);
}

simulated function bool HasWeaponChanged()
{
	local XComGameState_Item PrevState;
	PrevState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(UpdatedWeapon.GetReference().ObjectID));
	return PrevState.WeaponAppearance != UpdatedWeapon.WeaponAppearance || PrevState.Nickname != UpdatedWeapon.Nickname;
}

simulated function CreateCustomizationState()
{
	if (CustomizationState == none) // Only create a new customization state if one doesn't already exist
	{
		CustomizationState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Weapon Customize");
	}
	UpdatedWeapon = XComGameState_Item(CustomizationState.ModifyStateObject(class'XComGameState_Item', WeaponRef.ObjectID));
}

simulated function OpenWeaponNameInputBox()
{
	local TInputDialogData kData;

//	if(!`GAMECORE.WorldInfo.IsConsoleBuild() || `ISCONTROLLERACTIVE )
//	{
		kData.strTitle = m_strCustomizeWeaponName;
		kData.iMaxChars = class'XComCharacterCustomization'.const.NICKNAME_NAME_MAX_CHARS;
		kData.strInputBoxText = UpdatedWeapon.Nickname;
		kData.fnCallback = OnNameInputBoxClosed;

		Movie.Pres.UIInputDialog(kData);
/*	}
	else
	{
		Movie.Pres.UIKeyboard( m_strCustomizeWeaponName, 
			UpdatedWeapon.Nickname, 
			VirtualKeyboard_OnNameInputBoxAccepted, 
			VirtualKeyboard_OnNameInputBoxCancelled,
			false, 
			class'XComCharacterCustomization'.const.NICKNAME_NAME_MAX_CHARS
		);
	}*/
}

function OnNameInputBoxClosed(string text)
{
	CreateCustomizationState();
	UpdatedWeapon.Nickname = text;
	SubmitCustomizationChanges();
	SetWeaponReference(WeaponRef);
}
function VirtualKeyboard_OnNameInputBoxAccepted(string text, bool bWasSuccessful)
{
	if(bWasSuccessful && text != "") //ADDED_SUPPORT_FOR_BLANK_STRINGS - JTA 2016/6/9
	{
		OnNameInputBoxClosed(text);
	}
}

function VirtualKeyboard_OnNameInputBoxCancelled()
{
	
}

simulated function OnReceiveFocus()
{
	// Clean up pending game states to prevent a RedScreen that occurs due to Avenger visibility changes
	// (in XGBase.SetAvengerVisibility, called by XComCamState_HQ_BaseRoomView.InitRoomView)
	if(CustomizationState != none) SubmitCustomizationChanges();

	MouseGuard.ActorPawn = ActorPawn;
	super.OnReceiveFocus();

	UpdateCustomization(none);
}

simulated function SubmitCustomizationChanges()
{
	if(HasWeaponChanged()) 
	{
		`GAMERULES.SubmitGameState(CustomizationState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(CustomizationState);
	}
	CustomizationState = none;
	UpdatedWeapon = none;
}

simulated function CleanupCustomizationState()
{
	if (CustomizationState != none) // Only cleanup the CustomizationState if it isn't already none
	{
		`XCOMHISTORY.CleanupPendingGameState(CustomizationState);
	}
	CustomizationState = none;
	UpdatedWeapon = none;
}

simulated function ReleasePawn(optional bool bForce)
{
	ActorPawn.Destroy();
	ActorPawn = none;
}

simulated static function bool CanCycleTo(XComGameState_Unit Unit)
{
	local TWeaponUpgradeAvailabilityData Data;

	class'UIUtilities_Strategy'.static.GetWeaponUpgradeAvailability(Unit, Data);

	// Logic taken from UIArmory_MainMenu
	return super.CanCycleTo(Unit) && Data.bHasWeaponUpgrades && Data.bHasModularWeapons && Data.bCanWeaponBeUpgraded;
}

function InterpolateWeapon()
{
	local Vector LocationLerp;
	local Rotator RotatorLerp;
	local Quat StartRotation;
	local Quat GoalRotation;
	local Quat ResultRotation;
	local Vector GoalLocation;
	local PointInSpace PlacementActor;

	// Variables for Issue #832
	local Vector BeginLocation, Offset;
	local XComGameState_Item WeaponState;
	local int Index;
	
	PlacementActor = GetPlacementActor();
	GoalLocation = PlacementActor.Location;
	if(PawnLocationTag != '')
	{
		if(VSize(GoalLocation - ActorPawn.Location) > 0.1f)
		{
			LocationLerp = VLerp(ActorPawn.Location, GoalLocation, 0.1f);
			ActorPawn.SetLocation(LocationLerp);
		}

		// if MouseGuard is handling rotation of the weapon, stop rotating it here to prevent conflict
		if(MouseGuard.ActorPawn == none && ActiveList.SelectedIndex != -1 && UIArmory_WeaponUpgradeItem(ActiveList.GetSelectedItem()).UpgradeTemplate != none)
		{
			StartRotation = QuatFromRotator(ActorPawn.Rotation);
			GoalRotation = QuatFromRotator(PlacementActor.Rotation);
			ResultRotation = QuatSlerp(StartRotation, GoalRotation, 0.1f, true);
			RotatorLerp = QuatToRotator(ResultRotation);
			ActorPawn.SetRotation(RotatorLerp);
		}
	}
	
	// Start Issue #832
	/// HL-Docs: feature:AdjustPositionOfWeaponPawn; issue:832; tags:customization
	/// When a weapon pawn is displayed in the weapon upgrade view it sets the position to the root bone of the mesh at the center of the screen. 
	/// Some weapon models simply do not fit correctly on the screen and obscure the UI. This fix aims to adjust that. It moves the position of the 
	/// created pawn by specified offset values from a config entry in the `XComUI.ini`.
	/// x is left/right with moving left being positive
	/// y is fore/aft with moving aft being positive (zoom level)
	/// z is up/down with moving up being positive
	/// Use this feature by creating the following lines in `XComUI.ini`:
	///
	/// ```ini
	/// [XComGame.UIArmory_WeaponUpgrade]
	/// ;template
	/// ;+WeaponViewOffsets=(Template=, offset_x=0.0, offset_y=0.0, offset_z=0.0)
	/// ;example that shifts the sniper rifles to the left, up a little and slightly smaller
	/// +WeaponViewOffsets=(Template=SniperRifle_CV, offset_x=20, offset_y=10, offset_z=10)
	/// +WeaponViewOffsets=(Template=SniperRifle_MG, offset_x=20, offset_y=10, offset_z=10)
	/// +WeaponViewOffsets=(Template=SniperRifle_BM, offset_x=20, offset_y=10, offset_z=10)
	/// ```

	// Save the original position of the actor
	BeginLocation = ActorPawn.Location;

	// Make sure we have got the right weapon details for the pawn/actor
	WeaponState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
	if (WeaponState == none)
		return;
		
	Index = default.WeaponViewOffsets.Find('Template', WeaponState.GetMyTemplateName());
	if (Index == INDEX_NONE) 
		return;

	// Add an offset to the camera/root based on the weapon template ... this adjusts the weapons position on the screen
	Offset.x = default.WeaponViewOffsets[Index].offset_x;
	Offset.y = default.WeaponViewOffsets[Index].offset_y;
	Offset.z = default.WeaponViewOffsets[Index].offset_z;

	GoalLocation = BeginLocation + Offset;

	if (VSize(GoalLocation - ActorPawn.Location) > 0.1f)
	{
		LocationLerp = VLerp(ActorPawn.Location, GoalLocation, 0.1f);
		ActorPawn.SetLocation(LocationLerp);
	}
	// End Issue #832
}

simulated function OnListChildMouseEvent(UIPanel Panel, int Cmd)
{
	// if we get any mouse event on the list, stop mouse guard rotation
	//MouseGuard.SetActorPawn(none);
}

simulated function OnMouseGuardMouseEvent(UIPanel Panel, int Cmd)
{
	// resume mouse guard rotation if mouse moves over mouse guard
	/*switch(Cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		MouseGuard.SetActorPawn(ActorPawn, MouseGuard.ActorRotation);
		WeaponStats.PopulateData(XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID)));
		RestoreWeaponLocation();
		break;
	}*/
}

simulated function RestoreWeaponLocation()
{
	local XComGameState_Item Weapon;
	Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(WeaponRef.ObjectID));
	PawnLocationTag = X2WeaponTemplate(Weapon.GetMyTemplate()).UIArmoryCameraPointTag;
}

simulated function Remove()
{
	super.Remove();
	ClearTimer(nameof(InterpolateWeapon));
}

simulated function OnLoseFocus()
{
	MouseGuard.ActorPawn = none;
	super.OnLoseFocus();
}

//==============================================================================

simulated function SetSlotsListTitle(string ListTitle)
{
	MC.FunctionString("setLeftPanelTitle", ListTitle);
}

simulated function SetUpgradeListTitle(string ListTitle)
{
	MC.FunctionString("setRightPanelTitle", ListTitle);
}

simulated function SetCustomizeTitle(string ListTitle)
{
	MC.FunctionString("setCustomizeTitle", ListTitle);
}

simulated function SetWeaponName(string WeaponName)
{
	MC.FunctionString("setWeaponName", WeaponName);
}

simulated function SetEquippedText(string EquippedLabel, string SoldierName)
{
	MC.BeginFunctionOp("setEquipedText");
	MC.QueueString(EquippedLabel);
	MC.QueueString(SoldierName);
	MC.EndOp();
}

// Passing empty strings hides the upgrade description box
simulated function SetUpgradeText(optional string UpgradeName, optional string UpgradeDescription)
{
	MC.BeginFunctionOp("setUpgradeText");
	MC.QueueString(UpgradeName);
	MC.QueueString(UpgradeDescription);
	MC.EndOp();
}

simulated function SetAvailableSlots(string SlotsAvailableLabel, string NumAvailableSlots)
{
	MC.BeginFunctionOp("setUpgradeCount");
	MC.QueueString(SlotsAvailableLabel);
	MC.QueueString(NumAvailableSlots);
	MC.EndOp();
}

//==============================================================================

defaultproperties
{
	LibID = "WeaponUpgradeScreenMC";
	CameraTag = "UIBlueprint_Loadout";
	DisplayTag = "UIBlueprint_Loadout";
	bHideOnLoseFocus = false;
}
