// Leaf node actions are the nodes that actually modify variables in the behavior class.
// i.e. select ability, find shot target, find path to flank, find path to improve aim, find path to target, etc.
class X2AIBTDefaultActions extends X2AIBTLeafNode
	native(AI)
	dependson(XGAIBehavior);

var delegate<BTActionDelegate> m_dActionFn;
var name m_MoveProfile;

delegate bt_status BTActionDelegate();       

protected function OnInit( int iObjectID, int iFrame )
{
	super.OnInit(iObjectID, iFrame);
	// Fill out parameters based on ParamList strings
	if( FindBTStatActionDelegate(m_ParamList, m_dActionFn) )
	{
		if( m_ParamList.Length > 0 )
		{
			`LogAI("Found stat action delegate - "$m_ParamList[0]);
		}
	}
	// Fill out delegate, ability name, and move profile as needed.
	else if (!FindBTActionDelegate(m_strName, m_dActionFn, SplitNameParam, m_MoveProfile))
	{
		`WARN("X2AIBTDefaultActions- No delegate action defined for node"@m_strName);
	}
	// For nodes with ability names, check unit if ability exists and replace with an equivalent ability if needed.
	if( SplitNameParam != '' )
	{
		ResolveAbilityNameWithUnit(SplitNameParam, m_kBehavior);
	}
}

protected function bt_status Update()
{
	local bt_status eStatus;
	// Early exit if this has already been evaluated.
	if (m_eStatus == BTS_SUCCESS || m_eStatus == BTS_FAILURE)
		return m_eStatus;

	X2AIBTBehaviorTree(Outer).ActiveNode = self;

	if (m_dActionFn != None)
	{
		eStatus = m_dActionFn();
		return eStatus;
	}
	return BTS_FAILURE;
}

static function bool IsValidMoveProfile(name MoveProfile, optional out int MoveTypeIndex_out)
{
	MoveTypeIndex_out = class'XGAIBehavior'.default.m_arrMoveWeightProfile.Find('Profile', MoveProfile);
	if( MoveTypeIndex_out != INDEX_NONE )
	{
		return true;
	}
	return false;
}

static function bool IsValidAoEProfile(name AoEProfile)
{
	if( class'XGAIBehavior'.default.AoEProfiles.Find('Profile', AoEProfile) == INDEX_NONE )
	{
		`LogAIBT("AoE Profile: "$AoEProfile@ "not found in valid AOE profile list.");
		return false;
	}
	return true;
}

static event bool FindBTStatActionDelegate(array<Name> ParamList, optional out delegate<BTActionDelegate> dOutFn )
{
	if( ParamList.Length == 3 )
	{
		if( ParamList[0] == 'SetBTVar' )
		{
			dOutFn = SetBTVar;
			return true;
		}
		else if (ParamList[0] == 'SetUnitValue')
		{
			dOutFn = SetUnitValue;
			return true;
		}
	}
	return false;
}

static event bool FindBTActionDelegate(name strName, optional out delegate<BTActionDelegate> dOutFn, optional out name NameParam, optional out name MoveProfile)
{
	local Name PreHyphenString, PostHyphenString;

	dOutFn = None;

	// Search for a class function with the given name.  If found, return as a delegate.
	if (FindBTDelegateByName(strName, dOutFn))
	{
		return true;
	}

	if (SplitNameAtHyphen(strName, PreHyphenString, PostHyphenString))
	{
		if (FindBTDelegateByName(PreHyphenString, dOutFn))
		{
			if (IsValidMoveProfile(PostHyphenString))
			{
				MoveProfile = PostHyphenString;
			}
			else
			{
				NameParam = PostHyphenString;
			}
			return true;
		}
	}

	`WARN("Unresolved behavior tree Action name with no delegate definition:"@strName);
	return false;
}

function bt_status ReduceCurrTileScore()
{
	local string AdjustmentString;
	local float fAdjustmentValue;
	if (m_ParamList.Length == 1)
	{
		AdjustmentString = String(m_ParamList[0]);
		fAdjustmentValue = float(AdjustmentString);
		m_kBehavior.BT_AdjustCurrTileScore(fAdjustmentValue);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}
// Find destination to hit multiple targets with the specified AoE profile name.  
function bt_status FindMultiTargetDestination()
{
	local bool bRequireLoS;
	if (m_ParamList.Length == 1 && m_ParamList[0] != '0')
	{
		bRequireLoS = true;
	}
	if (m_kBehavior.BT_FindMultiTargetDestination(SplitNameParam, bRequireLoS, false))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}
// Same as FindMultiTargetDestination, but allows moving without cover, or into flanked areas.
function bt_status FindAnyMultiTargetDestination()
{
	local bool bRequireLoS;
	if (m_ParamList.Length >= 1 && m_ParamList[0] != '0')
	{
		bRequireLoS = true;
	}
	if (m_kBehavior.BT_FindMultiTargetDestination(SplitNameParam, bRequireLoS, true))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status LostHuntingGroupMove()
{
	if( m_kBehavior.BT_LostHuntingGroupMove() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}
function bt_status LostScamperMove()
{
	if (m_kBehavior.BT_LostHuntingGroupMove(true))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status LostHuntingTargetAttack()
{
	if( m_kBehavior.BT_LostHuntingTargetAttack() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SelectNearestUnconcealedTarget()
{
	local XComGameState_Unit NearestEnemy;
	local vector UnitLocation;
	local AvailableTarget kTarget;
	UnitLocation = m_kBehavior.GetGameStateLocation();
	NearestEnemy = m_kBehavior.GetNearestKnownEnemy(UnitLocation, , , false);
	if( NearestEnemy != None )
	{
		kTarget.PrimaryTarget.ObjectID = NearestEnemy.ObjectID;
		m_kBehavior.m_kBTCurrTarget.AbilityName = 'Potential';
		m_kBehavior.m_kBTCurrTarget.iScore = 100;
		m_kBehavior.m_kBTCurrTarget.TargetID = kTarget.PrimaryTarget.ObjectID;
		m_kBehavior.m_kBTCurrTarget.kTarget = kTarget;
		m_kBehavior.BT_UpdateBestTarget();
		return BTS_SUCCESS;
	}

	`LogAIBT("GetNearestKnownEnemy returned NONE!");
	return BTS_FAILURE;
}

function bt_status DisableGreenAlertMovement()
{
	m_kBehavior.bDisableGreenAlertMovement = true;
	return BTS_SUCCESS;
}

function bt_status FindDestinationTowardObjective()
{
	local XComGameState_AIBlackboard Blackboard;
	local TTile ObjectiveTile, TargetTile;
	local array<TTile> AdjacentTiles;
	local XComWorldData World;
	Blackboard = XComGameState_AIBlackboard(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_AIBlackboard'));
	if( Blackboard != None )
	{
		if( Blackboard.GetKeyValue("ObjectiveID") > 0 )
		{
			ObjectiveTile.X = Blackboard.GetKeyValue("ObjectiveTileX");
			ObjectiveTile.Y = Blackboard.GetKeyValue("ObjectiveTileY");
			ObjectiveTile.Z = Blackboard.GetKeyValue("ObjectiveTileZ");

			TargetTile = ObjectiveTile;
			TargetTile.X += 1;
			AdjacentTiles.AddItem(TargetTile);
			TargetTile = ObjectiveTile;
			TargetTile.X -= 1;
			AdjacentTiles.AddItem(TargetTile);
			TargetTile = ObjectiveTile;
			TargetTile.Y += 1;
			AdjacentTiles.AddItem(TargetTile);
			TargetTile = ObjectiveTile;
			TargetTile.Y -= 1;
			AdjacentTiles.AddItem(TargetTile);

			foreach AdjacentTiles(ObjectiveTile)
			{
				TargetTile = class'Helpers'.static.GetClosestValidTile(ObjectiveTile);
				World = `XWORLD;
				if( m_kBehavior.m_kUnit.m_kReachableTilesCache.IsTileReachable(TargetTile)
				   || class'Helpers'.static.GetFurthestReachableTileOnPathToDestination(TargetTile, TargetTile, m_kUnitState) )
				{
					m_kBehavior.m_vBTDestination = World.GetPositionFromTileCoordinates(TargetTile);
					m_kBehavior.m_bBTDestinationSet = true;
					return BTS_SUCCESS;
				}
			}
		}
	}
	return BTS_FAILURE;
}

function bt_status DoRedScreenFailure()
{
	local string DebugDetail;
	DebugDetail = m_kUnitState.GetMyTemplateName() @ " - Unit# "$m_kUnitState.ObjectID;
	`RedScreen(String(SplitNameParam) @ DebugDetail );
	if( m_ParamList.Length >= 1 )
	{
		`RedScreen(String(m_ParamList[0]));
	}
	return BTS_FAILURE;
}

function bt_status SetTargetPotential()
{
	local AvailableTarget Target;
	if( m_kBehavior.BT_HasTargetOption('Potential', Target) )
	{
		if( m_kBehavior.BT_SetTargetOption(SplitNameParam, Target) )
		{
			return BTS_SUCCESS;
		}
		else
		{
			`LogAIBT("Unable to set ability"@SplitNameParam@"to Potential target- Failed in SetTargetOption.");
		}
	}
	else
	{
		`LogAIBT("Unable to set ability"@SplitNameParam@"to Potential target: Potential Target does not exist.");
	}
	return BTS_FAILURE;
}

function bt_status RestrictFromKnownEnemyLoS()
{
	m_kBehavior.BT_RestrictMoveFromEnemyLoS();
	return BTS_SUCCESS;
}



function bt_status HeatSeekNearestUnconcealed()
{
	if( m_kBehavior.BT_HeatSeekNearestUnconcealed() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetRandUnitValue()
{
	local string RandMaxString;
	local float RandMaxFloat, RandFloat;
	local EUnitValueCleanup CleanupType;

	if( m_ParamList.Length >= 1 )
	{
		RandMaxString = String(m_ParamList[0]);
		RandMaxFloat = float(RandMaxString);
		// Set new value.
		RandFloat = `SYNC_FRAND() * RandMaxFloat;
		`LogAIBT("SetRandUnitValue Rand("$RandMaxFloat$") returned:"@RandFloat);
		// Allow optional second parameter to specify when to clear the unit value.
		if( m_ParamList.Length == 2 && m_ParamList[1] != '0' )
		{
			// Param[1] set == CleanUpTurn.
			CleanupType = eCleanup_BeginTurn;
		}
		else
		{
			CleanupType = eCleanup_BeginTactical;
		}

		SetUnitValue_Internal(SplitNameParam, RandFloat, CleanupType);
		return BTS_SUCCESS;
	}
	`LogAIBT("SetRandUnitValue failed - No Param[0] defined for max rand value!");
	return BTS_FAILURE;
}

function bt_status SetUnitValue()
{
	local EUnitValueCleanup CleanupType;
	local string StringParam;
	local float FloatValue;
	if( m_ParamList.Length >= 1 )
	{
		if (m_ParamList.Length == 3) // More flexible node name version
		{
			StringParam = String(m_ParamList[2]);
			FloatValue = float(StringParam);
			CleanupType = eCleanup_BeginTactical;
			SetUnitValue_Internal(m_ParamList[1], FloatValue, CleanupType);
		}
		// Allow optional second parameter to specify when to clear the unit value.
		else
		{
			if (m_ParamList.Length == 2 && m_ParamList[1] != '0')
			{
				// Param[1] set == CleanUpTurn.
				CleanupType = eCleanup_BeginTurn;
			}
			else
			{
				CleanupType = eCleanup_BeginTactical;
			}

			StringParam = String(m_ParamList[0]);
			FloatValue = float(StringParam);
			SetUnitValue_Internal(SplitNameParam, FloatValue, CleanupType);
		}
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function SetUnitValue_Internal( Name ValueName, float FloatValue, EUnitValueCleanup CleanupType )
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	`LogAIBT("Setting Unit Value"@ValueName@" to "$FloatValue);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("BehaviorTree - SetUnitValue");
	NewUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', m_kUnitState.ObjectID));
	NewUnitState.SetUnitFloatValue(ValueName, FloatValue, CleanupType);
	`GAMERULES.SubmitGameState(NewGameState);
}

function bt_status TargetScoreByHitChanceValue()
{
	local float ScaleValue, HitChance;
	local string strParam;
	HitChance = m_kBehavior.BT_GetHitChanceOnTarget();

	if( m_ParamList.Length >= 1 ) // Check for a scalar value.
	{
		if( m_ParamList.Length == 2 ) // Find hit chance on alternate ability.
		{
			HitChance = m_kBehavior.BT_GetHitChanceOnTarget(m_ParamList[1]);
			`LogAIBT("Hit Chance on ability "$m_ParamList[1]$"= "$HitChance@"\n");
		}
		strParam = String(m_ParamList[0]);
		ScaleValue = float(strParam);
		HitChance *= ScaleValue;
		`LogAIBT("Multiplied by param[0] ("$ScaleValue$")");
	}
	`LogAIBT("Scaled HitChance = "$HitChance@"\n");
	m_kBehavior.BT_AddToTargetScore(HitChance, m_strName);
	return BTS_SUCCESS;
}
function bt_status TargetScoreByScaledDistance()
{
	local float ScaleValue, DistMeters, AddendValue;
	local string strParam;
	local XComGameState_Unit TargetUnitState;
	local GameRulesCache_VisibilityInfo VisInfo;
	if( m_ParamList.Length > 0 )
	{
		if( m_kBehavior.BT_GetTarget(TargetUnitState) )
		{
			strParam = String(m_ParamList[0]);
			ScaleValue = float(strParam);
			if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(m_kUnitState.ObjectID, TargetUnitState.ObjectID, VisInfo)
				&& VisInfo.bClearLOS ) // DefaultTargetDist isn't valid if visibility check fails.
			{
				DistMeters = Sqrt(VisInfo.DefaultTargetDist);
			}
			else
			{
				DistMeters = m_kBehavior.GetDistanceFromEnemy(TargetUnitState);
			}
			DistMeters = `UNITSTOMETERS(DistMeters);
			if ( m_ParamList.Length > 1)
			{
				strParam = String(m_ParamList[1]);
				AddendValue = float(strParam);
				`LogAIBT("TargetScoreByScaledDistance: Distance = "@DistMeters@ "\nScale value = "$ScaleValue@ "+"@ AddendValue);

			}
			else
			{
				`LogAIBT("TargetScoreByScaledDistance: Distance = "@DistMeters@"\nScale value="$ScaleValue);
			}
			DistMeters *= ScaleValue;
			DistMeters += AddendValue;
			m_kBehavior.BT_AddToTargetScore(DistMeters, m_strName);
			return BTS_SUCCESS;
		}
		else
		{
			`LogAIBT("BT ERROR: TargetScoreByScaledDistance failed: No Target specified!  (Within SetTargetStack?)");
		}
	}
	`LogAIBT("BT ERROR: TargetScoreByScaledDistance failed: No scalar Param value specified!");
	return BTS_FAILURE;
}

function bt_status TargetScoreByVisibleXComDist()
{
	local float ScaleValue, BestDistMeters, DistMeters;
	local string strParam;
	local XComGameState_Unit TargetUnitState;
	local array<GameRulesCache_VisibilityInfo> VisInfos;
	local GameRulesCache_VisibilityInfo VisInfo;
	if (m_ParamList.Length == 1)
	{
		if (m_kBehavior.BT_GetTarget(TargetUnitState))
		{
			BestDistMeters = -1;
			class'X2TacticalVisibilityHelpers'.static.GetAllTeamUnitsForTileLocation(TargetUnitState.TileLocation, TargetUnitState.ControllingPlayer.ObjectID, eTeam_XCom, VisInfos);
			strParam = String(m_ParamList[0]);
			ScaleValue = float(strParam);
			if (m_kBehavior.GetAIUnitDataID(m_kUnitState.ObjectID) > 0) // Skip this step if the unit has no alert data container.  (XCom units)
			{
				// Find closest distance to a known / visible enemy.
				foreach VisInfos(VisInfo)
				{
					if (VisInfo.SourceID == TargetUnitState.ObjectID)
						continue;
					// Ignore concealed.
					if (m_kBehavior.CachedKnownUnitRefs.Find('ObjectId', VisInfo.SourceID) != INDEX_NONE)
					{
						if (VisInfo.bClearLOS)
						{
							DistMeters = Sqrt(VisInfo.DefaultTargetDist);
							if (BestDistMeters < 0 || DistMeters < BestDistMeters)
							{
								BestDistMeters = DistMeters;
							}
						} // otherwise the DefaultTargetDist is invalid.  Ignore targets not visible to XCom.
					}
				}
			}

			if ( BestDistMeters > 0 )
			{
				BestDistMeters = `UNITSTOMETERS(BestDistMeters);
				`LogAIBT("TargetScoreByXComDistance: Distance = "@BestDistMeters@ "\nScale value = "$ScaleValue);
				BestDistMeters *= ScaleValue;
				m_kBehavior.BT_AddToTargetScore(BestDistMeters, m_strName);
				return BTS_SUCCESS;
			}
			else
			{
				`LogAIBT("TargetScoreByXComDistance: No XCom units can see Unit #"$TargetUnitState.ObjectID);
			}
		}
		else
		{
			`LogAIBT("BT ERROR: TargetScoreByXComDistance failed: No Target specified!  (Within SetTargetStack?)");
		}
	}
	`LogAIBT("BT ERROR: TargetScoreByXComDistance failed: No scalar Param value specified!");
	return BTS_FAILURE;
}

function bt_status TargetScoreByScaledMaxStat()
{
	local int nScore;
	local float ScaleValue;
	local ECharStatType StatType;
	local string strParam;
	local XComGameState_Unit TargetUnitState;
	if( m_ParamList.Length == 1 )
	{
		if( m_kBehavior.BT_GetTarget(TargetUnitState) )
		{
			strParam = String(m_ParamList[0]);
			ScaleValue = float(strParam);
			strParam = String(SplitNameParam);
			StatType = FindStatByName(strParam);
			nScore = TargetUnitState.GetMaxStat(StatType);
			`LogAIBT("TargetScoreByScaledMaxStat: MaxStat("$strParam$")="@nScore@"\nScale value="$ScaleValue);
			nScore *= ScaleValue;
			m_kBehavior.BT_AddToTargetScore(nScore, m_strName);
			return BTS_SUCCESS;
		}
		else
		{
			`LogAIBT("BT ERROR: TargetScoreByScaledMaxStat failed: No Target specified!  (Within SetTargetStack?)");
		}
	}
	`LogAIBT("BT ERROR: TargetScoreByScaledMaxStat failed: No scalar Param value specified!");
	return BTS_FAILURE;
}

function bt_status RestrictFromAlliesWithEffect()
{
	local float MinDistance;
	local string strParam;
	if( m_ParamList.Length == 1 )
	{
		strParam = String(m_ParamList[0]);
		MinDistance = float(strParam);
		m_kBehavior.BT_RestrictFromAlliesWithEffect(SplitNameParam, MinDistance);
		return BTS_SUCCESS;
	}
	`LogAIBT("BT ERROR: RestrictFromAlliesWithEffect failed: No DISTANCE Param value specified!");

	return BTS_FAILURE;
}

function bt_status RestrictToAxisLoS()
{
	m_kBehavior.BT_RestrictToAxisLoS();
	return BTS_SUCCESS;
}

function bt_status RestrictToGroundTiles()
{
	m_kBehavior.BT_RestrictToGroundTiles();
	return BTS_SUCCESS;
}

function bt_status SetTargetAsPriority()
{
	if (m_kBehavior.BT_SetTargetAsPriority(SplitNameParam))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetPriorityTargetFromKismet()
{
	local XComGameState_AIPlayerData AIPlayerData;
	if (m_kBehavior.m_kPlayer != None)
	{
		AIPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(m_kBehavior.m_kPlayer.GetAIDataID()));
		if (AIPlayerData != None)
		{
			if ( AIPlayerData.HasPriorityTargetUnit() || AIPlayerData.HasPriorityTargetObject() )
			{
				m_kBehavior.BTPriorityTarget = AIPlayerData.PriorityTarget.ObjectID;
				m_kBehavior.SetBestTargetOption('Potential', AIPlayerData.PriorityTarget.ObjectID);
				return BTS_SUCCESS;
			}
		}
	}
	return BTS_FAILURE;
}

function bt_status TargetScoreByScaledCurrStat()
{
	local int nScore;
	local float ScaleValue;
	local ECharStatType StatType;
	local string strParam;
	local XComGameState_Unit TargetUnitState;
	if( m_ParamList.Length == 1 )
	{
		if( m_kBehavior.BT_GetTarget(TargetUnitState) )
		{
			strParam = String(m_ParamList[0]);
			ScaleValue = float(strParam);
			strParam = String(SplitNameParam);
			StatType = FindStatByName(strParam);
			nScore = TargetUnitState.GetCurrentStat(StatType);
			`LogAIBT("TargetScoreByScaledCurrStat: CurrStat("$strParam$")="@nScore@"\nScale value="$ScaleValue);
			nScore *= ScaleValue;
			m_kBehavior.BT_AddToTargetScore(nScore, m_strName);
			return BTS_SUCCESS;
		}
		else
		{
			`LogAIBT("BT ERROR: TargetScoreByScaledMaxStat failed: No Target specified!  (Within SetTargetStack?)");
		}
	}
	`LogAIBT("BT ERROR: TargetScoreByScaledCurrStat failed: No scalar Param value specified!");
	return BTS_FAILURE;
}

function bt_status AddAbilityRangeWeight()
{
	local string ParamString;
	local float Weight;
	if( m_ParamList.Length == 1 )
	{
		ParamString = String(m_ParamList[0]);
		Weight = float(ParamString);
	}
	else
	{
		Weight = 1.0f;
	}
	if( m_kBehavior.BT_AddAbilityRangeWeight(SplitNameParam, Weight) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}


function bt_status IgnoreHazards()
{
	m_kBehavior.BT_IgnoreHazards();
	return BTS_SUCCESS;
}

function bt_status SkipMove()
{
	m_kBehavior.BT_SkipMove();
	return BTS_SUCCESS;
}

function bt_status FindPotentialAoETargets()
{
	if (IsValidAoEProfile(SplitNameParam))
	{
		if (m_kBehavior.BT_FindPotentialAoETarget(SplitNameParam, m_ParamList))
		{
			return BTS_SUCCESS;
		}
	}
	return BTS_FAILURE;
}

function bt_status SelectAoETarget()
{
	if (IsValidAoEProfile(SplitNameParam))
	{
		if (m_kBehavior.BT_SelectAoETarget(SplitNameParam))
		{
			return BTS_SUCCESS;
		}
	}
	return BTS_FAILURE;
}
// Handle any movement for non-red-alert units.
function bt_status SelectGreenAlertAction()
{
	if (m_kBehavior.BTHandleGenericMovement())
	{
		return BTS_SUCCESS;
	}
	// This is an acceptable failure for units that have nothing to do now.  (i.e. guards on green alert.)
	return BTS_FAILURE;
}

function bt_status SetBTVar()
{
	if( m_kBehavior.BT_SetBTVar(String(m_ParamList[1]), int(String(m_ParamList[2])) ))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SelectAbility()
{
	local String DebugText;
	if (m_kBehavior.IsValidAbility(SplitNameParam, DebugText))
	{
		if( m_ParamList.Length > 0 && m_ParamList[0] == 'UseDestination' )
		{
			if( m_kBehavior.m_bBTDestinationSet )
			{
				m_kBehavior.bSetDestinationWithAbility = true;
			}
			else
			{
				`LogAIBT("Attempted to SelectAbility with param[0] UseDestination, when no destination has been set!");
				m_kBehavior.bSetDestinationWithAbility = false;
				return BTS_FAILURE;
			}
		}
		else
		{
			m_kBehavior.bSetDestinationWithAbility = false;
		}

		// Wait until next tick to execute the ability.
		if( !m_kBehavior.WaitForExecuteAbility )
		{
			m_kBehavior.WaitForExecuteAbility = true;
			return BTS_RUNNING;
		}

		m_kBehavior.WaitForExecuteAbility = false;
		// Mark ability as selected.
		m_kBehavior.m_strBTAbilitySelection = SplitNameParam;
		
		return BTS_SUCCESS;
	}
	else
	{
		`LogAIBT("IsValidAbility-"$SplitNameParam@ "returned false!  Reason:"@DebugText);
	}
	return BTS_FAILURE;
}

function bt_status SelectAbilityGroupwide()
{
	local XComGameState_AIGroup GroupState;
	local XGAIBehavior MemberBehavior;

	GroupState = m_kUnitState.GetGroupMembership();
	if (GroupState.AIBTFindAbility(string(SplitNameParam),, MemberBehavior))
	{
		if ( MemberBehavior != m_kBehavior) // If the selected group member is not the active one, 
		{									// mark the active unit to defer the ability selection to another unit.
			m_kBehavior.m_strBTAbilitySelection = 'DeferredToGroup';
			m_kBehavior.bUseGroupActionSelections = true;
			m_kBehavior.DeferredBTTargetID = MemberBehavior.UnitState.ObjectID;
			MemberBehavior.InitBTVarsInternal();
			MemberBehavior.m_strBTAbilitySelection = SplitNameParam;
		}
		else
		{
			return SelectAbility();
		}
		return BTS_SUCCESS;
	}
	`LogAIBT("SelectAbilityGroupwide failed to find the target ability"@SplitNameParam@ " in any group member.");
	return BTS_FAILURE;
}

function bt_status SetAbilityForFindDestination()
{
	local AvailableAction kAbility;
	kAbility = m_kBehavior.GetAvailableAbility(string(SplitNameParam), true);
	if (kAbility.AbilityObjectRef.ObjectID > 0)
	{
		m_kBehavior.BT_SetAbilityForDestination(kAbility);
		return BTS_SUCCESS;
	}
	`LogAIBT("SetAbilityForFindDestination failed - Ability not found:"$SplitNameParam);
	return BTS_FAILURE;
}

function bt_status SetTargetStack()
{
	if( m_kBehavior.BT_SetTargetStack(SplitNameParam) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

// SetPotentialTargetStack - Consider all enemies. Certain target functions (i.e. TargetHitChance) won't be applicable for this.
function bt_status SetPotentialTargetStack()
{
	if( m_kBehavior.BT_SetPotentialTargetStack() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

// SetVisiblePotentialTargetStack - Consider all visible enemies (within LoS).
function bt_status SetVisiblePotentialTargetStack()
{
	if( m_kBehavior.BT_SetPotentialTargetStack(true) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

// SetPotentialAllyTargetStack - Consider all Allies. Certain target functions (i.e. TargetHitChance) won't be applicable for this.
function bt_status SetPotentialAllyTargetStack()
{
	if (m_kBehavior.BT_SetPotentialAllyTargetStack())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

// SetPotentialAnyTeamTargetStack - Consider all units. Certain target functions (i.e. TargetHitChance) won't be applicable for this.
function bt_status SetPotentialAnyTeamTargetStack()
{
	if (m_kBehavior.BT_SetPotentialAnyTeamTargetStack())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetNextTarget()
{
	if (m_kBehavior.BT_SetNextTarget())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetOverwatcherStack()
{
	if( m_kBehavior.BT_SetOverwatcherStack() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetNextOverwatcher()
{
	if( m_kBehavior.BT_SetNextOverwatcher() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetSuppressorStack()
{
	if( m_kBehavior.BT_SetSuppressorStack() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetNextSuppressor()
{
	if( m_kBehavior.BT_SetNextSuppressor() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status FindDestination()
{
	local int MoveTypeIndex;
	if( IsValidMoveProfile(m_MoveProfile, MoveTypeIndex) )
	{
		return m_kBehavior.BT_FindDestination(MoveTypeIndex);
	}
	return BTS_FAILURE;
}

function bt_status ResetDestinationSearch()
{
	m_kBehavior.BT_ResetDestinationSearch();
	return BTS_SUCCESS;
}

function bt_status FindRestrictedDestination()
{
	local int MoveTypeIndex;
	if (IsValidMoveProfile(m_MoveProfile, MoveTypeIndex))
	{
		return m_kBehavior.BT_FindDestination(MoveTypeIndex, true);
	}
	return BTS_FAILURE;
}

function bt_status FindClosestPointToTarget()
{
	if( m_kBehavior.BT_FindClosestPointToTarget(SplitNameParam) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status DisableGroupMove()
{
	m_kBehavior.BT_DisableGroupMove();
	return BTS_SUCCESS;
}

function bt_status FindClosestPointToAxisGround()
{
	if( m_kBehavior.BT_FindClosestPointToAxisGround() )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status RestrictToAbilityRange()
{
	if( m_kBehavior.BT_RestrictMoveToAbilityRange(SplitNameParam) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status RestrictToAlliedAbilityRange()
{
	local string strParam;
	local int MinTargetCount;
	if( m_ParamList.Length == 1 )
	{
		strParam = string(m_ParamList[0]);
		MinTargetCount = int(strParam);
	}
	if( m_kBehavior.BT_RestrictMoveToAbilityRange(SplitNameParam, MinTargetCount) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status RestrictToPotentialTargetRange()
{
	if( m_kBehavior.BT_RestrictMoveToPotentialTargetRange(SplitNameParam) )
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status IncludeAlliesAsMeleeTargets()
{
	m_kBehavior.BT_IncludeAlliesAsMeleeTargets();
	return BTS_SUCCESS;
}

function bt_status RestrictToFlanking()
{
	m_kBehavior.BT_RestrictMoveToFlanking();
	return BTS_SUCCESS;
}

function bt_status RestrictToEnemyLoS()
{
	m_kBehavior.BT_RestrictMoveToEnemyLoS();
	return BTS_SUCCESS;
}

function bt_status RestrictToAllyLoS()
{
	m_kBehavior.BT_RestrictMoveToAllyLoS();
	return BTS_SUCCESS;
}

function bt_status RestrictOffensiveGrapple()
{
	m_kBehavior.BT_RestrictOffensiveGrapple();
	return BTS_SUCCESS;
}
function bt_status FindDestinationWithLoS()
{
	local int MoveTypeIndex;
	if (IsValidMoveProfile(m_MoveProfile, MoveTypeIndex))
	{
		return m_kBehavior.BT_FindDestinationWithLOS(MoveTypeIndex);
	}
	return BTS_FAILURE;
}
function bt_status RequireEnemyLoSToTile()
{
	m_kBehavior.BT_RequireEnemyLoSToTile();
	return BTS_SUCCESS;
}

function bt_status GASRestrictMoveToAoETarget()
{
	m_kBehavior.BT_GASRestrictMoveToAoETarget();
	return BTS_SUCCESS;
}

function bt_status AddToTargetScore()
{
	local int nScore;
	local string strParam;
	if (m_ParamList.Length == 1)
	{
		strParam = string(m_ParamList[0]);
		nScore = int(strParam);
		m_kBehavior.BT_AddToTargetScore(nScore);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status UpdateBestTarget()
{
	m_kBehavior.BT_UpdateBestTarget();
	return BTS_SUCCESS;
}

function bt_status SetAlertDataStack()
{
	if (m_kBehavior.BT_SetAlertDataStack())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetNextAlertData()
{
	if (m_kBehavior.BT_SetNextAlertData())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status DeleteCurrentAlertData()
{
	m_kBehavior.BT_MarkAlertDataForDeletion();
	return BTS_SUCCESS;
}

function bt_status AddToAlertDataScore()
{
	local int nScore;
	local string strParam;
	if (m_ParamList.Length == 1)
	{
		strParam = string(m_ParamList[0]);
		nScore = int(strParam);
		m_kBehavior.BT_AddToAlertDataScore(nScore);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status UpdateBestAlertData()
{
	m_kBehavior.BT_UpdateBestAlertData();
	return BTS_SUCCESS;
}

function bt_status AlertDataMovementUseCover()
{
	m_kBehavior.BT_AlertDataMovementUseCover();
	return BTS_SUCCESS;
}

function bt_status AlertDataMovementIgnoreCover()
{
	m_kBehavior.m_bAlertDataMovementUseCover = false;
	return BTS_SUCCESS;
}

function bt_status FindAlertDataMovementDestination()
{
	if (m_kBehavior.BT_FindAlertDataMovementDestination())
	{
		return BTS_SUCCESS;
	}

	return BTS_FAILURE;
}

function bt_status UseDashMovement()
{
	m_kBehavior.BT_SetCanDash();
	return BTS_SUCCESS;
}

function bt_status SetCiviliansAsEnemiesInMoveCalculation()
{
	m_kBehavior.BT_SetCiviliansAsEnemiesInMoveCalculation();
	return BTS_SUCCESS;
}

function bt_status SetNoCoverMovement()
{
	m_kBehavior.BT_SetNoCoverMovement();
	return BTS_SUCCESS;
}

function bt_status DoNoiseAlert() // contents basically stolen from SeqAct_DropAlert
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local AlertAbilityInfo AlertInfo;
	local XComGameState_Unit kUnitState;
	local XComGameState_AIUnitData NewUnitAIState, kAIData;

	History = `XCOMHISTORY;

	// Kick off mass alert to location.
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "BehaviorTree - DoNoiseAlert" );

	AlertInfo.AlertTileLocation = m_kUnitState.TileLocation;
	AlertInfo.AlertRadius = 1000;
	AlertInfo.AlertUnitSourceID = m_kUnitState.ObjectID;
	AlertInfo.AnalyzingHistoryIndex = History.GetCurrentHistoryIndex( ); //NewGameState.HistoryIndex; <- this value is -1.

	foreach History.IterateByClassType( class'XComGameState_AIUnitData', kAIData )
	{
		kUnitState = XComGameState_Unit( History.GetGameStateForObjectID( kAIData.m_iUnitObjectID ) );
		if (kUnitState != None && kUnitState.IsAlive( ))
		{
			NewUnitAIState = XComGameState_AIUnitData( NewGameState.ModifyStateObject( kAIData.Class, kAIData.ObjectID ) );
			if( !NewUnitAIState.AddAlertData( kAIData.m_iUnitObjectID, eAC_AlertedByYell, AlertInfo, NewGameState ) )
			{
				NewGameState.PurgeGameStateForObjectID(NewUnitAIState.ObjectID);
			}
		}
	}

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return BTS_SUCCESS;
}

function bt_status CivilianExitMap()
{
	return RunCivilianExitMap(m_kUnitState);
}

function bt_status SetBestTargetAsCurrentTarget()
{
	local AvailableTarget TargetChoice;
	TargetChoice = m_kBehavior.BT_GetBestTarget(SplitNameParam);
	if( TargetChoice.PrimaryTarget.ObjectID > 0 )
	{
		m_kBehavior.BT_InitNextTarget(TargetChoice);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

static function bt_status RunCivilianExitMap( XComGameState_Unit UnitState ) 
{
	local XComParcelManager ParcelManager;
	local XComWorldData WorldData;
	local XGUnit UnitVisualizer;
	local array<Vector> SpawnLocations;
	local array<TTile> PathTiles;
	local XComGameState NewGameState;
	local XComGameState NewGameState2;
	local TTile EndTile;
	local XComGameStateHistory History;
	local X2TacticalGameRuleset TacticalRules;

	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit CurrentRescuerUnit;
	local XComGameState_Unit NewRescuerUnit;



	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	// Find the soldier that rescued the civilian, and setup and submit a new XComGameState
	// for that soldier, with an associated visualization function.
	foreach History.IterateContextsByClassType( class'XComGameStateContext_Ability', AbilityContext, , true, History.GetEventChainStartIndex())
	{
		if( AbilityContext.InputContext.AbilityTemplateName == 'StandardMove' || AbilityContext.InputContext.AbilityTemplateName == 'Grapple' )
		{
			CurrentRescuerUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

			NewGameState2 = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Behavior Tree - CivilianExitMap: " @ CurrentRescuerUnit.GetVisualizer( ) @ " (" @ CurrentRescuerUnit.ObjectID @ ")" );

			NewRescuerUnit = XComGameState_Unit(NewGameState2.ModifyStateObject(class'XComGameState_Unit',CurrentRescuerUnit.ObjectID));
			NewGameState2.GetContext().PreBuildVisualizationFn.AddItem(NewRescuerUnit.SoldierRescuesCivilian_BuildVisualization);

			`XEVENTMGR.TriggerEvent('CivilianRescued', NewRescuerUnit, UnitState, NewGameState2);
			TacticalRules.SubmitGameState(NewGameState2);
			break;
		}
	}

	if( CurrentRescuerUnit == none )
	{
		`Redscreen("Behavior Tree - CivilianExitMap: Unable to find the rescuing xcom soldier.  Speak to mdomowicz.");
	}

	if( UnitState.GetTeam() != eTeam_Neutral && UnitState.GetTeam() != eTeam_Resistance )
	{
		`Redscreen("Behavior Tree - CivilianExitMap: Attempting to rescue a non-civilian unit.");
		return BTS_FAILURE;
	}

	// find the spawn location tile
	ParcelManager = `PARCELMGR;
	ParcelManager.SoldierSpawn.GetValidFloorLocations( SpawnLocations );

	WorldData = `XWORLD;
	WorldData.GetFloorTileForPosition( SpawnLocations[ 0 ], EndTile );

	UnitVisualizer = XGUnit(UnitState.GetVisualizer());
	if( UnitVisualizer != none )
	{
		// have them run toward the spawn location if there is a way to get there
		if( !class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, EndTile, PathTiles, false) )
		{
			// If the unit can't find a path, then just path anywhere it can.
			UnitVisualizer.m_kReachableTilesCache.GetAllPathableTiles(PathTiles);
			if( PathTiles.Length > 0 )
			{
				EndTile = PathTiles[PathTiles.Length - 1];
				PathTiles.Length = 0;
				if( !class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, EndTile, PathTiles, false) )
				{
					`Warn("CivilianExitMap - could not build path to destination!  Rescue movement will be skipped.");
				}
			}
			else
			{
				`Warn("CivilianExitMap - Unit has no pathable tiles!  Rescue movement will be skipped.");
			}
		}

		// truncate it to just the beginning part of the path. They don't need to go the entire way, just enough to
		// see them move
		if( PathTiles.Length > 0 )
		{
			PathTiles.Length = min(PathTiles.Length, 6);
			XComTacticalController(UnitVisualizer.GetOwningPlayerController()).GameStateMoveUnitSingle(UnitVisualizer, PathTiles);
		}
		// Since this moves the unit for the AI, we don't need the AI to process anything further.
		if( UnitVisualizer.m_kBehavior != None )
		{
			UnitVisualizer.m_kBehavior.BT_SkipMove();
		}

		// and then they exit the level
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Behavior Tree - CivilianExitMap: " @ UnitState.GetVisualizer() @ " (" @ UnitState.ObjectID @ ")");
		UnitState.EvacuateUnit(NewGameState);

		TacticalRules.SubmitGameState(NewGameState);

		if( PathTiles.Length > 0 )
		{
			return BTS_SUCCESS;
		}
	}
	else
	{
		`RedScreen("CivilianExitMap - Unit visualizer not found!");
	}
	return BTS_FAILURE;
}

function bt_status OrangeAlertMovement()
{
	if (m_kBehavior.BT_HandleOrangeAlertMovement())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SelectYellowAlertAction()
{
	if (m_kBehavior.BT_HandleYellowAlertMovement())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}
//------------------------------------------------------------------------------
// Functions used for debugging 
function string GetNodeDetails(const out array<BTDetailedInfo> TraversalData)
{
	local string strText;
	local name Param;
	local int iParam;
	strText = super.GetNodeDetails(TraversalData);

	strText @= "ACTION    Param count="$m_ParamList.Length$"\n";

	if (m_dActionFn != None)
	{
		strText @= "delegate="$string(m_dActionFn)$"\n";
	}

	if (SplitNameParam != '')
	{
		strText @= "Ability Name="$string(SplitNameParam)@"\n";
	}

	for (iParam=0; iParam<m_ParamList.Length; iParam++)
	{
		Param = m_ParamList[iParam];
		strText @= "(Param "$iParam$")"@Param@"\n";
	}
	return 	strText;
}

function bt_status SelectDestinationFromRandomDir()
{
	local TTile Tile;
	local UnitValue UnitVal;
	local Rotator Rot;
	local vector TileVector, DirVector, TargetDest;
	local float MaxDist;
	local XComWorldData World;
	World = `XWORLD;

	// Use the random direction set from the BT (UnitValue: RandomDir) to find a destination.
	if (m_kUnitState.GetUnitValue('RandomDir', UnitVal))
	{
		Rot.Pitch = 0;
		Rot.Yaw = UnitVal.fValue;
		Rot.Roll = 0;
		TileVector = vect(1, 0, 0);
		DirVector = TransformVectorbyRotation(Rot, TileVector);
		MaxDist = m_kUnitState.GetCurrentStat(eStat_Mobility) * World.World_StepSize;
		TargetDest = m_kBehavior.GetGameStateLocation() + (DirVector * MaxDist);
		Tile = World.GetTileCoordinatesFromPosition(TargetDest);

		Tile = class'Helpers'.static.GetClosestValidTile(Tile); // Ensure the tile isn't occupied before finding a path to it.
		if (!class'Helpers'.static.GetFurthestReachableTileOnPathToDestination(Tile, Tile, m_kUnitState, false))
		{
			Tile = m_kBehavior.m_kUnit.m_kReachableTilesCache.GetClosestReachableDestination(Tile);
		}

		if (m_kBehavior.m_kUnit.m_kReachableTilesCache.IsTileReachable(Tile) && Tile != m_kUnitState.TileLocation)
		{
			m_kBehavior.m_vBTDestination = World.GetPositionFromTileCoordinates(Tile);
			`LogAIBT("SelectDestinationFromRandomDir - Setting destination to: ("$Tile.X@Tile.Y@Tile.Z$").");
			m_kBehavior.m_bBTDestinationSet = true;
			return BTS_SUCCESS;
		}

		if ( m_kUnitState.TileLocation == Tile)
		{
			`LogAIBT("Path failure toward ("$Tile.X@Tile.Y@Tile.Z$").  Target tile matches current unit tile location.");
		}
		else
		{
			`LogAIBT("Tile unreachable! ("$Tile.X@Tile.Y@Tile.Z$")."); 
		}
		return BTS_FAILURE;
	}

	`LogAIBT("Failed to find UnitValue: 'RandomDir' on unit state!");
	return BTS_FAILURE;
}

function bt_status SetShatteredTarget()
{
	local StateObjectReference TargetUnitRef;
	local array<StateObjectReference> VisibleUnits;
	local int iSelection;

	// Pull the target ID from the Will Roll context.
	TargetUnitRef.ObjectID = class'X2Effect_Panicked'.static.GetPanicSourceID(m_kUnitState.ObjectID, 'Shattered');
	if (TargetUnitRef.ObjectID == INDEX_NONE || TargetUnitRef.ObjectID == m_kUnitState.ObjectID)
	{
		`LogAIBT("Failed to find Shattered target.  Selecting random nearby enemy.");
		// As a fallback, we are selecting a random nearby unit, since we were unable to find the target from the panic effect.
		class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(m_kUnitState.ObjectID, VisibleUnits);
		if (VisibleUnits.Length > 0)
		{
			iSelection = `SYNC_RAND(VisibleUnits.Length);
			TargetUnitRef = VisibleUnits[iSelection];
		}
	}
	if (TargetUnitRef.ObjectID > 0)
	{
		SetUnitValue_Internal(class'X2Effect_Shattered'.default.ShatteredTargetValueName, TargetUnitRef.ObjectID, eCleanup_BeginTactical);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetObsessedTarget()
{
	local StateObjectReference TargetUnitRef;
	local array<StateObjectReference> VisibleUnits;
	local int iSelection;

	// Pull the target ID from the Will Roll context.
	TargetUnitRef.ObjectID = class'X2Effect_Panicked'.static.GetPanicSourceID(m_kUnitState.ObjectID, 'Obsessed');
	if (TargetUnitRef.ObjectID == INDEX_NONE || TargetUnitRef.ObjectID == m_kUnitState.ObjectID)
	{
		`LogAIBT("Failed to find obsessed target.  Selecting random nearby enemy.");
		// As a fallback, we are selecting a random nearby unit, since we were unable to find the target from the panic effect.
		class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(m_kUnitState.ObjectID, VisibleUnits);
		if (VisibleUnits.Length > 0)
		{
			iSelection = `SYNC_RAND(VisibleUnits.Length);
			TargetUnitRef = VisibleUnits[iSelection];
		}
	}
	if ( TargetUnitRef.ObjectID > 0 )
	{
		SetUnitValue_Internal(class'X2Effect_Obsessed'.default.ObsessedTargetValueName, TargetUnitRef.ObjectID, eCleanup_BeginTactical);
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status FindClosestDestinationTowardsObsessedTarget()
{
	local XComGameState_Unit TargetUnit;
	local UnitValue ObsessedTargetValue;
	local Vector TargetLoc;
	if (m_kUnitState.GetUnitValue(class'X2Effect_Obsessed'.default.ObsessedTargetValueName, ObsessedTargetValue))
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObsessedTargetValue.fValue));
		if (TargetUnit != None)
		{
			TargetLoc = `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
			if (m_kBehavior.HasValidDestinationToward(TargetLoc, TargetLoc))
			{
				m_kBehavior.GetClosestCoverLocation(TargetLoc, TargetLoc, false);
				m_kBehavior.m_vBTDestination = TargetLoc;
				m_kBehavior.m_bBTDestinationSet = true;
				return BTS_SUCCESS;
			}
		}
	}
	return BTS_FAILURE;
}

// Attempt to find a tile in movement range that is also adjacent to a teammate that is not affected by the Burning effect.
function bt_status SetDestinationNextToUnburnedTeammate()
{
	local XComGameState_Unit TargetUnit;
	local array<XComGameState_Unit> Teammates;
	local array<TTile> AdjacentTiles;
	local TTile Tile;
	local int RandIndex;

	m_kBehavior.m_kPlayer.GetPlayableUnits(Teammates, true);

	while (Teammates.Length > 0)
	{
		// Randomize order so the same unit doesn't always get targeted.
		RandIndex = `SYNC_RAND(Teammates.Length);
		TargetUnit = Teammates[RandIndex];
		Teammates.Remove(RandIndex, 1);
		if (TargetUnit.IsUnitAffectedByEffectName(class'X2StatusEffects'.default.BurningName))
		{
			continue;
		}

		AdjacentTiles.Length = 0;
		m_kBehavior.GetMeleePointsAroundTile(TargetUnit.TileLocation, AdjacentTiles);
		// Also skip this unit if we are already adjacent to this unit.
		if (class'Helpers'.static.FindTileInList(m_kUnitState.TileLocation, AdjacentTiles) != INDEX_NONE)
		{
			continue;
		}
		foreach AdjacentTiles(Tile)
		{
			if (m_kBehavior.IsWithinMovementRange(Tile))
			{
				`LogAIBT("SetDestinationNextToUnburnedTeammate- Found Tile next to Unit# "$TargetUnit.ObjectID$".\n");
				m_kBehavior.m_vBTDestination = `XWORLD.GetPositionFromTileCoordinates(Tile);
				m_kBehavior.m_bBTDestinationSet = true;
				return BTS_SUCCESS;
			}
		}
	}
	return BTS_FAILURE;
}

function bt_status GroupWideExcludeEffect()
{
	m_kBehavior.BT_AddGroupEffectExclusion(SplitNameParam);
	return BTS_SUCCESS;
}

// Generic ability selector for units that cannot be given a custom behavior tree.  (Shadowbind units, etc)
function bt_status InitGenericAbilities()
{
	if (m_kBehavior.BT_InitGenericAbilities())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status ChooseGenericAbilityOption()
{
	if (m_kBehavior.BT_ChooseGenericAbilityOption())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetCurrOptionAsPreselectedAbility()
{
	if (m_kBehavior.BT_SetCurrOptionAsPreselectedAbility())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetPreselectedAbility()
{
	if (m_kBehavior.BT_SetPreselectedAbility(SplitNameParam))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status TrySelectGenericAbilityOption()
{
	if (m_kBehavior.BT_TrySelectGenericAbilityOption())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SelectPreselectedAbility()
{
	if (m_kBehavior.BT_SelectPreselectedAbility())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status RestrictToGASRange()
{
	if (m_kBehavior.BT_RestrictToGASRange())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status MoveCloserForGenericAbility()
{
	if (m_kBehavior.BT_MoveCloserForGenericAbility())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status SetDestinationSearchForTarget()
{
	if (m_kBehavior.BT_SetDestinationSearchForTarget())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status OverrideIdealRange()
{
	local float Override;
	if (m_ParamList.Length > 0)
	{
		Override = float(String(m_ParamList[0]));
		if (Override > 0)
		{
			m_kBehavior.BT_OverrideIdealRange(Override);
			return BTS_SUCCESS;
		}
		`LogAIBT("Invalid parameter for Ideal Range: " @m_ParamList[0]);
	}
	Override = float(String(SplitNameParam));
	if (Override > 0)
	{
		m_kBehavior.BT_OverrideIdealRange(Override);
		return BTS_SUCCESS;
	}
	`LogAIBT("Invalid parameter for OverrideIdealRange " @SplitNameParam);

	return BTS_FAILURE;
}

function bt_status RestrictToUnflanked()
{
	m_kBehavior.BT_RestrictMoveToUnflanked();
	return BTS_SUCCESS;
}

function bt_status RestrictToNonFlanking()
{
	m_kBehavior.BT_RestrictMoveToNonFlanking();
	return BTS_SUCCESS;
}

function bt_status RestrictToHighCover()
{
	m_kBehavior.BT_RestrictMoveToHighCover();
	return BTS_SUCCESS;

}

function bt_status SetPotentialTargetStackAll()
{
	if (m_kBehavior.BT_SetPotentialTargetStack(,true))
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status OverridePreferredDestinationToSpawnLocation()
{
	if (m_kBehavior.BT_OverridePreferredDestinationToSpawnLocation())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}

function bt_status OverridePreferredDestinationToPotentialTarget()
{
	if (m_kBehavior.BT_OverridePreferredDestinationToPotentialTarget())
	{
		return BTS_SUCCESS;
	}
	return BTS_FAILURE;
}


function bt_status FindDestinationTowardAoETarget()
{
	local TTile Tile;
	local XComWorldData World;

	if (m_kBehavior.TopAoETarget.Ability != '')
	{
		World = `XWORLD;
		Tile = World.GetTileCoordinatesFromPosition(m_kBehavior.TopAoETarget.Location);
		Tile = class'Helpers'.static.GetClosestValidTile(Tile); // Ensure the tile isn't occupied before finding a path to it.
		if (!class'Helpers'.static.GetFurthestReachableTileOnPathToDestination(Tile, Tile, m_kUnitState, false))
		{
			Tile = m_kBehavior.m_kUnit.m_kReachableTilesCache.GetClosestReachableDestination(Tile);
		}

		if (m_kBehavior.m_kUnit.m_kReachableTilesCache.IsTileReachable(Tile) && Tile != m_kUnitState.TileLocation)
		{
			m_kBehavior.m_vBTDestination = World.GetPositionFromTileCoordinates(Tile);
			m_kBehavior.m_bBTDestinationSet = true;
			return BTS_SUCCESS;
		}
	}
	`LogAIBT("No AoE Targets specified!  Need to call FindPotentialAoETargets-xxx before this node!");
	return BTS_FAILURE;
}

function bt_status MarkAsLastTrackingShotTarget()
{
	local AvailableTarget kTarget;
	kTarget = m_kBehavior.BT_GetBestTarget('TrackingShotMark');
	SetUnitValue_Internal('LastTrackingShotTarget', kTarget.PrimaryTarget.ObjectID, eCleanup_BeginTactical);
	return BTS_SUCCESS;
}

cpptext
{
	virtual void ResetObject();
};

//------------------------------------------------------------------------------------------------
defaultproperties
{
}