//-----------------------------------------------------------
//
//-----------------------------------------------------------
class Helpers extends Object
	dependson(XComGameStateVisualizationMgr)
	abstract
	native;

struct native CamCageResult
{
	var int                 iCamZoneID;
	var int                 iCamZoneBlocked;
};

static function string GetMessageFromDamageModifierInfo(DamageModifierInfo ModInfo)
{
	local X2Effect_Persistent EffectTemplate;

	if (ModInfo.bIsRupture)
		return class'X2StatusEffects'.default.RupturedFriendlyName;

	EffectTemplate = X2Effect_Persistent(class'X2Effect'.static.GetX2Effect(ModInfo.SourceEffectRef));
	if (EffectTemplate != None)
		return EffectTemplate.GetSpecialDamageMessageName();

	return "";
}

static function bool IsObjectiveTarget(int ObjectID, optional XComGameState CheckGameState)
{
	local XComGameState_BaseObject ObjectState, ObjectiveInfo;

	if (ObjectID > 0)
	{
		if (CheckGameState != none)
			ObjectState = CheckGameState.GetGameStateForObjectID(ObjectID);
		if (ObjectState == none)
			ObjectState = `XCOMHISTORY.GetGameStateForObjectID(ObjectID);

		if (ObjectState != none)
		{
			ObjectiveInfo = ObjectState.FindComponentObject(class'XComGameState_ObjectiveInfo');
			return ObjectiveInfo != none;
		}
	}
	return false;
}

native static final function float S_EvalInterpCurveFloat( const out InterpCurveFloat Curve, float AlphaValue );
native static final function vector S_EvalInterpCurveVector( const out InterpCurveVector Curve, float AlphaValue );

native static final function rotator RotateLocalByWorld( rotator Local, rotator ByWorld );

native static final function bool isVisibilityBlocked(vector vFrom, vector vTo, Actor SourceActor, out vector vHitLoc, optional bool bVolumesOnly = false);

native static final function OverridePPSettings(out PostProcessSettings BasePPSettings, out PostProcessSettings NewPPSettings, float Alpha);

native static final function WorldInfo GetWorldInfo();

static final function OutputMsg( string msg, optional name logCategory)
{
    local Console PlayerConsole;
    local LocalPlayer LP;

	LP = LocalPlayer( GetWorldInfo().GetALocalPlayerController().Player );
	if( ( LP != none )  && ( LP.ViewportClient.ViewportConsole != none ) )
	{
		PlayerConsole = LP.ViewportClient.ViewportConsole;
		PlayerConsole.OutputText(msg);
	}
	
	//Output to log just encase..
	`log(msg, true, logCategory);
}

static simulated native function SetGameRenderingEnabled(bool Enabled, int iFrameDelay);

static native final function int NextAbilityID();

/**
 * GetUVCoords - Used to get the UV intersection of a ray with a static mesh.
 * MeshComp - The mesh component you want to test intersection with
 * vWorldStartPos - The origin point of the line check in world space
 * vWorldDirection - The direction of the line check in world space
 * Return value - FVector2D - return the UVs of the intersection point. Returns (-1,-1) if we failed intersection.
 */
static native function vector2d GetUVCoords(StaticMeshComponent MeshComp, vector vWorldStartPos, vector vWorldDirection);

native static final function bool AreVectorsDifferent(const out Vector v1, const out Vector v2, float fTolerance);

/**
 * Returns the concatenated hashes of all the important packages we care the network to verify between client and server.
 */
native static final function string NetGetVerifyPackageHashes();

static native function bool NetAreModsInstalled();
static native function bool NetAreInstalledDLCsRankedFriendly();
static native function bool NetGameDataHashesAreValid();
static native function bool NetAllRankedGameDataValid();
static native function int  NetGetInstalledMPFriendlyDLCHash();
static native function int  NetGetInstalledModsHash();
static native function string NetGetMPINIHash();
static native function array<string>     GetInstalledModNames();
static native function array<string>     GetInstalledDLCNames();
static native function bool IsDevConsoleEnabled();

static native function SetOnAllActorsInLevel(LevelStreaming StreamedLevel, bool bHidden, bool bCollision);

static native function SetOnAllActorsInLevelWithTag(LevelStreaming StreamedLevel, name TagToMatch, bool bHidden, bool bCollision);

static native function CollectDynamicShadowLights(LevelStreaming StreamedLevel);

static native function ToggleDynamicShadowLights(LevelStreaming StreamedLevel, bool bTurnOn);

native static final function float CalculateStatContestBinomialDistribution(float AttackerRolls, float AttackerRollSuccessChance, float DefenderRolls, float DefenderRollSuccessChance);

static native function StaticMesh ConstructRegionActor(Texture2D RegionTexture);

static native function Vector GetRegionCenterLocation(StaticMeshComponent MeshComp, bool bUseTransform);

static native function bool IsInRegion(StaticMeshComponent MeshComp, Vector Loc, bool bUseTransform);

static native function Vector GetRegionBorderIntersectionPoint(StaticMeshComponent MeshComp, Vector InnerPoint, Vector OuterPoint);

static native function GenerateCumulativeTriangleAreaArray(StaticMeshComponent MeshComp, out array<float> CumulativeTriangleArea);

static native function Vector GetRandomPointInRegionMesh(StaticMeshComponent MeshComp, int Tri, bool bUseTransform);

// Check if unit is in range (Cylindrical range - Z-diff checked within MaxZTileDist, then 2D distance check.)
static native function bool IsTileInRange(const out TTile TileA, const out TTile TileB, float MaxTileDistSq, float MaxZTileDiff=3.0f);

// Test if the Target Unit is within the required min/max ranges and angle of the source unit. If MinRange is 0, no minimum range is
// required. If MaxRange is 0, no maximum range is required. If MaxAngle is 360 or greater, then no angle check is required.
static native function bool IsUnitInRange(const ref XComGameState_Unit SourceUnit, const ref XComGameState_Unit TargetUnit,
										  float MinRange = 0.0f, float MaxRange = 0.0f, float MaxAngle = 360.0f);

static native function bool IsUnitInRangeFromLocations(const ref XComGameState_Unit SourceUnit, const ref XComGameState_Unit TargetUnit,
										  const out TTile SourceTile, const out TTile TargetTile, 
										  float MinRange = 0.0f, float MaxRange = 0.0f, float MaxAngle = 360.0f);

static function bool HasAvailableLootInternal(Lootable LootableObject, StateObjectReference LooterRef)
{
	local XComGameState_Item Item;
	local XComGameState_Unit Looter;
	local XComGameStateHistory History;
	local Array<StateObjectReference> ItemRefs;
	local int LootIndex;

	History = `XCOMHISTORY;

	Looter = XComGameState_Unit(History.GetGameStateForObjectID(LooterRef.ObjectID));
	if( Looter != None )
	{
		ItemRefs = LootableObject.GetAvailableLoot();
		for( LootIndex = 0; LootIndex < ItemRefs.Length; ++LootIndex )
		{
			Item = XComGameState_Item(History.GetGameStateForObjectID(ItemRefs[LootIndex].ObjectID));
			if( Item != none )
			{
				if( Item.GetMyTemplate().CanBeLootedByUnit(Item, Looter, LootableObject) )
				{
					return true;
				}
			}
		}
	}

	return false;
}

static function bool GetLootInternal(Lootable LootableObject, StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	local XComGameState_Item Item;
	local XComGameState_Unit Looter;
	local X2EquipmentTemplate EquipmentTemplate;
	local EInventorySlot DestinationSlot;

	Looter = XComGameState_Unit(ModifyGameState.ModifyStateObject(class'XComGameState_Unit', LooterRef.ObjectID));

	Item = XComGameState_Item(ModifyGameState.ModifyStateObject(class'XComGameState_Item', ItemRef.ObjectID));

	if( Looter != none && Item != none )
	{
		DestinationSlot = eInvSlot_Backpack;
		EquipmentTemplate = X2EquipmentTemplate(Item.GetMyTemplate());
		if( EquipmentTemplate != none && EquipmentTemplate.InventorySlot == eInvSlot_Mission )
			DestinationSlot = eInvSlot_Mission;
		
		//start issue #114: pass along item state in case a mod wants to interact with this in some way.
		if( Looter.CanAddItemToInventory(Item.GetMyTemplate(), DestinationSlot, ModifyGameState, Item.Quantity, Item) && 
			Item.GetMyTemplate().CanBeLootedByUnit(Item, Looter, LootableObject) )
		{
		//end issue #114
			if( Looter.AddItemToInventory(Item, DestinationSlot, ModifyGameState) )
			{
				LootableObject.RemoveLoot(ItemRef, ModifyGameState);
				`XEVENTMGR.TriggerEvent('ItemLooted', Item, Looter, ModifyGameState);
				return true;
			}
		}
	}
	return false;
}


