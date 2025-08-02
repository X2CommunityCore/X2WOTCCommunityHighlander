//---------------------------------------------------------------------------------------
//  FILE:    X2Helpers_DLC_Day60.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Helpers_DLC_Day60 extends Object
	config(GameCore)
	abstract;

var private config array<name> VALID_ABILITIES_WITH_ICARUS_DROP;
var private config array<name> VALID_ABILITIES_WITH_FREEZE_EFFECT;
var private config array<name> INVALID_ABILITIES_WITH_FREEZE_EFFECT;

struct AlienRulerAdditionalTags
{
	var int NumTimesAppeared;
	var name TacticalTag;
};

struct AlienRulerData
{
	var name AlienRulerTemplateName;
	var int ForceLevel;
	var name ActiveTacticalTag;
	var name DeadTacticalTag;
	var array<AlienRulerAdditionalTags> AdditionalTags;
	var int FreezeModifier;
	var int StunChanceModifier;
};

struct RulerEscapeHealthThreshold
{
	var int Difficulty;
	var int NumTimesAppeared;
	var float Threshold;
	var int DisabledEnemyThreshold;
	var int MinActionsThreshold;
};

struct RulerReappearChance
{
	var int Difficulty;
	var int MissionCount;
	var int PercentChance;
};

struct AlienRulerLocation
{
	var StateObjectReference RulerRef;
	var StateObjectReference MissionRef;
	var TDateTime ActivationTime;
	var bool bActivated;
	var bool bNeedsPopup;
};


//---------------------------------------------------------------------------------------
static function bool IsUnitAlienRuler(XComGameState_Unit UnitState)
{
	return UnitState.IsUnitAffectedByEffectName('AlienRulerPassive');
}

//---------------------------------------------------------------------------------------
static function float GetRulerEscapeHealthThreshold(XComGameState_Unit UnitState)
{
	local array<RulerEscapeHealthThreshold> AllHealthThresholds;
	local RulerEscapeHealthThreshold MaxAppearHealthThreshold;
	local int CampaignDifficulty, idx;

	AllHealthThresholds = class'XComGameState_AlienRulerManager'.default.RulerEscapeHealthThresholds;
	CampaignDifficulty = `TacticalDifficultySetting;

	for(idx = 0; idx < AllHealthThresholds.Length; idx++)
	{
		if(AllHealthThresholds[idx].Difficulty != CampaignDifficulty)
		{
			AllHealthThresholds.Remove(idx, 1);
			idx--;
		}
	}

	if(AllHealthThresholds.Length == 0)
	{
		return 0.0f;
	}

	MaxAppearHealthThreshold = AllHealthThresholds[0];

	for(idx = 0; idx < AllHealthThresholds.Length; idx++)
	{
		if(GetRulerNumAppearances(UnitState) == AllHealthThresholds[idx].NumTimesAppeared)
		{
			return AllHealthThresholds[idx].Threshold;
		}

		if(AllHealthThresholds[idx].NumTimesAppeared > MaxAppearHealthThreshold.NumTimesAppeared)
		{
			MaxAppearHealthThreshold = AllHealthThresholds[idx];
		}
	}

	return MaxAppearHealthThreshold.Threshold;
}

//---------------------------------------------------------------------------------------
static function bool RulerHealthBelowEscapeThreshold(XComGameState_Unit UnitState, optional out string DebugOut)
{
	local int CurrentHealth, EscapeHealth;

	CurrentHealth = UnitState.GetCurrentStat(eStat_HP);
	EscapeHealth = GetRulerEscapeHealth(UnitState);
	DebugOut = DebugOut@`ShowVar(CurrentHealth)@`ShowVar(EscapeHealth);
	return (CurrentHealth <= EscapeHealth);
}
//---------------------------------------------------------------------------------------
static function bool RulerDisabledEnoughEnemiesToEscape(XComGameState_Unit UnitState, optional out string DebugOut)
{
	local int DisabledCount, RulerActionsCount, StartingDisabledCount, NumDisabledThreshold, NumActionsThreshold;
	local UnitValue RulerActionsValue, StartingDisabledValue;
	
	DisabledCount = 0;
	RulerActionsCount = 0;

	if (UnitState.GetUnitValue('RulerActionsCount', RulerActionsValue))
	{
		RulerActionsCount = int(RulerActionsValue.fValue);
	}
	NumActionsThreshold = GetRulerMinActionsThreshold(UnitState);
	DebugOut = DebugOut@`ShowVar(RulerActionsCount)@`ShowVar(NumActionsThreshold);
	
	// Only start checking number of disabled units once the ruler has performed its minimum number of actions
	if (RulerActionsCount > NumActionsThreshold)
	{
		if (UnitState.GetUnitValue('StartingDisabledCount', StartingDisabledValue))
		{
			StartingDisabledCount = int(StartingDisabledValue.fValue);
		}
		DisabledCount = GetCurrentDisabledCount();
		NumDisabledThreshold = GetRulerDisabledEnemiesThreshold(UnitState);
		DebugOut = DebugOut@`ShowVar(StartingDisabledCount)@`ShowVar(DisabledCount)@`ShowVar(NumDisabledThreshold);
		if ((DisabledCount - StartingDisabledCount) >= NumDisabledThreshold)
		{
			return true;
		}
	}

	return false;
}

