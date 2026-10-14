//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGAIPlayer_Civilian.uc    
//  AUTHOR:  Alex Cheng  --  2/25/2009
//  PURPOSE: For spawning and controlling Animal behaviors
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XGAIPlayer_Civilian extends XGAIPlayer
	native(AI)
	dependson(XGGameData)
	config(Animation);

var array<XGUnit> MovingUnitList;

var(Terror) array<XGUnit> m_arrCivilian;

var localized string m_strCivilianSaved;

var config float PodIdleTalkDistanceInUnits;

// Cache all ladder tiles, so we can avoid these during civilian movement.
var array<TTile> LadderTiles;
var bool bLadderTilesInitialized;

// Set max distance from pods to spawn civilians at 15 meters.
const MAX_SPAWN_DIST_FROM_PODS=960;

//`if(`isdefined(FINAL_RELEASE))
	`define	DebugTickMacro
//`else
	`define	DebugTickMacro DebugTick();	// Function defined in our parent class
//`endif

function UpdatePodIdles()
{
	local XGUnit CurrentUnit;
	local XGUnit TestUnit;
	local int ScanUnit;
	local int InnerScan;
	local Vector TurnVector;
	local Array<bool> CivilianUsed;
	local Array<XComGameState_Unit> Civilians;
	local vector TraceStart;
	local vector TraceEnd;
	local Actor HitActor;

	GetUnits(Civilians);

	m_arrCivilian.Length = 0;
	for( ScanUnit = 0; ScanUnit < Civilians.Length; ++ScanUnit )
	{
		m_arrCivilian.AddItem(XGUnit(Civilians[ScanUnit].GetVisualizer()));
	}

	CivilianUsed.Add(m_arrCivilian.Length);

	for( ScanUnit = 0; ScanUnit < m_arrCivilian.Length; ++ScanUnit )
	{
		if( CivilianUsed[ScanUnit] == true )
		{
			continue;
		}

		CurrentUnit = m_arrCivilian[ScanUnit];

		for( InnerScan = ScanUnit + 1; InnerScan < m_arrCivilian.Length; ++InnerScan )
		{
			if( CivilianUsed[InnerScan] == true )
			{
				continue;
			}

			TestUnit = m_arrCivilian[InnerScan];

			if( VSize2D(TestUnit.GetLocation() - CurrentUnit.GetLocation()) < PodIdleTalkDistanceInUnits )
			{
				TraceStart = CurrentUnit.GetPawn().GetHeadshotLocation();
				TraceEnd = TestUnit.GetPawn().GetHeadshotLocation();
				if( `XWORLD.WorldTrace(TraceStart, TraceEnd, TraceEnd, TraceEnd, HitActor) == FALSE )
				{
					CivilianUsed[InnerScan] = true;

					// We found 2 guys close together, make them talk to each other.
					// If Current unit is close to 2 guys he faces the second in the list
					CurrentUnit.IdleStateMachine.SetPodTalker(CurrentUnit);
					TestUnit.IdleStateMachine.SetPodTalker(CurrentUnit);

					TurnVector = TestUnit.GetLocation() - CurrentUnit.GetLocation();
					TurnVector.Z = 0;
					TurnVector = Normal(TurnVector);
					CurrentUnit.GetPawn().SetRotation(Rotator(TurnVector));

					TurnVector = CurrentUnit.GetLocation() - TestUnit.GetLocation();
					TurnVector.Z = 0;
					TurnVector = Normal(TurnVector);
					TestUnit.GetPawn().SetRotation(Rotator(TurnVector));
				}
			}
		}
	}
}

//------------------------------------------------------------------------------------------------
function OnUnitSeen(XGUnit MyUnit, XGUnit EnemyUnit)
{
	local array<XGUnitNativeBase> EnemiesInSquadSight;
	MyUnit.DetermineEnemiesInSquadSight(EnemiesInSquadSight, MyUnit.Location, false, false);

	// Don't call super, the purpose of this implementation is to eliminate the call to play combat music
}

//------------------------------------------------------------------------------------------------
function OnUnitEndTurn(XGUnit Unit)
{	
	local XComGameState VisualizationFence;
	MovingUnitList.RemoveItem(Unit);
	if( MovingUnitList.Length == 0 )
	{
		// Insert vis fence.
		VisualizationFence = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Visualization Fence", true, 40.0f);
		`TACTICALRULES.SubmitGameState(VisualizationFence);
	}
}

//------------------------------------------------------------------------------------------------
simulated function DrawDebugLabel(Canvas kCanvas)
{
}

function InvalidateUnitToMove(int iID)
{
}

//------------------------------------------------------------------------------------------------
simulated function InitTurn()
{
	UpdateCachedSquad();
}

function Init(bool bLoading = false)
{
	super.Init(bLoading);
	InitLadderTiles( true );
}

function InitLadderTiles( bool bForceReset = false )
{
	local XComWorldData WorldData;
	if( !bLadderTilesInitialized || bForceReset )
	{
		WorldData = `XWORLD;
		LadderTiles.Length = 0;
		WorldData.CollectLadderLandingTiles(LadderTiles);
		bLadderTilesInitialized = true;
	}
}

native function bool IsInLadderArea(vector vLocation);

function AddToMoveList(XGUnit UnitToMove)
{
	MovingUnitList.AddItem(UnitToMove);
}

//------------------------------------------------------------------------------------------------
simulated function GatherUnitsToMove()
{
	return;
}


//------------------------------------------------------------------------------------------------
function RestartYellCooldown()
{
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData kAIPlayerData;

	if (m_iDataID <= 0)
		RefreshDataID();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Restart Civilian Yell Cooldown");
	kAIPlayerData = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', m_iDataID));
	kAIPlayerData.m_iCivilianYellCooldown = kAIPlayerData.GetYellCooldownDuration();

	`TACTICALRULES.SubmitGameState(NewGameState);
}

function int GetYellCooldown()
{
	local XComGameState_AIPlayerData kAIPlayerData;
	if (m_iDataID <= 0)
		RefreshDataID();
	kAIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(m_iDataID));
	return kAIPlayerData.m_iCivilianYellCooldown;
}

//This method is responsible for letting the movement ability submission code know whether the move should be 
//visualized simultaneously with another move or not. If a value of -1 is assigned to OutVisualizeIndex then the 
//unit will not move simultaneously. bInsertFenceAfterMove returns as 1 if a fence needs to be inserted after this
//move completes ( used for patrol / group moves )
function GetSimultaneousMoveVisualizeIndex(XComGameState_Unit UnitState, XGUnit UnitVisualizer,
										   out int OutVisualizeIndex, out int bInsertFenceAfterMove)
{
	OutVisualizeIndex = `TACTICALRULES.LastNeutralReactionEventChainIndex;
}

defaultproperties
{
	m_eTeam = eTeam_Neutral
}
