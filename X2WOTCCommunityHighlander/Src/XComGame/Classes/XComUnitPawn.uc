class XComUnitPawn extends XComLocomotionUnitPawn
	abstract	
	hidecategories(Physics,Collision,PrimitiveComponent,Rendering); // basically, everything

var() vector					    LocalCameraOffset;
var() float						    CameraFocusDistance;
var() float						    AimAtTargetMissPercent;	    // Percent towards our miss location we should aim (0.0 to 1.0)
var() float                         TurnSpeedMultiplier;        // If a unit is configured with m_bShouldTurnBeforeMoving, this is a multiplier that affects the units turn speed when moving
var protected  array<int>	        m_kUpdateWhenNotRenderedStack;

var AnimNodeSequence				TurningSequence;

var XComTacticalGame	            m_kTacticalGame;

// used for moving cosmetic pawns offscreen and out of the way of UI
var string HQIdleAnim;
var string HQOffscreenAnim;
var string HQOnscreenAnimPrefix;
var  Vector HQOnscreenOffset;
var  Vector HQOnscreenLocation;

//Supports patterns/ color customization ( mostly for the gremlin, but might be useful for aliens too )
//Base added to the end of these var names to 
var transient protectedwrite TAppearance m_kAppearanceBase; 
var transient private XComPatternsContent PatternsContentBase;
var transient int NumPossibleTints;

// static/abstract class that contains the list of sounds
// for this type of pawn
var() XComFootstepSoundCollection Footsteps;

// Allow for arbitrary body part attachments
//******************************
var() name DefaultIdleAnimation <ToolTip = "Specify an animation name to use as this unit's default idle when in the HQ. This is designed to be used with units that won't have a personality setting to provide the idle animation. So, aliens, civilians, etc.">;
var() array<XComBodyPartContent>			DefaultAttachments<ToolTip = "XComBodyPartContent archetypes in this array will be automatically attached to the character when it is created">;
var transient array<XComPawnPhysicsProp>    m_aPhysicsProps;
var transient array<SkeletalMeshComponent>	AttachedMeshes; //Container for generic attached skeletal components
//******************************

// Wise Settings
var() name AkEventCharacterSwitch<ToolTip="Some characters used a shared animation set. This value controls the Wise character selector, allowing Wise events to play a character specific sound from the same AkEvent">;

//var LightingChannelsObject OutsideLightChannels;
//var LightingChannelsObject InsideLightChannels;
var() DynamicLightEnvironmentComponent LightEnvironment;
var() CharacterLightRigComponent LightRig;

var StaticMeshComponent	        RangeIndicator;                     //Indicates attack range of enemy
var StaticMesh                  CloseAndPersonalRing;
var StaticMesh                  ArcThrowerRing;
var StaticMesh                  CivilianRescueRing;
var StaticMesh                  MedikitRing;
var StaticMesh                  KineticStrikeCard;
var StaticMesh                  FlamethrowerCard;

var() protected DamageTypeHitEffectContainer DamageEffectContainer;			// Effects that can be used when this pawn is shot

// If true we will keep our matinee animations set on the mesh when the matinee ends
var bool m_bRemainInAnimControlForDeath;

// An actor that this unit should be looking at
var     Actor m_kLookAtTarget;

// multiplier for whenever we add an inpulse to a rigid body actor
var() float PhysicsPushScale;
var() float WeaponScale;
var() float PerkEffectScale;

var() bool PlayNonFootstepSounds;
var() bool bDoDyingActions;
var bool bFinalRagdoll; //FALSE indicates the unit will get back up after rag-dolling, otherwise the unit will freeze after rag-dolling
var Vector DeathRestingLocation;

var float fFallImpactSoundEffectTimer;

var vector PreviousHeadLocation;

var() EXComUnitPawn_RagdollFlag RagdollFlag;
var() float                     RagdollBlendTime; //This determines how long the state 'RagDollBlend' will spend blending from full anim weights to full physics
var() bool                      SmashEnvironmentOnDeath; //If true, the character's death animation will destroy environmental objects
var array<PrimitiveComponent>   TempCollisionComponents; //These collision components are temporarily disabled while a character is ragdolling. This is for frac mesh actors.
var float                       RagdollFinishTimer; //After this long in the RagdollBlend state, the ragdoll will be frozen and the state will exit. Defaults to 10 seconds.
var private float               DefaultRagdollFinishTimer;
var float                       WaitingToBeDestroyedTimer;
var bool						bReactionFireDeath; //TRUE if this unit was killed by reaction fire. Determined by the death animation computation in the death action.
var float						RagdollDistance; //Set by KnockbackDistance in X2Action_Knockback
var float						DragRagdollDistanceThreshold; //RagdollDistance must be this large or larger in order for us to use the logic that pulls the ragdoll to a specific location

// Made these members because we delay ragdoll effects slightly
var vector DyingImpulse;
var TraceHitInfo DyingHitInfo;

const MAX_TARGETS = 16;

/**
 *  Controls the character's behavior, visuals, and effects while it is in the 'Dying' state
 */
var() XComDeathHandler  DeathHandlerTemplate;
var XComDeathHandler    m_deathHandler;

var repnotify Vector    m_vTeleportToLocation;

var() bool  m_bHasFullAnimWeightBones;

var bool bIsFemale;

var() array<Texture2D> UITextures<Tooltip="Any required UI textures, this makes a reference so the cooker will bring them in">;

var float fPhysicsMotorForce;
var bool bAnimatedRagdoll;
var bool bProcessingDeathOnLoad;
var vector LastHeadBoneLocation;

var bool m_bInWater;
var float m_fWaterWorldZ;
var array<ParticleSystem> m_aInWaterParticleSystems;
var TriggerVolume m_kLastWaterVolume;

var() const SkeletalMesh CovertOpsMesh;

//Used by the Exalt death anim when they are stunned
var() const SkeletalMesh ExaltSuicideSyringeMesh;

// If this is true, the LeftHandIK enables in code are ignored and are only set through anim notifies
var() bool m_bOnlyAllowAnimLeftHandIKNotify;
var() bool m_bDropWeaponOnDeath;

var bool m_bTutorialCanDieInMatinee;

// Closer than this distance we will use our CloseRangeMissAngleMultiplier
var() float CloseRangeMissDistance;
// The distance at/past which we will use our NormalMissAngleMultiplier (interpolated between close and normal)
var() float NormalMissDistance;
// The miss angle multiplier to use for normal distances
var() float NormalMissAngleMultiplier;
// The miss angle multiplier to use for close distances
var() float CloseRangeMissAngleMultiplier;

var() bool EvacWithRope;

var protected float fHiddenTime;      //  used in STRATEGY to track how long the pawn has been loading itself
var bool bAllowPersistentFX;          //  used in STRATEGY only

var bool bUseDesiredEndingAtomOnDeath;

var private bool m_bWasIdleBeforeMatinee;
var private name QueuedDialogAnim; //Temp storage for a line of dialog that this pawn should play.
var private XComNarrativeMoment DialogNarrativeMoment;

var transient bool bPhotoboothPawn;

// Issue #641
// This array is private as it is internal CHL logic and mods do not need to access it directly
// If you have a use case for accessing this array, open a new issue
var private array<Actor> AdvancedBodyPartActors;

delegate AdditionalHitEffect( XComUnitPawn Pawn );

event RigidBodyCollision( PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex )
{
	local XComGameState_Unit UnitState;

	if (fFallImpactSoundEffectTimer > 0.05f)   // these values were found empirically. The timer is used for general purpose now.
	{
		fFallImpactSoundEffectTimer = -0.05f;  // setting less than 0, makes the delay longer for subsequent plays
		PlayBodyFallImpactSound();

		if(bWaitingForRagdollNotify && ((OtherComponent == none) ||
		   		   (!OtherComponent.Owner.IsA('XComUnitPawn') &&  //Don't cancel our rag doll due to collisions with other pawns
		   		   !OtherComponent.Owner.IsA('XComWeapon') &&    //Or their weapons
		   		   !OtherComponent.Owner.IsA('KActorSpawnable')))) //Or their loots
		{	
			// chosen should never disable their death anims in favor of ragdoll due to RigidBodyCollisions
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kGameUnit.ObjectID));
			if (
				UnitState == none ||
				!UnitState.GetMyTemplate().bIsChosen ||
				(UnitState.GetMyTemplate().bIsChosen && class'CHHelpers'.default.ENABLE_CHOSEN_RAGDOLL) // Conditional for Issue #41
			)
			{
				bWaitingForRagdollNotify = false;
				//`log("RigidBodyCollision happened during ragdoll death, setting bWaitingForRagdollNotify to FALSE");
			}
		}
	}	
}

event EXComUnitPawn_RagdollFlag GetRagdollFlag( )
{
	return RagdollFlag;
}

simulated event SetInWater(bool bInWater, optional float fWaterWorldZ, optional array<ParticleSystem> InWaterParticles)
{
	m_bInWater = bInWater;
	m_fWaterWorldZ = fWaterWorldZ;
	m_aInWaterParticleSystems = InWaterParticles;
}

simulated event SetVisible(bool bVisible)
{
	if (m_bVisible && !bVisible)
	{
		FadeOutPawnSounds();
	}
	else if (!m_bVisible && bVisible)
	{
		FadeInPawnSounds();
	}

	super.SetVisible(bVisible);
	// civilians don't have weapons - was causing error spam
	if (Weapon != none)
	{
		XComWeapon(Weapon).SetVisible(bVisible);
	}
}

simulated event Attach(Actor Other)
{
	super.Attach(Other);
}

simulated event Detach(Actor Other)
{
	super.Detach(Other);
}

function SetCinLightingChannels()
{
	local LightingChannelContainer CinLightingChannels;

	m_DefaultLightingChannels = Mesh.LightingChannels;

	CinLightingChannels.bInitialized = true;

	if (GetGameUnit() != none /*&& (GetGameUnit().GetCharacter().IsA('XGCharacter_Soldier') || GetGameUnit().GetCharacter().IsA('XGCharacter_Tank'))*/ ) // total hack for now, courtesy of demo -cdoyle    jbouscher - REFACTORING CHARACTERS
	{		
		CinLightingChannels.Cinematic_1 = true;
		m_kHeadMeshComponent.SetLightingChannels(CinLightingChannels);
	}
	else
	{
		CinLightingChannels.Cinematic_4 = true;
	}

	Mesh.SetLightingChannels(CinLightingChannels);
}

function RestoreDefaultLightingChannels()
{
	Mesh.SetLightingChannels(m_DefaultLightingChannels);

	if (GetGameUnit() != none/* && (GetGameUnit().GetCharacter().IsA('XGCharacter_Soldier') || GetGameUnit().GetCharacter().IsA('XGCharacter_Tank')) */)    //  jbouscher - REFACTORING CHARACTERS
	{
		m_kHeadMeshComponent.SetLightingChannels(m_DefaultLightingChannels);
	}
}

simulated function PlayerController GetOwningPlayerController()
{
	return GetGameUnit().GetOwningPlayerController();
}

simulated function LookAt( Actor kLookAt )
{
	//kLookAt = XComTacticalController(GetGameUnit().Owner).GetCursor();
	// NOTE:  This is called every frame by the gamecore.  A value of 'none' should reset the pawn to not look at anything.
	if( m_kLookAtTarget != kLookAt )
	{
		m_kLookAtTarget = kLookAt;
	}
}

function PlayBodyFallImpactSound()
{
	if(!bProcessingDeathOnLoad)
	{
		PostAkEvent(AkEvent'SoundX2CharacterFX.XCom_and_Advent_Bodyfall_RagDoll');
	}
}

simulated event PlayFootStepSound(int FootDown)
{
	local bool bIsOutsideAndIsRaining;

	if (`XTACTICALSOUNDMGR != none) // Only in tactical will there be an XComSoundManager
	{
		if(WorldInfo.NetMode != NM_Standalone)
		{
			// MP: if the unit isn't visible, don't play the sound. otherwise opponents can 'scan' the map by moving the cursor when its not their turn and listen for footstep sounds. -tsmith
			if(!m_bVisible)
				return;
		}

		bIsOutsideAndIsRaining = !IndoorInfo.IsInside();

		if (Footsteps != none)
			Footsteps.PlayFootstepSound( self, FootDown, GetMaterialTypeBelow(), bIsOutsideAndIsRaining );

		if (m_bInWater)
		{
			PlayInWaterParticles(FootDown);
		}
	}
}

simulated event PlayInWaterParticles(int FootDown)
{
	local int i;
	local Vector Loc;
	local float FeetZs;
	local Vector FeetLocation;

	FeetLocation = GetFeetLocation();
	FeetZs = `XWORLD.GetFloorZForPosition(FeetLocation);
	if(FeetZs > m_fWaterWorldZ)
		return;     //  don't play if we are standing above the water

	Loc = Location;
	Loc.Z = m_fWaterWorldZ;	

	for (i = 0; i < m_aInWaterParticleSystems.Length; i++)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter( m_aInWaterParticleSystems[i], Loc,  Rotation);
	}
}

/**
 * Plays sounds for the owning player only.
 * NOTE: do NOT call this function directly. Call XGUnit::UnitSpeak so the server can enforce rules.
 */
reliable client function UnitSpeak( Name nCharSpeech )
{
	// jboswell: Override this in subclasses (Soldiers use XComHumanPawn's version)
}

// called when pawn leaves PHYS_Falling
event Landed(vector HitNormal, actor FloorActor)
{
	local vector Impulse;

	Super.Landed(HitNormal, FloorActor);

	// add impulse to Vehicles, DynamicSMActors...
	Impulse.Z = Velocity.Z;

	ApplyImpulseToPhysicsActor( FloorActor, Impulse, Location );
}

event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
	local vector Impulse;
	super.Bump( Other, OtherComp, HitNormal );

	Impulse = Velocity;
	ApplyImpulseToPhysicsActor( Other, Impulse, Location );
}

function ApplyImpulseToPhysicsActor( Actor PhysActor, vector Impulse, vector HitLocation )
{
	Impulse *= PhysicsPushScale;

	if ( DynamicSMActor(PhysActor) != none )
	{
		DynamicSMActor(PhysActor).StaticMeshComponent.AddImpulse( Impulse, HitLocation );
	}
	else if ( KAsset(PhysActor) != none )
	{
		KAsset(PhysActor).SkeletalMeshComponent.AddImpulse( Impulse, HitLocation );
	}
}

simulated function DamageTypeHitEffectContainer GetDamageTypeHitEffectContainer()
{
	return DamageEffectContainer;
}

/// HL-Docs: feature:OverrideHitEffects; issue:825; tags:tactical
/// Allows listeners to change behavior of `XComUnitPawn::PlayHitEffects()`.
/// Listeners can set `OverrideHitEffect` to `true`, 
/// and then the default behavior will be omitted entirely,
/// and no hit effect will be played.
///
/// Alternatively, listeners can modify the parameters passed with the Tuple 
/// to modify the default behavior.
///
/// For example, this listener can be used to prevent Templar purple hit effects
/// from playing for any attack that has the hit result eHit_Parry, 
/// eHit_Reflect or eHit_Deflect.
///
/// ```event
/// EventID: OverrideHitEffects,
/// EventData: [
///     inout bool OverrideHitEffect,
///     inout float Damage,
///     in Actor InstigatedBy,
///     inout vector HitLocation,
///     inout name DamageTypeName,
///     inout vector Momentum,
///     inout bool bIsUnitRuptured,
///     inout enum[EAbilityHitResult] HitResult,
/// ],
/// EventSource: XComUnitPawn (Pawn),
/// NewGameState: none
/// ```
simulated private function bool TriggerOnOverrideHitEffects(
	// Start Issue #1114 - make some of the function arguments 'out'.
	out float Damage,
	Actor InstigatedBy,
	out vector HitLocation,
	out name DamageTypeName,
	out vector Momentum,
	out int iIsUnitRuptured,
	out EAbilityHitResult HitResult
	// End Issue #1114
)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideHitEffects';
	Tuple.Data.Add(8);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false; // Override default hit effects
	Tuple.Data[1].kind = XComLWTVFloat;
	Tuple.Data[1].f = Damage;
	Tuple.Data[2].kind = XComLWTVObject;
	Tuple.Data[2].o = InstigatedBy;
	Tuple.Data[3].kind = XComLWTVVector;
	Tuple.Data[3].v = HitLocation;
	Tuple.Data[4].kind = XComLWTVName;
	Tuple.Data[4].n = DamageTypeName;
	Tuple.Data[5].kind = XComLWTVVector;
	Tuple.Data[5].v = Momentum;
	Tuple.Data[6].kind = XComLWTVBool;
	Tuple.Data[6].b = iIsUnitRuptured != 0;
	Tuple.Data[7].kind = XComLWTVInt;
	Tuple.Data[7].i = HitResult;

	`XEVENTMGR.TriggerEvent('OverrideHitEffects', Tuple, self);

	// Start Issue #1114 - update function arguments from Tuple.
	Damage = Tuple.Data[1].f;
	HitLocation = Tuple.Data[3].v;
	DamageTypeName = Tuple.Data[4].n;
	Momentum = Tuple.Data[5].v;
	iIsUnitRuptured = Tuple.Data[6].b ? 1 : 0;
	HitResult = EAbilityHitResult(Tuple.Data[7].i);
	// End Issue #1114

	return Tuple.Data[0].b;
}


simulated function PlayHitEffects(float Damage, Actor InstigatedBy, vector HitLocation, name DamageTypeName, vector Momentum, bool bIsUnitRuptured, EAbilityHitResult HitResult= eHit_Success, optional TraceHitInfo ThisHitInfo )
{
	local XComPawnHitEffect HitEffect;
	local XComPawnHitEffect HitEffectTemplate, RuptureEffectTemplate;
	local vector HitNormal;
	local XComPerkContentShared kPerkContent;
	local DamageTypeHitEffectContainer DamageContainer;
	local XGUnit SourceUnit;
	local int iIsUnitRuptured; // Variable for Issue #825

	// Start Issue #825
	iIsUnitRuptured = bIsUnitRuptured ? 1 : 0;
	if (TriggerOnOverrideHitEffects(Damage, InstigatedBy, HitLocation, DamageTypeName, Momentum, iIsUnitRuptured, HitResult))
	{
		return;
	}
	bIsUnitRuptured = iIsUnitRuptured != 0;
	// End Issue #825

	// The HitNormal used to have noise applied, via "* 0.5 * VRand();", but S.Jameson requested 
	// that it be removed, since he can add noise with finer control via the editor.  mdomowicz 2015_07_06
	HitNormal = Normal(Momentum);

	DamageContainer = GetDamageTypeHitEffectContainer();

	if (DamageContainer != none)
		HitEffectTemplate = DamageContainer.GetHitEffectsTemplateForDamageType(DamageTypeName,HitResult);

	if (HitEffectTemplate != none)
		HitEffect = Spawn(class'XComPawnHitEffect',self,,HitLocation, Rotator(HitNormal),HitEffectTemplate);

	if (HitEffect != None)
	{
		`log("PlayHitEffects" @ HitEffect, , 'XCom_Visualization');

		if( HitResult == eHit_Parry || HitResult == eHit_Deflect )
		{
			ThisHitInfo.BoneName = 'R_Gauntlet';
			ThisHitInfo.HitComponent = self.Mesh;
		}
		else if( HitResult == eHit_Reflect )
		{
			ThisHitInfo.BoneName = 'FX_Psi_Ball_L';
			ThisHitInfo.HitComponent = self.Mesh;
		}

		if (ThisHitInfo.HitComponent == self.Mesh)
			HitEffect.AttachTo(self, ThisHitInfo.BoneName);
		else
			HitEffect.AttachTo(self, '');
	}

	if (bIsUnitRuptured)
	{
		if (DamageContainer != none)
		{
			RuptureEffectTemplate = DamageContainer.GetRuptureHitEffectsTemplateForDamageType(DamageTypeName);
		}

		if (RuptureEffectTemplate != none)
		{
			Spawn(class'XComPawnHitEffect', , , HitLocation, Rotator(HitNormal), RuptureEffectTemplate);
		}
	}

	foreach arrTargetingPerkContent( kPerkContent )
	{
		kPerkContent.OnDamage( self );
	}

	SourceUnit = XGUnit(InstigatedBy);
	if( SourceUnit != None && SourceUnit.CurrentPerkAction != None )
	{
		SourceUnit.CurrentPerkAction.TriggerActivationDamageEffects(self);
	}
}

