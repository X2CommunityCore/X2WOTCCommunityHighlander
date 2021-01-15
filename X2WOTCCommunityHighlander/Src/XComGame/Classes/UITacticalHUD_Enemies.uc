//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_Enemies.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: HUD component to show currently visible aliens to the active soldier. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD_Enemies extends UIPanel implements(X2VisualizationMgrObserverInterface);

var Actor m_kTargetActor;
var array<StateObjectReference> m_arrTargets;
var array<StateObjectReference> m_arrCurrentlyAffectable;
var array<StateObjectReference> m_arrSSEnemies;
var int m_iMaxNumberOfEnemies; //Corresponds to the number of flash icons on stage, since these are not dynamic. 
var public string m_strBonusMC;
var public string m_strPenaltyMC;
var public string m_strIconMC;
var int CurrentTargetIndex; 
var int m_iCurrentHover;
var int m_iVisibleEnemies; 
var int IconWidth; 
var int IconHeight; 
var int LargeIconWidth; 
var int LargeIconHeight;
var int iNumVisibleEnemies;
var XGUnit m_highlightedEnemy; //this is the enemy highlighted by hovering over the enemy icon right above the ability confirmation icon, which is not neccessarily the same as targeted enemy

// The last History Index that was realized
var int LastRealizedIndex;
var int LatestVisBlockCompletedIndex;

var X2GameRulesetVisibilityManager VisibilityMgr; 

var localized string m_strHitTooltip;
var localized string m_strCritTooltip;

var X2Camera_LookAtEnemyHead LookAtTargetCam;

simulated function UITacticalHUD_Enemies InitEnemyTargets()
{
	InitPanel();
	Hide();
	if(!Movie.IsMouseActive())
		MC.FunctionVoid("MoveDown");
	return self;
}

simulated function OnInit()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnInit();

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable(XComTacticalController(PC), 'GetActiveUnit', self, OnTacticalControllerSelectedUnitChanged);

	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( UITacticalHUD(screen), 'm_isMenuRaised', self, UpdateVisibleEnemies);
	//WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( UITacticalHUD(screen).m_kAbilityHUD, 'm_iCurrentIndex', self, UpdateVisibleEnemies);

	//UpdateVisibleEnemies();

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'ScamperBegin', OnReEvaluationEvent, ELD_OnVisualizationBlockCompleted);
	EventManager.RegisterForEvent(ThisObj, 'UnitDied', OnReEvaluationEvent, ELD_OnVisualizationBlockCompleted);
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockCompleted);

	InitializeTooltipData();
	if(!Movie.IsMouseActive())
		InitNavHelp();
}

function AddLookAtTargetCamera(Actor LookAtActor)
{
	if(LookAtTargetCam == none)
	{
		LookAtTargetCam = new class'X2Camera_LookAtEnemyHead';
		LookAtTargetCam.ActorToFollow = LookAtActor;
		`CAMERASTACK.AddCamera(LookAtTargetCam);
	}
}

function RemoveLookAtTargetCamera()
{
	local XComCamera Cam;	

	Cam = XComCamera(GetALocalPlayerController().PlayerCamera);

	if(Cam != none && LookAtTargetCam != none)
	{		
		Cam.CameraStack.RemoveCamera(LookAtTargetCam);
		LookAtTargetCam = none;
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int TargetIndex;

	// Dont allow selections with the mouse if we are in the first mission
	if ( `BATTLE.m_kDesc.m_bIsTutorial && `BATTLE.m_kDesc.m_bDisableSoldierChatter)
		return;
	
	TargetIndex = int(Split( args[5], "icon", true));


	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:

			RemoveLookAtTargetCamera();

			if(!UITacticalHUD(Owner).IsMenuRaised())
			{
				SetFocusedEnemy(-1, -1);
				ClearSelectedEnemy();
				m_kTargetActor = none; 
			} 
			else if(CurrentTargetIndex != TargetIndex)
			{
				SetFocusedEnemy(-1, -1); // hide hit chance if not currently targeted enemy
			}

			ClearHighlightedEnemy();
			RefreshShine(False);
			m_iCurrentHover = -1;
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:

			`XTACTICALSOUNDMGR.PlayPersistentSoundEvent("TacticalUI_TargetSelectMouse");

			m_kTargetActor = GetEnemyAtIcon( TargetIndex );

			HighlightEnemy(XGUnit(m_kTargetActor));

			if( !XComPresentationLayer(screen.Owner).Get2DMovie().HasModalScreens() )
			{
				AddLookAtTargetCamera(m_kTargetActor);
				SetFocusedEnemy(TargetIndex, GetHitChance(TargetIndex));
			}
			RefreshShine(true);
			m_iCurrentHover = TargetIndex;
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			SelectEnemyByIndex(TargetIndex);
			break;
	}
}

