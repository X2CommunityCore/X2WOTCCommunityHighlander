
class UIArmory_MainMenu 
	extends UIArmory
	dependson(UIDialogueBox)
	dependson(UIUtilities_Strategy);

var localized string m_strTitle;
var localized string m_strCustomizeSoldier;
var localized string m_strCustomizeWeapon;
var localized string m_strAbilities;
var localized string m_strPromote;
var localized string m_strImplants;
var localized string m_strLoadout;
var localized string m_strSoldierBonds;
var localized string m_strDismiss;
var localized string m_strPropaganda;
var localized string m_strPromoteDesc;
var localized string m_strImplantsDesc;
var localized string m_strLoadoutDesc;
var localized string m_strSoldierBondsDesc;
var localized string m_strDismissDesc;
var localized string m_strPropagandaDesc;
var localized string m_strCustomizeWeaponDesc;
var localized string m_strCustomizeSoldierDesc;

var localized string m_strDismissDialogTitle;
var localized string m_strDismissDialogDescription;

var localized string m_strRookiePromoteTooltip;
var localized string m_strNoImplantsTooltip;
var localized string m_strNoGTSTooltip;
var localized string m_strCantEquiqPCSTooltip;
var localized string m_strNoModularWeaponsTooltip;
var localized string m_strCannotUpgradeWeaponTooltip;
var localized string m_strNoWeaponUpgradesTooltip;
var localized string m_strInsufficientRankForImplantsTooltip;
var localized string m_strCombatSimsSlotsFull;

var localized string m_strToggleAbilities;
var localized string m_strToggleTraits;

// set to true to prevent spawning popups when cycling soldiers
var bool bIsHotlinking;

var UIList List;
var UIListItemString PromoteItem;
var bool bListingTraits; 

// Issue #47
var UIPanel BGPanel;
var UIListItemString CustomizeButton, LoadoutButton, PCSButton, WeaponUpgradeButton, PromotionButton, PropagandaButton, SoldierBondsButton, DismissButton;

simulated function InitArmory(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	bUseNavHelp = class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory');
	super.InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, CheckGameState);

	// Start Issue #47
	List = Spawn(class'UIList', self).InitList(); // Initialize a new list so it can be positions
	// List.OnItemClicked = OnItemClicked; // Remove this and let each button handle its own callbacks, so that mod buttons can change order/insert without breaking stuff
	List.OnSelectionChanged = OnSelectionChanged;
	// Adjust position slightly for larger list
	List.SetPosition(113, 143);
	List.SetSize(401, 360); // Should I reduce width to leave room for scrollbar on background?

	// Create background BGPanel so can make some changes and move the existing panel
	BGPanel = Spawn(class'UIPanel', self).InitPanel('armoryMenuBG');
	BGPanel.SetPosition(101, 126);
	BGPanel.SetSize(425, 600);
	BGPanel.bShouldPlayGenericUIAudioEvents = false;  
	BGPanel.ProcessMouseEvents(List.OnChildMouseEvent); // hook mousewheel to scroll MainMenu list instead of rotating soldier
	// End Issue #47

	CreateSoldierPawn();
	PopulateData();
	//CheckForCustomizationPopup();
}