/// HL-Docs: feature:OverrideMetaHitEffect; issue:1116; tags:tactical
/// Allows listeners to change the behavior of `XComUnitPawn::PlayMetaHitEffect()`.
/// Meta Hit Effects are intended to communicate the overall effect of the attack,
/// and include things like blood gushing out of the unit.
///
/// Listeners can set `OverrideMetaHitEffect` to `true`, 
/// and then the default behavior will be omitted entirely,
/// and no meta hit effect will be played.
///
/// Alternatively, listeners can modify the parameters passed with the Tuple 
/// to modify the default behavior.
///
/// ```event
/// EventID: OverrideMetaHitEffect,
/// EventData: [
///     inout bool OverrideMetaHitEffect,
///     inout vector HitLocation,
///     inout name DamageTypeName,
///     inout vector Momentum,
///     inout bool bIsUnitRuptured,
///     inout enum[EAbilityHitResult] HitResult,
/// ],
/// EventSource: XComUnitPawn (Pawn),
/// NewGameState: none
/// ```
simulated private function bool TriggerOnOverrideMetaHitEffect(
	out vector HitLocation,
	out name DamageTypeName,
	out vector Momentum,
	out int iUnitIsRuptured,
	out EAbilityHitResult HitResult
)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideMetaHitEffect';
	Tuple.Data.Add(6);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false; // Override default hit effects
	Tuple.Data[1].kind = XComLWTVVector;
	Tuple.Data[1].v = HitLocation;
	Tuple.Data[2].kind = XComLWTVName;
	Tuple.Data[2].n = DamageTypeName;
	Tuple.Data[3].kind = XComLWTVVector;
	Tuple.Data[3].v = Momentum;
	Tuple.Data[4].kind = XComLWTVBool;
	Tuple.Data[4].b = iUnitIsRuptured != 0;
	Tuple.Data[5].kind = XComLWTVInt;
	Tuple.Data[5].i = HitResult;

	`XEVENTMGR.TriggerEvent('OverrideMetaHitEffect', Tuple, self);

	HitLocation = Tuple.Data[1].v;
	DamageTypeName = Tuple.Data[2].n;
	Momentum = Tuple.Data[3].v;
	iUnitIsRuptured = Tuple.Data[4].b ? 1 : 0;
	HitResult = EAbilityHitResult(Tuple.Data[5].i);

	return Tuple.Data[0].b;
}

// The Meta Hit Effect is played once per shot (and NOT for every individual projectile), and
// is useful for showing an "overall" effect of the shot.  mdomowicz 2015_04_30
simulated function PlayMetaHitEffect(vector HitLocation, name DamageTypeName, vector Momentum, bool bIsUnitRuptured, EAbilityHitResult HitResult= eHit_Success, optional TraceHitInfo ThisHitInfo )
{
	local XComPawnHitEffect HitEffect;
	local XComPawnHitEffect HitEffectTemplate, RuptureEffectTemplate;
	local vector HitNormal;
	local DamageTypeHitEffectContainer DamageContainer;
	local XComPerkContentShared kPerkContent;
	local int iUnitIsRuptured; // Variable for Issue #1116

	// Start Issue #1116
	iUnitIsRuptured = bIsUnitRuptured ? 1 : 0;
	if (TriggerOnOverrideMetaHitEffect(HitLocation, DamageTypeName, Momentum, iUnitIsRuptured, HitResult))
	{
		return;
	}
	bIsUnitRuptured = iUnitIsRuptured > 0;
	// End Issue #1116

	// The HitNormal used to have noise applied, via "* 0.5 * VRand();", but S.Jameson requested 
	// that it be removed, since he can add noise with finer control via the editor.  mdomowicz 2015_07_06
	HitNormal = Normal(Momentum);

	DamageContainer = GetDamageTypeHitEffectContainer();

	if (DamageContainer != none)
		HitEffectTemplate = DamageContainer.GetMetaHitEffectTemplateForDamageType(DamageTypeName,HitResult);

	if (HitEffectTemplate != none)
		HitEffect = Spawn(class'XComPawnHitEffect',self,,HitLocation, Rotator(HitNormal),HitEffectTemplate);

	if (HitEffect != None)
	{
		`log("PlayMetaHitEffect" @ HitEffect, , 'XCom_Visualization');
		if (ThisHitInfo.HitComponent == self.Mesh)
			HitEffect.AttachTo(self, ThisHitInfo.BoneName);
		else
			HitEffect.AttachTo(self, '');
	}

	if (bIsUnitRuptured)
	{
		if (DamageContainer != none)
		{
			RuptureEffectTemplate = DamageContainer.GetMetaRuptureHitEffectTemplateForDamageType(DamageTypeName);
		}

		if (HitEffectTemplate != none)
		{
			Spawn(class'XComPawnHitEffect', , , HitLocation, Rotator(HitNormal), RuptureEffectTemplate);
		}
	}

	foreach arrTargetingPerkContent( kPerkContent )
	{
		kPerkContent.OnMetaDamage( self );
	}
}

// MHU - Easy to turn off, harder to turn on.
simulated function SkelMeshOptimizationCheck(optional bool bEnable = false)
{
	local XGUnit kUnit;
	local bool bCanEnableOptimizations;

	kUnit = XGUnit(GetGameUnit());
	if (kUnit != none &&
		!kUnit.IsUnitBusy())
		bCanEnableOptimizations = true;

	if (bCanEnableOptimizations && bEnable)
	{
		SetUpdateSkelWhenNotRendered(false);
		Mesh.bIgnoreControllersWhenNotRendered = true;
	}
	else
	{
		SetUpdateSkelWhenNotRendered(true);
		Mesh.bIgnoreControllersWhenNotRendered = false;
	}
}

// our version of Pawn::PlayDying. we dont tear off simulation to allow clients to properly handle pawn death
// and let references to the pawn continue to replicate as needed. -tsmith 
simulated function XComSuperPlayDying(class<DamageType> DamageTypeClass, vector HitLoc)
{
	if(VSize(DyingImpulse) == 0.0f) //failsafe - normally set inside of the knock back action
	{
		DyingImpulse = TearOffMomentum * 400.0f;
		if(DyingImpulse.Z < 50.0f) //Apply an up impulse if needed
		{
			DyingImpulse += Vect(0, 0, 1) * 300.0f;
		}
	}

	GotoState('Dying');
	bReplicateMovement = false;
		
	SetDyingPhysics();
	bPlayedDeath = true;
	LifeSpan = 9999999.0f;
}

simulated function PlayDying(class<DamageType> DamageTypeClass, vector HitLoc, optional Name AnimName='', optional vector Destination)
{
	local CustomAnimParams AnimParams;
	local XComGameState_Unit UnitState;
	local X2DamageTypeTemplate DamageTypeTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local AnimNodeSequence DeathAnim;
	local XComUnitPawn CarriedPawn;
	local DamageTypeHitEffectContainer DamageContainer;
	local name PlayAnimationName;

	local int Index;
	local bool bRagdollImmediately;
	local bool bCanPlayAnim;

	local X2Action CurrentAction;
	local X2Action_Death DeathAction;
	local bool bPlayDamageContainerEffect;
	local bool bPlayDamageContainerSound;

	HitDamageType = DamageTypeClass;
	TakeHitLocation = HitLoc;	 
	DeathRestingLocation = Destination;
	DeathRestingLocation.Z = GetDesiredZForLocation(DeathRestingLocation);

	if (!bDoDyingActions)
		return;

	DamageContainer = GetDamageTypeHitEffectContainer();
	if (DamageContainer == none)
	{
		`log("No DamageEffectContainer on" @ Name $ ". No sounds or effects will be played.");
	}

	//Drop any unit we're carrying
	CarriedPawn = XComUnitPawn(CarryingUnit);
	if (CarriedPawn != None)
	{
		CarryingUnit = None;
		CarriedPawn.bRunPhysicsWithNoController = true;
		CarriedPawn.UnitCarryingMe = None;
		GetAnimTreeController().DetachChildController(CarriedPawn.GetAnimTreeController());
		CarriedPawn.StartRagDoll();
	}

	bPlayDamageContainerEffect = true;
	bPlayDamageContainerSound = true;

	CurrentAction = `XCOMVISUALIZATIONMGR.GetCurrentActionForVisualizer(m_kGameUnit);
	DeathAction = X2Action_Death(CurrentAction);
	if (DeathAction != none)
	{
		bPlayDamageContainerEffect = DeathAction.ShouldPlayDamageContainerDeathEffect();
		bPlayDamageContainerSound = DeathAction.DamageContainerDeathSound();
	}
	
	if (bPlayDamageContainerEffect && DamageContainer != none && DamageContainer.DeathEffect != none)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(DamageContainer.DeathEffect, HitLoc, rot(0,0,1) );
	}

	if (bPlayDamageContainerSound && DamageContainer != none && DamageContainer.DeathSound != none)
	{
		PlaySound(DamageContainer.DeathSound);
	}
	
	//Gather information on how this unit died
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kGameUnit.ObjectID));
	
	//Find out whether this unit should cut to ragdoll immediately
	bRagdollImmediately = false;
	for(Index = 0; Index < UnitState.KilledByDamageTypes.Length; ++Index)
	{
		DamageTypeTemplate = ItemTemplateManager.FindDamageTypeTemplate(UnitState.KilledByDamageTypes[Index]);
		if( DamageTypeTemplate != none )
		{
			bRagdollImmediately = bRagdollImmediately || !DamageTypeTemplate.bAllowAnimatedDeath;
		}
	}

	// If a unit cannot Ragdoll, then they should be playing a death animation
	PlayAnimationName = AnimName;
	
	//Check to make sure we can actually play the desired death animation
	bCanPlayAnim = GetAnimTreeController().CanPlayAnimation(PlayAnimationName);
	if( !bReactionFireDeath && (!bCanPlayAnim || bRagdollImmediately) )
	{
		PlayAnimationName = 'HL_DeathDefault';
		bCanPlayAnim = GetAnimTreeController().CanPlayAnimation(PlayAnimationName);
	}

	// If we are loading don't play an animation
	bCanPlayAnim = bCanPlayAnim && !bProcessingDeathOnLoad;

	// If a unit cannot Ragdoll, then they should be playing a death animation
	if ( RagdollFlag == ERagdoll_Never )
	{
		bCanPlayAnim = true;
	}

	XComSuperPlayDying( DamageTypeClass, HitLoc );

	if( bUseDesiredEndingAtomOnDeath )
	{
		AnimParams.DesiredEndingAtoms.Add(1);
		AnimParams.DesiredEndingAtoms[0].Translation = Destination;
		AnimParams.DesiredEndingAtoms[0].Translation.Z = GetGameUnit().GetDesiredZForLocation(AnimParams.DesiredEndingAtoms[0].Translation); // TODO: Need to somehow let this know we don't want to goto Z
		AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(Rotation);
		AnimParams.DesiredEndingAtoms[0].Scale = 1.0f;
	}

	if(bCanPlayAnim)
	{	
		bWaitingForRagdollNotify = true;
		AnimParams.AnimName = PlayAnimationName;
		RagdollBlendTime = default.RagdollBlendTime;
		RagdollFinishTimer = RagdollFinishTimer;
	}
	else
	{
		AnimParams.HasPoseOverride = true;
		AnimParams.Pose = Mesh.LocalAtoms;
		AnimParams.PoseOverrideDuration = 1.0f;

		bWaitingForRagdollNotify = false;
		RagdollBlendTime = AnimParams.PoseOverrideDuration;
		RagdollFinishTimer = AnimParams.PoseOverrideDuration + 2.0f; // 2 Seconds of ragdoll after the pose
	}

	StartRagDoll(bCanPlayAnim);
	
	if(!bProcessingDeathOnLoad || bCanPlayAnim)
	{
		EnableRMA(true, true);
		EnableRMAInteractPhysics(true);
		CollisionComponent.SetComponentRBFixed(FALSE); //We want RMA to move the root, but we don't want to fix the bones as this makes them kinematic ( and thus will ignore rigid body physics )
		DeathAnim = GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
		GetAnimTreeController().SetAllowNewAnimations(false); //Don't let idle control the character
	}
	else
	{
		EnableRMA(false, false);
		EnableRMAInteractPhysics(false);
		CollisionComponent.SetComponentRBFixed(FALSE); //We want RMA to move the root, but we don't want to fix the bones as this makes them kinematic ( and thus will ignore rigid body physics )
	}
				
	if (bWaitingForRagdollNotify)
	{
		SetTimer(DeathAnim.GetTimeLeft(), false, nameof(CheckRagdollStatus));
	}

	GetGameUnit().HideCoverIcon();

	m_bAuxParamNeedsPrimary = true;
	m_bAuxParamNeedsSecondary = false;
	m_bAuxParamUse3POutline = false;

	bScanningProtocolOutline = false;
	bTargetDefinitionOutline = false;
	SetAuxParameters(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);

	//Don't mark the unit "dead in visualizer" unless they're really dead (would prevent AOE-marking incapacitated units)
	if (UnitState.IsDead())
		m_kGameUnit.SetDeadInVisualizer();
}

function CheckRagdollStatus()
{
	bWaitingForRagdollNotify = false;
	//`log("CheckRagdollStatus was triggered, setting bWaitingForRagdollNotify to FALSE");
}

function SetFinalRagdoll(bool bSetting)
{
	bFinalRagdoll = bSetting;
}

function DelaySetRagdollLinearDriveToDestination()
{
	if (RagdollDistance > DragRagdollDistanceThreshold && !bReactionFireDeath)
	{
		//Make sure all bones are set to no bone springs
		SetDesiredBoneSprings(false, false, 0.0f, 0.0f, 0.0f, 0.0f);

		//Reset the values used to blend the physics weight
		fPhysicsMotorForce = 3.0f;		

		//Set the drive target
		SetRagdollLinearDriveToDestination(DeathRestingLocation, DyingImpulse, fPhysicsMotorForce, fPhysicsMotorForce / 80);
	}
	
	RagdollBlendTime = 1.0f;
}

