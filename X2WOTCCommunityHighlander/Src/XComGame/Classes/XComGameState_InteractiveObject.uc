//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_InteractiveObject.uc
//  AUTHOR:  David Burchanowski  --  12/17/2013
//  PURPOSE: This object represents the instance data for an interactive object in a 
//              tactical game (doors, buttons, etc)
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

/// This object stores stateful data about an interactive object in the world. Please see XComInteractiveLevelActor for
/// a detailed breakdown of how this class and XComInteractiveLevelActor are meant to interact, and which class is
/// responsible for which duties.

class XComGameState_InteractiveObject extends XComGameState_Destructible
	implements(Lootable, Hackable)
	config(GameCore)
	native(Core);

//Instance-only variables
var string ArchetypePath;      // for spawned actors
var Rotator SpawnedRotation;   // for spawned actors

var Box InteractionBoundingBox;	
var privatewrite int InteractionCount;        // number of times this object has been interacted with
var bool bHasBeenHacked;
var int  UserSelectedHackReward;
var privatewrite int LockStrength;

//Templated variables (todo, have the level actor be the sole source of these)
var() int MaxInteractionCount;      // maximum number of times you can interact with this object

//Used for actors like doors which need to know how / which way they were interacted with
var() privatewrite name LastInteractedSocket;
var() bool bBroken;
var() protectedwrite bool bRemovedFromPlay;   // No longer on the battlefield

// Keeps track of whether or not this interactive actor has been disabled
var() bool IsEnabled;

var() LootResults PendingLoot;	//Results of rolling for loot

// While true, this Interactive Object is an objective which requires it's Objective shader be visible.
var() private bool RequiresObjectiveGlint;

var bool bOffersTacticalHackRewards;
var bool bOffersStrategyHackRewards;
var private array<name> HackRewards;    //Copied over from the OSP at mission start.
var() array<int> HackRollMods;	// A set of modifiers for the current hack

// The distance in meters away from the center of this Interactive object that should be considered as concealment breaking detection tiles.
var float DetectionRange;

// override to handle special visibiliy rules for doors
native function NativeGetVisibilityLocation(out array<TTile> VisibilityTiles) const;

event SetInitialStateNative(XComInteractiveLevelActor InVisualizer)
{
	SetInitialState(InVisualizer);
}