/**
* LeaveLoot
* Remove item from Looter's backpack and place in Lootable object.
*/
static function bool LeaveLootInternal(Lootable LootableObject, StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	local XComGameState_Item Item;
	local XComGameState_Unit Looter;

	Looter = XComGameState_Unit(ModifyGameState.ModifyStateObject(class'XComGameState_Unit', LooterRef.ObjectID));

	Item = XComGameState_Item(ModifyGameState.ModifyStateObject(class'XComGameState_Item', ItemRef.ObjectID));

	if( Looter != none && Item != none )
	{
		if( Looter.RemoveItemFromInventory(Item, ModifyGameState) )
		{
			LootableObject.AddLoot(ItemRef, ModifyGameState);
			return true;
		}
	}
	return false;
}

static function VisualizeLootFountainInternal(Lootable LootableObject, XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local VisualizationActionMetadata ActionMetadata;
	local int ThisObjectID;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability AbilityContext;
	local XGUnit ShootingUnit, TargetUnit;
	local VisualizationActionMetadata ShootersBuildTrack, TargetBuildTrack;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local XComGameState_Item WeaponUsed;
	local bool bOutOfAmmoVOWillPlay;
	local X2Action_LootFountain LootFountain;

	Context = VisualizeGameState.GetContext();
	ThisObjectID = XComGameState_BaseObject(LootableObject).ObjectID;

	// loot fountain
	History = `XCOMHISTORY;
	History.GetCurrentAndPreviousGameStatesForObjectID(ThisObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);

	if( ActionMetadata.StateObject_OldState == None || Lootable(ActionMetadata.StateObject_OldState).HasLoot() )
	{
		ActionMetadata.VisualizeActor = History.GetVisualizer(ThisObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
		LootFountain = X2Action_LootFountain(class'X2Action_LootFountain'.static.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded));
	}


	// Make the shooter speak a line of VO, e.g. "Looks like something over here."
	AbilityContext = XComGameStateContext_Ability(Context);
	if (AbilityContext != None)
	{
		// Detect if an out-of-ammo VO cue will play. The detection logic here matches the same in X2Action_EnterCover
		bOutOfAmmoVOWillPlay = false;
		if( AbilityContext.InputContext.AbilityTemplateName == 'StandardShot')
		{
			WeaponUsed = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
			if( WeaponUsed != None )
			{
				bOutOfAmmoVOWillPlay = ( WeaponUsed.Ammo <= 1 );
			}
		}


		ShootingUnit = XGUnit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID).GetVisualizer());
		if (ShootingUnit != none)
		{
			// prepare the track
			History.GetCurrentAndPreviousGameStatesForObjectID(ShootingUnit.ObjectID, ShootersBuildTrack.StateObject_OldState, ShootersBuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
			ShootersBuildTrack.VisualizeActor = ShootingUnit;

			// play the loot VO line, only if we know it won't be stomped by an out-of-ammo line
			if (!bOutOfAmmoVOWillPlay && !LootableObject.HasPsiLoot())
			{
				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ShootersBuildTrack, Context, false, LootFountain));
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'LootSpotted', eColor_Good);
			}
		}


		TargetUnit = XGUnit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID).GetVisualizer());
		if( TargetUnit != none )
		{
			// add target visualization sentinel
			History.GetCurrentAndPreviousGameStatesForObjectID(TargetUnit.ObjectID, TargetBuildTrack.StateObject_OldState, TargetBuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
			TargetBuildTrack.VisualizeActor = TargetUnit;			
		}
	}
}

/**
* AcquireAllLoot
* Award all loot held by this lootable to the player.
*/
static function AcquireAllLoot(Lootable TheLootable, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	local int LootIndex;
	local array<StateObjectReference> LootRefs;
	local bool AnyLootGotten;

	AnyLootGotten = false;
	LootRefs = TheLootable.GetAvailableLoot();

	for( LootIndex = 0; LootIndex < LootRefs.Length; ++LootIndex )
	{
		AnyLootGotten = TheLootable.GetLoot(LootRefs[LootIndex], LooterRef, ModifyGameState) || AnyLootGotten;
	}
}

static function int GetNumCiviliansKilled(optional out int iTotal, optional bool bPostMission = false)
{
	local int iKilled, i;
	local array<XComGameState_Unit> arrUnits;
	local XGBattle_SP Battle;
	local XComGameState_BattleData BattleData;

	Battle = XGBattle_SP(`BATTLE);
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if( Battle != None )
	{
		Battle.GetCivilianPlayer().GetOriginalUnits(arrUnits);

		for(i = 0; i < arrUnits.Length; i++)
		{
			if(arrUnits[i].GetMyTemplate().bIsAlien)
			{
				arrUnits.Remove(i, 1);
				i--;
			}
		}

		iTotal = arrUnits.Length;

		for( i = 0; i < iTotal; i++ )
		{
			if(arrUnits[i].IsDead())
			{
				iKilled++;
			}
			else if(bPostMission && !arrUnits[i].bRemovedFromPlay)
			{
				if(!BattleData.bLocalPlayerWon)
				{
					iKilled++;
				}
			}
		}
	}
	return iKilled;
}

