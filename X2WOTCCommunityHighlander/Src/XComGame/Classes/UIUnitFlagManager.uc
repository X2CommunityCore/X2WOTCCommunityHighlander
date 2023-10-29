//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIAllUnitFlags.uc
//  AUTHOR:  Tronster
//  PURPOSE: Maintains the collection of unit flags on units (enemies and soldiers).
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class UIUnitFlagManager extends UIScreen implements(X2VisualizationMgrObserverInterfaceNative) native(UI);

var array<UIUnitFlag>       m_arrFlags;
var array<UISimpleFlag>     m_arrSimpleFlags;
var Bool                    DebugHardHide;
var Bool                    m_bFlagsInitiallyLoaded;
var XGUnit                  m_lastActiveUnit;

//Tracks the latest history index passed down to the unit flags. Prevents out of order calls to OnVisualizationBlockComplete from causing the system
//to show information that is not up to date. Generally this will only ever increase, but could be reset during replay if going backwards.
var int						LatestHistoryIndex; 

var bool					m_addFlagsOnInit;

var public bool m_bHideFriendlies;  //tracks if we are currently hiding friendly flags.
var public bool m_bHideEnemies;     //tracks if we are currently hiding friendly flags.

// Flash is initialize and ready for commands.
simulated function OnInit()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnInit();

	if( m_addFlagsOnInit )
	{
		// Add the flags now if the visualizers were created before the flag manager was initialized.
		AddFlags();
	}

	//Register ourselves with the visualization mgr - this allows the UI to synchronize/verify itself with with the game state. Normally, the unit flags
	//are updated as part of the X2Actions that visualize the game state change. 'OnVisualizationBlockComplete' allows this manager to double check 
	//that the UI is in the correct state, and make corrections if necessary
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	//When loading a save, the flags initialize with data from the latest history index.
	//Some of the visualization sync actions may trigger updates from older indexes, though. Prevent them from leaving out-of-date flags.
	//(Motivating case: destructible objects triggering a flag update when created, but not explicitly when damaged later.)
	LatestHistoryIndex = `XCOMVISUALIZATIONMGR.LastStateHistoryVisualized;

	//force an update of buffs and debuffs, fixes an issue where they would not display after loading a saved game
	ForceUpdateBuffs();

	EventManager = `XEVENTMGR;
		ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnVisualizationBlockCompleted);
}

simulated function AddFlags()
{
	local XComGameState_Unit UnitState;
	local XComGameState_Destructible DestructibleState;

	if( bIsInited )
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
		{

			if( UnitState.GetMyTemplate().bDisplayUIUnitFlag )
			{
				AddFlag(UnitState.GetReference());
			}
		}

		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Destructible', DestructibleState, eReturnType_Reference)
		{
			if( DestructibleState.IsTargetable() )
			{
				AddFlag(DestructibleState.GetReference());
				//AddSimpleFlag(DestructibleState.GetReference());
			}
		}

		m_addFlagsOnInit = false;
	}
	else
	{
		m_addFlagsOnInit = true;
	}
}

