//-----------------------------------------------------------
// This class exists as the base class for XComUnitPawn in order
// to keep a seperation of native code for that class. Define
// native functions and properties here so that you don't need
// to make XComUnitPawn native and have to recompile C++ everytime
// you add a simple property. -- Dave@Psyonix
//-----------------------------------------------------------
class XComUnitPawnNativeBase extends XComPawn
	native(Unit)
	nativereplication;

const CYBERDISC_OPENCLOSE_DELAY = 0.5f;
const MAX_HIDDEN_TIME = 4.0f;

var XComAnimTreeController AnimTreeController;

//In some situations the unit we are working with is not part of the game state history. Examples include the character pool,
//Multiplayer squad setup, tactical quick launch, and others. In those situations we still want to drive the internal methods
//and data collection logic in this class from a state object, so store that object here. In MOST cases during normal gameplay
//the unit state should be retrieved and used from the history
var protectedwrite XComGameState_Unit UnitState_Menu; 

var float   m_fTurnInitialTargetDirAngle;
var bool    m_bTurnFinished;
var float   m_fTurnLocInterpAmount;
var Vector  m_vTurnInitialLocation;
var int     m_iAimActiveChild;

var Vector2D			AimOffset;
var Vector2D			StartingAimOffset;
var bool				AimEnabled;
var Name				AimSocketOrBone;
var bool				AimShouldTurn;
var float				AimCurrentBlendTime;
var float				AimTotalBlendTime;
var InterpCurveFloat	AimBlendCurve;

var() bool bSkipIK; // Turn off IK
var float fFootIKTimeLeft;  // When this expires, stop doing foot IK to prevent possible vibrating

// MHU - Selfflanked system
var bool bSelfFlankedSystemOK;

struct native FootIKInfo
{
	var SkelControlFootPlacement	FootIKControl;
	var int							FootIKBoneIndex;
	var BlendIKType					FootIKBlendType;
	var Vector						vCachedFootPos;
	var float						vCachedHitZ;
};

// holds physics and collision state -tsmith 
struct native PhysicsState
{
	var bool            m_bNeedsRestoring;
	var EPhysics        m_ePhysics;
	var bool            m_bCollideWorld;
	var bool            m_bCollideActors;
	var bool            m_bBlockActors;
	var bool            m_bIgnoreEncroachers;
};

var array<FootIKInfo> FootIKInfos;
/*
var array<SkelControlFootPlacement> FootIKControls;
var array<int> FootIKBoneIndices;
var array<BlendIKType> FootIKBlendTypes;*/

var array<int> abColCylEnable;

var bool m_bLeftHandIKEnabled;

var SkelControlLimb LeftHandIK;
var SkelControlLimb RightHandIK;

// Left Hand Animation Override
var bool m_bLeftHandIKAnimOverrideEnabled; // Whether or not we should override the LeftHandIK (because the animation tells us so)
var bool m_bLeftHandIKAnimOverrideOn; // Whether or not we should be putting the hand on the gun, if this is false we want our hand off the gun (this is only used when m_bLeftHandIKAnimOverrideEnabled is true)

// Controls turning/facing
var vector FocalPoint;

// Drives the move animations which use RMA to move the pawn
var vector vMoveDirection;

// Destination for moving
var vector vMoveDestination;

var vector LatentTurnTarget;                        //RAM - used by the latent function TurnTowardsPosition

var float fBaseZMeshTranslation;

var array<XComPerkContent>				arrPawnPerkDefinitions;
var array<XComPerkContentInst>			arrPawnPerkContent;
var array<XComPerkContentPassiveInst>	arrPawnPerkPassives;
var array<XComPerkContentShared>		arrTargetingPerkContent;  // Perk Content that references us as a target

var vector m_vFireLoc;

var float m_fTotalDistanceAlongPath;
var float m_fDistanceMovedAlongPath;
var float m_fDistanceToStopExactly;                 // Use this to stop at exactly this distance for things like climbovers/ontos/ladders etc.
var int m_iLastInterval_MoveReactionProcessing;     // MHU - Utilized for Reaction Processing while moving.
var(XComUnitPawn) float FollowDelay;

// Stair volume
var XComStairVolume m_StairVolume;

// The vector that path computations will be computed from, so if they are in cover, this is the location they will be in after
// exiting cover.
//var vector m_vPathFromLoc;

var repnotify protectedwrite XGUnitNativeBase m_kGameUnit;

var bool bUseObstructionShader;

// Jan 7, 2010 MHU - Allows us to specify the default animset for the unit pawn (independent of weapon)
var(XComUnitPawn) array<AnimSet> DefaultUnitPawnAnimsets;

var(XComUnitPawn) array<AnimSet> CarryingUnitAnimSets;
var(XComUnitPawn) array<AnimSet> BeingCarriedAnimSets;
var Actor UnitCarryingMe;
var Actor CarryingUnit;

var(XComUnitPawn) array<AnimSet> CustomFlightMovementRifleAnimsets;
var(XComUnitPawn) array<AnimSet> CustomFlightMovementPistolAnimsets;

var(XComUnitPawn) float PathingRadius; // Radius to use when calculating paths (should be larger than collision)
var(XComUnitPawn) float CollisionHeight; // Half-height to use when pathing/moving
var(XComUnitPawn) float CollisionRadius; // Radius to use when moving

var (XComUnitPawn) bool bAllowFireFromSuppressIdle; // MHU - Requested by Animators to allow units who point their weapons off center during
													//       AC_NO_IdleA to still aim properly.
var(XComUnitPawn) bool bAllowOnlyLowCoverAnims; // Requested by Animators to allow units to use only low cover animations
var bool ProjectileOverwriteAim; // When projectile fires, they overwrite the aim system by where the projectile is firing towards

var(XComUnitPawn) vector ThrowGrenadeStartPosition; //An offset that dictates where grenades should come from when thrown / shot
var(XComUnitPawn) vector ThrowGrenadeStartPositionUnderhand; //An offset that dictates where grenades should come from when thrown / shot

var(XComUnitPawn) float DistanceFromCoverToCenter; // How far from the cover location (wall) should the character stand?

var float fStopDistanceNoCover;  // The distance the stop animation moves the pawn, computed at init time.
var float fStopDistanceCover;  // The distance the stop animation moves the pawn, computed at init time.
var float fRunStartDistance;   // The distance the run start anim moves the pawn, computed at init time.
var float fRunTurnDistance; // The distance the run turn anim moves the pawn, computed at init time.
var float fStrangleStopDistance; // The distance the Viper Strangle Stop animation moves

var bool bShouldRotateToward;	// Don't Use: Rotate toward the focal point. Needed for moving along path and only the run needs it.
// Whether to use root motion accumulation.  If enabled, the animation itself will move this pawn's velocity, NOT the code.
var() bool m_bUseRMA;
var PhysicsState        m_kLastPhysicsState;
var protectedwrite bool m_bIsPhasing;
var bool bWaitingForRagdollNotify; //Used by the ragdoll notify to control the bone springs amount
var bool bNoZAcceleration; //Disables moving vertically when TRUE

var EUnitPawn_OpenCloseState m_eOpenCloseState;
struct native TUnitPawnOpenCloseStateReplicationData
{
	var EUnitPawn_OpenCloseState    m_eOpenCloseState;
	var bool                        m_bImmediate;

	structcpptext
	{
		FTUnitPawnOpenCloseStateReplicationData() :
			m_eOpenCloseState(eUP_None), m_bImmediate(FALSE) {}
	}
};
var protectedwrite repnotify TUnitPawnOpenCloseStateReplicationData   m_kOpenCloseStateReplicationData;

var(XComUnitPawn) editinline array<AnimNotify_PlayParticleEffect> m_arrParticleEffects<ToolTip="Particle Effects to play upon spawning">;

var name m_WeaponSocketNameToUse;

var(XComUnitPawn) array<Name> HiddenSlots<ToolTip="Slots listed here will not show what is attached to them on the pawn.">;

// Where are we currently aiming?
var vector								TargetLoc;
var vector								HeadLookAtTarget;
var() name                              HeadBoneName;

// Whether or not the unit should rotate before moving forward (originally intended for Elder, SHIV, and Sectopod
var bool m_bShouldTurnBeforeMoving;

var MaterialInstance	        m_kAuxiliaryMaterial; //Cached auxiliary material
var MaterialInterface           m_kAuxiliaryMaterial_ZeroAlpha; //For parts of meshes that are translucent (e.g. the halo around a grenade).
var LightingChannelContainer    m_DefaultLightingChannels;

var MaterialInstance            m_kScanningProtocolMaterial;
var MaterialInstance			m_kTargetDefinitionMaterial;

//var float m_fUnitRingRadius;

var float                       m_fPercent;
var float                       m_fVisibilityPercentage; // last rendered frame's percent of screen pixels occupied by the actor and its components
var int                         m_iTurnsTillVisibilityCheck;

var(BlendTimes) float Into_Idle_Blend;

enum ETimeDilationState
{
	ETDS_None,
	ETDS_VictimOfOverwatch,
	ETDS_ReactionFiring,
	ETDS_TriggeredPodActivation,
};


var ETimeDilationState m_eTimeDilationState;

// true if this pawn is participating in a matinee
var bool m_bInMatinee;

// true if this pawn has been hidden for the duration of a matinee
var bool m_bHiddenForMatinee;

// AuxParams stuff
var bool	                            m_bAuxParametersDirty;
var bool                                m_bAuxParamNeedsPrimary;
var bool                                m_bAuxParamNeedsSecondary;
var bool                                m_bAuxParamUse3POutline;
var bool                                m_bAuxAlwaysVisible; // Whether or not the aux material should be visible even if the unit isn't obscured

var private bool                        m_bAuxParamNeedsAOEMaterial;
var bool                                m_bNewNeedsAOEMaterial;
var bool                                m_bUseFriendlyAOEMaterial;

