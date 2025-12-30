//---------------------------------------------------------------------------------------
//  FILE:    XComInteractiveLevelActor.uc
//  AUTHOR:  David Burchanowski, et. al.  --  2/13/2014
//  PURPOSE: Provides the visualizer for interactive game objects
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

/// Interactive actors work a bit differently in X2. Previously, this class was responsible for visual representation,
/// state data and setup information. State data has now been moved to XComGameState_InteractiveObject. ONLY visual data
/// and initial setup data should be specified in this class. Basically, if it's something the LDs or artists need to
/// fill out at map creation time, put it here. If it's something that change at runtime, such as unlock status, current health,
/// etc, it goes in the state object. It is perfectly correct to have the state object poll this class for any editor-time data
/// it may be interested in, just make sure that data remains constant.
///
/// The only exception to this rule is information that is purely used to assist in representing the visual state of the actor.
/// This information should be able to be reconstituted solely by entering the various unreal states of this actor, however.
/// Please don't add a bunch of visual data into the state object. If you think you need to do this, talk to dburchanowski.

class XComInteractiveLevelActor extends XComDestructibleActor
	dependson(XGUnitNativeBase)
	native(Destruction)
	PerObjectConfig;

enum EInteractionSocket
{
	XGSOCKET_None,

	XGDOOR_Inside01,
	XGDOOR_Inside02,
	XGDOOR_Inside03,
	XGDOOR_Inside04,
	XGDOOR_Inside05,
	XGDOOR_Inside06,

	XGDOOR_Outside01,
	XGDOOR_Outside02,
	XGDOOR_Outside03,
	XGDOOR_Outside04,
	XGDOOR_Outside05,
	XGDOOR_Outside06,

	XGWINDOW_Inside01,
	XGWINDOW_Inside02,
	XGWINDOW_Inside03,
	XGWINDOW_Inside04,
	XGWINDOW_Inside05,
	XGWINDOW_Inside06,

	XGWINDOW_Outside01,
	XGWINDOW_Outside02,
	XGWINDOW_Outside03,
	XGWINDOW_Outside04,
	XGWINDOW_Outside05,
	XGWINDOW_Outside06,

	XGBUTTON_01,
	XGBUTTON_02,
	XGBUTTON_03,
	XGBUTTON_04,
};

enum EIconSocket
{
	XGDOOR_Icon,
	XGWINDOW_Icon,
	XGBUTTON_Icon,
};

enum EInteractionAnim
{
	INTERACTION_None,
	OpenA,
	OpenB,
	CloseA,
	CloseB,
	IdleOpenA,
	IdleOpenB,
	IdleCloseA,
	IdleCloseB,
	BreakOpenA,
	BreakOpenB,
};

enum ETypeOfActor
{
	Type_Default,
	Type_AdventTower,
};

struct native SocketInteraction
{
	var()       EInteractionSocket SrcSocket<Tooltip=The socket that the unit will stand at to interact with this object>;
	var() const EInteractionSocket DestSocket<Tooltip=The socket SrcSocket is connected to for pathing (optional)>;
	var() const Name UnitInteractionAnimName<Tooltip=The animation to play on a unit to interact with (e.g. open) this object>;
	var() const Name UnitDestroyAnimName<Tooltip=The animation to play on a unit to destroy this object>;
	var() const EInteractionAnim InteractionAnim<Tooltip=The animation to play on this actor when it is interacted with by a unit>;
	var() const EInteractionAnim DestroyAnim<Tooltip=The animation to play on this actor when it is destroyed by an unit>;
	var() const EInteractionAnim InactiveIdleAnim<Tooltip=The animation to play on this actor when it is inactive (after interaction)>;
	var() const bool bMirrorAnims<Tooltip=True when unit right shoulder is against cover, false when left shoulder is against cover>;
	var() const EInteractionFacing Facing<Tooltip=Facing when standing at SrcSocket. Left = Unit left shoulder is against cover>;
	var transient const int DestroyAnimIndex;
	var transient const int InteractionAnimIndex;
	var transient const int InactiveIdleAnimIndex;

	structdefaultproperties
	{
		SrcSocket=XGSOCKET_None;
		DestSocket=XGSOCKET_None;
		InteractionAnim=INTERACTION_None;
		InactiveIdleAnim=INTERACTION_None;
		Facing=eIF_None;
		InteractionAnimIndex=INDEX_NONE;
		InactiveIdleAnimIndex=INDEX_NONE;
	}
};

cpptext
{
	static FName InteractionSocketToName(EInteractionSocket Socket);
	static FName InteractionAnimToName(EInteractionAnim Anim);

	void ReattachMeshes();
	virtual void Spawned();
	virtual void PostEditMove(UBOOL bFinished);
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PostEditChangeChainProperty( FPropertyChangedChainEvent& PropertyChangedEvent );
	virtual void PostLoad( );

	void UpdateDLEToLightingSocket();

public:
	virtual FSphere GetBoundsSphere();

	virtual UBOOL ShouldTrace(UPrimitiveComponent* Primitive,AActor *SourceActor, DWORD TraceFlags);
}