simulated function int GetHitChance(int TargetIndex)
{
	return GetHitChanceForObjectRef(GetEnemyRefAtIcon(TargetIndex));
}

simulated function int GetHitChanceForObjectRef(StateObjectReference TargetRef)
{
	local AvailableAction Action;
	local ShotBreakdown Breakdown;
	local X2TargetingMethod TargetingMethod;
	local XComGameState_Ability AbilityState;

	//If a targeting action is active and we're hoving over the enemy that matches this action, then use action percentage for the hover  
	TargetingMethod = XComPresentationLayer(screen.Owner).GetTacticalHUD().GetTargetingMethod();

	if( TargetingMethod != none && TargetingMethod.GetTargetedObjectID() == TargetRef.ObjectID )
	{	
		AbilityState = TargetingMethod.Ability;
	}
	else
	{			
		AbilityState = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetCurrentSelectedAbility();

		if( AbilityState == None )
		{
			XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetDefaultTargetingAbility(TargetRef.ObjectID, Action, true);
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		}
	}

	if( AbilityState != none )
	{
		AbilityState.LookupShotBreakdown(AbilityState.OwnerStateObject, TargetRef, AbilityState.GetReference(), Breakdown);
		
		if( !Breakdown.HideShotBreakdown )
		{
		    return min(((Breakdown.bIsMultishot ) ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance ), 100);
	    }
	}

	return -1;
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	RealizeTargets(GameState.HistoryIndex);

	return ELR_NoInterrupt;
}

function EventListenerReturn OnReEvaluationEvent(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	RealizeTargets(GameState.HistoryIndex);

	return ELR_NoInterrupt;
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	//Track the largest index we have seen so far. This is necessary because the OnVisualizationBlockComplete can complete in an arbitrary order relative to the history
	if (AssociatedGameState.HistoryIndex > LatestVisBlockCompletedIndex)
	{
		//Limit how often this can be called	
		if (AssociatedGameState.GetContext().bLastEventInChain)
		{
			RealizeTargets(AssociatedGameState.HistoryIndex);
		}

		LatestVisBlockCompletedIndex = AssociatedGameState.HistoryIndex;
	}
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	RealizeTargets(-1);

	// play the sighted enemies sound whenever changing the active unit if there are any visible enemies
	if( iNumVisibleEnemies > 0 )
	{
		PlayEnemySightedSound();
	}

	// note that this will also play when regaining control of the same unit. If this proves undesirable, the additional update is to cache off the 
	// SightedEnemiesAtLastNotification in PlayEnemySightedSound() and check as follows:
	//
	//{
	//	local StateObjectReference CurrentRef;

	//	// play the sighted enemies sound if there are any visible enemies which were not notified about previously
	//	foreach m_arrTargets(CurrentRef)
	//	{
	//		if( SightedEnemiesAtLastNotification.Find('ObjectID', CurrentRef.ObjectID) == INDEX_NONE )
	//		{
	//			PlayEnemySightedSound();
	//			break;
	//		}
	//	}
	//}
}

event OnVisualizationIdle();

