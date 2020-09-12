//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIAfterActionReport
//  AUTHOR:  Sam Batista -- 5/20/14
//  PURPOSE: This file controls the post-mission squad view.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIAfterAction extends UIScreen;

struct TUIAfterActionFlyoverInfo
{
	var string ColorStr; 
	var string Label;
	var string Icon; 
	var int Priority; //Setting the same priority level will cause flyovers to trigger simultaneously 
	var int Slot; 
};

var bool isBondIconFocused; // bsg-jrebar (05/19/17): Keep focus on bond or promote

var int FlyoverPriorityLevel; 
var float FlyoverTime; 
var array<TUIAfterActionFlyoverInfo> Flyovers; 

var string UIDisplayCam;
var string m_strPawnLocationIdentifier;
var string m_strPawnLocationSlideawayIdentifier;

var localized string m_strDone;
var localized string m_strContinue;
var localized string m_strAfterActionReport;

var localized string m_strInfluenceIncreased;
var localized string m_strMostCohesion;
var localized string m_strBondAvailable;
var localized string m_strBondLevelUpAvailable;

var UISquadSelectMissionInfo m_kMissionInfo;
var array<int> SlotListOrder; //The slot list is not 0->n for cinematic reasons ( ie. 0th and 1st soldier are in a certain place )
var UIList m_kSlotList;

var XComGameState UpdateState;
var XComGameState_HeadquartersXCom XComHQ;

var array<XComUnitPawn> UnitPawns;
var array<XComUnitPawn> UnitPawnsCinematic; //Make a second set of pawns just for the skyranger fly in

var bool bWalkupStarted;
var bool bRecievedShowHUDRemoteEvent;
var bool bForceHelpActivate; 

var string UIDisplayCam_WalkUpStart;		//Starting point for the slow truck downward that the after action report camera plays
var string UIDisplayCam_Default;			//Name of the point that the camera rests at in the after action report
var string UIBlueprint_Prefix;	            //Prefix for the blueprint containing camera + 3D screen location
var string UIBlueprint_Prefix_Wounded;
var string UIBlueprint_PrefixHero;	            //Prefix for the blueprint containing camera + 3D screen location
var string UIBlueprint_PrefixHero_Wounded;

// Config vars for post mission Faction line play chances
var config int FactionChosenCommentChance;
var config int FactionChosenDefeatedCommentChance;
var config int FactionMissionOutcomeCommentChance;
var config int FactionHeroOnMissionCommentChance;
var config int SitrepEventCommentChance;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local int i, listX, listWidth, listItemPadding;

	super.InitScreen(InitController, InitMovie, InitName);

	Navigator.HorizontalNavigation = true;
	Navigator.LoopSelection = true;

	// get existing states
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	m_kMissionInfo = Spawn(class'UISquadSelectMissionInfo', self).InitMissionInfo();

	listWidth = 0;
	listItemPadding = 6;
	for (i = 0; i < XComHQ.Squad.Length; ++i)
	{
		if (XComHQ.Squad[i].ObjectID > 0)
			listWidth += (class'UIAfterAction_ListItem'.default.width + listItemPadding); 
	}
	listX = Clamp((Movie.UI_RES_X / 2) - (listWidth / 2), 100, Movie.UI_RES_X / 2);

	m_kSlotList = Spawn(class'UIList', self);
	m_kSlotList.InitList('', listX, -405, Movie.UI_RES_X, 310, true).AnchorBottomLeft();
	m_kSlotList.itemPadding = listItemPadding;

	UpdateData();
	UpdateMissionInfo();
	BuildFlyoverList();

	//Delay by a slight amount to let pawns configure. Otherwise they will have Giraffe heads.
	SetTimer(0.1f, false, nameof(StartPostMissionCinematic));

	//SoldierPicture_Head_Armory

	`HQPRES.CAMLookAtNamedLocation(UIDisplayCam_WalkUpStart, 0.0f);
	XComHeadquartersController(`HQPRES.Owner).SetInputState('None');

	// Show header with "After Action" text
	`HQPRES.m_kAvengerHUD.FacilityHeader.SetText(class'UIFacility'.default.m_strAvengerLocationName, m_strAfterActionReport);
	`HQPRES.m_kAvengerHUD.FacilityHeader.Hide();
	Navigator.SetSelected(m_kSlotList);

	isBondIconFocused = UIAfterAction_ListItem(m_kSlotList.GetSelectedItem()).BondIcon.bIsFocused; // bsg-jrebar (05/19/17): Keep focus on bond or promote

	LoadPhotoboothAutoGenDeadSoldiers();

	//In case of emergency, and we've missed the cinematic event etc., this will trigger the nave help UI to activate. 
	SetTimer(10.0f, false, nameof(ForceNavHelpOn));
}

function ForceNavHelpOn()
{
	bForceHelpActivate = true;
	UpdateNavHelp();
}