var const MaterialInstance HumanGlowMaterial;
var const MaterialInstance AlienGlowMaterial;
var const MaterialInstance CivilianGlowMaterial;

var Material ScanningProtocolMaterial;
var Material TargetDefinitionMaterial;

var() SkeletalMeshComponent	            m_kTurretBaseMesh;
var X2Actor_TurretBase					m_TurretBaseActor;
var SkeletalMeshComponent				m_kHeadMeshComponent; //Alias to the base mesh for this pawn ( for backwards compatibility )
var SkeletalMeshComponent	            m_kTorsoComponent, m_kArmsMC, m_kLegsMC, m_kHelmetMC, m_kDecoKitMC, m_kEyeMC, m_kTeethMC, m_kHairMC, m_kBeardMC, m_kUpperFacialMC, m_kLowerFacialMC;
var protectedwrite SkeletalMeshComponent HairComponent;       //  jbouscher - this was pulled from XComHumanPawn as it is needed in native code for terrible reasons

//Independently selectable arm meshes
var transient SkeletalMeshComponent     m_kLeftArm, m_kRightArm, m_kLeftArmDeco, m_kRightArmDeco;

// XPack Meshes
var SkeletalMeshComponent				m_kLeftForearmMC, m_kRightForearmMC, m_kThighsMC, m_kShinsMC, m_kTorsoDecoMC;

var array<ParticleSystemComponent>      m_arrRemovePSCOnDeath;

var private bool                        m_bTexturesBoosted;     //  used in strategy for getting textures to load early

//  cached by game systems so the animation system knows what slots to look at for attaching/unattaching items
var transient ELocation                 m_eMoveItemToSlot;
var transient XComWeapon                m_kMoveItem;

//Cache for Flamethrower
var array<XComDestructibleActor>        NearbyFragileDestructibles;

var bool                                m_bWaitingToTurnIntoZombie;

// used to prevent unneeded loot sparkle updates
var private int  m_LastLootSparkleCount;
var private bool m_LootSparkles;
var private bool m_HighlightedLootSparkles;
var private bool bLootSparklesShouldBeEnabled;

var protected Material m_kLootSparkles;
var protected MaterialInstanceConstant m_kLocalLootSparkles; //A child of m_kLootSparkles that has some instance specific data such as LootGlintColorParam
var protected name LootGlintColorParam;
var protected LinearColor DefaultLootGlint;
var protected LinearColor HighlightedLootGlint;

var protected StaticMeshComponent LootMarkerMesh;

var bool bScanningProtocolOutline;
var bool bTargetDefinitionOutline;			//	toggled by UpdatePawnVisibility - true when the unit is in the FOW, false when it isn't - material only shows up when true
var bool bAffectedByTargetDefinition;		//	toggled by X2Effect_TargetDefinition (using X2Action_TargetDefinition) - means the effect is on the unit
var() StaticMesh DeathMesh;
var StaticMeshComponent DeathMeshComp;

var	array<TTile>		LaserScopeVisibleTiles; // All tiles with a laser scope visible to them.
var	bool				bLaserScopeTilesNeedUpdate;

//Game state object ID associated with this pawn. Assigned in the methods that create pawns
var int ObjectID;

// ------------------------------------------------------------------------------------
native function UpdateLaserScopeTiles(const out array<TTile> PathableTiles);
function UpdateTrackingShotMark(TTile NewTileLocation)
{
	local XComPerkContentInst PerkContent;
	local XComGameState_Effect EffectState;
	local XComGameState_Unit TargetUnitState;
	local bool bVisible;

	if (class'Helpers'.static.FindTileInList(NewTileLocation, LaserScopeVisibleTiles) != INDEX_NONE)
	{
		bVisible = true;
	}

	PerkContent = GetPerkContent("TrackingShotMark", true);
	if (!bVisible)
	{
		if (PerkContent != None)
		{
			if (PerkContent.IsInState('ActionActive'))
			{
				PerkContent.OnPerkDeactivation();
			}
			else if (PerkContent.IsInState('DurationActive'))
			{
				PerkContent.OnPerkDurationEnd();
			}
		}
	}
	else
	{
		if (PerkContent == None)
		{
			TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
			EffectState = TargetUnitState.GetUnitAffectedByEffectState(class'X2Ability_ChosenSniper'.default.TrackingShotMarkTargetEffectName);
			ReloadPerk(EffectState);
		}
	}
}

function ReloadPerk(XComGameState_Effect EffectState)
{
	local name EffectName;
	local int  y;
	local array<XComPerkContent> Perks;
	local XComGameState_Unit SourceState;
	local X2AbilityTemplate AbilityTemplate;
	local WorldInfo WInfo;
	local XComPerkContentInst PerkInstance;
	local XGUnit EffectSource;
	local XComUnitPawn SourcePawn;
	WInfo = class'WorldInfo'.static.GetWorldInfo();
	EffectName = EffectState.GetX2Effect().EffectName;
	SourceState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	EffectSource = XGUnit(SourceState.GetVisualizer());
	SourcePawn = EffectSource.GetPawn();
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(EffectState.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName);
	class'XComPerkContent'.static.GetAssociatedPerkDefinitions(Perks, SourcePawn, EffectState.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName);
	for (y = 0; y < Perks.Length; ++y)
	{
		if (Perks[y].AssociatedEffect == EffectName)
		{
			PerkInstance = class'XComPerkContent'.static.GetMatchingInstanceForPerk(SourcePawn, Perks[y]);
			if (PerkInstance == None)
			{
				PerkInstance = WInfo.Spawn(class'XComPerkContentInst');
				PerkInstance.Init(Perks[y], SourcePawn);
			}

			if (!PerkInstance.IsInState('DurationActive'))
			{
				SourceState.ReloadPerkContentInst(PerkInstance, EffectState, AbilityTemplate, Perks[y].AssociatedEffect, EffectName);
			}
		}
	}
}

native function FadeOutPawnSounds();     
native function FadeInPawnSounds();

native function vector GetHeadLocation();
native function vector GetFeetLocation();
native function vector GetCollisionComponentLocation();

native function Rotator GetFlyingDesiredRotation(optional float DesiredPathDistance = -1);

native function SyncCarryingUnits();
native function SetDesiredBoneSprings(bool bEnableLinear, bool bEnableAngular, float InBoneLinearSpring, float InBoneLinearDamping, float InBoneAngularSpring, float InBoneAngularDamping);
simulated native function SetHidden(bool bNewHidden);
simulated event SetVisible(bool bVisible)
{
	Super.SetVisible(bVisible);
	if( m_TurretBaseActor != None )
	{
		m_TurretBaseActor.SetVisible(bVisible);
	}
}

simulated event bool IsFemale()
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	if( UnitState != None && UnitState.kAppearance.iGender == eGender_Female )
	{
		return true;
	}

	return false;
}

event EXComUnitPawn_RagdollFlag GetRagdollFlag( );

function SetMenuUnitState(XComGameState_Unit UnitState)
{
	UnitState_Menu = UnitState;
}

// This function is triggered from an animation's AnimNotify_Script from the Death animation.
simulated function DeathMeshSwap()
{
	local vector Offset;
	local SkeletalMeshComponent MeshComp;

	if (DeathMeshComp != none)
	{
		// To do: Drop static mesh down to ground level.  Also - swap mesh on load for dead sectopods.
		Mesh.SetHidden(true);
		// hide our gun
		foreach AllOwnedComponents(class'SkeletalMeshComponent', MeshComp)
		{
			MeshComp.SetHidden(true);
		}
		// translate our death mesh to the ground and offset under where our death anim moves us to		
		// +1.0f because the mesh incorporates decal like pieces that z-fight if the mesh is flush with the ground
		Offset.Z = `XWORLD.GetFloorZForPosition(Location, true) - Location.Z + 1.0f;

		DeathMeshComp.SetTranslation(Offset);
		DeathMeshComp.SetHidden(false);
		DeathMeshComp.SetLightEnvironment(Mesh.LightEnvironment);
	}
}

// Overrridden by turrets.
simulated event Name GetDeathAnimOnLoadName()
{
	local XGUnitNativeBase Unit;
	local Name DeathAnim;
	Unit = GetGameUnit();

	if( GetAnimTreeController().CanPlayAnimation('HL_DeathInstant') )
	{
		return 'HL_DeathInstant';
	}

	if( Unit != None && Unit.HasOverrideDeathAnim(DeathAnim) )
	{
		return DeathAnim;
	}

	return 'HL_MeleeDeath';
}

simulated event PostBeginPlay()
{		
	super.PostBeginPlay();

	if (DeathMesh != none)
	{
		DeathMeshComp = new(self) class'StaticMeshComponent';
		DeathMeshComp.SetStaticMesh(DeathMesh);
		AttachComponent(DeathMeshComp);
		DeathMeshComp.SetHidden(true);
	}

	if (`TACTICALGRI != none)       //  not relevant in HQ
	{
		ScanningProtocolMaterial = Material(`CONTENT.RequestGameArchetype(class'XGTacticalGameCore'.default.ScanningProtocolMaterialLoc));
		TargetDefinitionMaterial = Material(`CONTENT.RequestGameArchetype(class'XGTacticalGameCore'.default.TargetDefinitionMaterialLoc));
	}

	InitiateBuiltInParticleEffects();
}

function InitiateBuiltInParticleEffects()
{
	local AnimNotify_PlayParticleEffect ParticleNotify;
	foreach m_arrParticleEffects(ParticleNotify)
	{
		if(ParticleNotify.SocketName == '' ||
		   Mesh.GetSocketByName(ParticleNotify.SocketName) != none) //RAM - don't permit particle effects to spawn and then fail to attach
		{
			ParticleNotify.TriggerNotify(Mesh);
		}
	}
}

simulated native function UpdateAuxParameterState(bool bDisableAuxMaterials);

// Stairs
native function EAnimUnitStairState GetStairState();

simulated function SetGameUnit(XGUnit kGameUnit)
{
	m_kGameUnit = kGameUnit;
}

