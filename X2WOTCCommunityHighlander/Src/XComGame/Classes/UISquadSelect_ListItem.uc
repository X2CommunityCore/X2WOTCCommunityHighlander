//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect_ListItem
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: Displays information pertaining to a single soldier in the Squad Select screen
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISquadSelect_ListItem extends UIPanel;

var int SlotIndex;
var bool bDisabled;

// Disable functionality for certain buttons
var bool bDisabledLoadout;
var bool bDisabledEdit;
var bool bDisabledDismiss;
var array<EInventorySlot> CannotEditSlots;

var UIPanel DynamicContainer;
var UIImage PsiMarkup;
var UIPanel AbilityIcons;
var UIList UtilitySlots;
var UIBondIcon BondIcon; 
var UIPanel Flyover; 

var localized string m_strSelectUnit;
var localized string m_strBackpack;
var localized string m_strBackpackDescription;
var localized string m_strEmptyHeavyWeapon;
var localized string m_strEmptyHeavyWeaponDescription;
var localized string m_strPromote;
var localized string m_strEdit;
var localized string m_strDismiss;
var localized string m_strNeedsMediumArmor;
var localized string m_strNoUtilitySlots;
var localized string m_strIncreaseSquadSize;
var localized string m_strTiredTooltip; 

enum ESquadSelectButton
{
	eSSB_Promote,
	eSSB_Edit,
	eSSB_Dismiss,
	eSSB_WeaponPrime,
	eSSB_WeaponHeavy,
	eSSB_Utility,
	eSSB_Bond,     // bsg-nlong (1.23.17): Adding controller support for selecting soldier bond
};
var ESquadSelectButton m_eActiveButton;

var Bool bEditDisabled;
var Bool bDismissDisabled;
var Bool bDirty;
var Bool bReverseInitialUtilityFocus; //set externally to indicate that focus is coming from a higher index (moving left horizontally)
simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	DynamicContainer = Spawn(class'UIPanel', self).InitPanel('dynamicContainerMC');
	
	PsiMarkup = Spawn(class'UIImage', DynamicContainer).InitImage(, class'UIUtilities_Image'.const.PsiMarkupIcon);
	PsiMarkup.SetScale(0.7).SetPosition(220, 258).Hide(); // starts off hidden until needed
	SetDirty(true, false);

	BondIcon = Spawn(class'UIBondIcon', self).InitBondIcon('bondIconMC', , OnClickBondIcon);
	
	CreateFlyoverTooltip();
	
	return self;
}