function StartPostMissionCinematic()
{
	local int PawnIndex;
	local int SlotIndex;
	local XComLevelActor AvengerSunShade;	
	local SkeletalMeshActor CineDummy;
	local SkeletalMeshActor IterateActor;	
	local XComGameState_MissionSite MissionState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local PlayerController Controller;
		
	History = `XCOMHISTORY;

	`GAME.GetGeoscape().m_kBase.SetAvengerCapVisibility(true);
	`GAME.GetGeoscape().m_kBase.SetPostMissionSequenceVisibility(true);

	Controller = class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController();
	Controller.ClientSetCameraFade(false);
	
	//Turn off the sunshade object that prevents the directional light from affecting the avenger side view
	foreach AllActors(class'XComLevelActor', AvengerSunShade)
	{		
		if(AvengerSunShade.Tag == 'AvengerSunShade')
		{
			AvengerSunShade.StaticMeshComponent.bCastHiddenShadow = false;
			AvengerSunShade.ReattachComponent(AvengerSunShade.StaticMeshComponent);
			break;
		}				
	}

	foreach AllActors(class'SkeletalMeshActor', IterateActor)
	{
		if(IterateActor.Tag == 'Cin_PostMission1_Cinedummy')
		{
			CineDummy = IterateActor;
			break;
		}
		else if(IterateActor.Tag == 'AvengerSideView_Dropship')
		{
			IterateActor.SetHidden(true); //Hide the skyranger visible during the ant farm side view...
		}
	}

	`GAME.GetGeoscape().m_kBase.SetPreMissionSequenceVisibility(false); //make sure the pre-mission skyranger is hidden as well
	
	//Link the cinematic pawns to the matinee
	WorldInfo.MyKismetVariableMgr.RebuildVariableMap();
	SlotIndex = 1;
	for(PawnIndex = 0; PawnIndex < XComHQ.Squad.Length; ++PawnIndex)
	{
		if(XComHQ.Squad[PawnIndex].ObjectID > 0)
		{
			if(UnitPawnsCinematic[PawnIndex] != none)
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[PawnIndex].ObjectID));
				UnitPawnsCinematic[PawnIndex].Mesh.bUpdateSkelWhenNotRendered = true;
				UnitPawnsCinematic[PawnIndex].SetBase(CineDummy);				
				UnitPawnsCinematic[PawnIndex].SetupForMatinee(, true);
				if(SetPawnVariable(UnitPawnsCinematic[PawnIndex], UnitState, SlotIndex))
				{
					// only increment if we could fill the slot. We want to fill as many of the "important"
					// matinee slots as possible
					SlotIndex++; 
				}
			}
		}
	}	

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(true);

	Hide();

	WorldInfo.RemoteEventListeners.AddItem(self);

	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	if(!MissionState.GetMissionSource().bRequiresSkyrangerTravel)
	{
		`XCOMGRI.DoRemoteEvent('CIN_StartWithoutFlyIn');
	}
	else
	{
		`XCOMGRI.DoRemoteEvent('CIN_StartWithFlyIn');
	}

	`HQPRES.HideLoadingScreen();
}

function bool SetPawnVariable(XComUnitPawn UnitPawn, XComGameState_Unit UnitState, int SlotIndex)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;
	local string VariableName;

	if(UnitPawn == none || UnitState == none)
	{
		return false;
	}

	// matinee slot names match the one's used for the loading screens
	VariableName = UnitState.GetMyTemplate().strLoadingMatineeSlotPrefix $ SlotIndex;
	WorldInfo.MyKismetVariableMgr.GetVariable(name(VariableName), OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(UnitPawn);
			return true;
		}
	}

	// if we couldn't find a place for the pawn, just hide it
	UnitPawn.SetVisible(false);
	return false;
}

event OnRemoteEvent(name RemoteEventName)
{
	local int i, j;
	local UIAfterAction_ListItem ListItem;

	super.OnRemoteEvent(RemoteEventName);

	// Only show screen if we're at the top of the state stack
	if(RemoteEventName == 'PostM_ShowSoldierHUD' && 
		(`SCREENSTACK.GetCurrentScreen() == self || `SCREENSTACK.IsCurrentClass(class'UIRedScreen') || `SCREENSTACK.HasInstanceOf(class'UIProgressDialogue'))) //bsg-jneal (5.10.17): allow remote events to call through even with dialogues up
	{
		Show();

		`HQPRES.m_kAvengerHUD.FacilityHeader.Show();
		bRecievedShowHUDRemoteEvent = true;
		UpdateNavHelp();

		// Animate the slots in from left to right
		for(i = 0; i < SlotListOrder.Length; ++i)
		{
			for(j = 0; j < m_kSlotList.ItemCount; ++j)
			{
				ListItem = UIAfterAction_ListItem(m_kSlotList.GetItem(j));
				if(j == SlotListOrder[i])
					ListItem.AnimateIn(float(j));
			}
		}

		`GAME.GetGeoscape().m_kBase.UpdateFacilityProps();

		`GAME.GetGeoscape().m_kBase.m_kCrewMgr.PopulateBaseRoomsWithCrew();
	}
	else if(RemoteEventName == 'PostM_ShowSoldiers')
	{
		GotoState('Cinematic_PawnsWalkingUp');
	}
}

simulated function UpdateData()
{
	local bool bMakePawns;
	local int SlotIndex;	//Index into the list of places where a soldier can stand in the after action scene, from left to right
	local int SquadIndex;	//Index into the HQ's squad array, containing references to unit state objects
	local int ListItemIndex;//Index into the array of list items the player can interact with to view soldier status and promote
	local UIAfterAction_ListItem ListItem;	

	bMakePawns = UnitPawns.Length == 0;//We only need to create pawns if we have never had them before	

	ListItemIndex = 0;
	for (SlotIndex = 0; SlotIndex < SlotListOrder.Length; ++SlotIndex)
	{
		SquadIndex = SlotListOrder[SlotIndex];
		if (SquadIndex < XComHQ.Squad.Length)
		{	
			if (XComHQ.Squad[SquadIndex].ObjectID > 0)
			{
				if (bMakePawns)
				{
					if (ShowPawn(XComHQ.Squad[SquadIndex]))
					{
						UnitPawns[SquadIndex] = CreatePawn(XComHQ.Squad[SquadIndex], SquadIndex, false);
						UnitPawns[SquadIndex].SetVisible(false);
						UnitPawnsCinematic[SquadIndex] = CreatePawn(XComHQ.Squad[SquadIndex], SquadIndex, true);
					}
				}

				if (m_kSlotList.itemCount > ListItemIndex)
				{
					ListItem = UIAfterAction_ListItem(m_kSlotList.GetItem(ListItemIndex));
					ListItem.OnLoseFocus(); // bsg-jrebar (05/19/17): Init everything to not focused
				}
				else
				{
					ListItem = UIAfterAction_ListItem(m_kSlotList.CreateItem(class'UIAfterAction_ListItem')).InitListItem();
					ListItem.Index = ListItemIndex; 
					ListItem.OnLoseFocus(); // bsg-jrebar (05/19/17): Init everything to not focused
				}

				ListItem.UpdateData(XComHQ.Squad[SquadIndex]);

				++ListItemIndex;
			}
		}
	}
	
	m_kSlotList.SetSelectedIndex(-1);
	for (ListItemIndex = 0; ListItemIndex < m_kSlotList.itemCount; ListItemIndex++)
	{
		if (m_kSlotList.GetItem(ListItemIndex).bIsNavigable) 
		{
			m_kSlotList.SetSelectedIndex(ListItemIndex);
			break;
		}
	}

	m_kSlotList.Navigator.SelectFirstAvailable();

	isBondIconFocused = UIAfterAction_ListItem(m_kSlotList.GetSelectedItem()).BondIcon.bIsFocused; // bsg-jrebar (05/19/17): Keep focus on bond or promote

	UpdateNavHelp();
}

simulated function UpdateMissionInfo()
{
	local GeneratedMissionData MissionData;
	local XComGameState_MissionSite MissionState;

	m_kMissionInfo.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT).SetY(50);

	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);
	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));

	m_kMissionInfo.UpdateData(MissionData.BattleOpName, MissionState.GetMissionObjectiveText(), "", "");
}

simulated function int GetListItemIndexForUnit(StateObjectReference UnitRef)
{
	local int SlotIndex;	//Index into the list of places where a soldier can stand in the after action scene, from left to right
	local int SquadIndex;	//Index into the HQ's squad array, containing references to unit state objects
	local int MissingSoldiers;	//How many soldiers are missing, so that the list item index needs to be offset
	local int SlotOffset;
	local int ReturnIndex;
	local int FirstMissingSoldierIndex;
	
	MissingSoldiers = (XComHQ.Squad.Length - m_kSlotList.ItemCount);
	if (MissingSoldiers > 0)
	{
		// If there are missing soldiers, find the first index in the slot array where one is missing
		for (SlotIndex = 0; SlotIndex < SlotListOrder.Length; ++SlotIndex)
		{
			SquadIndex = SlotListOrder[SlotIndex];
			if (SquadIndex < XComHQ.Squad.Length)
			{
				if (XComHQ.Squad[SquadIndex].ObjectID == 0)
				{
					FirstMissingSoldierIndex = SlotIndex;
					break;
				}
			}
		}
	}

	for (SlotIndex = 0; SlotIndex < SlotListOrder.Length; ++SlotIndex)
	{
		SquadIndex = SlotListOrder[SlotIndex];
		if (SquadIndex < XComHQ.Squad.Length)
		{	
			if (XComHQ.Squad[SquadIndex].ObjectID == UnitRef.ObjectID)
			{
				ReturnIndex = SlotIndex;
				if (XComHQ.Squad.Length <= 4)
				{
					// Account for the left-most slot being hidden at game start by shifting each index to the left by one
					ReturnIndex--;
					FirstMissingSoldierIndex--;
				}
				
				// Calculate the remaining amount that needs to be shifted based on number of missing soldiers
				SlotOffset = min(ReturnIndex, MissingSoldiers);				
				if (SlotOffset > 0 && ReturnIndex > FirstMissingSoldierIndex)
				{
					// Account for any missing soldier gaps in the XComHQ.Squad, since all will be adjacent in the walkup
					ReturnIndex -= SlotOffset;
				}
				
				return ReturnIndex;
			}
		}
	}

	return -1;
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	if (!bIsFocused)  
		return; //bsg-crobinson (5.19.17): Don't update without focus

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();
	if (bRecievedShowHUDRemoteEvent || bForceHelpActivate)
	{

		if( `ISCONTROLLERACTIVE )
		{
			if( m_kSlotList.GetSelectedItem() == None )
			{
				NavHelp.AddContinueButton(OnContinue);
			}
			else
			{
				NavHelp.AddSelectNavHelp(, true);
				NavHelp.AddCenterHelp(m_strContinue, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, OnContinue);
			}
		}
		else
		{
			NavHelp.AddContinueButton(OnContinue);
		}
	}
}

