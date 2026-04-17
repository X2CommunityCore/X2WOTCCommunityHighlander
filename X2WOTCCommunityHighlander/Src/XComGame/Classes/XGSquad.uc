//
// Author - Jacob Solomon
// Copyright 2009 Firaxis Games
// FIRAXIS SOURCE CODE
//
class XGSquad extends XGSquadNativeBase;

var protected int           m_iBadge;
var private array<XGUnit>   m_arrSortedUnits;       //  distance sorted list for bumpering

simulated event ReplicatedEvent(name VarName)
{
`if (`notdefined(FINAL_RELEASE))
	local int i;
`endif

	if( VarName == 'm_arrUnits' )
	{
`if(`notdefined(FINAL_RELEASE))
		for( i = 0; i < m_iNumUnits; i++ )
		{
			if( m_arrUnits[i] != none )
			{
				`log(self $ "::ReplicatedEvent: m_arrUnits[" $ i $ "]=" $ m_arrUnits[i] $
					 ", name=" $ m_arrUnits[i].SafeGetCharacterFirstName() $ " " $ m_arrUnits[i].SafeGetCharacterLastName(), true, 'XCom_Squad');
			}
			else
			{
				`log(self $ "::ReplicatedEvent: m_arrUnits[" $ i $ "]=" $ m_arrUnits[i], true, 'XCom_Squad');
			}
		}
`endif
	}
	else if( VarName == 'm_iNumUnits' )
	{
`if(`notdefined(FINAL_RELEASE))
		`log(self $ "::ReplicatedEvent: m_iNumUnits=" $ m_iNumUnits, true, 'XCom_Squad');
`endif
	}
	else
	{
		super.ReplicatedEvent(VarName);
	}
}


/*
 *  Tell each of our squad units
 *  to generate new sample data
 *  NOTE: called on beginning of turn
 */
/*
function GenerateRandomSamples()
{
	local int i;
	for(i = 0; i < m_iNumUnits; i++)
	{
		m_arrUnits[i].GenerateRandomSample();
		//`log("Generated random sample for:"@m_arrUnits[i].SafeGetCharacterName() @ "#"@`BATTLE.m_iTurn);
	}
}*/