simulated event StartRagDoll(optional bool bDoBoneSprings = true,
							 optional vector TranslationImpulse = vect(0, 0, 0),
							 optional vector RotationImpulse = vect(0, 0, 0),
							 bool DropWeapon = true)
{
	local vector AdditionalAngularVelocity;
	local vector UpVector;
	local vector FacingDir;
	local float RandomRotation;
	local bool bIsSoldier;
	local Vector HitDirection;
	local Actor HitActorHoriz;
	local Vector HitLocation;
	local Vector HitNormal;	
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local bool bReactionFireTarget;

	// Locking the mesh or forbidding ragdoll will exit early
	if(Mesh.bNoSkeletonUpdate || RagdollFlag == ERagdoll_Never)
	{
		return;
	}

	if(GetStateName() == 'RagDollBlend')
	{
		return;
	}

	if(DropWeapon)
	{
		XGUnit(GetGameUnit()).DropWeapon();
	}

	//Now that we are dead, let our attachments update using their own tick group.
	Mesh.bForceUpdateAttachmentsInTick = false;
	LockDownFootIK(false);
	EnableFootIK(false);
	EnableRMAInteractPhysics(false); //Make sure RMA physics is off, as this turns off collision ( important for ragdolls )

	//Always use bone springs, the bone springs target is set manually in the case where we don't have an animation. bDoBoneSprings indicates whether we should be driven by an anim or not
	bAnimatedRagdoll = bDoBoneSprings;

	Mesh.SetBlockRigidBody(true);
	Mesh.SetRBChannel(RBCC_Pawn, TRUE); // Wait to update the RB until the last update.
	Mesh.SetRBCollidesWithChannel(RBCC_Default, TRUE, TRUE);
	Mesh.SetRBCollidesWithChannel(RBCC_Pawn, TRUE, TRUE);
	Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, TRUE, TRUE);
	Mesh.SetRBCollidesWithChannel(RBCC_GameplayPhysics, TRUE, FALSE);

	Mesh.ForceSkelUpdate();
	Mesh.UpdateRBBonesFromSpaceBases(TRUE, TRUE);

	InitRagdoll();

	Mesh.PhysicsWeight = 1.0f;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_kGameUnit.ObjectID));
	bIsSoldier = UnitState.IsSoldier();

	//If we are a cover taking unit and a bonesprings request is coming down, check that the coast is clear. If the coast is NOT clear, ignore the bonesprings
	//request and use a standard ragdoll instead. This avoids ragdoll penetration events. You don't want those.
	if(m_kGameUnit.CanUseCover())
	{
		HitDirection = DyingImpulse;
		HitDirection.Z = 0.0f;
		HitDirection = Normal(HitDirection);
		HitActorHoriz = `XTRACEMGR.XTrace(eXTrace_World, HitLocation, HitNormal, Location + (HitDirection * class'XComWorldData'.const.WORLD_StepSize), Location, vect(10, 10, 10));
		//DrawDebugLine( Location, Location + (HitDirection * class'XComWorldData'.const.WORLD_StepSize), 120, 140, 232, true );		
		if(HitActorHoriz != none)
		{			
			//DrawDebugLine( Location, Location + (HitDirection * class'XComWorldData'.const.WORLD_StepSize), 255, 140, 140, true );		
			bAnimatedRagdoll = false;
		}
	}

	//Match the pose of the currently playing death animation
	if(!bProcessingDeathOnLoad)
	{
		if(bAnimatedRagdoll)
		{
			SetDesiredBoneSprings(true, true, fPhysicsMotorForce, fPhysicsMotorForce / 80, fPhysicsMotorForce, fPhysicsMotorForce / 80);
			Mesh.bUpdateKinematicBonesFromAnimation = true;
		}
		else 
		{
			//Use a custom bone spring target on just the root rigid body - the rest of the rag doll will simulate
			fPhysicsMotorForce = 0.0f;
			SetTimer(0.1f, false, nameof(DelaySetRagdollLinearDriveToDestination));
			Mesh.bUpdateKinematicBonesFromAnimation = true;
		}
	}
	else
	{
		fPhysicsMotorForce = 0.0f;

		Mesh.PhysicsAssetInstance.SetAngularDriveScale(1, 1, 0);
		Mesh.PhysicsAssetInstance.SetAllMotorsAngularPositionDrive(false, false, Mesh, true);
		Mesh.PhysicsAssetInstance.SetAllMotorsAngularDriveParams(fPhysicsMotorForce, fPhysicsMotorForce, 0, Mesh, true);
	}

	SetUpdateSkelWhenNotRendered(true); //make sure the skeleton updates, or else there won't be much rag dolling.
		
	Mesh.bSyncActorLocationToRootRigidBody = true;
	
	if(!bAnimatedRagdoll)
	{	
		if (bReactionFireDeath)
		{
			DyingImpulse = RMVelocity; //Continue our forward momentum
		}

		//Give soldiers a less ignominious death
		if (bIsSoldier)
		{
			DyingImpulse *= vect(0.1f, 0.1f, 0.2f);
		}

		//Give the unit some english...
		//Angular velocity setting is: vector direction is rotation axis, magnitude is velocity of rotation
		UpVector = vect(0, 0, 1);
		FacingDir = vector(Rotation);

		Mesh.SetRBLinearVelocity(DyingImpulse, false);

		//Are we in the middle of a move? Custom random rotation for reaction fire
		bReactionFireTarget = class'XComTacticalGRI'.static.GetReactionFireSequencer().GetTargetVisualizer() == m_kGameUnit;

		//Randomly select between a yaw ( spinning around ) and pitch ( head over heels ) death
		RandomRotation = FRand();
		if(RandomRotation <= 0.5f && !bReactionFireTarget) //no pitch if we are a reaction fire target
		{
			//pitch
			AdditionalAngularVelocity = Normal(FacingDir cross UpVector) * (4.0f + (FRand() * 12.0f));
		}
		else
		{
			//yaw
			AdditionalAngularVelocity = UpVector * (10.0f + ((-0.5f + (FRand() * 2.0f)) * 8.0f));
		}

		//If the dying impulse is zero, null out the rotation too. This mostly happens when loading a save and initing ragdolls from that.
		if(VSizeSq(DyingImpulse) == 0.0f)
		{
			AdditionalAngularVelocity = vect(0, 0, 0);
		}
		
		Mesh.SetRBAngularVelocity(AdditionalAngularVelocity, true);
	}

	GotoState('RagDollBlend');
}

// MHU - Adding counterpart to StartRagDoll
simulated function EndRagDoll()
{
	Mesh.SetBlockRigidBody(false);
	Mesh.SetRBChannel(RBCC_Pawn);
	Mesh.SetRBCollidesWithChannel(RBCC_Default, false);
	Mesh.SetRBCollidesWithChannel(RBCC_Pawn, false);
	Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, false);
	SetNoSkeletonUpdate(false);
	Mesh.bUpdateJointsFromAnimation = true;
	Mesh.PhysicsWeight = 0.0f;

	TermRagdoll();
	SetPhysics(PHYS_Walking);
	Mesh.ForceSkelUpdate();

	//Unset this flag, as it is used by other code to prevent dead units from playing animations. 
	//If the ragdoll state is ending, then we are presumably about to do something / play an anim. In many cases, this is but one of several flags checked to see if a unit is dead.
	bPlayedDeath = false;

	if( !IsInState('') )
		GotoState('');

	if( m_bHasFullAnimWeightBones )
	{
		Mesh.bEnableFullAnimWeightBodies = true;
		Mesh.SetHasPhysicsAssetInstance(TRUE);
		Mesh.bUpdateKinematicBonesFromAnimation = true;

		Mesh.SetBlockRigidBody(true);
		Mesh.SetRBChannel(RBCC_Pawn);
		Mesh.SetRBCollidesWithChannel(RBCC_Default, TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Pawn, TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, TRUE);

		// Ragdoll detaches all bodies so set them fixed to animation
		Mesh.PhysicsAssetInstance.SetAllBodiesFixed(true);

		// Except for bodies that say they should never be controlled by animation
		Mesh.PhysicsAssetInstance.SetFullAnimWeightBonesFixed(false, Mesh);

		Mesh.WakeRigidBody();
	}
}

simulated function UpdateAuxParameters(bool bDisableAuxMaterials)
{
	local XGUnitNativeBase kGameUnit;

	UpdateAuxParameterState(bDisableAuxMaterials);

	if (m_bAuxParametersDirty)
	{
		// if we have death handler we need to end it before reattaching our components otherwise particles will retrigger
		if (m_deathHandler != none)
		{
			m_deathHandler.EndDeath(self);
			m_deathHandler = none;
		}

		// If the pawn is dying or is dead and ticking for the last time, don't update the aux parameters, they've already been disabled
		kGameUnit = GetGameUnit();
		if (kGameUnit != none && kGameUnit.GetIsAliveInVisualizer())
		{
			SetAuxParameters(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
		}
	}
}

simulated event Tick(float DT)
{
`if(`notdefined(FINAL_RELEASE))	
	local Vector FireSocketLoc, vDir;
	local Rotator TrueAim;
`endif
	local XComTacticalCheatManager kTacticalCheatMgr;
	local bool bDisableAuxMaterials;
	local XComTacticalController kTacticalController;
	local PrimitiveComponent PreviousCollisionComponent;

	kTacticalController = XComTacticalController(GetALocalPlayerController());
	if (kTacticalController != none)
	{
		bDisableAuxMaterials = false;

		kTacticalCheatMgr = XComTacticalCheatManager(kTacticalController.CheatManager);
`if(`notdefined(FINAL_RELEASE))		
		if(kTacticalCheatMgr != none && kTacticalCheatMgr.bDebugWeaponSockets)
		{
			GetAimSocketOrBone(FireSocketLoc, TrueAim);
			vDir = TransformVectorByRotation(TrueAim, vect(16,0,0));
			`SHAPEMGR.DrawLine(FireSocketLoc, FireSocketLoc+vDir, 4, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));
			`SHAPEMGR.DrawLine(FireSocketLoc+vDir*1, FireSocketLoc+vDir*2, 3, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));
			`SHAPEMGR.DrawLine(FireSocketLoc+vDir*2, FireSocketLoc+vDir*3, 2, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));
			`SHAPEMGR.DrawLine(FireSocketLoc+vDir*3, FireSocketLoc+vDir*4, 1, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));
		}
`endif
		if(kTacticalCheatMgr != none && kTacticalCheatMgr.bDisableTargetingOutline )
		{
			bDisableAuxMaterials = true;
		}

		CalculateVisibilityPercentage();

		UpdateAuxParameters(bDisableAuxMaterials);
	}

	//Fallback to forcing the pawns visible if they are participating in a matinee, but only in tactical
	if(m_bInMatinee && bHidden && `TACTICALGRI != none )
	{
		SetVisibleToTeams(eTeam_All);
	}

	UpdateLeftHandIK(DT);
	
	// Determine DLE update rate based on state
	//   Don't do this for civilians
	if (LightEnvironment != none)
	{
		if( GetGameUnit() != none && XGUnit(GetGameUnit()).GetTeam() != eTeam_Neutral )
		{
			if( GetGameUnit() != none && GetGameUnit().IsInCinematicMode() )
			{
				LightEnvironment.MinTimeBetweenFullUpdates = 0.0;
			}
			else
			{
				// Update the current unit constantly
				if( IsSelected() )
				{
					LightEnvironment.MinTimeBetweenFullUpdates = 0.0;
				}
				else
				{
					LightEnvironment.MinTimeBetweenFullUpdates = 0.3;
				}
			}
		}

		LightEnvironment.OverriddenBounds.Origin = Location;
	}
	
	// Only execute this code if we're in Tactical
	if(kTacticalController != none)
	{
		// Aim Every Frame (either at something or back to 0)
		UpdateAiming(DT);
		UpdateHeadLookAtTarget();
	}

	// This goes both ways since we don't know who will update first.  During both updates we copy the location/rotation
	SyncCarryingUnits();

	//Update any rigid bodies active on this actor while it is in non-physics modes ( walking, kinematic, etc. ). This is handled by the rigid body update when the pawn is in that mode.
	if(Physics != PHYS_RigidBody)
	{		
		//The RBGrav update needs the collision component to be the skeletal mesh
		PreviousCollisionComponent = CollisionComponent;
		CollisionComponent = Mesh;
		ScriptAddRBGravAndDamping();
		CollisionComponent = PreviousCollisionComponent;
	}
}

simulated function UpdateLeftHandIK(float DT)
{
	local Vector vLeftHandIKLoc;
	local Rotator rRot;
	local name IKSocketName;
	local Name WeaponSocketName;
	local SkeletalMeshComponent PrimaryWeaponMeshComp;

	// allow IK with no tactical controller (ie. when in HQ)
	IKSocketName = GetLeftHandIKSocketName();
	WeaponSocketName = GetLeftHandIKWeaponSocketName();
	foreach Mesh.AttachedComponentsOnBone(class'SkeletalMeshComponent', PrimaryWeaponMeshComp, WeaponSocketName)
	{
		// Just do the first one
		break;
	}

	if( LeftHandIK != none )
	{
		if( PrimaryWeaponMeshComp != none && PrimaryWeaponMeshComp.GetSocketWorldLocationAndRotation(IKSocketName, vLeftHandIKLoc, rRot) )
		{
			if( IsSwitchingSides() )
			{
				LeftHandIK.ControlStrength -= DT * (1.0f / class'XComIdleAnimationStateMachine'.default.LeftHandIKBlendTime);
				if( LeftHandIK.ControlStrength < 0.0f )
					LeftHandIK.ControlStrength = 0.0f;
			}
			else if( ((m_bLeftHandIKAnimOverrideEnabled && m_bLeftHandIKAnimOverrideOn) || (!m_bLeftHandIKAnimOverrideEnabled && m_bLeftHandIKEnabled)) && LeftHandIK.ControlStrength < 1.0f )
			{
				LeftHandIK.ControlStrength += DT * (1.0f / class'XComIdleAnimationStateMachine'.default.LeftHandIKBlendTime);
				if( LeftHandIK.ControlStrength > 1.0f )
					LeftHandIK.ControlStrength = 1.0f;
			}
			else if( ((m_bLeftHandIKAnimOverrideEnabled && !m_bLeftHandIKAnimOverrideOn) || (!m_bLeftHandIKAnimOverrideEnabled && !m_bLeftHandIKEnabled)) && LeftHandIK.ControlStrength > 0.0f )
			{
				LeftHandIK.ControlStrength -= DT * (1.0f / class'XComIdleAnimationStateMachine'.default.LeftHandIKBlendTime);
				if( LeftHandIK.ControlStrength < 0.0f )
					LeftHandIK.ControlStrength = 0.0f;
			}
		}
		else
		{
			// if no IK socket, turn IK off
			LeftHandIK.ControlStrength -= DT * (1.0f / class'XComIdleAnimationStateMachine'.default.LeftHandIKBlendTime);
			if( LeftHandIK.ControlStrength < 0.0f )
				LeftHandIK.ControlStrength = 0.0f;
		}
	}
}

simulated function SkeletalMeshComponent GetPrimaryWeaponMeshComponent()
{
	return Weapon != none ? SkeletalMeshComponent(Weapon.Mesh) : none;
}

simulated function name GetLeftHandIKSocketName()
{
	return 'left_hand';
}

simulated event vector GetLeftHandIKTargetLoc()
{
	local vector vLeftHandIKLoc;
	local Name WeaponSocketName;
	local SkeletalMeshComponent PrimaryWeaponMeshComp;

	WeaponSocketName = GetLeftHandIKWeaponSocketName();
	foreach Mesh.AttachedComponentsOnBone(class'SkeletalMeshComponent', PrimaryWeaponMeshComp, WeaponSocketName)
	{
		// Just do the first one
		break;
	}
	if( PrimaryWeaponMeshComp != none )
	{
		PrimaryWeaponMeshComp.GetSocketWorldLocationAndRotation(GetLeftHandIKSocketName(), vLeftHandIKLoc);
	}

	return vLeftHandIKLoc;
}

simulated function bool IsSwitchingSides()
{
	//RAM - Constant Combat
	return false;
}

simulated function EnableLeftHandIK(bool bEnable)
{
	if (!m_bOnlyAllowAnimLeftHandIKNotify)
	{
		LeftHandIK.EffectorLocation = vect(0, 0, 0);
		m_bLeftHandIKEnabled = bEnable;
	}
}

//Used by custom pawn types for their own handling of this event
function OnFinishRagdoll()
{

}

function SetNoSkeletonUpdate(bool bSetting)
{
	local SkeletalMeshComponent MeshComp;

	foreach AllOwnedComponents(class'SkeletalMeshComponent', MeshComp)
	{
		MeshComp.bNoSkeletonUpdate = bSetting;
	}
}

//Handles syncing the unit pawn to a game state. This is done when the game state
//is directly setting the pawn's behavior ( such as when a tactical game first starts )
simulated function GameStateResetVisualizer(XComGameState_Unit UnitState)
{
	local name PawnState;
	local vector NewLocation;
	local XGUnit UnitVisualizer;
	local XComPresentationLayer PresentationLayer;
	local ParticleSystemComponent PSC;
	local XComGameState_Effect TestEffect;
	local bool StoredCollideWorld;

	UnitVisualizer = XGUnit(UnitState.GetVisualizer());

	PawnState = GetStateName();
	if( UnitState.IsAlive() && !UnitState.IsIncapacitated())
	{
		if( PawnState == 'Dying' || PawnState == 'RagDollBlend' || PawnState == 'WaitingToBeDestroyed' )
		{
			SetNoSkeletonUpdate(false);//Re-enable skeletal updates			
			SetPhysics(PHYS_Walking);
			GotoState('Auto');
		}
	}

	PawnState = GetStateName();
				
	NewLocation = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);

	`log("Setting" @ self @ "position to tile: (" @ UnitState.TileLocation.X @ "," @ UnitState.TileLocation.Y @ "," @ UnitState.TileLocation.Z @ ")" );

	NewLocation.Z = m_kGameUnit.GetDesiredZForLocation(NewLocation, `XWORLD.IsFloorTile(UnitState.TileLocation));

	`log("Setting" @ self @ "position to Location:" @ NewLocation);

	StoredCollideWorld = bCollideWorld;
	bCollideWorld = false;	
	EnableRMAInteractPhysics(false); //Turn off RMA for the teleport
	LockDownFootIK(false); // Jwats: Because our location changed make sure our feet reset.
	SetLocationNoCollisionCheck(NewLocation);

	if( UnitState.GetMyTemplate().bIsTurret )
	{
		SetRotation(UnitState.MoveOrientation);
		UnitVisualizer.SyncLocation(); // Force turret base to sync up with pawn.
	}
	bCollideWorld = StoredCollideWorld;

	UpdateLootSparklesEnabled(false, UnitState);

	if (UnitState.bRemovedFromPlay)
	{
		SetVisible(false);
	}
	else
	{
		UnitVisualizer.SetForceVisibility( eForceNone );
	}

	PresentationLayer = `PRES;

	if( PresentationLayer.m_kUnitFlagManager != None )
	{
		PresentationLayer.m_kUnitFlagManager.RespondToNewGameState(UnitVisualizer, None, true);
	}

	if(PresentationLayer.GetTacticalHUD() != none)
	{
		PresentationLayer.GetTacticalHUD().ForceUpdate(XComGameState(UnitState.Outer).HistoryIndex);
	}
	
	if ((!UnitState.IsAlive() || UnitState.IsIncapacitated()) && `TACTICALRULES.bProcessingLoad && !UnitState.bRemovedFromPlay )
	{
		TestEffect = UnitState.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
		if( TestEffect == None )
		{
			//Pawns need a little alone time before we start feeding animations and state changes to them.	
			SetTimer(2.0f, false, nameof(DelayPlayDyingOnLoad));
		}

		foreach m_arrRemovePSCOnDeath( PSC )
		{
			if (PSC != none && PSC.bIsActive)
				PSC.DeactivateSystem( );
		}
		m_arrRemovePSCOnDeath.Length = 0;
	}
}

function DelayPlayDyingOnLoad()
{
	local Vector Zero;
	local CustomAnimParams AnimParams;

	bProcessingDeathOnLoad = true;	
	if(RagdollFlag == ERagdoll_Never)
	{
		GetAnimTreeController().DeathOnLoad(true, AnimParams);			
	}
	else
	{
		DeathRestingLocation = Location;
		DeathRestingLocation.Z = `XWORLD.GetFloorZForPosition(DeathRestingLocation);		
		PlayDying(none, Zero, GetDeathAnimOnLoadName());		
	}

	GetAnimTreeController().SetAllowNewAnimations(false);
}

simulated state NoTicking
{
	ignores Tick;
}
simulated function GoToNextState() // Added to prevent none function on timer set in RagDollBlend
{
}

simulated function SyncCorpse()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local bool bIsSoldier;
	local XComGameStateContext_TacticalGameRule SyncCorpseContext;

	// if we're doing latent submission, defer the state submission until the next frame where we're clear --Ned
	if( `XCOMGAME.GameRuleset.IsDoingLatentSubmission() )
	{
		SetTimer(0.1f, false, 'SyncCorpse');
		return;
	}

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(m_kGameUnit.ObjectID));
	bIsSoldier = UnitState.IsSoldier();

	if( (bIsSoldier || UnitState.CanBeCarried()) && !bProcessingDeathOnLoad )
	{
		//Normally not allowed to push game states from visual sequences like this, but we make an exception for xcom soldier bodies
		SyncCorpseContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
		SyncCorpseContext.GameRuleType = eGameRule_SyncTileLocationToCorpse;
		SyncCorpseContext.UnitRef = UnitState.GetReference();
		`XCOMGAME.GameRuleset.SubmitGameStateContext(SyncCorpseContext);
	}
}