// bsg-nlong (1.23.17): Setting the active button to the first active one when initialized. m_eActiveButton was being initialized
// as the promote button by default which made soliders that weren't eligible for promotion have no button highlighted by default when selected
simulated function OnInit()
{
	// bsg-nlong (2.8.17): To Prevent an infinite loop in the tutorial we will loop through the buttons once, if no valid one is found we'll return the value to normal
	local int firstAvailableButton;

	super.OnInit();

	if( `ISCONTROLLERACTIVE )
	{
		// bsg-jrebar (5/30/17): loop for a first button if needed
		for( firstAvailableButton = m_eActiveButton; firstAvailableButton < ESquadSelectButton.EnumCount; ++firstAvailableButton)
		{
			m_eActiveButton = ESquadSelectButton(firstAvailableButton);
			if(!IsActiveButtonDisabled())
				break;
		}

		if( firstAvailableButton >= ESquadSelectButton.EnumCount )
		{
			for( firstAvailableButton = 0; firstAvailableButton < ESquadSelectButton.EnumCount; ++firstAvailableButton)
			{
				m_eActiveButton = ESquadSelectButton(firstAvailableButton);
				if(!IsActiveButtonDisabled())
					break;
			}
		}
		// bsg-jrebar (5/30/17): end
	}
	// bsg-nlong (2.8.17): end
}
// bsg-nlong (1.23.17): end
 
simulated function OnClickBondIcon(UIBondIcon Icon)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID));

	if(UnitState.GetSoldierClassTemplate().bCanHaveBonds )
	{
		SetDirty(true);
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoBond));
	}
}

simulated function GoBond()
{
	//We need an armory screen beneath the soldier bonds to handle the pawn. 
	`HQPRES.UIArmory_MainMenu(UISquadSelect(Screen).XComHQ.Squad[UISquadSelect(screen).m_iSelectedSlot]);
	`HQPRES.UISoldierBonds(GetUnitRef());
}

simulated function UpdateData(optional int Index = -1, optional bool bDisableEdit, optional bool bDisableDismiss, optional bool bDisableLoadout, optional array<EInventorySlot> CannotEditSlotsList)
{
	local bool bCanPromote;
	local string ClassStr, NameStr;
	local int i, NumUtilitySlots; //, UtilityItemIndex, NumUnitUtilityItems; // Issue #118, not needed
	local float UtilityItemWidth, UtilityItemHeight;
	local UISquadSelect_UtilityItem UtilityItem;
	//local array<XComGameState_Item> EquippedItems; // Issue #118, unneeded
	local XComGameState_Unit Unit;
	local XComGameState_Item PrimaryWeapon, HeavyWeapon;
	local X2WeaponTemplate PrimaryWeaponTemplate, HeavyWeaponTemplate;
	local X2AbilityTemplate HeavyWeaponAbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;
	//local XComGameState_ResistanceFaction FactionState; //Issue #1134, not needed
	local StackedUIIconData StackedClassIcon; // Variable for issue #1134

	// Variables for Issue #118
	local CHUIItemSlotEnumerator En;
	local bool AddedMedkitHint;

	if(bDisabled)
		return;

	SlotIndex = Index != -1 ? Index : SlotIndex;

	bDisabledEdit = bDisableEdit;
	bDisabledDismiss = bDisableDismiss;
	bDisabledLoadout = bDisableLoadout;
	CannotEditSlots = CannotEditSlotsList;

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
		AS_SetEmpty(m_strSelectUnit);
		AS_SetUnitHealth(-1, -1);
		AS_SetUnitStatus("", "");

		AbilityIcons.Remove();
		AbilityIcons = none;

		DynamicContainer.Hide();
		BondIcon.SetBondLevel(-1);
		
		if( !Movie.IsMouseActive() )
			HandleEmptyListItemFocus();
	}
	else
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID));
		bCanPromote = (Unit.ShowPromoteIcon());

		UtilitySlots.Show();
		DynamicContainer.Show();
		//Backpack controlled separately by the heavy weapon info. 

	//	if( Navigator.SelectedIndex == -1 )
//			Navigator.SelectFirstAvailable();

		//FactionState = Unit.GetResistanceFaction(); //Issue #1134, not needed

		// Issue #118 Start
		En = class'CHUIItemSlotEnumerator'.static.CreateEnumerator(Unit, , , true /* UseUnlockHints */);
		i = -1;
		UtilitySlots.ClearItems();
		AddedMedkitHint = !(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress);
		while (En.HasNext())
		{
			En.Next();
			// We can only show small slots, the other ones are hardcoded in flash
			if (class'CHItemSlot'.static.SlotIsSmall(En.Slot))
			{
				i++;

				if(i >= UtilitySlots.ItemCount)
				{
					UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.CreateItem(class'UISquadSelect_UtilityItem').InitPanel());
				}
				UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(i));
				UtilityItem.CannotEditSlots = CannotEditSlotsList;
				if (bDisableLoadout || En.IsLocked)
				{
					if (En.ItemState == none)
					{
						UtilityItem.SetLocked(En.IsLocked ? En.LockedReason : "");
					}
					else
					{
						// Send 2 as the total number, we fix it afterwards
						UtilityItem.SetDisabled(En.ItemState, En.Slot, En.IsMultiSlot ? En.IndexInSlot : 0, 2);
					}

					if(GetChildByName('attentionIconMC', false) != none)
					{
						GetChildByName('attentionIconMC').Remove();
					}
				}
				else
				{
					// Send 2 as the total number, we fix it afterwards
					UtilityItem.SetAvailable(En.ItemState, En.Slot, En.IsMultiSlot ? En.IndexInSlot : 0, 2);
					if (En.Slot == eInvSlot_Utility && !AddedMedkitHint)
					{
						AddedMedkitHint = true;
						// spawn the attention icon externally so it draws on top of the button and image 
						Spawn(class'UIPanel', UtilityItem).InitPanel('attentionIconMC', class'UIUtilities_Controls'.const.MC_AttentionIcon)
							.SetPosition(2, 4)
							.SetSize(70, 70); //the animated rings count as part of the size. 
					}
					else if(GetChildByName('attentionIconMC', false) != none)
					{
						GetChildByName('attentionIconMC').Remove();
					}
				}
			}
		}
		NumUtilitySlots = UtilitySlots.GetItemCount();
		UtilityItemWidth = (UtilitySlots.GetTotalWidth() - (UtilitySlots.ItemPadding * (NumUtilitySlots - 1))) / NumUtilitySlots;
		UtilityItemHeight = UtilitySlots.Height;
		// Now fix up the item size
		for(i = 0; i < NumUtilitySlots; ++i)
		{
			UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(i));
			UtilityItem.SetSize(UtilityItemWidth, UtilityItemHeight);
			UtilityItem.SetNumSlots(NumUtilitySlots);
			UtilitySlots.OnItemSizeChanged(UtilityItem);
		}
		// Issue #118 End
		
		// Don't show class label for rookies since their rank is shown which would result in a duplicate string
		if(Unit.GetRank() > 0)
		{
			// Start Issue #106
			ClassStr = class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetSoldierClassDisplayName()), eUIState_Faded, 17);
			// End Issue #106
		}
		else
			ClassStr = "";

		PrimaryWeapon = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon);
		if(PrimaryWeapon != none)
		{
			PrimaryWeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
		}

		NameStr = Unit.GetName(eNameType_Last);
		if (NameStr == "") // If the unit has no last name, display their first name instead
		{
			NameStr = Unit.GetName(eNameType_First);
		}

		// TUTORIAL: Disable buttons if tutorial is enabled
		if(bDisableEdit)
			MC.FunctionVoid("disableEdit");
		if(bDisableDismiss)
			MC.FunctionVoid("disableDismiss");
		bEditDisabled = bDisableEdit; //Used in controller nav
		bDismissDisabled = bDisableDismiss; //used in controller nav

		// Start Issue #106, #408
		AS_SetFilled( class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetSoldierRankName()), eUIState_Normal, 18),
					  class'UIUtilities_Text'.static.GetColoredText(Caps(NameStr), eUIState_Normal, 22),
					  class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetName(eNameType_Nick)), eUIState_Header, 28),
					  Unit.GetSoldierClassIcon(), Unit.GetSoldierRankIcon(),
					  class'UIUtilities_Text'.static.GetColoredText(m_strEdit, bDisableEdit ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(m_strDismiss, bDisableDismiss ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(PrimaryWeaponTemplate.GetItemFriendlyName(PrimaryWeapon.ObjectID), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(class'UIArmory_loadout'.default.m_strInventoryLabels[eInvSlot_PrimaryWeapon], bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(GetHeavyWeaponName(), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(GetHeavyWeaponDesc(), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  (bCanPromote ? m_strPromote : ""), Unit.IsPsiOperative() || (Unit.HasPsiGift() && Unit.GetRank() < 2), ClassStr);
		// End Issue #106, #408

		AS_SetUnitHealth(class'UIUtilities_Strategy'.static.GetUnitCurrentHealth(Unit), class'UIUtilities_Strategy'.static.GetUnitMaxHealth(Unit));

		if( Unit.UsesWillSystem() )
		{
			AS_SetUnitWill(class'UIUtilities_Strategy'.static.GetUnitWillPercent(Unit), class'UIUtilities_Strategy'.static.GetUnitWillColorString(Unit));
		}
		else
		{
			AS_SetUnitWill(-1, "");
		}

		// Start Issue #1134
		StackedClassIcon = Unit.GetStackedClassIcon();
		if (StackedClassIcon.Images.Length > 0)
		{
			AS_SetFactionIcon(StackedClassIcon);
		}
		else
		{
			MC.FunctionVoid("clearUnitFactionIcon");
		}
		// End Issue #1134

		if(Unit.BelowReadyWillState())
		{
			AS_SetUnitStatus(class'UIUtilities_Text'.static.InjectImage("power_icon_warning", 16, 16) $ Unit.GetMentalStateLabel(), class'UIUtilities_Strategy'.static.GetUnitWillColorString(Unit));
		}
		else
		{
			AS_SetUnitStatus("", "");
		}
		
		PsiMarkup.SetVisible(Unit.HasPsiGift());

		HeavyWeapon = Unit.GetItemInSlot(eInvSlot_HeavyWeapon);
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

		if(!Unit.GetSoldierClassTemplate().bCanHaveBonds)
		{
			BondIcon.AnimateCohesion(false);
			BondIcon.SetBondLevel(-1);
			BondIcon.RemoveTooltip();
		}
		else if( Unit.HasSoldierBond(BondmateRef, BondData) )
		{
			BondIcon.AnimateCohesion(false);
			BondIcon.SetBondLevel(BondData.BondLevel, UISquadSelect(Screen).IsUnitOnSquad(BondmateRef));
			if( Index == 5 )
				BondIcon.SetBondmateTooltip(BondmateRef, class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
			else
				BondIcon.SetBondmateTooltip(BondmateRef);
		}
		else
		{
			BondIcon.SetBondLevel(0);
			if (Unit.HasSoldierBondAvailable(BondmateRef, BondData))
			{
				BondIcon.AnimateCohesion(true);
				BondIcon.SetTooltipText(class'XComHQPresentationLayer'.default.m_strBannerBondAvailable);
			}
			else
			{
				BondIcon.AnimateCohesion(false);
				BondIcon.SetTooltipText(class'UISoldierBondScreen'.default.BondTitle);
			}
		}
	}
	RefreshFocus();
	//bsg-cballinger (7.8.16): disable update optimization on SquadSelect for now (dirty is now always set). Causes items to not update properly on the SquadSelect screen when changes are made to the squad loadout
}

simulated function DisableSlot()
{
	bDisabled = true;
	AS_SetDisabled(m_strIncreaseSquadSize);
	BondIcon.Hide();
	DynamicContainer.Hide();
}

simulated function AnimateIn(optional float AnimationIndex = -1.0)
{
	MC.FunctionNum("animateIn", AnimationIndex);
}

// bsg-jrebar (5/30/17): making it work for MP Screens
function StateObjectReference GetUnitRef()
{
	local StateObjectReference NullRef; 
	local UISquadSelect SquadScreen;
	local UIMPShell_SquadEditor MPSquadScreen;

	SquadScreen = UISquadSelect(Screen);
	MPSquadScreen = UIMPShell_SquadEditor(Screen);
	if(SquadScreen != none)
	{
		if( SlotIndex >= SquadScreen.XComHQ.Squad.length)
			return NullRef;
		else
			return SquadScreen.XComHQ.Squad[SlotIndex];
	}
	else if(MPSquadScreen != none)
	{
		if(SlotIndex >= MPSquadScreen.XComHQ.Squad.length)
			return NullRef;
		else
			return MPSquadScreen.XComHQ.Squad[SlotIndex];
	}
}
// bsg-jrebar (5/30/17): end

simulated function string GetHeavyWeaponName()
{
	if(GetEquippedHeavyWeapon() != none)
		return GetEquippedHeavyWeapon().GetMyTemplate().GetItemFriendlyName();
	else
		return HasHeavyWeapon() ? m_strEmptyHeavyWeapon : "";
}

simulated function string GetHeavyWeaponDesc()
{
	if(GetEquippedHeavyWeapon() != none)
		return class'UIArmory_loadout'.default.m_strInventoryLabels[eInvSlot_HeavyWeapon];
	else
		return "";
}

simulated function XComGameState_Item GetEquippedHeavyWeapon()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID)).GetItemInSlot(eInvSlot_HeavyWeapon);
}

function bool HasHeavyWeapon()
{
	if(GetUnitRef().ObjectID > 0)
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID)).HasHeavyWeapon();
	return false;
}

//------------------------------------------------------

simulated function OnClickedPromote()
{
	UISquadSelect(Screen).m_iSelectedSlot = SlotIndex;
	if( GetUnitRef().ObjectID > 0 )
	{
		//UISquadSelect(Screen).bDirty = true;
		SetDirty(true);
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoPromote));
	}
}

simulated function GoPromote()
{
	`HQPRES.UIArmory_Promotion(GetUnitRef());
}

// bsg-jrebar (5/30/17): making it work for MP Screens
simulated function OnClickedPrimaryWeapon()
{
	local UISquadSelect SquadScreen;
	local UIMPShell_SquadEditor MPSquadScreen;

	SquadScreen = UISquadSelect(Screen);
	MPSquadScreen = UIMPShell_SquadEditor(Screen);

	if (bDisabledLoadout)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	if(SquadScreen != none)
	{
		SquadScreen.m_iSelectedSlot = SlotIndex;
		if(GetUnitRef().ObjectID > 0)
		{
			//SquadScreen.bDirty = true;
			SetDirty(true);
			SquadScreen.SnapCamera();
			SetTimer(0.1f, false, nameof(GoToPrimaryWeapon));
		}
	}
	else if(MPSquadScreen != none)
	{
		if(GetUnitRef().ObjectID > 0)
		{
			//MPSquadScreen.bDirty = true;
			SetDirty(true);
			MPSquadScreen.SnapCamera();
			SetTimer(0.1f, false, nameof(GoToPrimaryWeapon));
		}
	}
}
// bsg-jrebar (5/30/17): end

simulated function GoToPrimaryWeapon()
{
	`HQPRES.UIArmory_Loadout(GetUnitRef(), CannotEditSlots);
	
	if (CannotEditSlots.Find(eInvSlot_PrimaryWeapon) == INDEX_NONE)
	{
		UIArmory_Loadout(Movie.Stack.GetScreen(class'UIArmory_Loadout')).SelectWeapon(eInvSlot_PrimaryWeapon);
	}
}

// bsg-jrebar (5/30/17): making it work for MP Screens
simulated function OnClickedHeavyWeapon()
{
	local UISquadSelect SquadScreen;
	local UIMPShell_SquadEditor MPSquadScreen;

	SquadScreen = UISquadSelect(Screen);
	MPSquadScreen = UIMPShell_SquadEditor(Screen);

	if (bDisabledLoadout)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	if(SquadScreen != none)
	{
		SquadScreen.m_iSelectedSlot = SlotIndex;
		if(GetUnitRef().ObjectID > 0)
		{
			//SquadScreen.bDirty = true;
			SetDirty(true);
			SquadScreen.SnapCamera();
			SetTimer(0.1f, false, nameof(GoToHeavyWeapon));
		}
	}
	else if(MPSquadScreen != none)
	{
		if(GetUnitRef().ObjectID > 0)
		{
			//SquadScreen.bDirty = true;
			SetDirty(true);
			MPSquadScreen.SnapCamera();
			SetTimer(0.1f, false, nameof(GoToHeavyWeapon));
		}
	}
}
// bsg-jrebar (5/30/17): end

simulated function GoToHeavyWeapon()
{
	`HQPRES.UIArmory_Loadout(GetUnitRef(), CannotEditSlots);

	if (CannotEditSlots.Find(eInvSlot_HeavyWeapon) == INDEX_NONE)
	{
		UIArmory_Loadout(Movie.Stack.GetScreen(class'UIArmory_Loadout')).SelectWeapon(eInvSlot_HeavyWeapon);
	}
}

// bsg-jrebar (5/30/17): making it work for MP Screens
simulated function OnClickedDismissButton()
{
	local UISquadSelect SquadScreen;
	local UIMPShell_SquadEditor MPSquadScreen;
	local XComGameState_HeadquartersXCom XComHQ;
	local int i;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(!XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ') || bDisabledDismiss)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	// destroy your tooltip so they dont leak as we open and close unit slots
	for (i = 0; i < UtilitySlots.GetItemCount(); i++)
	{
		UtilitySlots.GetItem(i).SetTooltipText("");
	}

	HandleButtonFocus(m_eActiveButton, false);

	SquadScreen = UISquadSelect(screen);
	MPSquadScreen = UIMPShell_SquadEditor(screen);
	if(SquadScreen != none)
	{
		//Need to refresh entire squad bond icon data. 
		SetDirty(true);

		SquadScreen.m_iSelectedSlot = SlotIndex;
		SquadScreen.ChangeSlot();
		
		UpdateData(); // passing no params clears the slot
		SquadScreen.UpdateData();
	}
	else if(MPSquadScreen != none)
	{
		UpdateData(); // passing no params clears the slot
		MPSquadScreen.SelectFirstListItem();
	}
}
// bsg-jrebar (5/30/17): end

simulated function OnClickedEditUnitButton()
{
	local UISquadSelect SquadScreen;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(!XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ') || bDisabledEdit)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	SquadScreen = UISquadSelect(screen);
	SquadScreen.m_iSelectedSlot = SlotIndex;
	
	if( XComHQ.Squad[SquadScreen.m_iSelectedSlot].ObjectID > 0 )
	{
		//UISquadSelect(Screen).bDirty = true;
		SetDirty(true);
		SquadScreen.SnapCamera();
		`HQPRES.UIArmory_MainMenu(XComHQ.Squad[SquadScreen.m_iSelectedSlot], 'PreM_CustomizeUI', 'PreM_SwitchToSoldier', 'PreM_GoToLineup', 'PreM_CustomizeUI_Off', 'PreM_SwitchToLineup');
		`XCOMGRI.DoRemoteEvent('PreM_GoToSoldier');
	}
}

simulated function OnClickedSelectUnitButton()
{
	local UISquadSelect SquadScreen;
	SquadScreen = UISquadSelect(Screen);
	SquadScreen.m_iSelectedSlot = SlotIndex;
	//UISquadSelect(Screen).bDirty = true;
	SetDirty(true);
	SquadScreen.SnapCamera();
	`HQPRES.UIPersonnel_SquadSelect(SquadScreen.ChangeSlot, SquadScreen.UpdateState, SquadScreen.XComHQ);
}

simulated function OnMouseEvent(int Cmd, array<string> Args)
{
	local string CallbackTarget;

	Super.OnMouseEvent(Cmd, Args);

	if(bDisabled) return;

	if(Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		CallbackTarget = Args[Args.Length - 2]; // -2 to account for bg within ButtonControls

		switch(CallbackTarget)
		{
		case "promoteButtonMC":         OnClickedPromote(); break;
		case "primaryWeaponButtonMC":   OnClickedPrimaryWeapon(); break;
		case "heavyWeaponButtonMC":     OnClickedHeavyWeapon(); break;
		case "dismissButtonMC":         OnClickedDismissButton(); break;
		case "selectUnitButtonMC":      OnClickedSelectUnitButton(); break;
		case "editButtonMC":            OnClickedEditUnitButton(); break;
		case "bondIconMC":              OnClickBondIcon(none); break;  // bsg-nlong (1.23.17): Adding controller support for the solider bond button
		}
	}
}

simulated function SetDirty(bool bIsDirty, optional bool bMarkSquadSelectScreen = true)
{
	bDirty = bIsDirty;
	if(bMarkSquadSelectScreen)
		UISquadSelect(Screen).bDirty = bIsDirty;
}
simulated function Bool ListItemIsEmpty()
{
	return MC.GetBool("isEmpty");
}

simulated function bool HasUnit()
{
	return `XCOMHQ.Squad.Length > SlotIndex && `XCOMHQ.Squad[SlotIndex].ObjectID > 0;
}

//Returns the variable name that is set in actionscript (useful for 'invoke' functions)
simulated function String GetActionscriptButtonString(ESquadSelectButton Button)
{
	switch(Button)
	{
		case eSSB_Dismiss:		return "dismissButton";
		case eSSB_Promote:		return "promoteButton";
		case eSSB_WeaponPrime:	return "primaryWeaponButton";
		case eSSB_WeaponHeavy:	return "heavyWeaponButton";
		case eSSB_Edit:			return "editButton";
		case eSSB_Bond:         return "bondIconMC"; // bsg-nlong (1.23.17): Adding controller support for the solider bond button
		default:				return "Error-ReturnCaseNotHandled";
	}
}

//simulates a mouse click
simulated function HandleButtonSelect()
{
	if( !IsVisible() )
		return; 

	if(ListItemIsEmpty())
	{
		OnClickedSelectUnitButton();
		return;
	}

	switch(m_eActiveButton)
	{
		case eSSB_Dismiss:		OnClickedDismissButton(); break;
		case eSSB_Promote:		OnClickedPromote(); break;
		case eSSB_WeaponPrime:	OnClickedPrimaryWeapon(); break;
		case eSSB_WeaponHeavy:	OnClickedHeavyWeapon(); break;
		case eSSB_Edit:			OnClickedEditUnitButton(); break;
		case eSSB_Utility:
			UISquadSelect_UtilityItem(UtilitySlots.GetSelectedItem()).Button.Click();
			break;
		case eSSB_Bond:         OnClickBondIcon(none); break; // bsg-nlong (1.23.17): Adding controller support for the solider bond button
		default:				break;
	}			
}

//Finds the next available index (looping if it moves out of bounds)
simulated function INT LoopButtonIndex(INT Index, Bool bDownward, INT MaxCount)
{
	Index = bDownward ? Index + 1 : Index - 1;
	if(Index < 0)
		Index = MaxCount - 1;
	Index = Index % MaxCount;

	return Index;
}

//Moves the focus of the button down the list of buttons with an enum in ESquadSelectButton
//checks for disabled states and skips them
simulated function ShiftButtonFocus(Bool bDownward)
{
	//removes focus from previous button/list
	HandleButtonFocus(m_eActiveButton, false);

	do
	{
		//Find index of next ListItem in sequence
		m_eActiveButton = ESquadSelectButton(LoopButtonIndex(INT(m_eActiveButton), bDownward, ESquadSelectButton.EnumCount));
	}
	//check for disabled buttons
	until( !IsActiveButtonDisabled() );

	//gives focus to the newly active button/list
	HandleButtonFocus(m_eActiveButton, true);	
}

//for cycling through the utility items while those are in focus
//iForceUtilityIndex attempts to set the focus directly (instead of shifting it). If that index is unavailable, it will continue through the loop
simulated function bool ShiftHorizontalFocus(Bool bIncreasing, optional int iForceUtilityIndex = -1)
{
	local int Index;
	local UISquadSelect_UtilityItem Item;

	if(m_eActiveButton == eSSB_Utility && UtilitySlots.ItemCount > 1)
	{
		//grabs Index locally to check for a change later
		Index = UtilitySlots.SelectedIndex;
		
		if(iForceUtilityIndex != -1)
		{
			if(bIncreasing)	Index = iForceUtilityIndex - 1;
			else			Index = iForceUtilityIndex + 1;
		}

		do
		{
			//grabs the next index
			if(bIncreasing)	Index++;
			else			Index--;

			if(Index < 0 || Index >= UtilitySlots.ItemCount)
				return false;

			Item = UISquadSelect_UtilityItem(UtilitySlots.GetItem(Index));
			if(Item == None) `log("ERROR: List Item found is not a UISquadSelect_ListItem. Breaking loop...");
		}
		//checks to make sure the next slot isn't disabled
		until(Item == None || !Item.Button.IsDisabled);

	//	//checks to make sure it didn't loop back to the original index
	//	//if(Index != UtilitySlots.SelectedIndex)
	//	{
			//remove current focus
			UtilitySlots.GetSelectedItem().OnLoseFocus();

			//Assign new current focus
			UtilitySlots.SetSelectedIndex(Index);

			//Give focus to new utility item
			Item.OnReceiveFocus();

			return true;
	//	}				
	}

	return false;
}

//checks for disabled states (used before giving buttons focus in vertical nav)
simulated function bool IsActiveButtonDisabled()
{
	// bsg-jrebar (5/30/17): Covering all buttons for disabled states
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID));

	//check for disabled buttons
	if(m_eActiveButton == eSSB_Edit && bEditDisabled)
		return true;
	else if(m_eActiveButton == eSSB_Dismiss && bDismissDisabled)
		return true;
	else if(m_eActiveButton == eSSB_WeaponPrime && bDisabledLoadout)
		return true;
	else if(m_eActiveButton == eSSB_WeaponHeavy && !HasHeavyWeapon())
		return true;
	// Issue #118 Start -- allow selecting utility slots even if the default one is not selected
	else if(m_eActiveButton == eSSB_Utility && (UtilitySlots.GetSelectedItem() != none && UISquadSelect_UtilityItem(UtilitySlots.GetSelectedItem()).Button.IsDisabled && !SelectNonDisabledUtilitySlot()))
	// Issue #118 end
		return true;
	else if(m_eActiveButton == eSSB_Promote && (UnitState == none || !UnitState.ShowPromoteIcon()))
		return true;
	else if(m_eActiveButton == eSSB_Bond && (UnitState == none || !UnitState.GetSoldierClassTemplate().bCanHaveBonds))
		return true;
	// bsg-jrebar (5/30/17): end
	
	return false;
}