simulated function OnContinue()
{		
	class'XComGameStateContext_StrategyGameRule'.static.RemoveInvalidSoldiersFromSquad();

	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action");
	`XEVENTMGR.TriggerEvent('PostAfterAction',,,UpdateState);
	`GAMERULES.SubmitGameState(UpdateState);

	`XCOMGRI.DoRemoteEvent('CIN_ExitRooftopLineup');

	`GAME.GetGeoscape().m_kBase.SetAvengerCapVisibility(false);

	CloseScreen();

	`HQPRES.UIInventory_LootRecovered();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;	

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if (!bRecievedShowHUDRemoteEvent)
	{
		return true;
	}
	bHandled = true;

	switch( cmd )
	{
		// OnAccept
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		//case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		//TEST//case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			if( bRecievedShowHUDRemoteEvent )
			{				
				//Only process continue once the player has seen the HUD
				OnContinue();
			}
			else
			{
				bHandled = false;
			}
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			`HQPRES.UIPauseMenu( ,true );
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			if (m_kSlotList.GetSelectedItem() != None) 
			{
				m_kSlotList.GetSelectedItem().OnUnrealCommand(cmd, arg);
			}
			else
			{
				OnContinue();
			}

			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			if (bRecievedShowHUDRemoteEvent)
			{
				OnContinue();
			}
			else
			{
				bHandled = false;
			}

			break;

		// bsg-nlong (1.24.17): Pass up and down input to the list item to cycle between promote and bond
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			if (m_kSlotList.GetSelectedItem() != None ) 
			{
				bHandled = m_kSlotList.GetSelectedItem().OnUnrealCommand(cmd, arg);
				isBondIconFocused = UIAfterAction_ListItem(m_kSlotList.GetSelectedItem()).BondIcon.bIsFocused;
			}
			break;
		// bsg-nlong (1.24.17): end
		// bsg-jrebar (05/19/17): Keep focus on bond or promote
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
			if (m_kSlotList.GetSelectedItem() != None )
			{
				bHandled = super.OnUnrealCommand(cmd, arg);
				if(bHandled && isBondIconFocused)
				{
					UIAfterAction_ListItem(m_kSlotList.GetSelectedItem()).OnUpDownInputHandler();
				}
				isBondIconFocused = UIAfterAction_ListItem(m_kSlotList.GetSelectedItem()).BondIcon.bIsFocused;
			}
			break;
		// bsg-jrebar (05/19/17): end
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	ForceNavHelpOn();
	UpdateData();
	`HQPRES.CAMLookAtNamedLocation(UIDisplayCam_Default, 0);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	if (Movie != none)
		XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function OnRemoved()
{
	super.OnRemoved();
	WorldInfo.RemoteEventListeners.RemoveItem(self);
	ClearPawns();	
}

//------------------------------------------------------

simulated function bool ShowPawn(StateObjectReference UnitRef)
{
	local XComGameState_Unit Unit;
	if(UnitRef.ObjectID > 0)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		return Unit.IsAlive() && !Unit.bCaptured; //At present, we show the pawn for all cases except death and capture
	}
	return false;
}

simulated function SetGremlinMatineeVariable(int idx, XComUnitPawn GremlinPawn)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	WorldInfo.MyKismetVariableMgr.GetVariable(name("Gremlin"$(idx+1)), OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(None);
			SeqVarPawn.SetObjectValue(GremlinPawn);
		}
	}
}

simulated function XComUnitPawn CreatePawn(StateObjectReference UnitRef, int index, bool bCinematic)
{
	local name LocationName;
	local PointInSpace PlacementActor;
	local XComGameState_Unit UnitState;
	local XComUnitPawn UnitPawn, GremlinPawn;
	local Vector ZeroVec;
	local Rotator ZeroRot;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if(!bCinematic)
	{
		LocationName = name(m_strPawnLocationIdentifier $ index);

		PlacementActor = GetPlacementActor(LocationName);

		UnitPawn = `HQPRES.GetUIPawnMgr().RequestPawnByState(self, UnitState, PlacementActor.Location, PlacementActor.Rotation);
		UnitPawn.GotoState('CharacterCustomization');

		UnitPawn.CreateVisualInventoryAttachments(`HQPRES.GetUIPawnMgr(), UnitState); // spawn weapons and other visible equipment

		GremlinPawn = `HQPRES.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
		if (GremlinPawn != none)
		{
			SetGremlinMatineeVariable(index, GremlinPawn);
			GremlinPawn.SetLocation(PlacementActor.Location);
			GremlinPawn.SetVisible(false);
		}
	}
	else
	{
		UnitPawn = UnitState.CreatePawn(self, ZeroVec, ZeroRot); //Create a throw-away pawn
		UnitPawn.CreateVisualInventoryAttachments(none, UnitState); // spawn weapons and other visible equipment
	}
		
	return UnitPawn;
}