native simulated function XGUnitNativeBase GetGameUnit();

native simulated function bool IsUnitFullyComposed(optional bool bBoostTextures=true);
native simulated function ForceBoostTextures();

replication
{
	if (Role == ROLE_Authority && bNetDirty)
		m_kGameUnit, m_kOpenCloseStateReplicationData, m_fTotalDistanceAlongPath;

}

native function BuildFootIKData();

native function PushCollisionCylinderEnable(bool bEnable);
native function PopCollisionCylinderEnable();

/**
 * Plays sounds for the owning player only.
 * NOTE: do NOT call this function directly. Call XGUnit::UnitSpeak so the server can enforce rules.
 */
reliable client function UnitSpeak( Name nCharSpeech);

cpptext
{
	// AActor collision functions.
	virtual UBOOL ShouldTrace(UPrimitiveComponent* Primitive,AActor *SourceActor, DWORD TraceFlags);

	void EnableCollisionCylinder(UBOOL bEnable);
	INT* GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, UActorChannel* Channel );

	virtual USkeletalMeshComponent* GetMeshForSkelControlLimbTransform(const USkeletalMeshComponent* SkelControlled);
	virtual void BuildAnimSetList();
}

simulated event Name GetLeftHandIKWeaponSocketName()
{
	return 'R_Hand';
}

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'm_kOpenCloseStateReplicationData')
	{
		XComUpdateOpenCloseStateNode(m_kOpenCloseStateReplicationData.m_eOpenCloseState, m_kOpenCloseStateReplicationData.m_bImmediate);
	}

	if( VarName == 'm_kGameUnit' && m_kGameUnit != none )
	{		
		// RAM - register the pawn with the visibility map
		`XWORLD.RegisterActor(self, m_kGameUnit.GetSightRadius() );	
	}
}

simulated event bool ShouldRaiseWeapon()
{
	local X2Action_ExitCover ExitCover;
	local Vector TraceStart;
	local Vector TestDirection;
	local Vector TraceEnd;
	local Actor HitActor;
	local bool bRaiseWeapon;
	
	bRaiseWeapon = false;
	ExitCover = X2Action_ExitCover(`XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(m_kGameUnit));
	if( ExitCover != None && ExitCover.AnimParams.DesiredEndingAtoms.Length != 0 )
	{
		TraceStart = ExitCover.AnimParams.DesiredEndingAtoms[0].Translation;
		TraceStart.Z = `XWORLD.GetFloorZForPosition(TraceStart, true);
		TraceStart.Z += GetAnimTreeController().RaiseWeaponHeightCheck;
		TestDirection = vector(QuatToRotator(ExitCover.AnimParams.DesiredEndingAtoms[0].Rotation));

		TraceEnd = TraceStart + (TestDirection * `TILESTOUNITS(1));

		bRaiseWeapon = `XWORLD.WorldTrace(TraceStart, TraceEnd, TraceEnd, TraceEnd, HitActor, /*XComCover::TraceCove*/1);
	}

	return bRaiseWeapon;
}

simulated function bool IsInitialReplicationComplete()
{
	`LogNetLoadHang(self $ "::" $ GetFuncName() @ `ShowVar(m_kGameUnit));

	// NOTE: can't call m_kGameUnit::IsInitialReplicationComplete as that calls this function and thus infinite recursion. -tsmith 
	return m_kGameUnit != none;
}

simulated native function CalculateVisibilityPercentage();
simulated native function SetVisibilityPercentage(float Percent);
simulated native function UpdateOccludedUnitShader(float Percent);
simulated native function ProcessTimeDilation(float DeltaTime);
simulated native function SetVisibleToTeams(byte eVisibleToTeamsFlags);

simulated function UpdateMeshRenderChannels(RenderChannelContainer RenderChannels) {};
simulated function UpdateAllMeshMaterials() {};
simulated function UpdateMeshMaterials(MeshComponent MeshComp, optional bool bAttachment);

// Aux parameter stuff
simulated native function MarkAuxParametersAsDirty(bool bNeedsPrimary, bool bNeedsSecondary, bool bUse3POutline);
// This is automatically called if m_bAuxParametersDirty is true!
// Do not call this directly!  Use MarkAuxParametersAsDirty instead.
simulated protected function SetAuxParameters(bool bNeedsPrimary, bool bNeedsSecondary, bool bUse3POutline)
{
	SetAuxParametersNative(bNeedsPrimary, bNeedsSecondary, bUse3POutline);


	if(
	// Start Issue #186: Guard with a config option, will hopefully improve performance especially with many mods
		class'CHHelpers'.default.UPDATE_MATERIALS_CONSTANTLY &&
	// End Issue #186
		!m_bAuxParamNeedsAOEMaterial )
	{
		UpdateAllMeshMaterials();
	}
}

simulated protected native function SetAuxParametersNative(bool bNeedsPrimary, bool bNeedsSecondary, bool bUse3POutline);
simulated protected native function CreateAuxMaterial();
simulated public native function ChangeAuxMaterialOnTeamChange(ETeam TeamChangedInto);

simulated private native function UpdateAndReattachComponent(MeshComponent SkelMeshComp, bool bNeedsPrimary, bool bNeedsSecondary, bool bUse3POutline, optional bool bReattach = true);

simulated native function float GetDesiredZForLocation(Vector TestLocation, bool bGetFloorZ = true);

simulated function EnableFootIK(bool bEnable)
{
	local FootIKInfo IKInfo;

	foreach FootIKInfos(IKInfo)
	{
		IKInfo.FootIKControl.SetSkelControlStrength(bEnable ? 1.0f : 0.0f, 0.0f);
	}
}

simulated native function LockDownFootIK(bool bEnable);

simulated function CheckSelfFlankedSystem()
{
	local XComAnimNodeBlendBySelfFlanked kSelfFlankedNode;
	local AnimBlendChild kBlendChild;
	local AnimNodeSequence kAnimNodeSequence;

	bSelfFlankedSystemOK = true;

	kSelfFlankedNode = XComAnimNodeBlendBySelfFlanked(Mesh.FindAnimNode('SelfFlankedNode'));
	if (kSelfFlankedNode != none)
	{
		foreach kSelfFlankedNode.Children (kBlendChild)
		{
			kAnimNodeSequence = AnimNodeSequence(kBlendChild.Anim);
			if (kAnimNodeSequence == none)
			{
				bSelfFlankedSystemOK = false;
				break;
			}
		}
	}
}

// Use this to hook up references to the anim tree nodes you need. -- Dave@Psyonix
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	if (SkelComp == Mesh && Mesh.Animations != none)
	{
		// Start Issue #455
		DLCInfoPostInitAnimTree(SkelComp);
		// End Issue #455

		if (AnimTreeController == none)
		{
			AnimTreeController = new class'XComAnimTreecontroller';
		}
		
		GetAnimTreeController().InitializeNodes(SkelComp);

		LeftHandIK = SkelControlLimb(SkelComp.FindSkelControl('LeftHandIK'));
		RightHandIK = SkelControlLimb(SkelComp.FindSkelControl('RightHandIK'));

		if (LeftHandIK != none)
			LeftHandIK.SetSkelControlStrength(0,0);

		if (RightHandIK != none)
			RightHandIK.SetSkelControlStrength(0,0);

		// MHU - Temporary check to see if we have complete assets for SelfFlanked.
		//       Remove when all aliens have selfflanked animations.
		CheckSelfFlankedSystem();

		if (Mesh != none && Mesh.SkeletalMesh != none)
		{
			fStopDistanceNoCover	= GetAnimTreeController().ComputeAnimationRMADistance('MV_RunFwd_StopStandA');
			fStopDistanceCover		= GetAnimTreeController().ComputeAnimationRMADistance('HL_Run2CoverA');
			fRunStartDistance		= GetAnimTreeController().ComputeAnimationRMADistance('MV_RunFwd_StartA');
			fRunTurnDistance		= GetAnimTreeController().ComputeAnimationRMADistance('MV_RunTurn90LeftA');
			fStrangleStopDistance	= GetAnimTreeController().ComputeAnimationRMADistance('NO_StrangleStopA');
		}

		BuildFootIKData();
	}
	
	Super.PostInitAnimTree(SkelComp);
}

// Start Issue #455
simulated function DLCInfoPostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local XGUnit Unit;
	local XComGameState_Unit UnitState;

	Unit = XGUnit(GetGameUnit());
	if (Unit != none)
	{
		UnitState = Unit.GetVisualizedGameState();
	}

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.UnitPawnPostInitAnimTree(UnitState, self, SkelComp);
	}
}
// End Issue #455

native function HideAllAttachments(bool ShouldHide = true);

native function XComAnimTreeController GetAnimTreeController();
native function AnimNodeSequence PlayWeaponAnim(out CustomAnimParams Params);

native function SetAiming(bool Enable, float BlendTime, optional Name SocketOrBone = 'gun_fire', optional bool ShouldTurn = false);
native function Vector2D GetAimDifference();
native function Vector2D GetDesiredAimOffset();
native function GetAimSocketOrBone(out Vector vLoc, out Rotator rRot);
native function UpdateAiming(float DT);

simulated function UpdateAimProfile(optional string DirectRequest)
{
	local string aimProfileToUse;
	local XComAnimTreeController ATC;

	if( DirectRequest == "" && Weapon != none)
	{
		aimProfileToUse = XComWeapon(Weapon).GetWeaponAimProfileString();
	}
	else
	{
		aimProfileToUse = DirectRequest;
	}

	ATC = GetAnimTreeController();
	if (ATC != none)
		ATC.SetStandingAimOffsetNodeProfile(name(aimProfileToUse));
}

// MHU - Ensures custom animsets have been hooked up according to equipped weapon.
simulated exec function UpdateAnimations()
{
	local XComAnimTreeController ATC;

	// Need to perform animset overriding on a per weapon basis.
	XComUpdateAnimSetList();

	// Need to ensure the right aim profiles are selected for the FocusFire aim node
	UpdateAimProfile();

	ATC = GetAnimTreeController();

	if (ATC != none)
	{
		if (fStopDistanceNoCover == 0)
			fStopDistanceNoCover = ATC.ComputeAnimationRMADistance(`XANIMNAME(eAnim_Running2NoCoverStart));

		if (fStopDistanceCover == 0)
			fStopDistanceCover = ATC.ComputeAnimationRMADistance(`XANIMNAME(eAnim_Running2CoverRightStart));

		if (fRunStartDistance == 0)
			fRunStartDistance = ATC.ComputeAnimationRMADistance('MV_RunFwd_StartA');

		if (fRunTurnDistance == 0)
			fRunTurnDistance = ATC.ComputeAnimationRMADistance('MV_RunTurn90LeftA');

		if (fStrangleStopDistance == 0)
			fStrangleStopDistance = ATC.ComputeAnimationRMADistance('NO_StrangleStopA');
	}
}

simulated function bool XComUpdateOpenCloseStateNode(EUnitPawn_OpenCloseState eDesiredState, optional bool bImmediate = false)
{
	return AnimTreeController.UpdateOpenCloseStateNode(eDesiredState, bImmediate);
}

// MHU - Update list of AnimSets for this Pawn
// CS0 - Prepended with XCom because of name conflict with FEB UE3 
simulated function XComUpdateAnimSetList()
{
	local XComWeapon currentWeapon;
	local XGUnit kUnit;
	local XComPerkContent kPerkContent;
	local XComGameState_Unit UnitState, TempUnitState;
	local XComGameState_Effect TestEffect;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_AdditionalAnimSets AdditionalAnimSetsEffect;
	local UIPawnMgr PawnMgr;
	
	// MHU - Attempt to reset animsets to default (usually rifle animset)
	//       If the default animset doesn't exist, do nothing.
	if (RestoreAnimSetsToDefault())
	{
		kUnit = XGUnit(GetGameUnit());

		if (kUnit != none)
		{
			UnitState = kUnit.GetVisualizedGameState();
		}

		currentWeapon = XComWeapon(Weapon);
		if (currentWeapon != none)
		{
			kUnit = XGUnit(GetGameUnit());

			// Add the weapon's animsets
			XComAddAnimSets(currentWeapon.CustomUnitPawnAnimsets);

			// 2. Customizations for movement + weapons
			if (kUnit != none)
			{
				UnitState = kUnit.GetVisualizedGameState();
				if( UnitState != None && UnitState.kAppearance.iGender == eGender_Female )
				{
					XComAddAnimSets(currentWeapon.CustomUnitPawnAnimsetsFemale);
				}
			}

			foreach arrPawnPerkDefinitions(kPerkContent)
			{
				kPerkContent.AddAnimSetsToPawn(XComUnitPawn(self));
			}
		}

		TempUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
		if (TempUnitState == none) // if there isn't one in the history, check for a pawn manager because shell character pool is a thing.
		{
			foreach `XWORLDINFO.AllActors(class'UIPawnMgr', PawnMgr)
				break;
			TempUnitState = PawnMgr.GetUnitState( ObjectID );
		}

		if( TempUnitState != None )
		{
			XComAddAnimSets(TempUnitState.GetMyTemplate().AdditionalAnimSets);
			if( TempUnitState.kAppearance.iGender == eGender_Female )
			{
				XComAddAnimSets(TempUnitState.GetMyTemplate().AdditionalAnimSetsFemale);
			}
		}

		if( UnitState != None )
		{
			TestEffect = UnitState.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
			if( TestEffect != None )
			{
				XComAddAnimSets(BeingCarriedAnimSets);
			}

			TestEffect = UnitState.GetUnitAffectedByEffectState(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
			if( TestEffect != None )
			{
				XComAddAnimSets(CarryingUnitAnimSets);
			}
		}

		// Loop over extra anim sets added by any X2Effect_AdditionalAnimSetsEffect
		if( UnitState != None )
		{
			History = `XCOMHISTORY;
			foreach UnitState.AffectedByEffects(EffectRef)
			{
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				AdditionalAnimSetsEffect = X2Effect_AdditionalAnimSets(EffectState.GetX2Effect());
				if( AdditionalAnimSetsEffect != none )
				{
					XComAddAnimSets(AdditionalAnimSetsEffect.AdditonalAnimSets);
				}
			}
		}

		Mesh.UpdateAnimations();
	}
}

simulated final function XComReaddCarryAnimSets()
{
	local XGUnit kUnit;
	local XComGameState_Unit UnitState;
	local XComGameState_Effect TestEffect;

	if (!IsA('XComCivilian'))
	{
		kUnit = XGUnit(GetGameUnit());

		if (kUnit != none)
		{
			UnitState = kUnit.GetVisualizedGameState();
		}

		if (!IsA('XComCivilian') && UnitState != None)
		{
			TestEffect = UnitState.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
			if (TestEffect != None)
			{
				XComRemoveAnimSet(BeingCarriedAnimSets);
				XComAddAnimSets(BeingCarriedAnimSets);
			}

			TestEffect = UnitState.GetUnitAffectedByEffectState(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
			if (TestEffect != None)
			{
				XComRemoveAnimSet(CarryingUnitAnimSets);
				XComAddAnimSets(CarryingUnitAnimSets);
			}
		}
	}
}

simulated final function XComAddAnimSetsExternal(const out array<AnimSet> CustomAnimSets)
{
	local int i;

	for( i=0; i<CustomAnimSets.Length; i++ )
	{
		if( CustomAnimSets[i] != none )
		{
			if( Mesh.AnimSets.Find(CustomAnimSets[i]) == INDEX_NONE )
			{
				Mesh.AnimSets[Mesh.AnimSets.Length] = CustomAnimSets[i];
			}
		}
	}

	Mesh.UpdateAnimations();
}

// MHU - Add a given list of anim sets on the top of the current list (for animsequence overriding by name)
// CS0 - Prepended with XCom because of name conflict with FEB UE3 
simulated final function private XComAddAnimSets(const out array<AnimSet> CustomAnimSets)
{
	local int i;

	for(i=0; i<CustomAnimSets.Length; i++)
	{
		if (CustomAnimSets[i] != none && Mesh.AnimSets.Find(CustomAnimSets[i]) == INDEX_NONE)
			Mesh.AnimSets[Mesh.AnimSets.Length] = CustomAnimSets[i];
	}
}

simulated final function private XComRemoveAnimSet(const out array<AnimSet> CustomAnimSets)
{
	local int i;

	for (i = 0; i < CustomAnimSets.Length; i++)
	{
		if (CustomAnimSets[i] != none)
			Mesh.AnimSets.RemoveItem(CustomAnimSets[i]);
	}
}

// MHU - Restore default animsets specified for this unit
simulated event bool RestoreAnimSetsToDefault()
{
	local int Index;
	local InterpGroup Matinee;
	local XGUnit kUnit, ShadowBoundTargetVisualizer;
	local XComUnitPawn ShadowBoundTargetUnitPawn;
	local XComGameState_Unit UnitState;
	local array<AnimSet> ShadowUnit_CopiedDefaultAnimSets;
	local AnimSet PawnAnimSet;

	//Make sure matinee added anims are passed on
	for (Index = 0; Index < InterpGroupList.Length; Index++)
	{
		Matinee = InterpGroupList[Index];

		AddAnimSets(Matinee.GroupAnimSets);

		if ( IsFemale() )
		{
			AddAnimSets(Matinee.GroupAnimSetsFemale);
		}
	}

	if (DefaultUnitPawnAnimsets.Length > 0)
	{
		XComAddAnimSets(DefaultUnitPawnAnimsets);
	}

	// Add the possible ShadowUnit_CopiedDefaultAnimSets (these come from the unit the Shadow is a copy of)
	kUnit = XGUnit(GetGameUnit());

	if (kUnit != none)
	{
		UnitState = kUnit.GetVisualizedGameState();
		if ((UnitState != none) &&
			(UnitState.ShadowUnit_CopiedUnit.ObjectID > 0))
		{
			ShadowBoundTargetVisualizer = XGUnit(`XCOMHISTORY.GetVisualizer(UnitState.ShadowUnit_CopiedUnit.ObjectID));
			if (ShadowBoundTargetVisualizer != none)
			{
				ShadowBoundTargetUnitPawn = ShadowBoundTargetVisualizer.GetPawn();
				foreach ShadowBoundTargetUnitPawn.DefaultUnitPawnAnimsets(PawnAnimSet)
				{
					ShadowUnit_CopiedDefaultAnimSets.AddItem(PawnAnimSet);
				}
				XComAddAnimSets(ShadowUnit_CopiedDefaultAnimSets);
			}
		}
	}

	return true;
}

