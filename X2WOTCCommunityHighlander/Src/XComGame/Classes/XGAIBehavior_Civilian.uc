//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGAIBehavior_Civilian.uc    
//  AUTHOR:  Alex Cheng  --  10/7/2009
//  PURPOSE: Civilian-specific AI behavior
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XGAIBehavior_Civilian extends XGAIBehavior
	native(AI);

var config float CIVILIAN_NEAR_TERROR_REACT_RADIUS;	  // Distance in tiles for civilians to react, terror 
var config float CIVILIAN_NEAR_STANDARD_REACT_RADIUS; // Distance in tiles for civilians to react, non-terror

var int m_iMoveTimeStart;
var eTeam EnemyTeam;

//------------------------------------------------------------------------------------------------
simulated function InitTurn(bool UpdateHistoryIndexStart=true)
{
	if( UpdateHistoryIndexStart )
	{
		DecisionStartHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
		ResetErrorCheck();
	}

	RefreshUnitCache();
	UpdateSightRange();
	m_kPlayer.UpdateTerror();
	UpdateEnemyTeam();
	UpdateSpreadVars(); // Cache values related to Minimum Spread for destination search.
	m_bCanDash = false;//m_iTurnsUnseen >= MAX_TURNS_UNSEEN_BEFORE_RUSH
	m_bAbortMove = false; // Reset before rebuilding abilities.  This flag is used to see if we should attempt to move again.
}