function CheckForMissingFlags(XComGameState AssociatedGameState)
{
	local XComGameState_Unit GSUnit;
	local XComGameState_Unit GSUnitPrevious;
	local XComGameState_Destructible GSDestructible;
	local UIUnitFlag kFlag;
	//local UISimpleFlag kSimpleFlag;

	foreach AssociatedGameState.IterateByClassType(class'XComGameState_Unit', GSUnit)
	{
		if( GSUnit.GetCurrentStat(eStat_HP) > 0 && !GSUnit.GetMyTemplate().bIsCosmetic && !GSUnit.IsCivilian() && !GSUnit.bRemovedFromPlay )
		{
			kFlag = GetFlagForObjectID(GSUnit.ObjectID);
			//kSimpleFlag = GetSimpleFlagForObjectID(GSUnit.ObjectID);
			if( kFlag == none )
			{
				AddFlag(GSUnit.GetReference());
			}
			else
			{
				// Check to see if our team switched
				GSUnitPrevious = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GSUnit.ObjectID, , AssociatedGameState.HistoryIndex - 1));
				if( GSUnitPrevious == None || GSUnitPrevious.ControllingPlayer != GSUnit.ControllingPlayer )
					`PRES.ResetUnitFlag(GSUnit.GetReference());

			}
		}
	}

	//We need to re-check destructibles, as they may have become targetable due to an enemy moving near them.
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Destructible', GSDestructible)
	{
		if( GSDestructible.IsTargetable() )
		{
			kFlag = GetFlagForObjectID(GSDestructible.ObjectID);
			//kSimpleFlag = GetSimpleFlagForObjectID(GSDestructible.ObjectID);
			if( kFlag == none )
			{
				AddFlag(GSDestructible.GetReference());
				//AddSimpleFlag(GSDestructible.GetReference());
			}
		}
	}
}

simulated function ForceRefreshAllUnitFlags()
{
	local int i;

	// if the visualization manager switched to idle, but it has not yet processed all pending game states, we need to wait for it to get caught up to date before updating the unit flags
	if( !class'XComGameStateVisualizationMgr'.static.VisualizerIdleAndUpToDateWithHistory() )
	{
		SetTimer(0.001, false, 'ForceRefreshAllUnitFlags', self);
		return;
	}

	for( i = 0; i < m_arrFlags.Length; i++ )
	{
		m_arrFlags[i].RespondToNewGameState(None, true);
	}

	for( i = 0; i < m_arrSimpleFlags.Length; i++ )
	{
		m_arrSimpleFlags[i].RespondToNewGameState(None, true);
	}
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local UIUnitFlag kFlag;
	local UISimpleFlag kSimpleFlag;

	if( LatestHistoryIndex < AssociatedGameState.HistoryIndex )
	{
		CheckForMissingFlags(AssociatedGameState);

		LatestHistoryIndex = AssociatedGameState.HistoryIndex;
		foreach m_arrFlags(kFlag)
		{
			kFlag.RespondToNewGameState(AssociatedGameState, true);
		}

		foreach m_arrSimpleFlags(kSimpleFlag)
		{
			kSimpleFlag.RespondToNewGameState(AssociatedGameState, true);
		}
	}


}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle()
{
	SetTimer(0.001, false, 'ForceRefreshAllUnitFlags', self);
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	if( LatestHistoryIndex < GameState.HistoryIndex )
	{
		RealizeBuffs(-1, GameState.HistoryIndex);
		RealizeCover(-1, GameState.HistoryIndex);
		LatestHistoryIndex = GameState.HistoryIndex;
	}

	return ELR_NoInterrupt;
}


simulated function Update()
{
	local UIUnitFlag kFlag;
	local UISimpleFlag kSimpleFlag;
	local XGUnit     kActiveUnit;
	local int        i;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	// Apparently it is possible for HUD to be not visible while the flag manager is @todo: bsteiner. Make this not suck, plz.
	if( !`PRES.Get2DMovie().bIsVisible && bIsVisible )
	{
		Hide();
	}
	else if( `PRES.Get2DMovie().bIsVisible && !bIsVisible )
	{
		Show();
	}

	// Only update if shown
	if( !bIsVisible )
		return;

	if( !m_bFlagsInitiallyLoaded )
	{
		m_bFlagsInitiallyLoaded = true;

		foreach m_arrFlags(kFlag)
		{
			if( !kFlag.bIsInited )
			{
				m_bFlagsInitiallyLoaded = false;
				break;
			}
		}
	}
	else if( m_arrFlags.Length > 0 || m_arrSimpleFlags.Length > 0 )
	{
		// Does a new active unit check need to be done?
		kActiveUnit = none;
		if( m_lastActiveUnit != XComTacticalController(PC).GetActiveUnit() )
		{
			kActiveUnit = XComTacticalController(PC).GetActiveUnit();
			m_lastActiveUnit = kActiveUnit;
		}

		History = `XCOMHISTORY;

			if( m_arrFlags.Length > 0 )
			{

				for( i = m_arrFlags.Length - 1; i >= 0; --i )
				{
					kFlag = m_arrFlags[i];

					UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kFlag.StoredObjectID));
					if( UnitState != none && UnitState.bRemovedFromPlay )
					{
						// The unit is no longer in play, so no need to display the flag anymore
						kFlag.Remove();
					}
					else
					{
						kFlag.Update(kActiveUnit);
					}
				}
			}

		if( m_arrSimpleFlags.Length > 0 )
		{
			for( i = m_arrSimpleFlags.Length - 1; i >= 0; --i )
			{
				kSimpleFlag = m_arrSimpleFlags[i];

				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kSimpleFlag.StoredObjectID));
				if( UnitState != none && UnitState.bRemovedFromPlay )
				{
					// The unit is no longer in play, so no need to display the flag anymore
					kSimpleFlag.Remove();
				}
				else
				{
					kSimpleFlag.Update(kActiveUnit);
				}
			}
		}
	}
}