var() privatewrite array<SocketInteraction> InteractionPoints;
var() EIconSocket IconSocket;
var() ETypeOfActor ActorType;
var() StaticMesh LockedIcon; // 3D flyover that appears when an object is locked
var() StaticMesh InteractionIcon; // 3D flyover that appears when an object has been unlocked or is otherwise interactive
var() StaticMesh ControllerLockedIcon; // 3D flyover that appears when an object is locked
var() StaticMesh ControllerInteractionIcon; // 3D flyover that appears when an object has been unlocked or is otherwise interactive

var() const name AnimNodeName;
var transient privatewrite AnimNodeBlendList AnimNode;

var() const EInteractionAnim ActiveIdleAnim;
var transient int ActiveIdleAnimIndex;

var transient name ActiveSocketName;

var() const bool bUseRMATranslation;
var() const bool bUseRMARotation;

var transient const bool bMustDestroy;

var transient init array<XComInteractPoint> InteractPoints;

var() bool bTouchActivated;
var bool bWasTouchActivated;

var transient int nTicks;

var() bool bHiddenSkeletalMesh;
var() bool bRequiresCamera; // Temp variable to mark if the objective requires the interacting unit to be carrying a camera
var() bool bHasDisplayRadius;
var StaticMeshComponent kRangeMesh;
var() StaticMeshComponent Mesh;

// Wise Settings
var() name AkEventDoorTypeSwitch<ToolTip = "Some doors used a shared animation set. This value controls the Wise door selector, allowing Wise events to play a door specific sound from the same AkEvent">;

//New interactive mesh support
var() StaticMeshComponent AttachedMesh1;    //Attaches to Mesh1 socket
var() StaticMeshComponent AttachedMesh2;    //Attaches to Mesh2 socket

var() bool bEnableOnPostBeginPlay;

/// If this interactive level actor belongs to a key/lock setup, this caches the setup object it belongs to.
var XComInteractiveLockInfo CachedLockInfo;

// If true will automatically generate a lock info object of the specified strength
var() private bool AutoGenerateSelfLock;
var() private int AutoGenerateSelfLockStrengthModifier;

// The distance in meters away from the center of this Interactive object that should be considered as concealment breaking detection tiles.
var() float DetectionRange;

// if true, then this interactive object should be considered part of the network of tactical hackables.
var() bool bOffersTacticalHackRewards;
var() bool bOffersStrategyHackRewards;

// The name of this actor to show in the hacking UI when this actor is being hacked.
var() localized string FriendlyDisplayName;

// The icon to show in the hacking ui when this actor is being hacked.
var() Texture2D HackingIcon;

// If >= 0, the maximum number of times the user will be able to interact with this object.
var() int MaxInteractionCount;
var() int StartingInteractionCount; // The number of interactions this actor should have on map load
var protected transient SpriteComponent DoorOpenSprite;

// This shader will be applied to the mesh of this Interactive Actor if it is an active mission Objective.
var() private Material ObjectiveShader;
var private bool bObjectiveShaderEnabled;

// List of items that are required to interact with this actor. At least one item in the list must match
// or interaction will not be permitted
var() private const array<string> RequiredItemList; 

// Required ability to interact with this actor
var() name InteractionAbilityTemplateName;

// Required ability to hack this actor
var() name HackAbilityTemplateName;

// Looting variables
var protected bool m_bLootSparkles;
var protected bool m_bHighlightedLootSparkles;
var protected Material m_kLootSparkles;
var protected name LootGlintColorParam;
var protected LinearColor DefaultLootGlint;
var protected LinearColor HighlightedLootGlint;
var protected StaticMeshComponent LootMarkerMesh;

/* If this is true, the Animation has started playing, start checking each frame for end of animation so we know when to trigger the vis blocking texture update. */
var transient protected bool m_bUpdateVisibilityAfterAnimPlays;

/* The bounds of the Actor when the animation started playing. Added to new bounds (when animation ends) to know which tiles need updating. */
var transient protected Box m_kBoundsAtStartOfAnim;

var private XComAnimNodeBlendDynamic m_XComAnimBlendDynamicHandler;
var private bool m_bInAlertMode;
var private bool m_bInHackedMode;
var private bool bLootSparklesShouldBeEnabled;


// override to handle our funky door setups, which the XComDestructibleActor base class can't see
event Vector GetTargetingFocusLocation()
{
	local Vector Result;
	local Vector SocketLocation;
	local Rotator SocketRotation;
	local int MeshCount;
	
	if((AttachedMesh1 == none || AttachedMesh1.StaticMesh == none) && (AttachedMesh2 == none || AttachedMesh2.StaticMesh == none))
	{
		// if no door meshes attached, try to face the interaction socket if there is one
		if(GetSocketTransform('XGBUTTON_Icon', SocketLocation, SocketRotation))
		{
			Result = SocketLocation;
		}
		else
		{
			// just do whatever the base class wants to do
			Result = super.GetTargetingFocusLocation();
		}
	}
	else
	{
		// add in the center of door 1
		if(AttachedMesh1 != none && AttachedMesh1.StaticMesh != none)
		{
			Result += AttachedMesh1.Bounds.Origin;
			MeshCount++;
		}

		// add in the center of door 2
		if(AttachedMesh2 != none && AttachedMesh2.StaticMesh != none)
		{
			Result += AttachedMesh2.Bounds.Origin;
			MeshCount++;
		}

		// and average
		if(MeshCount > 1)
		{
			Result /= MeshCount;
		}
	}

	return Result;
}

