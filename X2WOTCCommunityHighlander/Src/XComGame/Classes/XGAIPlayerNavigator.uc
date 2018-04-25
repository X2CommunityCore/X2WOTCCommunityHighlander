//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGAIPlayerNavigator.uc    
//  AUTHOR:  Alex Cheng  --  10/28/2013
//  PURPOSE: AI movement-related code. (Initially set up to handle any patrolling behavior)
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XGAIPlayerNavigator extends Actor;

var TwoVectors m_kAxisOfPlay;
var XGAIPlayer m_kPlayer;

var array<XGAIPatrolGroup> m_arrPatrolGroups;
//------------------------------------------------------------------------------------------------
var XComGameState_AIPlayerData m_kGameState;

var array<int> m_arrReinforcements; 

var AkEvent FirstReinforcementsInbound, ReinforcementsIn1Turn;
var bool m_bPlayedReinforcementsAudio;

const CoverSearchRadius=320; // Look for any cover within 5 tiles of the retreat location for cover-taking units.

//------------------------------------------------------------------------------------------------
function Init( XGAIPlayer kPlayer)
{
	m_kPlayer = kPlayer;
}
//------------------------------------------------------------------------------------------------
function RefreshAxisOfPlay()
{
	local XComGameState_BattleData BattleData;
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	m_kAxisOfPlay.v1 = BattleData.MapData.SoldierSpawnLocation;
	m_kAxisOfPlay.v2 = BattleData.MapData.ObjectiveLocation;
}
//------------------------------------------------------------------------------------------------
// This 'CurrentLineOfPlay' uses the soldier's actual location (cheat) to limit or increase
//  the number of enemies a player will face at any time.
function UpdateCurrentLineOfPlay(out TwoVectors CurrLineOfPlay)
{
	local vector XComLocation, ObjectiveLoc;
	local float  Radius;
	RefreshAxisOfPlay();
	m_kPlayer.GetSquadLocation(XComLocation, Radius);
	CurrLineOfPlay.v1 = XComLocation;
	if( `TACTICALMISSIONMGR.GetLineOfPlayEndpoint(ObjectiveLoc) )
	{
		CurrLineOfPlay.v2 = ObjectiveLoc;
	}
}

// Return false if any xcom units will be crossed in order to path to the target location.
function bool IsAwayFromXCom(vector GroupLocation, vector FromLocation, float MinTileDist=3.0f)
{
	// If any xcom unit is closer to the group location than us, return failure.
	// Use dot product between vector from xcom to us and xcom to group.  If negative, fail.
	local vector XComPosition, XComToGroup, XComToUnit;
	local float MinDistSq, XComDistSq;
	local array<XComGameState_Unit> XComUnits;
	local XComGameState_Unit XComUnit;
	local XGPlayer XComPlayer;
	local XComWorldData WorldData;
	WorldData = `XWORLD;
	XComPlayer = XGBattle_SP(`BATTLE).GetHumanPlayer();
	XComPlayer.GetPlayableUnits(XComUnits, true);
	MinDistSq = Square(`TILESTOUNITS(MinTileDist));
	foreach XComUnits(XComUnit)
	{
		XComPosition = WorldData.GetPositionFromTileCoordinates(XComUnit.TileLocation);
		XComToUnit = FromLocation - XComPosition;
		XComDistSq = VSizeSq(XComToUnit);
		if( XComDistSq > MinDistSq ) // Ignore units within a 3-tile radius to run past.
		{
			XComToGroup = GroupLocation - XComPosition;
			if( XComToGroup dot XComToUnit < 0 )
			{
				`LogAI("IsAwayFromXCom: Unit Fallback to group at ("$GroupLocation.X@GroupLocation.Y@GroupLocation.Z
					$")failed due to unit "$XComUnit.ObjectID@"between unit and group.");
				return false;
			}
		}
	}
	return true;
}

function bool GetNearestUnrevealedGroup(out StateObjectReference TargetGroupRef, vector SearchFromLocation, ETeam TargetTeam)
{
	local XComGameStateHistory History;
	local XComGameState_AIGroup AIGroupState;
	local float ClosestDistSq, DistSq;
	local vector CurrLocation;

	History = `XCOMHISTORY;
	ClosestDistSq = -1;
	foreach History.IterateByClassType(class'XComGameState_AIGroup', AIGroupState)
	{
		// Requirements - Group must have more than one unit and not processed scamper.  Must also be on the same team.
		if( !AIGroupState.bProcessedScamper && AIGroupState.m_arrMembers.Length > 1 && AIGroupState.TeamName == TargetTeam)
		{
			CurrLocation = AIGroupState.GetGroupMidpoint();
			// Don't consider this group if it would make the unit run closer to the enemy.
			if( IsAwayFromXCom(CurrLocation, SearchFromLocation) )
			{
				// Take the closest of any groups that pass all these restrictions.
				DistSq = VSizeSq(SearchFromLocation - CurrLocation);
				if( ClosestDistSq < 0 || DistSq < ClosestDistSq )
				{
					ClosestDistSq = DistSq;
					TargetGroupRef = AIGroupState.GetReference();
				}
			}
		}
	}
	if( ClosestDistSq > 0 )
	{
		return true;
	}

	return false;
}
//------------------------------------------------------------------------------------------------
function bool HasRetreatLocation(XGUnit RetreatUnit, optional out StateObjectReference RetreatGroupRef)
{
	local vector UnitLocation;
	UnitLocation = RetreatUnit.GetGameStateLocation(false);
	// If we have no current objective location, look for a nearby guard in the fow.
	return GetNearestUnrevealedGroup(RetreatGroupRef, UnitLocation, RetreatUnit.GetTeam());
}

//------------------------------------------------------------------------------------------------
function XComParcel GetClosestParcel( vector vLocation )
{
	local XComParcel kParcel, kClosest;
	local float fDist, fClosest;
	foreach WorldInfo.AllActors(class'XComParcel', kParcel)
	{
		fDist = VSizeSq(vLocation - kParcel.Location);
		if (kClosest == None || fDist < fClosest)
		{
			kClosest = kParcel;
			fClosest = fDist;
		}
	}
	return kClosest;
}
//------------------------------------------------------------------------------------------------
function XComPlotCoverParcel GetClosestPCP( vector vLocation )
{
	local XComPlotCoverParcel kPCP, kClosest;
	local float fDist, fClosest;
	foreach WorldInfo.AllActors(class'XComPlotCoverParcel', kPCP)
	{
		fDist = VSizeSq(vLocation - kPCP.Location);
		if (kClosest == None || fDist < fClosest)
		{
			kClosest = kPCP;
			fClosest = fDist;
		}
	}
	return kClosest;
}

//------------------------------------------------------------------------------------------------
function RefreshGameState()
{
	local XComGameState_AIPlayerData kAIState;
	local XComGameStateHistory History;
	if (m_kPlayer == None)
		m_kPlayer = XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());

	History = `XCOMHISTORY;
	//Get the existing AIPlayerData - should always be present
	foreach History.IterateByClassType(class'XComGameState_AIPlayerData', kAIState, eReturnType_Copy)
	{
		//if (kAIState.m_iPlayerObjectID == m_kPlayer.ObjectID)
		if(kAIState.m_iPlayerObjectID > 0) //issue #226 - have it grab the first existing AIPlayerData it finds, since that's the only AIPlayerData it can find
		{
			m_kPlayer.m_iDataID = kAIState.ObjectID;
			m_kGameState = kAIState;
			break;
		}
	}

	// Ensure we have the latest version of this data.
	RefreshAxisOfPlay();
	m_arrPatrolGroups.Length = 0;
	RefreshGroups();
}
//------------------------------------------------------------------------------------------------
function AddPatrolGroup( const out array<int> arrObjIDs, float InfluenceRange=0, bool bRefresh=false)
{
	local XGAIPatrolGroup kGroup;
	kGroup = Spawn( class'XGAIPatrolGroup' );
	kGroup.Init(arrObjIDs, InfluenceRange, bRefresh);
	if (m_arrPatrolGroups.Find(kGroup) == -1)
	{
		m_arrPatrolGroups.AddItem(kGroup);
	}
}

//------------------------------------------------------------------------------------------------
function bool HasPatrolGroup(const out array<int> arrObjIDs, out int iGroupIndex)
{
	local int ObjectID;
	ObjectID = arrObjIDs[0];
	if (ObjectID > 0)
	{
		for (iGroupIndex = 0; iGroupIndex < m_arrPatrolGroups.Length; ++iGroupIndex)
		{
			if (m_arrPatrolGroups[iGroupIndex].m_arrUnitIDs.Find(ObjectID) != -1)
			{
				return true;
			}
		}
	}
	return false;
}

//------------------------------------------------------------------------------------------------
function UpdatePatrolGroup( const out array<int> arrObjIDs, float InfluenceRange, bool AddCheckOnly=false, bool bRefresh=false)
{
	local int iGroup;
	if (HasPatrolGroup(arrObjIDs, iGroup))
	{
		if (!AddCheckOnly)
		{
			m_arrPatrolGroups[iGroup].Init(arrObjIDs, InfluenceRange);
		}
		return;
	}
	else
	{
		// Patrol Group not found?
		AddPatrolGroup(arrObjIDs, InfluenceRange, bRefresh);
	}
}

function TransferUnitToGroup(int NewGroupUnitID, int UnitToTransferID)
{
	local XGAIGroup Group;
	// Remove from old group.
	if( GetGroupInfo(UnitToTransferID, Group) )
	{
		Group.m_arrUnitIDs.RemoveItem(UnitToTransferID);
		Group.RefreshMembers();
	}
	else
	{
		`LogAI("Nav::TransferUnitToGroup: Could not find old group for unit to transfer.");
	}
	if( GetGroupInfo(NewGroupUnitID, Group) )
	{
		Group.m_arrUnitIDs.AddItem(UnitToTransferID);
		Group.RefreshMembers();
	}
	else
	{
		`LogAI("Nav::TransferUnitToGroup: Could not find old group for unit to transfer." );
	}
}

function RefreshGroups()
{
	local XComGameStateHistory History;
	local XComGameState_AIGroup kGroup;
	local array<int> arrObjIDs;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_AIGroup', kGroup)
	{
		arrObjIDs.Length = 0;
		if (kGroup.GetLivingMembers(arrObjIDs))
		{
			UpdatePatrolGroup(arrObjIDs, kGroup.InfluenceRange, true, true);
		}
	}

}
//------------------------------------------------------------------------------------------------
function RemoveFromGroup( XGAIGroup kOldGroup, int ObjectID )
{
	local int iGroup, iIndex;
	if (kOldGroup.IsA('XGAIPatrolGroup'))
	{
		for (iGroup=0; iGroup<m_arrPatrolGroups.Length; ++iGroup)
		{
			if (m_arrPatrolGroups[iGroup] == kOldGroup)
			{
				iIndex = m_arrPatrolGroups[iGroup].m_arrUnitIDs.Find(ObjectID);
				if (iIndex != -1)
				{
					m_arrPatrolGroups[iGroup].m_arrUnitIDs.Remove(iIndex, 1);
					m_arrPatrolGroups[iGroup].m_arrMember.Remove(iIndex, 1);
					if (m_arrPatrolGroups[iGroup].m_arrUnitIDs.Length == 0)
						m_arrPatrolGroups.Remove(iGroup, 1);
					break;
				}
				else
				{
					`Warn("AIPlayerNav::RemoveFromGroup failure! Failed to find ObjectID in old group to remove!");
				}
			}
		}
	}
}
//------------------------------------------------------------------------------------------------
function InitTurn()
{
	local XGAIPatrolGroup kGroup;
	RefreshGameState();
	foreach m_arrPatrolGroups(kGroup)
	{
		kGroup.InitTurn();
	}
}
//------------------------------------------------------------------------------------------------
function OnEndTurn()
{
	local XGAIPatrolGroup kGroup;
	foreach m_arrPatrolGroups(kGroup)
	{
		kGroup.OnEndTurn();
	}
}
//------------------------------------------------------------------------------------------------
function DebugDraw()
{
	if (`CHEATMGR.bShowPatrolPaths)
	{
		DebugDrawAxisOfPlay();
	}
}
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
function DebugDrawAxisOfPlay( bool bPersistent=false)
{
	local LinearColor kDebugColor;
	if (`CHEATMGR != None)
	{
		kDebugColor = MakeLinearColor(0,1,0,1);
		DrawDebugLine(m_kAxisOfPlay.v1, m_kAxisOfPlay.v2, kDebugColor.R*255, kDebugColor.G*255, kDebugColor.B*255, bPersistent);
	}
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
function vector GetNearestPointOnAxisOfPlay( vector vLoc, bool bValidate=false )
{
	local vector ClosestPoint;
	ClosestPoint = GetClosestPointAlongLineToTestPoint(m_kAxisOfPlay.v1, m_kAxisOfPlay.v2, vLoc);
	if( bValidate )
	{
		ClosestPoint = XComTacticalGRI(WorldInfo.GRI).GetClosestValidLocation(ClosestPoint, None);
	}
	return ClosestPoint;
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// Helper function.  
static function vector GetClosestPointAlongLineToTestPoint( vector vLinePointA, vector vLinePointB, vector vTestPoint )
{
	local Vector vProjection, vLineAtoB, vLineAtoTestPoint, vLineBtoA, vNewPoint;
	vLineAtoB = Normal(vLinePointB - vLinePointA);
	vLineBtoA = vLinePointA - vLinePointB;
	vLineAtoTestPoint = vTestPoint - vLinePointA;
	vProjection = ProjectOnTo(vLineAtoTestPoint, vLineAtoB);

	// Check if behind A.
	if (vLineAtoB Dot vProjection < 0)
		return vLinePointA;

	// Save out new point.
	vNewPoint = vProjection + vLinePointA;

	// Check if behind B.
	vProjection = vNewPoint - vLinePointB;
	if (vLineBtoA Dot vProjection < 0)
		return vLinePointB;

	// Inner point.
	return vNewPoint;
}
//------------------------------------------------------------------------------------------------

function bool GetGroupInfo( int iObjectID, out XGAIGroup kGroup )
{
	local XGAIPatrolGroup kPatrol;
	if (m_kGameState == None)
		RefreshGameState();

	if (IsPatrol(iObjectID, kPatrol))
	{
		kGroup = kPatrol;
		return true;
	}
	return false;
}

//------------------------------------------------------------------------------------------------
function bool IsPatrol(int ObjectID, optional out XGAIPatrolGroup kPatrol)
{
	foreach m_arrPatrolGroups(kPatrol)
	{
		if (kPatrol.m_arrUnitIDs.Find(ObjectID) != -1)
		{
			return true;
		}
	}
	kPatrol = None;
	return false;
}

//------------------------------------------------------------------------------------------------
function int GetNumPatrolGroups()
{
	return m_arrPatrolGroups.Length;
}
//------------------------------------------------------------------------------------------------
defaultproperties
{
	FirstReinforcementsInbound=AkEvent'SoundSpeechCentralTactical.FirstReinforcementsInbound'
	ReinforcementsIn1Turn=AkEvent'SoundSpeechCentralTactical.ReinforcementsIn1Turn'
}