simulated function ForceUpdateBuffs()
{
	RealizeBuffs(-1, -1);
}

simulated function AddFlag(StateObjectReference kObject)
{
	local UIUnitFlag kFlag;
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int i;

	// don't add duplicate units. -tsmith 
	for( i = 0; i < m_arrFlags.Length; i++ )
	{
		if( m_arrFlags[i].StoredObjectID == kObject.ObjectID )
			return;
	}

	kFlag = Spawn(class'UIUnitFlag', self);
	kFlag.InitFlag(kObject);
	m_arrFlags.AddItem(kFlag);

	myValue.Type = AS_String;
	myValue.s = string(kFlag.MCName);
	myArray.AddItem(myValue);

	myValue.Type = AS_Boolean;
	myValue.b = kFlag.m_bIsFriendly.GetValue();
	myArray.AddItem(myValue);

	Invoke("AddFlag", myArray);
}

simulated function AddSimpleFlag(StateObjectReference kObject)
{
	local UISimpleFlag kFlag;
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int i;

	// don't add duplicate units. -tsmith 
	for( i = 0; i < m_arrSimpleFlags.Length; i++ )
	{
		if( m_arrSimpleFlags[i].StoredObjectID == kObject.ObjectID )
			return;
	}

	kFlag = Spawn(class'UISimpleFlag', self);
	kFlag.InitFlag(kObject);
	m_arrSimpleFlags.AddItem(kFlag);

	myValue.Type = AS_String;
	myValue.s = string(kFlag.MCName);
	myArray.AddItem(myValue);

	myValue.Type = AS_Boolean;
	myValue.b = kFlag.m_bIsFriendly;
	myArray.AddItem(myValue);

	Invoke("AddSimpleFlag", myArray);
}

simulated function RemoveFlag(UIUnitFlag kFlag)
{
	m_arrFlags.RemoveItem(kFlag);
}

simulated function RemoveSimpleFlag(UISimpleFlag kFlag)
{
	m_arrSimpleFlags.RemoveItem(kFlag);
}

simulated function UIUnitFlag GetFlagForObjectID(int UnitID)
{
	local int i;

	for( i = 0; i < m_arrFlags.Length; i++ )
	{
		if( m_arrFlags[i].StoredObjectID == UnitID )
		{
			return m_arrFlags[i];
		}
	}
	return none;
}

simulated function UISimpleFlag GetSimpleFlagForObjectID(int UnitID)
{
	local int i;

	for( i = 0; i < m_arrSimpleFlags.Length; i++ )
	{
		if( m_arrSimpleFlags[i].StoredObjectID == UnitID )
		{
			return m_arrSimpleFlags[i];
		}
	}
	return none;
}

simulated function RespondToNewGameState(XGUnit Unit, XComGameState NewGameState, bool bForceUpdate = false)
{
	local int i;

	for( i = 0; i < m_arrFlags.Length; i++ )
	{
		if( m_arrFlags[i].StoredObjectID == Unit.ObjectID )
		{
			m_arrFlags[i].RespondToNewGameState(NewGameState, bForceUpdate);
			return;
		}
	}

	for( i = 0; i < m_arrSimpleFlags.Length; i++ )
	{
		if( m_arrSimpleFlags[i].StoredObjectID == Unit.ObjectID )
		{
			m_arrSimpleFlags[i].RespondToNewGameState(NewGameState, bForceUpdate);
			return;
		}
	}
}

