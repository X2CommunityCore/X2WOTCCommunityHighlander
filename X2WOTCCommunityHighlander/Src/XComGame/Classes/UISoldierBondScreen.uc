//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISoldierBondScreen.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Soldier bond information screen.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISoldierBondScreen extends UIScreen
	implements(IUISortableScreen);

enum ESoldierBondSortType
{
	eSoldierBondSortType_Name,
	eSoldierBondSortType_Rank,
	eSoldierBondSortType_Class,
	eSoldierBondSortType_Compatibility,
	eSoldierBondSortType_Cohesion,
};

// these are set in UIFlipSortButton
var bool m_bFlipSort;
var ESoldierBondSortType m_eSortType;
var UIPanel m_kSoldierSortHeader;

//bsg-crobinson (5.16.17): Necessary toggle/sort variables
var array<ESoldierBondSortType> m_aSortTypeOrder; 
var int m_iSortTypeOrderIndex; 
var bool m_bDirtySortHeaders;
//bsg-crobinson (5.16.17): end

var localized string m_strButtonLabels[ESoldierBondSortType.EnumCount]<BoundEnum = ESoldierBondSortType>;
var localized string m_strButtonValues[ESoldierBondSortType.EnumCount]<BoundEnum = ESoldierBondSortType>;
var localized string m_strSwitchSoldier;

var StateObjectReference UnitRef;
var StateObjectReference BondmateRef;
var bool bSquadOnly;

var UIList List;
var UINavigationHelp NavHelp;

var array<StateObjectReference> m_arrSoldiers;
var XComGameState_HeadquartersXCom HQState; 

var int m_iMaskWidth;
var int m_iMaskHeight;

var localized string BondTitle;
var localized string BondMateTitle;
var localized string NoBond;