function PlayEnemySightedSound()
{
	PlaySound(SoundCue'SoundFX.AlienInRangeCue');
}

simulated function RealizeTargets(int HistoryIndex, bool bDontRefreshVisibleEnemies = false)
{
	if (HistoryIndex == -1)		//	force an update no matter what (e.g. if we switched units, we could realize the same index)
	{
		LastRealizedIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	}
	else
	{
		if (HistoryIndex < LastRealizedIndex)
			return;
		LastRealizedIndex = HistoryIndex;
	}

	//  update the abilities array - otherwise when the enemy heads get sorted by hit chance, the cached abilities those functions use could be out of date
	XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.UpdateAbilitiesArray();
	XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.MC.FunctionVoid("MoveDown");
	XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyPreview.MC.FunctionVoid("MoveDownPreview");

	ClearSelectedEnemy();
	if( !bDontRefreshVisibleEnemies )
	{
		UpdateVisibleEnemies(HistoryIndex);
	}
}

simulated function int GetEnemyCount()
{
	return m_arrTargets.Length;
}

simulated function SelectEnemyByIndex(int TargetIndex)
{
	UITacticalHUD(Owner).m_kAbilityHUD.DirectTargetObject( GetEnemyRefAtIcon(TargetIndex).ObjectID );
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.ActivateExtensionForTargetedUnit( GetSelectedEnemyStateObjectRef() );
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

		
simulated function UpdateVisibleEnemies(int HistoryIndex)
{
	local XGUnit kActiveUnit;
	local XComGameState_Unit ActiveUnit;
	local XComGameStateHistory History;
	local int i;
	local XComGameState_Ability CurrentAbilityState;
	local X2AbilityTemplate AbilityTemplate;

	m_arrSSEnemies.length = 0;
	m_arrCurrentlyAffectable.length = 0;

	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	if (kActiveUnit != none)
	{
		// DATA: -----------------------------------------------------------
		History = `XCOMHISTORY;
		ActiveUnit = XComGameState_Unit(History.GetGameStateForObjectID(kActiveUnit.ObjectID, , HistoryIndex));

		CurrentAbilityState = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kAbilityHUD.GetCurrentSelectedAbility();
		AbilityTemplate = CurrentAbilityState != none ? CurrentAbilityState.GetMyTemplate() : none;

		if (AbilityTemplate != none && AbilityTemplate.AbilityTargetStyle.SuppressShotHudTargetIcons())
		{
			m_arrTargets.Length = 0;
		}
		else
		{
			ActiveUnit.GetUISummary_TargetableUnits(m_arrTargets, m_arrSSEnemies, m_arrCurrentlyAffectable, CurrentAbilityState, HistoryIndex);
		}

		// if the currently selected ability requires the list of ability targets be restricted to only the ones that can be affected by the available action, 
		// use that list of targets instead
		if (AbilityTemplate != none)
		{
			if (AbilityTemplate.bLimitTargetIcons)
			{
				m_arrTargets = m_arrCurrentlyAffectable;
			}
			else
			{
				//  make sure that all possible targets are in the targets list - as they may not be visible enemies
				for (i = 0; i < m_arrCurrentlyAffectable.Length; ++i)
				{
					if (m_arrTargets.Find('ObjectID', m_arrCurrentlyAffectable[i].ObjectID) == INDEX_NONE)
						m_arrTargets.AddItem(m_arrCurrentlyAffectable[i]);
				}
			}
		}
		
		iNumVisibleEnemies = m_arrTargets.Length;

		m_arrTargets.Sort(SortEnemies);
		UpdateVisuals(HistoryIndex);
	}
}
public function UpdateVisuals(int HistoryIndex)
{
	local XGUnit kActiveUnit;
	local XComGameState_BaseObject TargetedObject;
	local XComGameState_Unit EnemyUnit;
	local X2VisualizerInterface Visualizer;
	local XComGameStateHistory History;
	local StateObjectReference ActiveUnitRef;
	local int i;
	local bool DisabledIcon;

	// DATA: -----------------------------------------------------------
	History = `XCOMHISTORY;
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	ActiveUnitRef.ObjectID = kActiveUnit.ObjectID;
	if( kActiveUnit == none ) return; 


	// VISUALS: -----------------------------------------------------------
	// Now that the array is tidy, we can set the visuals from it.
	
	SetVisibleEnemies( iNumVisibleEnemies ); //Do this before setting data 

	for(i = 0; i < m_arrTargets.Length; i++)
	{
		TargetedObject = History.GetGameStateForObjectID(m_arrTargets[i].ObjectID, , HistoryIndex);
		Visualizer = X2VisualizerInterface(TargetedObject.GetVisualizer());
		EnemyUnit = XComGameState_Unit(TargetedObject);
			
		SetIcon( i, Visualizer.GetMyHUDIcon() );
		SetFlanked(i, false);  // Flanking was leaking inappropriately! 

		if( m_arrCurrentlyAffectable.Find('ObjectID', TargetedObject.ObjectID) > -1 )
		{
			SetBGColor(i, Visualizer.GetMyHUDIconColor());
			SetDisabled(i, false);
			DisabledIcon = false;
		}
		else
		{
			SetBGColor(i, eUIState_Disabled);
			SetDisabled(i, true);
			DisabledIcon = true;
		}
				
		if(m_arrSSEnemies.Find('ObjectID', TargetedObject.ObjectID) > -1)
			SetSquadSight(i, true);
		else
			SetSquadSight(i, false);

		if( EnemyUnit != none && EnemyUnit.IsFlanked(ActiveUnitRef, false, HistoryIndex) && !DisabledIcon )
			SetFlanked(i, true);
			
	}

	RefreshShine();

	Movie.Pres.m_kTooltipMgr.ForceUpdateByPartialPath( string(MCPath) );

	// force set selected index, since updating the visible enemies resets the state of the selected target
	if(CurrentTargetIndex != -1)
		SetTargettedEnemy(CurrentTargetIndex, true);
}


function RefreshShine(optional bool bMoveAbovePercent = false)
{
	local int i;
	local bool bMenuRaised; 

	if( `REPLAY.bInTutorial )
	{
		bMenuRaised = UITacticalHUD(Screen).IsMenuRaised();
		for( i = 0; i < m_arrTargets.Length; i++ )
		{
			if( `TUTORIAL.IsTarget(m_arrTargets[i].ObjectID) && bMenuRaised)
			{
				SetShine(i, true, bMoveAbovePercent);
			}
			else
			{
				SetShine(i, false, bMoveAbovePercent);
			}
		}
	}
}