// Issue #118 Start -- allow selecting utility slots even if the default one is not selected
simulated function bool SelectNonDisabledUtilitySlot()
{
	local int i;
	for (i = 0; i < UtilitySlots.GetItemCount(); i++)
	{
		if (!UISquadSelect_UtilityItem(UtilitySlots.GetItem(i)).Button.IsDisabled)
		{
			//remove current focus
			UtilitySlots.GetSelectedItem().OnLoseFocus();
			//Assign new current focus
			UtilitySlots.SetSelectedIndex(i);
			//Give focus to new utility item
			UtilitySlots.GetSelectedItem().OnReceiveFocus();
			return true;
		}
	}
	return false;
}
// Issue #118 End

//Handles the visuals to simulate mouse-hover focus
simulated function HandleButtonFocus(ESquadSelectButton ButtonControl, bool bFocusGiven)
{
	//all of the button assets are not visible if List Item is empty
	if(HandleEmptyListItemFocus())
		return;

	//GIVING focus to the button
	if(bFocusGiven)
	{
		if(m_eActiveButton == eSSB_Utility)
		{
			HandleUtilityItemFocus();
		}
		// bsg-nlong (1.23.17): Adding controller support for the solider bond button
		else if(m_eActiveButton == eSSB_Bond)
		{
			BondIcon.OnReceiveFocus();
			MC.FunctionVoid("onReceiveFocus");
		}
		// bsg-nlong (1.23.17): end
		else
		{
			Invoke(GetActionscriptButtonString(m_eActiveButton) $ ".onReceiveFocus");
			
			MC.FunctionVoid("onReceiveFocus"); //needs to call manually because the actionscript turns the visual focus off when the other buttons lose focus
		}
	}
	//REMOVING focus to from button
	else
	{
		if(m_eActiveButton == eSSB_Utility)
			UtilitySlots.GetSelectedItem().OnLoseFocus();
		// bsg-nlong (1.23.17): Adding controller support for the solider bond button
		else if(m_eActiveButton == eSSB_Bond)
			BondIcon.OnLoseFocus();
		// bsg-nlong (1.23.17): end
		else
			Invoke(GetActionscriptButtonString(m_eActiveButton) $ ".onLoseFocus");
	}
}