simulated function OnInit()
{
	super.OnInit();

	List = Spawn(class'UIList', self);
	List.bIsNavigable = true;
	List.InitList('listAnchor', , , m_iMaskWidth, m_iMaskHeight);
	List.bStickyHighlight = false;

	//bsg-crobinson (4.14.17): Update Navhelp on selection change
	if(`ISCONTROLLERACTIVE)
		List.OnSelectionChanged = OnSoldierSelectionChanged;
	//bsg-crobinson (4.14.17): end

	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();

	if( !bSquadOnly )
	{
		class'UIUtilities'.static.DisplayUI3D('UIBlueprint_Promotion_Hero', 'UIBlueprint_Promotion_Hero', `HQINTERPTIME);
		MC.FunctionVoid("AlignLeftLayout");
	}
	
	SetScreenHeader(BondTitle);
	RefreshHeader();
	CreateSortHeaders();
	RefreshData();
	CycleToSoldier(UnitRef); //bsg-crobinson (4.14.17): make sure the soldier is updated for rotation
	AnimateIn();

	//bsg-jneal (3.17.17): add list to the navigator for controller
	if(`ISCONTROLLERACTIVE)
	{
		Navigator.SetSelected(List);
		List.SetSelectedIndex(0);
	}
	//bsg-jneal (3.17.17): end

	UpdateNavHelp(); // bsg-jrebar (4/26/17): Soldier bond, adding X Button press and readding select behavior

}

//bsg-crobinson (4.14.17): Update the navhelp on selection change
function OnSoldierSelectionChanged(UIList ContainerList, int ItemIndex)
{
	UpdateNavHelp();
}
//bsg-crobinson (4.14.17):end

function RebuildScreenForSoldier(StateObjectReference NewUnitRef)
{
	UnitRef = NewUnitRef; 

	RefreshHeader();
	RefreshData();
	UpdateNavHelp();
}

function RefreshHeader()
{
	local XComGameState_Unit Unit, Bondmate;
	local string classIcon, rankIcon, flagIcon;
	local int iRank;
	local X2SoldierClassTemplate SoldierClass;
	local SoldierBond BondData;
	local float CohesionPercent, CohesionMax;
	local array<int> CohesionThresholds;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	
	iRank = Unit.GetRank();

	SoldierClass = Unit.GetSoldierClassTemplate();

	flagIcon = Unit.GetCountryTemplate().FlagImage;
	rankIcon = class'UIUtilities_Image'.static.GetRankIcon(iRank, SoldierClass.DataName);
	classIcon = SoldierClass.IconImage;

	SetPlayerInfo(Caps(`GET_RANK_STR(Unit.GetRank(), SoldierClass.DataName)), 
					Caps(Unit.GetName(eNameType_FullNick)),
					classIcon,
					rankIcon, 
					"", 
					0);

	if( Unit.HasSoldierBond(BondmateRef, BondData) )
	{
		Bondmate = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));

		iRank = Bondmate.GetRank();

		SoldierClass = Bondmate.GetSoldierClassTemplate();

		flagIcon = Bondmate.GetCountryTemplate().FlagImage;
		rankIcon = class'UIUtilities_Image'.static.GetRankIcon(iRank, SoldierClass.DataName);
		classIcon = SoldierClass.IconImage;
		
		CohesionThresholds = class'X2StrategyGameRulesetDataStructures'.default.CohesionThresholds;
		CohesionMax = float(CohesionThresholds[Clamp(BondData.BondLevel + 1, 0, CohesionThresholds.Length - 1)]);
		CohesionPercent = float(BondData.Cohesion) / CohesionMax;

		SetBondMateInfo(BondMateTitle, 
						BondData.BondLevel,
						Caps(Bondmate.GetName(eNameType_Full)),
						Caps(Bondmate.GetName(eNameType_Nick)),
						Caps(`GET_RANK_ABBRV(Bondmate.GetRank(), SoldierClass.DataName)),
						rankIcon,
						Caps(SoldierClass != None ? SoldierClass.DisplayName : ""),
						classIcon,
						flagIcon,
						class'X2StrategyGameRulesetDataStructures'.static.GetSoldierCompatibilityLabel(BondData.Compatibility),
						CohesionPercent,
						false /*todo: is disabled*/ );

	}
	else
	{

		SetBondMateInfo(NoBond,
						-1, //Negative bond level makes this area hide itself.
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						"",
						-1,
						false);
	}
}

simulated function RefreshData()
{
	UpdateData();
	SortData();
	UpdateList();
}

simulated function UpdateData()
{
	local int i;
	local XComGameState_Unit Unit;
	local array<StateObjectReference> UnitRefs;

	// Destroy old data
	m_arrSoldiers.Length = 0;

	//Need to get the latest state here, else you may have old data in the list upon refreshing at OnReceiveFocus, such as 
	//still showing dismissed soldiers. 
	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (bSquadOnly)
	{
		UnitRefs = HQState.Squad;
	}
	else
	{
		UnitRefs = HQState.Crew;
	}

	for( i = 0; i < UnitRefs.Length; i++ )
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRefs[i].ObjectID));

		if( Unit.IsAlive() && Unit.ObjectID != UnitRef.ObjectID && Unit.ObjectID != BondmateRef.ObjectID)
		{
			if( Unit.IsSoldier() )
			{
				m_arrSoldiers.AddItem(Unit.GetReference());
			}
		}
	}
}

simulated function UpdateList()
{
	local int SelIdx;
	SelIdx = List.SelectedIndex;

	List.ClearItems();
	PopulateListInstantly();

	List.SetSelectedIndex(SelIdx);
}

// calling this function will add items instantly
simulated function PopulateListInstantly()
{
	local UISoldierBondListItem kItem;
	local StateObjectReference SoldierRef;
	
	while( List.itemCount < m_arrSoldiers.Length )
	{

		kItem = Spawn(class'UISoldierBondListItem', List.itemContainer);
		SoldierRef = m_arrSoldiers[List.itemCount];
		kItem.InitListItem(SoldierRef, UnitRef);
	}
}

simulated function OnConfirmBond(UISoldierBondListItem BondListItem)
{
	local XComGameStateHistory History;
	local XComGameState_Unit SelectedUnitState, BondUnitState;

	History = `XCOMHISTORY;
	
	if (BondListItem != none)
	{
		BondUnitState = XComGameState_Unit(History.GetGameStateForObjectID(BondListItem.ScreenUnitRef.ObjectID));
		SelectedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(BondListItem.UnitRef.ObjectID));

		if(class'X2StrategyGameRulesetDataStructures'.static.CanHaveBondAtLevel(BondUnitState, SelectedUnitState, 1))
		{
			`HQPRES.UISoldierBondConfirm(BondUnitState, SelectedUnitState);
		}
	}
}

simulated function OnSelectSoldier(StateObjectReference NewUnitRef)
{
	class'UIArmory'.static.CycleToSoldier(NewUnitRef);

	RebuildScreenForSoldier(NewUnitRef);
}

function SetPlayerInfo(string strRankLabel, string strName, string strClass, string strRank, string strCohesionLabel, float numCohesionValue)
{
	MC.BeginFunctionOp("SetPlayerInfo");
	MC.QueueString(strRankLabel);
	MC.QueueString(strName);
	MC.QueueString(strClass);
	MC.QueueString(strRank);
	MC.QueueString(strCohesionLabel);
	MC.QueueNumber(numCohesionValue/100);
	MC.EndOp();

}

function SetBondMateInfo(string strBondTitle,
							int numBondLevel,
							string UnitName,
							string UnitNickname,
							string UnitRank,
							string UnitRankPath,
							string UnitClass,
							string UnitClassPath,
							string UnitFlagPath,
							string UnitCompatibility,
							float UnitCohesion,
							bool bIsDisabled)
{
	MC.BeginFunctionOp("SetBondMateInfo");
	MC.QueueString(strBondTitle);
	MC.QueueNumber(numBondLevel);
	MC.QueueString(UnitName);
	MC.QueueString(UnitNickname);
	MC.QueueString(UnitRank);
	MC.QueueString(UnitRankPath);
	MC.QueueString(UnitClass);
	MC.QueueString(UnitClassPath);
	MC.QueueString(UnitFlagPath);
	MC.QueueString(UnitCompatibility);
	MC.QueueNumber(UnitCohesion);
	MC.QueueBoolean(bIsDisabled);
	MC.EndOp();
}


function SetScreenHeader(string Title)
{
	MC.FunctionString("SetScreenHeader", Title);
}

//==============================================================================

simulated function OnReceiveFocus()
{
	local XComHQPresentationLayer HQPresLayer;
	local float InterpTime;
	
	super.OnReceiveFocus();

	if(!bSquadOnly)
	{
		HQPresLayer = `HQPRES;

		if(HQPresLayer.m_bExitingFromPhotobooth)
		{
			InterpTime = 0;
			HQPresLayer.m_bExitingFromPhotobooth = false;
		}
		else
		{
			InterpTime = `HQINTERPTIME;
		}

		class'UIUtilities'.static.DisplayUI3D('UIBlueprint_Promotion_Hero', 'UIBlueprint_Promotion_Hero', InterpTime);
	}

	UpdateNavHelp();
	RefreshHeader();
	RefreshData();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function UpdateNavHelp()
{
	local int i;
	local string PrevKey, NextKey;
	local XGParamTag LocTag;
	// bsg-jrebar (4/26/17): Soldier bond, adding X Button press and readding select behavior
	local XComGameState_Unit SelectedUnitState, BondUnitState;
	local XComGameStateHistory History;

	if(!bIsFocused)
		return; //bsg-crobinson (5.30.17): If not focused return

	History = `XCOMHISTORY;
	// bsg-jrebar (4/26/17): end

	if( XComHQPresentationLayer(Movie.Pres) != none )
		NavHelp = XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp;
	else
		NavHelp = Movie.Pres.GetNavHelp();

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE && IsInSquadScreen(); //bsg-crobinson (5.16.17): Set Vertical for AA report
	NavHelp.AddBackButton(CloseScreen);

	if( XComHQPresentationLayer(Movie.Pres) != none )
	{
		if(class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitRef, class'UIArmory'.static.CanCycleTo) )
		{
			if( Movie.IsMouseActive() )
			{
				if (!IsInSquadScreen())
				{
					LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
					LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_PrevUnit);
					PrevKey = `XEXPAND.ExpandString(class'UIArmory'.default.PrevSoldierKey);
					LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_NextUnit);
					NextKey = `XEXPAND.ExpandString(class'UIArmory'.default.NextSoldierKey);

					NavHelp.SetButtonType("XComButtonIconPC");
					i = eButtonIconPC_Prev_Soldier;
					NavHelp.AddCenterHelp(string(i), "", PrevSoldier, false, PrevKey);
					i = eButtonIconPC_Next_Soldier;
					NavHelp.AddCenterHelp(string(i), "", NextSoldier, false, NextKey);
					NavHelp.SetButtonType("");
				}
			}
			else
			{

				BondUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UISoldierBondListItem(List.GetSelectedItem()).ScreenUnitRef.ObjectID));
				SelectedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UISoldierBondListItem(List.GetSelectedItem()).UnitRef.ObjectID));

				if(class'X2StrategyGameRulesetDataStructures'.static.CanHaveBondAtLevel(BondUnitState, SelectedUnitState, 1))
				{   //bsg-crobinson (5.19.17): We want to bond in AAR with A button
					NavHelp.AddSelectNavHelp();
				}

				if (!IsInSquadScreen())
				{
					// bsg-jrebar (4/26/17): Soldier bond, adding X Button press and readding select behavior
					if(	!UISoldierBondListItem(List.GetSelectedItem()).IsDisabled )
					{
						//bsg-crobinson (5.19.17): Changing X to switch soldiers
						NavHelp.AddLeftHelp(m_strSwitchSoldier, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_X_SQUARE);
					}
				
					if( class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitRef, class'UIArmory'.static.CanCycleTo) )
					{
						NavHelp.AddCenterHelp(class'UIArmory'.default.m_strTabNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LBRB_L1R1); // bsg-jrebar (5/23/17) Removed button inlining
					}

					NavHelp.AddCenterHelp(class'UIArmory'.default.m_strRotateNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RSTICK); // bsg-jrebar (5/23/17) Removed button inlining
					// bsg-jrebar (4/26/17): end
				}

				//bsg-crobinson (5.16.17): Add Toggle/Sort Navhelp
				NavHelp.AddRightHelp(class'UIPersonnel'.default.m_strToggleSort, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
				NavHelp.AddRightHelp(class'UIPersonnel'.default.m_strChangeColumn, class'UIUtilities_Input'.const.ICON_DPAD_HORIZONTAL);
				//bsg-crobinson (5.16.17):
			}
		}
	}

	NavHelp.Show();
}