static function int GetNumResistanceSoldiersKilled(optional out int iTotal, optional bool bPostMission = false)
{
	local int iKilled, i;
	local array<XComGameState_Unit> arrUnits;
	local XGBattle_SP Battle;
	local XComGameState_BattleData BattleData;

	Battle = XGBattle_SP(`BATTLE);
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if(Battle != None)
	{
		Battle.GetResistancePlayer().GetOriginalUnits(arrUnits);

		for(i = 0; i < arrUnits.Length; i++)
		{
			if(arrUnits[i].GetMyTemplate().bIsAlien)
			{
				arrUnits.Remove(i, 1);
				i--;
			}
		}

		iTotal = arrUnits.Length;

		for(i = 0; i < iTotal; i++)
		{
			if(arrUnits[i].IsDead())
			{
				iKilled++;
			}
			else if(bPostMission && !arrUnits[i].bRemovedFromPlay)
			{
				if(!BattleData.bLocalPlayerWon)
				{
					iKilled++;
				}
			}
		}
	}
	return iKilled;
}

static function int GetRemainingXComActionPoints(bool CheckSkipped, optional out array<StateObjectReference> UnitsWithActionPoints)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local int TotalPoints, Points;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState, , , )
	{
		if( UnitState.GetTeam() == eTeam_XCom 
		   && UnitState.IsAbleToAct() 
		   && !UnitState.bRemovedFromPlay
		   && !UnitState.GetMyTemplate().bIsCosmetic )
		{
			if( CheckSkipped )
			{
				Points = UnitState.SkippedActionPoints.Length;
			}
			else
			{
				Points = UnitState.ActionPoints.Length;
			}

			if( Points > 0 )
			{
				TotalPoints += Points;
				`LogAI("Adding Action Points from unit"@UnitState.ObjectID@":"@Points);
				UnitsWithActionPoints.AddItem(UnitState.GetReference());
			}
		}
	}
	return TotalPoints;
}