simulated function HandleUtilityItemFocus()
{
	local int NewIndex;

	if(bReverseInitialUtilityFocus)
	{
		//should should only trigger on the 'initial' focus given when the list item is given focus
		//so that the utility item on the RIGHT if given focus when it's parent list's focus comes from the RIGHT		
		bReverseInitialUtilityFocus = false;
		//sets focus to the first available index from the top/right
		ShiftHorizontalFocus(false, UtilitySlots.ItemCount - 1);
		MC.FunctionVoid("onReceiveFocus"); //needs to call manually because the actionscript turns the visual focus off when the other buttons lose focus
		return;
	}
	//if the user has been navigating vertically within this list item, it will grab the most recent utility slot that was selected
	else if(UtilitySlots.SelectedIndex > 0)
		NewIndex = UtilitySlots.SelectedIndex;
	else
		NewIndex = 0;

	UtilitySlots.GetItem(NewIndex).OnReceiveFocus();
	UtilitySlots.SetSelectedIndex(NewIndex);
	MC.FunctionVoid("onReceiveFocus"); //needs to call manually because the actionscript turns the visual focus off when the other buttons lose focus
}

//Resets the focus in actionscript, ensuring proper visual highlights
simulated function RefreshFocus()
{
	// bsg-jrebar (5/16/17): This needs to function for both use cases
	local UISquadSelect SquadScreen;	
	local UIMPShell_SquadEditor MPSquadScreen;

	SquadScreen = UISquadSelect(Screen);
	MPSquadScreen = UIMPShell_SquadEditor(Screen);

	if((SquadScreen != None && SquadScreen.m_iSelectedSlot == SlotIndex) || (MPSquadScreen != None))
	{	
		//Tells actionscript that it lost focus so it can properly gain it again cleanly
		OnLoseFocus();

		//Delay needed to wait for Flash to clear the previous focus
		SetTimer(0.25f, false, 'DelayedRefreshFocus');
	}
	// bsg-jrebar (5/16/17): end
}