simulated function XComUnitPawn GetPawn(StateObjectReference UnitRef)
{
	local int i;

	for(i = 0; i < XComHQ.Squad.Length; ++i)
	{
		if(XComHQ.Squad[i].ObjectID == UnitRef.ObjectID)
		{
			return UnitPawns[i];
		}
	}

	return none;
}

simulated function SetPawn(StateObjectReference UnitRef, XComUnitPawn NewPawn)
{
	local int i;

	for(i = 0; i < XComHQ.Squad.Length; ++i)
	{
		if(XComHQ.Squad[i].ObjectID == UnitRef.ObjectID)
		{
			UnitPawns[i] = NewPawn;
		}
	}	
}

simulated function name GetPawnLocationTag(StateObjectReference UnitRef, optional string PawnLocationItentifier = m_strPawnLocationIdentifier)
{	
	local int i;

	for(i = 0; i < XComHQ.Squad.Length; ++i)
	{
		if(XComHQ.Squad[i].ObjectID == UnitRef.ObjectID)
		{
			return name(PawnLocationItentifier $ i);
		}
	}

	return '';
}

simulated function string GetPromotionBlueprintTag(StateObjectReference UnitRef)
{
	local int i;
	local XComGameState_Unit UnitState;

	for(i = 0; i < XComHQ.Squad.Length; ++i)
	{
		if(XComHQ.Squad[i].ObjectID == UnitRef.ObjectID)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));
			// Start Issue #600
			if (UnitState.GetResistanceFaction() != none)
			{
				if (UnitState.IsGravelyInjured())
					return TriggerOverridePromotionBlueprintTagPrefix(UnitState, UIBlueprint_PrefixHero_Wounded) $ i;
				else
					return TriggerOverridePromotionBlueprintTagPrefix(UnitState, UIBlueprint_PrefixHero) $ i;
			}
			else
			{
				if (UnitState.IsGravelyInjured())
					return TriggerOverridePromotionBlueprintTagPrefix(UnitState, UIBlueprint_Prefix_Wounded) $ i;
				else
					return TriggerOverridePromotionBlueprintTagPrefix(UnitState, UIBlueprint_Prefix) $ i;
			}
			// End Issue #600
		}
	}

	return "";
}

// Start Issue #600
/// HL-Docs: feature:OverridePromotionBlueprintTagPrefix; issue:600; tags:strategy,ui
/// Fires an 'OverridePromotionBlueprintTagPrefix' event that allows mods to override
/// the promotion blueprint tag prefix for the after action screen. This means that
/// mods can ensure the camera is positioned properly when displaying their custom
/// promotion screen during the post-mission cinematic.
///
/// ```event
/// EventID: OverridePromotionBlueprintTagPrefix,
/// EventData: [in XComGameState_Unit UnitState, inout string TagPrefix],
/// EventSource: UIAfterAction (Screen),
/// NewGameState: none
/// ```
simulated function string TriggerOverridePromotionBlueprintTagPrefix(XComGameState_Unit UnitState, string TagPrefix)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverridePromotionBlueprintTagPrefix';
	Tuple.Data.Add(2);
	Tuple.Data[0].Kind = XComLWTVObject;
	Tuple.Data[0].o = UnitState;
	Tuple.Data[1].Kind = XComLWTVString;
	Tuple.Data[1].s = TagPrefix;

	`XEVENTMGR.TriggerEvent(Tuple.Id, Tuple, self);

	return Tuple.Data[1].s;
}
// End Issue #600

simulated function ClearPawns()
{
	local XComUnitPawn UnitPawn;
	foreach UnitPawns(UnitPawn)
	{
		if(UnitPawn != none)
		{
			`HQPRES.GetUIPawnMgr().ReleasePawn(self, UnitPawn.ObjectID);
		}
	}

	foreach UnitPawnsCinematic(UnitPawn)
	{
		if (UnitPawn != none)
		{
			UnitPawn.Destroy();
		}
	}

}