// jboswell: Don't ask. You know why this is here. I'm not proud.
simulated event PlayMECEventSound(EMECEvent Event);

simulated event FireWeapon()
{
	// NOTE: dont call Start/StopFire to avoid all of unreal's InvManager crap which causes havoc on clients. call the weapon's CustomFire directly -tsmith 
	if (Weapon != none)
		Weapon.CustomFire();
}

// Jwats: Called from AnimNotify_Ragdoll
simulated event RagdollNotify()
{
	if (GetStateName() == 'RagDollBlend')
	{
		//`log("RagdollNotify was triggered, setting bWaitingForRagdollNotify to FALSE");
		bWaitingForRagdollNotify = false; //Indicate that we would like to transition from bone springs to actual physics
	}
}

//  jbouscher - called from AnimNotify_CosmeticUnit
simulated event AnimateCosmeticUnit(name AnimName, bool Looping)
{
	local XComGameState_Unit UnitState;
	local XComGameState_Item ItemState;
	local XGUnit CosmeticUnit;
	local CustomAnimParams AnimParams;
	
	if (AnimName != '')
	{
		UnitState = GetGameUnit().GetVisualizedGameState();
		ItemState = UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon);      //  bit of an optimization as we know cosmetic units are the secondary weapon
		if (ItemState != none && ItemState.CosmeticUnitRef.ObjectID > 0)
		{
			CosmeticUnit = XGUnit(`XCOMHISTORY.GetVisualizer(ItemState.CosmeticUnitRef.ObjectID));
			if (CosmeticUnit != none)
			{
				if (CosmeticUnit.GetPawn().GetAnimTreeController().CanPlayAnimation(AnimName))
				{
					AnimParams.AnimName = AnimName;
					AnimParams.Looping = Looping;
					CosmeticUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				}
			}
		}
	}
}

function SetStairVolume(XComStairVolume StairVolume)
{
	if (StairVolume == none && GetGameUnit().IsInCover() == false)
	{
		`log("Exit stair volume");
		m_StairVolume = none;
	} 
	else
	{
		if (m_StairVolume == none)
		{
			`log("Enter stair volume");
			m_StairVolume = StairVolume;
		}
	}
}

simulated event Destroyed()
{
	local array<XGWeapon> Weapons;
	local XGWeapon DestroyWeapon;

	if( m_kGameUnit != none )
	{
		m_kGameUnit.GetInventory().GetWeapons(Weapons);
		foreach Weapons(DestroyWeapon)
		{				
			if( DestroyWeapon != none && DestroyWeapon.m_kEntity != None)
			{
				XComWeapon(DestroyWeapon.m_kEntity).Destroy();
			}			
		}
	}
	super.Destroyed();
}

simulated event SetFocalPoint(Vector vFocalPt)
{
	// MHU - Uncomment the below to resolve FocalPoint issues (which could result in strange turning/orientation).
	//       Also use the console command "ShowOrientation", which will visually display the focal point (among other things).
	//if (VSize(FocalPoint) > 5000)
	//{
	//	`log("SetFocalPoint called: "@self@FocalPoint);
	//}

	FocalPoint = vFocalPt;
	FocalPoint.Z = Location.Z;

	// NOTE: focal points are stored/accessed only on our pawns because we do clientside locomotion -tsmith 
	//if (Controller != none)
	//	Controller.SetFocalPoint( FocalPoint );


//	if (!self.IsA('XComSectoid'))
//		DrawDebugBox(FocalPoint, vect(0.25,0.25,1), 0, 255, 0, true);
		
}

simulated event RootMotionProcessed(SkeletalMeshComponent SkelComp)
{
	if( AnimTreeController != None )
	{
		AnimTreeController.RootMotionProcessed();
	}
}

// -------------------------------------------------------------------------------------
// Receives mouse events
function bool OnMouseEvent(    int cmd, 
							   int Actionmask, 
							   optional Vector MouseWorldOrigin, 
							   optional Vector MouseWorldDirection, 
							   optional Vector HitLocation)
{
	local XGUnit kUnit; 

	kUnit = XGUnit(GetGameUnit());

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:
			//`log("LEFT MOUSE - DOWN!" @ self ,,'uixcom');
		break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			//`log("LEFT MOUSE - UP!" @ self ,,'uixcom');
		break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			//`log("LEFT MOUSE - OUT!" @ self ,,'uixcom');
			if( kUnit != none )
			{
				kUnit.ShowMouseOverDisc(false);
			}
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			//`log("LEFT MOUSE - IN!" @ self ,,'uixcom');
			if (kUnit != none && !kUnit.IsActiveUnit())
				kUnit.ShowMouseOverDisc();
			break;
	}
	return false; 
}

function ResetMaterials(MeshComponent ResetMeshComp)
{
	local int i;

	for(i=0; i<Mesh.GetNumElements(); i++)
	{
		Mesh.SetMaterial(i, none);
	}
}

simulated function ResetWeaponMaterials()
{
	local int i;

	for(i=0; i<Weapon.Mesh.GetNumElements(); i++)
	{
		Weapon.Mesh.SetMaterial(i, none);
	}
}

simulated event ApplyMITV(MaterialInstanceTimeVarying MITV);
simulated function CleanUpMITV();

simulated event vector GetLeftHandIKTargetLoc();

simulated event MoveToGroundAfterDestruction()
{
	if (GetGameUnit() == none)
	{
		`log(self @ GetFuncName() @ "missing XGUnit!");
		return;
	}
	SnapToGround(1024);
	XGUnit(GetGameUnit()).ProcessNewPosition();
	fFootIKTimeLeft = `FOOTIK_IDLETIMER;
}

/**
* Enables the units physics and collision to work with RMA interaction.
* The unit will not collide with anything and expects to be rotated
* and or translated completely thru RMA.
*
* @param bEnable   == true, disable all collision and remember last collision flags and physics mode.
*                  == false, set collision flags and physics mode back to previous values.
*/
simulated function EnableRMAInteractPhysics(bool bEnable)
{
	if( bEnable && Physics != PHYS_RMAInteract )
	{
		m_kLastPhysicsState.m_bNeedsRestoring = (`BATTLE == none || !(`BATTLE.m_kDesc != none && `BATTLE.m_kDesc.m_bIsTutorial));
		m_kLastPhysicsState.m_ePhysics = Physics;

		if( !m_bIsPhasing )
		{
			m_kLastPhysicsState.m_bCollideWorld = bCollideWorld;
			m_kLastPhysicsState.m_bCollideActors = bCollideActors;
			m_kLastPhysicsState.m_bBlockActors = bBlockActors;
			m_kLastPhysicsState.m_bIgnoreEncroachers = bIgnoreEncroachers;
		}

		// MHU - Order for the below is important. When we change collision for the pawn to false,
		//       untouch events will be triggered, and knowing if the current physics state is PHYS_RMAInteract 
		//       will help assist with building visibility determination.

		// turn off all collision as the animations completely drive the interaction and should not collide with anything -tsmith 
		SetPhysics(PHYS_RMAInteract);
		PushCollisionCylinderEnable(false);
		bCollideWorld = false;
		SetCollision(true /* bCollideActors */, false /* bBlockActors */, false /* bIgnoreEncroachers */);

	}
	else if( !bEnable && (Physics == PHYS_RMAInteract || m_kLastPhysicsState.m_bNeedsRestoring) )
	{
		m_kLastPhysicsState.m_bNeedsRestoring = false;
		SetPhysics(m_kLastPhysicsState.m_ePhysics);
		PopCollisionCylinderEnable();

		if( !m_bIsPhasing )
		{
			bCollideWorld = m_kLastPhysicsState.m_bCollideWorld;
			SetCollision(m_kLastPhysicsState.m_bCollideActors, m_kLastPhysicsState.m_bBlockActors, m_kLastPhysicsState.m_bIgnoreEncroachers);
		}
	}

	// Jwats: Someone is messing with collide world! Simple quick fix to sync them up.
	if( bEnable && bCollideWorld == true )
	{
		bCollideWorld = false;
	}
}

simulated function XComPerkContentInst GetPerkContent(string Perk, bool bTargeted=false)
{
	local XComPerkContentInst kPawnPerk;
	local XComPerkContentShared PerkContentShared;
	local string AbilityName;

	if (bTargeted)
	{
		foreach arrTargetingPerkContent(PerkContentShared)
		{
			AbilityName = string(PerkContentShared.GetAbilityName());
			if (AbilityName == Perk)
			{
				return XComPerkContentInst(PerkContentShared);
			}
		}
	}

	foreach arrPawnPerkContent(kPawnPerk)
	{
		AbilityName = string(kPawnPerk.GetAbilityName());

		if( AbilityName == Perk )
			return kPawnPerk;
	}

	return None;
}

simulated function SetPhasing(bool IsPhasing)
{
	local XComPerkContentInst WallPhasingPerk;
	local PerkActivationData ActivationData;

	if( IsPhasing == m_bIsPhasing )
	{
		return;
	}

	m_bIsPhasing = IsPhasing;
	WallPhasingPerk = GetPerkContent("WallPhasing");

	bSkipIK = IsPhasing;

	if( m_bIsPhasing )
	{
		if( WallPhasingPerk != none )
		{
			WallPhasingPerk.OnPerkActivation( ActivationData );
		}

		if( !m_kLastPhysicsState.m_bNeedsRestoring )
		{
			m_kLastPhysicsState.m_bCollideWorld = bCollideWorld;
			m_kLastPhysicsState.m_bCollideActors = bCollideActors;
			m_kLastPhysicsState.m_bBlockActors = bBlockActors;
			m_kLastPhysicsState.m_bIgnoreEncroachers = bIgnoreEncroachers;

			bCollideWorld = false;
			SetCollision(true /* bCollideActors */, false /* bBlockActors */, false /* bIgnoreEncroachers */);
		}
	}
	else
	{
		if( WallPhasingPerk != none )
		{
			WallPhasingPerk.OnPerkDeactivation();
		}

		if( !m_kLastPhysicsState.m_bNeedsRestoring )
		{
			bCollideWorld = m_kLastPhysicsState.m_bCollideWorld;
			SetCollision(m_kLastPhysicsState.m_bCollideActors, m_kLastPhysicsState.m_bBlockActors, m_kLastPhysicsState.m_bIgnoreEncroachers);
		}
	}
}

simulated event AnimNodeSequence StartTurning(Vector target, optional bool bIgnoreMovingCursor, optional bool AwayFromCover = false)
{
	// MHU - Units no longer pitch.
	target.Z = Location.Z;

	// dont allow turning to face our location as it will cause twitching (target direction would be zero vector)
	if( target.X != Location.X || target.Y != Location.Y )
	{
		//if (!GetAnimTreeController().IsTurnNodeFinishedTurning() && target != FocalPoint)
		//{
		//	`log(self@"new turn target requested while turning, New: "$target$" Current: "$FocalPoint);
		//}

		FocalPoint = target;
		
		EnableRMA(true, true);
		EnableRMAInteractPhysics(true);
		return GetAnimTreeController().TurnToTarget(target, AwayFromCover);
	}

	return none;
}

simulated event StopTurning()
{
	Acceleration = vect(0,0,0);
}

simulated function bool IsInStrategy()
{
	return  IsInState('InHQ') ||
			IsInState('CharacterCustomization') ||
			IsInState('OffDuty');
}

// MHU - Please set all RMA modes through ONLY this function.
simulated function EnableRMA(bool bEnableRMATranslation, bool bEnableRMARotation, optional bool bUpdateFocalPoint = true)
{
	Helper_EnableRMATranslation(bEnableRMATranslation);
	Helper_EnableRMARotation(bEnableRMARotation, bUpdateFocalPoint);
}

simulated function bool IsRMAEnabled()
{
	return Mesh.RootMotionMode==RMM_Accel || Mesh.RootMotionRotationMode==RMRM_RotateActor;
}

// MHU - Never call this directly. Use EnableRMA.
simulated protected function Helper_EnableRMATranslation(bool bEnable)
{
	if (m_bUseRMA)
	{
		if (bEnable)
		{
			if (GetGameUnit() != none)
			{
				`log("*********************** ENABLE RMA Translation for"@GetGameUnit()@"*********************************", `CHEATMGR.MatchesXComAnimUnitName(GetGameUnit().Name), 'XCom_Anim');
				`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(GetGameUnit().Name), 'XCom_Anim');
			}
			Mesh.RootMotionMode=RMM_Accel;
		}
		else
		{
			if (GetGameUnit() != none)
			{
				`log("*********************** DISABLE RMA Translation for"@GetGameUnit()@"*********************************", `CHEATMGR.MatchesXComAnimUnitName(GetGameUnit().Name), 'XCom_Anim');
				`log(GetScriptTrace(), `CHEATMGR.MatchesXComAnimUnitName(GetGameUnit().Name), 'XCom_Anim');
			}

			Mesh.RootMotionMode=RMM_Ignore;
			Velocity = vect(0,0,0);
			Acceleration = vect(0,0,0);
		}
	}
}

// MHU - Never call this directly. Use EnableRMA.
simulated protected function Helper_EnableRMARotation(bool bEnable, bool bUpdateFocalPoint)
{
	local bool NameMatches;
	if (m_bUseRMA)
	{
		NameMatches = (`CHEATMGR != none) ? `CHEATMGR.MatchesXComAnimUnitName(GetGameUnit().Name) : false;
		if (bEnable)
		{
			`log("*********************** ENABLE RMA Rotation for"@GetGameUnit()@"*********************************", NameMatches, 'XCom_Anim');
			`log(GetScriptTrace(), NameMatches, 'XCom_Anim');
			mesh.RootMotionRotationMode=RMRM_RotateActor;
		}
		else if (mesh.RootMotionRotationMode!=RMRM_Ignore)
		{
			`log("*********************** DISABLE RMA Rotation for"@GetGameUnit()@"*********************************", NameMatches, 'XCom_Anim');
			`log(GetScriptTrace(), NameMatches, 'XCom_Anim');
			mesh.RootMotionRotationMode=RMRM_Ignore;

			// MHU - If we're turning using stop/startturning, we don't override the original
			//       desired focalpoint. Normally the below is fine, but we have an
			//       underlying turning issue which isn't settling on the correct on the first turn.
			//       NOTE: Once turning is fixed, restore the below.
			if (bUpdateFocalPoint)
				SetFocalPoint(Location + Vector(Rotation)*1000); 
		}
	}
}

event bool PlayParticleEffect(const AnimNotify_PlayParticleEffect AnimNotifyData)
{
	local SkeletalMeshComponent SkeletalMeshComp;

	if ( PassesPlayLimitsTest( AnimNotifyData ) )
	{
		if ( AnimNotifyData.bIsWeaponEffect )
		{
			SkeletalMeshComp = SkeletalMeshComponent( Weapon.Mesh );
		}
		else
		{
			SkeletalMeshComp = Mesh;
		}

		return PlayParticleEffectInternal( AnimNotifyData, SkeletalMeshComp );
	}

	return false;
}

//  jbouscher - copied verbatim from SkeletalMeshActor::PlayParticleEffect because we need to override some code and there's no other elegant way of doing this
function bool PlayParticleEffectInternal( const AnimNotify_PlayParticleEffect AnimNotifyData, SkeletalMeshComponent MeshToAttachTo )
{
	local vector Loc;
	local rotator Rot;
	local ParticleSystemComponent PSC;
	local bool bPlayNonExtreme;
	local int AttachBoneIndex;
	local SkeletalMeshSocket AttachSocket;

	if (WorldInfo.NetMode == NM_DedicatedServer) 
	{
		`Log("(SkeletalMeshActor): PlayParticleEffect on dedicated server!");
		return true;
	}

	// should I play non extreme content?
	bPlayNonExtreme = ( AnimNotifyData.bIsExtremeContent == TRUE ) && ( WorldInfo.GRI.ShouldShowGore() == FALSE ) ;

	// if we should not respond to anim notifies OR if this is extreme content and we can't show extreme content then return
	if( ( /*bShouldDoAnimNotifies == */FALSE )
		// if playing non extreme but no data is set, just return
		|| ( bPlayNonExtreme && AnimNotifyData.PSNonExtremeContentTemplate==None )
		)
	{
		// Return TRUE to prevent the SkelMeshComponent from playing it as well!
		return true;
	}


	// now go ahead and spawn the particle system based on whether we need to attach it or not
	if( AnimNotifyData.bAttach == TRUE )
	{
		// BEGIN FIRAXIS
		// If an instance of the particle system we want to create is already
		// attached to the mesh at the same spot, then we shouldn't spawn another one.
		if ( AnimNotifyData.bOneInstanceOnly )
		{
			foreach MeshToAttachTo.AttachedComponentsOnBone( class'ParticleSystemComponent', PSC, AnimNotifyData.SocketName, AnimNotifyData.BoneName )
			{
				if (PSC.Template == AnimNotifyData.PSTemplate && PSC.HasCompleted() == false)
					return false;
			}
		}

		AttachBoneIndex = MeshToAttachTo.MatchRefBone(AnimNotifyData.BoneName);
		AttachSocket = MeshToAttachTo.GetSocketByName(AnimNotifyData.SocketName);

		if( AttachBoneIndex != INDEX_NONE || AttachSocket != none ) //RAM - don't permit particle effects to spawn and then fail to attach
		{
			PSC = new(self) class'ParticleSystemComponent';  // move this to the object pool once it can support attached to bone/socket and relative translation/rotation

			if (Mesh != none)
			{
				PSC.SetRenderChannels(Mesh.RenderChannels);
			}

			if ( bPlayNonExtreme )
			{
				PSC.SetTemplate( AnimNotifyData.PSNonExtremeContentTemplate );
			}
			else
			{
				PSC.SetTemplate( AnimNotifyData.PSTemplate );
			}

			if( AnimNotifyData.SocketName != '' )
			{
				//`log( "attaching AnimNotifyData.SocketName" );
				MeshToAttachTo.AttachComponentToSocket( PSC, AnimNotifyData.SocketName );
			}
			else if( AnimNotifyData.BoneName != '' )
			{
				//`log( "attaching AnimNotifyData.BoneName" );
				MeshToAttachTo.AttachComponent( PSC, AnimNotifyData.BoneName );
			}

			PSC.ActivateSystem();
			PSC.OnSystemFinished = SkelMeshActorOnParticleSystemFinished;
		}
		else
		{
			return false; //Fail through when we can't find the socket to attach to - handled by UAnimNotify_PlayParticleEffect::Notify
		}
		// END FIRAXIS
	}
	else
	{
		//RAM - adding a fail through for when a socket was requested, but the actor doesn't have it
		if( AnimNotifyData.SocketName != '' || AnimNotifyData.BoneName != '' )
		{
			AttachBoneIndex = MeshToAttachTo.MatchRefBone(AnimNotifyData.BoneName);
			AttachSocket = MeshToAttachTo.GetSocketByName(AnimNotifyData.SocketName);

			if( AttachBoneIndex != INDEX_NONE ) 
			{
				Loc = MeshToAttachTo.GetBoneLocation( AnimNotifyData.BoneName );
				Rot = QuatToRotator(MeshToAttachTo.GetBoneQuaternion(AnimNotifyData.BoneName));
			}
			else if( AttachSocket != none )
			{
				MeshToAttachTo.GetSocketWorldLocationAndRotation( AnimNotifyData.SocketName, Loc, Rot );
			}
			else
			{
				return false; //The specified socket / bone was not found. Fail through handled by UAnimNotify_PlayParticleEffect::Notify
			}
		}
		else
		{
			Loc = Location;
			Rot = rot(0,0,1);
		}

		PSC = WorldInfo.MyEmitterPool.SpawnEmitter( AnimNotifyData.PSTemplate, Loc,  Rot);
	}

	if( PSC != None && AnimNotifyData.BoneSocketModuleActorName != '' )
	{
		if (AnimNotifyData.bIsWeaponEffect)
		{
			PSC.SetSkeletalMeshParameter( AnimNotifyData.BoneSocketModuleActorName, SkeletalMeshComponent( Weapon.Mesh ) );
		}
		else
		{
			PSC.SetActorParameter(AnimNotifyData.BoneSocketModuleActorName, self);
		}
	}

	//  jbouscher - this is the additional code that isn't in SkeletalMeshActor
	if (PSC != none && AnimNotifyData.bRemoveOnPawnDeath)
	{
		m_arrRemovePSCOnDeath.AddItem(PSC);
	}

	return true;
}


event bool PassesPlayLimitsTest( const AnimNotify_WithPlayLimits AnimNotifyData )
{
	local XGUnit GameUnit;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Unit TargetUnitState;


	GameUnit = XGUnit(GetGameUnit());
	History = `XCOMHISTORY;

	if(GameUnit != none)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(GameUnit.ObjectID));
	}
	else
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID)); //Pawns can also have an object ID assigned, in cases where there is no XGUnit
	}	

	if(AnimNotifyData.Limits.RequirementsAreForAttackTarget)
	{
		// If we are here, then we want to only play this effect if there is an attack target of a matching "type"
		// So first we must see if an attack target exists.
		if(GameUnit != none && GameUnit.CurrentFireAction != none)
		{
			if(GameUnit.CurrentFireAction.AbilityContext.InputContext.PrimaryTarget.ObjectID > 0)
			{
				TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(GameUnit.CurrentFireAction.AbilityContext.InputContext.PrimaryTarget.ObjectID));
			}
		}

		// If there is no attack target, or if there is one, but it's not the correct type, we bail.
		if(TargetUnitState == none || !PassesPlayLimitsTestUnit(AnimNotifyData, TargetUnitState))
			return false;
	}
	else
	{
		if(!PassesPlayLimitsTestUnit(AnimNotifyData, UnitState))
		{
			return false;
		}	
	}

	return true;
}

private function bool PassesPlayLimitsTestUnit(const AnimNotify_WithPlayLimits AnimNotifyData, XComGameState_Unit UnitState)
{
	local name UnitStateTemplateName;
	local bool bAnyPlayLimits;

	if( UnitState_Menu != none )
	{
		UnitState = UnitState_Menu;
	}

	if( AnimNotifyData.Limits.PlayForXcomOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsSoldier() )
			return false;
	}
	if( AnimNotifyData.Limits.Enemies.PlayForAlienOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsAlien() )
			return false;
	}
	if( AnimNotifyData.Limits.Enemies.PlayForAdventOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsAdvent() )
			return false;
	}
	if( AnimNotifyData.Limits.Enemies.PlayForCyberusOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && UnitState.GetMyTemplateName() != Name("Cyberus") )
			return false;
	}
	if( AnimNotifyData.Limits.Enemies.PlayForAndromedonOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && UnitState.GetMyTemplateName() != Name("Andromedon") )
			return false;
	}
	if( AnimNotifyData.Limits.PlayForRobotOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsRobotic() )
			return false;
	}
	if( AnimNotifyData.Limits.PlayForHumanOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsSoldier() && !UnitState.IsCivilian() )
			return false;
	}
	if( AnimNotifyData.Limits.Enemies.PlayForPsiWitchOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none )
		{
			UnitStateTemplateName = UnitState.GetMyTemplateName();

			if( (UnitStateTemplateName != 'AdvPsiWitchM2') &&
				(UnitStateTemplateName != 'AdvPsiWitchM3') )
			{
				return false;        //  don't play
			}
		}
	}
	if( AnimNotifyData.Limits.SoldierClass.PlayForRangerOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsSoldier() && UnitState.GetSoldierClassTemplateName() != 'Ranger' && UnitState.GetSoldierClassTemplateName() != 'MP_Ranger' )
			return false;
	}
	if( AnimNotifyData.Limits.SoldierClass.PlayForSharpshooterOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsSoldier() && UnitState.GetSoldierClassTemplateName() != 'Sharpshooter' && UnitState.GetSoldierClassTemplateName() != 'MP_Sharpshooter' )
			return false;
	}
	if( AnimNotifyData.Limits.SoldierClass.PlayForGrenadierOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsSoldier() && UnitState.GetSoldierClassTemplateName() != 'Grenadier' && UnitState.GetSoldierClassTemplateName() != 'MP_Grenadier' )
			return false;
	}
	if( AnimNotifyData.Limits.SoldierClass.PlayForSpecialistOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsSoldier() && UnitState.GetSoldierClassTemplateName() != 'Specialist' && UnitState.GetSoldierClassTemplateName() != 'MP_Specialist' )
			return false;
	}
	if( AnimNotifyData.Limits.SoldierClass.PlayForPsiOperativeOnly )
	{
		bAnyPlayLimits = true;
		if( UnitState != none && !UnitState.IsSoldier() && UnitState.GetSoldierClassTemplateName() != 'PsiOperative' && UnitState.GetSoldierClassTemplateName() != 'MP_PsiOperative' )
			return false;
	}
	if (AnimNotifyData.Limits.Enemies.PlayForChosenAssassinM1Only)
	{
		bAnyPlayLimits = true;
		if (UnitState != none && UnitState.GetMyTemplateName() != Name("ChosenAssassin"))
			return false;
	}
	if (AnimNotifyData.Limits.Enemies.PlayForChosenAssassinM2Only)
	{
		bAnyPlayLimits = true;
		if (UnitState != none && UnitState.GetMyTemplateName() != Name("ChosenAssassinM2"))
			return false;
	}
	if (AnimNotifyData.Limits.Enemies.PlayForChosenAssassinM3Only)
	{
		bAnyPlayLimits = true;
		if (UnitState != none && UnitState.GetMyTemplateName() != Name("ChosenAssassinM3"))
			return false;
	}
	if (AnimNotifyData.Limits.Enemies.PlayForChosenAssassinM4Only)
	{
		bAnyPlayLimits = true;
		if (UnitState != none && UnitState.GetMyTemplateName() != Name("ChosenAssassinM4"))
			return false;
	}
	if (AnimNotifyData.Limits.Enemies.PlayForSpectreM2Only)
	{
		bAnyPlayLimits = true;
		if (UnitState != none && UnitState.GetMyTemplateName() != Name("SpectreM2"))
			return false;
	}

	if( bAnyPlayLimits && (UnitState == None || m_bInMatinee) )
	{
		return false;
	}

	// We have play limits, and the limits didn't return false so SUCCESS!
	return true;
}

function bool NotifyPSCWantsRemoveOnDeath(ParticleSystemComponent PSC)
{
	m_arrRemovePSCOnDeath.AddItem(PSC);
	return true;
}

simulated function SkelMeshActorOnParticleSystemFinished( ParticleSystemComponent PSC )
{
	Mesh.DetachComponent( PSC );

	m_arrRemovePSCOnDeath.RemoveItem(PSC);
}

simulated function SetWaitingToBeZombified(bool bIsWaitingToZombify)
{
	m_bWaitingToTurnIntoZombie = bIsWaitingToZombify;
}

function UpdateLootSparklesEnabled(bool bHighlight, XComGameState_Unit UnitState)
{
	bLootSparklesShouldBeEnabled = UnitState.HasAvailableLoot();

	UpdateLootSparkles(bHighlight, UnitState);
}

simulated native function UpdateLootSparkles(bool bHighlight, optional XComGameState_Unit UnitState);

//This method enables linear drive for the rag doll's root rigid body, which will move it towards the location specified by Destination
//Destination: where we want the rag doll to land
//Impulse: direction of the physics impulse moving the rag doll. Some roll is introduced in this direction to make the motion seem more physical
native function SetRagdollLinearDriveToDestination(const out Vector Destination, const out Vector Impulse, FLOAT PhysicsMotorForce, FLOAT PhysicsDampingForce);

native function UpdateRagdollLinearDriveDestination(const out Vector Destination);

simulated function UpdateHeadLookAtTarget()
{
	local XComGameStateHistory			History;
	local X2TargetingMethod				TargetingMethod;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;
	local XGUnit                        UnitVis;
	local XComPresentationLayer			PresLayer;
	
	History = `XCOMHISTORY;
	PresLayer = `PRES;

	// This isn't thread safe. If you comment out this code block, the game is likely to crash because
	// the head tracking determines visibility via the visibility conditions. These always operate against the
	// most recent history frame, and not the cached frame for non-latent state threads. So memory will be shifting
	// out from under the visibility query below, and will cause access violations. At some point this needs to be
	// made properly thread safe, but for now I'm band-aiding it since I am leaving tomorrow - dburchanowski
	if (`TACTICALRULES.BuildingLatentGameState)
		return;

	// no heads turning on dead guys
	if (m_kGameUnit != none && m_kGameUnit.IsDead())
		return;

	// similarly if we're not force updated or onscreen
	if (!(Mesh.bUpdateSkelWhenNotRendered || Mesh.bRecentlyRendered))
		return;

	if( PresLayer != none && PresLayer.GetTacticalHUD() != None )
	{
		TargetingMethod = PresLayer.GetTacticalHUD().GetTargetingMethod();
	}
	
	if( TargetingMethod != none && TargetingMethod.Ability.OwnerStateObject.ObjectID == ObjectID )
	{
		TargetingMethod.GetCurrentTargetFocus(HeadLookAtTarget);
	}
	else if( m_kGameUnit != none && m_kGameUnit.CurrentExitAction != none )
	{
		HeadLookAtTarget = m_kGameUnit.CurrentExitAction.TargetLocation;
	}
	else if( class'X2TacticalVisibilityHelpers'.static.GetClosestVisibleEnemy(ObjectID, OutVisibilityInfo) )
	{
		UnitVis = XGUnit(History.GetVisualizer(OutVisibilityInfo.TargetID));
		if(UnitVis != none && UnitVis.GetPawn() != none)
			HeadLookAtTarget = UnitVis.GetPawn().GetHeadLocation();
	}

	GetAnimTreeController().SetHeadLookAtTarget(HeadLookAtTarget);
}

//Triggered by the world data visibility build process. Also used by the visibility observer to compare notes with the game play visibility system. Returns TRUE if there are FOW viewers of this pawn.
event bool UpdatePawnVisibility()
{
	local X2GameRulesetVisibilityInterface VisibilityViewerInterface;
	local XComGameState_Unit GameStateObject;
	local EForceVisibilitySetting ForcedVisible;
	local bool bSeen;

	if (m_kGameUnit != none)	
	{
		GameStateObject = m_kGameUnit.GetVisualizedGameState();
	}
	else
	{
		GameStateObject = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	}

	VisibilityViewerInterface = X2GameRulesetVisibilityInterface(GameStateObject);
	ForcedVisible = VisibilityViewerInterface.ForceModelVisible();

	if(ForcedVisible == eForceVisible || XComTacticalCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager).bAllowSelectAll)
	{
		m_kGameUnit.SetVisibleToTeams(eTeam_All);
		//`SHAPEMGR.DrawTile(NewTile, 0, 255, 255);

		if (bAffectedByTargetDefinition)
		{
			bSeen = IsPawnSeenInFOW();
			bTargetDefinitionOutline = !bSeen;
			MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
		}

		return true;
	}
	else if(ForcedVisible == eForceNotVisible)
	{
		m_kGameUnit.SetVisibleToTeams(eTeam_None);
		return false;
	}
	else
	{
		bSeen = IsPawnSeenInFOW() || class'X2TacticalVisibilityHelpers'.static.IsUnitAlwaysVisibleToLocalPlayer(GameStateObject);
		
		if (bSeen)
		{
			m_kGameUnit.SetVisibleToTeams(eTeam_All);
			//`SHAPEMGR.DrawTile(NewTile, 0, 255, 0);			
			return true;
		}
		else
		{
			m_kGameUnit.SetVisibleToTeams(eTeam_None);
			//`SHAPEMGR.DrawTile(NewTile, 255, 0, 0);
			return false;
		}
	}

	return false;
}

function bool IsPawnSeenInFOW()
{
	local TTile PawnTile;
	local FOWTileStatus TileStatus;
	local BYTE GameplayFlags;
	local CachedCoverAndPeekData CoverPeekData;
	local bool bSeen;
	local int Index;

	`XWORLD.GetFloorTileForPosition(Location, PawnTile, true);
	`XWORLD.ClampTile(PawnTile);

	CoverPeekData = `XWORLD.GetCachedCoverAndPeekData(PawnTile);

	`XWORLD.GetTileFOWValue(CoverPeekData.DefaultVisibilityCheckTile, TileStatus, GameplayFlags);
	bSeen = TileStatus == eFOWTileStatus_Seen && GameplayFlags != 0;

	//Check peeks if not seen at the default tile location
	if (!bSeen)
	{
		for (Index = 0; Index < 4; ++Index)
		{
			if (CoverPeekData.CoverDirectionInfo[Index].bHasCover == 1)
			{
				if (CoverPeekData.CoverDirectionInfo[Index].LeftPeek.bHasPeekaround == 1)
				{
					`XWORLD.GetTileFOWValue(CoverPeekData.CoverDirectionInfo[Index].LeftPeek.PeekTile, TileStatus, GameplayFlags);
					if (TileStatus == eFOWTileStatus_Seen && GameplayFlags != 0)
					{
						bSeen = true;
						break;
					}
				}

				if (CoverPeekData.CoverDirectionInfo[Index].RightPeek.bHasPeekaround == 1)
				{
					`XWORLD.GetTileFOWValue(CoverPeekData.CoverDirectionInfo[Index].RightPeek.PeekTile, TileStatus, GameplayFlags);
					if (TileStatus == eFOWTileStatus_Seen && GameplayFlags != 0)
					{
						bSeen = true;
						break;
					}
				}
			}
		}
	}

	return bSeen;
}

// NOTICE: This should only be called by an animation notify, usuall for melee
//         attacks that do not use a weapon.
//         Example: Berserker Smash, Chryssalid Slash
event OnMeleeStrike()
{
	local XGUnit Unit;
	local X2Action CurrentAction;

	Unit = XGUnit(GetGameUnit());

	CurrentAction = `XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(Unit);
	CurrentAction.OnAnimNotify(new class'XComAnimNotify_NotifyTarget');

	if( Unit.CurrentFireAction != none )
	{
		Unit.CurrentFireAction.NotifyTargetsAbilityApplied();
	}
}


native function GeoscapePauseInterpActions();
native function GeoscapeUnpauseInterpActions();

native simulated function SetDitherEnable(bool bEnableDither);

//Sets the character's location regardless of what intervening geo might exist
native function bool SetLocationNoCollisionCheck(vector NewLocation);

//Method for manually adjusting the APEX clothing distance scale - which blends between the simulated cloth position and the skinned position. 
// 0.0 is fully skinned, while 1.0 is fully simulated
native function SetApexClothingMaxDistanceScale_Manual(float DistanceScale);
native function SetApexClothingLowerGravity();
native function ToggleClothingSimulation(bool bEnabled);

native function SyncActorToRBPhysics_ScriptAccess();

DefaultProperties
{
	Begin Object Class=SkeletalMeshComponent Name=SkeletalMeshComponent		
	End Object

	Begin Object Class=StaticMeshComponent Name=LootMarkerMeshComponent
		HiddenGame=true
		HideDuringCinematicView=true
		StaticMesh=StaticMesh'UI_3D.Waypoint.LootStatus'
		AbsoluteTranslation=true
		AbsoluteRotation=true // the billboard shader will break if rotation is in the matrix
	End Object
	Components.Add(LootMarkerMeshComponent)
	LootMarkerMesh=LootMarkerMeshComponent

	Begin Object Class=SkeletalMeshComponent Name=Torso
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kTorsoComponent = Torso
	Components.Add(Torso)

	Begin Object Class=SkeletalMeshComponent Name=Arms
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kArmsMC = Arms
	Components.Add(Arms)

	Begin Object Class=SkeletalMeshComponent Name=Legs
	bHasPhysicsAssetInstance = FALSE
	bOwnerNoSee = FALSE
	bIgnoreOwnerHidden = FALSE
	CollideActors = TRUE
	BlockZeroExtent = TRUE
	bAcceptsDynamicDecals = TRUE
	End Object

	m_kLegsMC = Legs
	Components.Add(Legs)

	Begin Object Class=SkeletalMeshComponent Name=Helmet
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kHelmetMC = Helmet
	Components.Add(Helmet)

	Begin Object Class=SkeletalMeshComponent Name=DecoKit
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kDecoKitMC = DecoKit
	Components.Add(DecoKit)

	Begin Object Class=SkeletalMeshComponent Name=EyeMesh
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kEyeMC = EyeMesh
	Components.Add(EyeMesh)

	Begin Object Class=SkeletalMeshComponent Name=TeethMesh
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kTeethMC = TeethMesh
	Components.Add(TeethMesh)


	Begin Object Class=SkeletalMeshComponent Name=HairMesh
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kHairMC = HairMesh
	Components.Add(HairMesh)

	Begin Object Class=SkeletalMeshComponent Name=BeardMesh
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kBeardMC = BeardMesh
	Components.Add(BeardMesh)


	Begin Object Class=SkeletalMeshComponent Name=UpperFacialMesh
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	m_kUpperFacialMC = UpperFacialMesh
	Components.Add(UpperFacialMesh)

	Begin Object Class=SkeletalMeshComponent Name=LowerFacialMesh
		bHasPhysicsAssetInstance = FALSE
		bOwnerNoSee = FALSE
		bIgnoreOwnerHidden = FALSE
		CollideActors = TRUE
		BlockZeroExtent = TRUE
		bAcceptsDynamicDecals = TRUE
	End Object

	FollowDelay = 0.2f

	m_kLowerFacialMC = LowerFacialMesh
	Components.Add(LowerFacialMesh)

	//RemoteRole=ROLE_SimulatedProxy`
	//bAlwaysRelevant=true
	RemoteRole=ROLE_None
	bAlwaysRelevant=false
	m_bReplicateHidden=false

	m_bTurnFinished=true
	bUseObstructionShader=true
	bSkipIK=false

	PathingRadius=19.0f
	CollisionRadius=14.0f
	CollisionHeight=64.0f

	DistanceFromCoverToCenter = 36.0f // Default for cover location used to be 40.  Now the cover location is 4 from the wall

	bSelfFlankedSystemOK=false

	m_eOpenCloseState = eUP_None

	bAllowFireFromSuppressIdle = false

	m_WeaponSocketNameToUse="gun_fire"
	AimSocketOrBone="gun_fire"
	AimEnabled = false;
	AimOffset = (X=0.0f, Y=0.0f);
	StartingAimOffset = (X=0.0f, Y=0.0f);
	AimShouldTurn = false;
	AimCurrentBlendTime = 0.0f;
	AimTotalBlendTime = 1.0f;
	AimBlendCurve = (Points = ((InVal = 0.0f, OutVal = 0.0f, ArriveTangent = 0, LeaveTangent = 0, InterpMode = CIM_CurveAuto), (InVal = 1.0f, OutVal = 1.0f, ArriveTangent = 0, LeaveTangent = 0, InterpMode = CIM_CurveAuto)))

	HiddenSlots(0)=eSlot_RearBackPack;
	HiddenSlots(1)=eSlot_LowerBack;

	/* zel: refrencing old Visibility MIC's
	HumanGlowMaterial=MaterialInstance'FX_Visibility.Materials.MInst_HumanGlow'
	AlienGlowMaterial=MaterialInstance'FX_Visibility.Materials.MInst_AlienGlow'
	CivilianGlowMaterial=MaterialInstance'FX_Visibility.Materials.MInst_CivilianGlow'
	*/

	bShouldRotateToward = false;

	HumanGlowMaterial=MaterialInstanceConstant'UI_3D.Unit.Unit_Xray_Player'
	AlienGlowMaterial=MaterialInstanceConstant'UI_3D.Unit.Unit_Xray_Alien'
	CivilianGlowMaterial=MaterialInstanceConstant'UI_3D.Unit.Unit_Xray_Civilian'

	//These are from EU and are totally bogus, but look decent enough.
	ThrowGrenadeStartPosition = (X=-12.928f, Y=33.727f, Z=111.398f) //default is correct for soldiers
	ThrowGrenadeStartPositionUnderhand = (X=46.8f, Y=23.996f, Z=40.395f) //default is correct for soldiers

	Into_Idle_Blend=0.25f

	m_bWaitingToTurnIntoZombie=false
	m_kLootSparkles=Material'Materials.Approved.Looting'
	LootGlintColorParam="LootGlintColor"
	DefaultLootGlint = (R=1.0f, G=0.75f, B=0.25f, A=1.0f)
	HighlightedLootGlint = (R=1.0f, G=0.5f, B=0.05f, A=1.0f)
}