//Called from a Timer in RefreshFocus()
simulated function DelayedRefreshFocus()
{	
	// bsg-jrebar (5/16/17): This needs to function for both use cases
	local UISquadSelect SquadScreen;
	local UIMPShell_SquadEditor MPSquadScreen;

	SquadScreen = UISquadSelect(Screen);
	MPSquadScreen = UIMPShell_SquadEditor(Screen);

	if((SquadScreen != None && SquadScreen.m_iSelectedSlot == SlotIndex) || (MPSquadScreen != None))
	{	
		OnReceiveFocus();
		SetSquadSelectButtonFocus();
	}
	// bsg-jrebar (5/16/17): end
}
//------------------------------------------------------

simulated function AS_SetFilled( string firstName, string lastName, string nickName,
								 string classIcon, string rankIcon, string editLabel, string dismissLabel, 
								 string primaryWeaponLabel, string primaryWeaponDescription,
								 string heavyWeaponLabel, string heavyWeaponDescription,
								 string promoteLabel, bool isPsiPromote, string className )
{
	mc.BeginFunctionOp("setFilledSlot");
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
	mc.EndOp();
}

simulated function AS_HasHeavyWeapon( bool bHasHeavyWeapon )
{
	mc.FunctionBool("setHeavyWeapon", bHasHeavyWeapon);
}