function SetInitialState(XComDestructibleActor InVisualizer)
{
	local XComInteractiveLevelActor InteractiveActor;

	super.SetInitialState(InVisualizer);

	InteractiveActor = XComInteractiveLevelActor(InVisualizer);
	if(InteractiveActor == none)
	{
		`Redscreen("Attempting to initialize an interactive object with a non-interactive actor!");
		return;
	}

	`XCOMHISTORY.SetVisualizer(ObjectID, InVisualizer);
	InVisualizer.SetObjectIDFromState(self);
	TileLocation = `XWORLD.GetTileCoordinatesFromPosition(InVisualizer.Location);
	DetectionRange = InteractiveActor.DetectionRange;
	bOffersTacticalHackRewards = InteractiveActor.bOffersTacticalHackRewards;
	bOffersStrategyHackRewards = InteractiveActor.bOffersStrategyHackRewards;
	MaxInteractionCount = InteractiveActor.MaxInteractionCount;
	InteractionCount = InteractiveActor.StartingInteractionCount;

	if(MustBeHacked())
	{
		DetermineLockStrength();
	}
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	local XComGameStateHistory History;
	local XComTacticalMissionManager MissionManager;
	local XComInteractiveLevelActor ObjectVisualizer;
	local ObjectiveSpawnPossibility Spawn;
	local ObjectiveSpawnInfo        SpawnInfo;
	local TTile SpawnTile;
	local vector SpawnLocation;
	local XComWorldData WorldData;

	History = `XCOMHISTORY;
	MissionManager = `TACTICALMISSIONMGR;
	SpawnInfo = MissionManager.GetObjectiveSpawnInfoByType(MissionManager.ActiveMission.sType);

	ObjectVisualizer = XComInteractiveLevelActor( History.GetVisualizer( ObjectID ) );
	if (ObjectVisualizer == none)
	{
		ObjectVisualizer = XComInteractiveLevelActor( GetLevelActorForObject( ) );

		if (ObjectVisualizer != None)
		{
			//Make sure we're not trying to grab a visualizer that belongs to some other state object
			`assert(ObjectVisualizer.ObjectID == ObjectID || ObjectVisualizer.ObjectID == 0);

			ObjectVisualizer.SetObjectIDFromState( self );
			History.SetVisualizer( ObjectID, ObjectVisualizer );
		}
	}

	// if the actor is still none, then this actor was spawned (probably as an objective)
	// and we need to manually reconstitute it
	if (ObjectVisualizer == none)
	{
		WorldData = `XWORLD;

		// first check if we need to remove any spawn point swap actors to make room for the 
		// interactive actor
		foreach `XCOMGAME.AllActors( class'ObjectiveSpawnPossibility', Spawn )
		{
			if (Spawn.arrActorsToSwap.Length > 0)
			{
				SpawnLocation = Spawn.GetSpawnLocation();
				WorldData.GetFloorTileForPosition( SpawnLocation, SpawnTile );
				if (SpawnTile == TileLocation)
				{
					Spawn.HideSwapActors();
					break;
				}
				else
				{
					Spawn = none;
				}
			}
		}

		SpawnLocation = WorldData.GetPositionFromTileCoordinates( TileLocation );
		SpawnLocation.Z = WorldData.GetFloorZForPosition( SpawnLocation );
		ObjectVisualizer = XComInteractiveLevelActor( DynamicLoadObject( ArchetypePath, class'XComInteractiveLevelActor' ) );
		if( ObjectVisualizer != None )
		{
			ObjectVisualizer = `XCOMGAME.Spawn(ObjectVisualizer.Class, , , SpawnLocation, SpawnedRotation, ObjectVisualizer);
			History.SetVisualizer(ObjectID, ObjectVisualizer);
			WorldData.AddDestructibleToBuildingVis( ObjectVisualizer );

			if (ActorId.ActorName == '')
				SetInitialState( ObjectVisualizer );

			if(Spawn != none)
			{
				// update the visualizer with the swap info in case it needs to grab visuals from one of the 
				// swap actors
				MissionManager.UpdateObjectiveVisualizerFromSwapInfo(ObjectVisualizer, Spawn, SpawnInfo);
			}
		}
		else
		{
			`Warn(`Location@"DynamicLoadObject failed - Unable to spawn visualizer. "$`ShowVar(ArchetypePath)@`ShowVar(ActorId.OuterName));
		}
	}

	return ObjectVisualizer;
}

function SyncVisualizer(optional XComGameState GameState = none)
{
	local XComGameStateHistory History;
	local XComInteractiveLevelActor ObjectVisualizer;	
	local XComGameState_MaterialSwaps SwapState;
	local XComWorldData WorldData;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;
	ObjectVisualizer = XComInteractiveLevelActor( History.GetVisualizer( ObjectID ) );

	if( ObjectVisualizer != None )
	{
		if(bRemovedFromPlay)
		{
			// syncing to a state that has been removed from play, so also remove
			// the visualizer
			WorldData.RemoveActorTileData(ObjectVisualizer);
			History.SetVisualizer(ObjectID, none);
			ObjectVisualizer.SetVisible(false);
			return;
		}

		// relink the visualizer - this needs to happen before UpdateLootSparkles
		ObjectVisualizer.SetObjectIDFromState(self);

		//If we had a previous interaction, make sure the visualizer knows about it
		if( InteractionCount > 0 )
		{
			ObjectVisualizer.ActiveSocketName = LastInteractedSocket;
			if( LastInteractedSocket == '' && ObjectVisualizer.InteractPoints.Length > 0 )
			{
				// if we didn't record an interaction socket but have been interacted with, attempt to
				// at least show some interaction state as a fallback
				ObjectVisualizer.ActiveSocketName = ObjectVisualizer.InteractPoints[0].InteractSocketName;
			}

			//Disable the visualizer if we've been interacted with enough
			if (MaxInteractionCount >= 0 && InteractionCount >= MaxInteractionCount)
			{
				ObjectVisualizer.OnDisableInteractiveActor();
			}
			else
			{
				ObjectVisualizer.PlayAnimations(none, ObjectVisualizer.ActiveSocketName);

				if (Health > 0) // if it's still alive, we need to update tile data for the animated position
				{
					WorldData.RefreshActorTileData( ObjectVisualizer );
				}
			}
		}

		// see if we want to have loot sparkles
		ObjectVisualizer.UpdateLootSparklesEnabled(false, self);

		// update any material swaps we have
		SwapState = XComGameState_MaterialSwaps( FindComponentObject( class'XComGameState_MaterialSwaps', true ) );
		if (SwapState != none)
		{
			SwapState.ApplySwapsToVisualizer( );
		}

		// reset any autolock
		if (ObjectVisualizer.CachedLockInfo == None && LockStrength > 0)
		{
			ObjectVisualizer.CachedLockInfo = ObjectVisualizer.Spawn( class'XComInteractiveLockInfo', ObjectVisualizer );
			ObjectVisualizer.CachedLockInfo.arrKeys.AddItem( ObjectVisualizer );
			ObjectVisualizer.CachedLockInfo.arrDoors.AddItem( ObjectVisualizer );
		}
	}
}

private event Actor GetLevelActorForObject()
{
	local XComInteractiveLevelActor InteractiveActor;
	local XGBattle Battle;

	local ActorIdentifier ConsideredId;
	local bool HadNameMatch;
	local XComInteractiveLevelActor BestActor;
	local bool NamesMatch, LocsMatch;

	Battle = `BATTLE;

	//Must line up with XComDestructibleActor: FindExistingState! Don't want half a pairing...
	HadNameMatch = false;
	BestActor = none;
	foreach Battle.AllActors(class'XComInteractiveLevelActor', InteractiveActor)
	{
		//Don't consider actors which already have an object ID besides ours.
		if (InteractiveActor.ObjectID != 0 && InteractiveActor.ObjectID != ObjectID)
			continue;

		ConsideredId = InteractiveActor.GetActorId();

		//If the ID matches, this is definitely the match
		if (ActorId == ConsideredId)
		{
			BestActor = InteractiveActor;
			break;
		}

		NamesMatch = (ActorId.ActorName == ConsideredId.ActorName);
		LocsMatch = (VSizeSq(ActorId.Location - ConsideredId.Location) < 0.0001f);

		if (NamesMatch && LocsMatch)
		{
			BestActor = InteractiveActor;
			HadNameMatch = true;
		}
		else if (LocsMatch && !HadNameMatch)
		{
			BestActor = InteractiveActor;
		}
	}

	return BestActor;
}

function OnBeginTacticalPlay(XComGameState NewGameState)
{
	local Object ThisObj;
	local X2EventManager EventManager;

	super.OnBeginTacticalPlay(NewGameState);

	ThisObj = self;
	EventManager = `XEVENTMGR;

	class'SeqEvent_OnInteractiveObjectBeginPlay'.static.FireEvent( self );
	EventManager.RegisterForEvent( ThisObj, 'ObjectDestroyed', OnObjectDestroyed, ELD_OnStateSubmitted,, ThisObj );
	EventManager.RegisterForEvent( ThisObj, 'ObjectInteraction', OnObjectInteraction, ELD_OnStateSubmitted,, ThisObj );
	EventManager.RegisterForEvent( ThisObj, 'ObjectHacked', OnObjectHacked, ELD_OnStateSubmitted,, ThisObj );
}

function RemoveFromPlay(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local XComGameState_InteractiveObject NewObjectState;
	local Object thisObj;

	EventManager = `XEVENTMGR;

	// register for and then trigger an event so that we can guarantee we visualize without
	// every caller of this function having to manually sync our visualizer
	thisObj = self;
	EventManager.RegisterForEvent(thisObj, 'InteractiveObjectRemovedFromPlay', VisualizeRemovedFromPlay, ELD_OnVisualizationBlockCompleted,, self);
	EventManager.TriggerEvent('InteractiveObjectRemovedFromPlay', self, self, NewGameState );		

	NewObjectState = XComGameState_InteractiveObject(NewGameState.ModifyStateObject(class'XComGameState_InteractiveObject', ObjectID));
	NewObjectState.bRemovedFromPlay = true;
}

protected function EventListenerReturn VisualizeRemovedFromPlay(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	`XEVENTMGR.UnRegisterFromEvent(EventSource, 'InteractiveObjectRemovedFromLevel');
	XComGameState_InteractiveObject(EventSource).SyncVisualizer(GameState);

	return ELR_NoInterrupt;
}

function EventListenerReturn OnObjectDestroyed(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit EventUnit;
	local Object ThisObj;

	EventUnit = XComGameState_Unit(EventData);

	class'SeqEvent_OnInteractiveObjectDestroyed'.static.FireEvent( self, EventUnit );

	ThisObj = self;
	`XEVENTMGR.UnRegisterFromEvent( ThisObj, 'ObjectDestroyed' );

	return ELR_NoInterrupt;
}

function EventListenerReturn OnObjectInteraction(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit EventUnit;
	local Object ThisObj;

	EventUnit = XComGameState_Unit(EventData);

	class'SeqEvent_OnInteractiveObjectInteracted'.static.FireEvent( self, EventUnit );

	if( MaxInteractionCount >= 0 && InteractionCount >= MaxInteractionCount )
	{
		ThisObj = self;
		`XEVENTMGR.UnRegisterFromEvent( ThisObj, 'ObjectInteraction' );
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnObjectHacked(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit EventUnit;
	local Object ThisObj;

	EventUnit = XComGameState_Unit(EventData);

	class'SeqEvent_OnInteractiveObjectHacked'.static.FireEvent( self, EventUnit );

	ThisObj = self;
	`XEVENTMGR.UnRegisterFromEvent( ThisObj, 'ObjectHacked' );

	return ELR_NoInterrupt;
}

event Interacted( XComGameState_Unit InstigatingUnit, XComGameState NewGameState, name InteractionSocketName )
{
	local Object ThisObj;

	if( MaxInteractionCount < 0 || InteractionCount < MaxInteractionCount )
	{
		++InteractionCount;
		bRequiresVisibilityUpdate = true;

		ThisObj = self;
		`XEVENTMGR.TriggerEvent( 'ObjectInteraction', InstigatingUnit, ThisObj, NewGameState );

		LastInteractedSocket = InteractionSocketName;

		// automatically acquire electronic data
		GetElectronicLoot(InstigatingUnit, NewGameState);
	}
}

/// <summary>
/// Returns a string representation of this object.
/// </summary>
function string ToString(optional bool bAllFields)
{
	return ToStringT3D();
}

private function ModifyLockStrengthForSitReps( )
{
	local XComGameState_BattleData BattleDataState;
	local X2SitRepEffect_ModifyHackDefenses SitRepEffect;

	// Gather sitrep granted abilities
	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (BattleDataState != none)
	{
		foreach class'X2SitreptemplateManager'.static.IterateEffects(class'X2SitRepEffect_ModifyHackDefenses', SitRepEffect, BattleDataState.ActiveSitReps)
		{
			SitRepEffect.DefenseDeltaFn( LockStrength );
			LockStrength = Clamp( LockStrength, SitRepEffect.DefenseMin, SitRepEffect.DefenseMax );
		}
	}
}

/// <summary>
/// Determines and caches the strength of the lock on this interactive object based on the current force level
/// and any strength modifier on the actor archetype 
/// </summary>
function DetermineLockStrength()
{
	local XComInteractiveLevelActor VisActor;
	
	// add in any modifier from the actor
	VisActor = XComInteractiveLevelActor(GetVisualizer());
	if(VisActor != none && VisActor.CachedLockInfo != none)
	{
		LockStrength = VisActor.CachedLockInfo.iLockStrengthModifier;

		ModifyLockStrengthForSitReps( );
	}
}

function native bool IsDoor();

function bool HasDestroyAnim()
{
	local XComInteractiveLevelActor VisActor;

	VisActor = XComInteractiveLevelActor(GetVisualizer());
	if (VisActor == None)
	{
		return false;
	}

	return VisActor.HasDestroyAnim();
}

/// <summary>
/// Returns true if this object can currently be interacted with "normally". I.e., it's not locked or just a key
/// </summary>
event bool CanInteractNormally(XComGameState_Unit Unit, optional XComInteractiveLevelActor kInteractActor)
{
	local XComInteractiveLevelActor VisActor;
	local XComInteractiveLockInfo LockInfo;

	if(!IsEnabled) return false;

	if( MaxInteractionCount >= 0 && InteractionCount >= MaxInteractionCount )
	{
		return false;
	}

	VisActor = XComInteractiveLevelActor(GetVisualizer());
	if (VisActor == None && kInteractActor != None)
		VisActor = kInteractActor;

	if(VisActor == none || !VisActor.CanInteract(Unit)) return false;

	LockInfo = VisActor.CachedLockInfo;
	if(LockInfo == none) return true;

	if( LockInfo.IsSystemLocked())
	{
		return false; // no normal interactions if the system is still locked
	}

	if(LockInfo.arrKeys.Find(VisActor) != INDEX_NONE && LockInfo.arrDoors.Find(VisActor) == INDEX_NONE)
	{
		// pure keys (they are not their own door) can only be hacked. Normal interactions are not allowed
		return false;
	}

	return true;
}

function bool CanBeLooted(XComGameState_Unit Unit)
{
	return HasAvailableLoot() && !CanInteractHack(Unit);
}

/// <summary>
/// Returns true if this object can currently be interacted with by hacking.
/// </summary>
event bool CanInteractHack(XComGameState_Unit Unit)
{
	local array<Name> CurrentHackRewards;

	if(!IsEnabled) return false;

	if( bOffersTacticalHackRewards && class'XComGameState_BattleData'.static.TacticalHackCompleted() )
	{
		return false;
	}

	CurrentHackRewards = GetHackRewards('');

	return MustBeHacked() && !HasBeenHacked() && (Unit.GetCurrentStat(eStat_Hacking) > 0) && (CurrentHackRewards.Length > 0);
}

/// <summary>
/// Returns true if this object is a "key" object that should be hacked
/// </summary>
event bool MustBeHacked()
{
	local XComInteractiveLevelActor VisActor;
	local XComInteractiveLockInfo LockInfo;

	VisActor = XComInteractiveLevelActor(GetVisualizer());
	if(VisActor == none) return false;

	LockInfo = VisActor.CachedLockInfo;
	if(LockInfo == none) return false;

	return LockInfo.arrKeys.Find(VisActor) >= 0; // we are a key
}

function SetLocked(int InLockStrength)
{
	local XComInteractiveLevelActor VisActor;

	VisActor = XComInteractiveLevelActor(GetVisualizer());

	if( VisActor.CachedLockInfo == None )
	{
		VisActor.CachedLockInfo = VisActor.Spawn(class'XComInteractiveLockInfo', VisActor);
		VisActor.CachedLockInfo.arrKeys.AddItem(VisActor);
		VisActor.CachedLockInfo.arrDoors.AddItem(VisActor);
	}

	LockStrength = InLockStrength;

	ModifyLockStrengthForSitReps( );

	bOffersStrategyHackRewards = true;
}

simulated event bool HasLoot()
{
	if(class'XComGameState_Cheats'.static.GetCheatsObject().DisableLooting)
	{
		return false;
	}

	return PendingLoot.LootToBeCreated.Length > 0 || PendingLoot.AvailableLoot.Length > 0;
}

simulated event bool HasAvailableLoot()
{
	return HasLoot() && InteractionCount > 0; // interactive object must be open to be looted
}

function bool HasAvailableLootForLooter(StateObjectReference LooterRef)
{
	return class'Helpers'.static.HasAvailableLootInternal(self, LooterRef);
}

simulated function bool HasPsiLoot()
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local int i;

	History = `XCOMHISTORY;

	for( i = 0; i < PendingLoot.LootToBeCreated.Length; ++i )
	{
		if( PendingLoot.LootToBeCreated[i] == 'BasicFocusLoot' )
		{
			return true;
		}
	}

	for( i = 0; i < PendingLoot.AvailableLoot.Length; ++i )
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(PendingLoot.AvailableLoot[i].ObjectID));
		if( ItemState != none && X2FocusLootItemTemplate(ItemState.GetMyTemplate()) != none )
		{
			return true;
		}
	}

	return false;
}

simulated function bool HasNonPsiLoot()
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local int i;

	History = `XCOMHISTORY;

	for (i = 0; i < PendingLoot.LootToBeCreated.Length; ++i)
	{
		if (PendingLoot.LootToBeCreated[i] != 'BasicFocusLoot')
		{
			return true;
		}
	}

	for (i = 0; i < PendingLoot.AvailableLoot.Length; ++i)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(PendingLoot.AvailableLoot[i].ObjectID));
		if (ItemState != none && X2FocusLootItemTemplate(ItemState.GetMyTemplate()) == none)
		{
			return true;
		}
	}

	return false;
}

function Lootable MakeAvailableLoot(XComGameState ModifyGameState)
{
	local name LootName;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Item NewItem, SearchItem;
	local XComGameState_InteractiveObject NewObject;
	local StateObjectReference Ref;
	local array<XComGameState_Item> CreatedLoots;
	local bool bStacked;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	NewObject = XComGameState_InteractiveObject(ModifyGameState.ModifyStateObject(class'XComGameState_InteractiveObject', ObjectID));
	CreatedLoots.Length = 0;

	//  copy any objects that have already been created into the new game state
	foreach NewObject.PendingLoot.AvailableLoot(Ref)
	{
		NewItem = XComGameState_Item(ModifyGameState.ModifyStateObject(class'XComGameState_Item', Ref.ObjectID));
	}
	//  create new items for all loot that hasn't been created yet
	foreach NewObject.PendingLoot.LootToBeCreated(LootName)
	{
		ItemTemplate = ItemTemplateManager.FindItemTemplate(LootName);
		if (ItemTemplate != none)
		{
			bStacked = false;
			if (ItemTemplate.MaxQuantity > 1)
				{
					foreach CreatedLoots(SearchItem)
					{
						if (SearchItem.GetMyTemplate() == ItemTemplate)
						{
							if (SearchItem.Quantity < ItemTemplate.MaxQuantity)
							{
								SearchItem.Quantity++;
								bStacked = true;
								break;
							}
						}
					}
					if (bStacked)
						continue;
				}

			NewItem = ItemTemplate.CreateInstanceFromTemplate(ModifyGameState);						
			NewObject.PendingLoot.AvailableLoot.AddItem(NewItem.GetReference());	
			CreatedLoots.AddItem(NewItem);
		}
	}
	NewObject.PendingLoot.LootToBeCreated.Length = 0;	

	return NewObject;
}

function VisualizeLootFountain(XComGameState VisualizeGameState)
{
	class'Helpers'.static.VisualizeLootFountainInternal(self, VisualizeGameState);
}

function bool GetLoot(StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	return class'Helpers'.static.GetLootInternal(self, ItemRef, LooterRef, ModifyGameState);
}

function bool LeaveLoot(StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	return class'Helpers'.static.LeaveLootInternal(self, ItemRef, LooterRef, ModifyGameState);
}

function UpdateLootSparklesEnabled(bool bHighlightObject)
{
	XComInteractiveLevelActor(GetVisualizer()).UpdateLootSparklesEnabled(bHighlightObject, self);
}

function array<StateObjectReference> GetAvailableLoot()
{
	return PendingLoot.AvailableLoot;
}

// Helper function to grab all loot marked as "electronic", which should automatically be transferred when
// an object is successfully interacted with
private function GetElectronicLoot(XComGameState_Unit Looter, XComGameState ModifyGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Item LootItem;
	local X2QuestItemTemplate QuestItemTemplate;
	local int i;

	History = `XCOMHISTORY;

	MakeAvailableLoot(ModifyGameState);

	for (i = PendingLoot.AvailableLoot.Length - 1; i >= 0; --i)
	{
		LootItem = XComGameState_Item(History.GetGameStateForObjectID(PendingLoot.AvailableLoot[i].ObjectID));
		if (LootItem == none) continue;
	
		QuestItemTemplate = X2QuestItemTemplate(LootItem.GetMyTemplate());
		if (QuestItemTemplate == none) continue;
		
		if(QuestItemTemplate.IsElectronicReward)
		{
			GetLoot(LootItem.GetReference(), Looter.GetReference(), ModifyGameState);
		}
	}
}

event bool ShouldShow3DLootIcon()
{
	local XComGameStateHistory History;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2QuestItemTemplate QuestItemTemplate;
	local XComGameState_Item LootItem;
	local StateObjectReference ObjectRef;
	local name LootName;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// only show the loot icon if we have at least one piece of loot that will require the
	// the loot ui. "Elecronic" loot does not, so skip those.
	foreach PendingLoot.LootToBeCreated(LootName)
	{
		QuestItemTemplate = X2QuestItemTemplate(ItemTemplateManager.FindItemTemplate(LootName));

		if(QuestItemTemplate == none || !QuestItemTemplate.IsElectronicReward)
		{
			return true; // non-quest items or non-electronic quest items should show the loot icon.
		}
	}

	History = `XCOMHISTORY;

	foreach PendingLoot.AvailableLoot(ObjectRef)
	{
		LootItem = XComGameState_Item(History.GetGameStateForObjectID(ObjectRef.ObjectID));
		if (LootItem != none)
		{
			QuestItemTemplate = X2QuestItemTemplate(LootItem.GetMyTemplate());
			if(QuestItemTemplate == none || !QuestItemTemplate.IsElectronicReward)
			{
				return true; // non-quest items or non-electronic quest items should show the loot icon.
			}
		}
	}

	return false;
}

function AddLoot(StateObjectReference ItemRef, XComGameState ModifyGameState)
{
	local XComGameState_InteractiveObject NewInteractiveObjectState;

	NewInteractiveObjectState = XComGameState_InteractiveObject(ModifyGameState.ModifyStateObject(class'XComGameState_InteractiveObject', ObjectID));

	NewInteractiveObjectState.PendingLoot.AvailableLoot.AddItem(ItemRef);
}

function RemoveLoot(StateObjectReference ItemRef, XComGameState ModifyGameState)
{
	local XComGameState_InteractiveObject NewInteractiveObjectState;

	NewInteractiveObjectState = XComGameState_InteractiveObject(ModifyGameState.ModifyStateObject(class'XComGameState_InteractiveObject', ObjectID));

	NewInteractiveObjectState.PendingLoot.AvailableLoot.RemoveItem(ItemRef);
}

function string GetLootingName()
{
	local XComInteractiveLevelActor VisActor;

	VisActor = XComInteractiveLevelActor(GetVisualizer());

	return VisActor.FriendlyDisplayName;
}

simulated function TTile GetLootLocation()
{
	return TileLocation;
}

simulated function bool IsLocationValidForInteraction(const out Vector TestLocation)
{
	return ( InteractionBoundingBox.IsValid == 0 ) || IsPointInBox(TestLocation, InteractionBoundingBox);
}

simulated function bool GetRequiresObjectiveGlint()
{
	return RequiresObjectiveGlint;
}

simulated function SetRequiresObjectiveGlint( bool InRequiresObjectiveGlint )
{
	if( RequiresObjectiveGlint != InRequiresObjectiveGlint )
	{
		RequiresObjectiveGlint = InRequiresObjectiveGlint;
	}
}

////////////////////////////////////////////////////////////////////////////////////////
// Hackable interface

function array<int> GetHackRewardRollMods()
{
	return HackRollMods;
}

function SetHackRewardRollMods(const out array<int> RollMods)
{
	HackRollMods = RollMods;
}

/// <summary>
/// Returns true if this object is a "key" object that has been hacked
/// </summary>
function bool HasBeenHacked()
{
	return bHasBeenHacked;
}

function int GetUserSelectedHackOption()
{
	return UserSelectedHackReward;
}

function array<Name> GetHackRewards(Name HackAbilityName)
{
	local XComGameState_BattleData BattleData;
	local array<Name> OutHackRewards;
	local Name HackRewardName;

	OutHackRewards = HackRewards;

	if( bOffersTacticalHackRewards )
	{
		BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		foreach BattleData.TacticalHackRewards(HackRewardName)
		{
			OutHackRewards.AddItem(HackRewardName);
		}
	}
	else if( bOffersStrategyHackRewards )
	{
		BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		foreach BattleData.StrategyHackRewards(HackRewardName)
		{
			OutHackRewards.AddItem(HackRewardName);
		}
	}

	return OutHackRewards;
}

simulated function SetHackRewards(array<Name> InHackRewards)
{
	HackRewards = InHackRewards;
}

// ----- X2GameRulesetVisibilityInterface -----
event float GetVisibilityRadius()
{
	return 0.0;
}

event EForceVisibilitySetting ForceModelVisible()
{
	return eForceVisible;
}
// ----- end X2GameRulesetVisibilityInterface -----

cpptext
{
	// ----- X2GameRulesetVisibilityInterface -----
	virtual UBOOL CanEverSee() const
	{
		return FALSE;
	}

	virtual UBOOL CanEverBeSeen() const
	{
		return TRUE;
	}
	// ----- end X2GameRulesetVisibilityInterface -----
};

DefaultProperties
{	
	bTacticalTransient=true
	MaxInteractionCount=-1
	IsEnabled=true
	LockStrength=-1
}