simulated function ResetUnitLocations()
{
	local int i;
	local XComUnitPawn UnitPawn, GremlinPawn;
	local PointInSpace PlacementActor;

	for(i = 0; i < XComHQ.Squad.Length; ++i)
	{
		UnitPawn = UnitPawns[i];
		PlacementActor = GetPlacementActor(GetPawnLocationTag(XComHQ.Squad[i]));

		if(UnitPawn != none && PlacementActor != None)
		{
			UnitPawn.SetLocation(PlacementActor.Location);
			UnitPawn.SetRotation(PlacementActor.Rotation);
			GremlinPawn = `HQPRES.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitPawn.ObjectID);
			if(GremlinPawn != none)
			{
				GremlinPawn.SetLocation(PlacementActor.Location);
				GremlinPawn.SetRotation(PlacementActor.Rotation);
			}
		}
	}
}

simulated function OnPromote(StateObjectReference UnitRef)
{
	`HQPRES.UIArmory_Promotion(UnitRef);
	MovePawns();
}

function MovePawns()
{
	local int i;
	local XComUnitPawn UnitPawn, GremlinPawn;
	local PointInSpace PlacementActor;
	local StateObjectReference UnitBeingPromoted;

	if(`SCREENSTACK.IsInStack(class'UIArmory_Promotion'))
		UnitBeingPromoted = UIArmory_Promotion(`SCREENSTACK.GetScreen(class'UIArmory_Promotion')).UnitReference;

	if (`SCREENSTACK.IsInStack(class'UIArmory_PromotionHero'))
		UnitBeingPromoted = UIArmory_PromotionHero(`SCREENSTACK.GetScreen(class'UIArmory_PromotionHero')).UnitReference;

	for(i = 0; i < XComHQ.Squad.Length; ++i)
	{
		if(XComHQ.Squad[i] == UnitBeingPromoted)
			continue;

		PlacementActor = GetPlacementActor(GetPawnLocationTag(XComHQ.Squad[i], m_strPawnLocationSlideawayIdentifier));
		UnitPawn = UnitPawns[i];

		if(UnitPawn != none && PlacementActor != none)
		{
			UnitPawn.SetLocation(PlacementActor.Location);
			GremlinPawn = `HQPRES.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitPawn.ObjectID);
			if(GremlinPawn != none)
				GremlinPawn.SetLocation(PlacementActor.Location);
		}
	}
}

simulated function PointInSpace GetPlacementActor(name PawnLocationTag)
{
	local Actor TmpActor;
	local array<Actor> Actors;
	local XComBlueprint Blueprint;
	local PointInSpace PlacementActor;

	foreach WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if (PlacementActor != none && PlacementActor.Tag == PawnLocationTag)
			break;
	}

	if(PlacementActor == none)
	{
		foreach WorldInfo.AllActors(class'XComBlueprint', Blueprint)
		{
			if (Blueprint.Tag == PawnLocationTag)
			{
				Blueprint.GetLoadedLevelActors(Actors);
				foreach Actors(TmpActor)
				{
					PlacementActor = PointInSpace(TmpActor);
					if(PlacementActor != none)
					{
						break;
					}
				}
			}
		}
	}

	return PlacementActor;
}

//During the after action report, the characters walk up to the camera - this state represents that time
state Cinematic_PawnsWalkingUp
{
	simulated event BeginState(name PreviousStateName)
	{
		bWalkupStarted = true;
		StartWalkAnimForPawns();
		WalkUpEvent();
		StartCameraMove();
	}

	function StartWalkAnimForPawns()
	{
		local int PawnIndex;
		local XComGameState_Unit UnitState;
		local XComGameStateHistory History;
		local X2SoldierPersonalityTemplate PersonalityData;
		local XComHumanPawn HumanPawn;
		local XComUnitPawn GremlinPawn;

		History = `XCOMHISTORY;

		for(PawnIndex = 0; PawnIndex < XComHQ.Squad.Length; ++PawnIndex)
		{
			if(XComHQ.Squad[PawnIndex].ObjectID > 0)
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[PawnIndex].ObjectID));
				PersonalityData = UnitState.GetPersonalityTemplate();

				UnitPawns[PawnIndex].EnableFootIK(false);
				UnitPawns[PawnIndex].SetVisible(true);

				HumanPawn = XComHumanPawn(UnitPawns[PawnIndex]);	
				if(HumanPawn != none)
				{
					HumanPawn.GotoState('SquadLineup_Walkup');
					GremlinPawn = `HQPRES.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, HumanPawn.ObjectID);
					if (GremlinPawn != none)
					{
						GremlinPawn.SetVisible(true);
						GremlinPawn.GotoState('Gremlin_Walkup');
					}
				}
				else
				{
					//If not human, just play the idle
					UnitPawns[PawnIndex].PlayFullBodyAnimOnPawn(PersonalityData.IdleAnimName, true);
				}
			}
		}
	}

	function WalkUpEvent()
	{
		// Begin the walkup sequence by triggering the soldier pawns
		UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Walk Up Event");
		`XEVENTMGR.TriggerEvent('AfterActionWalkUp', , , UpdateState);
		`GAMERULES.SubmitGameState(UpdateState);

		// First trigger any events from specific missions
		if (!TriggerSpecificMissionEvents())
		{
			// If no comment played, try to trigger any Hero Killed, Captured, or Chosen Encountered events		
			if (!TriggerXPackHeroAndChosenEvents())
			{
				// If no comment played, have a chance to play a relevant comment
				if (!TriggerExtraComments())
				{
					// If no comment played, report general mission outcome
					if (!TriggerMissionOutcomeEvent())
					{
						// If no comments have played up to this point, try and play extra comments again so someone says something
						TriggerExtraComments(true);
					}				
				}
			}
		}
	}

	function bool TriggerSpecificMissionEvents()
	{
		local XComGameStateHistory History;
		local XComGameState_BattleData BattleData;
		local XComGameState_MissionSite MissionState;

		History = `XCOMHISTORY;
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));

		if (BattleData.bLocalPlayerWon && class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M6_MoxReturns') == eObjectiveState_InProgress)
		{
			UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Mox Rescued");
			`XEVENTMGR.TriggerEvent('MoxRescuedAfterAction', , , UpdateState);
			`XCOMGAME.GameRuleset.SubmitGameState(UpdateState);
			return true;
		}
		else if (BattleData.bRulerEscaped)
		{
			UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Alien Ruler on Last Mission");
			`XEVENTMGR.TriggerEvent('AfterAction_RulerEscaped', , , UpdateState);
			`XCOMGAME.GameRuleset.SubmitGameState(UpdateState);
			return true;
		}
		else if (MissionState != None)
		{
			if (MissionState.GetMissionSource().DataName == 'MissionSource_LostAndAbandoned')
			{
				UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Lost and Abandoned");
				`XEVENTMGR.TriggerEvent('AfterAction_LostAndAbandoned', , , UpdateState);
				`GAMERULES.SubmitGameState(UpdateState);
				return true;
			}
			else if (MissionState.GetMissionSource().DataName == 'MissionSource_ChosenAvengerAssault')
			{
				UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Avenger Assault");
				`XEVENTMGR.TriggerEvent('AfterAction_AvengerAssault', , , UpdateState);
				`GAMERULES.SubmitGameState(UpdateState);
				return true;
			}
		}

		return false;
	}

	function bool TriggerXPackHeroAndChosenEvents()
	{
		local XComGameStateHistory History;
		local XComGameState_BattleData BattleData;
		local XComGameState_ResistanceFaction FactionState;
		local XComGameState_AdventChosen ChosenState;
		local XComGameState_MissionSite MissionState;

		History = `XCOMHISTORY;
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		// If the player permanently defeated one of the Chosen on the Stronghold mission, always play a comment
		if (BattleData.bChosenDefeated)
		{			
			if (class'X2StrategyGameRulesetDataStructures'.static.Roll(default.FactionChosenDefeatedCommentChance))
			{
				ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));
				if (ChosenState != None)
				{
					FactionState = ChosenState.GetRivalFaction();
					if (FactionState != None && FactionState.GetChosenDefeatedEvent() != '')
					{
						UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Chosen Defeated");
						`XEVENTMGR.TriggerEvent(FactionState.GetChosenDefeatedEvent(), , , UpdateState);
						`GAMERULES.SubmitGameState(UpdateState);
						return true;
					}
				}
			}
			
			// If a Faction event was not triggered or found, play a Central, Shen, or Tygan comment instead
			UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Chosen Defeated");
			`XEVENTMGR.TriggerEvent('AfterAction_ChosenDefeated', , , UpdateState);
			`GAMERULES.SubmitGameState(UpdateState);
			return true;
		}

		// If a soldier was rescued
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));
		if (MissionState != None && MissionState.GetMissionSource().DataName == 'MissionSource_RescueSoldier' && BattleData.OneStrategyObjectiveCompleted())
		{
			FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(MissionState.ResistanceFaction.ObjectID));
			if (FactionState != None && FactionState.GetSoldierRescuedEvent() != '')
			{
				UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Soldier Rescued");
				`XEVENTMGR.TriggerEvent(FactionState.GetSoldierRescuedEvent(), , , UpdateState);
				`GAMERULES.SubmitGameState(UpdateState);
				return true;
			}
		}
		
		// Acknowledge any Faction heroes which were killed or captured on the mission
		if (BattleData.FactionHeroesKilled.Length > 0)
		{
			FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(BattleData.FactionHeroesKilled[`SYNC_RAND(BattleData.FactionHeroesKilled.Length)].ObjectID));
			if (FactionState.GetHeroKilledEvent() != '')
			{
				UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Faction Hero Killed");
				`XEVENTMGR.TriggerEvent(FactionState.GetHeroKilledEvent(), , , UpdateState);
				`GAMERULES.SubmitGameState(UpdateState);
				return true;
			}
		}
		
		if (BattleData.bSoldierCaptured)
		{
			UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Soldier Captured Event");
			if (BattleData.FactionHeroesCaptured.Length > 0)
			{
				FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(BattleData.FactionHeroesCaptured[`SYNC_RAND(BattleData.FactionHeroesCaptured.Length)].ObjectID));
				`XEVENTMGR.TriggerEvent(FactionState.GetHeroCapturedEvent(), , , UpdateState);
			}
			else
			{
				`XEVENTMGR.TriggerEvent('AfterAction_SoldierCaptured', , , UpdateState);
			}
			`GAMERULES.SubmitGameState(UpdateState);
			return true;
		}
		
		if (BattleData.bChosenWon || BattleData.bChosenLost)
		{
			// A Chosen was encountered, so play one of the appropriate lines
			UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Chosen Encountered");
			if (BattleData.FactionHeroesOnMission.Length > 0 && class'X2StrategyGameRulesetDataStructures'.static.Roll(default.FactionChosenCommentChance))
			{
				FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(BattleData.FactionHeroesOnMission[`SYNC_RAND(BattleData.FactionHeroesOnMission.Length)].ObjectID));
				`XEVENTMGR.TriggerEvent(FactionState.GetChosenFoughtEvent(), , , UpdateState);
			}
			else if (BattleData.bChosenWon)
			{
				if(BattleData.bToughMission)
					`XEVENTMGR.TriggerEvent('AfterAction_ChosenWon_ToughMission', , , UpdateState);
				else
					`XEVENTMGR.TriggerEvent('AfterAction_ChosenWon', , , UpdateState);
			}
			else if (BattleData.bChosenLost)
			{
				`XEVENTMGR.TriggerEvent('AfterAction_ChosenLost', , , UpdateState);
			}
			`GAMERULES.SubmitGameState(UpdateState);
			return true;
		}

		return false;
	}

	function bool TriggerMissionOutcomeEvent()
	{
		local XComGameStateHistory History;
		local XComGameState_BattleData BattleData;
		local XComGameState_ResistanceFaction FactionState;

		History = `XCOMHISTORY;
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		if (BattleData.bGreatMission)
		{
			UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Great Mission Event");
			if (BattleData.FactionHeroesOnMission.Length > 0 && class'X2StrategyGameRulesetDataStructures'.static.Roll(default.FactionMissionOutcomeCommentChance))
			{
				FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(BattleData.FactionHeroesOnMission[`SYNC_RAND(BattleData.FactionHeroesOnMission.Length)].ObjectID));
				`XEVENTMGR.TriggerEvent(FactionState.GetGreatMissionEvent(), , , UpdateState);
			}
			else
			{
				`XEVENTMGR.TriggerEvent('AfterAction_GreatMission', , , UpdateState);
			}
			`GAMERULES.SubmitGameState(UpdateState);
			return true;
		}
		else if (BattleData.bToughMission)
		{
			UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Tough Mission Event");
			if (BattleData.FactionHeroesOnMission.Length > 0 && class'X2StrategyGameRulesetDataStructures'.static.Roll(default.FactionMissionOutcomeCommentChance))
			{
				FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(BattleData.FactionHeroesOnMission[`SYNC_RAND(BattleData.FactionHeroesOnMission.Length)].ObjectID));
				`XEVENTMGR.TriggerEvent(FactionState.GetToughMissionEvent(), , , UpdateState);
			}
			else
			{
				`XEVENTMGR.TriggerEvent('AfterAction_ToughMission', , , UpdateState);
			}
			`GAMERULES.SubmitGameState(UpdateState);
			return true;
		}
		
		return false;
	}

	function bool TriggerExtraComments(optional bool bIgnoreRoll = false)
	{
		// If no comment played, check for SITREP specific commentary
		if (!TriggerSitrepEvent(bIgnoreRoll))
		{
			// If no comment played, check for any Hero specific commentary
			if (!TriggerFactionHeroOnMissionEvent(bIgnoreRoll))
			{
				return false;
			}
		}

		return true;
	}

	function bool TriggerSitrepEvent(bool bIgnoreRoll)
	{
		local XComGameStateHistory History;
		local XComGameState_BattleData BattleData;

		History = `XCOMHISTORY;
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		if (class'X2StrategyGameRulesetDataStructures'.static.Roll(default.SitrepEventCommentChance) || bIgnoreRoll)
		{
			if (BattleData.ActiveSitReps.Find('TheLost') != INDEX_NONE || BattleData.ActiveSitReps.Find('TheHorde') != INDEX_NONE)
			{
				UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Lost Encountered Event");
				`XEVENTMGR.TriggerEvent('AfterAction_LostEncountered', , , UpdateState);
				`GAMERULES.SubmitGameState(UpdateState);
				return true;
			}
		}

		return false;
	}

	function bool TriggerFactionHeroOnMissionEvent(bool bIgnoreRoll)
	{
		local XComGameStateHistory History;
		local XComGameState_BattleData BattleData;
		local XComGameState_ResistanceFaction FactionState;

		History = `XCOMHISTORY;
		BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		if (class'X2StrategyGameRulesetDataStructures'.static.Roll(default.FactionHeroOnMissionCommentChance) || bIgnoreRoll)
		{
			if (BattleData.FactionHeroesOnMission.Length > 0)
			{
				UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("After Action Hero On Mission Event");
				if (BattleData.FactionHeroesHighLevel.Length > 0)
				{
					`XEVENTMGR.TriggerEvent('AfterAction_HighLevelHero', , , UpdateState);
				}
				else
				{
					FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(BattleData.FactionHeroesOnMission[`SYNC_RAND(BattleData.FactionHeroesOnMission.Length)].ObjectID));
					`XEVENTMGR.TriggerEvent(FactionState.GetHeroOnMissionEvent(), , , UpdateState);
				}
				`GAMERULES.SubmitGameState(UpdateState);
				return true;
			}
		}

		return false;
	}

	function StartCameraMove()
	{
		//<workshop> Fix temporary control lockup after mission by changing interp time from 6 to 0 seconds... the camera didn't seem to move anyways AMS 2016/05/25
		//`HQPRES.CAMLookAtNamedLocation(UIDisplayCam_Default, 6.0f);
		`HQPRES.CAMLookAtNamedLocation(UIDisplayCam_Default, 0.0f);
	}
}

function RestoreCamera()
{
	`HQPRES.CAMLookAtNamedLocation(UIDisplayCam_Default, 6.0f);
}

//----------------------------------------------------------------------------------

function BuildFlyoverList()
{	
	local int Priority;
	
	Priority = 0;
	AddWillStateFlyovers(Priority);
	AddMostCohesionFlyovers(Priority);
	AddBondAvailableFlyovers(Priority);
}

function AddWillStateFlyovers(out int Priority)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local bool bFlyoverAdded;
	local int idx;

	History = `XCOMHISTORY;

	// Add flyovers for any soldier who is Tired or Shaken after the mission
	for (idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		if (XComHQ.Squad[idx].ObjectID > 0)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));
			if (UnitState.IsAlive() && !UnitState.bCaptured && UnitState.BelowReadyWillState())
			{
				AddFlyover(UnitState.GetMentalStateLabel(), "", class'UIUtilities_Colors'.const.BLACK_HTML_COLOR, Priority, GetListItemIndexForUnit(UnitState.GetReference()));
				bFlyoverAdded = true;
			}
		}
	}

	// If a flyover was added, increase the priority for the next group
	if (bFlyoverAdded)
	{
		Priority++; 
	}
}

function AddMostCohesionFlyovers(out int Priority)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitStateA, UnitStateB;
	local SoldierBond BondData;
	local array<StateObjectReference> MaxCohesionPair;
	local bool bFlyoverAdded;
	local int i, j, MaxCohesion;

	History = `XCOMHISTORY;

	// Add flyovers for the soldier pair with the highest cohesion gain
	for (i = 0; i < XComHQ.Squad.Length - 1; i++)
	{
		if (XComHQ.Squad[i].ObjectID > 0)
		{
			UnitStateA = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));
			if (UnitStateA.IsAlive() && !UnitStateA.bCaptured)
			{
				for (j = (i+1); j < XComHQ.Squad.Length; j++)
				{
					UnitStateB = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[j].ObjectID));
					if (UnitStateB.IsAlive() && !UnitStateB.bCaptured)
					{
						UnitStateA.GetBondData(UnitStateB.GetReference(), BondData);
						if (MaxCohesion == 0 || BondData.MostRecentCohesionGain > MaxCohesion)
						{
							MaxCohesion = BondData.MostRecentCohesionGain;
							MaxCohesionPair.Length = 0; // Clear the max cohesion pair and re-add the new pair
							MaxCohesionPair.AddItem(UnitStateA.GetReference());
							MaxCohesionPair.AddItem(UnitStateB.GetReference());
						}
					}
				}
			}
		}
	}

	// There is only one max cohesion pair at the end of each mission
	for (i = 0; i < MaxCohesionPair.Length; i++)
	{
		AddFlyover(m_strMostCohesion, "", class'UIUtilities_Colors'.const.GOOD_HTML_COLOR, Priority, GetListItemIndexForUnit(MaxCohesionPair[i]));
		bFlyoverAdded = true;
	}

	// If a flyover was added, increase the priority for the next group
	if (bFlyoverAdded)
	{
		Priority++;
	}
}