static function bool FindAvailableNeighborTile(const out TTile HomeTile, out TTile AvailableTile)
{
	local TTile NeighborTileLocation;
	local XComWorldData World;
	local array<Actor> TileActors;

	World = `XWORLD;
	NeighborTileLocation = HomeTile;

	for (NeighborTileLocation.X = HomeTile.X - 1; NeighborTileLocation.X <= HomeTile.X + 1; ++NeighborTileLocation.X)
	{
		for (NeighborTileLocation.Y = HomeTile.Y - 1; NeighborTileLocation.Y <= HomeTile.Y + 1; ++NeighborTileLocation.Y)
		{
			TileActors = World.GetActorsOnTile(NeighborTileLocation);

			// If the tile is empty and is on the same z as this unit's location
			if ((TileActors.Length == 0) && (World.GetFloorTileZ(NeighborTileLocation, false) == World.GetFloorTileZ(HomeTile, false)))
			{
				AvailableTile = NeighborTileLocation;
				return true;
			}
		}
	}

	return false;
}

// Validate tile to fit in the map and avoid NoSpawn locations.
static function TTile GetClosestValidTile(TTile Tile)
{
	local XComWorldData World;
	local vector ValidLocation;
	World = `XWORLD;
	ValidLocation = World.GetPositionFromTileCoordinates(Tile);
	ValidLocation = World.FindClosestValidLocation(ValidLocation, false, false, true);
	return World.GetTileCoordinatesFromPosition(ValidLocation);
}