simulated function PopulateData()
{
	local bool bInTutorialPromote;

	super.PopulateData();

	List.ClearItems();

	bInTutorialPromote = !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory');

	// Start Issue #47
	// -------------------------------------------------------------------------------
	// Customize soldier: 
	CustomizeButton = Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strCustomizeSoldier).SetDisabled(bInTutorialPromote, "");
	CustomizeButton.MCName = 'ArmoryMainMenu_CustomizeButton';
	CustomizeButton.ButtonBG.OnClickedDelegate = OnCustomize;

	// -------------------------------------------------------------------------------
	// Loadout:
	LoadoutButton = Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strLoadout).SetDisabled(bInTutorialPromote, "");
	LoadoutButton.MCName = 'ArmoryMainMenu_LoadoutButton';
	LoadoutButton.ButtonBG.OnClickedDelegate = OnLoadout;

	// -------------------------------------------------------------------------------
	// PCS:
	PCSButton = Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strImplants);
	PCSButton.MCName = 'ArmoryMainMenu_PCSButton';
	PCSButton.ButtonBG.OnClickedDelegate = OnPCS;

	// -------------------------------------------------------------------------------
	// Customize Weapons:
	WeaponUpgradeButton = Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strCustomizeWeapon);
	WeaponUpgradeButton.MCName = 'ArmoryMainMenu_WeaponUpgradeButton';
	WeaponUpgradeButton.ButtonBG.OnClickedDelegate = OnWeaponUpgrade;
	// -------------------------------------------------------------------------------
	// Promotion:
	PromotionButton = Spawn(class'UIListItemString', List.ItemContainer).InitListItem();
	PromotionButton.MCName = 'ArmoryMainMenu_PromotionButton';
	PromotionButton.ButtonBG.OnClickedDelegate = OnPromote;

	// -------------------------------------------------------------------------------
	// Propaganda
	PropagandaButton = Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strPropaganda).SetDisabled((bInTutorialPromote || class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress()), "");
	PropagandaButton.MCName = 'ArmoryMainMenu_PropagandaButton';
	PropagandaButton.ButtonBG.OnClickedDelegate = OnPropaganda;

	// -------------------------------------------------------------------------------
	// Soldier Bonds:
	SoldierBondsButton = Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strSoldierBonds);
	SoldierBondsButton.MCName = 'ArmoryMainMenu_SoldierBondsButton';
	SoldierBondsButton.ButtonBG.OnClickedDelegate = OnSoldierBonds;

	// -------------------------------------------------------------------------------
	// Dismiss: 
	DismissButton = Spawn(class'UIListItemString', List.ItemContainer).InitListItem(m_strDismiss).SetDisabled((bInTutorialPromote || class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress() || !class'XComGameState_HeadquartersXCom'.static.LostAndAbandonedCompleted()), "");
	DismissButton.MCName = 'ArmoryMainMenu_DismissButton';
	DismissButton.ButtonBG.OnClickedDelegate = OnDismiss;

	UpdateData();
	// End Issue #47

	List.Navigator.SelectFirstAvailable();
}