static function int GetCurrentDisabledCount()
{
	local XComGameStateHistory History;
	local XComGameState_Unit XComUnitState;
	local int DisabledCount;

	History = `XCOMHISTORY;
	DisabledCount = 0;

	foreach History.IterateByClassType(class'XComGameState_Unit', XComUnitState)
	{
		// Count number of XCom units currently disabled or dead.
		if (XComUnitState.GetTeam() == eTeam_XCom && XComUnitState.IsSoldier() && !XComUnitState.IsMindControlled()
			&& (!XComUnitState.IsAlive() || XComUnitState.IsIncapacitated()
			// Adding Stunned, Panic, Bound, and Freeze directly to this check since they are not currently considered in the IsIncapacitated fn.
			|| XComUnitState.IsStunned() || XComUnitState.IsPanicked()
			|| XComUnitState.IsUnitAffectedByEffectName(class'X2Ability_Viper'.default.BindSustainedEffectName)
			|| XComUnitState.IsUnitAffectedByEffectName(class'X2Effect_DLC_Day60Freeze'.default.EffectName)))
		{
			++DisabledCount;
		}
	}

	return DisabledCount;
}

static function int GetRulerDisabledEnemiesThreshold(XComGameState_Unit UnitState)
{
	local array<RulerEscapeHealthThreshold> AllHealthThresholds;
	local RulerEscapeHealthThreshold MaxAppearHealthThreshold;
	local int CampaignDifficulty, idx;

	AllHealthThresholds = class'XComGameState_AlienRulerManager'.default.RulerEscapeHealthThresholds;
	CampaignDifficulty = `TacticalDifficultySetting;

	for( idx = 0; idx < AllHealthThresholds.Length; idx++ )
	{
		if( AllHealthThresholds[idx].Difficulty != CampaignDifficulty )
		{
			AllHealthThresholds.Remove(idx, 1);
			idx--;
		}
	}

	if( AllHealthThresholds.Length == 0 )
	{
		return 3;
	}

	MaxAppearHealthThreshold = AllHealthThresholds[0];

	for( idx = 0; idx < AllHealthThresholds.Length; idx++ )
	{
		if( GetRulerNumAppearances(UnitState) == AllHealthThresholds[idx].NumTimesAppeared )
		{
			return AllHealthThresholds[idx].DisabledEnemyThreshold;
		}

		if( AllHealthThresholds[idx].NumTimesAppeared > MaxAppearHealthThreshold.NumTimesAppeared )
		{
			MaxAppearHealthThreshold = AllHealthThresholds[idx];
		}
	}

	return MaxAppearHealthThreshold.DisabledEnemyThreshold;
}