simulated state RagDollBlend
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		
		// jboswell: you get 'RagdollFinishTimer' seconds to resolve ragdoll, then freeze
		SetTimer(RagdollFinishTimer, false, 'FinishRagDoll');

		RagdollFinishTimer = default.DefaultRagdollFinishTimer;
	}

	simulated event EndState(name NextStateName)
	{
		local int Index; //Tmp array iterator

		super.EndState(NextStateName);

		if(bFinalRagdoll)
		{
			//Restore collision to any frac mesh actor components we disabled for the ragdoll to bash through
			for(Index = 0; Index < TempCollisionComponents.Length; ++Index)
			{
				TempCollisionComponents[Index].SetBlockRigidBody(true);
			}
			TempCollisionComponents.Length = 0;

			if(!Mesh.bNoSkeletonUpdate)
			{
				FinishRagDoll(); //If the ragdoll has not finished yet, finish it
			}
			ClearTimer('FinishRagDoll'); // in case we are exiting from some other code path
		}		
	}

	simulated function FinishRagDoll()
	{
		local XComWorldData WorldData;
		local TTile kTile;
		local CustomAnimParams AnimParams;					
		
		// Start Issue #41
		// Guard clause, early return and finish ragdoll if ragdoll collision
		// is enabled.
		if (class'CHHelpers'.default.ENABLE_RAGDOLL_COLLISION)
		{
			OnFinishRagdoll();
		
			SetTimer(1.0f, false, 'GoToNextState');
			return;
		}
		// End Issue #41

		// When we're locking the body down, death effects need to die as well
		if (m_deathHandler != none)
		{
			m_deathHandler.EndDeath(self);
			m_deathHandler = none;
		}
				
		Mesh.PutRigidBodyToSleep();

		SyncCorpse();

		//Must take place before we possible turn off the physics below
		Mesh.bSyncActorLocationToRootRigidBody = true;
		SyncActorToRBPhysics_ScriptAccess();

		//Stop all skeletal mesh updates and destroy the rag doll if the body is resting on an
		//indestructible surface.
		//This can be a pretty major optimization for missions that involves a large number of 
		//units being killed like Avenger Defense or Alien Fortress
		WorldData = `XWORLD;
		WorldData.GetFloorTileForPosition(Location, kTile, true);
		if (!WorldData.TileHasFloorThatIsDestructible(kTile))
		{
			//Before turning off skeleton updates, create and run a pose based on our rag doll bone positions. This will keep 
			//the character from doing anything strange if a system, material change, etc. force the component to update
			AnimParams.AnimName = 'FinishRagdollPose';
			AnimParams.Looping = true;
			AnimParams.BlendTime = 0.0f;
			AnimParams.HasPoseOverride = true;
			AnimParams.Pose = Mesh.LocalAtoms;
			GetAnimTreeController().SetAllowNewAnimations(true);
			GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
			GetAnimTreeController().SetAllowNewAnimations(false);

			SetNoSkeletonUpdate(true);
			TermRagdoll();
			SetPhysics(PHYS_Walking);
		}

		bProcessingDeathOnLoad = false;

		OnFinishRagdoll();
	
		SetTimer(1.0f, false, 'GoToNextState');
	}

	simulated function GoToNextState()
	{
		GotoState('');
	}

	simulated event Tick(float DT)
	{		
		if (fPhysicsMotorForce != 0.0f)
		{
			if(RagdollBlendTime <= 0.01f)
			{
				if(!bWaitingForRagdollNotify)
				{
					// Turn the powered ragdoll off and let the character become fully physics driven
					fPhysicsMotorForce = 0.0f;
				}
			}
			else
			{
				//If we enter this branch, it means we are a rag doll that is using SetRagdollLinearDriveToDestination. In this case, we want to ramp up the
				//motor force slowly
				fPhysicsMotorForce -= fPhysicsMotorForce*DT*(1.0f / RagdollBlendTime);
			}

			//`log("RagdollBlendTime is" @ RagdollBlendTime @ ", applying physics motor force of" @ fPhysicsMotorForce);
			
			if (fPhysicsMotorForce < 0.1)
			{	
				fPhysicsMotorForce = 0.0;				
			}
			
			if(bAnimatedRagdoll)
			{
				//Update all bones
				SetDesiredBoneSprings(fPhysicsMotorForce > 0.0f, fPhysicsMotorForce > 0.0f, fPhysicsMotorForce, fPhysicsMotorForce / 80, fPhysicsMotorForce, fPhysicsMotorForce / 80);
			}
			else if(RagdollDistance > DragRagdollDistanceThreshold && !bReactionFireDeath)
			{
				//Limited update
				SetRagdollLinearDriveToDestination(DeathRestingLocation, DyingImpulse, fPhysicsMotorForce, fPhysicsMotorForce / 80);
			}
		}

		fFallImpactSoundEffectTimer += DT;

		UpdateLeftHandIK(DT);

		BreakFragile(); //This is to handle interact actors, which are skeletal meshes and thus don't have physx collision
	}

	//This function traces forward from the head of the unit's corpse / ragdoll - this catches actors and collisions that the PhysX collisions cannot.
	simulated function BreakFragile()
	{
		//local vector HeadBoneLocation;
		//local vector ToLastHeadBoneLocation;
		//local RB_BodyInstance HeadRigidBody;    //Rigid body instance used to get the head bone location when in the ragdoll state
		//local Plane TranslationMatrixRow;       //Interface to rigid body translation
		//local Vector    TraceLoc;               //Tmp trace variable
		//local Vector    TraceNormal;            //Tmp trace variable
		//local Actor     TraceActor;             //Tmp trace variable	
		//local XComInteractiveLevelActor InteractActor;  //Temp for casting XComInteractiveLevelActors
		//local XComFracLevelActor FracActor;
		//local DamageEvent DoDamageEvent;
		
		//HeadRigidBody = Mesh.FindBodyInstanceNamed(HeadBoneName);
		//if( HeadRigidBody != none && HeadRigidBody.BodyData.Dummy != 0 )
		//{
		//	TranslationMatrixRow = HeadRigidBody.GetUnrealWorldTM().WPlane;
		//	HeadBoneLocation.X = TranslationMatrixRow.X;
		//	HeadBoneLocation.Y = TranslationMatrixRow.Y;
		//	HeadBoneLocation.Z = TranslationMatrixRow.Z;

		//	ToLastHeadBoneLocation = LastHeadBoneLocation - HeadBoneLocation;
						
		//	TraceActor = Trace( TraceLoc, TraceNormal, HeadBoneLocation - (ToLastHeadBoneLocation * 64.0f), HeadBoneLocation, true, vect(48.0f,48.0f,48.0f));

		//	InteractActor = XComInteractiveLevelActor(TraceActor);
		//	if( InteractActor != none && (InteractActor.Toughness == none || !InteractActor.Toughness.bInvincible))
		//	{
		//		InteractActor.TakeDirectDamage(class'XComDamageType'.static.CreateEvent((InteractActor.TotalHealth), InteractActor, InteractActor.Location, vect(0,0,0), class'XComDamageType_Melee'));
		//		InteractActor.DisableCollision();
		//		`XWORLD.RebuildTileData(InteractActor.Location, class'XComWorldData'.const.WORLD_StepSize, class'XComWorldData'.const.WORLD_StepSize * 4); //handle very tall windows...
		//	}

		//	if( SmashEnvironmentOnDeath )
		//	{
		//		FracActor =  XComFracLevelActor(TraceActor);
		//		if( FracActor != none && 
		//			!FracActor.FracturedStaticMeshComponent.bPreventChunkRemoval &&  //Do not trigger on floors / ceilings
		//			FracActor.ImpactMaterialType != MaterialType_Glass ) //Do not trigger on car windows
		//		{	
		//			DoDamageEvent.bDamagesUnits = false;
		//			DoDamageEvent.EventInstigator = m_kGameUnit;
		//			DoDamageEvent.DamageCauser    = m_kGameUnit;
		//			DoDamageEvent.Target          = none; //Do world damage, so set target to none
		//			DoDamageEvent.DamageAmount    = 500;
		//			DoDamageEvent.Radius          = class'XComWorldData'.const.WORLD_HalfStepSize / 2;
		//			DoDamageEvent.DamageType      = class'XComDamageType_DestructibleActorClear';
		//			DoDamageEvent.Momentum        = vect(0,0,0);
		//			DoDamageEvent.HitLocation     = HeadBoneLocation;
		//			DoDamageEvent.bIsHit          = false;
		//			DoDamageEvent.bRadialDamage   = true;
		//			DoDamageEvent.bCausesSurroundingAreaDamage = false;
		
		//			class'XComDamageType'.static.DealDamageWithDamageFrame(DoDamageEvent);
		//		}
		//	}

		//	LastHeadBoneLocation = HeadBoneLocation;
		//}
	}
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	//Associate this actor with the appropriate WWise switch group
	SetSwitch('Character', AkEventCharacterSwitch);

	super.PostInitAnimTree(SkelComp);

	// Animation State Initialization
}