function AddBondAvailableFlyovers(out int Priority)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitStateA, UnitStateB;
	local SoldierBond BondData;
	local int i, j;

	History = `XCOMHISTORY;

	// Add flyovers for any soldiers who have developed bonds
	for (i = 0; i < XComHQ.Squad.Length - 1; i++)
	{
		if (XComHQ.Squad[i].ObjectID > 0)
		{
			UnitStateA = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));
			if (UnitStateA.IsAlive() && !UnitStateA.bCaptured)
			{
				for (j = (i+1); j < XComHQ.Squad.Length; j++)
				{
					UnitStateB = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[j].ObjectID));
					if (UnitStateB.IsAlive() && !UnitStateB.bCaptured)
					{
						UnitStateA.GetBondData(UnitStateB.GetReference(), BondData);
						if (BondData.bSoldierBondLevelUpAvailable)
						{
							if (BondData.BondLevel > 0)
							{
								// Add two flyovers, one for each unit which has a bond available, at the same priority
								AddFlyover(m_strBondLevelUpAvailable, "", class'UIUtilities_Colors'.const.GOOD_HTML_COLOR, Priority, GetListItemIndexForUnit(UnitStateB.GetReference()));
								AddFlyover(m_strBondLevelUpAvailable, "", class'UIUtilities_Colors'.const.GOOD_HTML_COLOR, Priority, GetListItemIndexForUnit(UnitStateA.GetReference()));
							}
							else
							{
								// Add two flyovers, one for each unit which has a bond available, at the same priority
								AddFlyover(m_strBondAvailable, "", class'UIUtilities_Colors'.const.GOOD_HTML_COLOR, Priority, GetListItemIndexForUnit(UnitStateA.GetReference()));
								AddFlyover(m_strBondAvailable, "", class'UIUtilities_Colors'.const.GOOD_HTML_COLOR, Priority, GetListItemIndexForUnit(UnitStateB.GetReference()));
							}

							Priority++; // Increase priority for the next pair or flyover group
						}
					}
				}
			}
		}
	}


}

function AddFlyover(string strLabel, string strIcon, string strColor, int iPriority, int iSlot)
{
	local TUIAfterActionFlyoverInfo Info;

	Info.Label = strLabel;
	Info.Icon = strIcon;
	Info.ColorStr = strColor;
	Info.Priority = iPriority;
	Info.Slot = iSlot;

	if (Info.Slot > -1)
		Flyovers.AddItem(Info);
}

event Tick(float deltaTime)
{
	local float DelayPerPriorityLevel; 
	local float BaseDelay; 
	local int idx; 
	local TUIAfterActionFlyoverInfo Info; 

	if( Flyovers.length == 0 ) return;
	if( !bIsVisible || !bWalkupStarted ) return;

	FlyoverTime += deltaTime; 

	BaseDelay = 2.5;
	DelayPerPriorityLevel = 2.0; 

	if( FlyoverTime > ((DelayPerPriorityLevel * FlyoverPriorityLevel) + BaseDelay) )
	{
		for( idx = 0; idx < Flyovers.Length; idx++ )
		{
			Info = Flyovers[idx];
			if( Info.Priority == FlyoverPriorityLevel )
			{
				UIAfterAction_ListItem(m_kSlotList.GetItem(Info.Slot)).AS_SetUnitFlyover(Info.Icon, Info.Label, Info.ColorStr);
			}
		}
		FlyoverPriorityLevel++;
	}
}

function LoadPhotoboothAutoGenDeadSoldiers()
{
	local int SlotIndex;	//Index into the list of places where a soldier can stand in the after action scene, from left to right
	local int SquadIndex;	//Index into the HQ's squad array, containing references to unit state objects
	local XComGameState_Unit Unit;
	local bool bRequestAdded;

	bRequestAdded = false;
	for (SlotIndex = 0; SlotIndex < SlotListOrder.Length; ++SlotIndex)
	{
		SquadIndex = SlotListOrder[SlotIndex];
		if (SquadIndex < XComHQ.Squad.Length)
		{
			if (XComHQ.Squad[SquadIndex].ObjectID > 0)
			{
				Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Squad[SquadIndex].ObjectID));

				// Check for high ranking soldier death,
				if (!Unit.bCaptured && Unit.IsDead() && Unit.GetSoldierRank() >= 3)
				{
					`HQPRES.GetPhotoboothAutoGen().AddDeadSoldier(Unit.GetReference());
					bRequestAdded = true;
				}
			}
		}
	}

	if (bRequestAdded)
	{
		`HQPRES.GetPhotoboothAutoGen().RequestPhotos();
	}
}

DefaultProperties
{
	Package   = "/ package/gfxSquadList/SquadList";

	InputState = eInputState_Consume;
	bHideOnLoseFocus = true;
	bAutoSelectFirstNavigable = false;
	
	m_strPawnLocationIdentifier = "Blueprint_AfterAction_Promote";
	m_strPawnLocationSlideawayIdentifier = "UIPawnLocation_SlideAway_";

	UIDisplayCam_WalkUpStart = "Cam_AfterAction_Start"; //Starting point for the slow truck downward that the after action report camera plays
	UIDisplayCam_Default = "Cam_AfterAction_End"; //Name of the point that the camera rests at in the after action report
	UIBlueprint_Prefix = "Blueprint_AfterAction_Promote" //Prefix for the name of the point used for editing soldiers in-place on the avenger deck
	UIBlueprint_Prefix_Wounded = "Blueprint_AfterAction_PromoteWounded"
	UIBlueprint_PrefixHero = "Blueprint_AfterAction_HeroPromote" //Prefix for the name of the point used for editing soldiers in-place on the avenger deck
	UIBlueprint_PrefixHero_Wounded = "Blueprint_AfterAction_HeroPromoteWounded"

		//Refer to the points / camera setup in CIN_PostMission1 to understand this array
		SlotListOrder[0] = 4
		SlotListOrder[1] = 1
		SlotListOrder[2] = 0
		SlotListOrder[3] = 2
		SlotListOrder[4] = 3
		SlotListOrder[5] = 5

	FlyoverPriorityLevel = 0;
	FlyoverTime = 0.0; 
	bForceHelpActivate = false;
}