static function int GetRulerMinActionsThreshold(XComGameState_Unit UnitState)
{
	local array<RulerEscapeHealthThreshold> AllHealthThresholds;
	local RulerEscapeHealthThreshold MaxAppearHealthThreshold;
	local int CampaignDifficulty, idx;

	AllHealthThresholds = class'XComGameState_AlienRulerManager'.default.RulerEscapeHealthThresholds;
	CampaignDifficulty = `TacticalDifficultySetting;

	for (idx = 0; idx < AllHealthThresholds.Length; idx++)
	{
		if (AllHealthThresholds[idx].Difficulty != CampaignDifficulty)
		{
			AllHealthThresholds.Remove(idx, 1);
			idx--;
		}
	}

	if (AllHealthThresholds.Length == 0)
	{
		return 10;
	}

	MaxAppearHealthThreshold = AllHealthThresholds[0];

	for (idx = 0; idx < AllHealthThresholds.Length; idx++)
	{
		if (GetRulerNumAppearances(UnitState) == AllHealthThresholds[idx].NumTimesAppeared)
		{
			return AllHealthThresholds[idx].MinActionsThreshold;
		}

		if (AllHealthThresholds[idx].NumTimesAppeared > MaxAppearHealthThreshold.NumTimesAppeared)
		{
			MaxAppearHealthThreshold = AllHealthThresholds[idx];
		}
	}

	return MaxAppearHealthThreshold.MinActionsThreshold;
}

//---------------------------------------------------------------------------------------
static function bool CanRulerAttemptEscape(XComGameState_Unit UnitState)
{
	return true;
}

//---------------------------------------------------------------------------------------
static function int GetRulerNumEscapes(XComGameState_Unit UnitState)
{
	local XComGameState_Unit RulerState;
	local UnitValue EscapeValue;

	RulerState = GetRulerUnitState(UnitState);

	if(RulerState.GetUnitValue('NumEscapes', EscapeValue))
	{
		return int(EscapeValue.fValue);
	}

	return 0;
}

//---------------------------------------------------------------------------------------
static function int GetRulerNumAppearances(XComGameState_Unit UnitState)
{
	local XComGameState_Unit RulerState;
	local UnitValue AppearanceValue;

	RulerState = GetRulerUnitState(UnitState);

	if(RulerState.GetUnitValue('NumAppearances', AppearanceValue))
	{
		return int(AppearanceValue.fValue);
	}

	return 0;
}

//---------------------------------------------------------------------------------------
static function int GetRulerEscapeHealth(XComGameState_Unit UnitState)
{
	local XComGameState_Unit RulerState;
	local UnitValue EscapeHealth;

	RulerState = GetRulerUnitState(UnitState);

	if (RulerState.GetUnitValue('EscapeHealth', EscapeHealth))
	{
		return int(EscapeHealth.fValue);
	}

	return 0;
}

//---------------------------------------------------------------------------------------
static function int GetRulerFreezeModifier(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit RulerState;
	local StateObjectReference RulerRef;
	local int RulerIndex;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(UnitState.GetMyTemplateName());

	if (RulerRef.ObjectID == UnitState.ObjectID)
	{
		RulerState = UnitState;
	}
	else
	{
		RulerState = XComGameState_Unit(History.GetGameStateForObjectID(RulerRef.ObjectID));
	}

	if (RulerState != none)
	{
		RulerIndex = class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates.Find('AlienRulerTemplateName', RulerState.GetMyTemplateName());

		if (RulerIndex != INDEX_NONE)
		{
			return class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates[RulerIndex].FreezeModifier;
		}
	}

	return 0;
}

//---------------------------------------------------------------------------------------
static function int GetRulerStunChanceModifier(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit RulerState;
	local StateObjectReference RulerRef;
	local int RulerIndex;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(UnitState.GetMyTemplateName());

	if (RulerRef.ObjectID == UnitState.ObjectID)
	{
		RulerState = UnitState;
	}
	else
	{
		RulerState = XComGameState_Unit(History.GetGameStateForObjectID(RulerRef.ObjectID));
	}

	if (RulerState != none)
	{
		RulerIndex = class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates.Find('AlienRulerTemplateName', RulerState.GetMyTemplateName());

		if (RulerIndex != INDEX_NONE)
		{
			return class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates[RulerIndex].StunChanceModifier;
		}
	}

	return 0;
}

//---------------------------------------------------------------------------------------
// Only call on actual ruler unit
static function IncrementRulerNumEscapes(XComGameState_Unit UnitState)
{
	UnitState.SetUnitFloatValue('NumEscapes', float(GetRulerNumEscapes(UnitState)+1), eCleanup_Never);
}

//---------------------------------------------------------------------------------------
// Only call on actual ruler unit
static function IncrementRulerNumAppearances(XComGameState_Unit UnitState)
{
	UnitState.SetUnitFloatValue('NumAppearances', float(GetRulerNumAppearances(UnitState)+1), eCleanup_Never);
}

//---------------------------------------------------------------------------------------
// Only call on actual ruler unit
static function UpdateRulerEscapeHealth(XComGameState_Unit UnitState)
{
	local float Threshold, EscapeHealth, HealthThreshold;

	Threshold = GetRulerEscapeHealthThreshold(UnitState); // The percent of the rulers max health that must be lost to escape
	HealthThreshold = Threshold * UnitState.GetMaxStat(eStat_HP);
	EscapeHealth = max(UnitState.GetCurrentStat(eStat_HP) - HealthThreshold, 0.0);
	UnitState.SetUnitFloatValue('EscapeHealth', EscapeHealth, eCleanup_Never);
}

//---------------------------------------------------------------------------------------
// Given unit state return actual ruler version stored by strategy
static function XComGameState_Unit GetRulerUnitState(XComGameState_Unit UnitState)
{
	local XComGameStateHistory History;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit RulerState;
	local StateObjectReference RulerRef;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerRef = RulerMgr.GetAlienRulerReference(UnitState.GetMyTemplateName());

	if(RulerRef.ObjectID == UnitState.ObjectID)
	{
		return UnitState;
	}

	RulerState = XComGameState_Unit(History.GetGameStateForObjectID(RulerRef.ObjectID));

	if(RulerState != none)
	{
		return RulerState;
	}

	`Redscreen("Could not find valid ruler unit. @gameplay -mnauta");
	return UnitState;
}