simulated event PostBeginPlay()
{
	local RenderChannelContainer RenderChannels;
	local Vector MeshTranslation;

	super.PostBeginPlay();

	SetMovementPhysics();

	AddDefaultInventory();

	fBaseZMeshTranslation = -CollisionHeight;
	MeshTranslation.Z = fBaseZMeshTranslation;
	Mesh.SetTranslation(MeshTranslation);

	// jboswell: Use values from XComUnitPawnNativeBase (archetype)
	CylinderComponent.SetCylinderSize(CollisionRadius, CollisionHeight);
	

	// Initialize the z-height of the attack range indicator
	RangeIndicator.SetTranslation( vect(0,0,-1) * ( CylinderComponent.CollisionHeight - 17.0f ) );
 
	EnableFootIK(true);

	// Put unit pawn in the appropriate renderchannel
	RenderChannels = Mesh.RenderChannels;
	RenderChannels.RainCollisionDynamic = true;
	Mesh.SetRenderChannels(RenderChannels);
	//Mesh.PrestreamTextures(2.0f, true);
	Mesh.PutRigidBodyToSleep();
	Mesh.bUpdateJointsFromAnimation=false; 

	if (m_bHasFullAnimWeightBones)
	{
		Mesh.bEnableFullAnimWeightBodies = true;
		Mesh.PhysicsWeight = 0;
		Mesh.SetHasPhysicsAssetInstance(TRUE);
		Mesh.bUpdateKinematicBonesFromAnimation=true;

		Mesh.SetBlockRigidBody(true);
		Mesh.SetRBChannel(RBCC_Pawn);		
		Mesh.SetRBCollidesWithChannel(RBCC_Default,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Pawn,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Vehicle,TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_Clothing, TRUE);
		Mesh.SetRBCollidesWithChannel(RBCC_ClothingCollision, TRUE);

		Mesh.PhysicsAssetInstance.SetFullAnimWeightBonesFixed(false, Mesh);
	}

	CreateDefaultAttachments();

	if( `TACTICALGRI != none && (`BATTLE.m_kDesc != None && `BATTLE.m_kDesc.m_iMissionType == eMission_HQAssault) )
	{
		WaitingToBeDestroyedTimer = 0.5f;
	}

`if (`notdefined(FINAL_RELEASE))
	// for debug rendering
	AddHUDOverlayActor();
`endif
}

function CreateDefaultAttachments()
{
	local int DefaultAttachmentIndex;
		
	for(DefaultAttachmentIndex = 0; DefaultAttachmentIndex < DefaultAttachments.Length; ++DefaultAttachmentIndex)
	{
		CreateBodyPartAttachment(DefaultAttachments[DefaultAttachmentIndex]);
	}
	// Start Issue #21
	// Defer XComHumanPawn socket adjustments until part customization
	if (XComHumanPawn(self) == none)
	{
		DLCAppendSockets(); // LWS added call to helper function
	}
	// End Issue #21
}

// Start Issue #21
// Function to allow DLC/Mods to append sockets to units
function DLCAppendSockets()
{
	local array<X2DownloadableContentInfo> DLCInfos; 
	local int i; 
	local SkeletalMesh SkelMesh;
	local string SkeletalMeshString;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		SkeletalMeshString = DLCInfos[i].DLCAppendSockets(self);
		if (SkeletalMeshString != "")
		{
			SkelMesh = SkeletalMesh(DynamicLoadObject(SkeletalMeshString, class'SkeletalMesh'));
			if (SkelMesh != none)
			{
				Mesh.AppendSockets(SkelMesh.Sockets, true);
			}
		}
	}
}
// End Issue #21

function CreateBodyPartAttachment(XComBodyPartContent BodyPartContent)
{
	local SkeletalMeshComponent SkelMeshComp;
	local XComPawnPhysicsProp PhysicsProp;

	// Variables for issue #641
	local XComBodyPartContentAdvanced AdvancedContent;
	local Actor Archetype, Instance;
	local Vector SocketLocation;
	local Rotator SocketRotation;

	if (BodyPartContent == none)
		return;

	// Start issue #641
	AdvancedContent = XComBodyPartContentAdvanced(BodyPartContent);
	if (AdvancedContent != none)
	{
		foreach AdvancedContent.Archetypes(Archetype)
		{
		    Mesh.GetSocketWorldLocationAndRotation(BodyPartContent.SocketName, SocketLocation, SocketRotation);
			Instance = Spawn(Archetype.Class,,, SocketLocation, SocketRotation, Archetype);

			if (Instance != None)
			{
				Instance.SetBase(self,, Mesh, BodyPartContent.SocketName);
				AdvancedBodyPartActors.AddItem(Instance);
			}
		}

		return;
	}
	// End issue #641

	if( BodyPartContent.SocketName != '' && Mesh.GetSocketByName(BodyPartContent.SocketName) != none )
	{
		if( BodyPartContent.SkeletalMesh != none )
		{
			if( BodyPartContent.UsePhysicsAsset != none )
			{
				PhysicsProp = Spawn(class'XComPawnPhysicsProp', self);
				PhysicsProp.CollisionComponent = PhysicsProp.SkeletalMeshComponent;
				PhysicsProp.SetBase(self);
				PhysicsProp.SkeletalMeshComponent.SetSkeletalMesh(BodyPartContent.SkeletalMesh);

				Mesh.AttachComponentToSocket(PhysicsProp.SkeletalMeshComponent, BodyPartContent.SocketName, BodyPartContent.SocketName);

				//Do NOT set bForceUpdateAttachmentsInTick because we need the cape to update in its selected tick group when attached to a ragdoll					
				if( BodyPartContent.UsePhysicsAsset != none )
				{
					PhysicsProp.SkeletalMeshComponent.SetPhysicsAsset(BodyPartContent.UsePhysicsAsset, true);
					PhysicsProp.SkeletalMeshComponent.SetHasPhysicsAssetInstance(true);
					PhysicsProp.SkeletalMeshComponent.WakeRigidBody();
					PhysicsProp.SkeletalMeshComponent.PhysicsWeight = 1.0f;
					PhysicsProp.SetTickGroup(TG_PostUpdateWork);
				}

				PhysicsProp.SkeletalMeshComponent.SetAcceptsDynamicDecals(FALSE); // Fix for blood puddles appearing on the hair.
				PhysicsProp.SkeletalMeshComponent.SetAcceptsStaticDecals(FALSE);

				m_aPhysicsProps.AddItem(PhysicsProp);
			}
			else
			{
				SkelMeshComp = new(self) class'SkeletalMeshComponent';
				SkelMeshComp.SetSkeletalMesh(BodyPartContent.SkeletalMesh);
				Mesh.AttachComponentToSocket(SkelMeshComp, BodyPartContent.SocketName);
			}
		}
	}
	else if( BodyPartContent.SkeletalMesh != none )
	{
		SkelMeshComp = new(self) class'SkeletalMeshComponent';
		SkelMeshComp.SetSkeletalMesh(BodyPartContent.SkeletalMesh);
		SkelMeshComp.SetParentAnimComponent(Mesh);
		Mesh.AppendSockets(SkelMeshComp.Sockets, true);
		AttachComponent(SkelMeshComp);
		AttachedMeshes.AddItem(SkelMeshComp);
	}
}

function RemoveBodyPartAttachment(XComBodyPartContent BodyPartContent)
{
	local int AttachmentIndex;
	local SkeletalMeshComponent AttachedMesh;

	// Variables for issue #641
	local XComBodyPartContentAdvanced AdvancedContent;
	local Actor AttachedActor, Archetype;
	
	// Start issue #641
	AdvancedContent = XComBodyPartContentAdvanced(BodyPartContent);
	if (AdvancedContent != none)
	{
		foreach AdvancedBodyPartActors(AttachedActor)
		{
			foreach AdvancedContent.Archetypes(Archetype)
			{
				if (AttachedActor.ObjectArchetype == Archetype)
				{
					AdvancedBodyPartActors.RemoveItem(AttachedActor);
					AttachedActor.Destroy();
				}
			}
		}

		return;
	}
	// End issue #641

	if( BodyPartContent.SkeletalMesh != None )
	{
		for( AttachmentIndex = 0; AttachmentIndex < Mesh.Attachments.Length; ++AttachmentIndex )
		{
			AttachedMesh = SkeletalMeshComponent(Mesh.Attachments[AttachmentIndex].Component);
			if( AttachedMesh != None )
			{
				if( AttachedMesh.SkeletalMesh == BodyPartContent.SkeletalMesh )
				{
					RemoveProp(AttachedMesh);
					return;
				}
			}
		}
	}
}

simulated function RemoveProp(MeshComponent PropComponent)
{
	local int PropIdx;

	DetachComponent(PropComponent);
	Mesh.DetachComponent(PropComponent);

	for( PropIdx = 0; PropIdx < m_aPhysicsProps.Length; ++PropIdx )
	{
		if( m_aPhysicsProps[PropIdx] != none && m_aPhysicsProps[PropIdx].SkeletalMeshComponent == PropComponent )
		{
			//m_aPhysicsProps[PropIdx].SetBase(none);
			m_aPhysicsProps[PropIdx].Destroy();
			m_aPhysicsProps.Remove(PropIdx, 1);
			break;
		}
	}
}

simulated function XComUpdateCylinderSize(bool bAlert)
{
	local Vector vCollisionCylinderLoc;

	// Quick hack to not let the soldier go under the world in the tutorial
	if (m_bTutorialCanDieInMatinee && Physics == PHYS_Interpolating)
	{
		return;
	}

	if (bAlert &&
		CylinderComponent.CollisionHeight != CollisionHeight) 
	{
		vCollisionCylinderLoc.X = 0;
		vCollisionCylinderLoc.Y = 0;
		vCollisionCylinderLoc.Z = 0;
		CylinderComponent.SetTranslation(vCollisionCylinderLoc);
		CylinderComponent.SetCylinderSize(CollisionRadius, CollisionHeight);
	}
	else if (!bAlert &&
			 CylinderComponent.CollisionHeight != (CollisionHeight * 0.1f))
	{   
		CylinderComponent.SetCylinderSize(CollisionRadius, CollisionHeight * 0.1f);

		vCollisionCylinderLoc.X = 0;
		vCollisionCylinderLoc.Y = 0;
		vCollisionCylinderLoc.Z = -CollisionHeight;
		CylinderComponent.SetTranslation(vCollisionCylinderLoc);
	}
}

simulated function ResetIKTranslations()
{
	local Vector Trans;
	local int i;

	Trans.Z = fBaseZMeshTranslation;

	Mesh.SetTranslation(Trans);

	for(i = 0; i < FootIKInfos.Length; i++)
	{
		FootIKInfos[i].vCachedFootPos = vect(99999,99999,99999);
	}
}

simulated event Destroyed ()
{
	super.Destroyed();

	DestroyAdvancedBodyPartActors(); // Issue #641
}

// Start issue #641
simulated private function DestroyAdvancedBodyPartActors ()
{
	local Actor Actor;

	// We do not need to worry about iterator invalidation here as no callbacks/events in Actor.Destroy() chain
	// affect the AdvancedBodyPartActors array. However, if one is to be added, then this code needs to be checked
	// for potential iterator invalidation issues
	foreach AdvancedBodyPartActors(Actor)
	{
		if (Actor != none)
		{
			Actor.Destroy();
		}
	}

	AdvancedBodyPartActors.Length = 0;
}
// End issue #641

simulated function int GetCurrentFloor()
{
	return IndoorInfo.GetCurrentFloorNumber();
}

simulated function OnChangedIndoorStatus()
{
	local bool bIsInside;
	
	// set the body head and weapon light environments on or off
	// TODO: Add entries for any other shadow casting attached components

	// only do this stuff if we're initialized e.g. GetGameUnit() != none.
	if (GetGameUnit() != none)
	{
		bIsInside = IndoorInfo.IsInside();
		GetGameUnit().OnChangedIndoorOutdoor( bIsInside );
	}

	super.OnChangedIndoorStatus();
}

/*
 * Fired when this unit goes from selected -> unselected
 */
simulated event OnUnSelected()
{
	NotifyTacticalGameOfEvent(PAWN_UNSELECTED);
}

/*
 * Fired when this unit goes from unselected -> selected
 */
simulated event OnSelected()
{
	local XGUnit kUnit;

	NotifyTacticalGameOfEvent(PAWN_SELECTED);

	kUnit = XGUnit(GetGameUnit());

	//RAM - do not fire unit related kismet events until the battle is initialized
	if( `BATTLE.AtBottomOfRunningStateBeginBlock() )
	{
		// fire off the OnUnitChanged event in Kismet if it exists.
		TriggerGlobalEventClass( class'SeqEvent_OnUnitChanged', kUnit, 0 );
	}
}

simulated function bool IsSelected()
{
	local XComTacticalController kOwnerTacticalController;

	kOwnerTacticalController = XComTacticalController(Owner);

	return  kOwnerTacticalController != none && 
			kOwnerTacticalController.GetActiveUnit() != none && 
			kOwnerTacticalController.GetActiveUnit() == GetGameUnit();
}

simulated function SetCurrentWeapon(XComWeapon kWeapon)
{
	local XComGameState_Item Item;
	local name AkEventWeaponSwitch;

	Weapon = kWeapon;
	if( kWeapon != None )
	{
		kWeapon.m_kPawn = self;

		if (kWeapon.m_kGameWeapon != none) // some weapons (like those spawned by perks) don't have game weapons.
		{
			// Set the Wwise switch on this unit for unit-pawn-based weapon sounds e.g. reloads
			Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(kWeapon.m_kGameWeapon.ObjectID));
			if (Item != none)
			{
				AkEventWeaponSwitch = Item.GetWeaponTech();
				SetSwitch('WeaponType', AkEventWeaponSwitch);
			}
		}
	}
	MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
}

simulated function EquipWeapon( XComWeapon kWeapon, bool bImmediate, bool bIsRearBackPackItem)
{
	local XComGameState_Item Item;
	local MeshComponent AttachedComponent;
	
	local XComUnitPawn WeaponPawn;
	local XComAnimatedWeapon AnimatedWeapon;	
	local XComGameStateHistory History;
	local X2WeaponTemplate WeaponTemplate;
	local int Idx;
	// Single variable for Issue #921
	local float fOverrideWeaponScale;

	// Jerad@Psyonix, do some stuff that InventoryManager.CreateInventory does...
	if (kWeapon != None)
	{
		kWeapon.SetOwner(self);
		kWeapon.Instigator = self;
		kWeapon.GivenTo(self, False);
	}

	SetCurrentWeapon( kWeapon );
	
	if( kWeapon != None )
	{
		History = `XCOMHISTORY;
			Item = XComGameState_Item(History.GetGameStateForObjectID(kWeapon.m_kGameWeapon.ObjectID));

		if( Item != none && Item.CosmeticUnitRef.ObjectID > 0 )
		{
			//If we have a cosmetic unit ref, it is independent of this pawn
			AnimatedWeapon = XComAnimatedWeapon(kWeapon);
			WeaponPawn = XGUnit(History.GetVisualizer(Item.CosmeticUnitRef.ObjectID)).GetPawn();
			if( WeaponPawn != none )
			{
				AnimatedWeapon.Mesh = WeaponPawn.Mesh;
			}
		}
		else if( bImmediate && (kWeapon.Mesh != none))
		{
			WeaponTemplate = X2WeaponTemplate(Item.GetMyTemplate());
			if( bIsFemale && !IsA('XComMECPawn') && (WeaponTemplate == none || !WeaponTemplate.bUseArmorAppearance))
				kWeapon.Mesh.SetScale(WeaponScale);

			// Start Issue #921
			if (TriggerOverrideWeaponScale(fOverrideWeaponScale, Item))
			{
				kWeapon.Mesh.SetScale(fOverrideWeaponScale);
			}
			// End Issue #921

			Mesh.AttachComponentToSocket(kWeapon.Mesh, kWeapon.DefaultSocket);
			kWeapon.Mesh.CastShadow = true;
		}

		if( kWeapon.SheathMesh != None && kWeapon.SheathSocket != '' )
			Mesh.AttachComponentToSocket(kWeapon.SheathMesh, kWeapon.SheathSocket);

		if (kWeapon.Mesh != none)
		{
			// MHU - Backpack items that are equipped must be visible.
			if( bIsRearBackPackItem )
				kWeapon.Mesh.SetHidden(false);

			kWeapon.Mesh.PrestreamTextures(1.0f, true);

			UpdateMeshMaterials(kWeapon.Mesh, true);
			for( Idx = 0; Idx < SkeletalMeshComponent(kWeapon.Mesh).Attachments.Length; ++Idx )
			{
				AttachedComponent = MeshComponent(SkeletalMeshComponent(kWeapon.Mesh).Attachments[Idx].Component);
				if( AttachedComponent != none )
				{
					UpdateMeshMaterials(AttachedComponent, true);
				}
			}
		}
	}

	// MHU - Jan 25th, 2010
	// Animset switching code tested and verified ok. 
	// The function below will perform an animset update based on the currently equipped weapon.
	// I'll bring this online once art assets are in stable shape.
	UpdateAnimations();

	MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
}
// Start Issue #921
/// HL-Docs: feature:OverrideWeaponScale; issue:921; tags:pawns
/// The `OverrideWeaponScale` event allows mods to rescale weapons for unit pawns. 
/// 
/// This event is triggered from two places: 
/// 1) `XComUnitPawn::EquipWeapon()` is used by items in weapon slots, as well as for utility items
/// that use the [Display Multi Slot Items](../misc/DisplayMultiSlotItems.md) functionality. 
/// 2) `XComUnitPawn::AttachItem()` is used for utility items by default. In this case,
/// the `ItemState` component of the Tuple will be `none`. 
///
/// ```event
/// EventID: OverrideWeaponScale,
/// EventData: [out bool bOverride, inout float fOverrideWeaponScale, in XComGameState_Item ItemState],
/// EventSource: XComUnitPawn (UnitPawn),
/// NewGameState: none
/// ```
private function bool TriggerOverrideWeaponScale(out float fOverrideWeaponScale, optional XComGameState_Item Item)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideWeaponScale';
	OverrideTuple.Data.Add(3);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;  
	OverrideTuple.Data[1].kind = XComLWTVFloat;
	OverrideTuple.Data[1].f = fOverrideWeaponScale; 
	OverrideTuple.Data[2].kind = XComLWTVObject;
	OverrideTuple.Data[2].o = Item; 

	`XEVENTMGR.TriggerEvent('OverrideWeaponScale', OverrideTuple, self);

	fOverrideWeaponScale = OverrideTuple.Data[1].f;

	return OverrideTuple.Data[0].b;
}
// End Issue #921

// This function creates and attaches the meshes needed for a soldier's loadout in a non-gamestate altering way.
// It is ONLY intended for representative purposes, such as the UI, throwaway matinee pawns, etc. Do not use it 
// as a mechanism for syncing the visual state of a unit during gameplay!
simulated function CreateVisualInventoryAttachments(UIPawnMgr PawnMgr, XComGameState_Unit UnitState, optional XComGameState CheckGameState, bool bSetAsVisualizer=true, bool OffsetCosmeticPawn=true, bool bUsePhotoboothPawns=false, bool bArmorAppearanceOnly=false)
{
	local array<AnimSet> PhotoboothAnimSets;
	// Variables for Issue #118
	local array<EInventorySlot> ValidSlots;
	local array<CHItemSlot> SlotTemplates;
	local CHItemSlot SlotIter;
	local EInventorySlot Slot;

	// Variable for Issue #885
	local array<EInventorySlot> ValidMultiSlots;

	PhotoboothAnimSets.Length = 0;

	// Issue #118 Start, clean up and add mod added slots
	ValidSlots.AddItem(eInvSlot_PrimaryWeapon);
	ValidSlots.AddItem(eInvSlot_SecondaryWeapon);
	ValidSlots.AddItem(eInvSlot_HeavyWeapon);
	ValidSlots.AddItem(eInvSlot_GrenadePocket);
	ValidSlots.AddItem(eInvSlot_AmmoPocket);
	ValidSlots.AddItem(eInvSlot_TertiaryWeapon);
	ValidSlots.AddItem(eInvSlot_QuaternaryWeapon);
	ValidSlots.AddItem(eInvSlot_QuinaryWeapon);
	ValidSlots.AddItem(eInvSlot_SenaryWeapon);
	ValidSlots.AddItem(eInvSlot_SeptenaryWeapon);

	SlotTemplates = class'CHItemSlot'.static.GetAllSlotTemplates();
	foreach SlotTemplates(SlotIter)
	{
		if (SlotIter.ShowOnCinematicPawns)
		{
			// Start Issue #885
			if (SlotIter.IsMultiItemSlot)
			{
				ValidMultiSlots.AddItem(SlotIter.InvSlot);
			} // End Issue #885
			else
			{
				ValidSlots.AddItem(SlotIter.InvSlot);
			}
		}
	}

	foreach ValidSlots(Slot)
	{
		CreateVisualInventoryAttachment(PawnMgr, Slot, UnitState, CheckGameState, bSetAsVisualizer, OffsetCosmeticPawn, bUsePhotoboothPawns, PhotoboothAnimSets, bArmorAppearanceOnly);
	}
	// Issue #118 End

	// Issue #885 Start
	ValidMultiSlots.AddItem(eInvSlot_Utility);
	CreateVisualInventoryAttachmentsForMultiSlotItems(PawnMgr, UnitState, ValidMultiSlots, CheckGameState, bSetAsVisualizer, OffsetCosmeticPawn, bUsePhotoboothPawns, PhotoboothAnimSets, bArmorAppearanceOnly);
	// Issue #885 End

	if (bUsePhotoboothPawns)
	{
		XComAddAnimSetsExternal(PhotoboothAnimSets);
	}
}

simulated function SpawnCosmeticUnitPawn(UIPawnMgr PawnMgr, EInventorySlot InvSlot, string CosmeticUnitTemplate, XComGameState_Unit OwningUnit, bool OffsetForArmory, bool bUsePhotoboothPawns = false)
{
	local X2CharacterTemplate EquipCharacterTemplate;
	local XComUnitPawn ArchetypePawn, CosmeticPawn;
	local string ArchetypeStr;
	local Vector PawnLoc;
	local TAppearance UseAppearance;
	local XComGameState_Unit OwnersUnitState;
	local TTile TileLocation;

	EquipCharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(name(CosmeticUnitTemplate));
	if (EquipCharacterTemplate == none)
	{
		`Redscreen("Cosmetic unit template \""$CosmeticUnitTemplate$"\" not found!");
		return;
	}

	ArchetypeStr = EquipCharacterTemplate.GetPawnArchetypeString(none);
	ArchetypePawn = XComUnitPawn(`CONTENT.RequestGameArchetype(ArchetypeStr));
	if (ArchetypePawn == none)
	{
		`Redscreen("Cosmetic unit archetype pawn for \""$CosmeticUnitTemplate$"\" not found!");
		return;
	}

	// Start Issue #380: Moved earlier because we want to SetAppearance() whether we create a new pawn or not
	UseAppearance = OwningUnit.kAppearance;
	UseAppearance.iArmorTint = UseAppearance.iWeaponTint;
	UseAppearance.iArmorTintSecondary = UseAppearance.iArmorTintSecondary;
	UseAppearance.nmPatterns = UseAppearance.nmWeaponPattern;
	// End Issue #380
	CosmeticPawn = PawnMgr.GetCosmeticArchetypePawn(InvSlot, OwningUnit.ObjectID, bUsePhotoboothPawns);
	if (CosmeticPawn != none && CosmeticPawn == ArchetypePawn)
	// Start Issue #380
	{
		CosmeticPawn.SetAppearance(UseAppearance, true);
		return;
	}
	//End Issue #380

	PawnLoc = Location;
	OwnersUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	if (OffsetForArmory)
	{
		PawnLoc += EquipCharacterTemplate.AvengerOffset;
	}
	else
	{
		TileLocation = `XWORLD.GetTileCoordinatesFromPosition(PawnLoc);
		TileLocation.Z += OwnersUnitState.GetDesiredZTileOffsetForAttachedCosmeticUnit();
		PawnLoc = `XWORLD.GetPositionFromTileCoordinates(TileLocation);
	}
	
	CosmeticPawn = PawnMgr.AssociateCosmeticPawn(InvSlot, ArchetypePawn, OwningUnit.ObjectID, self, PawnLoc, Rotation, bUsePhotoboothPawns);

	CosmeticPawn.SetAppearance(UseAppearance, true);
	CosmeticPawn.HQIdleAnim  = EquipCharacterTemplate.HQIdleAnim;
	CosmeticPawn.HQOffscreenAnim = EquipCharacterTemplate.HQOffscreenAnim;
	CosmeticPawn.HQOnscreenAnimPrefix = EquipCharacterTemplate.HQOnscreenAnimPrefix;
	CosmeticPawn.HQOnscreenOffset = EquipCharacterTemplate.HQOnscreenOffset;
	CosmeticPawn.GotoState('Onscreen');
}

simulated function SetAppearance(const out TAppearance kAppearance, optional bool bRequestContent = true)
{
	m_kAppearanceBase = kAppearance;
	if (bRequestContent)
	{
		RequestFullPawnContent();
	}
}