simulated function int SortEnemies(StateObjectReference ObjectA, StateObjectReference ObjectB)
{
	local XComGameState_Destructible DestructibleTargetA, DestructibleTargetB;
	local XComGameStateHistory History;
	local int HitChanceA, HitChanceB;

	History = `XCOMHISTORY; 
	DestructibleTargetA = XComGameState_Destructible(History.GetGameStateForObjectID(ObjectA.ObjectID));
	DestructibleTargetB = XComGameState_Destructible(History.GetGameStateForObjectID(ObjectB.ObjectID));

	//Push the destructible enemies to the back of the list.
	if( DestructibleTargetA != none && DestructibleTargetB == none ) 
	{
		return -1;
	}
	if( DestructibleTargetB != none && DestructibleTargetA == none ) 
	{
		return 1;
	}

	// push lower-hit chance targets back
	HitChanceA = GetHitChanceForObjectRef(ObjectA);
	HitChanceB = GetHitChanceForObjectRef(ObjectB);
	if( HitChanceA < HitChanceB )
	{
		return -1;
	}

	return 1;
}

simulated function RefreshSelectedEnemy(optional bool bUpdateVisibleTargets, optional bool bShowHitPercentage = true)
{
	local int i, TargetID;
	local XGUnit kUnit; 
	local X2TargetingMethod TargetingMethod; 
	local XComGameState_Unit kTargetGameStateUnit; 
	local array<UISummary_UnitEffect> bonuses, penalties; 

	kUnit = XComTacticalController(PC).GetActiveUnit(); 
	if( kUnit == none )                 return; 

	TargetingMethod = XComPresentationLayer(screen.Owner).GetTacticalHUD().GetTargetingMethod();
	if( TargetingMethod == none )           { SetTargettedEnemy( -1 ); return; }
	
	TargetID = TargetingMethod.GetTargetedObjectID();
	if (TargetID == 0)
		return;

	if(bUpdateVisibleTargets)
		UpdateVisibleEnemies(-1);

	kTargetGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetID));

	for( i = 0; i < m_arrTargets.Length; i++ )
	{
		if( TargetID == m_arrTargets[i].ObjectID)
		{
			SetTargettedEnemy( i );
			SetFocusedEnemy(i, bShowHitPercentage ? GetHitChance(i) : -1);

			if (kTargetGameStateUnit != none)
			{
				bonuses = kTargetGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Bonus); 
				penalties = kTargetGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Penalty);
				SetBonusAndPenalty(i, (bonuses.length>0), (penalties.length>0) );
			}
			return;
		}
	}

	// If we didn't set a target, clear out the targeting indicator
	ClearSelectedEnemy();
}

simulated function RefreshAllTargetsBuffs()
{
	local int i;
	local array<UISummary_UnitEffect> bonuses, penalties; 
	local XComGameState_Unit kTargetGameStateUnit; 

	for( i = 0; i < m_arrTargets.Length; i++ )
	{
		kTargetGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_arrTargets[i].ObjectID));

		if (kTargetGameStateUnit != none)
		{
			bonuses = kTargetGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Bonus); 
			penalties = kTargetGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Penalty);
			SetBonusAndPenalty(i, (bonuses.length>0), (penalties.length>0) );
		}
	}
}

simulated function RefreshTargetHoverData()
{
	if (m_iCurrentHover >= 0)
	{
		SetFocusedEnemy(m_iCurrentHover, GetHitChance(m_iCurrentHover));
	}
}

simulated function ClearSelectedEnemy()
{
	ClearHighlightedEnemy();	
	SetTargettedEnemy(-1);
}

simulated function Actor GetEnemyAtIcon( int iTargetIcon )
{
	if (iTargetIcon >= 0 && iTargetIcon <= m_arrTargets.Length)
		return `XCOMHISTORY.GetVisualizer(m_arrTargets[iTargetIcon].ObjectID);
	else
		return none; 
}