simulated function SortUnits(optional XGUnit kFirstUnit = none)
{
	local array<XGUnit> arrUnits;
	local XGUnit kCloseUnit;

	if (Role < ROLE_Authority && !IsInitialReplicationComplete())
	{
		return;
	}

	if (GetPlayer().m_eTeam != eTeam_XCom)
		return;

	if (kFirstUnit == none)
	{
		if (m_arrSortedUnits.Length != 0)
			kFirstUnit = m_arrSortedUnits[0];
		else
			kFirstUnit = m_arrUnits[0];
	}

	m_arrSortedUnits.Length = 0;
	if (kFirstUnit.GetSquad() == self)
		m_arrSortedUnits.AddItem(kFirstUnit);
	GetUnsortedUnits(arrUnits);
	while (arrUnits.Length != 0)
	{
		kCloseUnit = GetClosestUnit(kFirstUnit, arrUnits);
		if (kCloseUnit != none)
		{
			m_arrSortedUnits.AddItem(kCloseUnit);
			arrUnits.RemoveItem(kCloseUnit);
		}
		else
			break;      //  something went wrong?
	}
	`assert(m_arrSortedUnits.Length == m_iNumUnits);
}

simulated function GetUnsortedUnits(out array<XGUnit> arrUnits)
{
	local int i;

	arrUnits.Length = 0;
	for (i = 0; i < m_iNumUnits; ++i)
	{
		if (m_arrSortedUnits.Find(m_arrUnits[i]) == -1)
			arrUnits.AddItem(m_arrUnits[i]);
	}
}

simulated function XGUnit GetClosestUnit(const XGUnit kCloseToUnit, const out array<XGUnit> arrUnits)
{
	local float fDist, fClosest;
	local int i;
	local XGUnit kClosest;
	kClosest = arrUnits[0];
	for (i = 0; i < arrUnits.Length; ++i)
	{
		if (arrUnits[i].GetPawn() == None) continue;
		fDist = VSizeSq(arrUnits[i].GetPawn().Location  - kCloseToUnit.GetPawn().Location);
		if (i == 0 || fDist < fClosest)
		{
			fClosest = fDist;
			kClosest = arrUnits[i];
		}
	}

	return kClosest;
}

function AddUnit( XGUnit kUnit, optional bool bTemporary=false )
{
	local int iPermanentIndex;

	// We are adding a permanent member to this squad
	if( !bTemporary )
	{
		iPermanentIndex = GetPermanentIndex( kUnit );
		// IF( This is the first time this unit has been added to the squad )
		if( iPermanentIndex == -1 )
		{
			AddUnitToEnd( kUnit );
			AddPermanentUnit( kUnit );
		}
		// ELSE( This unit is being added back to their original squad )
		else
		{
			ReAddUnit( kUnit, iPermanentIndex );
		}
	}
	// We are adding a temporary member to this squad
	else
	{
		AddUnitToEnd( kUnit );
	}
}

function AddPermanentUnit( XGUnit kAddUnit )
{
	local XGUnit kLeaderUnit;

	m_arrPermanentMembers[m_iNumPermanentUnits++] = kAddUnit;

	if( /*kAddUnit.GetCharacterRank() > eRank_Rookie &&*/ kAddUnit.IsSoldier())
	{
		kLeaderUnit = GetSquadLeader();

		if( kLeaderUnit != none )
		{
			if( kLeaderUnit.GetCharacterRank() < kAddUnit.GetCharacterRank() )
			{
				SetSquadLeader( m_iNumPermanentUnits-1 );
			}
		}
		else
		{
			SetSquadLeader( m_iNumPermanentUnits-1 );
		}
	}
	SortUnits();
}

function AddUnitToEnd( XGUnit kAddUnit )
{
	m_arrUnits[ m_iNumUnits++ ] = kAddUnit;
	kAddUnit.SetSquad( self );	
	SortUnits();
}

function RemoveUnit(XGUnit kUnit)
{
	local int i;
	local bool bFound;

	bFound = false;
	
	for (i = 0; i < m_iNumUnits; i++)
	{
		if (m_arrUnits[i] == kUnit)
		{
			bFound = true;	
		}

		if (bFound && i < m_iNumUnits-1)
		{
			m_arrUnits[i] = m_arrUnits[i+1];
		}
		else if (bFound)
		{
			m_arrUnits[i] = none;
		}
	}

	if (bFound)
	{
		m_iNumUnits--;
		kUnit.SetSquad(none);
		SortUnits();
	}	
}

// Add an original member back to the squad at their original location
function ReAddUnit( XGUnit kAddUnit, int iPermanentIndex )
{
	local int i, iUnitPermIndex, iAddIndex;

	iAddIndex = -1;
	for (i = 0; i < m_iNumUnits; i++)
	{
		iUnitPermIndex = GetPermanentIndex( m_arrUnits[i] );

		// IF( The unit being readded was originally before this unit (or this unit is not a permanent member and belongs at the back) )
		if( iPermanentIndex < iUnitPermIndex || iUnitPermIndex == -1 )
		{
			iAddIndex = i;
			break;
		}
	}

	if( iAddIndex == -1 )
	{
		AddUnitToEnd( kAddUnit );
	}
	else
	{
		// Move the units up one slot
		for( i = m_iNumUnits; i > iAddIndex; i-- )
		{
			m_arrUnits[i] = m_arrUnits[i-1];
		}
		m_iNumUnits++;
		m_arrUnits[iAddIndex] = kAddUnit;
		kAddUnit.SetSquad( self );
	}
	SortUnits();
}

function Uninit()
{
	local int i;
	for (i = 0; i < m_iNumUnits; i++)
	{
		m_arrUnits[i].Uninit();
		m_arrUnits[i].Destroy();
	}
	m_iNumUnits = 0;
}

simulated function int GetNumPermanentMembers()
{
	return m_iNumPermanentUnits;
}

simulated function XGUnit GetPermanentMemberAt( int iIndex )
{
	return m_arrPermanentMembers[iIndex];
}

simulated function int GetIndex( XGUnit kUnit )
{
	local int i;
	for( i = 0; i < m_iNumUnits; i++ )
	{
		if( m_arrUnits[i] == kUnit )
			return i;
	}
	return -1;
}

simulated function int GetSortedIndex(XGUnit kUnit)
{
	local int i;
	for (i = 0; i < m_iNumUnits; ++i)
	{
		if (m_arrSortedUnits[i] == kUnit)
			return i;
	}
	return -1;
}

simulated function int GetPermanentIndex( XGUnit kUnit )
{
	local int i;
	for( i = 0; i < m_iNumPermanentUnits; i++ )
	{
		if( m_arrPermanentMembers[i] == kUnit )
			return i;
	}
	return -1;
}

simulated function XGPlayer GetPlayer()
{
	return m_kPlayer;
}

function AddCloseUnit( XGUnit kUnit )
{
	m_iNumCloseUnits++;
}

function RemoveCloseUnit( XGUnit kUnit )
{
	m_iNumCloseUnits--;
}

// simulated function bool HasCloseUnits()
// {
// 	return m_iNumCloseUnits > 0;
// }

function int GetNumCloseUnits()
{
	return m_iNumCloseUnits;
}

function bool HasPostCloseCombatTurn(int iUnit)
{
	if ((m_iCloseCombatInit & (1<<iUnit)) != 0)
		return true;
	return false;
}

simulated function BeginTurn( optional bool bLoadedFromCheckpoint = false )
{
	local int i;

	for( i = 0; i < m_iNumUnits; i++ )
	{
		if( m_arrUnits[i].IsAliveAndWell() )
		{	
			m_arrUnits[i].BeginTurn(bLoadedFromCheckpoint);
		}
	}
}

simulated function bool IsNetworkIdle(bool bCountPathActionsAsIdle)
{
	local int iNumUnits, i;
	local bool bAllUnitsAreNetworkIdle;

	bAllUnitsAreNetworkIdle = true;
	iNumUnits = GetNumMembers();
	for(i = 0; i < iNumUnits && bAllUnitsAreNetworkIdle; i++)
	{
		bAllUnitsAreNetworkIdle = GetMemberAt(i).IsNetworkIdle(bCountPathActionsAsIdle);
	}

	return bAllUnitsAreNetworkIdle;
}

function EndTurn()
{
	local int i;

	for( i = 0; i < m_iNumUnits; i++ )
	{
		if( m_arrUnits[i].IsAliveAndWell() )
		{
			m_arrUnits[i].EndTurn();
		}
	}
}

function InitLoadedMembers()
{
	local int i;

	// First pass: post-process loaded data
	for (i = 0; i < m_iNumUnits; ++i)
	{
		m_arrUnits[i].SetOwner(Owner);
		m_arrUnits[i].LoadInit(m_kPlayer);
	}
}

delegate bool CheckUnitDelegate(XGUnit kUnit);

simulated function bool IsAnyoneElse_CheckUnitDelegate(delegate<CheckUnitDelegate> fnCheckUnit, XGUnit kIgnoreUnit, optional out XGUnit kFoundUnit)
{
	local int i;
	local XGUnit kUnit;

	for( i = 0; i < GetNumMembers(); i++ )
	{
        kUnit = GetMemberAt( i );

		if( kIgnoreUnit == kUnit )
			continue;

		if( fnCheckUnit(kUnit) )
		{
			kFoundUnit = kUnit;
			return true;
		}
	}

	return false;
}

delegate VisitUnitDelegate(XGUnit kUnit);

function VisitUnit(delegate<VisitUnitDelegate> fnVisitUnit, bool bIgnoreTime=true, bool bVisitDead=false, bool bSkipPanicked=true)
{
	local XGUnit kUnit;
	local int iUnit;
	if (!bVisitDead)
	{
		kUnit = GetNextGoodMember(none, bIgnoreTime, false, bSkipPanicked);
		while (kUnit != none)
		{
			fnVisitUnit(kUnit);
			kUnit = GetNextGoodMember(kUnit, bIgnoreTime, false, bSkipPanicked);
		}
	}
	else
	{
		// Step through all units, regardless of status (dead/alive/off battlefield/etc).
		for (iUnit=0; iUnit<m_iNumUnits; iUnit++)
		{
			kUnit = m_arrUnits[iUnit];
			fnVisitUnit(kUnit);
		}
	}
}

// MHU - TODO: Unify GetNext/GetPrevGoodMember.
simulated function XGUnit GetNextGoodMember( XGUnit kUnit = NONE, bool IgnoreTime=true, bool bWraparound=true, bool bSkipPanicked=true, bool bSortedList=false, bool bSkipStrangling=true )
{
	local int iIndex;
	local int i;
	local XGUnit kLoopUnit;

	// can't use units sorted by distance in MP as they may be in different order depending on when sort was called, then client and server would get different units. -tsmith 
	if(WorldInfo.NetMode != NM_Standalone)
	{
		bSortedList = false;
	}

	if (bSortedList && m_arrSortedUnits.Length > 0)
		iIndex = GetSortedIndex(kUnit);
	else
		iIndex = GetIndex( kUnit );

	for( i = iIndex + 1; i < m_iNumUnits * 2; i++ )
	{
		if (!bWraparound && i >= m_iNumUnits)
			return none;

		if (bSortedList)
			kLoopUnit = m_arrSortedUnits[ i % m_iNumUnits ];
		else
			kLoopUnit = m_arrUnits[ i % m_iNumUnits ];

		// skips this unit if it is off the battlefield
		if ( kLoopUnit.DEPRECATED_m_bOffTheBattlefield || kLoopUnit.IsCriticallyWounded() || (bSkipPanicked && kLoopUnit.IsInState('Panicked')) || (bSkipStrangling && false))
		{
			continue;
		}

		if( kLoopUnit.IsAliveAndWell() 
			&& (IgnoreTime) )
		{
			return kLoopUnit;
		}
	}

	return kUnit;
}

simulated function XGUnit GetPrevGoodMember( XGUnit kUnit = NONE, bool IgnoreTime=true, bool bSortedList=false, bool bSkipStrangling=true )
{
	local int iIndex;
	local int i;
	local XGUnit kLoopUnit;

	// can't use units sorted by distance in MP as they may be in different order depending on when sort was called, then client and server would get different units. -tsmith 
	if(WorldInfo.NetMode != NM_Standalone)
	{
		bSortedList = false;
	}

	if (bSortedList && m_arrSortedUnits.Length > 0)
		iIndex = GetSortedIndex(kUnit);
	else
		iIndex  = GetIndex( kUnit );

	if( iIndex == -1 )
		iIndex = 0;

	for( i = m_iNumUnits + iIndex-1; i >= 0; i-- )
	{
		if (bSortedList)
			kLoopUnit = m_arrSortedUnits[ i % m_iNumUnits ];
		else
			kLoopUnit = m_arrUnits[ i % m_iNumUnits ];

		// skips this unit if it is off the battlefield 
		if ( kLoopUnit.DEPRECATED_m_bOffTheBattlefield || kLoopUnit.IsCriticallyWounded() || kLoopUnit.IsInState('Panicked') || (bSkipStrangling && false))
		{
			continue;
		}

		if( kLoopUnit.IsAliveAndWell() )
			return kLoopUnit;
	}

	return kUnit;
}

simulated function color GetColor()
{
	return m_clrColors;
}

simulated function string GetName()
{
	return m_strName;
}

function SetName( string strNewName )
{
	m_strName = strNewName;
}

simulated function string GetMotto()
{
	return "\""$m_strMotto$"\"";
}

simulated function int GetBadge()
{
	return m_iBadge;
}

simulated function bool IsInitialReplicationComplete()
{
	return AllUnitsHaveReplicated() && AllPermanentUnitsHaveReplicated();
}

// function used to ensure initial replication is complete on clients -tsmith 
simulated function bool AllPermanentUnitsHaveReplicated()
{
	local int   i;
	local int   iNumPermanentUnits;
	local bool  bAllPermanentUnitsHaveReplicated;

	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_iNumPermanentUnits));

	bAllPermanentUnitsHaveReplicated = false;
	if( m_iNumPermanentUnits > 0 )
	{
		for(i = 0; i < m_iNumPermanentUnits; i++)
		{
			`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_arrPermanentMembers[i].IsInitialReplicationComplete()));
			if(m_arrPermanentMembers[i] != none && m_arrPermanentMembers[i].IsInitialReplicationComplete())
			{
				iNumPermanentUnits++;
			}
		}

		bAllPermanentUnitsHaveReplicated = (iNumPermanentUnits == m_iNumPermanentUnits);
	}

	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(bAllPermanentUnitsHaveReplicated));

	return bAllPermanentUnitsHaveReplicated;
}