simulated function AS_SetEmpty( string label )
{
	mc.FunctionString("setEmptySlot", label);
}

simulated function AS_SetBlank( string label )
{
	mc.FunctionString("setBlankSlot", label);
}

simulated function AS_SetDisabled( string label )
{
	mc.FunctionString("setDisabledSlot", label);
}

simulated function AS_SetUnitHealth(int CurrentHP, int MaxHP)
{
	mc.BeginFunctionOp("setUnitHealth");
	mc.QueueNumber(CurrentHP);
	mc.QueueNumber(MaxHP);
	mc.EndOp();
}

//Attempts to set focus to the button, will grab the next button in line if that's not possible
simulated function SetSquadSelectButtonFocus(optional int ButtonEnumAsInt = 0, optional bool bReverseFocusIfUtility = false) //ESquadSelectButton
{
	local ESquadSelectButton ButtonEnum;
	local XComGameState_Unit Unit;

	ButtonEnum = ESquadSelectButton(ButtonEnumAsInt);
	
	if(ButtonEnum == eSSB_Promote)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID));
		if(Unit != none && Unit.ShowPromoteIcon())
		{
			ButtonEnum = ESquadSelectButton(ButtonEnum + 1);
			m_eActiveButton = ButtonEnum;
		}
	}

	//allows the player to move fluidly Right->Left while selecting a Utility item and there are more than 1
	if(bReverseFocusIfUtility && ButtonEnum == eSSB_Utility)
		bReverseInitialUtilityFocus = true;

	//If the previous listItem had a heavy weapon selected and this does not have that enabled, move to a lower index
	if(ButtonEnum == eSSB_WeaponHeavy && !HasHeavyWeapon())
		ButtonEnum = ESquadSelectButton(ButtonEnum - 1);

	//sets the active button to a lower increment b/c ShiftButtonFocus() always increases by at least 1
	if(ButtonEnum <= 0 || ButtonEnum >= ESquadSelectButton.EnumCount) //Desired index is 0
		m_eActiveButton = ESquadSelectButton(ESquadSelectButton.EnumCount - 1);
	else //Desired index is not 0
		m_eActiveButton = ESquadSelectButton(ButtonEnum - 1);

	//loops through buttons until it finds one that can be given focus (always increases m_eActiveButton by 1)
	ShiftButtonFocus(true);
}