//---------------------------------------------------------------------------------------
static function bool FindAvailableMidpointTile(TTile TileLocation, TTile TargetTile, Vector PreferredDirection, out TTile OutTileLocation)
{
	local TTile MidpointTile, BestTile;
	local XComWorldData World;
	local array<Actor> TileActors;
	local Vector ToNeighbor, DistanceFromMidV, DistanceFromSourceV;
	local float BestDot, DotToPreferred;
	local float DistanceFromMid, BestDistanceFromMid;
	local float DistanceFromSource, BestDistanceFromSource;
	local bool FoundTile;

	local Vector TestPosition;
	local XComCoverPoint CoverHandle;
	local bool bFlanked;

	local TTile MidpointFloorTile;

	World = `XWORLD;

	MidpointTile.X = (TileLocation.X + TargetTile.X) / 2.0;
	MidpointTile.Y = (TileLocation.Y + TargetTile.Y) / 2.0;
	MidpointTile.Z = (TileLocation.Z + TargetTile.Z) / 2.0;
	TestPosition = World.GetPositionFromTileCoordinates(MidpointTile);
	World.GetFloorTileForPosition(TestPosition, MidpointFloorTile, TRUE);
	TestPosition = World.GetPositionFromTileCoordinates(MidpointFloorTile);

	TileActors = World.GetActorsOnTile(MidpointFloorTile);
	
	World.GetCoverPoint(TestPosition, CoverHandle);
	bFlanked = class'XGUnitNativeBase'.static.DoesFlankCover(World.GetPositionFromTileCoordinates(TileLocation), CoverHandle);
	if( TileActors.Length == 0 && bFlanked && World.IsPositionOnFloorAndValidDestination(TestPosition) )
	{
		OutTileLocation = MidpointFloorTile;
		return true;
	}

	// Find a tile out of cover to pull to
	BestDot = -1.0f;
	BestDistanceFromMid = 10000000.0f;
	BestDistanceFromSource = 10000000.0f;
	FoundTile = false;
	for( BestTile.X = MidpointTile.X - 2; BestTile.X <= MidpointTile.X + 2; ++BestTile.X )
	{
		for( BestTile.Y = MidpointTile.Y - 2; BestTile.Y <= MidpointTile.Y + 2; ++BestTile.Y )
		{
			TileActors = World.GetActorsOnTile(BestTile);
			TestPosition = World.GetPositionFromTileCoordinates(BestTile);
			World.GetFloorTileForPosition(TestPosition, MidpointFloorTile, TRUE);
			TestPosition = World.GetPositionFromTileCoordinates(MidpointFloorTile);

			World.GetCoverPoint(TestPosition, CoverHandle);
			bFlanked = class'XGUnitNativeBase'.static.DoesFlankCover(World.GetPositionFromTileCoordinates(TileLocation), CoverHandle);
			// If the tile is empty
			
			if( TileActors.Length == 0 && bFlanked && World.IsPositionOnFloorAndValidDestination(TestPosition) )
			{
				ToNeighbor = Normal(World.GetPositionFromTileCoordinates(BestTile) - World.GetPositionFromTileCoordinates(TileLocation));
				DistanceFromMidV.X = BestTile.X - MidpointTile.X;
				DistanceFromMidV.Y = BestTile.Y - MidpointTile.Y;
				DistanceFromMidV.Z = BestTile.Z - MidpointTile.Z;
				DistanceFromMid = VSizeSq(DistanceFromMidV);

				DistanceFromSourceV.X = BestTile.X - TileLocation.X;
				DistanceFromSourceV.Y = BestTile.Y - TileLocation.Y;
				DistanceFromSourceV.Z = BestTile.Z - TileLocation.Z;
				DistanceFromSource = VSizeSq(DistanceFromSourceV);

				DotToPreferred = NoZDot(PreferredDirection, ToNeighbor);

				if( DotToPreferred >= BestDot )
				{
					if( DistanceFromMid <= 2 * BestDistanceFromMid || (DistanceFromMid == BestDistanceFromMid && DistanceFromSource <= 2 * BestDistanceFromSource) )
					{
						BestDot = DotToPreferred;
						BestDistanceFromMid = DistanceFromMid;
						BestDistanceFromSource = DistanceFromSource;
						OutTileLocation = BestTile;
						FoundTile = true;
					}
				}
			}
		}
	}

	// If we didn't find an out of cover tile try again to find the closest midpoint tile
	if( !FoundTile )
	{
		BestDot = -1.0f;
		BestDistanceFromMid = 10000000.0f;
		BestDistanceFromSource = 10000000.0f;
		for( BestTile.X = MidpointTile.X - 2; BestTile.X <= MidpointTile.X + 2; ++BestTile.X )
		{
			for( BestTile.Y = MidpointTile.Y - 2; BestTile.Y <= MidpointTile.Y + 2; ++BestTile.Y )
			{
				TileActors = World.GetActorsOnTile(BestTile);
				TestPosition = World.GetPositionFromTileCoordinates(BestTile);
				World.GetFloorTileForPosition(TestPosition, MidpointFloorTile, TRUE);
				TestPosition = World.GetPositionFromTileCoordinates(MidpointFloorTile);

				// If the tile is empty
				
				if( TileActors.Length == 0 && World.IsPositionOnFloorAndValidDestination(TestPosition) )
				{
					ToNeighbor = Normal(World.GetPositionFromTileCoordinates(BestTile) - World.GetPositionFromTileCoordinates(TileLocation));
					DistanceFromMidV.X = BestTile.X - MidpointTile.X;
					DistanceFromMidV.Y = BestTile.Y - MidpointTile.Y;
					DistanceFromMidV.Z = BestTile.Z - MidpointTile.Z;
					DistanceFromMid = VSizeSq(DistanceFromMidV);

					DistanceFromSourceV.X = BestTile.X - TileLocation.X;
					DistanceFromSourceV.Y = BestTile.Y - TileLocation.Y;
					DistanceFromSourceV.Z = BestTile.Z - TileLocation.Z;
					DistanceFromSource = VSizeSq(DistanceFromSourceV);

					DotToPreferred = NoZDot(PreferredDirection, ToNeighbor);

					if( DotToPreferred >= BestDot )
					{
						if( DistanceFromMid <= 2 * BestDistanceFromMid || (DistanceFromMid == BestDistanceFromMid && DistanceFromSource <= 2 * BestDistanceFromSource) )
						{
							BestDot = DotToPreferred;
							BestDistanceFromMid = DistanceFromMid;
							BestDistanceFromSource = DistanceFromSource;
							OutTileLocation = BestTile;
							FoundTile = true;
						}
					}
				}
			}
		}
	}

	return FoundTile;
}

static function bool AnyActionPointsRemainingForXCom()
{
	local XComGameState_Unit XComUnitState;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', XComUnitState)
	{
		if( XComUnitState.GetTeam() == eTeam_XCom && !XComUnitState.GetMyTemplate().bIsCosmetic && XComUnitState.IsAbleToAct() )
		{
			if( XComUnitState.NumActionPoints() > 0 )
			{
				return true;
			}
		}
	}
	return false;
}

static function BuildUIAlert_DLC_Day60(
	out DynamicPropertySet PropertySet,
	Name AlertName,
	delegate<X2StrategyGameRulesetDataStructures.AlertCallback> CallbackFunction,
	Name EventToTrigger,
	string SoundToPlay,
	bool bImmediateDisplay)
{
	class'X2StrategyGameRulesetDataStructures'.static.BuildDynamicPropertySet(PropertySet, 'UIAlert_DLC_Day60', AlertName, CallbackFunction, bImmediateDisplay, true, true, false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'EventToTrigger', EventToTrigger);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicStringProperty(PropertySet, 'SoundToPlay', SoundToPlay);
}

static function ShowHunterWeaponsPOIPopup(StateObjectReference POIRef)
{
	local XComHQPresentationLayer Pres;
	local DynamicPropertySet PropertySet;

	Pres = `HQPRES;

	BuildUIAlert_DLC_Day60(PropertySet, 'eAlert_HunterWeaponsScanningSite', Pres.POIAlertCB, '', "Geoscape_POIReveal", false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'POIRef', POIRef.ObjectID);
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

static function ShowNestPOIPopup(StateObjectReference POIRef)
{
	local XComHQPresentationLayer Pres;
	local DynamicPropertySet PropertySet;

	Pres = `HQPRES;

	BuildUIAlert_DLC_Day60(PropertySet, 'eAlert_NestScanningSite', Pres.POIAlertCB, '', "Geoscape_POIReveal", false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'POIRef', POIRef.ObjectID);
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

static function ShowHunterWeaponsPOICompletePopup(StateObjectReference POIRef)
{
	local XComHQPresentationLayer Pres;
	local DynamicPropertySet PropertySet;

	Pres = `HQPRES;

	BuildUIAlert_DLC_Day60(PropertySet, 'eAlert_HunterWeaponsScanComplete', Pres.POICompleteCB, '', "Geoscape_POIReached", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'POIRef', POIRef.ObjectID);
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

static function ShowNestPOICompletePopup(StateObjectReference POIRef)
{
	local XComHQPresentationLayer Pres;
	local DynamicPropertySet PropertySet;

	Pres = `HQPRES;

	BuildUIAlert_DLC_Day60(PropertySet, 'eAlert_NestScanComplete', Pres.POICompleteCB, '', "Geoscape_POIReached", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'POIRef', POIRef.ObjectID);
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

static function ShowHunterWeaponsAvailablePopup()
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert_DLC_Day60(PropertySet, 'eAlert_HunterWeaponsAvailable', HunterWeaponsCB, 'HunterWeaponsPopup', "Geoscape_CrewMemberLevelledUp", false);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'ItemTemplate', 'HunterRifle_CV_Schematic');
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

static function ShowRulerGuardingFacilityPopup(StateObjectReference MissionRef)
{
	local DynamicPropertySet PropertySet;
	
	BuildUIAlert_DLC_Day60(PropertySet, 'eAlert_RulerGuardingFacility', RulerGuardianFacilityCB, 'OnRulerGuardingFacilityPopup', "GeoscapeFanfares_AlienFacility", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'MissionRef', MissionRef.ObjectID);
	class'XComPresentationLayerBase'.static.QueueDynamicPopup(PropertySet);
}

simulated static function RulerGuardianFacilityCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_MissionSite MissionSite;

	if (eAction == 'eUIAction_Accept' && !`SCREENSTACK.IsInStack(class'UIMission_AlienFacility'))
	{
		MissionSite = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'MissionRef')));
		`HQPRES.UIMission_AlienFacility(MissionSite, bInstant);
	}
}

simulated function HunterWeaponsCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom ArmoryState;
	
	if (eAction == 'eUIAction_Accept')
	{
		if (`GAME.GetGeoscape().IsScanning())
			`HQPRES.StrategyMap2D.ToggleScan();

		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		ArmoryState = XComHQ.GetFacilityByName('Hangar');
		ArmoryState.GetMyTemplate().SelectFacilityFn(ArmoryState.GetReference(), true);
	}
}

// Return unvalidated corner tiles around a given tile, with a given distance in tiles
static function GetSideAndCornerTiles(out array<TTile> CornerTiles_Out, TTile CenterTile, int TileDistance, int ExtraSideOffset=-1)
{
	local TTile Tile;
	local int xOffset, yOffset, i;

	// Pick corner points.  
	for( i = 0; i < 4; i++ )
	{
		// Add Corner Tiles			//  0,  1,  2,  3
		xOffset = (i % 2) * 2 - 1;	// -1,  1, -1,  1
		yOffset = (i / 2) * 2 - 1;	// -1, -1,  1,  1
		Tile = CenterTile;
		Tile.X += xOffset * TileDistance;
		Tile.Y += yOffset * TileDistance;
		CornerTiles_Out.AddItem(Tile);

		if( ExtraSideOffset >= 0 )
		{
			// Add Side tiles - xOffset =  -1,  1,  0,  0
			//					yOffest =   0,  0, -1,  1
			if( i < 2 )
			{
				yOffset = 0;
			}
			else
			{
				yOffset = xOffset;
				xOffset = 0;
			}
			Tile = CenterTile;
			Tile.X += xOffset * (TileDistance + ExtraSideOffset);
			Tile.Y += yOffset * (TileDistance + ExtraSideOffset);
			CornerTiles_Out.AddItem(Tile);
		}
	}

}

static function bool GetEscapeTiles(out array<TTile> EscapeArea, XComGameState_Unit RulerUnitState)
{
	local XComGameState_Effect EscapeEffect;
	local TTile EscapeTile;
	local Vector EscapePos;
	local XComWorldData World;
	World = `XWORLD;
	// Find the escape tile.
	EscapeEffect = RulerUnitState.GetUnitAffectedByEffectState(class'X2Ability_DLC_Day60AlienRulers'.default.CallForEscapeEffectName);
	if( EscapeEffect == None )
	{
		`LogAIBT("Unable to find escape effect on unit.");
		return false;
	}
	if( EscapeEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations.Length < 1 )
	{
		`LogAIBT("Unable to find escape target location from context.");
		return false;
	}
	EscapePos = EscapeEffect.ApplyEffectParameters.AbilityInputContext.TargetLocations[0];
	EscapeTile = World.GetTileCoordinatesFromPosition(EscapePos);
	EscapeArea.AddItem(EscapeTile);
	GetSideAndCornerTiles(EscapeArea, EscapeTile, 1, 0);

	return true;
}