simulated private function RequestFullPawnContent()
{
	local int i;
	local MeshComponent AttachedComponent;
	local XComLinearColorPalette Palette;
	local X2BodyPartTemplate PartTemplate;
	local X2BodyPartTemplateManager PartManager;

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	PartTemplate = PartManager.FindUberTemplate(string('Patterns'), m_kAppearanceBase.nmPatterns);

	if (PartTemplate != none)
	{
		PatternsContentBase = XComPatternsContent(`CONTENT.RequestGameArchetype(PartTemplate.ArchetypeName, self, none, false));
	}
	else
	{
		PatternsContentBase = none;
	}

	NumPossibleTints = 0;
	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	NumPossibleTints = Palette.Entries.Length;

	if (Mesh != none)
	{
		UpdateMaterials(Mesh);
	}

	for (i = 0; i < Mesh.Attachments.Length; ++i)
	{
		AttachedComponent = MeshComponent(Mesh.Attachments[i].Component);
		if (AttachedComponent != none)
		{
			UpdateMaterials(AttachedComponent);
		}
	}
}

simulated private function UpdateMaterials(MeshComponent MeshComp)
{
	local int i;
	local MaterialInterface Mat, ParentMat;
	local MaterialInstanceConstant MIC, ParentMIC, NewMIC;

	if (MeshComp != none)
	{
		for (i = 0; i < MeshComp.GetNumElements(); ++i)
		{
			Mat = MeshComp.GetMaterial(i);
			MIC = MaterialInstanceConstant(Mat);

			// It is possible for there to be MITVs in these slots, so check
			if (MIC != none)
			{
				// If this is not a child MIC, make it one. This is done so that the material updates below don't stomp
				// on each other between units.
				if (InStr(MIC.Name, "MaterialInstanceConstant") == INDEX_NONE)
				{
					NewMIC = new (self) class'MaterialInstanceConstant';
					NewMIC.SetParent(MIC);
					MeshComp.SetMaterial(i, NewMIC);
					MIC = NewMIC;
				}

				ParentMat = MIC.Parent;
				while (!ParentMat.IsA('Material'))
				{
					ParentMIC = MaterialInstanceConstant(ParentMat);
					if (ParentMIC != none)
						ParentMat = ParentMIC.Parent;
					else
						break;
				}

				UpdateIndividualMaterial(MeshComp, MIC);
			}
		}
	}
}

// Logic largely based off of UpdateArmorMaterial in XComHumanPawn
simulated function UpdateIndividualMaterial(MeshComponent MeshComp, MaterialInstanceConstant MIC)
{
	local XComLinearColorPalette Palette;
	local LinearColor PrimaryTint;
	local LinearColor SecondaryTint;

	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	if (Palette != none)
	{
		if (m_kAppearanceBase.iArmorTint != INDEX_NONE)
		{
			PrimaryTint = Palette.Entries[m_kAppearanceBase.iArmorTint].Primary;
			MIC.SetVectorParameterValue('Primary Color', PrimaryTint);
		}
		if (m_kAppearanceBase.iArmorTintSecondary != INDEX_NONE)
		{
			SecondaryTint = Palette.Entries[m_kAppearanceBase.iArmorTintSecondary].Secondary;
			MIC.SetVectorParameterValue('Secondary Color', SecondaryTint);
		}
	}

	//Pattern Addition 2015-5-4 Chang You Wong
	if (PatternsContentBase != none && PatternsContentBase.Texture != none)
	{
		//For Optimization, we want to fix the SetStaticSwitchParameterValueAndReattachShader function
		//When that happens we need to change the relevant package back to using static switches
		//SoldierArmorCustomizable_TC  M_Master_PwrdArm_TC  WeaponCustomizable_TC
		//MIC.SetStaticSwitchParameterValueAndReattachShader('Use Pattern', true, MeshComp);
		MIC.SetScalarParameterValue('PatternUse', 1);
		MIC.SetTextureParameterValue('Pattern', PatternsContentBase.Texture);// .ReferencedObjects[0]));
	}
	else
	{
		//Same optimization as above
		//MIC.SetStaticSwitchParameterValueAndReattachShader('Use Pattern', false, MeshComp);
		MIC.SetScalarParameterValue('PatternUse', 0);
		MIC.SetTextureParameterValue('Pattern', none);
	}
}

simulated function CreateVisualInventoryAttachment(UIPawnMgr PawnMgr, EInventorySlot InvSlot, XComGameState_Unit UnitState, XComGameState CheckGameState, bool bSetAsVisualizer, bool OffsetCosmeticPawn, bool bUsePhotoboothPawns = false, optional out array<AnimSet> PhotoboothAnimSets, bool bArmorAppearanceOnly = false)
{
	local XGWeapon kWeapon;
	local XComGameState_Item ItemState;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local bool bRegularItem;
	local XComWeapon CurrentWeapon;
	local int i;

	ItemState = UnitState.GetItemInSlot(InvSlot, CheckGameState);
	if (ItemState != none)
	{
		if(bArmorAppearanceOnly)
		{
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			if(WeaponTemplate == none || WeaponTemplate.bUseArmorAppearance == false)
			{
				return;
			}
		}

		EquipmentTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
		
		//Is this a cosmetic unit item?
		bRegularItem = EquipmentTemplate == none || EquipmentTemplate.CosmeticUnitTemplate == "";
		if(bRegularItem)
		{
			kWeapon = XGWeapon(class'XGItem'.static.CreateVisualizer(ItemState, bSetAsVisualizer, self));

			if(kWeapon != none)
			{
				if(kWeapon.m_kOwner != none)
				{
					kWeapon.m_kOwner.GetInventory().PresRemoveItem(kWeapon);
				}

				if(PawnMgr != none)
				{
					PawnMgr.AssociateWeaponPawn(InvSlot, ItemState.GetVisualizer(), UnitState.GetReference().ObjectID, self, bUsePhotoboothPawns);
				}

				kWeapon.UnitPawn = self;
				kWeapon.m_eSlot = X2WeaponTemplate(ItemState.GetMyTemplate()).StowedLocation; // right hand slot is for Primary weapons
				EquipWeapon(kWeapon.GetEntity(), true, false);

				if (bUsePhotoboothPawns)
				{
					CurrentWeapon = kWeapon.GetEntity();
					if (CurrentWeapon != none)
					{
						// Add the weapon's animsets
						for (i = 0; i < CurrentWeapon.CustomUnitPawnAnimsets.Length; ++i)
						{
							PhotoboothAnimSets.AddItem(CurrentWeapon.CustomUnitPawnAnimsets[i]);
						}

						if (UnitState.kAppearance.iGender == eGender_Female)
						{
							for (i = 0; i < CurrentWeapon.CustomUnitPawnAnimsetsFemale.Length; ++i)
							{
								PhotoboothAnimSets.AddItem(CurrentWeapon.CustomUnitPawnAnimsetsFemale[i]);
							}
						}
					}
				}
			}
		}
		else
		{
			if(PawnMgr != none)
			{
				SpawnCosmeticUnitPawn(PawnMgr, InvSlot, EquipmentTemplate.CosmeticUnitTemplate, UnitState, OffsetCosmeticPawn, bUsePhotoboothPawns);
			}
		}
	}   
	else
	{
		`log("CreateVisualInventoryAttachment could not find inventory item for slot" @ InvSlot, , 'XCom_Visualization');
	}
}

// Issue #885 Start
// Generally behaves in the same way as CreateVisualInventoryAttachment(), but it cycles through all items in all multi slots, 
// and runs ShouldDisplayMultiSlotItemInStrategy callbacks for each to make the individual decision whether the item should be displayed on the unit.
simulated private function CreateVisualInventoryAttachmentsForMultiSlotItems(UIPawnMgr PawnMgr, XComGameState_Unit UnitState, array<EInventorySlot> ValidMultiSlots, XComGameState CheckGameState, bool bSetAsVisualizer, bool OffsetCosmeticPawn, bool bUsePhotoboothPawns = false, optional out array<AnimSet> PhotoboothAnimSets, bool bArmorAppearanceOnly = false)
{
	local XGWeapon kWeapon;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> ItemStates;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local XComWeapon CurrentWeapon;
	local int i, MultiSlotIndex;
	local CHHelpers CHHelpersObj;
	local EInventorySlot ValidMultiSlot;

	CHHelpersObj = class'CHHelpers'.static.GetCDO();
	if (CHHelpersObj == none || PawnMgr == none)
	{
		return;
	}

	foreach ValidMultiSlots(ValidMultiSlot)
	{	
		// The MultiSlotIndex is used to track the position of the item in the Multi Slot.
		// It will be used make sure that each item has its own visualizer slot in the soldier's PawnInfo, so that if this item is replaced by another item, 
		// the visualizer of the original item gets properly removed from the soldier's pawn.
		MultiSlotIndex = -1;
		ItemStates = UnitState.GetAllItemsInSlot(ValidMultiSlot, CheckGameState);

		foreach ItemStates(ItemState)
		{
			// Increment index for each item in this Multi Slot.
			MultiSlotIndex++;

			if (!CHHelpersObj.ShouldDisplayMultiSlotItemInStrategy(UnitState, ItemState, ValidMultiSlot, self, CheckGameState))
			{
				continue;
			}

			if(bArmorAppearanceOnly)
			{
				WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
				if(WeaponTemplate == none || WeaponTemplate.bUseArmorAppearance == false)
				{
					continue;
				}
			}
		
			EquipmentTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
			//Is this a cosmetic unit item?
			if(EquipmentTemplate == none || EquipmentTemplate.CosmeticUnitTemplate == "")
			{
				kWeapon = XGWeapon(class'XGItem'.static.CreateVisualizer(ItemState, bSetAsVisualizer, self));

				if(kWeapon == none)
				{
					continue;
				}

				if(kWeapon.m_kOwner != none)
				{
					kWeapon.m_kOwner.GetInventory().PresRemoveItem(kWeapon);
				}

				PawnMgr.AssociateMultiSlotWeaponPawn(MultiSlotIndex, ItemState.GetVisualizer(), UnitState.GetReference().ObjectID, self, ValidMultiSlot, bUsePhotoboothPawns);
				kWeapon.UnitPawn = self;
				kWeapon.m_eSlot = X2WeaponTemplate(ItemState.GetMyTemplate()).StowedLocation; // right hand slot is for Primary weapons
				EquipWeapon(kWeapon.GetEntity(), true, false);
					
				if (bUsePhotoboothPawns)
				{
					CurrentWeapon = kWeapon.GetEntity();
					if (CurrentWeapon == none)
					{
						continue;
					}
					// Add the weapon's animsets
					for (i = 0; i < CurrentWeapon.CustomUnitPawnAnimsets.Length; ++i)
					{
						PhotoboothAnimSets.AddItem(CurrentWeapon.CustomUnitPawnAnimsets[i]);
					}

					if (UnitState.kAppearance.iGender == eGender_Female)
					{
						for (i = 0; i < CurrentWeapon.CustomUnitPawnAnimsetsFemale.Length; ++i)
						{
							PhotoboothAnimSets.AddItem(CurrentWeapon.CustomUnitPawnAnimsetsFemale[i]);
						}
					}
				}
			}
			else 
			{
				// This is a cosmetic unit item, e.g. Gremlin. Currently there's a limitation that only cosmetic unit can be visible per inventory slot.
				SpawnCosmeticUnitPawn(PawnMgr, ValidMultiSlot, EquipmentTemplate.CosmeticUnitTemplate, UnitState, OffsetCosmeticPawn, bUsePhotoboothPawns);
			}
		}   
	}
}
// Issue #885 End

// MHU - This function is used to move the weapon or item to a new socket on the unit WITHOUT
//       equipping it. For example, applying the initial loadout or debugging when we don't have
//       a valid item attach notifies (infinite grenades).
simulated function AttachItem(Actor a, name SocketName, bool bIsRearBackPackItem, out MeshComponent kFoundMeshComponent)
{
	local MeshComponent MeshComp;
	local bool bHideItem;
	local int i;

	// Single variable for Issue #921
	local float fOverrideWeaponScale;

	// MHU - Is there already a foundMeshComponent? If so, then the weapon was already added to the unit
	//       and we're now moving it to a different socketName.
	if (kFoundMeshComponent != none)
	{
		// `log("Pawn::AddItem:" @ MeshComp @ SocketName);
		Mesh.AttachComponentToSocket(kFoundMeshComponent, SocketName);
	}
	else if (a != none)
	{
		foreach a.ComponentList(class'MeshComponent', MeshComp)
		{
			// For non-MEC females, all weapons are scaled to 75% -- jboswell
			if (bIsFemale && !IsA('XComMECPawn'))
				MeshComp.SetScale(WeaponScale);

			// Start Issue #921
			if (TriggerOverrideWeaponScale(fOverrideWeaponScale))
			{
				MeshComp.SetScale(fOverrideWeaponScale);
			}
			// End Issue #921

			// `log("Pawn::AddItem:" @ MeshComp @ SocketName);
			Mesh.AttachComponentToSocket(MeshComp, SocketName);

			// MHU - When the component is moved from Item.m_kEntity's Components array over to
			//       the Unit Mesh Attachments array, we save a ptr to the found mesh component.
			//       This allows us to easily find it later to drop.
			kFoundMeshComponent = MeshComp;

			MeshComp.SetLightEnvironment(LightEnvironment);
			MeshComp.SetShadowParent(Mesh);
			MeshComp.CastShadow = false;
			MeshComp.PrestreamTextures(1.0f, true);

			break;
		}
	}

	if (kFoundMeshComponent != none)
	{
		if (!bIsRearBackPackItem)
		{
			for (i = 0; i < HiddenSlots.Length; i++)
			{
				if (HiddenSlots[i] == SocketName)
				{
					bHideItem = true;
					break;
				}
			}
		}

		if (bIsRearBackPackItem || bHideItem)
		{
			MeshComp.SetHidden(true);
		}
	}

	MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
}

simulated function DetachItem(MeshComponent MeshComp)
{
	if (MeshComp != none)
	{
		// Force thrown grenades and dropped weapons not to draw with scanlines ever.
		MeshComp.bNeedsPrimaryProxy = true;
		MeshComp.bNeedsSecondaryProxy = false;
		Mesh.DetachComponent(MeshComp);
	}
}
// debug/test fn
// function bool StackIsGood(bool bIdleExecute=false)
// {
// 	if (m_kUpdateWhenNotRenderedStack.Length > 0)
// 	{
// 		// When starting an idle, the top of the stack should be true.
// 		if (bIdleExecute && m_kUpdateWhenNotRenderedStack[m_kUpdateWhenNotRenderedStack.Length-1] != 0)
// 			return true;
// 		// When popping an action off, the bottom of the stack should be true.
// 		else if (!bIdleExecute && m_kUpdateWhenNotRenderedStack[0] != 0)
// 			return true;
// 	}
// 	else
// 	{
// 		return Mesh.bUpdateSkelWhenNotRendered;
// 	}
// 	return false;
// }

// push current state of whether to update skeleton or not when offscreen
// NOTE: DO NOT DISABLE ANIM NODES. EVER. CASEY WILL FIND YOU AND HANG YOUR DOG. -- jboswell
//function PushUpdateSkelWhenNotRendered(bool bNewState)
//{
//	m_kUpdateWhenNotRenderedStack.AddItem(int(Mesh.bUpdateSkelWhenNotRendered));     
//	Mesh.bUpdateSkelWhenNotRendered = bNewState;
//	//Mesh.bTickAnimNodesWhenNotRendered = bNewState;
//	Mesh.bIgnoreControllersWhenNotRendered = !bNewState;
//}

//// pop current state of whether to render or not when offscreen
//function PopUpdateSkelWhenNotRendered()
//{
//	local bool bUpdateWhenNotRendered;

//	if (m_kUpdateWhenNotRenderedStack.Length > 0)
//	{
//		bUpdateWhenNotRendered = bool(m_kUpdateWhenNotRenderedStack[m_kUpdateWhenNotRenderedStack.Length-1]);
//		Mesh.bUpdateSkelWhenNotRendered = bUpdateWhenNotRendered;
//		//Mesh.bTickAnimNodesWhenNotRendered = bUpdateWhenNotRendered;
//		Mesh.bIgnoreControllersWhenNotRendered = !bUpdateWhenNotRendered;

//		m_kUpdateWhenNotRenderedStack.Remove(m_kUpdateWhenNotRenderedStack.Length-1, 1);
//	}
//}

simulated function LogDebugInfo()
{
	super.LogDebugInfo();

	`log( "CylinderComponent Radius, Height:"@CylinderComponent.CollisionRadius@CylinderComponent.CollisionHeight );
}

// MHU - Where, in world space, we look at when there's no target
simulated function Vector GetNoTargetLocation(optional bool bThirdPerson = false)
{
	local Vector vLoc, vRot;
	local float fDistance;

	if (bThirdPerson)
		fDistance = `METERSTOUNITS(5);
	else
		fDistance = `METERSTOUNITS(2);

	vRot = Vector(Rotation);
	vLoc = GetHeadShotLocation() +  vRot * fDistance;

	return vLoc;
}

// Where, in world space, would a headshot strike this unit?
simulated function vector GetHeadshotLocation()
{
	return GetHeadLocation();
}

// Where, in world space, would a headshot strike this unit?
simulated function vector GetPsiSourceLocation()
{
	local Vector PsiSourceLocation;
	local Rotator tempRotator;

	if (!Mesh.GetSocketWorldLocationAndRotation('Inven_PsiSource', PsiSourceLocation, tempRotator))
	{
		//`log ( "Can't find socket Inven_PsiSource, utilizing HeadShot location:" @Mesh.SkeletalMesh);
		return GetHeadshotLocation();
	}
	else
		return PsiSourceLocation;
}

simulated function bool CalcCamera( float DeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{
	local vector Focus;

	out_CamLoc = GetHeadLocation();
	out_CamLoc += LocalCameraOffset >> Rotation;

	Focus = out_CamLoc + vector(Rotation) * CameraFocusDistance;
	out_CamRot = rotator(Focus - out_CamLoc);

	out_FOV = 90;

	return true;
}

/**
 * Adjusts weapon aiming direction.
 * Gives Pawn a chance to modify its aiming. For example aim error, auto aiming, adhesion, AI help...
 * Requested by weapon prior to firing.
 *
 * @param	W, weapon about to fire
 * @param	StartFireLoc, world location of weapon fire start trace, or projectile spawn loc.
 */
simulated function Rotator GetAdjustedAimFor( Weapon W, vector StartFireLoc )
{
	// MHU - If there's an invalid target location to fire at, utilize default rotator.
	if (VSizeSq(TargetLoc) == 0)
	{
		return Weapon.Mesh.GetRotation();
	}
	else
	{
		return rotator(TargetLoc - GetWeaponStartTraceLocation());
	}
}

/**
 * Return world location to start a weapon fire trace from.
 *
 * @return	World location where to start weapon fire traces from
 */
simulated event Vector GetWeaponStartTraceLocation(optional Weapon CurrentWeapon)
{
	local vector FireSocketLoc;
	local rotator FireSocketRot;

	if (!SkeletalMeshComponent(Weapon.Mesh).GetSocketWorldLocationAndRotation(m_WeaponSocketNameToUse, FireSocketLoc, FireSocketRot))
	{
		FireSocketLoc = Weapon.Mesh.GetPosition();
		FireSocketRot = Weapon.Mesh.GetRotation();
	}

	return FireSocketLoc;
}

simulated function AttachRangeIndicator(float fDiameter, StaticMesh kMesh)
{
	RangeIndicator.SetStaticMesh(kMesh);
	RangeIndicator.SetScale(fDiameter / 512.0f);    // 512 is the size of the ring static mesh
	RangeIndicator.SetHidden(false);
}

simulated function DetachRangeIndicator()
{
	RangeIndicator.SetHidden(true);
}

simulated function AttachKineticStrikeIndicator(float fDiameter, StaticMesh kMesh)
{
	RangeIndicator.SetStaticMesh(kMesh);	
	RangeIndicator.SetAbsolute(false, true, false);
	RangeIndicator.SetHidden(false);
}

simulated function DetachKineticStrikeIndicator()
{
	RangeIndicator.SetAbsolute(false, false, false);
	RangeIndicator.SetHidden(true);
}

simulated function AttachFlamethrowerIndicator(float fDiameter, StaticMesh kMesh)
{
	RangeIndicator.SetStaticMesh(kMesh);	
	RangeIndicator.SetAbsolute(false, true, false);
	RangeIndicator.SetHidden(false);
}

simulated function DetachFlamethrowerIndicator()
{
	RangeIndicator.SetAbsolute(false, false, false);
	RangeIndicator.SetHidden(true);
}

simulated function AppendAbilityPerks( name AbilityName, optional name PerkName = '' )
{
	local XComPerkContentInst kPawnPerk;

	if (PerkName == '')
		PerkName = AbilityName;

	`CONTENT.AppendAbilityPerks( PerkName, self );

	// if the ability we're adding these perks for is not the same as the perks for (MP ability replacements)
	// re-associate the perks to this ability so that they play appropriately.
	if (AbilityName != PerkName)
	{
		foreach arrPawnPerkContent( kPawnPerk )
		{
			if (kPawnPerk.GetAbilityName( ) == PerkName)
			{
				kPawnPerk.ReassociateToAbility( AbilityName );
			}
		}
	}
}

simulated function StartPersistentPawnPerkFX( optional name PerkName = '' )
{
	local WorldInfo WInfo;
	local XComPerkContent kPawnPerkDefinition;
	local XComPerkContentPassiveInst kPawnPerkPassive;

	if (bAllowPersistentFX)
	{
		WInfo = class'WorldInfo'.static.GetWorldInfo();

		foreach arrPawnPerkDefinitions(kPawnPerkDefinition)
		{
			if ((PerkName == '') || (kPawnPerkDefinition.AssociatedAbility == PerkName))
			{
				if (class'XComPerkContentPassiveInst'.static.PerkRequiresPassive( kPawnPerkDefinition ))
				{
					kPawnPerkPassive = WInfo.Spawn( class'XComPerkContentPassiveInst' );
					kPawnPerkPassive.Init( kPawnPerkDefinition, self );

					arrPawnPerkPassives.AddItem( kPawnPerkPassive );

					kPawnPerkPassive.StartPersistentFX( );
				}
			}
		}
	}
}

simulated function StopPersistentPawnPerkFX( optional name PerkName = '' )
{
	local XComPerkContentPassiveInst kPawnPerk;

	foreach arrPawnPerkPassives(kPawnPerk)
	{
		if ((PerkName == '') || (kPawnPerk.GetAbilityName() == PerkName))
			kPawnPerk.StopPersistentFX();
	}
}

//------------------------------------------------------------------------------------------------


event EncroachedBy( actor Other )
{
	// if the cursor is trying to kill us, dont let it. -Dom
	if ( XCom3DCursor(Other) == None )
		super.EncroachedBy(Other);
}

function SetDyingPhysics()
{
	//This is already handled by other things in X2. It was doing nothing but breaking death anims when used for BleedingOut/Unconscious.
	return;
}

//==============================================================================
// 		STATES:
//==============================================================================

//RAM - this relies primarily on Pawn::Dying, but overrides so that we
//      can do special death related processing / actions
simulated State Dying
{	
	simulated event Timer()
	{		
		super.Timer();

		if( m_deathHandler != none )
		{
			m_deathHandler.Update();
		}
	}

	simulated event BeginState(Name PreviousStateName)
	{
		local XComPerkContentInst kPawnPerkInst;
		local XComPerkContentPassiveInst kPawnPerkPassive;
		local XComPerkContentShared kPawnPerkShared;
		local ParticleSystemComponent PSC;
		local X2Action_Death DeathAction;
		local XComGameStateVisualizationMgr VisualizationMgr;

		super.BeginState(PreviousStateName);

		PreviousHeadLocation = GetHeadLocation();

		// Disable aux materials immediately
		MarkAuxParametersAsDirty(TRUE, FALSE, FALSE);
		m_bAuxParamNeedsPrimary = TRUE;
		m_bAuxParamNeedsSecondary = FALSE;
		m_bAuxParamUse3POutline = FALSE;
		SetAuxParameters(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);

		//Find the X2Action_Death to see if it wants the death handler played.
		VisualizationMgr = `XCOMVISUALIZATIONMGR;
		DeathAction = X2Action_Death(VisualizationMgr.GetNodeOfType(VisualizationMgr.VisualizationTree, class'X2Action_Death', m_kGameUnit));		

		if(DeathHandlerTemplate != none && DeathAction != none && DeathAction.ShouldRunDeathHandler())
		{
			m_deathHandler = new class'XComDeathHandler'(DeathHandlerTemplate);			
			m_deathHandler.BeginDeath( HitDamageType, self, TakeHitLocation, DeathAction.vHitDir );
		}

		foreach m_arrRemovePSCOnDeath(PSC)
		{
			if (PSC != none && PSC.bIsActive)
				PSC.DeactivateSystem();
		}
		m_arrRemovePSCOnDeath.Length = 0;

		//  notify perks of death
		foreach arrPawnPerkContent(kPawnPerkInst)
		{
			kPawnPerkInst.OnPawnDeath();
		}
		foreach arrPawnPerkPassives(kPawnPerkPassive)
		{
			kPawnPerkPassive.OnPawnDeath();
		}
		foreach arrTargetingPerkContent(kPawnPerkShared)
		{
			kPawnPerkShared.RemovePerkTarget( XGUnit(m_kGameUnit) );
		}

		// remove any rescue ring
		if(RangeIndicator.StaticMesh == CivilianRescueRing)
		{
			RangeIndicator.SetHidden(true);
		}
		
		LifeSpan = 0.f; //Our parent will attempt to set a lifespan for us, set it back so that bodies stick around.
	}

	simulated event Tick(float DT)
	{
		/*
		// Jwats: See if we have to trigger ragdoll early
		local Vector    TraceLoc;               //Tmp trace variable
		local Vector    TraceNormal;            //Tmp trace variable
		local Actor     TraceActor;             //Tmp trace variable
		local vector    CurrentHeadLocation;
		local vector    MovementDir;
		CurrentHeadLocation = GetHeadLocation();
		MovementDir = CurrentHeadLocation - PreviousHeadLocation;
		MovementDir = MovementDir + (Normal(MovementDir) * 16.0f);

		TraceActor = Trace(TraceLoc, TraceNormal, PreviousHeadLocation + MovementDir, PreviousHeadLocation, true, vect(16.0f,16.0f,16.0f));			
		if(TraceActor != none)
		{
			StartRagdoll(true);	
		}

		PreviousHeadLocation = CurrentHeadLocation;
		*/
	}
}