// Start Issue #47
simulated function UpdateData()
{
	local bool bEnableImplantsOption, bEnableWeaponUpgradeOption, bInTutorialPromote;
	local TWeaponUpgradeAvailabilityData WeaponUpgradeAvailabilityData;
	local TPCSAvailabilityData PCSAvailabilityData;
	local string ImplantsTooltip, WeaponUpgradeTooltip, PromoteIcon;
	local XComGameState_Unit Unit;
	local StateObjectReference BondmateRef;
	local SoldierBond BondData;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));

	bInTutorialPromote = !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory');

	// -------------------------------------------------------------------------------
	// PCS:
	class'UIUtilities_Strategy'.static.GetPCSAvailability(Unit, PCSAvailabilityData);

	if(!PCSAvailabilityData.bHasAchievedCombatSimsRank)
		ImplantsTooltip = m_strInsufficientRankForImplantsTooltip;
	else if(!PCSAvailabilityData.bCanEquipCombatSims)
		ImplantsTooltip = m_strCantEquiqPCSTooltip;
	else if( !PCSAvailabilityData.bHasCombatSimsSlotsAvailable )
		ImplantsTooltip = m_strCombatSimsSlotsFull;
	else if( !PCSAvailabilityData.bHasNeurochipImplantsInInventory )
		ImplantsTooltip = m_strNoImplantsTooltip;
	else if( !PCSAvailabilityData.bHasGTS )
		ImplantsTooltip = m_strNoGTSTooltip;

	bEnableImplantsOption = PCSAvailabilityData.bCanEquipCombatSims && PCSAvailabilityData.bHasAchievedCombatSimsRank && 
		PCSAvailabilityData.bHasNeurochipImplantsInInventory &&	PCSAvailabilityData.bHasGTS && !bInTutorialPromote;
	
	PCSButton.SetDisabled(!bEnableImplantsOption, ImplantsTooltip);

	if( bEnableImplantsOption )
	{
		if( PCSAvailabilityData.bHasNeurochipImplantsInInventory && PCSAvailabilityData.bHasCombatSimsSlotsAvailable)
			PCSButton.NeedsAttention(true);
		else
			PCSButton.NeedsAttention(false);
	} 
	else
	{
		PCSButton.NeedsAttention(false);
	}

	// -------------------------------------------------------------------------------
	// Customize Weapons:
	class'UIUtilities_Strategy'.static.GetWeaponUpgradeAvailability(Unit, WeaponUpgradeAvailabilityData);

	if( !WeaponUpgradeAvailabilityData.bHasModularWeapons )
		WeaponUpgradeTooltip = m_strNoModularWeaponsTooltip;
	else if( !WeaponUpgradeAvailabilityData.bCanWeaponBeUpgraded )
		WeaponUpgradeTooltip = m_strCannotUpgradeWeaponTooltip;
	else if( !WeaponUpgradeAvailabilityData.bHasWeaponUpgrades )
		WeaponUpgradeTooltip = m_strNoWeaponUpgradesTooltip;

	bEnableWeaponUpgradeOption = WeaponUpgradeAvailabilityData.bHasModularWeapons && WeaponUpgradeAvailabilityData.bCanWeaponBeUpgraded && !bInTutorialPromote;
	WeaponUpgradeButton.SetDisabled(!bEnableWeaponUpgradeOption, WeaponUpgradeTooltip);

	if( WeaponUpgradeAvailabilityData.bHasWeaponUpgrades && WeaponUpgradeAvailabilityData.bHasWeaponUpgradeSlotsAvailable && WeaponUpgradeAvailabilityData.bHasModularWeapons)
		WeaponUpgradeButton.NeedsAttention(true);
	else
		WeaponUpgradeButton.NeedsAttention(false);

	// -------------------------------------------------------------------------------
	// Promotion:
	if(Unit.ShowPromoteIcon())
	{
		PromoteIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_PromotionIcon, 20, 20, 0) $ " ";
		PromotionButton.SetText(PromoteIcon $ m_strPromote);
	}
	else
	{
		PromotionButton.SetText(m_strAbilities);
	}
		
	UpdatePromoteItem();

	// -------------------------------------------------------------------------------
	// Soldier Bonds:
	if( Unit.ShowBondAvailableIcon(BondmateRef, BondData) )
		SoldierBondsButton.NeedsAttention(true);
	else
		SoldierBondsButton.NeedsAttention(false);
	SoldierBondsButton.SetDisabled(bInTutorialPromote || !Unit.GetSoldierClassTemplate().bCanHaveBonds);

	// trigger now to allow inserting new buttons
	`XEVENTMGR.TriggerEvent('OnArmoryMainMenuUpdate', List, self);

	RefreshAbilitySummary();
	UpdateNavHelp();
}

//follows is a series of handlers for each individual button
simulated function OnCustomize(UIButton kButton)
{
	local XComGameState_Unit UnitState;

	if(CheckForDisabledListItem(kButton)) return;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
	Movie.Pres.UICustomize_Menu(UnitState, ActorPawn);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function OnLoadout(UIButton kButton)
{
	local XComHQPresentationLayer HQPres;

	if(CheckForDisabledListItem(kButton)) return;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	if( HQPres != none )
		HQPres.UIArmory_Loadout(UnitReference);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function OnPCS(UIButton kButton)
{
	local XComHQPresentationLayer HQPres;

	if(CheckForDisabledListItem(kButton)) return;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	if( HQPres != none && `XCOMHQ.HasCombatSimsInInventory() )
		`HQPRES.UIInventory_Implants();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function OnWeaponUpgrade(UIButton kButton)
{
	local XComHQPresentationLayer HQPres;

	if(CheckForDisabledListItem(kButton)) return;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	ReleasePawn();
	if( HQPres != none && `XCOMHQ.bModularWeapons )
		HQPres.UIArmory_WeaponUpgrade(UnitReference);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function OnPromote(UIButton kButton)
{
	local XComHQPresentationLayer HQPres;

	if(CheckForDisabledListItem(kButton)) return;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	if( HQPres != none && GetUnit().GetRank() >= 1 || GetUnit().CanRankUpSoldier() || GetUnit().HasAvailablePerksToAssign() )
		HQPres.UIArmory_Promotion(UnitReference);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function OnPropaganda(UIButton kButton)
{
	local XComHQPresentationLayer HQPres;

	if(CheckForDisabledListItem(kButton)) return;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	if (HQPres != none)
		HQPres.UIArmory_Photobooth(UnitReference);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function OnSoldierBonds(UIButton kButton)
{
	local XComHQPresentationLayer HQPres;

	if(CheckForDisabledListItem(kButton)) return;

	HQPres = XComHQPresentationLayer(Movie.Pres);
	if( HQPres != none )
		HQPres.UISoldierBonds(UnitReference);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function OnDismiss(UIButton kButton)
{
	if(CheckForDisabledListItem(kButton)) return;

	OnDismissUnit();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
}

simulated function bool CheckForDisabledListItem(UIButton kButton)
{
	local UIListItemString Parent;

	Parent = UIListItemString(kButton.ParentPanel);
	if( Parent != none && Parent.bDisabled )
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		return true;
	}
	return false;
}
// End Issue #47

simulated function RefreshAbilitySummary()
{
	local XComGameState_Unit Unit;
	local bool bHasTraits;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
	if( bListingTraits )
	{
		bHasTraits = class'UIUtilities_Strategy'.static.PopulateAbilitySummary_Traits(self, Unit);

		if( !bHasTraits )
		{
			bHasTraits = class'UIUtilities_Strategy'.static.PopulateAbilitySummary(self, Unit);
		}
	}
	else
	{
		bHasTraits = class'UIUtilities_Strategy'.static.PopulateAbilitySummary(self, Unit);
	}
}

simulated function UpdateNavHelp()
{
	local XComGameState_Unit Unit;

	super.UpdateNavHelp();

	// If you don't have any traits, then we aren't going to show you toggle option at all. 

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
	if( Unit.AcquiredTraits.length == 0 ) return;

	if( bUseNavHelp )
	{
		if( XComHQPresentationLayer(Movie.Pres) != none )
		{	
			if( bListingTraits )
			{
				if( `ISCONTROLLERACTIVE )
					NavHelp.AddRightHelp(m_strToggleAbilities, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE); // bsg-jrebar (05/19/17): Changing to X
				else
					NavHelp.AddRightHelp(m_strToggleAbilities, , ToggleAbilitiesAndTraits);
			}
			else
			{
				if( `ISCONTROLLERACTIVE )
					NavHelp.AddRightHelp(m_strToggleTraits, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE); // bsg-jrebar (05/19/17): Changing to X
				else
					NavHelp.AddRightHelp(m_strToggleTraits, , ToggleAbilitiesAndTraits);
			}
		}
	}
}

simulated function ToggleAbilitiesAndTraits()
{
	if( bUseNavHelp )
	{
		bListingTraits = !bListingTraits; 
		RefreshAbilitySummary();
		UpdateNavHelp();
	}
}

simulated function UpdatePromoteItem()
{
	if(GetUnit().GetRank() < 1 && !GetUnit().CanRankUpSoldier())
	{
		PromotionButton.SetDisabled(true, m_strRookiePromoteTooltip);
	}
}

simulated function CheckForCustomizationPopup()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true);
	if(XComHQ != none)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
		if (!XComHQ.bHasSeenCustomizationsPopup && UnitState.IsVeteran())
		{
			`HQPRES.UISoldierCustomizationsAvailable();
		}
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	PopulateData();
	CreateSoldierPawn();
	UpdatePromoteItem();
	//if(!bIsHotlinking)
		//CheckForCustomizationPopup();
	Header.PopulateData();
}

simulated function OnAccept()
{
	// Start Issue #47
	if( UIListItemString(List.GetSelectedItem()).bDisabled )
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		return;
	}

	// Start Issue #47: navigable button bg for UIListItemString start
	// buttons are self-contained. send event to list
	// assume arg and cmd
	List.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_KEY_ENTER, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
	// navigable button bg for UIListItemString end
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuSelect");
	// End Issue #47
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	OnAccept();
}

// Start Issue #47
//reworked to switch off button instead of list index
simulated function OnSelectionChanged(UIList ContainerList, int ItemIndex)
{
	local XComGameState_Unit UnitState;
	local string Description, CustomizeDesc;
	
	// Index order matches order that elements get added in 'PopulateData'
	switch(ContainerList.GetItem(ItemIndex))
	{
	case CustomizeButton: // CUSTOMIZE
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
		CustomizeDesc = UnitState.GetMyTemplate().strCustomizeDesc;
		Description = CustomizeDesc != "" ? CustomizeDesc : m_strCustomizeSoldierDesc;
		break;
	case LoadoutButton: // LOADOUT
		Description = m_strLoadoutDesc;
		break;
	case PCSButton: // NEUROCHIP IMPLANTS
		Description = m_strImplantsDesc;
		break;
	case WeaponUpgradeButton: // WEAPON UPGRADE
		Description = m_strCustomizeWeaponDesc;
		break;
	case PromotionButton: // PROMOTE
		Description = m_strPromoteDesc;
		break;
	case PropagandaButton: // PROPAGANDA
		Description = m_strPropagandaDesc;
		break;
	case SoldierBondsButton: // SOLDIER BONDS
		Description = m_strSoldierBondsDesc;
		break;
	case DismissButton: // DISMISS
		Description = m_strDismissDesc;
		break;
	}

	MC.ChildSetString("descriptionText", "htmlText", class'UIUtilities_Text'.static.AddFontInfo(Description, bIsIn3D));
}
// End Issue #47

simulated function OnDismissUnit()
{
	local XGParamTag        kTag;
	local TDialogueBoxData  DialogData;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = GetUnit().GetName(eNameType_Full);
	
	DialogData.eType       = eDialog_Warning;
	DialogData.strTitle	= m_strDismissDialogTitle;
	DialogData.strText     = `XEXPAND.ExpandString(m_strDismissDialogDescription); 
	DialogData.fnCallback  = OnDismissUnitCallback;

	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated public function OnDismissUnitCallback(Name eAction)
{
	local XComGameState_HeadquartersXCom XComHQ;

	if( eAction == 'eUIAction_Accept' )
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		XComHQ.FireStaff(UnitReference);
		OnCancel();
	}
}

//==============================================================================

simulated function OnCancel()
{
	if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory'))
	{
		super.OnCancel();
	}
}

simulated function OnRemoved()
{
	super.OnRemoved();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

//==============================================================================

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// bsg-jrebar (5/23/17): Added error handling and replaced ti use X button
	local XComGameState_Unit Unit;
	

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_X :
		// If you don't have any traits, then we aren't going to show you toggle option at all. 
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));

		if( Unit.AcquiredTraits.length >= 0 ) 
			ToggleAbilitiesAndTraits(); 
		return true; 
	}

	return super.OnUnrealCommand(cmd, arg);
	// bsg-jrebar (5/23/17): end
}

defaultproperties
{
	LibID = "ArmoryMenuScreenMC";
	DisplayTag = "UIBlueprint_ArmoryMenu";
	CameraTag = "UIBlueprint_ArmoryMenu";

	bShowExtendedHeaderData = true;
	bListingTraits = true; 
}