simulated function AS_SetUnitWill(int WillPercent, string strColor)
{
	mc.BeginFunctionOp("setUnitWill");
	mc.QueueNumber(WillPercent);
	mc.QueueString(strColor);
	mc.EndOp();
}

simulated function AS_SetUnitStatus(string strStatusLabel, string strColor)
{
	mc.BeginFunctionOp("setStatusMessage");
	mc.QueueString(strStatusLabel);
	mc.QueueString(strColor);
	mc.EndOp();
}

public function AS_SetFactionIcon(StackedUIIconData IconInfo)
{
	local int i;

	if (IconInfo.Images.Length > 0)
	{
		MC.BeginFunctionOp("setUnitFactionIcon");
		MC.QueueBoolean(IconInfo.bInvert);
		for (i = 0; i < IconInfo.Images.Length; i++)
		{
			MC.QueueString("img:///" $ Repl(IconInfo.Images[i], ".tga", "_sm.tga"));
		}

		MC.EndOp();
	}
}

// Don't propagate focus changes to children
simulated function OnReceiveFocus()
{
	// bsg-jrebar (5/16/17): This needs to function for both use cases
	local UISquadSelect SquadScreen;
	local int firstAvailableButton;

	if( !bIsFocused )
	{
		SquadScreen = UISquadSelect(Screen);
		//if(SquadScreen != none)
		if( SquadScreen != none && SquadScreen.m_iSelectedSlot != SlotIndex )
		{
			SquadScreen.m_iSelectedSlot = SlotIndex;
			SquadScreen.m_kSlotList.SetSelectedItem(self);
		}

		if( `ISCONTROLLERACTIVE )
		{
			// bsg-jrebar (5/30/17): adding looping behavior for button selection
			for( firstAvailableButton = m_eActiveButton; firstAvailableButton < ESquadSelectButton.EnumCount; ++firstAvailableButton )
			{
				m_eActiveButton = ESquadSelectButton(firstAvailableButton);
				if( !IsActiveButtonDisabled() )
					break;
			}

			if( firstAvailableButton >= ESquadSelectButton.EnumCount )
			{
				for( firstAvailableButton = 0; firstAvailableButton < ESquadSelectButton.EnumCount; ++firstAvailableButton )
				{
					m_eActiveButton = ESquadSelectButton(firstAvailableButton);
					if( !IsActiveButtonDisabled() )
						break;
				}
			}
			// bsg-jrebar (5/30/17): end
		}

		MC.FunctionVoid("onReceiveFocus");
		bIsFocused = true;

		HandleButtonFocus(m_eActiveButton, true); // bsg-jrebar (5/30/17): Activate new button (handles empty case as well)
		// bsg-jrebar (5/16/17): end
	}
}

simulated function OnLoseFocus()
{
	// bsg-jrebar (5/16/17): This needs to function for both use cases
	local UISquadSelect SquadScreen;

	if( bIsFocused )
	{
		SquadScreen = UISquadSelect(Screen);

		if( SquadScreen != none )
		{
			SquadScreen.m_iSelectedSlot = SlotIndex;
			SquadScreen.m_kSlotList.SetSelectedItem(none);
		}

		MC.FunctionVoid("onLoseFocus");
		bIsFocused = false;
		HandleButtonFocus(m_eActiveButton, false);
		if( UtilitySlots != None )
		{
			//UtilitySlots.SelectedIndex = 0;
			bReverseInitialUtilityFocus = false;
		}
		
		// bsg-jrebar (5/16/17): end
	}
}

//Called when there is a focus change in 'HandleButtonFocus', returns TRUE if handled and no other focus changes are needed
simulated function bool HandleEmptyListItemFocus()
{
	if(GetUnitRef().ObjectID <= 0) //Will return true if the ListItem is empty
	{
		if(bIsFocused)
		{
			Invoke("selectUnitButton.onReceiveFocus");
		}
		else
		{
			Invoke("selectUnitButton.onLoseFocus");
		}

		//In actionscript, this function detects whether or not the button is in focus and changes the visuals accordingly
		MC.FunctionVoid("realizeUnitFocus");

		return true;
	}

	return false;
}

simulated function CreateFlyoverTooltip()
{
	local UITooltipMgr Mgr;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID));

	if( UnitState.GetMentalStateUIState() == eMentalState_Tired )
	{
		Mgr = XComHQPresentationLayer(Movie.Pres).m_kTooltipMgr;

		CachedTooltipId = Mgr.AddNewTooltipTextBox(m_strTiredTooltip,
												   10,
												   0,
												   string(MCPath) $".unitFlyover",
												   ,
												   ,
												   ,
												   true);
		bHasTooltip = true;
	}
}

defaultproperties
{
	LibID = "SquadSelectListItem";
	width = 282;
	bIsNavigable = true;
	bCascadeFocus = false;
}

//------------------------------------------------------