simulated singular event OutsideWorldBounds()
{
	DoDeathOnOutsideOfBounds();
}

simulated event FellOutOfWorld(class<DamageType> dmgType)
{
	DoDeathOnOutsideOfBounds();
}

function DoDeathOnOutsideOfBounds()
{
	//local vector vZero;

	`log(self $ "::" $ GetFuncName() @ "Unit=" $ m_kGameUnit @ m_kGameUnit.SafeGetCharacterFullName(), true, 'XCom_Net');
	if(!XGUnit(m_kGameUnit).IsDead())
	{
		XGUnit(m_kGameUnit).m_bMPForceDeathOnMassiveTakeDamage = true;
		`ASSERT(false);
		//XGUnit(m_kGameUnit).OnTakeDamage(class'XGUnit'.const.MASSIVE_AMOUNT_OF_DAMAGE, class'XComDamageType_Plasma', none, vZero, vZero);
	}
}

//------------------------------------------------------------------------------------------------
simulated function bool SnapToGround( optional float Distance = 1024.0f )
{
	local vector vHitLoc;
	local bool bSnapped;

	vHitLoc = Location;
	vHitLoc.Z = `XWORLD.GetFloorZForPosition(Location, true);

	bSnapped = true;
	vHitLoc.Z += CylinderComponent.CollisionHeight;

	bCollideWorld = false;
	SetLocationNoOffset(vHitLoc);
	bCollideWorld = true;

	fFootIKTimeLeft = 10.0f;	

	return bSnapped;
}

function SetUpdateSkelWhenNotRendered(bool bSetting)
{
	local SkeletalMeshComponent MeshComp;

	foreach AllOwnedComponents(class'SkeletalMeshComponent', MeshComp)
	{
		MeshComp.bUpdateSkelWhenNotRendered = bSetting;
	}
}

function bool GetUpdateSkelWhenNotRendered()
{
	local bool UpdateSkelWhenNotRendered;

	UpdateSkelWhenNotRendered = false;
	if( Mesh != None )
	{
		UpdateSkelWhenNotRendered = Mesh.bUpdateSkelWhenNotRendered;
	}

	return UpdateSkelWhenNotRendered;
}

//------------------------------------------------------------------------------------------------

simulated function SetupForMatinee(optional Actor MatineeBase, optional bool bDisableFootIK, optional bool bDisableGenderBlender, optional bool bHardAttachToMatineeBase)
{
	if (m_bInMatinee)
	{
		ReturnFromMatinee();
	}

	if (MatineeBase != none)
	{
		SetBase(MatineeBase);
		SetHardAttach(bHardAttachToMatineeBase);
	}

	if (bDisableFootIK)
	{
		EnableFootIK(false);
	}

	PushCollisionCylinderEnable(false);	
	SetUpdateSkelWhenNotRendered(true);
	EnableRMA(false, false);
	EnableRMAInteractPhysics(false);
	SetPhysics(PHYS_Interpolating);
	ResetIKTranslations(); // Reset any IK translations that may have been applied.
	UpdateAnimations();
	Mesh.SaveAnimSets();	
	m_bInMatinee = true;
}

simulated function ReturnFromMatinee()
{
	if (m_bInMatinee)
	{
		EnableFootIK(true);
		PopCollisionCylinderEnable();
		EnableRMA(true, true);
		EnableRMAInteractPhysics(true);
		Mesh.RestoreSavedAnimSets();
		UpdateAnimations();
		ResetIKTranslations();
		ResetDesiredRotation();		
		if (m_bWasIdleBeforeMatinee)
			m_kGameUnit.IdleStateMachine.Resume(none);
		m_bInMatinee = false;
		m_bWasIdleBeforeMatinee = false;
	}
}

//------------------------------------------------------------------------------
// Matinee/Interp debugging
//------------------------------------------------------------------------------
/** Called when we start an AnimControl track operating on this Actor. Supplied is the set of AnimSets we are going to want to play from. */
simulated event BeginAnimControl(InterpGroup InInterpGroup)
{
	super.BeginAnimControl(InInterpGroup);
}

/** Called when we are done with the AnimControl Metadata. */
simulated event FinishAnimControl(InterpGroup InInterpGroup)
{
	if( !m_bRemainInAnimControlForDeath )
	{
		super.FinishAnimControl(InInterpGroup);
	}
}

/** called when a SeqAct_Interp action starts interpolating this Actor via matinee
 * @note this function is called on clients for actors that are interpolated clientside via MatineeActor
 * @param InterpAction the SeqAct_Interp that is affecting the Actor
 */
simulated event InterpolationStarted(SeqAct_Interp InterpAction, InterpGroupInst GroupInst)
{
	super.InterpolationStarted( InterpAction, GroupInst );
	`log(Name @ "started" @ InterpAction.GetPackageName() $"."$ InterpAction $"/"$ GroupInst.Group.GroupName,,'DevMatinee');
}

/** called when a SeqAct_Interp action finished interpolating this Actor
 * @note this function is called on clients for actors that are interpolated clientside via MatineeActor
 * @param InterpAction the SeqAct_Interp that was affecting the Actor
 */