function UpdateEnemyTeam()
{
	if( m_kPlayer.bCiviliansTargetedByAliens || !XGBattle_SP(`BATTLE).IsLowPopularSupport()) 
	{
		EnemyTeam = eTeam_Alien;
	}
	else
	{
		EnemyTeam = eTeam_XCom;
	}
}

//------------------------------------------------------------------------------------------------
function InitActivate()
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Civilian Move Init.");
	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

	NewUnitState.ActionPoints.Length = 0;
	NewUnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	`TACTICALRULES.SubmitGameState(NewGameState);
}
state Active
{
Begin:
	Sleep(0);
	InitActivate();
	InitTurn();
	m_kUnit.m_kReachableTilesCache.ForceCacheUpdate();
	GotoState('ExecutingAI');
}

state ExecutingAI
{
Begin:
	// Prevent multiple Behavior Trees from starting before this one is completed.
	// This prevents problems with multiple units attempting to move to the same tile.
	while( WaitingForBTRun() )
	{
		sleep(0.1f);
	}

	if( GetCheatOverride(m_kBTCurrAbility, m_strBTAbilitySelection) )
	{
		BTExecuteAbility();
	}
	else if (!IsBehaviorTreeAvailable() || !StartRunBehaviorTree() )
	{
		if (UnitState.IsAlive())
		{
			`LogAI("Error- Civilian behavior tree not available or could not start.");
		}

		GotoState('EndOfTurn');
	}
	else
	{
		while (m_eBTStatus == BTS_RUNNING)
		{
			Sleep(0.0f);
			if (WorldInfo.TimeSeconds > m_fBTAbortTime)
			{
				`CHEATMGR.AIStringsUpdateString(UnitState.ObjectID, "Error- Behavior tree timed-out!");
				`Warn("Error- behavior tree took too long to finish!  Aborted!");
				`Assert(false);
				break;
			}
		}
	}
	while( WaitingForBTRun() )
	{
		sleep(0.1f);
	}
	GotoState('EndOfTurn');
}
simulated event Tick( float fDeltaT )
{
	if (m_kUnit == none)
	{
		`Warn("Error- Invalid m_kUnit (== None) associated with this behavior.  Perhaps the unit fell through the world?  Check for a bad pod (underground or off the map) in: "$WorldInfo.GetMapName());
		SetTickIsDisabled(true);
		return;
	}
	DebugDrawDestination();
}

function BTRunCompletePreExecute()
{
	local AvailableAction YellAction;
	local int TargetIndex;
	super.BTRunCompletePreExecute();
	if( !m_kPlayer.bCiviliansTargetedByAliens )
	{
		// Yell before moving.
		YellAction = FindAbilityByName('Yell');
		if( YellAction.AbilityObjectRef.ObjectID > 0 && YellAction.AvailableCode == 'AA_Success' )
		{
			if( YellAction.AvailableTargets.Length == 0 )
			{
				TargetIndex = INDEX_NONE;
			}
			class'XComGameStateContext_Ability'.static.ActivateAbility(YellAction, TargetIndex);
		}
	}
}
// Civilian tile scores may differ from regular units because enemies are undefined.
function ai_tile_score FillTileScoreData( TTile kTile, vector vLoc, XComCoverPoint kCover, optional array<GameRulesCache_VisibilityInfo> arrEnemyInfos, optional out float fDist, optional bool AddSpreadToOldLocation=true)
{
	local ai_tile_score kTileData;
	local GameRulesCache_VisibilityInfo VisibilityInfo;
	local int EnemyInfoIndex;
	local array<GameRulesCache_VisibilityInfo> arrAlliesInfo;
	local int nFlanked, nMidCover, nHighCover, nVisibleEnemies, nVisibleAllies;
	local float fDistSq, fClosestSq, SpreadDistSq;
	local array<GameRulesCache_VisibilityInfo> arrAllEnemyInfos;
	local XComWorldData World;
	World = `XWORLD;

	// Pull enemy visibility/cover data.
	kTileData = InitMoveTileData(kTile, kCover);
	if (arrEnemyInfos.Length == 0)
	{
		class'X2TacticalVisibilityHelpers'.static.GetAllTeamUnitsForLocation(vLoc, m_kPlayer.ObjectID, EnemyTeam, arrEnemyInfos );

		if (arrEnemyInfos.Length > 0)
		{
			arrAllEnemyInfos = arrEnemyInfos;
			// Remove units that can't be seen.
			for( EnemyInfoIndex = arrEnemyInfos.Length - 1; EnemyInfoIndex >= 0; EnemyInfoIndex-- )
			{
				if(!arrEnemyInfos[EnemyInfoIndex].bClearLOS || arrEnemyInfos[EnemyInfoIndex].PeekToTargetDist > m_fSightRangeSq ) 
				{
					arrEnemyInfos.Remove(EnemyInfoIndex, 1);
				}
			}
		}
	}	

	class'X2TacticalVisibilityHelpers'.static.GetAllAlliesForLocation(vLoc, m_kPlayer.ObjectID, arrAlliesInfo);			
	foreach arrAlliesInfo(VisibilityInfo)
	{
		if (VisibilityInfo.SourceID != m_kUnit.ObjectID && VisibilityInfo.bClearLOS
			&& VisibilityInfo.PeekToTargetDist < m_fSightRangeSq)
		{
			nVisibleAllies++;
			if( VisibilityInfo.DefaultTargetDist < SpreadMinDistanceSq )
			{
				kTileData.bWithinSpreadMin = true;
				// Keep track of shortest spread distance.
				if( SpreadDistSq == 0 || VisibilityInfo.DefaultTargetDist < SpreadDistSq )
				{
					SpreadDistSq = VisibilityInfo.DefaultTargetDist;
				}
			}
		}
	}

	// Also update the spread value against our current location.
	if (AddSpreadToOldLocation)
	{
		fDistSq = VSizeSq(vLoc - m_vCurrLocation);
		if (fDistSq < SpreadMinDistanceSq)
		{
			kTileData.bWithinSpreadMin = true;
			// Keep track of shortest spread distance.
			if (SpreadDistSq == 0 || fDistSq < SpreadDistSq)
			{
				SpreadDistSq = fDistSq;
			}
		}
	}

	if( kTileData.bWithinSpreadMin )
	{
		UpdateSpreadValue(kTileData, SpreadDistSq);
	}

	fClosestSq = -1;
	// Determine if flanked or not in cover.  Also determine if each enemy might be flanked from here.
	foreach arrEnemyInfos(VisibilityInfo)
	{
		if (VisibilityInfo.bClearLOS 
			&& VisibilityInfo.PeekToTargetDist < m_fSightRangeSq)
		{
			nVisibleEnemies++;
		}
		else
		{
			// Don't consider flanking or cover scores on enemies that we can't see from here.
			continue;
		}

		if (VisibilityInfo.TargetCover == CT_None )
		{
			nFlanked++;
		}
		// warning - this will just take the last cover type, not necessarily the worst or best cover available here.
		else if (VisibilityInfo.TargetCover == CT_MidLevel)
		{
			nMidCover++;
		}
		else 
		{
			nHighCover++;
		}

		fDistSq = VSizeSq(World.GetPositionFromTileCoordinates(VisibilityInfo.SourceTile) - vLoc);
		if (fClosestSq == -1 || fDistSq < fClosestSq)
		{
			fClosestSq = fDistSq;
		}
	}

	// Cover score is an average cover value against all enemies, from -5 (no cover) to 1 (standing cover)
	if (nFlanked+nMidCover+nHighCover > 0)
	{
		kTileData.fCoverValue = (nFlanked*(-5.0f)+nMidCover*(0.5f)+nHighCover*(1.0f))/float(nFlanked+nMidCover+nHighCover);
	}

	// Adding cheat for civilians to always have knowledge of surrounding enemies.
	if( fClosestSq == -1 )
	{
		foreach arrAllEnemyInfos(VisibilityInfo)
		{
			fDistSq = VSizeSq(World.GetPositionFromTileCoordinates(VisibilityInfo.SourceTile) - vLoc);
			if( fClosestSq == -1 || fDistSq < fClosestSq )
			{
				fClosestSq = fDistSq;
			}
		}
	}

	//Fill out var int nTilesToEnemy; // Distance in tiles (direct length / 96) from enemy.
	if ( fClosestSq != -1 )
	{
		fDist = Sqrt(fClosestSq);
		kTileData.fDistanceScore = fDist / World.WORLD_StepSize;
	}
	else
	{
		`LogAI("FillTileScoreData could not find nearest enemy to target location!  Setting distance to 25 tiles.");
		kTileData.fDistanceScore = 25;
	}
//	kTileData.fDistanceScore = Min(25, kTileData.fDistanceScore); // Default max length.

	// Civilians don't care about flanking enemies.
	kTileData.fFlankScore = 0;

	//Fill out var float fEnemyVisibility; // 1 if enemy is visible, -1 if no enemy is visible.
	if (nVisibleEnemies > 0)
	{
		kTileData.fEnemyVisibility = 1.0f;
	}
	else
	{
		kTileData.fEnemyVisibility = -1.0f;
	}

	//Fill out var float AllyVisibility;   // 1 if ally is visible, 0 if no ally is visible.
	if (nVisibleAllies > 0)
	{
		kTileData.fAllyVisibility = 1.0f;
	}
	return kTileData;
}

simulated function ExecuteMoveAbility()
{
	if (m_bBTDestinationSet)
	{
		GotoState('CivilianMovement');
	}
	else
	{
		super.ExecuteMoveAbility();
	}
}

//------------------------------------------------------------------------------------------------
state CivilianMovement extends MoveState
{
	simulated event BeginState(Name P)
	{
		`LogAI(m_kUnit@"Beginning CivilianMovement from"@P);
		super.BeginState(P);
	}

	simulated event EndState(name N)
	{
		`LogAI(m_kUnit@"EndState CivilianMovement Move->"@N);
		m_kLastAIState = name("CivilianMovement");
		super.EndState(N);
	}
	function Vector DecideNextDestination( optional out string strFail )
	{
		`Assert(m_bBTDestinationSet);

		strFail @= "GotDestFromBTSearch.";
		return m_vBTDestination;
	}
}

simulated function DrawDebugLabel(Canvas kCanvas, out vector vScreenPos)
{
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	if( `CHEATMGR != None && `CHEATMGR.bShowCivilianLabels)
	{
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
		vScreenPos.Y += 15;
		if( m_kUnit.IsAliveAndWell() )
		{
			if( m_kUnit.GetTeam() == eTeam_Neutral || m_kUnit.GetTeam() == eTeam_Resistance )
			{
				kCanvas.SetDrawColor(210, 210, 210);
			}
			else
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_kUnit.ObjectID));

				// Draw color is now based on their alert level.
				if( UnitState.GetCurrentStat(eStat_AlertLevel) == 2 )
					kCanvas.SetDrawColor(255, 128, 128);
				else if( UnitState.GetCurrentStat(eStat_AlertLevel) == 0 )
					kCanvas.SetDrawColor(128, 255, 128);
				else
					kCanvas.SetDrawColor(255, 255, 255);
			}
		}
		else
		{
			kCanvas.SetDrawColor(200, 200, 200);
		}

		// Base text.
		kCanvas.DrawText(m_kUnit@"["$UnitState.GetMyTemplateName()$"]"@m_kUnit.ObjectID);
	}
}

simulated function OnUnitEndTurn()
{
	m_kPlayer.OnUnitEndTurn(m_kUnit);
}

simulated function bool IsInBadArea(Vector vLoc, bool bDebugLog = false, optional out string strFail)
{
	if( XGAIPlayer_Civilian(m_kPlayer).IsInLadderArea(vLoc) )
	{
		return true;
	}
	return super.IsInBadArea(vLoc, bDebugLog, strFail);
}