simulated function StateObjectReference GetEnemyRefAtIcon( int iTargetIcon )
{
	local StateObjectReference EmptyRef;
	if (iTargetIcon >= 0 && iTargetIcon <= m_arrTargets.Length)
		return m_arrTargets[iTargetIcon];
	else
		return EmptyRef; 
}

simulated function int GetEnemyIDAtIcon( int iTargetIcon )
{
	if (iTargetIcon >= 0 && iTargetIcon <= m_arrTargets.Length)
		return m_arrTargets[iTargetIcon].ObjectID;
	else
		return -1;
}

simulated function StateObjectReference GetSelectedEnemyStateObjectRef()
{
	local StateObjectReference EmptyRef;
	if (CurrentTargetIndex >= 0 && CurrentTargetIndex <= m_arrTargets.Length)
		return m_arrTargets[CurrentTargetIndex];
	else
		return EmptyRef;
}

simulated function Actor GetSelectedEnemy()
{
	if (CurrentTargetIndex >= 0 && CurrentTargetIndex <= m_arrTargets.Length)
		return XGUnit(`XCOMHISTORY.GetVisualizer(m_arrTargets[CurrentTargetIndex].ObjectID));
	return none;
}

simulated function int GetCurrentTargetIndex()
{
	return CurrentTargetIndex;
}

//Used to display proper NavHelp and Input Handling when the Enemy Info button is pressed
simulated function bool TargetEnemyHasEffectsToDisplay()
{
	local XComGameState_Unit kGameStateUnit;
	local XGUnit kActiveUnit;
	local array<UISummary_UnitEffect> Bonuses, Penalties;
		
	kActiveUnit = XGUnit(GetEnemyAtIcon(CurrentTargetIndex));
	if(kActiveUnit != None)
	{
		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
		Bonuses = kGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Bonus);
		Penalties = kGameStateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Penalty);
	}

	return Bonuses.Length > 0 || Penalties.Length > 0;
}
// ------------------------------------------------------------------------------------------
//Refactored so you can set total number of enemies after setting the icon types first. 
simulated function SetVisibleEnemies( int iVisibleAliens)
{
	if(iVisibleAliens != m_iVisibleEnemies)
	{
		m_iVisibleEnemies = iVisibleAliens;
		MC.FunctionNum("SetVisibleEnemies", iVisibleAliens);
		
		if(iVisibleAliens > 0)
			Show();
		else
			Hide();

	}
}
simulated function SetFocusedEnemy( int TargetIndex, float fHitChance )
{
	MC.BeginFunctionOp("SetFocusedEnemy");
	MC.QueueNumber(TargetIndex);
	MC.QueueNumber(fHitChance);
	MC.EndOp();
}
simulated function SetBGColor( int TargetIndex, EUIState bgColorState )
{
	MC.BeginFunctionOp("SetBGColor");
	MC.QueueNumber(TargetIndex);
	MC.QueueString( class'UIUtilities_Colors'.static.GetHexColorFromState(bgColorState) );
	MC.EndOp();
}
simulated function SetDisabled( int TargetIndex, bool bIsDisabled )
{
	MC.BeginFunctionOp("SetDisabled");
	MC.QueueNumber(TargetIndex);
	MC.QueueBoolean(bIsDisabled);
	MC.EndOp();
}

simulated function SetIcon( int TargetIndex, string path )
{
	MC.BeginFunctionOp("SetIcon");
	MC.QueueNumber(TargetIndex);
	MC.QueueString("img:///" $ path);
	MC.EndOp();
}
simulated function SetTargettedEnemy( int TargetIndex, optional bool bForceUpdate )
{
	if(TargetIndex != CurrentTargetIndex || bForceUpdate)
	{
		CurrentTargetIndex = TargetIndex;
		MC.FunctionNum("SetTargettedEnemy", TargetIndex);
	}
}
// Must be set after the enemy number is set. 
simulated function SetFlanked( int TargetIndex, bool isFlanked )
{
	MC.BeginFunctionOp("SetFlanked");
	MC.QueueNumber(TargetIndex);
	MC.QueueBoolean(isFlanked);
	MC.EndOp();
}
// Must be set after the enemy number is set. 
simulated function SetSquadSight( int TargetIndex, bool bShow )
{
	MC.BeginFunctionOp("SetSquadSight");
	MC.QueueNumber(TargetIndex);
	if( bShow ) 
		MC.QueueString("img:///" $ class'UIUtilities_Image'.const.TargetIcon_Squadsight);
	else
		MC.QueueString("");
	MC.EndOp();
}
// Must be set after the enemy number is set. 
simulated function SetAlertState( int TargetIndex, int iLevel )
{
	MC.BeginFunctionOp("SetAlertState");
	MC.QueueNumber(TargetIndex);
	MC.QueueNumber(iLevel);
	MC.EndOp();
}
simulated function SetBonusAndPenalty( int TargetIndex, bool showBonus, bool showFlanked)
{
	MC.BeginFunctionOp("SetBonusAndPenalty");
	MC.QueueNumber(TargetIndex);
	MC.QueueBoolean(showBonus);
	MC.QueueBoolean(showFlanked);
	MC.EndOp();
}
//MUST call after SetIcon() so that flash already knows what path of an image ot load in for the shine animation. 
simulated function SetShine(int TargetIndex, bool showShine, optional bool bMoveAbovePercent = false)
{

	MC.BeginFunctionOp("SetShine");
	MC.QueueNumber(TargetIndex);
	MC.QueueBoolean(showShine);
	MC.EndOp();
}

function SetLabel(string DisplayText)
{
	MC.FunctionString("SetLabel", DisplayText);
}

simulated function InitNavHelp()
{
	local String NavHelpIdL, NavHelpIdR;

	NavHelpIdL = "navHelpL";
	NavHelpIdR = "navHelpR";

	//The bumper NavHelp positioning is reliant on the amount of visible enemy icons, which is handled completely in Actionscript,
	//However, for ease of keybinding or size iteration, the icons are spawned here in Unrealscript
	//bsg-jneal (3.17.17): no need for icon prefixes for these gamepad icons
	Spawn(class'UIGamepadIcons', Self, name(NavHelpIdL)).InitGamepadIcon(name(NavHelpIdL), class'UIUtilities_Input'.const.ICON_LB_L1).SetSize(38, 26);
	Spawn(class'UIGamepadIcons', Self, name(NavHelpIdR)).InitGamepadIcon(name(NavHelpIdR), class'UIUtilities_Input'.const.ICON_RB_R1).SetSize(38, 26);
	//bsg-jneal (3.17.17): end

	//sends the instance names to actionscript, where they will be handled every time 'SetTargettedEnemy' is called
	MC.BeginFunctionOp("SetNavHelpPanels");
	MC.QueueString(NavHelpIdL);
	MC.QueueString(NavHelpIdR);
	MC.EndOp();
}
// ------------------------------------------------------------------------------------------

simulated function InitializeTooltipData()
{
	local UITooltip tooltip; 
	local int i; 

	for( i = 0; i < m_iMaxNumberOfEnemies; i++ )
	{
		//tooltip = new(Movie.Pres.m_kTooltipMgr) class'UITooltip'; 
		tooltip = Spawn(class'UITooltip', Movie.Pres.m_kTooltipMgr); 
		tooltip.Init();
		tooltip.SetPosition(0,0); 
		tooltip.tDelay        = 0.1; // Make this snappy
		tooltip.targetPath    = string(MCPath) $".icon" $ i $".iconHead.theIcon.theIcon"; //specific Flash MC 

		tooltip.bRelativeLocation = true;
		tooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_RIGHT);
		tooltip.bFollowMouse  = false;

		tooltip.del_OnMouseIn = UpdateTooltipText;

		tooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( tooltip );
	}
}
simulated function UpdateTooltipText( UIToolTip tooltip )
{
	local int                   TargetIndex;
	local int                   HitChance, iCriticalChance; 	
	local XGUnit                kUnit;
	local XGUnit                kTargetUnit;
	local array<string>         path; 	
	local string                strDisplay;
	local bool                  bShowCrit; 

	if( UITextTooltip(tooltip) == none ) return; 

	path = SplitString( tooltip.targetPath, "." );
	TargetIndex = int(Split( path[5], "icon", true));
	m_kTargetActor = `XCOMHISTORY.GetVisualizer(m_arrTargets[TargetIndex].ObjectID);
	kUnit = XComTacticalController(PC).GetActiveUnit();

	kTargetUnit = XGUnit(m_kTargetActor);
	if(kTargetUnit == none) return;

	HitChance =  XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kUnit.ObjectID)).GetUISummary_StandardShotHitChance(kTargetUnit);
	HitChance = min(HitChance, 100);
	
	// Should we show crit info? -----------------------------------------
	bShowCrit = false; 
	iCriticalChance = 0;
	if( iCriticalChance > 0 )
	{
		bShowCrit = true;
	}

	// Start building the UI string ------------------------------------------

	UITextTooltip(tooltip).sTitle  = kTargetUnit.SafeGetCharacterName(); 

	strDisplay = "";

	strDisplay $= "<b>" $HitChance $"%" @ class'UITooltipMgr'.default.m_strSightlineContainer_HitTooltip $"</b>";

	if( bShowCrit )
	{
		strDisplay $= "<br>";
		strDisplay $= "<b>" $class'UIUtilities_Text'.static.GetColoredText( iCriticalChance $"%" @class'UITooltipMgr'.default.m_strSightlineContainer_CritTooltip, eUIState_Warning ) $"</b>";
	}

	// Fill in the data: 
	UITextTooltip(tooltip).sBody = strDisplay; 
}