simulated event InterpolationFinished(SeqAct_Interp InterpAction)
{
	super.InterpolationFinished( InterpAction );
	`log(Name @ "finished" @ InterpAction.GetPackageName() $"."$ InterpAction,,'DevMatinee');
}

/**
 * Play FaceFX animations on this Actor.
 * Returns TRUE if succeeded, if failed, a log warning will be issued.
 */
simulated event bool PlayActorFaceFXAnim(FaceFXAnimSet AnimSet, String GroupName, String SeqName, SoundCue SoundCueToPlay, AkEvent AkEventToPlay )
{
	Speak(SoundCueToPlay);

	if (m_kHeadMeshComponent != none)
	{
		return m_kHeadMeshComponent.PlayFaceFXAnim(AnimSet, SeqName, GroupName, SoundCueToPlay, AkEventToPlay);
	}
	return Mesh.PlayFaceFXAnim(AnimSet, SeqName, GroupName, SoundCueToPlay, AkEventToPlay);
}

/** Unmounts the facefxanimset from the actors */
simulated event UnMountCinematicFaceFX()
{
	if (m_kHeadMeshComponent != none)
	{
		m_kHeadMeshComponent.UnMountCinematicFaceFX();
	}
	else
	{
		Mesh.UnMountCinematicFaceFX();
	}
}

/** Used by Matinee in-game to mount FaceFXAnimSets before playing animations. */
simulated event FaceFXAsset GetActorFaceFXAsset()
{
	if (m_kHeadMeshComponent != none)
	{
		if (m_kHeadMeshComponent.SkeletalMesh != None && !m_kHeadMeshComponent.bDisableFaceFX)
		{	
			return m_kHeadMeshComponent.SkeletalMesh.FaceFXAsset;
		}
		else
		{
			return None;
		}
	}
	else
	{
		if (Mesh.SkeletalMesh != None && !Mesh.bDisableFaceFX)
		{	
			return Mesh.SkeletalMesh.FaceFXAsset;
		}
		else
		{
			return None;
		}
	}
}

simulated function SoundNodeWave GetWavNode(SoundCue SndCue, optional SoundNode SndNode)
{
	local int i;
	local SoundNodeWave retNode;

	if (SndCue != none)
	{
		SndNode = SndCue.FirstNode;
	}
	
	if (SndNode != none)
	{
		if (SndNode.IsA('SoundNodeWave'))
		{
			return SoundNodeWave(SndNode);
		}
		else
		{
			for ( i = 0; i < SndNode.ChildNodes.Length; i++ )
			{
				retNode = GetWavNode(none, SndNode.ChildNodes[i]);
				
				if (retNode != none)
					return retNode;
			}
		}
	}

	return none;
}

simulated function bool IsPawnReadyForViewing()
{
	return true;
}

simulated event Speak(SoundCue Cue)
{
	local SoundNodeWave WavAudio;
	local UINarrativeMgr NarrativeMgr;
	local UINarrativeCommLink CommLink;

	if (Cue == none || !m_bTutorialCanDieInMatinee) // Such a hack, I know.  Dont do this if we arent using SetupPawnForMatinee action - Ryan Baker
	{
		return;
	}

	CommLink = `PRES.GetUIComm();
	NarrativeMgr = `PRES.m_kNarrativeUIMgr;

	StopCommLink();

	ClearTimer('StopCommLink');

	WavAudio = GetWavNode(Cue);
	if (WavAudio != none)
	{
		NarrativeMgr.CurrentOutput.strTitle = "";
		NarrativeMgr.CurrentOutput.strImage = NarrativeMgr.SpeakerToPortait(WavAudio.eSpeaker);
		NarrativeMgr.CurrentOutput.strText = WavAudio.SpokenText;
		NarrativeMgr.CurrentOutput.fDuration = WavAudio.Duration;
		SetTimer(WavAudio.Duration, false, 'StopCommLink');
	}

	CommLink.Show();
}

simulated function StopCommLink()
{
	local UINarrativeMgr NarrativeMgr;
	local UINarrativeCommLink CommLink;

	CommLink = `PRES.GetUIComm();
	NarrativeMgr = `PRES.m_kNarrativeUIMgr;

	CommLink.Hide();

	NarrativeMgr.CurrentOutput.strTitle = "";
	NarrativeMgr.CurrentOutput.strText = "";
}

simulated function RotateInPlace(int Dir); // only used for character customization -- jboswell

// Used exclusively for civilian offscreen deaths.  (Overwritten in XComCivilian)
function DelayedDeathSound()
{
}

simulated function DebugVis( Canvas kCanvas, XComCheatManager kCheatManager )
{
	local Vector vScreenPos;
	local XComFloorVolume FloorVolume;
	local int i;
	local float savedX;

	if( kCheatManager.m_bDebugVis )
	{
		vScreenPos = kCanvas.Project(Location+vect(0,0,64));

		kCanvas.SetDrawColor(255,255,255);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText(self.Name);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Location:"@Location);

		// Building volume
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Building:" @ self.IndoorInfo.CurrentBuildingVolume );

		// Floor volumes
		savedX = vScreenPos.X;
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Floor Volumes: "  );
		for( i=0; i<self.IndoorInfo.CurrentFloorVolumes.Length; i++ )
		{
			FloorVolume = self.IndoorInfo.CurrentFloorVolumes[i];
			kCanvas.SetPos(savedX += 100, vScreenPos.Y);
			kCanvas.DrawText( " " @ FloorVolume);
		}


		// Current floor
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Current Floor:" @ self.IndoorInfo.GetCurrentFloorNumber() );

		// Inside ?
		// 
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Inside? "@self.IndoorInfo.IsInside());

	}
}

simulated function DebugIK(Canvas kCanvas, XComCheatManager kCheatManager)
{
	local Vector vScreenPos, vLeftHandIKLoc;
	local string activePrefix;
	local name IKSocketName;
	local Name WeaponSocketName;
	local SkeletalMeshComponent PrimaryWeaponMeshComp;

	if( kCheatManager.bDebugHandIK )
	{
		vScreenPos = kCanvas.Project(Location+vect(0,0,64));

		kCanvas.SetDrawColor(255,255,255);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText(self.Name);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Location:"@Location@"Rotation:"@Rotation);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("LH_IKAnimOverrideEnabled"@m_bLeftHandIKAnimOverrideEnabled);

		if( m_bLeftHandIKAnimOverrideEnabled )
		{
			activePrefix = "--->";
			if( m_bLeftHandIKAnimOverrideOn )
			{
				kCanvas.SetDrawColor(150,255,150);
			}
			else
			{
				kCanvas.SetDrawColor(255,150,150);
			}
		}
		else
		{
			activePrefix = "";
			kCanvas.SetDrawColor(255,255,255);
		}
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText(activePrefix$"LH_IKAnimOverrideOn"@m_bLeftHandIKAnimOverrideOn);

		if( !m_bLeftHandIKAnimOverrideEnabled )
		{
			activePrefix = "--->";
			if( m_bLeftHandIKEnabled )
			{
				kCanvas.SetDrawColor(150,255,150);
			}
			else
			{
				kCanvas.SetDrawColor(255,150,150);
			}
		}
		else
		{
			activePrefix = "";
			kCanvas.SetDrawColor(255,255,255);
		}
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText(activePrefix$"LH_IKEnabled"@m_bLeftHandIKEnabled);

		kCanvas.SetDrawColor(255,255,255);

		if( LeftHandIK != none )
		{
			kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
			kCanvas.DrawText("LH_IK Strength"@LeftHandIK.ControlStrength);

			kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
			kCanvas.DrawText("LH_IK Loc"@LeftHandIK.EffectorLocation);
		}
		else
		{
			kCanvas.SetDrawColor(255,150,150);
			kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
			kCanvas.DrawText("No IK Node"@PathName(Mesh.AnimTreeTemplate));
			kCanvas.SetDrawColor(255,255,255);
		}

		WeaponSocketName = GetLeftHandIKWeaponSocketName();
		foreach Mesh.AttachedComponentsOnBone(class'SkeletalMeshComponent', PrimaryWeaponMeshComp, WeaponSocketName)
		{
			// Just do the first one
			break;
		}

		if( PrimaryWeaponMeshComp != none )
		{
			IKSocketName = GetLeftHandIKSocketName();
			if( PrimaryWeaponMeshComp.GetSocketWorldLocationAndRotation(IKSocketName, vLeftHandIKLoc) )
			{
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
				kCanvas.DrawText("Weapon"@IKSocketName@vLeftHandIKLoc);
				if( LeftHandIK != none && LeftHandIK.ControlStrength > 0.0f )
				{
					DrawDebugSphere(vLeftHandIKLoc, 4, 4, 0,255,0);
				}
				else
				{
					DrawDebugSphere(vLeftHandIKLoc, 4, 4, 255,0,0);
				}
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
				kCanvas.DrawText("Weapon mesh"@PathName(PrimaryWeaponMeshComp.SkeletalMesh));
			}
			else
			{
				kCanvas.SetDrawColor(255,150,150);
				kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
				kCanvas.DrawText("Weapon missing"@IKSocketName@"socket!"@PathName(PrimaryWeaponMeshComp.SkeletalMesh));
				kCanvas.SetDrawColor(255,255,255);
			}
		}
		else
		{
			kCanvas.SetDrawColor(255,150,150);
			kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
			kCanvas.DrawText("No weapon!");
			kCanvas.SetDrawColor(255,255,255);
		}
	}
}

/**
 * Override this function to draw to the HUD after calling AddHUDOverlayActor(). 
 * Script function called by NativePostRenderFor().
 * 
 */
simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
`if (`notdefined(FINAL_RELEASE))
	local XComCheatManager kCheatManager;
	local bool bSingleUnitDebugging;
	local Vector vScreenPos;

	super.PostRenderFor(kPC, kCanvas, vCameraPosition, vCameraDir);

	kCheatManager = XComCheatManager( GetALocalPlayerController().CheatManager );

	if (kCheatManager != none)
	{
		DebugIK(kCanvas, kCheatManager);
		DebugVis(kCanvas, kCheatManager);

		bSingleUnitDebugging = kCheatManager.m_DebugAnims_TargetName == self.Name;
		if (kCheatManager.bDebugAnims && kCheatManager.bDebugAnimsPawn && 
			((kCheatManager.m_DebugAnims_TargetName == '') || bSingleUnitDebugging))
		{
			vScreenPos = kCanvas.Project(Location);

			GetAnimTreeController().DebugAnims(kCanvas, kCheatManager.bDisplayAnims, none, vScreenPos);
			m_kGameUnit.DebugWeaponAnims(kCanvas, false, vScreenPos);
		}
	}
`endif
}

simulated event ApplyMITV(MaterialInstanceTimeVarying MITV)
{
	local SkeletalMeshComponent MeshComp;
	
	foreach AllOwnedComponents(class'SkeletalMeshComponent', MeshComp)
	{
		ApplyMITVToSkeletalMeshComponent(MeshComp, MITV);
	}
}

function ApplyMITVToSkeletalMeshComponent(SkeletalMeshComponent MeshComp, MaterialInstanceTimeVarying MITV)
{
	local MaterialInstanceTimeVarying MITV_Ghost;
	local SkeletalMeshComponent AttachedComponent;
	local int i;

	for (i = 0; i < MeshComp.SkeletalMesh.Materials.Length; i++)
	{
		MeshComp.PushMaterial(i, MITV, eMatPriority_AnimNotify);
		MITV_Ghost = MeshComp.CreateAndSetMaterialInstanceTimeVarying(i);
		MITV_Ghost.SetDuration(MITV_Ghost.GetMaxDurationFromAllParameters());
	}

	// (BSG:mwinfield,2012.03.13) This shouldn't work, but it does. What we really want to do is replace the AuxMaterials, 
	// but if I use SetAuxMaterial(), I can't create and set the Material instance and the effect doesn't work. Strangely,
	// if I set the material using the aux material index it does. To Do: Gain a better understanding of how this works.
	for (i = 0; i < MeshComp.AuxMaterials.Length; i++)
	{
		MeshComp.PushMaterial(i, MITV, eMatPriority_AnimNotify);
		MITV_Ghost = MeshComp.CreateAndSetMaterialInstanceTimeVarying(i);
		MITV_Ghost.SetDuration(MITV_Ghost.GetMaxDurationFromAllParameters());
	}

	// Loop over all of the SkeletalMeshComponents attached to this MeshComp and
	// apply the Ghost MITV to them as well. (Things like weapon attachements)
	for(i = 0; i < MeshComp.Attachments.Length; ++i)
	{
		AttachedComponent = SkeletalMeshComponent(MeshComp.Attachments[i].Component);
		if(AttachedComponent != none)
		{
			ApplyMITVToSkeletalMeshComponent(AttachedComponent, MITV);
		}
	}
}

simulated function CleanUpMITV()
{
	local MeshComponent MeshComp;
	local int i;

	foreach AllOwnedComponents(class'MeshComponent', MeshComp)
	{
		for (i = 0; i < MeshComp.Materials.Length; i++)
		{
			if (MeshComp.GetMaterial(i).IsA('MaterialInstanceTimeVarying'))
			{
				MeshComp.PopMaterial(i, eMatPriority_AnimNotify);
			}
		}

		for (i = 0; i < MeshComp.AuxMaterials.Length; i++)
		{
			if (MeshComp.GetMaterial(i).IsA('MaterialInstanceTimeVarying'))
			{
				MeshComp.PopMaterial(i, eMatPriority_AnimNotify);
			}
		}
	}

	UpdateAllMeshMaterials();
}

simulated function UpdateMeshAttachmentRenderChannels(PrimitiveComponent Attachment, RenderChannelContainer RenderChannels)
{
	local SkeletalMeshComponent SkelMeshComponent;
	local PrimitiveComponent AttachedComponent;
	local int Idx;

	if (Attachment != none)
	{
		Attachment.SetRenderChannels(RenderChannels);

		SkelMeshComponent = SkeletalMeshComponent(Attachment);
		if (SkelMeshComponent != None)
		{
			SkelMeshComponent.bUpdateSkelWhenNotRendered = true;
			for (Idx = 0; Idx < SkelMeshComponent.Attachments.Length; ++Idx)
			{
				AttachedComponent = PrimitiveComponent(SkelMeshComponent.Attachments[Idx].Component);
				if (AttachedComponent != none)
				{
					UpdateMeshAttachmentRenderChannels(AttachedComponent, RenderChannels);
				}
			}
		}
	}
}

//Helper method for playing full body idle / cinematic animations
function AnimNodeSequence PlayFullBodyAnimOnPawn(name AnimName, bool bLooping, float BlendTime=0.0f)
{
	local CustomAnimParams PlayAnimParams;
	local AnimNodeSequence Sequence;

	PlayAnimParams.AnimName = AnimName;

	if(!AnimTreeController.CanPlayAnimation(PlayAnimParams.AnimName))
	{
		PlayAnimParams.AnimName = 'HL_Idle'; //Fall back to combat idle if we can't play what was requested
	}

	if(AnimTreeController.CanPlayAnimation(PlayAnimParams.AnimName))
	{
		PlayAnimParams.BlendTime = BlendTime;
		PlayAnimParams.Looping = bLooping;
		PlayAnimParams.PlayRate = class'XComIdleAnimationStateMachine'.static.GetNextIdleRate();
		Sequence = AnimTreeController.PlayFullBodyDynamicAnim(PlayAnimParams);
	}	

	return Sequence;
}

//Implemented in sub classes
function PlayHQIdleAnim(optional name OverrideAnimName, optional bool bIsCapture = false, optional bool bIgnoreInjuredAnim = false)
{
}

// Start Issue #24
simulated exec function UpdateAnimations()
{
	local XComGameStateHistory History;
	local array<X2DownloadableContentInfo> DLCInfos;
	local array<AnimSet> CustomAnimSets;
	local XComGameState_Unit UnitState;
	local int i;

	History = `XCOMHISTORY;

	super.UpdateAnimations();

	if (UnitState_Menu != none) // We're at the Main Menu
	{
		UnitState = UnitState_Menu;
	}
	else // We're at a Saved Game
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
	}

	if (UnitState != none)
	{
		DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
		for(i = 0; i < DLCInfos.Length; ++i)
		{
			CustomAnimSets.Length = 0;
			DLCInfos[i].UpdateAnimations(CustomAnimSets, UnitState, self);
			if (CustomAnimSets.Length > 0)
				XComAddAnimSetsExternal(CustomAnimSets);
		}
	}
}
// End Issue #24

//Request from the narrative moment to play dialog
function QueueDialog(name DialogAnimName)
{
	QueuedDialogAnim = DialogAnimName;		
	GotoState('PlayDialogLineOneshot');
}

//Triggered by animation
function PlayDialogAudio()
{
	`HQPRES.m_kNarrativeUIMgr.DialogTriggerAudio();
}

state PlayDialogLineOneshot
{
	function AnimNodeSequence PlayDialogAnimInternal(name AnimationName)
	{
		local CustomAnimParams PlayAnimParams;

		PlayAnimParams.AnimName = AnimationName;
		PlayAnimParams.Looping = false;

		return AnimTreeController.PlayFullBodyDynamicAnim(PlayAnimParams);
	}

begin:
	FinishAnim(PlayDialogAnimInternal(QueuedDialogAnim));
	PlayHQIdleAnim();
	QueuedDialogAnim = '';//Done with the line
}

// used for the gremlin in the armory
state Offscreen
{
begin:
	PlayHQIdleAnim(name(HQIdleAnim));
}

state Onscreen
{
begin:
	PlayHQIdleAnim(name(HQIdleAnim));
}

state StartOnscreenMove
{
	function AnimNodeSequence PlayMoveOnscreenAnimation(name AnimationName)
	{
		local CustomAnimParams PlayAnimParams;

		PlayAnimParams.AnimName = AnimationName;
		PlayAnimParams.Looping = false;
		PlayAnimParams.PlayRate = class'XComIdleAnimationStateMachine'.static.GetNextIdleRate();

		return AnimTreeController.PlayFullBodyDynamicAnim(PlayAnimParams);	
	}

begin:
	FinishAnim(PlayMoveOnscreenAnimation(name(HQOnscreenAnimPrefix$"Start")));
	SetLocation(Location - HQOnscreenOffset);
	GotoState('FinishOnscreenMove');
}

state FinishOnscreenMove
{
	function AnimNodeSequence PlayMoveOnscreenAnimation(name AnimationName)
	{
		local CustomAnimParams PlayAnimParams;

		PlayAnimParams.AnimName = AnimationName;
		PlayAnimParams.Looping = false;
		PlayAnimParams.PlayRate = class'XComIdleAnimationStateMachine'.static.GetNextIdleRate();

		return AnimTreeController.PlayFullBodyDynamicAnim(PlayAnimParams);	
	}

begin:
	FinishAnim(PlayMoveOnscreenAnimation(name(HQOnscreenAnimPrefix$"Stop")));
	SetLocation(HQOnscreenLocation);
	GotoState('Onscreen');
}

state MoveOffscreen
{
	function AnimNodeSequence PlayMoveOffscreenAnimation()
	{
		local CustomAnimParams PlayAnimParams;

		PlayAnimParams.AnimName = name(HQOffscreenAnim);
		PlayAnimParams.Looping = false;
		PlayAnimParams.PlayRate = class'XComIdleAnimationStateMachine'.static.GetNextIdleRate();

		return AnimTreeController.PlayFullBodyDynamicAnim(PlayAnimParams);	
	}

begin:
	HQOnscreenLocation = Location;
	FinishAnim(PlayMoveOffscreenAnimation());
	SetLocation(Location + HQOnscreenOffset);
	GotoState('Offscreen');
}

state Gremlin_Move
{
	function AnimNodeSequence PlayAnimation(name AnimationName, bool bLooping = false)
	{
		local CustomAnimParams PlayAnimParams;

		PlayAnimParams.AnimName = AnimationName;
		PlayAnimParams.Looping = bLooping;
		PlayAnimParams.PlayRate = class'XComIdleAnimationStateMachine'.static.GetNextIdleRate();

		return AnimTreeController.PlayFullBodyDynamicAnim(PlayAnimParams);	
	}
}

state Gremlin_Walkback extends Gremlin_Move
{
begin:
	PlayAnimation('Gremlin_WalkBack_Normal');
}

state Gremlin_Idle extends Gremlin_Move
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		PlayAnimation('Gremlin_Idle_Normal', true);
	}
}

state Gremlin_Walkup extends Gremlin_Move
{
begin:
	FinishAnim(PlayAnimation('Gremlin_WalkUp_Normal'));
	GotoState('Gremlin_Idle');
}

//==============================================================================
// 		REPLICATION:
//==============================================================================

simulated event ReplicatedEvent( name varName )
{
	super.ReplicatedEvent( varName );

	switch( varName )
	{
	case 'm_vTeleportToLocation':
		SetLocation(m_vTeleportToLocation);
		break;
	}
}

replication
{
	if( Role == Role_Authority && bNetDirty )
		 m_vTeleportToLocation;
}

defaultproperties
{
	Components.Remove(CollisionCylinder)	

	PhysicsPushScale=1.0f

	PlayNonFootstepSounds = true;

	m_bUseRMA = true
	m_bInMatinee = false
	m_bHiddenForMatinee = false

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=false
		bCastShadows=false
		bDynamic=true
		bUseBooleanEnvironmentShadowing=false
		bForceCompositeAllLights=true
		bSynthesizeDirectionalLight=true
		bIsCharacterLightEnvironment=true;
		bSynthesizeSHLight=true
		MinTimeBetweenFullUpdates=0.0
		InvisibleUpdateTime=4
		bUseBiasedSubjectMatrix=true
		fBiasedSubjectFarDistance=150 // Used to be Mesh.Bounds.SphereRadius, which was roughly 65
		bDoNotResetOnAttachingTo=true
	End Object
	//LightEnvironment = MyLightEnvironment;
	//Components.Add(MyLightEnvironment)

	Begin Object Class=CharacterLightRigComponent Name=MyLightRig
	End Object
	LightRig=MyLightRig
	Components.Add(MyLightRig)

	m_DefaultLightingChannels=(bInitialized=true,Dynamic=true)

	//Begin Object Class=LightingChannelsObject Name=OutsideLightingChannelsObject
	//	LightingChannels=(BSP=true,Static=true,Dynamic=false,Unnamed_1=false,Unnamed_2=false)
	//End Object 
	//OutsideLightChannels=OutsideLightingChannelsObject;

	//Begin Object Class=LightingChannelsObject Name=InsideLightingChannelsObject
	//	LightingChannels=(BSP=false,Static=false,Dynamic=false,Unnamed_1=true,Unnamed_2=true)
	//End Object
	//InsideLightChannels=InsideLightingChannelsObject;


	Begin Object Name=SkeletalMeshComponent
		//LightEnvironment=MyLightEnvironment
		bAcceptsLights=true
		bAcceptsDynamicLights=true
		bHasPhysicsAssetInstance=false
		//bEnableFullAnimWeightBodies=true
		bUpdateJointsFromAnimation=true
		bUpdateKinematicBonesFromAnimation=false
		bUpdateSkelWhenNotRendered=FALSE
		//bComponentUseFixedSkelBounds=TRUE;
		CollideActors=true
		BlockZeroExtent=true
		bAcceptsDynamicDecals=TRUE
		CanBlockCamera=TRUE
		bNeedsGameThreadVisibility=TRUE;
		bNotifyRigidBodyCollision=true
		ScriptRigidBodyCollisionThreshold=300.0
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE,Vehicle=TRUE)
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=FALSE,Gameplay_1=TRUE,bInitialized=TRUE) // Gameplay_1 is the unit-only lighting channel
	End Object

	Mesh=SkeletalMeshComponent

	Components.Add(SkeletalMeshComponent)

	Begin Object Class=CylinderComponent Name=UnitCollisionCylinder
		CollisionRadius=14.000000

		//CollisionHeight is decided in PostBeginPlay
		//CollisionHeight=10.000000
		BlockNonZeroExtent=true
		BlockZeroExtent=false       // Zero extent traces should not be enabled on the collision cylinder, we use the physics asset for those. - Casey
		BlockActors=true
		CollideActors=true
		BlockRigidBody=true
		RBChannel=RBCC_Pawn
		RBCollideWithChannels=(Default=True,Pawn=False,Vehicle=True,Water=True,GameplayPhysics=True,EffectPhysics=True,Untitled1=True,Untitled2=True,Untitled3=True,Untitled4=True,Cloth=True,FluidDrain=True,SoftBody=True,FracturedMeshPart=False,BlockingVolume=True,DeadPawn=True)
		CanBlockCamera=TRUE
		HiddenGame=False

	End Object
	CollisionComponent=UnitCollisionCylinder
	CylinderComponent=UnitCollisionCylinder
	Components.Add(UnitCollisionCylinder)

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
		//TranslucencySortPriority=1000
	End Object
	Components.Add(RangeIndicatorMeshComponent)
	RangeIndicator=RangeIndicatorMeshComponent
	CloseAndPersonalRing=StaticMesh'UI_Range.Meshes.RadiusRing_CloseAndPersonal'
	ArcThrowerRing=StaticMesh'UI_Range.Meshes.RadiusRing_ArcThrower'
	CivilianRescueRing=StaticMesh'UI_Range.Meshes.RadiusRing_CivRescue'
	MedikitRing=StaticMesh'UI_Range.Meshes.RadiusRing_MedKit'
	KineticStrikeCard=StaticMesh'UI_Range.Meshes.KinetiStrikeDir_Plane'
	FlamethrowerCard=StaticMesh'UI_Range.Meshes.96Triangle'

	GroundSpeed=1
	MaxStepHeight=48.0f //RAM - Need to be able to step onto ramp tiles from the side
	WalkableFloorZ=.10f

	bPushesRigidBodies=true // jboswell: causes dudes to push stuff out of the way
	RBPushRadius=8.0f // added to collision cylinder radius as a margin
	RBPushStrength=5.0f // force used to push objects out of the way

	ControllerClass=none

	SupportedEvents.Add(class'SeqEvent_OnUnitChanged')

	RotationRate=(Pitch=20000,Yaw=40000,Roll=20000)

	LocalCameraOffset=(X=-50.0f,Y=38.0f,Z=0.0f)
	CameraFocusDistance=6400.0f

	BaseEyeHeight=40.0f

	//bAlwaysRelevant=true
	//RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=false
	RemoteRole=ROLE_None

	bCollideActors=true	
	bBlockActors=false
	CollisionType=COLLIDE_BlockAll
	bDoDyingActions=true

	RagdollFlag=ERagdoll_IfDamageTypeSaysTo

	HeadBoneName=Head
	AimAtTargetMissPercent=1.0
	MeleeRange=128

	m_bAuxParamNeedsPrimary = true
	m_bAuxParamNeedsSecondary = false
	m_bAuxParametersDirty = false
	m_bAuxParamNeedsAOEMaterial = false
	m_bNewNeedsAOEMaterial = false
	m_bUseFriendlyAOEMaterial = false
	m_bAuxAlwaysVisible=false  // This state must match the default value of the MIC
	m_kAuxiliaryMaterial_ZeroAlpha = Material'FX_Visibility.Materials.MPar_NoUnitGlow'
	bIsFemale = false
	m_fVisibilityPercentage=0.0f
	m_bHasFullAnimWeightBones=false

	fPhysicsMotorForce = 100

	m_bTutorialCanDieInMatinee=false

	m_fPercent=100
	m_iTurnsTillVisibilityCheck=0

	CloseRangeMissDistance=512
	NormalMissDistance=1024
	CloseRangeMissAngleMultiplier=1.0
	NormalMissAngleMultiplier=3.0

	m_bDropWeaponOnDeath=false

	RagdollBlendTime = 0.01f;

	TurnSpeedMultiplier=1.0f

	RagdollFinishTimer=10.0f
	DefaultRagdollFinishTimer=10.0f
	WaitingToBeDestroyedTimer=5.0f
	bAllowPersistentFX=true

	TurningSequence = none;

	AkEventCharacterSwitch = "XCOMSoldier"
	WeaponScale=1.0

	PerkEffectScale=1.0

	fFallImpactSoundEffectTimer = 0.0f

	bHidden=true // spawn invisible, until we request being set to visible

	bUseDesiredEndingAtomOnDeath=true
	EvacWithRope = true

	bPhotoboothPawn = false
	DragRagdollDistanceThreshold = 400.0f
}