simulated function bool IsInSquadScreen()
{
	if(`ScreenStack.IsInStack(class'UISquadSelect')) 
		return true;

	if (`ScreenStack.IsInStack(class'UIAfterAction'))
		return true; 

	return false; 
}

//bsg-crobinson (4.14.17): ensure soldier cycling / rotation
simulated function NextSoldier()
{
	local StateObjectReference NewUnitRef;
	if( class'UIUtilities_Strategy'.static.CycleSoldiers(1, UnitRef, CanCycleTo, NewUnitRef) )
		CycleToSoldier(NewUnitRef);
}

simulated function PrevSoldier()
{
	local StateObjectReference NewUnitRef;
	if( class'UIUtilities_Strategy'.static.CycleSoldiers(-1, UnitRef, CanCycleTo, NewUnitRef) )
		CycleToSoldier(NewUnitRef);
}

simulated function CycleToSoldier(StateObjectReference NewRef)
{
	local int i;
	local UIArmory ArmoryScreen, CurrentScreen;
	local UIScreenStack ScreenStack;
	local Rotator CachedRotation, ZeroRotation;

	ScreenStack = `SCREENSTACK;

	for( i = ScreenStack.Screens.Length - 1; i >= 0; --i )
	{
		ArmoryScreen = UIArmory(ScreenStack.Screens[i]);
		if( ArmoryScreen != none )
		{
			CachedRotation = ArmoryScreen.ActorPawn != none ? ArmoryScreen.ActorPawn.Rotation : ZeroRotation;

			ArmoryScreen.ReleasePawn(true);

			ArmoryScreen.SetUnitReference(NewRef);
			ArmoryScreen.CreateSoldierPawn(CachedRotation);
			ArmoryScreen.PopulateData();

			ArmoryScreen.Header.UnitRef = NewRef;
			ArmoryScreen.Header.PopulateData(ArmoryScreen.GetUnit());

			// Signal focus change (even if focus didn't actually change) to ensure modders get notified of soldier switching
			ArmoryScreen.SignalOnReceiveFocus();
		}
	}

	CurrentScreen = UIArmory(ScreenStack.GetCurrentScreen());
	if( CurrentScreen != none && CurrentScreen.bShowExtendedHeaderData )
		ArmoryScreen.Header.ShowExtendedData();
	else
		ArmoryScreen.Header.HideExtendedData();

	// TTP[7879] - Immediately process queued commands to prevent 1 frame delay of customization menu options
	if( ArmoryScreen != none )
		ArmoryScreen.Movie.ProcessQueuedCommands();

	RebuildScreenForSoldier(NewRef);
	UpdateNavHelp();
}

simulated static function bool CanCycleTo(XComGameState_Unit Unit)
{
	return Unit.IsSoldier() && !Unit.IsDead() && !Unit.IsOnCovertAction() && Unit.GetSoldierClassTemplate().bCanHaveBonds;
}
//bsg-crobinson (4.14.17): end

//bsg-crobinson (5.16.17): Update the sort headers
simulated function UpdateSortHeaders()
{
	local int i;
	local array<UIPanel> SortButtons;
	local UIFlipSortButton SortButton;

	// Realize sort buttons
	m_kSoldierSortHeader.GetChildrenOfType(class'UIFlipSortButton', SortButtons);

	for(i = 0; i < SortButtons.Length; ++i)
	{
		SortButton = UIFlipSortButton(SortButtons[i]);
		SortButton.RealizeSortOrder();
		SortButton.SetArrow(m_bFlipSort);
		if (SortButton.IsSelected())
		{
			SortButton.OnReceiveFocus();
		}
	}
}
//bsg-crobinson (5.16.17): end
//==============================================================================

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		CloseScreen();
		break;
	
	// bsg-jrebar (4/26/17): Soldier bond, adding A Button press and readding select behavior
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
		OnConfirmBond(UISoldierBondListItem(List.GetSelectedItem()));
		break;
	// bsg-jrebar (4/26/17): end

	case class'UIUtilities_Input'.const.FXS_MOUSE_5 :
	case class'UIUtilities_Input'.const.FXS_KEY_TAB :
	case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER :
		if(!IsInSquadScreen())
			NextSoldier(); //bsg-crobinson (4.14.17): Cycle to next soldier
		break;

	case class'UIUtilities_Input'.const.FXS_MOUSE_4 :
	case class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT :
	case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER :
		if(!IsInSquadScreen())
			PrevSoldier(); //bsg-crobinson (4.14.17): Cycle to prev soldier
		break;

	// bsg-jrebar (4/26/17): Soldier bond, adding X Button press and readding select behavior
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		if(!IsInSquadScreen())
			OnSelectSoldier(UISoldierBondListItem(List.GetSelectedItem()).UnitRef);
		break; //bsg-crobinson (4.14.17): check for a valid bond
	// bsg-jrebar (4/26/17): end

		`if (`notdefined(FINAL_RELEASE))
	case class'UIUtilities_Input'.const.FXS_KEY_HOME :
			`HQPRES.UISoldierBondAlert(UnitRef, m_arrSoldiers[0]);
			break;
		`endif
	
	//bsg-crobinson (5.16.17): Add in toggle/sort functionality
	case class'UIUtilities_Input'.const.FXS_BUTTON_L3:
		m_bFlipSort = !m_bFlipSort;
		RefreshData();
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:			
		m_bFlipSort = false;
		m_iSortTypeOrderIndex--;
		if(m_iSortTypeOrderIndex < 0)
			m_iSortTypeOrderIndex = m_aSortTypeOrder.Length - 1;
		SetSortType(m_aSortTypeOrder[m_iSortTypeOrderIndex]);
		m_bDirtySortHeaders = true;
		UpdateSortHeaders();
		PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		m_bFlipSort = false;
		m_iSortTypeOrderIndex++;
		if(m_iSortTypeOrderIndex >= m_aSortTypeOrder.Length)
			m_iSortTypeOrderIndex = 0;
		SetSortType(m_aSortTypeOrder[m_iSortTypeOrderIndex]);
		m_bDirtySortHeaders = true;
		UpdateSortHeaders();
		PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
			break;
	//bsg-crobinson (5.16.17): end

	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function CloseScreen()
{
	super.CloseScreen();

	if (IsInSquadScreen())
	{
		if (`ScreenStack.IsInStack(class'UISquadSelect'))
		{
			`ScreenStack.PopUntilClass(class'UISquadSelect', true);
		}
		else if (`ScreenStack.IsInStack(class'UIAfterAction'))
		{
			`ScreenStack.PopUntilClass(class'UIAfterAction', true);
		}
	}
}

//==============================================================================

// IUISortableInterface, for access from the flip sort header buttons. 
function bool GetFlipSort()
{
	return m_bFlipSort;
}
function int GetSortType()
{
	return int(m_eSortType);
}
function SetFlipSort(bool bFlip)
{
	m_bFlipSort = bFlip;
}
function SetSortType(int eSortType)
{
	m_eSortType = ESoldierBondSortType(eSortType);
}


simulated function CreateSortHeaders()
{
	m_kSoldierSortHeader = Spawn(class'UIPanel', self);
	m_kSoldierSortHeader.bIsNavigable = false;
	m_kSoldierSortHeader.InitPanel('soldierSort', 'SoldierSortHeader');
	
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("rankButton", eSoldierBondSortType_Rank, m_strButtonLabels[eSoldierBondSortType_Rank]);
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("nameButton", eSoldierBondSortType_Name, m_strButtonLabels[eSoldierBondSortType_Name]);
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("classButton", eSoldierBondSortType_Class, m_strButtonLabels[eSoldierBondSortType_Class]);
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("compatibilityButton", eSoldierBondSortType_Compatibility, m_strButtonLabels[eSoldierBondSortType_Compatibility]);
	Spawn(class'UIFlipSortButton', m_kSoldierSortHeader).InitFlipSortButton("cohesionButton", eSoldierBondSortType_Cohesion, m_strButtonLabels[eSoldierBondSortType_Cohesion]);

	//bsg-crobinson (5.16.17): Populate the sort array
	m_aSortTypeOrder.Length = 0;

	m_aSortTypeOrder.AddItem(eSoldierBondSortType_Rank);
	m_aSortTypeOrder.AddItem(eSoldierBondSortType_Name);
	m_aSortTypeOrder.AddItem(eSoldierBondSortType_Class);
	m_aSortTypeOrder.AddItem(eSoldierBondSortType_Compatibility);
	m_aSortTypeOrder.AddItem(eSoldierBondSortType_Cohesion);
	//bsg-crobinson (5.16.17): end
}

function SortData()
{
	switch (m_eSortType)
	{
	case eSoldierBondSortType_Rank:				m_arrSoldiers.Sort(SortByRank);      break;
	case eSoldierBondSortType_Name:				m_arrSoldiers.Sort(SortByName);      break;
	case eSoldierBondSortType_Class:			m_arrSoldiers.Sort(SortByClass);     break;
	case eSoldierBondSortType_Compatibility:	m_arrSoldiers.Sort(SortByCompatibility); break;
	case eSoldierBondSortType_Cohesion:			m_arrSoldiers.Sort(SortByCohesion);      break;
	}
	
	// If going to or returning from a mission, place the soldiers in the current squad at the top of the list
	if (bSquadOnly)
	{
		m_arrSoldiers.Sort(SortBySquad);
	}

	m_bDirtySortHeaders = false;
	UpdateSortHeaders(); //bsg-crobinson (5.16.17): Update the headers
}

simulated function int SortByCompatibility(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit ScreenUnit;
	local SoldierBond BondDataA, BondDataB;
	
	ScreenUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	ScreenUnit.GetBondData(A, BondDataA);
	ScreenUnit.GetBondData(B, BondDataB);
	
	if (BondDataA.Compatibility < BondDataB.Compatibility)
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if (BondDataA.Compatibility > BondDataB.Compatibility)
	{
		return m_bFlipSort ? 1 : -1;
	}
	else if (BondDataA.Cohesion != BondDataB.Cohesion)  // Compatibility match, so sort by Cohesion if possible
	{
		return SortByCohesion(A, B);
	}
	else
	{
		return SortByName(A, B);
	}

	return 0;
}

simulated function int SortByCohesion(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit ScreenUnit;
	local SoldierBond BondDataA, BondDataB;

	ScreenUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	ScreenUnit.GetBondData(A, BondDataA);
	ScreenUnit.GetBondData(B, BondDataB);

	if (BondDataA.Cohesion < BondDataB.Cohesion)
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if (BondDataA.Cohesion > BondDataB.Cohesion)
	{
		return m_bFlipSort ? 1 : -1;
	}
	else if (BondDataA.Compatibility != BondDataB.Compatibility)  // Cohesion match, so sort by compatibility if possible
	{
		return SortByCompatibility(A, B);
	}
	else
	{
		return SortByName(A, B);
	}
	return 0;
}

simulated function int SortByName(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local string NameA, NameB, FullA, FullB;

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	NameA = UnitA.GetName(eNameType_Last);
	NameB = UnitB.GetName(eNameType_Last);

	if (NameA < NameB)
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if (NameA > NameB)
	{
		return m_bFlipSort ? 1 : -1;
	}
	else // Last names match, so sort by full name.
	{
		FullA = UnitA.GetName(eNameType_Full);
		FullB = UnitB.GetName(eNameType_Full);
		if (FullA < FullB)
		{
			return m_bFlipSort ? -1 : 1;
		}
		else if (FullA > FullB)
		{
			return m_bFlipSort ? 1 : -1;
		}
		else
		{
			return 0;
		}
	}
	return 0;
}
simulated function int SortByClass(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local X2SoldierClassTemplate SoldierClassA, SoldierClassB;
	local string NameA, NameB;

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	SoldierClassA = UnitA.GetSoldierClassTemplate();
	SoldierClassB = UnitB.GetSoldierClassTemplate();

	NameA = SoldierClassA.DisplayName;
	NameB = SoldierClassB.DisplayName;

	if (NameA < NameB)
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if (NameA > NameB)
	{
		return m_bFlipSort ? 1 : -1;
	}
	return 0;
}

simulated function int SortByRank(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_Unit UnitA, UnitB;
	local int RankA, RankB;

	UnitA = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(A.ObjectID));
	UnitB = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(B.ObjectID));

	RankA = UnitA.GetRank();
	RankB = UnitB.GetRank();

	if (RankA < RankB)
	{
		return m_bFlipSort ? 1 : -1;
	}
	else if (RankA > RankB)
	{
		return m_bFlipSort ? -1 : 1;
	}
	return 0;
}

simulated function int SortBySquad(StateObjectReference A, StateObjectReference B)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bUnitAInSquad, bUnitBInSquad;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (XComHQ.Squad.Find('ObjectID', A.ObjectID) != INDEX_NONE)
	{
		bUnitAInSquad = true;
	}
	
	if (XComHQ.Squad.Find('ObjectID', B.ObjectID) != INDEX_NONE)
	{
		bUnitBInSquad = true;
	}
	
	if (bUnitAInSquad && !bUnitBInSquad)
	{
		return 1;
	}
	else if (!bUnitAInSquad && bUnitBInSquad)
	{
		return -1;
	}
	return 0;
}



//==============================================================================

defaultproperties
{
	Package = "/ package/gfxXPACK_SoldierBondScreen/XPACK_SoldierBondScreen";
	InputState = eInputState_Consume;

	m_eSortType = eSoldierBondSortType_Cohesion;
	m_bFlipSort = true;
	m_iMaskWidth = 1140;
	m_iMaskHeight = 620;
}