simulated function string ProcessModifiers( array<string> arrLabels, array<int> arrValues, bool bIsCritType )
{
	local int i; 
	local string strLabel, strValue, strPrefix, strSuffix; 
	local EUIState eState; 
	local string strDisplayString; 

	strSuffix = "%"; 
	strDisplayString = ""; 

	if( arrLabels.Length > 0 )
	{
		strDisplayString $= "<br>";
	}

	for( i=0; i < arrLabels.length; i++)
	{
		if( arrValues[i] < 0 )
		{
			eState = eUIState_Bad;
			strPrefix = "   ";
		}
		else
		{
			if( bIsCritType ) 
				eState = eUIState_Warning; 
			else
				eState = eUIState_Normal; 
			strPrefix = "  +";
		}
		
		strLabel = class'UIUtilities_Text'.static.GetColoredText( arrLabels[i], eState );
		strValue = class'UIUtilities_Text'.static.GetColoredText( strPrefix $ string(arrValues[i]) $ strSuffix, eState );

		if( bIsCritType ) 
			strDisplayString $= strValue @ strLabel;
		else
			strDisplayString $= strValue @ strLabel;

		if( i <= arrLabels.Length - 2 ) 
			strDisplayString $= "<br>";
	}
	return strDisplayString;
}

simulated function HighlightEnemy(XGUnit UnitToHighlight)
{
	local XGUnit kActiveUnit;
	local ETeam ActiveTeam;
	local bool bSameTeam;
	m_highlightedEnemy = UnitToHighlight;
	if (m_highlightedEnemy != none)
	{
		kActiveUnit = XComTacticalController(PC).GetActiveUnit();
		if( kActiveUnit != none )
		{
			ActiveTeam = kActiveUnit.GetTeam();
		}
		else
		{
			ActiveTeam = eTeam_None;
		}
		m_highlightedEnemy.ShowMouseOverDisc();
		bSameTeam = m_highlightedEnemy.GetTeam() == ActiveTeam;
		m_highlightedEnemy.ShowSelectionBox(true, !bSameTeam);
	}
}