static function bool HasPathToArea(array<TTile> TileArea, XComGameState_Unit UnitState, optional out array<TTile> PathTiles)
{
	local TTile Tile;
	local XComWorldData World;
	local vector EndPos;
	local XGUnit UnitVisualizer;
	World = `XWORLD;

	UnitVisualizer = XGUnit(UnitState.GetVisualizer());
	// First check the reachable tile cache to see if any tiles are reachable.
	foreach TileArea(Tile)
	{
		PathTiles.Length = 0;
		if( UnitVisualizer.m_kReachableTilesCache.BuildPathToTile(Tile, PathTiles) )
		{
			if( PathTiles.Length > 0 )
			{
				return true;
			}
		}
	}

	// Return true if a paths to any tiles in the array succeed.
	foreach TileArea(Tile)
	{
		EndPos = World.GetPositionFromTileCoordinates(Tile);
		if( World.IsPositionOnFloorAndValidDestination(EndPos, UnitState) )
		{
			if( class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, Tile, PathTiles, false) )
			{
				// Found a valid path. 
				return true;
			}
		}
		PathTiles.Length = 0; // Clear path.
	}
	// No valid paths found to target area (or no alert data found).
	return false;
}

static function bool IsXPackIntegrationEnabled()
{
	local XComGameState_CampaignSettings CampaignSettings;

	CampaignSettings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	return CampaignSettings.HasIntegratedDLCEnabled();
}

// Loop over the ability templates (for all difficulty levels) and add any conditions
// that need to pass allowing the ability to be used
static function OnPostAbilityTemplatesCreated()
{
	local X2AbilityTemplateManager AbilityTemplateMgr;
	local array<name> AbilityTemplateNames;
	local name AbilityTemplateName;
	local array<X2AbilityTemplate> AbilityTemplates;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition_UnitEffects ArchonExcludeEffects, FreezeExcludeEffects;
	local X2Effect_RemoveEffects JumpUpEffectRemoval, FreezeRemoval, StasisRemoval;
	local X2Effect EffectIterator;
	local X2Effect_PersistentTraversalChange JumpUpTraversalRemoval;

	AbilityTemplateMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	
	// The shooter must not already be grabbing a unit
	ArchonExcludeEffects = new class'X2Condition_UnitEffects';
	ArchonExcludeEffects.AddExcludeEffect(class'X2Ability_DLC_60ArchonKing'.default.IcarusDropGrabberEffectName, 'AA_UnitIsBound');
	ArchonExcludeEffects.AddExcludeEffect(class'X2Ability_DLC_60ArchonKing'.default.IcarusDropGrabbeeEffect_SustainedName, 'AA_UnitIsBound');

	FreezeExcludeEffects = new class'X2Condition_UnitEffects';
	FreezeExcludeEffects.AddExcludeEffect(class'X2Effect_DLC_Day60Freeze'.default.EffectName, 'AA_UnitIsFrozen');

	FreezeRemoval = new class'X2Effect_RemoveEffects';
	FreezeRemoval.EffectNamesToRemove.AddItem(class'X2Effect_DLC_Day60Freeze'.default.EffectName);

	JumpUpTraversalRemoval = new class'X2Effect_PersistentTraversalChange';
	JumpUpTraversalRemoval.BuildPersistentEffect(1, true, true, false);
	JumpUpTraversalRemoval.AddTraversalChange(eTraversal_JumpUp, false);
	JumpUpTraversalRemoval.EffectName = 'CarryUnitJumpTraversalRemoval';
	JumpUpTraversalRemoval.DuplicateResponse = eDupe_Ignore;

	JumpUpEffectRemoval = new class'X2Effect_RemoveEffects';
	JumpUpEffectRemoval.EffectNamesToRemove.AddItem('CarryUnitJumpTraversalRemoval');
	
	// Loop over all ability names
	AbilityTemplateMgr.GetTemplateNames(AbilityTemplateNames);
	foreach AbilityTemplateNames(AbilityTemplateName)
	{		
		AbilityTemplates.Length = 0;
		AbilityTemplateMgr.FindAbilityTemplateAllDifficulties(AbilityTemplateName, AbilityTemplates);

		foreach AbilityTemplates(AbilityTemplate)
		{
			if( !AbilityTemplate.bCommanderAbility )
			{
				if( default.VALID_ABILITIES_WITH_ICARUS_DROP.Find(AbilityTemplateName) == INDEX_NONE )
				{
					AbilityTemplate.AbilityShooterConditions.AddItem(ArchonExcludeEffects);
				}

				// This Ability is not allowed to trigger when Frozen if:
				// The Ability Template has a Player Input Trigger
				// AND
				// The Ability Template name is not in the Allowed Abilities array
				// OR
				// The Ability Template name is in the Not Allowed Abilities array
				if( (AbilityTemplate.HasTrigger('X2AbilityTrigger_PlayerInput') &&
					(default.VALID_ABILITIES_WITH_FREEZE_EFFECT.Find(AbilityTemplateName) == INDEX_NONE)) ||
					(default.INVALID_ABILITIES_WITH_FREEZE_EFFECT.Find(AbilityTemplateName) != INDEX_NONE) )
				{
					AbilityTemplate.AbilityShooterConditions.AddItem(FreezeExcludeEffects);
				}
			}

			switch(AbilityTemplateName)
			{
			case 'CarryUnit':
				AbilityTemplate.AddShooterEffect(JumpUpTraversalRemoval);
				break;
			case 'PutDownUnit':
				AbilityTemplate.AddShooterEffect(JumpUpEffectRemoval);
				break;
			case 'SKULLMINEAbility':
			case 'Knockout':
			case 'SKULLJACKAbility':
				AbilityTemplate.AddTargetEffect(FreezeRemoval);
				break;
			case 'Stasis':
				foreach AbilityTemplate.AbilityTargetEffects(EffectIterator)
				{
					StasisRemoval = X2Effect_RemoveEffects(EffectIterator);
					if (StasisRemoval != none)
					{
						StasisRemoval.EffectNamesToRemove.AddItem(class'X2Ability_DLC_60ArchonKing'.default.IcarusDropGrabbeeEffect_SustainedName);
						StasisRemoval.EffectNamesToRemove.AddItem(class'X2Ability_DLC_Day60ViperKing'.default.KingBindSustainedEffectName);
						break;
					}
				}
				break;
			case 'Justice':
			case 'StunStrike':
				AbilityTemplate.AbilityTargetConditions.AddItem(FreezeExcludeEffects);
				break;
			}
		}
	}
}

static function OnPostCharacterTemplatesCreated()
{
	local X2CharacterTemplateManager CharacterTemplateMgr;
	local X2CharacterTemplate SoldierTemplate;
	local array<X2DataTemplate> DataTemplates;
	local int i;

	CharacterTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	
	CharacterTemplateMgr.FindDataTemplateAllDifficulties('Soldier', DataTemplates);
	for( i = 0; i < DataTemplates.Length; ++i )
	{
		SoldierTemplate = X2CharacterTemplate(DataTemplates[i]);
		if( SoldierTemplate != none )
		{
			SoldierTemplate.Abilities.AddItem('Interact_DLC2Transmitter');
		}
	}

	CharacterTemplateMgr.FindDataTemplateAllDifficulties('NestCentral', DataTemplates);
	for( i = 0; i < DataTemplates.Length; ++i )
	{
		SoldierTemplate = X2CharacterTemplate(DataTemplates[i]);
		if( SoldierTemplate != none )
		{
			SoldierTemplate.Abilities.AddItem('Interact_DLC2Transmitter');
		}
	}
}

static function OnPostTechTemplatesCreated()
{
	local StrategyRequirement AltTechReq, AltItemReq;

	AltTechReq.RequiredTechs.AddItem('RAGESuit');
	AddAltRequirement(AltTechReq, 'HeavyWeapons');

	AltItemReq.RequiredItems.AddItem('HeavyAlienArmorMk2_Schematic');
	AddAltRequirement(AltItemReq, 'AdvancedHeavyWeapons');
}

static function AddAltRequirement(StrategyRequirement AltReq, Name BaseTemplateName)
{
	local X2StrategyElementTemplateManager StrategyTemplateMgr;
	local X2TechTemplate TechTemplate;
	local array<X2DataTemplate> DataTemplates;
	local int i;

	StrategyTemplateMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	StrategyTemplateMgr.FindDataTemplateAllDifficulties(BaseTemplateName, DataTemplates);
	
	for (i = 0; i < DataTemplates.Length; ++i)
	{
		TechTemplate = X2TechTemplate(DataTemplates[i]);
		if (TechTemplate != none)
		{			
			TechTemplate.AlternateRequirements.AddItem(AltReq);
		}
	}
}