function XComGameState_InteractiveObject GetInteractiveState(optional XComGameState NewGameState)
{
	return XComGameState_InteractiveObject(GetState(NewGameState));
}

function XComGameState_Destructible GetState(optional XComGameState NewGameState, optional bool bForceState)
{
	local XComGameStateHistory History;
	local X2TacticalGameRuleset Rules;
	local XComGameState_Destructible ExistingState;
	local XComGameState_InteractiveObject ObjectState;
	local bool SubmitState;
	local TTile TileLocation;

	// first check if this actor already has a state
	ExistingState = FindExistingState(NewGameState);
	if(ExistingState != none)
	{
		ObjectState = XComGameState_InteractiveObject(ExistingState);
		if(ObjectState == none)
		{
			`Redscreen("Attempting to get an interactive object state for a plain vanilla destructible state. This is very bad!");
		}

		return ObjectState;
	}

	// don't create state for interactive objects outside the bounds of the level (periphery pcps)
	TileLocation = `XWORLD.GetTileCoordinatesFromPosition(Location);
	if (`XWORLD.IsTileOutOfRange( TileLocation ))
	{
		return none;
	}

	// if it doesn't exist, then we need to create it
	History = `XCOMHISTORY;
	SubmitState = false;

	// see if we are in the start state
	if(History.GetStartState() != none)
	{
		`assert(NewGameState == none || NewGameState == History.GetStartState()); // there should be any other game states while the start state is still active
		NewGameState = History.GetStartState();
	}
	
	// no start state or supplied game state, make our own
	Rules = `TACTICALRULES;
	if( NewGameState == none )
	{
		if(Rules == none || !Rules.AddNewStatesAllowed())
		{
			//Tried to create a new state object while loading or otherwise unable to do so. This is a recoverable error since the next time this state object
			//is needed it will attempt it again and likely succeed.
			return none;
		}

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState();
		SubmitState = true;
	}
	
	ObjectState = XComGameState_InteractiveObject(NewGameState.CreateNewStateObject(class'XComGameState_InteractiveObject'));

	ObjectState.SetInitialState(self);
		
	if( Rules != None && SubmitState )
	{
		if(!Rules.SubmitGameState(NewGameState))
		{
			`Redscreen("Failed to submit new interactive object state.");
		}
	}

	return ObjectState;
}

function SetObjectIDFromState(XComGameState_BaseObject StateObject)
{
	local XComGameState_InteractiveObject InteractiveObject;
	local Object ThisObj;

	super.SetObjectIDFromState(StateObject);

	ThisObj = self;

	InteractiveObject = XComGameState_InteractiveObject(StateObject);
	if( InteractiveObject != none && ObjectiveShader != None )
	{
		if( InteractiveObject.GetRequiresObjectiveGlint() )
		{
			StartObjectiveShader();
		}
		else
		{
			StopObjectiveShader();
		}

		`XEVENTMGR.RegisterForEvent( ThisObj, 'ObjectiveGlintStatusChanged', OnObjectiveGlintStatusChanged, ELD_OnVisualizationBlockCompleted,, StateObject );
	}
}

function EventListenerReturn OnObjectiveGlintStatusChanged(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_InteractiveObject ObjectState;

	ObjectState = XComGameState_InteractiveObject(EventData);
	if( ObjectState != None )
	{
		if( ObjectState.GetRequiresObjectiveGlint() )
		{
			StartObjectiveShader();
		}
		else
		{
			StopObjectiveShader();
		}
	}

	return ELR_NoInterrupt;
}

native function StartObjectiveShader();
native function StopObjectiveShader();

function UpdateLootSparklesEnabled(bool bHighlight, XComGameState_InteractiveObject PendingState)
{
	bLootSparklesShouldBeEnabled = PendingState.HasAvailableLoot();

	UpdateLootSparkles(bHighlight, PendingState);
}

native function UpdateLootSparkles(optional bool bHighlight, optional XComGameState_InteractiveObject PendingState);

native simulated function bool ShouldIgnoreForCover();

simulated native function EInteractionFacing GetFacingForSocket(name SocketName);
simulated native function bool GetClosestSocket(Vector InLocation, out name SocketName, out Vector SocketLocation);
simulated native function bool GetSocketTransform(name SocketName, out Vector SocketLocation, out Rotator SocketRotation);

simulated native protected static function int FindChildIndex(AnimNodeBlendBase InAnimNode, name ChildName);
simulated native private function bool FindSocketInteraction(name SocketName, out SocketInteraction Interaction);

simulated native private function CacheAnimIndices();
simulated native private function CacheMustDestroy();

/** Sets all primitive components to hide completely rather than using cutout */
native simulated function SetHideableFlag(bool bShouldHide);

/** Flag all primitive components as currently cutdown, immediately without fade. */
native simulated function SetPrimitiveCutdownFlagImm(bool bShouldCutdown);
/** Flag all primitive components as currently cutout, immediately without fade. */
native simulated function SetPrimitiveCutoutFlagImm(bool bShouldCutout);

native simulated function SetPrimitiveHidden(bool bInHidden);

/** Sets all primitive components to hide completely rather than using cutout */
native simulated function SetHideableFlagImm(bool bShouldHide, optional bool bAffectMainSceneChannel=true);

/** Set vis fade on necessary primitive components */
native simulated function SetVisFadeFlag(bool bVisFade, optional bool bForceReattach=false );

/** Set all the height values used for building visibility */
native simulated function SetPrimitiveVisHeight( float fCutdownHeight,     float fCutoutHeight, 
												 float fOpacityMaskHeight, float fPreviousOpacityMaskHeight );

/** Set the current and target cutout and height values. Allows the actor to determine which primitive
 *  component the values come from. */
native simulated function SetPrimitiveVisFadeValues( float CutoutFade, float TargetCutoutFade );

/** Determine if the actor should perform cutout */
native simulated function bool CanUseCutout();

/** Update the cutdown/cutout heights and set hidden state. */
native simulated function ChangeVisibilityAndHide( bool bShow, float fCutdownHeight, float fCutoutHeight );

/** Should be called on PostBeginPlay to ensure that the correct DLE is assigned to the skeletalmeshcomponent
 *      This is a temporary work around for the problems we're experiencing with Archetypes.
 *      Currently the DLE from the archetype is being assigned to LightEnvironment while the DLE created in defaultproperties
 *          is being attached to the actor */
native private function SetLightEnvironment();

/**
 *  Checks if this actor was spawned dynamically and if so updates the destruction information so that
 *  it takes environment damage, etc.
 */
native private function UpdateDestructionTiles();

simulated native function bool IsDoor();
simulated native function bool IsOpenDoor( int HistoryIndex = -1 );

simulated function bool HasDestroyAnim()
{
	local int Index;
	for (Index = 0; Index < InteractionPoints.Length; Index++)
	{
		if (InteractionPoints[Index].DestroyAnimIndex >= 0)
		{
			return true;
		}
	}

	return false;
}

/* Returns the bounds of the component, which is used for calculating which tiles need to be update for the vis blocking texture */
native function GetBoundsForRenderVisUpdate(out vector Min, out vector Max);

// Called by skeletalmeshcomponent when the animtree is initialized
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	local CustomAnimParams Params;

	if( AttachedMesh1 != none )
	{
		SkeletalMeshComponent.AttachComponentToSocket(AttachedMesh1, 'Mesh1');
	}

	if( AttachedMesh2 != none )
	{
		SkeletalMeshComponent.AttachComponentToSocket(AttachedMesh2, 'Mesh2');
	}

	if( IsDoor() )
	{
		SkeletalMeshComponent.bEnableLineCheckWithBounds = true;

		//Only apply the LOD_TickRate to doors. These actors are animated, but do not have idles that do anything so we can turn down their tick rate most of the time
		//and then boost it when someone interacts with them.
		LOD_TickRate = 1.0f;
		TimeSinceLastTick = FRand();
	}	

	// Cache the anim node
	if (SkelComp == SkeletalMeshComponent)
	{
		AnimNode = AnimNodeBlendList(SkeletalMeshComponent.Animations.FindAnimNode(AnimNodeName));

		// Cache interaction animation indices
		CacheAnimIndices();

		if (ActorType == Type_Default)
		{
			if (AnimNode != none && ActiveIdleAnimIndex != INDEX_NONE)
			{
				AnimNode.SetActiveChild(ActiveIdleAnimIndex, 0.0f);
			}
		}
		else if (ActorType == Type_AdventTower)
		{
			m_XComAnimBlendDynamicHandler = XComAnimNodeBlendDynamic(SkeletalMeshComponent.Animations.FindAnimNode(AnimNodeName));
			if( m_XComAnimBlendDynamicHandler == none )
			{
				`RedScreenOnce("Advent Tower expecting XComAnimNodeBlendDynamic anim node with the name "@AnimNodeName@" but couldn't find it. (" @ ObjectArchetype @ ") See Josh Watson");
			}
			else
			{
				Params.AnimName = 'Idle';
				Params.BlendTime = 0.0f;
				Params.Looping = true;
				m_XComAnimBlendDynamicHandler.PlayDynamicAnim(Params);
			}
		}
	}
}

simulated function CacheLockInfo()
{
	local XComInteractiveLockInfo LockInfo;

	// see if we were manually assigned to a lock info in the map
	foreach AllActors(class'XComInteractiveLockInfo', LockInfo)
	{
		if(LockInfo.arrKeys.Find(self) >= 0 || LockInfo.arrDoors.Find(self) >= 0)
		{
			`assert(!AutoGenerateSelfLock); // We are marked for autolock but were assigned a lockinfo in the editor!

			CachedLockInfo = LockInfo;
			return;
		}
	}

	// not assigned a lock info in the map, so see if we should auto generate one
	if(AutoGenerateSelfLock)
	{
		CachedLockInfo = spawn(class'XComInteractiveLockInfo', self);
		CachedLockInfo.arrKeys.AddItem(self);
		CachedLockInfo.arrDoors.AddItem(self);
		CachedLockInfo.iLockStrengthModifier = AutoGenerateSelfLockStrengthModifier;
	}
	else
	{
		CachedLockInfo = none;
	}
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	UpdateDestructionTiles( );
	OnEnableInteractiveActor();
	CacheMustDestroy();
	CacheLockInfo();
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	LightEnvironment.SetEnabled(false);

	SkeletalMeshComponent.SetLightEnvironment( LightEnvironment );
}

function OnSetMaterial(SeqAct_SetMaterial Action)
{
	super.OnSetMaterial(Action);

	if(Mesh != none)
	{
		Mesh.SetMaterial(Action.MaterialIndex, Action.NewMaterial);
	}
}

simulated function AddDefaultInteractionPoints()
{
	local SocketInteraction InteractionPoint;

	InteractionPoint.SrcSocket = XGBUTTON_01;
	InteractionPoints.AddItem(InteractionPoint);

	InteractionPoint.SrcSocket = XGBUTTON_02;
	InteractionPoints.AddItem(InteractionPoint);

	InteractionPoint.SrcSocket = XGBUTTON_03;
	InteractionPoints.AddItem(InteractionPoint);

	InteractionPoint.SrcSocket = XGBUTTON_04;
	InteractionPoints.AddItem(InteractionPoint);

	IconSocket = XGBUTTON_Icon;
	SetSkeletalMesh(SkeletalMesh'HotButton.Meshes.HotButtonColumnLow');

	// rebuild tile data
	class'XComWorldData'.static.GetWorldData().AddActorTileData( self );
}

simulated event bool CanPathThrough()
{
	local XComGameState_InteractiveObject ObjectState;

	ObjectState = GetInteractiveState();

	return IsDoor() && (!ObjectState.MustBeHacked() || ObjectState.HasBeenHacked());
}

simulated event int GetInteractionCount()
{
	local XComGameState_InteractiveObject ObjectState;

	ObjectState = GetInteractiveState();
	if(ObjectState != none)
	{
		if(ObjectID == 0)
			ObjectID = ObjectState.ObjectID;
		return ObjectState.InteractionCount;
	}

	//This fall through case should only happen in rare situations where a saved game is interacting with a map that has changed since the save. It does not
	//deserve a red screen since it is A. common and B. easily recoverable
	return 0; 
}

simulated function OnDisableInteractiveActor()
{
	local XComWorldData WorldData;

	GotoState('_Inactive');

	// rebuild the pathing around us in state code so the world knows we are no longer interactive
	WorldData = class'XComWorldData'.static.GetWorldData();
	if (WorldData != none)
		WorldData.RefreshActorTileData( self );
}

simulated function OnEnableInteractiveActor()
{
	local XComWorldData WorldData;

	GotoState('_Pristine');

	// rebuild the pathing around us so the world knows we are interactive again
	WorldData = class'XComWorldData'.static.GetWorldData();
	if (WorldData != none)
		WorldData.AddActorTileData( self );
}

simulated function BreakInteractActor(name SocketName)
{
	local SocketInteraction Interaction;	

	SetSwitch('Door', AkEventDoorTypeSwitch);

	//Make sure the tick rate is back to normal
	LOD_TickRate = 0.0f;

	`log(self $ "::" $ GetFuncName() @ `ShowVar(SocketName), true, 'XCom_Net');
	if (FindSocketInteraction(SocketName, Interaction))
	{
		if (Interaction.DestroyAnim != INTERACTION_None)
		{
			`log(self $ "::" $ GetFuncName() @ `ShowVar(Interaction.DestroyAnim), true, 'XCom_Net');
			AnimNode.SetActiveChild(Interaction.DestroyAnimIndex, 0.1f);
			AnimNode.GetTerminalSequence().PlayAnim(false, 1.0f); // Make sure it plays forward
		}
		// Play the interaction animation for doors that do not have a destroy animation so they can open
		else if (IsDoor() && Interaction.InteractionAnim != INTERACTION_None)
		{
			`log(self $ "::" $ GetFuncName() @ `ShowVar(Interaction.InteractionAnim), true, 'XCom_Net');
			AnimNode.SetActiveChild(Interaction.InteractionAnimIndex, 0.1f);
			AnimNode.GetTerminalSequence().PlayAnim(false, 1.0f); // Make sure it plays forward
		}
	}
	else
	{
		`log(self $ "::" $ GetFuncName() @ "calling TakeDirectDamage", true, 'XCom_Net');
		
		//rmcfall - TODO - replace!
	}

	// Doors can be closed after being kicked in so don't actually break them
	if( !IsDoor() 
	   && ObjectArchetype.Name != 'ARC_IA_PsionicNode'
	   && ObjectArchetype.Name != 'ARC_RelayTransmitter_Anim_T1'
	   && ObjectArchetype.Name != 'ARC_RelayTransmitter_Anim_T2'
	   && ObjectArchetype.Name != 'ARC_RelayTransmitter_Anim_T3' )
	{
		GotoState('_Inactive');
		SetTimer(1.0f, false, nameof(DeferredRebuildTileData));
		DisableCollision();
	}

	ActiveSocketName = SocketName;
}

function DeferredRebuildTileData()
{
	class'XComWorldData'.static.GetWorldData().RemoveActorTileData( self, true );
}

simulated function AnimNodeSequence PlayAnimations(XGUnit InUnit, name SocketName);

simulated function bool IsAnimating()
{
	return AnimNode != None && AnimNode.GetTerminalSequence().AnimSeq != None && AnimNode.GetTerminalSequence().bPlaying && !AnimNode.GetTerminalSequence().bLooping;
}
// "virtual" interface for states to override

// Can interact is called from XComGameStateObject_InteractiveObject to allow subclasses to add extra
// logic checks to who and what can interact with them in a data driven way
simulated function bool CanInteract(XComGameState_Unit InUnit)
{
	return false;
}

simulated function BeginInteraction(XGUnit InUnit, name SocketName)
{
	
}

simulated function EndInteraction(XGUnit InUnit, name SocketName)
{
}

simulated function string GetActionString(XGUnit InUnit)
{
	return "UNKNOWN";
}

simulated function ShowRangeIndicator()
{
	kRangeMesh.SetScale(288.0f/512.0f);
	kRangeMesh.SetHidden(false);
}

simulated function HideRangeIndicator()
{
	kRangeMesh.SetHidden(true);
}

// Pristine == Active -- jboswell
simulated state _Pristine
{
	simulated event BeginState(name PreviousStateName)
	{
		// overridden from XComDestructible actor to prevent tick blocking
		if(bHasDisplayRadius && kRangeMesh.HiddenGame == true)
		{
			ShowRangeIndicator();
		}
	}

	simulated event EndState(name NextStateName)
	{
		// overridden from XComDestructible actor to prevent tick blocking
		if(bHasDisplayRadius && kRangeMesh.HiddenGame == false)
		{
			HideRangeIndicator();
		}
	}

	simulated event Tick(float DeltaTime)
	{
		local AnimNodeSequence SequenceObject;
		local CustomAnimParams Params;
		super.Tick(DeltaTime);

		if (`TACTICALRULES == None || !`TACTICALRULES.TacticalGameIsInPlay())
		{
			return; // these continue to exist/tick for a little bit after we've archived and the archive doesn't keep interactive gamestates
		}
				
		if (ActorType == Type_AdventTower)
		{
			SetTickIsDisabled(false);// Do not mess with the tick state, see XComLevelActor		
			if( !m_bInHackedMode && GetInteractiveState() != none )
			{
				if( GetInteractiveState().HasBeenHacked() ) //if soldier are in alert mode
				{
					if( m_XComAnimBlendDynamicHandler != None )
					{
						Params.AnimName = 'Idle';
						Params.Looping = false;
						SequenceObject = m_XComAnimBlendDynamicHandler.PlayDynamicAnim(Params);
						SequenceObject.StopAnim();
					}
					m_bInHackedMode = true;
				}
				else if( !m_bInAlertMode )
				{
					if( `battle.AnyEnemyInVisualizeAlert_Red() ) //if soldier are in alert mode
					{
						if( m_XComAnimBlendDynamicHandler != None )
						{
							Params.AnimName = 'IdleAlert';
							Params.Looping = true;
							m_XComAnimBlendDynamicHandler.PlayDynamicAnim(Params);
						}
						m_bInAlertMode = true;
					}
				}
			}
		}
		else
		{
			//Disable until we get an interaction. RAM - currently, disabling tick for this actor results in octree issues. 
			//This indicates a setup problem for this actor ( actors should be able to disable their tick without causing crashes ) and warrants investigation
			//SetTickIsDisabled(true); 
		}

		if( m_bUpdateVisibilityAfterAnimPlays )
		{
			SequenceObject = AnimNode.GetTerminalSequence();
			if( !SequenceObject.bPlaying )
			{
				m_bUpdateVisibilityAfterAnimPlays = false;
				UpdateRenderVisibility();
			}
		}
	}

	simulated private function bool UnitMeetsItemRequirements(XComGameState_Unit InUnit)
	{
		local string RequiredItem;

		if(RequiredItemList.Length == 0)
		{
			// if no required item specified, we're good
			return true;
		}

		// check to see if the unit is carrying at least one of the required items
		foreach RequiredItemList(RequiredItem)
		{
			if(InUnit.HasItemOfTemplateType(name(RequiredItem)))
			{
				return true;
			}
		}

		// no required item is carried, so requirement not met
		return false;
	}

	simulated function bool CanInteract(XComGameState_Unit InUnit)
	{
		// if we require a specific item, check to see if it is carried by the unit
		if(!UnitMeetsItemRequirements(InUnit))
		{
			return false;
		}

		return true;
	}

	simulated function BeginInteraction(XGUnit InUnit, name SocketName)
	{
		// Save interaction socket name
		ActiveSocketName = SocketName;
				
		SetTickIsDisabled(false);			

		`BATTLE.m_bSkipVisUpdate = true;

	}

	simulated function EndInteraction(XGUnit InUnit, name SocketName)
	{
		local XComGameState_InteractiveObject ObjectState;

		// Force Update Components ensures that the collision component gets updated and makes sure its added to the octree because
		// it may have been removed from the octree while the collision was off and the object was moving via RMA.
		InUnit.GetPawn().ForceUpdateComponents(true, true);

		`BATTLE.m_bSkipVisUpdate = false;

		InUnit.GetPawn().Acceleration = vect(0, 0, 0);

		ObjectState = GetInteractiveState();
		if (ObjectState.MaxInteractionCount >= 0 &&  ObjectState.InteractionCount >= ObjectState.MaxInteractionCount)
		{
			GotoState('_Inactive');
		}
	}

	simulated function string GetActionString(XGUnit InUnit)
	{
		local string ActionName;

		if (InUnit.m_bCanOpenWindowsAndDoors && !bMustDestroy)
		{
			ActionName = "Open";
		}
		else
		{
			ActionName = "Destroy";
		}

		switch (IconSocket)
		{
			case XGDOOR_Icon:
				ActionName @= "Door";
				break;
			case XGWINDOW_Icon:
				ActionName @= "Window";
				break;
		}

		return ActionName;
	}

	event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
	{
		local XComUnitPawn UnitPawn;
		local XComInteractPoint TouchPoint;
		local SocketInteraction UseInteraction;
		local bool bHasInteraction;

		super.Bump(Other, OtherComp, HitNormal);
		
		if( bTouchActivated && !bWasTouchActivated )
		{	
			UnitPawn = XComUnitPawn(Other);
			if( UnitPawn != none )
			{
				`XWORLD.GetClosestInteractionPoint( UnitPawn.Location, 
													class'XComWorldData'.const.WORLD_StepSize * 2.0f, 
													class'XComWorldData'.const.WORLD_StepSize * 2.0f,
													TouchPoint );
				
				bHasInteraction = FindSocketInteraction(TouchPoint.InteractSocketName, UseInteraction);
				if( bHasInteraction && TouchPoint.InteractiveActor == self)
				{	
					if( UseInteraction.DestroyAnimIndex > -1 )
					{
						bWasTouchActivated = true;
						`log(self @ " was touch activated, using node " @ TouchPoint.InteractSocketName,,'XComWorldData');
						BreakInteractActor(TouchPoint.InteractSocketName);					
						//`XWORLD.RebuildTileData(Location, class'XComWorldData'.const.WORLD_StepSize*2, class'XComWorldData'.const.WORLD_StepSize * 2);
					}
					else
					{
						`log(self @ " was touch activated, using node " $ TouchPoint.InteractSocketName $ " but UseInteraction.DestroyAnimIndex was not valid",,'XComWorldData');
					}
				}
			}
		}
	}

	simulated function AnimNodeSequence PlayAnimations(XGUnit InUnit, name SocketName)
	{
		local SocketInteraction Interaction;
		local CustomAnimParams AnimParams;
		local AnimNodeSequence PlayingSequence;
		local XComGameState_InteractiveObject ObjectState;
		local AnimNodeSequence ObjectSequence;

		ObjectState = GetInteractiveState();
		PlayingSequence = none;

		//Make sure the tick rate is back to normal
		LOD_TickRate = 0.0f;
		SetSwitch('Door', AkEventDoorTypeSwitch);

		if (ObjectState.InteractionCount % 2 != 0) // Open
		{
			if (FindSocketInteraction(SocketName, Interaction))
			{
				// Play unit's animation
				if (InUnit != None)
				{
					if( InUnit.m_bCanOpenWindowsAndDoors && !bMustDestroy && InUnit.GetPawn().GetAnimTreeController().CanPlayAnimation(Interaction.UnitInteractionAnimName) ) // open
					{
						AnimParams.AnimName = Interaction.UnitInteractionAnimName;
						PlayingSequence = InUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
					}
					else if( InUnit.GetPawn().GetAnimTreeController().CanPlayAnimation(Interaction.UnitDestroyAnimName) ) // destroy
					{
						AnimParams.AnimName = Interaction.UnitDestroyAnimName;
						PlayingSequence = InUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
					}
				}

				// Play my animation, but doors wait for a notification from the Unit's animation (if it exists) before playing
				if( (!IsDoor() || PlayingSequence == None) && (AnimNode != none))
				{
					AnimNode.SetActiveChild(Interaction.InteractionAnimIndex, 0.1f);
					ObjectSequence = AnimNode.GetTerminalSequence();
					ObjectSequence.PlayAnim(false, 1.0f); // Make sure we are playing forwards
				}
			}
		}
		else // Close
		{
			ObjectSequence = AnimNode.GetTerminalSequence();
			ObjectSequence.PlayAnim(false, -1.0f); // Play backwards
		}

		if( bBlockInteriorLighting == true )
		{				
			m_bUpdateVisibilityAfterAnimPlays = true;
			m_kBoundsAtStartOfAnim.Min = SkeletalMeshComponent.Bounds.Origin - SkeletalMeshComponent.Bounds.BoxExtent;
			m_kBoundsAtStartOfAnim.Max = SkeletalMeshComponent.Bounds.Origin + SkeletalMeshComponent.Bounds.BoxExtent;
			m_kBoundsAtStartOfAnim.IsValid = 1;
		}

		return PlayingSequence;
	}
}

simulated state _Inactive extends _Pristine
{
	simulated event BeginState(name PreviousStateName)
	{
	}

	simulated function bool CanInteract(XComGameState_Unit InUnit)
	{
		return false;
	}

	simulated function BeginInteraction(XGUnit InUnit, name SocketName)
	{
	}

	simulated function EndInteraction(XGUnit InUnit, name SocketName)
	{
	}

	simulated function string GetActionString(XGUnit InUnit)
	{
		return "UNKNOWN";
	}

	simulated function SwitchToInactiveAnimation()
	{
		local SocketInteraction Interaction;

		// play inactive idle anim
		if (AnimNode != none && FindSocketInteraction(ActiveSocketName, Interaction))
		{
			if (Interaction.InactiveIdleAnimIndex != INDEX_NONE)
			{
				AnimNode.SetActiveChild(Interaction.InactiveIdleAnimIndex, 0.1f);
			}
		}
	}

Begin:
	// Finish interaction anim
	if (AnimNode != none)
		FinishAnim(AnimNode.GetTerminalSequence());

	SwitchToInactiveAnimation();
}

function string GetMyHUDIcon()
{
	local XComGameState_InteractiveObject ObjectState;

	ObjectState = GetInteractiveState();

	if(ObjectState.MustBeHacked() && !ObjectState.HasBeenHacked())
	{
		return class'UIUtilities_Image'.const.TargetIcon_Hack;
	}
	else
	{
		return super.GetMyHUDIcon();
	}
}

defaultproperties
{
	AnimNodeName="Anim";
	ActiveIdleAnimIndex=INDEX_NONE;
	bUseRMATranslation=true;
	bUseRMARotation=true;

	LockedIcon=StaticMesh'UI_3D.Hacking.Hacking_Door';
	InteractionIcon=StaticMesh'UI_3D.Hacking.Hacking_DoorUnlocked';
	ControllerLockedIcon = StaticMesh'UI3D_Ctrl.Meshes.Hacking_Door_Ctrl';
	ControllerInteractionIcon = StaticMesh'UI3D_Ctrl.Meshes.Hacking_DoorUnlocked_Ctrl';

	bMustDestroy=false;
	bInteractive=true;

	begin object name=SkeletalMeshComponent0
		bUsePrecomputedShadows=false
		bForceUpdateAttachmentsInTick=true
	end object
	CollisionComponent=SkeletalMeshComponent0

	Begin Object Class=StaticMeshComponent Name=CoveringMeshComponent
		HiddenGame=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		BlockRigidBody=false
		CollideActors=false
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
	End Object

	Components.Add(CoveringMeshComponent)
	Mesh=CoveringMeshComponent

	Begin Object Class=StaticMeshComponent Name=CoveringMeshComponent1
		HiddenGame=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		BlockRigidBody=false
		CollideActors=false
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
	End Object

	Components.Add(CoveringMeshComponent1)
	AttachedMesh1=CoveringMeshComponent1

	Begin Object Class=StaticMeshComponent Name=CoveringMeshComponent2
		HiddenGame=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		BlockRigidBody=false
		CollideActors=false
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
	End Object

	Components.Add(CoveringMeshComponent2)
	AttachedMesh2=CoveringMeshComponent2

	Begin Object Class=StaticMeshComponent Name=RangeIndicatorMeshComponent
		HiddenGame=true
		bOwnerNoSee=false
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		BlockRigidBody=false
		CollideActors=false
		bAcceptsDecals=false
		bAcceptsStaticDecals=false
		bAcceptsDynamicDecals=false
		bAcceptsLights=false
		HiddenEditor=true
		StaticMesh=StaticMesh'UI_Range.Meshes.RadiusRing_ArcThrower'
	End Object
	
	Components.Add(RangeIndicatorMeshComponent)
	kRangeMesh=RangeIndicatorMeshComponent
	ActorType = Type_Default

	Begin Object Class=StaticMeshComponent Name=LootMarkerMeshComponent
		HiddenEditor=true
		HiddenGame=true
		HideDuringCinematicView=true
		AbsoluteRotation=true // the billboard shader will break if rotation is in the matrix
		StaticMesh=StaticMesh'UI_3D.Waypoint.LootStatus'
	End Object
	Components.Add(LootMarkerMeshComponent)
	LootMarkerMesh=LootMarkerMeshComponent
	
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.OpenDoorSprite'
		HiddenGame=true
		HiddenEditor=true
		Translation=(Y=10, Z=50)
	End Object
	Components.Add(Sprite)
	DoorOpenSprite=Sprite

	m_kLootSparkles=Material'Materials.Approved.Looting'
	LootGlintColorParam="LootGlintColor"
	DefaultLootGlint = (R=1.0f, G=0.75f, B=0.25f, A=1.0f)
	HighlightedLootGlint = (R=1.0f, G=0.5f, B=0.05f, A=1.0f)

	bTickIsDisabled=false;
	bTouchActivated=false;
	bWasTouchActivated=false;
	nTicks=0;

	bEnableOnPostBeginPlay=false;
	AutoGenerateSelfLock=false
	AutoGenerateSelfLockStrengthModifier=0
	InteractionAbilityTemplateName=Interact_OpenDoor
	HackAbilityTemplateName=Hack

	m_bUpdateVisibilityAfterAnimPlays=false
	m_bInAlertMode=false
	MaxInteractionCount = -1
	AkEventDoorTypeSwitch = "CityCenter"	
}