static native function bool GetFurthestReachableTileOnPathToDestination(out TTile BestTile_out, TTile DestinationTile, XComGameState_Unit UnitState, bool bAllowDash = true, bool bLimitedSearch=false, optional array<TTile> ExclusionTiles);
static native function bool GetFurthestReachableTileOnPath(out TTile FurthestReachable, array<TTile> Path, XComGameState_Unit UnitState, bool bAllowDash=true, optional array<TTile> ExclusionTiles);

static function float DistanceBetweenTiles(TTile TileA, TTile TileB, bool bSquared=true)
{
	local XComWorldData World;
	local vector LocA, LocB;
	World = `XWORLD;
	LocA = World.GetPositionFromTileCoordinates(TileA);
	LocB = World.GetPositionFromTileCoordinates(TileB);

	if (bSquared)
	{
		return VSizeSq(LocA - LocB);
	}

	return VSize(LocA - LocB);
}

static native function int FindTileInList(TTile Tile, const out array<TTile> List);
static native function RemoveTileSubset(out array<TTile> ResultList, const out array<TTile> Superset, const out array<TTile> Subset);
static native function bool GetTileIntersection(out array<TTile> ResultList, const out array<TTile> SetA, const out array<TTile> SetB);
static native function bool GetTileUnion(out array<TTile> ResultList, const out array<TTile> SetA, const out array<TTile> SetB, bool bAllowDuplicates=false);
static native function bool VectorContainsNaNOrInfinite(Vector V);

// Find all adjacent tiles to target that are valid for melee attacking.  This only looks at tiles adjacent to the target.
// ( Currently written only for attackers of UnitSize 1. )
static native function bool FindTilesForMeleeAttack(XComGameState_Unit Target, out Array<TTile> Tiles);

// Pulled GetOverwatchers code out of VisibilityHelpers class to be reused for checking all overwatchers within a specified area.
static function GetOverwatchersFromList( int TargetStateObjectID, // Unit to test against for IsEnemy check.
										out array<StateObjectReference> OutOverwatchingEnemies, // Input & output array.
										optional int StartAtHistoryIndex = -1,
										bool bSkipConcealed = false,
										optional array<Name> ValidReserveTypes)
{
	local int Index;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local bool bReserveActionPointsValid;
	local Name ReserveType;

	History = `XCOMHISTORY;
	// By default we only look at overwatchers. (Skip suppression/KillZone/Bladestorm)
	if (ValidReserveTypes.Length == 0)
	{
		ValidReserveTypes.AddItem(class'X2Effect_ReserveOverwatchPoints'.default.ReserveType);
		ValidReserveTypes.AddItem(class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint);
	}

	for (Index = OutOverwatchingEnemies.Length - 1; Index > -1; --Index)
	{
		bReserveActionPointsValid = false;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OutOverwatchingEnemies[Index].ObjectID, , StartAtHistoryIndex));

		if (UnitState != none && UnitState.TargetIsEnemy(TargetStateObjectID, StartAtHistoryIndex))
		{
			// Check against ValidReserveTypes
			foreach UnitState.ReserveActionPoints(ReserveType)
			{
				if (ValidReserveTypes.Find(ReserveType) != INDEX_NONE)
				{
					bReserveActionPointsValid = true;
					break;
				}
			}

			//This logic may need to be adjusted - right now it assumes that if the unit has reserve action points available an overwatch
			//shot can be performed. Eventually many more conditions may need to be evaluated / the actual abilities checked for a more general
			//condition ( like abilities that trigger on movement, for example )
			if (UnitState.NumAllReserveActionPoints() == 0
				|| (bSkipConcealed && UnitState.IsConcealed())
				|| (!bReserveActionPointsValid))
			{
				OutOverwatchingEnemies.Remove(Index, 1);
			}
		}
		else
		{
			OutOverwatchingEnemies.Remove(Index, 1);
		}
	}
}