simulated function ClearHighlightedEnemy()
{
	local XGUnit kActiveUnit;
	local ETeam ActiveTeam;
	local bool bSameTeam;
	if (m_highlightedEnemy != none)
	{
		kActiveUnit = XComTacticalController(PC).GetActiveUnit();
		if( kActiveUnit != none )
		{
			ActiveTeam = kActiveUnit.GetTeam();
		}
		else
		{
			ActiveTeam = eTeam_None;
		}
		m_highlightedEnemy.ShowMouseOverDisc(false);
		bSameTeam = m_highlightedEnemy.GetTeam() == ActiveTeam;
		m_highlightedEnemy.ShowSelectionBox(false, !bSameTeam);
		m_highlightedEnemy = none;
	}
}

// ------------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------------

defaultproperties
{
	MCName = "EnemyTargetsMC";
	LibID = "EnemyTargets";

	m_iMaxNumberOfEnemies = 20;
	m_strBonusMC = "bonusMC"
	m_strPenaltyMC = "penaltyMC";
	m_strIconMC = "iconHead";

	CurrentTargetIndex = -1;
	m_iCurrentHover = -1;

	bAnimateOnInit = false;
	IconWidth = 20; 
	IconHeight = 20; 
	LargeIconWidth = 40; 
	LargeIconHeight = 40;
}