// function used to ensure initial replication is complete on clients -tsmith 
simulated function bool AllUnitsHaveReplicated()
{
	local int   i;
	local int   iNumUnits;
	local bool  bAllUnitsHaveReplicated;

	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_iNumUnits));

	bAllUnitsHaveReplicated = false;
	if( m_iNumUnits > 0 )
	{
		for(i = 0; i < m_iNumUnits; i++)
		{
			`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_arrUnits[i].IsInitialReplicationComplete()));
			if(m_arrUnits[i] != none && m_arrUnits[i].IsInitialReplicationComplete())
			{
				iNumUnits++;
			}
		}

		bAllUnitsHaveReplicated = (iNumUnits == m_iNumUnits);
	}

	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(bAllUnitsHaveReplicated));

	return bAllUnitsHaveReplicated;
}

simulated function Box GetBoundingBox()
{
	local bool bInited;
	local int iUnit, nUnits;
	local XGUnit kUnit;
	local Box BBox;

	nUnits = GetNumMembers();
	bInited=false;
	for (iUnit = 0; iUnit < nUnits; iUnit++)
	{
		kUnit = GetMemberAt( iUnit );
		if (!kUnit.IsAliveAndWell())
			continue;

		if (!bInited)
		{
			BBox.Min = kUnit.GetLocation();
			BBox.Max = kUnit.GetLocation();
			bInited = true;
		}
		else
		{
			BBox.Min.X = Min(BBox.Min.X, kUnit.GetLocation().X);
			BBox.Min.Y = Min(BBox.Min.Y, kUnit.GetLocation().Y);
			BBox.Min.Z = Min(BBox.Min.Z, kUnit.GetLocation().Z);
			BBox.Max.X = Max(BBox.Max.X, kUnit.GetLocation().X);
			BBox.Max.Y = Max(BBox.Max.Y, kUnit.GetLocation().Y);
			BBox.Max.Z = Max(BBox.Max.Z, kUnit.GetLocation().Z);
		}
	}
	return BBox;
}

defaultproperties
{
	//m_strName="Alpha"
	m_clrColors=(R=255,G=0,B=0,A=128)

	m_iNumUnits = 0;
	m_iLeader=-1

	bTickIsDisabled=true
	//bAlwaysRelevant = true;
	//RemoteRole=ROLE_SimulatedProxy;
	bAlwaysRelevant=false;
	RemoteRole=ROLE_None
}