simulated function SetUnitFlagScale(XGUnit kUnit, int iScale)
{
	local int i;

	for( i = 0; i < m_arrFlags.Length; i++ )
	{
		if( m_arrFlags[i].StoredObjectID == kUnit.ObjectID )
		{
			m_arrFlags[i].SetScaleOverride(iScale);
			return;
		}
	}

	for( i = 0; i < m_arrSimpleFlags.Length; i++ )
	{
		if( m_arrSimpleFlags[i].StoredObjectID == kUnit.ObjectID )
		{
			m_arrSimpleFlags[i].SetScaleOverride(iScale);
			return;
		}
	}
}

simulated function PreviewMoves(XGUnit kUnit, int iMoves)
{
	local int i;

	for( i = 0; i < m_arrFlags.Length; i++ )
	{
		if( m_arrFlags[i].StoredObjectID == kUnit.ObjectID )
		{
			m_arrFlags[i].PreviewMoves(iMoves);
			return;
		}
	}
}

//simulated function StartTurn()
//{
//	RealizeMoves(-1, -1);
//}

simulated function EndTurn()
{
	local int i;
	for( i = 0; i < m_arrFlags.Length; i++ )
		m_arrFlags[i].EndTurn();
}

simulated function Show()
{
	if( `TACTICALRULES.HasTacticalGameEnded() )
	{
		Hide();
	}
	else
	{
		super.Show();
	}
}

simulated function Hide()
{
	super.Hide();
}

simulated function ShowAllFriendlyFlags()
{
	local UIUnitFlag kFlag;
	local UISimpleFlag kSimpleFlag;

	m_bHideFriendlies = false;

	// Ignore all Show/Hide commands if (debug) hard hide is active.
	if( DebugHardHide )
		return;

	foreach m_arrFlags(kFlag)
	{
		if( kFlag.m_bIsFriendly.GetValue() )
			kFlag.Show();
	}

	foreach m_arrSimpleFlags(kSimpleFlag)
	{
		if( kSimpleFlag.m_bIsFriendly )
			kSimpleFlag.Show();
	}
}

simulated function HideAllFriendlyFlags()
{
	local UIUnitFlag kFlag;
	local UISimpleFlag kSimpleFlag;

	m_bHideFriendlies = true;

	// Ignore all Show/Hide commands if (debug) hard hide is active.
	if( DebugHardHide )
		return;

	foreach m_arrFlags(kFlag)
	{
		if( kFlag.m_bIsFriendly.GetValue() )
			kFlag.Hide();
	}

	foreach m_arrSimpleFlags(kSimpleFlag)
	{
		if( kSimpleFlag.m_bIsFriendly )
			kSimpleFlag.Hide();
	}
}

simulated function ShowAllEnemyFlags()
{
	local UIUnitFlag kFlag;
	local UISimpleFlag kSimpleFlag;

	m_bHideEnemies = false;

	// Ignore all Show/Hide commands if (debug) hard hide is active.
	if( DebugHardHide )
		return;

	foreach m_arrFlags(kFlag)
	{
		if( !kFlag.m_bIsFriendly.GetValue() )
			kFlag.Show();
	}

	foreach m_arrSimpleFlags(kSimpleFlag)
	{
		if( !kSimpleFlag.m_bIsFriendly )
			kSimpleFlag.Show();
	}

}

simulated function HideAllEnemyFlags()
{
	local UIUnitFlag kFlag;
	local UISimpleFlag kSimpleFlag;

	m_bHideEnemies = true;

	// Ignore all Show/Hide commands if (debug) hard hide is active.
	if( DebugHardHide )
		return;

	foreach m_arrFlags(kFlag)
	{
		if( !kFlag.m_bIsFriendly.GetValue() )
			kFlag.Hide();
	}

	foreach m_arrSimpleFlags(kSimpleFlag)
	{
		if( !kSimpleFlag.m_bIsFriendly )
			kSimpleFlag.Hide();
	}
}

// Updates all unit flags to show whether the moving unit can see them at the end of its move
function RealizePreviewEndOfMoveLOS(GameplayTileData MoveToTileData)
{
	local int Index;
	local UIUnitFlag kFlag;
	local UISimpleFlag kSimpleFlag;

	foreach m_arrFlags(kFlag)
	{
		//Check the SourceID, as the visibility information is from an enemy to the potential move tile ( TargetID -1 )
		Index = MoveToTileData.VisibleEnemies.Find('SourceID', kFlag.StoredObjectID);
		if( Index == INDEX_NONE )
		{
			kFlag.RealizeLOSPreview(false);
		}
		else
		{
			kFlag.RealizeLOSPreview(true);
		}
	}

	foreach m_arrSimpleFlags(kSimpleFlag)
	{
		//Check the SourceID, as the visibility information is from an enemy to the potential move tile ( TargetID -1 )
		Index = MoveToTileData.VisibleEnemies.Find('SourceID', kSimpleFlag.StoredObjectID);
		if( Index == INDEX_NONE )
		{
			kSimpleFlag.RealizeLOSPreview(false);
		}
		else
		{
			kSimpleFlag.RealizeLOSPreview(true);
		}
	}
}

simulated function DebugForceVisibility(Bool bVisible)
{
	if( bVisible )
	{
		DebugHardHide = false;
		Show();
	}
	else
	{
		Hide();
		DebugHardHide = true;
	}
}

simulated function RefreshAllHealth()
{
	RealizeHealth(-1, -1);
}

// Some units have shields, which act as extra health, but need to be handled separately.
simulated function SetAbilityDamagePreview(UIUnitFlag kFlag, XComGameState_Ability AbilityState, StateObjectReference TargetObject)
{
	local XComGameState_Unit FlagUnit;
	local int shieldPoints, AllowedShield;
	local int possibleHPDamage, possibleShieldDamage;
	local WeaponDamageValue MinDamageValue;
	local WeaponDamageValue MaxDamageValue;

	if( kFlag == none || AbilityState == none )
	{
		return;
	}

	AbilityState.GetDamagePreview(TargetObject, MinDamageValue, MaxDamageValue, AllowedShield);

	FlagUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kFlag.StoredObjectID));
	shieldPoints = FlagUnit != none ? int(FlagUnit.GetCurrentStat(eStat_ShieldHP)) : 0;

	possibleHPDamage = MaxDamageValue.Damage;
	possibleShieldDamage = 0;

	// MaxHP contains extra HP points given by shield
	if( shieldPoints > 0 && AllowedShield > 0 )
	{
		possibleShieldDamage = min(shieldPoints, MaxDamageValue.Damage);
		possibleShieldDamage = min(possibleShieldDamage, AllowedShield);
		possibleHPDamage = MaxDamageValue.Damage - possibleShieldDamage;
	}

	if( possibleHPDamage > 0 && !AbilityState.DamageIgnoresArmor() && FlagUnit != none )
		possibleHPDamage -= max(0, FlagUnit.GetArmorMitigationForUnitFlag() - MaxDamageValue.Pierce);

	kFlag.SetShieldPointsPreview(possibleShieldDamage);
	kFlag.SetHitPointsPreview(possibleHPDamage);
	kFlag.SetArmorPointsPreview(MaxDamageValue.Shred, MaxDamageValue.Pierce);
}

simulated function LockFlagToReticle(bool bShouldLock, UITargetingReticle kReticle, StateObjectReference ObjectRef)
{
	local UIUnitFlag kFlag;

	foreach m_arrFlags(kFlag)
	{
		if( kFlag.StoredObjectID == ObjectRef.ObjectID )
		{
			//Set appropriate info on the targeted flag 
			kFlag.LockToReticle(bShouldLock, kReticle);
		}
	}
}

simulated function ClearAbilityDamagePreview()
{
	local UIUnitFlag kFlag;

	// Turn all flag info off initially 
	foreach m_arrFlags(kFlag)
	{
		if( !kFlag.m_bIsFriendly.GetValue() )
		{
			kFlag.SetHitPointsPreview(0);
			kFlag.SetArmorPointsPreview(0, 0);
			//			if(kFlag.m_kUnit.GetCharacter().m_ePawnType == ePawnType_Mechtoid)
			//				kFlag.SetShieldPointsPreview(0);
		}
	}
}
simulated function RealizeTargetedStates()
{
	local UIUnitFlag kFlag;

	foreach m_arrFlags(kFlag)
	{
		kFlag.RealizeTargetedState();
	}
}

simulated function OnRemoved()
{
	XComPresentationLayer(Movie.Pres).m_kUnitFlagManager = None;
}

simulated function UIUnitFlag GetFlagForUnit(int iObjID)
{
	local UIUnitFlag kFlag;

	foreach m_arrFlags(kFlag)
	{
		if( kFlag.StoredObjectID == iObjID )
			return kFlag;
	}
	return none;
}

simulated function ActivateExtensionForTargetedUnit(StateObjectReference ObjectRef)
{
	local UIUnitFlag kFlag;

	if( ObjectRef.ObjectID > 0 )
	{
		foreach m_arrFlags(kFlag)
		{
			kFlag.ActivateExtensionForTargeting(kFlag.StoredObjectID == ObjectRef.ObjectID);
		}
	}
}

simulated function DeactivateExtensionForTargetedUnit()
{
	local UIUnitFlag kFlag;

	foreach m_arrFlags(kFlag)
	{
		kFlag.DeactivateExtensionForTargeting();
	}

	// Updating here fixes 1 frame flash of flags that are offscreen
	Update();
}

//////////////////////////////////////////////////////////////////////////////////////////
// Individual X2Action-based UI flag updates
//////////////////////////////////////////////////////////////////////////////////////////



simulated function RealizeConcealment(int SpecificUnitID, int HistoryIndex)
{
	local UIUnitFlag kFlag;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

		foreach m_arrFlags(kFlag)
	{
		if( SpecificUnitID == -1 || SpecificUnitID == kFlag.StoredObjectID )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kFlag.StoredObjectID, , HistoryIndex));
			kFlag.RealizeConcealmentState(UnitState);
		}
	}
}

simulated function RealizeBuffs(int SpecificUnitID, int HistoryIndex)
{
	local UIUnitFlag kFlag;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

		foreach m_arrFlags(kFlag)
	{
		if( SpecificUnitID == -1 || SpecificUnitID == kFlag.StoredObjectID )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kFlag.StoredObjectID, , HistoryIndex));
			kFlag.RealizeBuffs(UnitState);
			kFlag.RealizeDebuffs(UnitState);
			kFlag.RealizeEKG(UnitState);
			kFlag.RealizeClaymore(UnitState);
		}
	}
}

simulated function RealizeCover(int SpecificUnitID, int HistoryIndex)
{
	local UIUnitFlag kFlag;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

		foreach m_arrFlags(kFlag)
	{
		if( SpecificUnitID == -1 || SpecificUnitID == kFlag.StoredObjectID )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kFlag.StoredObjectID, , HistoryIndex));
			kFlag.RealizeCover(UnitState, HistoryIndex);
		}
	}
}

simulated function RealizeMoves(int SpecificUnitID, int HistoryIndex)
{
	local UIUnitFlag kFlag;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

		foreach m_arrFlags(kFlag)
	{
		if( SpecificUnitID == -1 || SpecificUnitID == kFlag.StoredObjectID )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kFlag.StoredObjectID, , HistoryIndex));
			kFlag.RealizeMoves(UnitState);
		}
	}
}

simulated function RealizeOverwatch(int SpecificUnitID, int HistoryIndex)
{
	local UIUnitFlag kFlag;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

		foreach m_arrFlags(kFlag)
	{
		if( SpecificUnitID == -1 || SpecificUnitID == kFlag.StoredObjectID )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kFlag.StoredObjectID, , HistoryIndex));
			kFlag.RealizeOverwatch(UnitState);
		}
	}
}

simulated function RealizeHealth(int SpecificUnitID, int HistoryIndex)
{
	local UIUnitFlag kFlag;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;

		foreach m_arrFlags(kFlag)
	{
		if( SpecificUnitID == -1 || SpecificUnitID == kFlag.StoredObjectID )
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kFlag.StoredObjectID, , HistoryIndex));
			kFlag.RealizeHitPoints(UnitState);
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	Package   = "/ package/gfxUnitFlag/UnitFlag";
	MCName      = "theUnitFlagManager";
	
	m_bHideFriendlies   = false;
	m_bHideEnemies      = false;

	bHideOnLoseFocus     = false;

	m_bVisible = false;
}