cpptext
{
	static class AXComGameInfo* GetXComGameInfo();
	static class AX2GameRuleset* GetX2GameRuleset();
	static class AX2TacticalGameRuleset* GetX2GameTacticalRuleset();
	static class UXComGameStateHistory* GetHistory();
	static class AXComPlotCoverParcel* GetClosestPCPToLocation( const FVector& InLocation );
	static UBOOL TargetInRange(
		const FVector& SourceLocation,
		const FVector& TargetLocation,
		const FVector* SourceFacing=NULL,
		FLOAT MaxRange=0.f,
		FLOAT MaxAngle=360.f);
	static UBOOL IsTileInRangeNative(const FTTile& TileA, const FTTile& TileB, FLOAT MaxTileDistSq, FLOAT MaxTileZDist=3.0f);

	// Test if the Target Unit is within the required min/max ranges and angle of the source unit. If MinRange is 0, no minimum range is
	// required. If MaxRange is 0, no maximum range is required. If MaxAngle is 360 or greater, then no angle check is required.
	static UBOOL IsUnitInRangeNative(const class UXComGameState_Unit& SourceUnit, const class UXComGameState_Unit& TargetUnit,
									 FLOAT MinRange = 0.0f, FLOAT MaxRange = 0.0f, FLOAT MaxAngle = 360.0f);
	static UBOOL IsUnitInRangeFromLocationsNative(const class UXComGameState_Unit& SourceUnit, const class UXComGameState_Unit& TargetUnit,
									 const FTTile& SourceTile, const FTTile& TargetTile,
									 FLOAT MinRange = 0.0f, FLOAT MaxRange = 0.0f, FLOAT MaxAngle = 360.0f);
};

native static final function OpenWindowsExplorerToPhotos(int Campaign);

defaultproperties
{
}
