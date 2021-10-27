//---------------------------------------------------------------------------------------
//  FILE:    X2UnifiedProjectile.uc
//  AUTHOR:  Ryan McFall  --  9/12/2014
//  PURPOSE: This actor is responsible for visualizing projectiles within X-Com. A list
//           of projectile components are defined, each potentially defining some visual
//           aspect of a single 'logical' projectile. For instance, one component may be a 
//           glowing ball of plasma while another component is a heat distortion trail.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2UnifiedProjectile extends Actor dependson(X2UnifiedProjectileElement) native(Weapon)
	dependson(XComPrecomputedPath)
	hidecategories(Movement, Display, Attachment, Actor, Collision, Physics, Debug, Object, Advanced);

//Encapsulates a projectile component's instance data
struct native ProjectileElementInstance
{
	//These are set when this element is created
	var X2UnifiedProjectileElement ProjectileElement; //Defines behavior for this projectile component 
	var float StartTime;                              //The time at which this projectile will fire	
	var float EndTime;                                //The time at which this projectile will hit something, or fade out
	var float LastImpactTime;						  //The time at which we last played the impact events
	var int VolleyIndex;                              //Indicates which volley this is part of
	var int MultipleProjectileIndex;                  //For multiple projectile shots, indicates which projectile this element represents
	var float AdjustedTravelSpeed;                    //Initialized to the element's TravelSpeed, but different if the element's MaxTravelTime requires it to be faster
	
	//These are set and updated when the projectile is fired
	var bool bFired;                                  //Indicates whether this instance has been fired or not
	var bool bRecoilFromFiring;						  //Indicates whether we have start the recoil moment before the actual firing
	var bool bNotifiedTarget;						  //Indicates if this projectile have notified the targets that it has hit.
	var float AliveTime;						      //Tracks how long this projectile has been alive
	var float ActiveTime;							  //Tracks how long this projectile has been active
	var bool bWaitingToDie;							  //This flag is set when the projectile has been set into its final state ( triggered by its AliveTime )
	var bool bConstantComplete;                       //A constant
	var ParticleSystemComponent ParticleEffectComponent;//A particle system component from the world info pools
	var Vector InitialSourceLocation;       //This is the location that the projectile was fired from
	var Vector InitialTargetLocation;       //The initial target location for the projectile
	var Vector VisualizerToTargetOffset;	//The offset to get from the (possible) target visualizer to the InitialTargetLocation
	var Vector InitialTargetNormal;			//The normal detected if the projectile will hit something
	var Vector InitialTravelDirection;      //A normalized direction from InitialSourceLocation to InitialTargetLocation	
	var TraceHitInfo ImpactInfo;			//Stores information from the projectile trace
	var float TrailAdjustmentTime;			//Tracks the time that a trailing effect will spend growing/shrinking at the beginning/end of its lifespan
	var float InitialTargetDistance;		//The distance to the target as expressed by VSize(AimLocation - InitialSourceLocation). The projectile may travel past this point if it does not strike the target
	var bool bStruckTarget;					//Record whether this projectile struck the target. Will always be false for misses.

	var array<ProjectileTouchEvent> ImpactEvents;	//This contains a list of all interations the projectile will have with the environment as it travels
	var int ImpactEventsProcessed;					//Index into ImpactEvents indicating which ones have already been handled	

	var Actor SourceAttachActor;			//This actor is the initial position of the shot, some shot types move this point
	var Actor TargetAttachActor;			//This actor travels towards the target, some types of projectile particle effect attach to it
	var XComPrecomputedPath GrenadePath;            //Reference to the precomputed path object if we are using it

	structcpptext
	{
	FProjectileElementInstance()
	{
		appMemzero(this, sizeof(FProjectileElementInstance));
	}
	FProjectileElementInstance(EEventParm)
	{
		appMemzero(this, sizeof(FProjectileElementInstance));
	}
	}
};

struct native ProjectileSpreadValues
{
	var array<Vector> SpreadValues; //Support multi-shot projectiles such as shotguns
};

//Data definitions
var() instanced editinline array<X2UnifiedProjectileElement> ProjectileElements <ToolTip="Each element of this array defines distinct visual pieces of a firing projectile">;

//Runtime data
var private AnimNotify_FireWeaponVolley VolleyNotify;   //Reference to the animation notify that created us, if any
var private X2Action_Fire FireAction;                   //Reference to the fire action we are a part of. This is the actor that created us
var private XComGameStateContext_Ability SourceAbility; //Reference to the game state ability context being visualized by X2Action_Fire
var private EAbilityHitResult AbilityContextHitResult;
var private vector AbilityContextTargetLocation;
var private int AbilityContextPrimaryTargetID;
var private int AbilityContextAbilityRefID;
var private bool bWasHit;                               //Tracks whether the ability that created this projectile hit the target or not. Some abilities have different looking hit / miss effects
var private bool bIsASuppressionEffect;                 //Track if this is a suppression effect.  This flag is set and cached during the projectile's setup.
var private XComWeapon SourceWeapon;                    //Reference to the weapon firing this projectile volley
var private array<ProjectileSpreadValues> RandomSpreadValues; //We want each volley to have its own random trajectory, but within each volley the different projectile elements should take the same path
var private X2WeaponTemplate WeaponTemplate;
var private AbilityInputContext StoredInputContext;     //Keeps the input context for the ability responsible for these projectiles
var private AbilityResultContext StoredResultContext;   //Keeps the result context for the ability responsible for these projectiles


var private bool bCosmetic;                             //Indicates that this projectile is just for show
var private Actor CosmeticSource;                       //If the projectile is cosmetic, this actor represents the source
var private vector CosmeticSourceLocation;              // If the projectile is cosmetic, location represents the source. This will be ignored if the CosmeticSource is not none.
var private Actor CosmeticTarget;                       //If the projectile is cosmetic, this location represents the target
var private vector CosmeticTargetLocation;              // If the projectile is cosmetic, location represents the target. This will be ignored if the CosmeticTarget is not none.
var private bool bCosmeticShouldHitTarget;              // Usually a cosmetic projectile does not have to hit the target, this ensures it does

var private array<ProjectileElementInstance> Projectiles;//Holds a list of projectile instances and their supporting data
var private bool bSetupVolley;                           //Lets the cleanup process know that projectile initialization has occurred and it is safe to destroy this object.
var private bool bPlayedMetaHitEffect;                   //A latch for making sure the Meta Effect only plays once
var private name OrdnanceType;
var bool bFirstShotInVolley;							//Indicate this is the first shot in the volley
var private bool bProjectileFired;						//Indicate that at least a shot has been fired;
var array<AnimNodeSequence> PlayingSequences;			//Used to remove anim sequences we started

cpptext
{
	virtual void PostLoad();
}

function ConfigureNewProjectile(X2Action_Fire InFireAction, 
								AnimNotify_FireWeaponVolley InVolleyNotify,
								XComGameStateContext_Ability AbilityContext,
								XComWeapon InSourceWeapon)
{
	local int MultiIndex;	
	local XComGameState_Ability UsedAbility;

	FireAction = InFireAction;
	VolleyNotify = InVolleyNotify;
	SourceAbility = AbilityContext;
	StoredInputContext = AbilityContext.InputContext;
	StoredResultContext = AbilityContext.ResultContext;
	AbilityContextHitResult = StoredResultContext.HitResult;
	AbilityContextTargetLocation = StoredResultContext.ProjectileHitLocations[0];
	if (FireAction != none && FireAction.PrimaryTargetID > 0)
		AbilityContextPrimaryTargetID = FireAction.PrimaryTargetID;
	else
		AbilityContextPrimaryTargetID = StoredInputContext.PrimaryTarget.ObjectID;
	AbilityContextAbilityRefID = StoredInputContext.AbilityRef.ObjectID;
	SourceWeapon = InSourceWeapon;

	UsedAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContextAbilityRefID));

	if (UsedAbility.SourceWeapon.ObjectID > 0)
	{
		WeaponTemplate = X2WeaponTemplate(XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(UsedAbility.SourceWeapon.ObjectID)).GetMyTemplate());
	}

	if(StoredInputContext.MultiTargets.Length > 0)
	{
		for(MultiIndex = 0; MultiIndex < StoredInputContext.MultiTargets.Length; ++MultiIndex)
		{
			bWasHit = class'XComGameStateContext_Ability'.static.IsHitResultHit(StoredResultContext.MultiTargetHitResults[MultiIndex]);
			if( bWasHit)
			{
				break;			
			}
		}
	}
	else
	{
		bWasHit = class'XComGameStateContext_Ability'.static.IsHitResultHit(StoredResultContext.HitResult);
	}

	if( UsedAbility != none && (UsedAbility.GetMyTemplate().TargetingMethod.static.GetOrdnanceType() != '') )
	{
		OrdnanceType = UsedAbility.GetMyTemplate().TargetingMethod.static.GetOrdnanceType();
	}

	if( UsedAbility != none )
	{
		bIsASuppressionEffect = UsedAbility.GetMyTemplate().bIsASuppressionEffect;
	}
	bProjectileFired = false;
}

// If Source or Target are none, then use the SourceLocation or TargetLocation respectively. This allows projectiles to fire to specific locations
// without an actor in that spot (for example Blazing Pinions). If an InFireAction is sent, hit notifies will be sent.
function ConfigureNewProjectileCosmetic(AnimNotify_FireWeaponVolley InVolleyNotify, XComGameStateContext_Ability AbilityContext, optional Actor Source, optional Actor Target,
										optional X2Action_Fire InFireAction, optional vector SourceLocation, optional vector TargetLocation, optional bool bHitTarget)
{
	VolleyNotify = InVolleyNotify;
	bCosmetic = true;
	bCosmeticShouldHitTarget = bHitTarget;
	SourceAbility = AbilityContext;

	if( InFireAction != none)
	{
		FireAction = InFireAction;
	}

	if (Source != none)
	{
		CosmeticSource = Source;
	}
	else
	{
		CosmeticSourceLocation = SourceLocation;
	}

	if (Target != none)
	{
		CosmeticTarget = Target;
	}
	else
	{
		CosmeticTargetLocation = TargetLocation;
	}
}

function ProjectileTrace( out Vector HitLocation, out Vector HitNormal, Vector TraceStart, Vector TraceDirection, bool bCollideWithTargetPawn, optional out TraceHitInfo HitInfo )
{
	local Vector TraceEnd;

	TraceEnd = TraceStart + (TraceDirection * 10000);

	if(!bCosmetic)
	{
		if(!`XWORLD.ProjectileTrace(SourceAbility, HitLocation, HitNormal, TraceStart, TraceDirection, bCollideWithTargetPawn, HitInfo))
		{
			HitLocation = TraceEnd;
		}
	}
	else
	{
		if( CosmeticSource != none )
		{
			CosmeticSource.Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, vect(0, 0, 0), HitInfo);
			if(VSizeSq(HitNormal) == 0.0f) // check if there was a hit (because Trace returning a bool would make too much sense)
			{
				HitLocation = TraceEnd;
			}
		}
		else
		{
			HitNormal = Normal(CosmeticSourceLocation - CosmeticTargetLocation);
			HitLocation = CosmeticTargetLocation;
		}
	}
}

function DebugRender( )
{
	local Rotator MuzzleRotation;

	//Hit location and hit location modifying vectors
	local Vector SourceLocation;
	local Vector HitLocation;
	local Vector HitNormal;
	local Vector AimLocation;
	local Vector TravelDirection;
	local Vector TravelDirection2D;

	// The ability is not overriding the source location, so calculate as usual
	SkeletalMeshComponent( SourceWeapon.Mesh ).GetSocketWorldLocationAndRotation( Projectiles[ 0 ].ProjectileElement.MuzzleSocketName, SourceLocation, MuzzleRotation );

	// Get the target location
	// The ability is not overriding the target location, so calculate as usual
	if (Projectiles[ 0 ].ProjectileElement.bLockOrientationToMuzzle)
	{
		ProjectileTrace( AimLocation, HitNormal, SourceLocation, Vector( MuzzleRotation ), false );
	}
	else
	{
		AimLocation = GetAimLocation( 0 );
	}

	//Calculate the travel direction for this projectile
	TravelDirection = AimLocation - SourceLocation;
	//TravelDistance = VSize( TravelDirection );
	TravelDirection2D = TravelDirection;
	TravelDirection2D.Z = 0.0f;
	TravelDirection2D = Normal( TravelDirection2D );
	TravelDirection = Normal( TravelDirection );

	//Build the HitLocation
	ProjectileTrace( HitLocation, HitNormal, SourceLocation, TravelDirection, false );

	DrawDebugCoordinateSystem( SourceLocation, rotator( TravelDirection ), 10, true );
	DrawDebugLine( SourceLocation, HitLocation, 255, 255, 255, true );
}

//Iterate the projectile elements and create the instanced events that will create projectiles
function SetupVolley()
{
	local int VolleyIndex;
	local int ProjectileElementIndex;
	local int MultipleProjectileIndex;
	local int SuppressionRand;
	local X2UnifiedProjectileElement CurrentProjectileElement;
	local ProjectileElementInstance EmptyInstance;
	local int AddProjectileIndex;
	local float StartFireTime;
	local float NextFireTime;	
	local Vector SetSpreadValues;
	local bool PlayFromHit, PlayFromMiss, PlayFromSuppress, IsRightVolley;
	local XComGameState_Ability Ability;
	local X2AbilityTemplate AbilityTemplate;

	StartFireTime = WorldInfo.TimeSeconds;
	NextFireTime = StartFireTime;

	Ability = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID( AbilityContextAbilityRefID ) );
	AbilityTemplate = Ability.GetMyTemplate( );

	if (AbilityTemplate.bIsASuppressionEffect)
	{
		SuppressionRand = `SYNC_RAND( StoredResultContext.ProjectileHitLocations.Length );
		AbilityContextTargetLocation = StoredResultContext.ProjectileHitLocations[SuppressionRand];
	}
	
	for( VolleyIndex = 0; VolleyIndex < VolleyNotify.NumShots; ++VolleyIndex )
	{	
		RandomSpreadValues.Add(1);

		//Iterate the projectile elements, instantiating the individual events of the volley
		for( ProjectileElementIndex = 0; ProjectileElementIndex < ProjectileElements.Length; ++ProjectileElementIndex )
		{
			CurrentProjectileElement = ProjectileElements[ProjectileElementIndex];

			// Custom volley notifications should only fire custom projectiles and vis-versa
			if (VolleyNotify.bCustom != CurrentProjectileElement.bIsCustomDefinition)
			{
				continue;
			}
			else if (VolleyNotify.bCustom == true)
			{
				// Custom volley notifications should only fire the projectiles with the same ID
				if (VolleyNotify.CustomID != CurrentProjectileElement.CustomID)
				{
					continue;
				}
			}

			if(!bCosmetic) //Non cosmetic projectiles need to look up what kind of hit they were
			{
				PlayFromHit = (CurrentProjectileElement.bPlayOnHit && bWasHit && !AbilityTemplate.bIsASuppressionEffect);
				PlayFromSuppress = (CurrentProjectileElement.bPlayOnSuppress && bWasHit && AbilityTemplate.bIsASuppressionEffect);
				PlayFromMiss = (CurrentProjectileElement.bPlayOnMiss && !bWasHit);				
			}
			else
			{
				PlayFromHit = true;
				IsRightVolley = true;				
			}

			IsRightVolley = (CurrentProjectileElement.UseOncePerVolleySetting == eOncePerVolleySetting_None || VolleyIndex == 0); //Once per volley elements are only processed for index 0			

			//Only start projectile elements that match the result of this hit, or have the appropriate once per volley settings
			if( (PlayFromHit || PlayFromMiss || PlayFromSuppress) && IsRightVolley) 
			{
				//Projectile elements can specify multiple projectiles, as might be the case with a shotgun blast style of volley
				for( MultipleProjectileIndex = 0; MultipleProjectileIndex < CurrentProjectileElement.ProjectileCount; ++MultipleProjectileIndex )
				{
					//Create a new projectile element instance
					AddProjectileIndex = Projectiles.Length;
					Projectiles.AddItem(EmptyInstance);

					//Configure the instance's fire time
					Projectiles[AddProjectileIndex].ProjectileElement = CurrentProjectileElement;
					Projectiles[AddProjectileIndex].StartTime = NextFireTime;				
					switch(CurrentProjectileElement.UseOncePerVolleySetting)
					{
					case eOncePerVolleySetting_None:	
						//This is the default case, and requires no adjustment
						break;
					case eOncePerVolleySetting_Start:
						Projectiles[AddProjectileIndex].StartTime += CurrentProjectileElement.OncePerVolleyDelay;					
						break;
					case eOncePerVolleySetting_End:
						Projectiles[AddProjectileIndex].StartTime += (VolleyNotify.NumShots * VolleyNotify.ShotInterval) + CurrentProjectileElement.OncePerVolleyDelay;					
						break;
					}

					//We want to make sure that the multiple projectile elements use the same random offsets so that
					//for instance tracers don't end up going in a different direction than the smoke trail.
					Projectiles[AddProjectileIndex].MultipleProjectileIndex = MultipleProjectileIndex;
					Projectiles[AddProjectileIndex].VolleyIndex = VolleyIndex;
					if( RandomSpreadValues[VolleyIndex].SpreadValues.Length <= MultipleProjectileIndex )
					{
						SetSpreadValues.X = `SYNC_FRAND();
						SetSpreadValues.Y = `SYNC_FRAND();
						SetSpreadValues.Z = `SYNC_FRAND(); //Added Z spread value for aoe shots
						RandomSpreadValues[VolleyIndex].SpreadValues.AddItem(SetSpreadValues);
					}
				}
			}
		}

		NextFireTime += VolleyNotify.ShotInterval;
	}
	bSetupVolley = true;
	bFirstShotInVolley = true;
	//if (Projectiles.Length > 0)
	//{
	//	DebugRender( );
	//}
}

function EndConstantProjectileEffects( )
{
	local int Index;

	for (Index = 0; Index < Projectiles.Length; ++Index)
	{
		if ((Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_RangedConstant) && !Projectiles[Index].bConstantComplete)
		{
			Projectiles[Index].bConstantComplete = true;

			Projectiles[ Index ].ParticleEffectComponent.OnSystemFinished = none;
			Projectiles[ Index ].ParticleEffectComponent.DeactivateSystem( );
			Projectiles[ Index ].ParticleEffectComponent.KillParticlesForced( );
			// Start Issue #720
			/// HL-Docs: feature:ProjectilePerformanceDrain; issue:720; tags:tactical
			/// The game uses a global pool `WorldInfo.MyEmitterPool` to store Particle System Components (PSCs),
			/// which helps optimize performance. When a PSC is no longer needed, it is returned to the pool 
			/// so that it can be reused again later.
			///
			/// To return a PSC back to the pool, the `EmitterPool::OnParticleSystemFinished()` function must be called, 
			/// which usually happens seamlessly - the pool sets the `ParticleSystemComponent::OnSystemFinished` delegate 
			/// to the aforementioned function when the PSC is initially borrowed from the pool 
			/// (via `EmitterPool::SpawnEmitter`).
			///
			/// However, `X2UnifiedProjectile` overwrites the `OnSystemFinished` delegate with its own one 
			/// after borrowing the PSC from the pool, which means the `EmitterPool::OnParticleSystemFinished()`
			/// is never called for these PSCs. 
			///
			/// As such, the pool is never made aware that those PSCs are ready for reuse and when a new PCS is requested, 
			/// the pool has no choice but to simply create a new one, resulting in the pool getting bloated 
			/// with all the PSCs ever spawned by `X2UnifiedProjectile`s.
			///
			/// This bloat leads to two observable effects: endlessly increasing RAM usage and a significant 
			/// performance degradation. The more projectiles are fired over the course of a mission, the worse 
			/// these effects become. Frequent use of the Suppression ability or Idle Suppression mod 
			/// kick the problem into overdrive.
			///
			/// To address this bug, we manually call `WorldInfo.MyEmitterPool.OnParticleSystemFinished()` on PSCs 
			/// in `X2UnifiedProjectile` when the projectile is done with them.
			///
			/// **Compability note**: some particle systems cannot be returned directly after the projectile is done with the
			/// particle system - doing so destoys trails/smoke/effects that dissipate over time (e.g. rocket trails). To
			/// address this issue, we delay the return to pool (and the forced destruction of any remaining particles) by
			/// 1 minute. If this is not enough for your particle system, you can override the behaviour in `XComGame.ini`.
			/// Here's an example/template:
			///
			/// ```ini
			/// [XComGame.CHHelpers]
			/// +ProjectileParticleSystemExpirationOverrides=(ParticleSystemPathName="SomePackage.P_SomeParticleSystem", ExpiryTime=120)
			/// ```
			///
			/// | Property | Value |
			/// | -------- | ----- |
			/// | `ParticleSystemPathName` | The full path to your ParticleSystem (what you configure with emitters in the editor) |
			/// | `ExpiryTime` | Time in seconds to pass between the projectile being done with the system and its return to the pool |
			///
			/// Keep in mind that the above time (either the 1 min default or the override) is the max allowed delay - if 
			/// a particle system finishes (and reports so by calling `PSC.OnSystemFinished`), the delay will be aborted 
			/// and the PSC will be instantly returned to the pool. As such, there is no need/reason to manually set lower
			/// expiration times than the default - just make sure that your particle system is properly configured in
			/// the editor.
			///
			/// Mods that create Particle System Components using the Emitter Pool must carefully handle them the same way:
			/// if the PSC's `OnSystemFinished` delegate is replaced, then `EmitterPool::OnParticleSystemFinished()` must
			/// be called for this PSC manually when the PSC is no longer needed, otherwise the same "memory leak" 
			/// will occur. This applies to all PSCs using the Emitter Pool, not just those in `X2UnifiedProjectile`.
			WorldInfo.MyEmitterPool.OnParticleSystemFinished(Projectiles[ Index ].ParticleEffectComponent);
			CancelDelayedReturnToPoolPSC(Projectiles[ Index ].ParticleEffectComponent);
			// End Issue #720
			Projectiles[ Index ].ParticleEffectComponent = none;
			Projectiles[ Index ].SourceAttachActor.SetPhysics( PHYS_None );
			Projectiles[ Index ].TargetAttachActor.SetPhysics( PHYS_None );
		}
	}
}

function CreateProjectileCollision(Actor ProjectileActor)
{
	local CylinderComponent CollisionCylinder;

	CollisionCylinder = new(Self) class 'CylinderComponent';
	CollisionCylinder.SetActorCollision(true, false, false);

	ProjectileActor.AttachComponent(CollisionCylinder);
	ProjectileActor.CollisionComponent = CollisionCylinder;

	ProjectileActor.SetCollision(true, false, false);
}

//Getting aim location
function SetupAim(int Index, XComGameState_Ability AbilityState, X2AbilityTemplate AbilityTemplate, out Vector SourceLocation, out Vector AimLocation)
{
	local Rotator MuzzleRotation;
	local vector DifferenceLocation;
	local TTile DifferenceTileLocation;
	local XComUnitPawn UnitPawn;

	if(!bCosmetic)
	{
		// This is not cosmetic, so calculate as usual

		//The weapon mesh should already be attached to the pawn at this point (so we can fire projectiles from it).
		//If not, use a fallback position on the pawn itself; the weapon mesh is likely in a totally wrong location.
		if (SourceWeapon.Mesh.Owner == SourceWeapon.m_kPawn)
			SkeletalMeshComponent(SourceWeapon.Mesh).GetSocketWorldLocationAndRotation(Projectiles[Index].ProjectileElement.MuzzleSocketName, SourceLocation, MuzzleRotation);
		else
			SourceWeapon.m_kPawn.Mesh.GetSocketWorldLocationAndRotation('R_Hand', SourceLocation, MuzzleRotation);
	}
	else
	{
		if( CosmeticSource != none )
		{
			SourceLocation = CosmeticSource.Location;
			MuzzleRotation = CosmeticSource.Rotation;
		}
		else
		{
			SourceLocation = CosmeticSourceLocation;
			MuzzleRotation = Rotator(Normal(CosmeticTargetLocation - CosmeticSourceLocation));
		}
	}

	if (!AbilityTemplate.bOverrideAim)
	{
		AimLocation = GetAimLocation(Index);
	}
	else
	{
		UnitPawn = XComUnitPawn(SourceWeapon.m_kPawn);
		if (AbilityTemplate.bUseSourceLocationZToAim)
		{
			AimLocation = GetAimLocation(Index);
			DifferenceLocation = SourceLocation - AimLocation;
			DifferenceLocation.Z = Abs(DifferenceLocation.Z);
			DifferenceTileLocation = `XWORLD.GetTileCoordinatesFromPosition(DifferenceLocation);
			//Only Change the aim direction if the source unit is near the same Z Tile level as the target.
			if (DifferenceTileLocation.Z < 2)
			{
				UnitPawn.TargetLoc.Z = SourceLocation.Z;
			}
		}
		AimLocation = UnitPawn.TargetLoc;
		SourceWeapon.m_kPawn.ProjectileOverwriteAim = true;
	}
}

//Before firing projectile, we change the aim to where the projectile will be
function RecoilFromFiringProjectile(int Index)
{
	//Hit location and hit location modifying vectors
	local Vector SourceLocation;
	local Vector AimLocation;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	
	AbilityState = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID( AbilityContextAbilityRefID ) );
	AbilityTemplate = AbilityState.GetMyTemplate( );

	SetupAim( Index, AbilityState, AbilityTemplate, SourceLocation, AimLocation);

	//change the source unit aiming location based on where the shot is getting Chang You Wong 2015-6-9
	XComUnitPawn( SourceWeapon.m_kPawn ).TargetLoc = AimLocation;
	SourceWeapon.m_kPawn.ProjectileOverwriteAim = true;
}

//Finds how far into the path we already are, due to animation carrying us through its beginning.
function float FindPathStartTime(int Index, vector vLoc)
{
	local int i;
	local float PathPointDist;
	local float BestDist;
	local float BestTime;
	local XComPrecomputedPath Path;

	Path = Projectiles[Index].GrenadePath;
	if (Path == None)
		return 0.0f;

	BestDist = VSizeSq(Path.akKeyframes[0].vLoc - vLoc);
	BestTime = Path.akKeyframes[0].fTime;

	for (i = 1; i < Path.iNumKeyframes; i++)
	{
		PathPointDist = VSizeSq(Path.akKeyframes[i].vLoc - vLoc);
		if (PathPointDist < BestDist)
		{
			BestDist = PathPointDist;
			BestTime = Path.akKeyframes[i].fTime;
		}
		else if (PathPointDist > BestDist + 10.0f) //We should be getting closer and closer to the actual grenade release position - if we're getting worse, we already passed the right answer.
			break;
	}

	return BestTime;
}

//A projectile instance's time has come - create the particle effect and start updating it in Tick
function FireProjectileInstance(int Index)
{		
	//Hit location and hit location modifying vectors
	local Vector SourceLocation;
	local Vector HitLocation;
	local Vector HitNormal;
	local Vector AimLocation;
	local Vector TravelDirection;
	local Vector TravelDirection2D;
	local float DistanceTravelled;	
	local Vector ParticleParameterDistance;
	local Vector ParticleParameterTravelledDistance;
	local Vector ParticleParameterTrailDistance;
	local EmitterInstanceParameterSet EmitterParameterSet; //The parameter set to use for the projectile
	local float SpreadScale;
	local Vector SpreadValues;
	local XGUnit TargetVisualizer;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local bool bAllowSpread;
	local array<ProjectileTouchEvent> OutTouchEvents;
	local float HorizontalSpread, VerticalSpread, SpreadLerp;
	local XKeyframe LastGrenadeFrame, LastGrenadeFrame2;
	local Vector GrenadeImpactDirection;
	local TraceHitInfo GrenadeTraceInfo;
	local XComGameState_Unit ShooterState;

	local SkeletalMeshActorSpawnable CreateSkeletalMeshActor;
	local XComAnimNodeBlendDynamic tmpNode;
	local CustomAnimParams AnimParams;
	local AnimSequence FoundAnimSeq;
	local AnimNodeSequence PlayingSequence;

	local float TravelDistance, SpeedAdjustedDistance;
	local float TimeToTravel, TrailAdjustmentTimeToTravel;
	local bool bDebugImpactEvents;
	local bool bCollideWithUnits;

	// Variables for Issue #10
	local XComLWTuple Tuple;

	//local ParticleSystem AxisSystem;
	//local ParticleSystemComponent PSComponent;

	ShooterState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( SourceAbility.InputContext.SourceObject.ObjectID ) );
	AbilityState = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID( AbilityContextAbilityRefID ) );
	AbilityTemplate = AbilityState.GetMyTemplate( );
	
	SetupAim( Index, AbilityState, AbilityTemplate, SourceLocation, AimLocation);
	bProjectileFired = true;

	//Calculate the travel direction for this projectile
	TravelDirection = AimLocation - SourceLocation;
	TravelDistance = VSize(TravelDirection);
	TravelDirection2D = TravelDirection;
	TravelDirection2D.Z = 0.0f;
	TravelDirection2D = Normal(TravelDirection2D);
	TravelDirection = Normal(TravelDirection);
	
	//If spread values are set, apply them in this block
	bAllowSpread = !Projectiles[Index].ProjectileElement.bTriggerHitReact;

	if(bAllowSpread && Projectiles[Index].ProjectileElement.ApplySpread)
	{
		//If the hit was a critical hit, tighten the spread significantly
		switch (AbilityContextHitResult)
		{
			case eHit_Crit: SpreadScale = Projectiles[Index].ProjectileElement.CriticalHitScale;
				break;
			case eHit_Miss: SpreadScale = Projectiles[Index].ProjectileElement.MissShotScale;
				break;
			default:
				if (AbilityTemplate.bIsASuppressionEffect)
				{
					SpreadScale = Projectiles[Index].ProjectileElement.SuppressionShotScale;
				}
				else
				{
					SpreadScale = 1.0f;
				}
		}

		if (TravelDistance >= Projectiles[Index].ProjectileElement.LongRangeDistance)
		{
			HorizontalSpread = Projectiles[Index].ProjectileElement.LongRangeSpread.HorizontalSpread;
			VerticalSpread = Projectiles[Index].ProjectileElement.LongRangeSpread.VerticalSpread;
		}
		else
		{
			SpreadLerp = TravelDistance / Projectiles[Index].ProjectileElement.LongRangeDistance;

			HorizontalSpread = SpreadLerp * Projectiles[ Index ].ProjectileElement.LongRangeSpread.HorizontalSpread + 
				(1.0f - SpreadLerp) * Projectiles[ Index ].ProjectileElement.ShortRangeSpread.HorizontalSpread;
			VerticalSpread = SpreadLerp * Projectiles[ Index ].ProjectileElement.LongRangeSpread.VerticalSpread + 
				(1.0f - SpreadLerp) * Projectiles[ Index ].ProjectileElement.ShortRangeSpread.VerticalSpread;
		}

		HorizontalSpread *= SpreadScale;
		VerticalSpread *= SpreadScale;

		// convert from full angle spread to half angle spread for the rand computation
		HorizontalSpread /= 2.0f;
		VerticalSpread /= 2.0f;

		// convert from angle measurements to radians
		HorizontalSpread *= DegToRad;
		VerticalSpread *= DegToRad;

		//Apply the spread values - lookup into the precomputed random spread table
		SpreadValues = RandomSpreadValues[ Projectiles[ Index ].VolleyIndex ].SpreadValues[ Projectiles[ Index ].MultipleProjectileIndex ];

		// Randomize the travel direction based on the spread table and scalars
		TravelDirection = VRandCone3( TravelDirection, HorizontalSpread, VerticalSpread, SpreadValues.X, SpreadValues.Y );
	
		//Recalculate aim based on the spread
		AimLocation = SourceLocation + TravelDirection * TravelDistance;
		TravelDirection2D = TravelDirection;
		TravelDirection2D.Z = 0.0f;
		TravelDirection2D = Normal( TravelDirection2D );
	}

	//Build the HitLocation
	bDebugImpactEvents = false;

	if( OrdnanceType != '' )
	{
		if( OrdnanceType == class'X2TargetingMethod_MECMicroMissile'.default.OrdnanceTypeName )
		{
			//only want a new path for every volley shots
			if( Index > 0  && Projectiles[Index].VolleyIndex == Projectiles[Index-1].VolleyIndex )
			{
				Projectiles[Index].GrenadePath = Projectiles[Index-1].GrenadePath;
			}
			else
			{
				Projectiles[Index].GrenadePath = `PRECOMPUTEDPATH_SINGLEPROJECTILE;
			}
		}
		else
		{
			//when firing a single projectile, we can just fall back on the targeting path for now, since it would otherwise require re-calculating the trajectory
			Projectiles[Index].GrenadePath = `PRECOMPUTEDPATH;

			//We don't start at the beginning of the path, especially for underhand throws
			Projectiles[Index].AliveTime = FindPathStartTime(Index, SourceLocation);
		}

		HitNormal = -TravelDirection;
		HitLocation = AimLocation;
	}
	else if ((Projectiles[ Index ].ProjectileElement.ReturnsToSource && (AbilityContextHitResult == eHit_Miss)) ||
			 (Projectiles[ Index ].ProjectileElement.bAttachToTarget && (AbilityContextHitResult != eHit_Miss)))
	{
		// if the projectile comes back, only trace out to the aim location and no further		
		`XWORLD.GenerateProjectileTouchList(ShooterState, SourceLocation, AimLocation, OutTouchEvents, bDebugImpactEvents);

		HitLocation = OutTouchEvents[ OutTouchEvents.Length - 1 ].HitLocation;
		HitNormal = OutTouchEvents[OutTouchEvents.Length - 1].HitNormal;
		Projectiles[ Index ].ImpactInfo = OutTouchEvents[ OutTouchEvents.Length - 1 ].TraceInfo;
	}
	else
	{	
		//We want to allow some of the projectiles to go past the target if they don't hit it, so we set up a trace here that will not collide with the target. That way
		//the event list we generate will include impacts behind the target, but only for traveling type projectiles.
		//ranged types should hit the target so that InitialTargetDistance is the distance to the thing being hit.

		bCollideWithUnits = (Projectiles[Index].ProjectileElement.UseProjectileType != eProjectileType_Traveling);

		ProjectileTrace(HitLocation, HitNormal, SourceLocation, TravelDirection, bCollideWithUnits);
		HitLocation = HitLocation + (TravelDirection * 0.0001f); // move us KINDA_SMALL_NUMBER along the direction to be sure and get all the events we want
		`XWORLD.GenerateProjectileTouchList(ShooterState, SourceLocation, HitLocation, OutTouchEvents, bDebugImpactEvents);
		Projectiles[Index].ImpactInfo = OutTouchEvents[OutTouchEvents.Length - 1].TraceInfo;
	}
	
	//Derive the end time from the travel distance and speed if we are not of the grenade type.
	Projectiles[Index].AdjustedTravelSpeed = Projectiles[Index].ProjectileElement.TravelSpeed;      //  initialize to base travel speed
	DistanceTravelled = VSize(HitLocation - SourceLocation);
	if( Projectiles[Index].GrenadePath == none )
	{
		TimeToTravel = 0;
		TrailAdjustmentTimeToTravel = 0;
		if( Projectiles[Index].ProjectileElement.TravelSpeed != 0 )
		{
			TimeToTravel = (DistanceTravelled / Projectiles[Index].ProjectileElement.TravelSpeed);
			TrailAdjustmentTimeToTravel = (Projectiles[Index].ProjectileElement.MaximumTrailLength / Projectiles[Index].ProjectileElement.TravelSpeed);
			
			//  modify the adjusted travel speed as necessary based on max travel time
			if (Projectiles[Index].ProjectileElement.MaxTravelTime > 0 && Projectiles[Index].ProjectileElement.MaxTravelTime < TimeToTravel)
			{
				//  account for the max distance now so that the travel speed isn't based on going off into the distance much further than it should
				SpeedAdjustedDistance = DistanceTravelled;
				if (Projectiles[Index].ProjectileElement.MaxTravelDistanceParam > 0)
					SpeedAdjustedDistance = min(DistanceTravelled, Projectiles[Index].ProjectileElement.MaxTravelDistanceParam);
				
				TimeToTravel = Projectiles[Index].ProjectileElement.MaxTravelTime;
				Projectiles[Index].AdjustedTravelSpeed = SpeedAdjustedDistance / TimeToTravel;
				TrailAdjustmentTimeToTravel = (Projectiles[Index].ProjectileElement.MaximumTrailLength / Projectiles[Index].AdjustedTravelSpeed);
			}
		}
		Projectiles[Index].EndTime = Projectiles[Index].StartTime + TimeToTravel;
		if (Projectiles[Index].ProjectileElement.MaximumTrailLength > 0.0f)
		{
			Projectiles[Index].TrailAdjustmentTime = TrailAdjustmentTimeToTravel;
		}
		else if (Projectiles[ Index ].ProjectileElement.ReturnsToSource)
		{
			// Spoof a trail time so that the redscreen is generated at an appropriate time
			Projectiles[Index].TrailAdjustmentTime = Projectiles[ Index ].ProjectileElement.TimeOnTarget + 
				(DistanceTravelled / Projectiles[Index].ProjectileElement.ReturnSpeed);
		}
				
		Projectiles[Index].ImpactEvents = OutTouchEvents;
	}
	else
	{
		Projectiles[Index].ImpactEvents = StoredInputContext.ProjectileEvents;
	}
	
	//Mark this projectile as having been fired
	Projectiles[Index].bFired = true;
	Projectiles[Index].bConstantComplete = false;
	Projectiles[Index].LastImpactTime = 0.0f;

	//Set up the initial source & target location
	Projectiles[Index].InitialSourceLocation = SourceLocation;
	Projectiles[Index].InitialTargetLocation = HitLocation;		
	Projectiles[Index].InitialTargetNormal = HitNormal;
	Projectiles[Index].InitialTravelDirection = TravelDirection;	
	Projectiles[Index].InitialTargetDistance = VSize(AimLocation - Projectiles[Index].InitialSourceLocation);

	TargetVisualizer = XGUnit( `XCOMHISTORY.GetVisualizer( AbilityContextPrimaryTargetID ) );
	if (TargetVisualizer != none)
	{
		Projectiles[Index].VisualizerToTargetOffset = Projectiles[Index].InitialTargetLocation - TargetVisualizer.Location;
	}

	//Create an actor that travels through space using the settings given by the projectile element definition
	if( Projectiles[Index].ProjectileElement.AttachSkeletalMesh == none )
	{
		Projectiles[Index].SourceAttachActor = Spawn(class'DynamicPointInSpace', self, , Projectiles[Index].InitialSourceLocation, rotator(Projectiles[Index].InitialTravelDirection));	
		Projectiles[Index].TargetAttachActor = Spawn(class'DynamicPointInSpace', self, , Projectiles[Index].InitialSourceLocation, rotator(Projectiles[Index].InitialTravelDirection));

		CreateProjectileCollision(Projectiles[Index].TargetAttachActor);
	}
	else
	{
		Projectiles[Index].SourceAttachActor = Spawn(class'DynamicPointInSpace', self, , Projectiles[Index].InitialSourceLocation, rotator(Projectiles[Index].InitialTravelDirection));


		CreateSkeletalMeshActor = Spawn(class'SkeletalMeshActorSpawnable', self, , Projectiles[Index].InitialSourceLocation, rotator(Projectiles[Index].InitialTravelDirection));
		Projectiles[Index].TargetAttachActor = CreateSkeletalMeshActor;
		CreateSkeletalMeshActor.SkeletalMeshComponent.SetSkeletalMesh(Projectiles[Index].ProjectileElement.AttachSkeletalMesh);
		if (Projectiles[Index].ProjectileElement.CopyWeaponAppearance && SourceWeapon.m_kGameWeapon != none)
		{
			SourceWeapon.m_kGameWeapon.DecorateWeaponMesh(CreateSkeletalMeshActor.SkeletalMeshComponent);
		}
		CreateSkeletalMeshActor.SkeletalMeshComponent.SetAnimTreeTemplate(Projectiles[Index].ProjectileElement.AttachAnimTree);
		CreateSkeletalMeshActor.SkeletalMeshComponent.AnimSets.AddItem(Projectiles[Index].ProjectileElement.AttachAnimSet);
		CreateSkeletalMeshActor.SkeletalMeshComponent.UpdateAnimations();

		CreateProjectileCollision(Projectiles[Index].TargetAttachActor);

		// literally, the only thing that sets this variable is AbilityGrenade - Josh
		if (AbilityState.GetMyTemplate().bHideWeaponDuringFire)
			SourceWeapon.Mesh.SetHidden(true);

		tmpNode = XComAnimNodeBlendDynamic(CreateSkeletalMeshActor.SkeletalMeshComponent.Animations.FindAnimNode('BlendDynamic'));
		if (tmpNode != none)
		{
			AnimParams.AnimName = 'NO_Idle';
			AnimParams.Looping = true;
			tmpNode.PlayDynamicAnim(AnimParams);
		}
	}

	// handy debugging helper, just uncomment this and the declarations at the top
//	AxisSystem = ParticleSystem( DynamicLoadObject( "FX_Dev_Steve_Utilities.P_Axis_Display", class'ParticleSystem' ) );
//	PSComponent = new(Projectiles[Index].TargetAttachActor) class'ParticleSystemComponent';
//	PSComponent.SetTemplate(AxisSystem);
//	PSComponent.SetAbsolute( false, false, false );
//	PSComponent.SetTickGroup( TG_EffectsUpdateWork );
//	PSComponent.SetActive( true );
//	Projectiles[Index].TargetAttachActor.AttachComponent( PSComponent );

	if( Projectiles[Index].GrenadePath != none )
	{
		Projectiles[Index].GrenadePath.bUseOverrideSourceLocation = true;
		Projectiles[Index].GrenadePath.OverrideSourceLocation = Projectiles[Index].InitialSourceLocation;

		Projectiles[Index].GrenadePath.bUseOverrideTargetLocation = true;
		Projectiles[Index].GrenadePath.OverrideTargetLocation = Projectiles[Index].InitialTargetLocation;
		
		if( OrdnanceType == class'X2TargetingMethod_BlasterLauncher'.default.OrdnanceTypeName )
		{
			Projectiles[Index].GrenadePath.CalculateBlasterBombTrajectoryToTarget();
		}
		else
		{
			if( OrdnanceType == class'X2TargetingMethod_MECMicroMissile'.default.OrdnanceTypeName )
			{
				//initialize it if is not already initialized
				if( ! ( Index > 0  && Projectiles[Index].VolleyIndex == Projectiles[Index-1].VolleyIndex ) )
				{
					Projectiles[Index].GrenadePath.bNoSpinUntilBounce = true;
					Projectiles[Index].GrenadePath.SetupPath(SourceWeapon, TargetVisualizer.GetTeam(), WeaponTemplate.WeaponPrecomputedPathData);
					SpreadValues = RandomSpreadValues[ Projectiles[ Index ].VolleyIndex ].SpreadValues[ Projectiles[ Index ].MultipleProjectileIndex ];
					SpreadValues.x = (SpreadValues.x- 0.5f) * 2.0f;
					SpreadValues.y = (SpreadValues.y- 0.5f) * 2.0f;
					SpreadValues.z = 0.0f;
					Projectiles[Index].GrenadePath.OverrideTargetLocation += SpreadValues * Projectiles[Index].ProjectileElement.MicroMissileAdditionalRandomOffset;
					Projectiles[Index].GrenadePath.OverrideTargetLocation += Projectiles[Index].ProjectileElement.MicroMissileOffset[Projectiles[Index].VolleyIndex];
					//this is used for playing effects, so we update it
					Projectiles[Index].GrenadePath.SetFiringFromSocketPosition(name("gun_fire"));
					Projectiles[Index].GrenadePath.UpdateTrajectory();
					Projectiles[Index].InitialTargetLocation = Projectiles[Index].GrenadePath.akKeyframes[Projectiles[Index].GrenadePath.iNumKeyframes-1].vLoc;
					FireAction.allHitLocations.AddItem(Projectiles[Index].InitialTargetLocation);
					//micro missile has this scalar speed that alters its real end time, so we need to change this accordingly
					Projectiles[Index].EndTime = Projectiles[Index].StartTime + Projectiles[Index].GrenadePath.GetEndTime() / Projectiles[Index].ProjectileElement.TravelSpeed;
				}
				else //copy it from the previous element
				{
					Projectiles[Index].InitialTargetLocation = Projectiles[Index-1].InitialTargetLocation;
					Projectiles[Index].EndTime = Projectiles[Index-1].EndTime;
				}
			}
			//Normal grenades don't need their trajectory updated here
		}

		Projectiles[Index].GrenadePath.bUseOverrideTargetLocation = false;
		Projectiles[Index].GrenadePath.bUseOverrideSourceLocation = false;
		if( OrdnanceType != class'X2TargetingMethod_MECMicroMissile'.default.OrdnanceTypeName)
		{
			Projectiles[Index].EndTime = Projectiles[Index].StartTime + Projectiles[Index].GrenadePath.GetEndTime();
		}

		if (Projectiles[ Index ].GrenadePath.iNumKeyframes > 1)
		{
			// get the rough direction of travel at the end of the path.  TravelDirection is from the source to the target
			LastGrenadeFrame = Projectiles[ Index ].GrenadePath.ExtractInterpolatedKeyframe( Projectiles[ Index ].GrenadePath.GetEndTime( ) );
			LastGrenadeFrame2 = Projectiles[ Index ].GrenadePath.ExtractInterpolatedKeyframe( Projectiles[ Index ].GrenadePath.GetEndTime( ) - 0.05f );
			if (VSize( LastGrenadeFrame.vLoc - LastGrenadeFrame2.vLoc ) == 0)
			{
				`redscreen("Grenade path with EndTime and EndTime-.05 with the same point. ~RussellA");
			}

			GrenadeImpactDirection = Normal( LastGrenadeFrame.vLoc - LastGrenadeFrame2.vLoc );

			// don't use the projectile trace, because we don't want the usual minimal arming distance and other features of that trace.
			// really just trying to get the actual surface normal at the point of impact.  HitLocation and AimLocation should basically be the same.
			Trace( HitLocation, HitNormal, AimLocation + GrenadeImpactDirection * 5, AimLocation - GrenadeImpactDirection * 5, true, vect( 0, 0, 0 ), GrenadeTraceInfo );
			Projectiles[Index].ImpactInfo = GrenadeTraceInfo;
		}
		else
		{
			// Not enough keyframes to figure out a direction of travel... a straight up vector as a normal should be a reasonable fallback...
			HitNormal.X = 0.0f;
			HitNormal.Y = 0.0f;
			HitNormal.Z = 1.0f;
		}

		Projectiles[ Index ].InitialTargetNormal = HitNormal;
	}


	Projectiles[ Index ].SourceAttachActor.SetPhysics( PHYS_Projectile );
	Projectiles[ Index ].TargetAttachActor.SetPhysics( PHYS_Projectile );

	switch( Projectiles[Index].ProjectileElement.UseProjectileType )
	{
	case eProjectileType_Traveling:
		if( Projectiles[Index].GrenadePath == none ) //If there is a grenade path, we move along that
		{
			Projectiles[Index].TargetAttachActor.Velocity = Projectiles[Index].InitialTravelDirection * Projectiles[Index].AdjustedTravelSpeed;
		}
		break;
	case eProjectileType_Ranged:
	case eProjectileType_RangedConstant:
		Projectiles[Index].SourceAttachActor.Velocity = vect(0, 0, 0);
		Projectiles[Index].TargetAttachActor.Velocity = Projectiles[Index].InitialTravelDirection * Projectiles[Index].AdjustedTravelSpeed;
		break;
	}

	if( Projectiles[Index].ProjectileElement.UseParticleSystem != none )
	{
		EmitterParameterSet = Projectiles[Index].ProjectileElement.DefaultParticleSystemInstanceParameterSet;
		if( bWasHit && Projectiles[Index].ProjectileElement.bPlayOnHit && Projectiles[Index].ProjectileElement.PlayOnHitOverrideInstanceParameterSet != none )
		{
			EmitterParameterSet = Projectiles[Index].ProjectileElement.PlayOnHitOverrideInstanceParameterSet;
		}
		else if( !bWasHit && Projectiles[Index].ProjectileElement.bPlayOnMiss && Projectiles[Index].ProjectileElement.PlayOnMissOverrideInstanceParameterSet != none )
		{
			EmitterParameterSet = Projectiles[Index].ProjectileElement.PlayOnMissOverrideInstanceParameterSet;
		}

		//Spawn the effect
		switch(Projectiles[Index].ProjectileElement.UseProjectileType)
		{
		case eProjectileType_Traveling:
			//For this style of projectile, the effect is attached to the moving point in space
			if( EmitterParameterSet != none )
			{
				Projectiles[Index].ParticleEffectComponent = WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.UseParticleSystem, 
					Projectiles[Index].InitialSourceLocation, 
					rotator(TravelDirection),
					Projectiles[Index].TargetAttachActor,,,,
					EmitterParameterSet.InstanceParameters);
			}
			else
			{
				Projectiles[Index].ParticleEffectComponent = 
					WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.UseParticleSystem, 
					Projectiles[Index].InitialSourceLocation, 
					rotator(TravelDirection),
					Projectiles[Index].TargetAttachActor);
			}
			break;
		case eProjectileType_Ranged:
		case eProjectileType_RangedConstant:
			//For this style of projectile, the point in space is motionless
			if( EmitterParameterSet != none )
			{
				Projectiles[Index].ParticleEffectComponent = WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.UseParticleSystem, 
					Projectiles[Index].InitialSourceLocation, 
					rotator(TravelDirection),
					Projectiles[Index].SourceAttachActor,,,,
					EmitterParameterSet.InstanceParameters);
			}
			else
			{
				Projectiles[Index].ParticleEffectComponent = WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.UseParticleSystem, 
					Projectiles[Index].InitialSourceLocation, 
					rotator(TravelDirection),
					Projectiles[Index].SourceAttachActor);
			}
			break;
		}

		Projectiles[Index].ParticleEffectComponent.SetScale( Projectiles[Index].ProjectileElement.ParticleScale );
		Projectiles[Index].ParticleEffectComponent.OnSystemFinished = OnParticleSystemFinished;

		DistanceTravelled = Min( DistanceTravelled, Projectiles[ Index ].ProjectileElement.MaxTravelDistanceParam );
		//Tells the particle system how far the projectile must travel to reach its target
		ParticleParameterDistance.X = DistanceTravelled;
		ParticleParameterDistance.Y = DistanceTravelled;
		ParticleParameterDistance.Z = DistanceTravelled;
		Projectiles[Index].ParticleEffectComponent.SetVectorParameter('Target_Distance', ParticleParameterDistance);
		Projectiles[Index].ParticleEffectComponent.SetFloatParameter('Target_Distance', DistanceTravelled);

		ParticleParameterDistance.X = DistanceTravelled;
		ParticleParameterDistance.Y = DistanceTravelled;
		ParticleParameterDistance.Z = DistanceTravelled;
		Projectiles[ Index ].ParticleEffectComponent.SetVectorParameter( 'Initial_Target_Distance', ParticleParameterDistance );
		Projectiles[ Index ].ParticleEffectComponent.SetFloatParameter( 'Initial_Target_Distance', DistanceTravelled );

		//Tells the particle system how far we have moved
		ParticleParameterTravelledDistance.X = 0.0f;
		ParticleParameterTravelledDistance.Y = 0.0f;
		ParticleParameterTravelledDistance.Z = 0.0f;
		Projectiles[Index].ParticleEffectComponent.SetVectorParameter('Traveled_Distance', ParticleParameterTravelledDistance);
		Projectiles[Index].ParticleEffectComponent.SetFloatParameter('Traveled_Distance', 0.0f);

		if( Projectiles[Index].ProjectileElement.MaximumTrailLength > 0.0f )
		{
			ParticleParameterTrailDistance.X = 0.0f;
			ParticleParameterTrailDistance.Y = 0.0f;
			ParticleParameterTrailDistance.Z = 0.0f;
			Projectiles[Index].ParticleEffectComponent.SetVectorParameter('Trail_Distance', ParticleParameterTrailDistance);
			Projectiles[Index].ParticleEffectComponent.SetFloatParameter('Trail_Distance', 0.0f);
		}
	}

	`log("********************* PROJECTILE Element #"@self.Name@Index@"FIRED *********************************", , 'DevDestruction');
	`log("StartTime:"@Projectiles[Index].StartTime, , 'DevDestruction');
	`log("EndTime:"@Projectiles[Index].EndTime, , 'DevDestruction');
	`log("InitialSourceLocation:"@Projectiles[Index].InitialSourceLocation, , 'DevDestruction');
	`log("InitialTargetLocation:"@Projectiles[Index].InitialTargetLocation, , 'DevDestruction');
	`log("InitialTravelDirection:"@Projectiles[Index].InitialTravelDirection, , 'DevDestruction');
	`log("Projectile actor location is "@Projectiles[Index].SourceAttachActor.Location, , 'DevDestruction');
	`log("Projectile actor velocity is set to:"@Projectiles[Index].TargetAttachActor.Velocity, , 'DevDestruction');
	`log("******************************************************************************************", , 'DevDestruction');

	if( Projectiles[Index].ProjectileElement.bPlayWeaponAnim )
	{
		AnimParams.AnimName = 'FF_FireA';
		AnimParams.Looping = false;
		AnimParams.Additive = true;

		FoundAnimSeq = SkeletalMeshComponent(SourceWeapon.Mesh).FindAnimSequence(AnimParams.AnimName);
		if( FoundAnimSeq != None )
		{
			//Tell our weapon to play its fire animation
			if( SourceWeapon.AdditiveDynamicNode != None )
			{
				PlayingSequence = SourceWeapon.AdditiveDynamicNode.PlayDynamicAnim(AnimParams);
				PlayingSequences.AddItem(PlayingSequence);
				SetTimer(PlayingSequence.AnimSeq.SequenceLength, false, nameof(BlendOutAdditives), self);
			}
			
		}
	}

	if( Projectiles[Index].ProjectileElement.FireSound != none )
	{
		//Play a fire sound if specified
		// Start Issue #10 Trigger an event that allows to override the default projectile sound
		Tuple = new class'XComLWTuple';
		Tuple.Id = 'ProjectilSoundOverride';
		Tuple.Data.Add(3);

		// The SoundCue to play instead of the AKEvent, used as reference
		Tuple.Data[0].kind = XComLWTVObject;
		Tuple.Data[0].o = none;

		// Projectile Element ObjectArchetype Pathname Parameter
		Tuple.Data[1].kind = XComLWTVString;
		Tuple.Data[1].s = PathName(Projectiles[Index].ProjectileElement.ObjectArchetype);

		// Ability Context Ref Parameter
		Tuple.Data[2].kind = XComLWTVInt;
		Tuple.Data[2].i = AbilityContextAbilityRefID;

		`XEVENTMGR.TriggerEvent('OnProjectileFireSound', Tuple, Projectiles[Index].ProjectileElement, none);
		if (Tuple.Data[0].o != none)
		{
			Projectiles[Index].SourceAttachActor.PlaySound(SoundCue(Tuple.Data[0].o));
		}
		else
		{
			Projectiles[Index].SourceAttachActor.PlayAkEvent(Projectiles[Index].ProjectileElement.FireSound);
		}
		// End Issue #10
	}
}

// Issue #720, #1076: switching this from foreach to for loop.
// Since a foreach loop creates a copy (and ProjectileElementInstance is a struct)
// the `ParticleEffectComponent = none` assignment was being "lost".
// In vanilla game this made no difference, since the PSCs were never returned
// to the pool, but with the #720 fixes, it can be disasterous: we return
// the PSC to the pool here, then it's used for something else and then we
// (the rest of X2UP) manipulate the transform/parameters of the PSC and/or
// return it again, causing visual issues (or outright killing) the other effect
// that is now using the PSC
function OnParticleSystemFinished(ParticleSystemComponent PSystem)
{
	//local ProjectileElementInstance Element;
	local int i;

	//foreach Projectiles(Element)
	for (i = 0; i < Projectiles.Length; i++)
	{
		//if (Element.ParticleEffectComponent == PSystem)
		if (Projectiles[i].ParticleEffectComponent == PSystem)
		{
			// Start Issue #720
			/// HL-Docs: ref:ProjectilePerformanceDrain
			// Allow the pool to reuse this Particle System's spot in the pool.
			//WorldInfo.MyEmitterPool.OnParticleSystemFinished(Element.ParticleEffectComponent);
			WorldInfo.MyEmitterPool.OnParticleSystemFinished(Projectiles[i].ParticleEffectComponent);
			CancelDelayedReturnToPoolPSC(Projectiles[i].ParticleEffectComponent);
			// End Issue #720

			//Element.ParticleEffectComponent = none;
			Projectiles[i].ParticleEffectComponent = none;
			return;
		}
	}
}

function BlendOutAdditives()
{
	local CustomAnimParams AnimParams;
	local AnimNodeSequence RemoveSequence;
	local int scan;

	// Jwats: remove all the additives we started!
	for( scan = 0; scan < PlayingSequences.Length; ++scan )
	{
		RemoveSequence = PlayingSequences[scan];
		SourceWeapon.AdditiveDynamicNode.BlendOutDynamicAnim(RemoveSequence, AnimParams.BlendTime);
	}
	
	PlayingSequences.Length = 0;
}

function MaybeUpdateContinuousRange(int Index)
{
	local float TargetDistance;
	local float TravelDistance;
	local float DistanceDiff;
	local bool WaitingToDie;
	local Vector ParticleParameterDistance;

	if (!Projectiles[ Index ].ProjectileElement.bContinuousDistanceUpdates || (Projectiles[Index].GrenadePath != none))
	{
		// should we even bother?
		return;
	}
	if (Projectiles[ Index ].ProjectileElement.bAttachToTarget)
	{
		// attach to target already provides range recalculations
		return;
	}

	WaitingToDie = Projectiles[ Index ].bWaitingToDie;
	Projectiles[ Index ].ParticleEffectComponent.GetFloatParameter( 'Target_Distance', TargetDistance );
	Projectiles[ Index ].ParticleEffectComponent.GetFloatParameter( 'Traveled_Distance', TravelDistance );

	if (TargetDistance > TravelDistance)
	{
		DistanceDiff = TargetDistance - TravelDistance;

		if (WaitingToDie)
		{
			Projectiles[ Index ].bWaitingToDie = false;
			Projectiles[ Index ].StartTime = WorldInfo.TimeSeconds;
			Projectiles[ Index ].EndTime = Projectiles[ Index ].StartTime + (DistanceDiff / Projectiles[ Index ].AdjustedTravelSpeed);

			Projectiles[ Index ].TargetAttachActor.SetPhysics( PHYS_Projectile );
			Projectiles[ Index ].TargetAttachActor.Velocity = vector(Projectiles[ Index ].SourceAttachActor.Rotation) * Projectiles[ Index ].AdjustedTravelSpeed;
		}
		else
		{
			Projectiles[ Index ].EndTime = Projectiles[ Index ].StartTime + (TargetDistance / Projectiles[ Index ].AdjustedTravelSpeed);
		}
	}
	else if (TargetDistance < TravelDistance)
	{
		if (WaitingToDie)
		{
			Projectiles[ Index ].TargetAttachActor.SetLocation( Projectiles[ Index ].InitialTargetLocation );
		}
		else
		{
			// Reset the end time so that the next time we process, we end
			Projectiles[ Index ].EndTime = WorldInfo.TimeSeconds;
		}

		TravelDistance = TargetDistance;
		TravelDistance = Min( TravelDistance, Projectiles[ Index ].ProjectileElement.MaxTravelDistanceParam );

		ParticleParameterDistance.X = TravelDistance;
		ParticleParameterDistance.Y = TravelDistance;
		ParticleParameterDistance.Z = TravelDistance;
		Projectiles[ Index ].ParticleEffectComponent.SetVectorParameter( 'Traveled_Distance', ParticleParameterDistance );

		Projectiles[ Index ].ParticleEffectComponent.SetFloatParameter( 'Traveled_Distance', TravelDistance );

		//`log("********************* PROJECTILE Element #"@self.Name@Index@ " *********************************", , 'DevDestruction');
		//`log("MaybeUpdateContinuousRange", , 'DevDestruction' );
		//`log("Updating Traveled_Distance to "@TravelDistance, , 'DevDestruction');
		//`log("************************************************************************************************", , 'DevDestruction');
	}
}

function ProcessReturn(int Index)
{
	local vector ActorDiffNormal, TargetTravelDirection;
	local float DotProduct;

	if (!Projectiles[ Index ].ProjectileElement.ReturnsToSource)
	{
		return; // do we even need to bother?
	}

	if (WorldInfo.TimeSeconds <= Projectiles[Index].EndTime + Projectiles[Index].ProjectileElement.TimeOnTarget)
	{
		// is it too soon to start the return trip
		return;
	}

	ActorDiffNormal = Projectiles[ Index ].TargetAttachActor.Location - Projectiles[Index].SourceAttachActor.Location;
	if (VSizeSq(ActorDiffNormal) < 1.0f) // already reached the destination
	{
		if (Projectiles[ Index ].TargetAttachActor.Physics == PHYS_Projectile) // Landed exactly, miracle
		{
			Projectiles[ Index ].TargetAttachActor.SetPhysics( PHYS_None );
			Projectiles[ Index ].TargetAttachActor.Velocity = vect( 0, 0, 0 );
		}

		return;
	}

	ActorDiffNormal = Normal( ActorDiffNormal );
	TargetTravelDirection = Normal( Projectiles[ Index ].TargetAttachActor.Velocity );
	DotProduct = ActorDiffNormal dot TargetTravelDirection;
	if ((1.0f - DotProduct) < 0.02f) // overshot a bit
	{
		Projectiles[ Index ].TargetAttachActor.SetPhysics( PHYS_None );
		Projectiles[ Index ].TargetAttachActor.Velocity = vect( 0, 0, 0 );
		Projectiles[ Index ].TargetAttachActor.SetLocation( Projectiles[ Index ].SourceAttachActor.Location );

		return;
	}

	if (Projectiles[ Index ].TargetAttachActor.Physics == PHYS_Projectile)
	{
		// already moving backwards
		return;
	}

	Projectiles[ Index ].TargetAttachActor.SetPhysics( PHYS_Projectile );
	Projectiles[ Index ].TargetAttachActor.Velocity = -1 * vector( Projectiles[ Index ].SourceAttachActor.Rotation ) * Projectiles[ Index ].AdjustedTravelSpeed;
}

function MaybeUpdateTargetDistance(int Index)
{
	local Vector ParticleParameterDistance;
	local float TargetDistance;

	local Vector SourceLocation;
	local Rotator SourceRotation;
	local Vector HitLocation;
	local Vector HitNormal;

	if (Projectiles[ Index ].ProjectileElement.bAttachToTarget && Projectiles[ Index ].bWaitingToDie)
	{
		TargetDistance = VSize( Projectiles[ Index ].SourceAttachActor.Location - Projectiles[ Index ].TargetAttachActor.Location );
	}
	else if (Projectiles[ Index ].ProjectileElement.bContinuousDistanceUpdates)
	{
		SourceLocation = Projectiles[ Index ].SourceAttachActor.Location;
		SourceRotation = Projectiles[ Index ].SourceAttachActor.Rotation;

		ProjectileTrace( HitLocation, HitNormal, SourceLocation, Vector( SourceRotation ), true ); //Specify that we should collide with the pawn

		TargetDistance = VSize( HitLocation - SourceLocation );
		Projectiles[ Index ].InitialTargetLocation = HitLocation;
	}
	else if (Projectiles[ Index ].ProjectileElement.bAttachToSource)
	{
		TargetDistance = VSize( Projectiles[ Index ].SourceAttachActor.Location - Projectiles[ Index ].InitialTargetLocation );
	}
	else
	{
		return;
	}

	TargetDistance = Min( TargetDistance, Projectiles[ Index ].ProjectileElement.MaxTravelDistanceParam );

	ParticleParameterDistance.X = TargetDistance;
	ParticleParameterDistance.Y = TargetDistance;
	ParticleParameterDistance.Z = TargetDistance;
	Projectiles[ Index ].ParticleEffectComponent.SetVectorParameter( 'Target_Distance', ParticleParameterDistance );
	Projectiles[ Index ].ParticleEffectComponent.SetFloatParameter( 'Target_Distance', TargetDistance );
}

function UpdateProjectileDistances(int Index, float fDeltaT)
{
	local Vector SourceLocation;
	local Rotator MuzzleRotation;
	local XGUnit TargetVisualizer;
	local int UpdateType;
	local Vector Direction;
	local float TravelledDistance;
	local Vector ParticleParameterTravelledDistance;
	local float GrenadeTimeAtMiddlePoint;

	if (Projectiles[ Index ].ProjectileElement.bAttachToSource)
	{
		//Get the source and target locations
		if(!bCosmetic)
		{
			SkeletalMeshComponent(SourceWeapon.Mesh).GetSocketWorldLocationAndRotation(Projectiles[Index].ProjectileElement.MuzzleSocketName, SourceLocation, MuzzleRotation);
		}
		else
		{
			if( CosmeticSource != none )
			{
				SourceLocation = CosmeticSource.Location;
				MuzzleRotation = CosmeticSource.Rotation;
			}
			else
			{
				SourceLocation = CosmeticSourceLocation;
				MuzzleRotation = Rotator(Normal(CosmeticTargetLocation - CosmeticSourceLocation));
			}
		}

		Projectiles[ Index ].SourceAttachActor.SetLocation( SourceLocation );

		if (Projectiles[ Index ].ProjectileElement.bLockOrientationToMuzzle)
		{
			Projectiles[ Index ].SourceAttachActor.SetRotation( MuzzleRotation );
		}
	}

	if (Projectiles[ Index ].bWaitingToDie && Projectiles[ Index ].ProjectileElement.bAttachToTarget && (AbilityContextHitResult != eHit_Miss))
	{
		TargetVisualizer = XGUnit( `XCOMHISTORY.GetVisualizer( AbilityContextPrimaryTargetID ) );
		if (TargetVisualizer != none)
		{
			// if we're not attached to a socket or getting that socket from the mesh failed, fallback on math
			if (Projectiles[ Index ].ProjectileElement.TargetAttachSocket == '' ||
				!TargetVisualizer.GetPawn( ).Mesh.GetSocketWorldLocationAndRotation( Projectiles[ Index ].ProjectileElement.TargetAttachSocket, SourceLocation, MuzzleRotation ))
			{
				SourceLocation = TargetVisualizer.Location + Projectiles[ Index ].VisualizerToTargetOffset;
			}

			Projectiles[ Index ].TargetAttachActor.SetLocation( SourceLocation );
		}
	}

	if (Projectiles[ Index ].ProjectileElement.UseProjectileType != eProjectileType_Traveling)
	{
		UpdateType = int( Projectiles[ Index ].ProjectileElement.bAttachToSource ) | (int( Projectiles[ Index ].ProjectileElement.bAttachToTarget ) << 1);
	}

	switch (UpdateType)
	{
		// no attachment
		case 0:
			if (Projectiles[Index].GrenadePath != none)
			{
				TravelledDistance = Projectiles[ Index ].AliveTime * Projectiles[ Index ].AdjustedTravelSpeed;

				//Grenade_Path_Fix Chang You 5-11-2015
				GrenadeTimeAtMiddlePoint = Projectiles[Index].GrenadePath.GetEndTime() * 0.5f;
				//to match the velocity of the hand throw, we start off the grenade at 2x it's speed, and linearly slows it down until 1/2 into it's path
				if (Projectiles[Index].AliveTime < GrenadeTimeAtMiddlePoint)
				{
					//2x the speed at the start, slows down later on
					Projectiles[Index].AliveTime += Lerp(0.0f, fDeltaT, (GrenadeTimeAtMiddlePoint - Projectiles[Index].AliveTime) / GrenadeTimeAtMiddlePoint);
				}
				Projectiles[Index].GrenadePath.MoveAlongPath( Projectiles[ Index ].AliveTime, Projectiles[ Index ].TargetAttachActor );
			}
			else
			{
				// update projectile travel distances based on actual actor travel, and not math (because the impact probably won't be on an even frame boundry)
				TravelledDistance = VSize( Projectiles[ Index ].TargetAttachActor.Location - Projectiles[ Index ].SourceAttachActor.Location );
			}
			break;			

			// Source
		case 1: TravelledDistance = VSize( Projectiles[ Index ].TargetAttachActor.Location - Projectiles[ Index ].SourceAttachActor.Location );
			break;

			// Target or Source + Target
		case 2:
		case 3:
			Direction = Projectiles[ Index ].TargetAttachActor.Location - Projectiles[ Index ].SourceAttachActor.Location;
			TravelledDistance = VSize( Direction );
			Projectiles[ Index ].SourceAttachActor.SetRotation( rotator( Normal( Direction ) ) );
			break;
	}

	TravelledDistance = Min( TravelledDistance, Projectiles[Index].ProjectileElement.MaxTravelDistanceParam );
	if (Projectiles[ Index ].ParticleEffectComponent != none)
	{
		//Update the ranged projectile parameters
		ParticleParameterTravelledDistance.X = TravelledDistance;
		ParticleParameterTravelledDistance.Y = TravelledDistance;
		ParticleParameterTravelledDistance.Z = TravelledDistance;
		Projectiles[ Index ].ParticleEffectComponent.SetVectorParameter( 'Traveled_Distance', ParticleParameterTravelledDistance );
		Projectiles[ Index ].ParticleEffectComponent.SetFloatParameter( 'Traveled_Distance', TravelledDistance );

		//`log("********************* PROJECTILE Element #"@self.Name@Index@ " *********************************", , 'DevDestruction');
		//`log("UpdateProjectileDistances", , 'DevDestruction' );
		//`log("Updating Traveled_Distance to "@TravelledDistance, , 'DevDestruction');
		//`log("************************************************************************************************", , 'DevDestruction');

		MaybeUpdateTargetDistance( Index );

		MaybeUpdateContinuousRange( Index );
	}
}

function UpdateProjectileTrail(int Index)
{
	//Set based on whether the trail distance is shrinking or growing
	local float SquashOrStretch;
	local Vector ParticleVectorParameter;

	local float TimeSinceLaunch;
	local float TimeSinceImpact;
	local float ScaleFactor;
	local float TrailSize;

	local float MaximumTrailLength;
	local float TrailAdjustmentTime;

	MaximumTrailLength = Projectiles[ Index ].ProjectileElement.MaximumTrailLength;
	TrailAdjustmentTime = Projectiles[ Index ].TrailAdjustmentTime;

	if ((Projectiles[ Index ].ParticleEffectComponent == none) || (MaximumTrailLength == 0.0f))
	{
		return;
	}

	//Set the trail parameter if there is a trail length
	ScaleFactor = 1.0f;
	SquashOrStretch = 0.5f;

	//Measure time since the projectile launched and adjust the trail length accordingly
	TimeSinceLaunch = WorldInfo.TimeSeconds - Projectiles[ Index ].StartTime;
	if (TimeSinceLaunch < TrailAdjustmentTime)
	{
		ScaleFactor = FMin( TimeSinceLaunch / TrailAdjustmentTime, 1.0f );
		SquashOrStretch = 1.0f; //Indicate stretching
	}

	//Measure time since the projectile impacted and adjust the trail length accordingly
	TimeSinceImpact = WorldInfo.TimeSeconds - (Projectiles[ Index ].EndTime);
	if (TimeSinceImpact > 0.0f && TimeSinceImpact < TrailAdjustmentTime)
	{
		ScaleFactor = 1.0f - FMin( TimeSinceImpact / TrailAdjustmentTime, 1.0f );

		SquashOrStretch = 0.0f; //Indicate squashing
	}

	TrailSize = ScaleFactor * Projectiles[ Index ].ProjectileElement.MaximumTrailLength;

	ParticleVectorParameter.X = TrailSize;
	ParticleVectorParameter.Y = TrailSize;
	ParticleVectorParameter.Z = TrailSize;
	Projectiles[ Index ].ParticleEffectComponent.SetVectorParameter( 'Trail_Distance', ParticleVectorParameter );
	Projectiles[ Index ].ParticleEffectComponent.SetFloatParameter( 'Trail_Distance', TrailSize );

	ParticleVectorParameter.X = SquashOrStretch;
	ParticleVectorParameter.Y = SquashOrStretch;
	ParticleVectorParameter.Z = SquashOrStretch;
	Projectiles[ Index ].ParticleEffectComponent.SetVectorParameter( 'Squash_or_Stretch', ParticleVectorParameter );
	Projectiles[ Index ].ParticleEffectComponent.SetFloatParameter( 'Squash_or_Stretch', SquashOrStretch );
}

function bool StruckTarget(int Index, float fDeltaT)
{
	local XGUnit TargetVisualizer;
	local TraceHitInfo HitInfo;
	local Vector HitLocation;
	local Vector HitNormal;	
	local Vector TraceStart;
	local float DistanceTraveled;	
	local bool bTraveledToTarget;
	local bool bHit;
	local bool bForceHit; //If this projectile is responsible for triggering the hit reaction, guarantee a hit

	if (!Projectiles[Index].bWaitingToDie && AbilityContextHitResult != eHit_Miss && Projectiles[Index].GrenadePath == none)
	{
		if (SourceWeapon != none)
		{
			HitLocation = XComUnitPawn(SourceWeapon.m_kPawn).TargetLoc;
		}

		TargetVisualizer = XGUnit(`XCOMHISTORY.GetVisualizer(AbilityContextPrimaryTargetID));
		if(TargetVisualizer != none || (bCosmetic && !bCosmeticShouldHitTarget))
 		{
			// determine travel distance based on actual actor positions
			DistanceTraveled = VSize(Projectiles[ Index ].TargetAttachActor.Location - Projectiles[ Index ].SourceAttachActor.Location);

			// start the trace where we were at the beginning of the frame
			TraceStart = Projectiles[ Index ].TargetAttachActor.Location;
			TraceStart -= fDeltaT * Projectiles[ Index ].TargetAttachActor.Velocity;

			ProjectileTrace(HitLocation, HitNormal, TraceStart, Projectiles[Index].InitialTravelDirection, true, HitInfo); //This is the main place that we should check for a collision with the pawn
			bHit = HitInfo.HitComponent != None;

			// check against actual strike distance and not the cached initial strike distance
			bTraveledToTarget = DistanceTraveled >= VSize(HitLocation - Projectiles[ Index ].SourceAttachActor.Location);

			//Fudge the results if this is projectile can trigger a hit reaction
			if(Projectiles[Index].ProjectileElement.bTriggerHitReact)
			{
				bForceHit = bTraveledToTarget;
				if(bForceHit && !bHit)
				{
					HitLocation = Projectiles[Index].TargetAttachActor.Location;
					HitNormal = -Projectiles[Index].InitialTravelDirection;
				}				
			}
		}
 		else if (!bCosmetic && TargetVisualizer == none)
 		{
			// Acid Blob / Poison spit are projectile hits that aren't cosmetic, but only have target locations, not target actors
			// this code blows up the projectile once it has travel to/past its destination.
 			DistanceTraveled = Projectiles[Index].AdjustedTravelSpeed * Projectiles[Index].AliveTime;
			bTraveledToTarget = DistanceTraveled > Projectiles[Index].InitialTargetDistance;

			if (Projectiles[Index].ProjectileElement.bTriggerHitReact)
			{
				bForceHit = bTraveledToTarget;
				if (bForceHit)
				{
					HitLocation = SourceAbility.ResultContext.ProjectileHitLocations[0];
					HitNormal = -Projectiles[Index].InitialTravelDirection;
				}
			}
 		}

		if (bForceHit || ((TargetVisualizer == none || (bHit && HitInfo.HitComponent.Owner == TargetVisualizer.GetPawn())) && bTraveledToTarget))
		{
			Projectiles[Index].bStruckTarget = true;
			Projectiles[Index].EndTime = WorldInfo.TimeSeconds;
			Projectiles[Index].InitialTargetLocation = HitLocation;
			Projectiles[Index].InitialTargetNormal = HitNormal;

			return true;
		}
	}

	return false;
}

function DoTransitImpact(int Index, float fDeltaT)
{
	local XComProjectileImpactActor Impact;
	local ProjectileTouchEvent ProcessImpact;
	local Rotator DeathFXRotation;		
	local bool bMultiImpact;
	local int ImpactIndex;
	local float TraveledDistance;
	local bool bDoneProcessing;
	local bool bTriggerImpact;


	local XComProjectileImpactActor ImpactActor;
	local ParticleSystem ImpactEffects;
	local EmitterInstanceParameterSet EffectParams;

			
	bMultiImpact = (Projectiles[Index].ProjectileElement.bContinuousDistanceUpdates && (Projectiles[Index].ProjectileElement.MinImpactInterval > 0));
	if(bMultiImpact)
	{
		//If this is a continuous projectile / beam process all ImpactEvents
		for(ImpactIndex = 0; ImpactIndex < Projectiles[Index].ImpactEvents.Length; ++ImpactIndex)
		{
			ProcessImpact = Projectiles[Index].ImpactEvents[ImpactIndex];

			if((ProcessImpact.HitNormal.X == 0.0f && ProcessImpact.HitNormal.Y == 0.0f && ProcessImpact.HitNormal.Z == 0.0f) ||
			    ProcessImpact.TraceInfo.HitComponent != none && ProcessImpact.TraceInfo.HitComponent.Owner.IsA('XComUnitPawn')) //No transit impacts through pawns. They are either the target or not hit
			{
				continue;
			}

			if(ProcessImpact.bEntry)
			{
				if(FireAction != none)
				{
					FireAction.ProjectileNotifyHit(false, ProcessImpact.HitLocation);
				}
				
				ImpactActor = Projectiles[Index].ProjectileElement.TransitImpactActor_Enter;
				ImpactEffects = Projectiles[Index].ProjectileElement.PlayEffectOnTransitHit_Enter;
				EffectParams = Projectiles[Index].ProjectileElement.PlayEffectOnTransitHitInstanceParameterSet_Enter;
			}
			else
			{
				ImpactActor = Projectiles[Index].ProjectileElement.TransitImpactActor_Exit;
				ImpactEffects = Projectiles[Index].ProjectileElement.PlayEffectOnTransitHit_Exit;
				EffectParams = Projectiles[Index].ProjectileElement.PlayEffectOnTransitHitInstanceParameterSet_Exit;
			}
				
			if(ImpactActor != none)
			{
				Impact = Spawn(class'XComProjectileImpactActor', self, ,
								ProcessImpact.HitLocation,
								Rotator(ProcessImpact.HitNormal),
								ImpactActor, true);

				if(Impact != none)
				{
					Impact.HitNormal = ProcessImpact.HitNormal;
					Impact.HitLocation = ProcessImpact.HitLocation;
					Impact.TraceLocation = ProcessImpact.HitLocation;
					Impact.TraceNormal = ProcessImpact.HitNormal;
					Impact.TraceInfo = ProcessImpact.TraceInfo;
					Impact.TraceActor = none;
					Impact.Init();
				}
			}

			if(Projectiles[Index].ProjectileElement.bAlignPlayOnDeathToSurface)
			{
				DeathFXRotation = Rotator(-ProcessImpact.HitNormal);
			}
			else
			{
				DeathFXRotation = Rotator(vect(0, 0, 1));
			}

			if(ImpactEffects != none)
			{
				if( EffectParams != None )
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(ImpactEffects, ProcessImpact.HitLocation, DeathFXRotation, , , , , EffectParams.InstanceParameters);
				}
				else
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(ImpactEffects, ProcessImpact.HitLocation, DeathFXRotation);
				}
			}
		}
	}
	else
	{
		for(ImpactIndex = Projectiles[Index].ImpactEventsProcessed + 1; ImpactIndex < Projectiles[Index].ImpactEvents.Length && !bDoneProcessing; ++ImpactIndex)
		{
			ProcessImpact = Projectiles[Index].ImpactEvents[ImpactIndex];

			if(Projectiles[Index].GrenadePath == none)
			{
				TraveledDistance = Projectiles[Index].AliveTime * Projectiles[Index].AdjustedTravelSpeed;
				if(TraveledDistance >= ProcessImpact.TravelDistance && ProcessImpact.TravelDistance > 96.0f)
				{
					bTriggerImpact = true;
				}
				else
				{
					bDoneProcessing = true;
				}
			}
			else
			{
				//For the grenade path, the distance is time
				if(Projectiles[Index].AliveTime >= ProcessImpact.TravelDistance)
				{
					bTriggerImpact = true;
				}
				else
				{
					bDoneProcessing = true;
				}
			}

			if( (ProcessImpact.HitNormal.X == 0.0f && ProcessImpact.HitNormal.Y == 0.0f && ProcessImpact.HitNormal.Z == 0.0f) ||
			     ProcessImpact.TraceInfo.HitComponent != none && ProcessImpact.TraceInfo.HitComponent.Owner != None
				 && ProcessImpact.TraceInfo.HitComponent.Owner.IsA('XComUnitPawn') )//No transit impacts through pawns. They are either the target or not hit
			{
				Projectiles[Index].ImpactEventsProcessed = ImpactIndex;
				continue;
			}
				
			if(bTriggerImpact)
			{					
				Projectiles[Index].ImpactEventsProcessed = ImpactIndex;

				if(ProcessImpact.bEntry)
				{
					if (FireAction != none)
						FireAction.ProjectileNotifyHit(false, ProcessImpact.HitLocation);
					ImpactActor = Projectiles[Index].ProjectileElement.TransitImpactActor_Enter;
					ImpactEffects = Projectiles[Index].ProjectileElement.PlayEffectOnTransitHit_Enter;
					EffectParams = Projectiles[Index].ProjectileElement.PlayEffectOnTransitHitInstanceParameterSet_Enter;
				}
				else
				{
					ImpactActor = Projectiles[Index].ProjectileElement.TransitImpactActor_Exit;
					ImpactEffects = Projectiles[Index].ProjectileElement.PlayEffectOnTransitHit_Exit;
					EffectParams = Projectiles[Index].ProjectileElement.PlayEffectOnTransitHitInstanceParameterSet_Exit;
				}

				if(ImpactActor != none)
				{
					Impact = Spawn(class'XComProjectileImpactActor', self, ,
								   ProcessImpact.HitLocation,
								   Rotator(ProcessImpact.HitNormal),
								   ImpactActor, true);

					if(Impact != none)
					{
						Impact.HitNormal = ProcessImpact.HitNormal;
						Impact.HitLocation = ProcessImpact.HitLocation;
						Impact.TraceLocation = ProcessImpact.HitLocation;
						Impact.TraceNormal = ProcessImpact.HitNormal;
						Impact.TraceInfo = ProcessImpact.TraceInfo;
						Impact.TraceActor = none;
						Impact.Init();
					}
				}

				if(Projectiles[Index].ProjectileElement.bAlignPlayOnDeathToSurface)
				{
					DeathFXRotation = Rotator(-ProcessImpact.HitNormal);
				}
				else
				{
					DeathFXRotation = Rotator(vect(0, 0, 1));
				}

				if(ImpactEffects != none)
				{
					if( EffectParams != None )
					{
						WorldInfo.MyEmitterPool.SpawnEmitter(ImpactEffects, ProcessImpact.HitLocation, DeathFXRotation, , , , , EffectParams.InstanceParameters);
					}
					else
					{
						WorldInfo.MyEmitterPool.SpawnEmitter(ImpactEffects, ProcessImpact.HitLocation, DeathFXRotation);
					}
				}
			}
		}
	}
	
}

function DoMainImpact(int Index, float fDeltaT, bool bShowImpactEffects)
{
	local XGUnit TargetVisualizer;
	local XComProjectileImpactActor Impact;
	local Rotator DeathFXRotation;
	local name DamageTypeName;
	local XComGameState_Ability AbilityState;
	local float AbilityRadiusScalar;
	local ParticleSystemComponent DeathFX;
	local XComGameState_BaseObject OldBaseState, NewBaseState;
	local XComGameState_Unit OldUnitState, NewUnitState, ShooterState;
	local XComGameStateHistory History;
	local bool bIsUnitRuptured;

	local ProjectileTouchEvent MainImpactEvent; //for finding the appropriate bone to play hit effects on
	local int MainImpactEventIndex;
	local float ImpactEventDist;
	local float BestImpactEventDist;
	local vector BestImpactEffectPoint;
	local EAbilityHitResult EffectHitEffectsOverride;
	// Variables for Issue #10
	local XComLWTuple Tuple;

	if (Projectiles[ Index ].AdjustedTravelSpeed == 0)
	{
		// when projectile doesn't travel anywhere, we won't have impacted anything
		// seems to be an audio "projectile" with no physical form.
		return;
	}

	//If we are set to notify the target OR we are the last projectile and the target has not been notified yet...
	if( (FireAction != none) && !Projectiles[ Index ].bNotifiedTarget && (Projectiles[Index].ProjectileElement.bTriggerHitReact || (Index == Projectiles.Length - 1)) )
	{
		Projectiles[ Index ].bNotifiedTarget = true;
		FireAction.ProjectileNotifyHit(true, Projectiles[Index].InitialTargetLocation);
	}
	else if (FireAction != none)
	{
		FireAction.ProjectileNotifyHit(false, Projectiles[Index].InitialTargetLocation);
	}

	if (Projectiles[ Index ].ProjectileElement.ReturnsToSource && AbilityContextHitResult == eHit_Miss)
	{
		return; // when we've got a recoiling projectile that missed, there's not an actual impact
	}

	Projectiles[ Index ].LastImpactTime = WorldInfo.TimeSeconds;

	History = `XCOMHISTORY;
	TargetVisualizer = XGUnit(History.GetVisualizer(AbilityContextPrimaryTargetID));

	//Impact actors should be used when impacting against the environment.
	if(Projectiles[Index].ProjectileElement.UseImpactActor != none && (!Projectiles[Index].bStruckTarget || TargetVisualizer == none))
	{
		Impact = Spawn( class'XComProjectileImpactActor', self, ,
			Projectiles[ Index ].InitialTargetLocation,
			Rotator( Projectiles[ Index ].InitialTargetNormal ),
			Projectiles[ Index ].ProjectileElement.UseImpactActor, true );

		if (Impact != none)
		{
			Impact.HitNormal = Projectiles[ Index ].InitialTargetNormal;
			Impact.HitLocation = Projectiles[ Index ].InitialTargetLocation;
			Impact.TraceLocation = Impact.HitLocation; 
			Impact.TraceNormal = Impact.HitNormal;
			Impact.TraceInfo = Projectiles[ Index ].ImpactInfo;
			Impact.TraceActor = none;
			Impact.Init( );
		}
	}

	
	if (bShowImpactEffects && 
		!bIsASuppressionEffect && 
		AbilityContextHitResult != eHit_Miss && 
		Projectiles[Index].ProjectileElement.bTriggerPawnHitEffects &&
		Projectiles[Index].bStruckTarget)
	{
		History = `XCOMHISTORY;

		TargetVisualizer = XGUnit(History.GetVisualizer(AbilityContextPrimaryTargetID));
		if(TargetVisualizer != none)
		{
			DamageTypeName = WeaponTemplate != none ? WeaponTemplate.DamageTypeTemplateName : class'X2Item_DefaultDamageTypes'.default.DefaultDamageType;
			History.GetCurrentAndPreviousGameStatesForObjectID(AbilityContextPrimaryTargetID, OldBaseState, NewBaseState, eReturnType_Reference, 
															   FireAction == none ? -1 : FireAction.AbilityContext.AssociatedState.HistoryIndex);
			bIsUnitRuptured =false;
			OldUnitState = XComGameState_Unit(OldBaseState);
			NewUnitState = XComGameState_Unit(NewBaseState);

			if( (OldUnitState != none) &&
				(NewUnitState != none) &&
				(OldUnitState.Ruptured == 0) &&
				(NewUnitState.Ruptured > 0) )
			{
				// If the old state was not Ruptured and the new state has become Ruptured
				bIsUnitRuptured = true;
			}
		

			//Finding correct position and attachment for hit effect:
			//Of the impact events on the target's mesh, use the closest to the intended hit location (position and bone).
			//If none are valid, use the intended hit location exactly and search for the bone later.
			MainImpactEvent.TraceInfo.HitComponent = None;
			BestImpactEffectPoint = Projectiles[Index].TargetAttachActor.Location;
			for (MainImpactEventIndex = 0; MainImpactEventIndex < Projectiles[Index].ImpactEvents.Length; MainImpactEventIndex++)
			{
				if (Projectiles[Index].ImpactEvents[MainImpactEventIndex].TraceInfo.HitComponent != TargetVisualizer.GetPawn().Mesh)
					continue;

				ImpactEventDist = VSizeSq(Projectiles[Index].ImpactEvents[MainImpactEventIndex].HitLocation - Projectiles[Index].TargetAttachActor.Location);
				if (ImpactEventDist < BestImpactEventDist || MainImpactEvent.TraceInfo.HitComponent == None)
				{
					MainImpactEvent = Projectiles[Index].ImpactEvents[MainImpactEventIndex];
					BestImpactEventDist = ImpactEventDist;
					BestImpactEffectPoint = MainImpactEvent.HitLocation;
				}
			} 

			ShooterState = XComGameState_Unit(History.GetGameStateForObjectID(SourceAbility.InputContext.SourceObject.ObjectID));
			if( ShooterState != None && ShooterState.IsUnitAffectedByEffectName(class'X2Effect_BloodTrail'.default.EffectName) && AbilityContextHitResult == eHit_Success )
			{
				EffectHitEffectsOverride = eHit_Crit;
			}
			else
			{
				EffectHitEffectsOverride = AbilityContextHitResult;
			}

			TargetVisualizer.GetPawn().PlayHitEffects(1, none, BestImpactEffectPoint, DamageTypeName, -Projectiles[Index].InitialTravelDirection, bIsUnitRuptured, EffectHitEffectsOverride, MainImpactEvent.TraceInfo);

			// The Meta Hit Effect is played once per shot (and NOT for every individual projectile), and
			// is useful for showing an "overall" effect of the shot.  mdomowicz 2015_04_30
			if(!bPlayedMetaHitEffect)
			{
				bPlayedMetaHitEffect = true;
				TargetVisualizer.GetPawn().PlayMetaHitEffect(BestImpactEffectPoint, DamageTypeName, -Projectiles[Index].InitialTravelDirection, bIsUnitRuptured, EffectHitEffectsOverride, MainImpactEvent.TraceInfo);
			}
		}
	}	
	
	if(Projectiles[Index].ProjectileElement.bAlignPlayOnDeathToSurface)
	{
		DeathFXRotation = Rotator(-Projectiles[Index].InitialTargetNormal);
	}
	else
	{
		DeathFXRotation = Rotator(vect(0, 0, 1));
	}

	if(Projectiles[Index].ProjectileElement.PlayEffectOnDeath != none)
	{
		AbilityState = XComGameState_Ability( `XCOMHISTORY.GetGameStateForObjectID( AbilityContextAbilityRefID ) );
		AbilityRadiusScalar = bCosmetic ? 1.0f : AbilityState.GetActiveAbilityRadiusScalar( );

		DeathFX = WorldInfo.MyEmitterPool.SpawnEmitter(Projectiles[Index].ProjectileElement.PlayEffectOnDeath, Projectiles[Index].InitialTargetLocation, DeathFXRotation);
		DeathFX.SetScale( AbilityRadiusScalar );
	}

	if(Projectiles[Index].ProjectileElement.FireSoundLoopStop != none)
	{
		Projectiles[Index].SourceAttachActor.PlayAkEvent(Projectiles[Index].ProjectileElement.FireSoundLoopStop);
	}

	if(Projectiles[Index].ProjectileElement.DeathSound != none)
	{
		// Start Issue #10 Trigger an event that allows to override the default projectile sound
		Tuple = new class'XComLWTuple';
		Tuple.Id = 'ProjectilSoundOverride';
		Tuple.Data.Add(3);

		// The SoundCue to play instead of the AKEvent, used as reference
		Tuple.Data[0].kind = XComLWTVObject;
		Tuple.Data[0].o = none;

		// Projectile Element ObjectArchetype Pathname Parameter
		Tuple.Data[1].kind = XComLWTVString;
		Tuple.Data[1].s = PathName(Projectiles[Index].ProjectileElement.ObjectArchetype);

		// Ability Context Ref Parameter
		Tuple.Data[2].kind = XComLWTVInt;
		Tuple.Data[2].i = AbilityContextAbilityRefID;

		`XEVENTMGR.TriggerEvent('OnProjectileDeathSound', Tuple, Projectiles[Index].ProjectileElement, none);
		if (Tuple.Data[0].o != none)
		{
			Projectiles[Index].TargetAttachActor.PlaySound(SoundCue(Tuple.Data[0].o));
		}
		else
		{
			Projectiles[Index].TargetAttachActor.PlayAkEvent(Projectiles[Index].ProjectileElement.DeathSound, , , , Projectiles[Index].InitialTargetLocation);
		}
		// End Issue #10
	}
}

function EndProjectileInstance(int Index, float fDeltaT)
{
	if( !Projectiles[Index].bWaitingToDie )
	{
		Projectiles[Index].bWaitingToDie = true;

		if ((Projectiles[Index].ProjectileElement.UseProjectileType != eProjectileType_RangedConstant) || Projectiles[ Index ].ProjectileElement.ReturnsToSource)
		{			
			Projectiles[ Index ].SourceAttachActor.SetPhysics( PHYS_None );
			Projectiles[ Index ].TargetAttachActor.SetPhysics( PHYS_None );
		}

		if (Projectiles[Index].ProjectileElement.UseProjectileType != eProjectileType_Ranged)
		{
			Projectiles[Index].TargetAttachActor.SetLocation(Projectiles[Index].InitialTargetLocation);
			Projectiles[Index].TargetAttachActor.Velocity = vect(0,0,0);
			Projectiles[Index].TargetAttachActor.ForceUpdateComponents(FALSE);
		}

		Projectiles[Index].TargetAttachActor.SetHidden( true );
	}	
}

function vector GetAimLocation(int Index)
{
	local X2VisualizerInterface TargetVisualizer;
	local Rotator MuzzleRotation;
	local Vector SourceLocation;
	local XComGameState_Ability Ability;
	local X2AbilityTemplate AbilityTemplate;
	local XComPerkContentInst kContent;
	local bool bFiringAtMovingTarget;

	Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContextAbilityRefID));
	AbilityTemplate = Ability.GetMyTemplate( );

	if(bCosmetic)
	{
		if( CosmeticTarget != none )
		{
			return CosmeticTarget.Location;
		}
		else
		{
			return CosmeticTargetLocation;
		}
	}

	bFiringAtMovingTarget = class'XComTacticalGRI'.static.GetReactionFireSequencer().FiringAtMovingTarget();

	//If this was a hit OR the target is moving (overwatch)
	if((AbilityContextHitResult != eHit_Miss || (FireAction != none && bFiringAtMovingTarget)) && !AbilityTemplate.bIsASuppressionEffect)
	{
		TargetVisualizer = X2VisualizerInterface(`XCOMHISTORY.GetVisualizer(AbilityContextPrimaryTargetID));		

		if( TargetVisualizer != none )		
		{
			// if we're not attached to a socket or getting that socket from the mesh failed, fallback on math
			if (Projectiles[ Index ].ProjectileElement.bAttachToTarget && Projectiles[ Index ].ProjectileElement.TargetAttachSocket != '' &&
				XGUnit( TargetVisualizer ).GetPawn( ).Mesh.GetSocketWorldLocationAndRotation( Projectiles[ Index ].ProjectileElement.TargetAttachSocket, SourceLocation, MuzzleRotation ))
			{
				return SourceLocation;
			}
			if (VolleyNotify.bPerkVolley)
			{
				kContent = XComUnitPawn( SourceWeapon.m_kPawn ).GetPerkContent( VolleyNotify.PerkAbilityName );
				if (kContent.GetPerkWeapon() != none)
				{
					if ((kContent.m_PerkData.WeaponTargetSocket != '') && XGUnit( TargetVisualizer ).GetPawn( ).Mesh.GetSocketWorldLocationAndRotation( kContent.m_PerkData.WeaponTargetSocket, SourceLocation, MuzzleRotation ))
					{
						return SourceLocation;
					}
					if (kContent.m_PerkData.WeaponTargetBone != '')
					{
						return XGUnit( TargetVisualizer ).GetPawn( ).Mesh.GetBoneLocation( kContent.m_PerkData.WeaponTargetBone);
					}
				}
			}

			return TargetVisualizer.GetShootAtLocation(AbilityContextHitResult, SourceAbility.InputContext.SourceObject);
		}

		return AbilityContextTargetLocation;
	}

	return AbilityContextTargetLocation;
}

function bool ProjectileShouldImpact( int Index )
{
	local bool bMultiImpact; //True for continuous projectiles like beams	
	local float ImpactInterval, ImpactWindow;

	ImpactInterval = Projectiles[ Index ].ProjectileElement.MinImpactInterval;
	ImpactWindow = Projectiles[ Index ].ProjectileElement.MultiImpactWindowLength;
	bMultiImpact = (Projectiles[ Index ].ProjectileElement.bContinuousDistanceUpdates && (ImpactInterval > 0));

	// not continuous
	if (!bMultiImpact || (Projectiles[ Index ].LastImpactTime == 0.0f))
	{
		return true;
	}

	// Has the projectile been alive longer than the duration that should spawn impacts?
	if ((ImpactWindow > 0) && (Projectiles[ Index ].ActiveTime >= ImpactWindow))
	{
		return false;
	}

	// Is it too soon to play another impact?
	if (WorldInfo.TimeSeconds < (Projectiles[ Index ].LastImpactTime + ImpactInterval))
	{
		return false;
	}

	return true;
}

//Checks all running projectiles to see if their end time has elapsed already or not
function bool EndTimesCompleted()
{
	local int Index;
	local bool bReturn;

	bReturn = true;
	for (Index = 0; Index < Projectiles.Length; ++Index)
	{
		if (!Projectiles[Index].bFired || Projectiles[Index].EndTime >= WorldInfo.TimeSeconds)
		{
			bReturn = false;
			break;
		}
	}

	return bReturn;
}

private function DebugParamsOut( int Index )
{
	local ProjectileElementInstance Projectile;
	local ParticleSystemComponent ParticleSystem;

	local float InitalTargetDistance;
	local float TargetDistance;
	local float TravelDistance;

	Projectile = Projectiles[ Index ];
	ParticleSystem = Projectile.ParticleEffectComponent;

	if (ParticleSystem != none)
	{
		ParticleSystem.GetFloatParameter( 'Initial_Target_Distance', InitalTargetDistance );
		ParticleSystem.GetFloatParameter( 'Target_Distance', TargetDistance );
		ParticleSystem.GetFloatParameter( 'Traveled_Distance', TravelDistance );

		`log("********************* PROJECTILE Element #"@self.Name@Index@" Frame "@WorldInfo.TimeSeconds@" *********************************", , 'DevDestruction');
		`log("Source actor location is "@Projectile.SourceAttachActor.Location, , 'DevDestruction');
		`log("Target actor location is "@Projectile.TargetAttachActor.Location, , 'DevDestruction');
		`log("Target actor velocity is "@Projectile.TargetAttachActor.Velocity, , 'DevDestruction');
		`log("Param Initial Target Distance: "@InitalTargetDistance, , 'DevDestruction');
		`log("Param Current Target Distance: "@TargetDistance, , 'DevDestruction');
		`log("Param Travel Distance: "@TravelDistance, , 'DevDestruction');
		`log("Compute Travel Distance: "@VSize(Projectile.TargetAttachActor.Location - Projectile.SourceAttachActor.Location), , 'DevDestruction');
		`log("Start Time: "@Projectile.StartTime, , 'DevDestruction');
		`log("End Time: "@Projectile.EndTime, , 'DevDestruction');
		`log("Trail Time: "@Projectile.TrailAdjustmentTime, , 'DevDestruction' );
		`log("******************************************************************************************", , 'DevDestruction');
	}
}

auto state WaitingToStart
{
}

state Executing
{
	event BeginState(Name PreviousStateName)
	{		
		SetupVolley();
	}

	event EndState(Name PreviousStateName)
	{
		
	}

	simulated event Tick( float fDeltaT )
	{
		local int Index, i;
		local bool bAllProjectilesDone;

		local bool bShouldEnd, bShouldUpdate, bProjectileEffectsComplete, bStruckTarget;
		local float timeDifferenceForRecoil;
		local float originalfDeltaT;
		originalfDeltaT = fDeltaT;
		bAllProjectilesDone = true; //Set to false if any projectiles are 1. still to be created 2. being created 3. still in flight w. effects

		for( Index = 0; Index < Projectiles.Length; ++Index )
		{

			//Update existing projectiles, fire any projectiles that are pending
			if( Projectiles[Index].bFired )
			{
				if( OrdnanceType == class'X2TargetingMethod_MECMicroMissile'.default.OrdnanceTypeName )
				{
					//Travel Speed for Micromissile is the scalar value of how a gravity thrown bomb would be like
					 fDeltaT = Projectiles[Index].ProjectileElement.TravelSpeed * originalfDeltaT;
				}

				Projectiles[ Index ].ActiveTime += fDeltaT;
				if (!Projectiles[ Index ].bWaitingToDie)
				{
					Projectiles[ Index ].AliveTime += fDeltaT;
				}

				// Traveling projectiles should be forcibly deactivated once they've reaced their destination (and the trail has caught up).
				if(Projectiles[Index].ParticleEffectComponent != None && (Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_Traveling) && (WorldInfo.TimeSeconds >= (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime)))
				{
					Projectiles[ Index ].ParticleEffectComponent.OnSystemFinished = none;
					Projectiles[ Index ].ParticleEffectComponent.DeactivateSystem( );
					// Start Issue #720
					/// HL-Docs: ref:ProjectilePerformanceDrain
					// Allow the pool to reuse this Particle System's spot in the pool.
					// Cannot return to pool directly - doing so destoys trails/smoke/effects that dissipate over time.
					//WorldInfo.MyEmitterPool.OnParticleSystemFinished(Projectiles[ Index ].ParticleEffectComponent);
					DelayedReturnToPoolPSC(Projectiles[ Index ].ParticleEffectComponent);
					// End Issue #720
					Projectiles[ Index ].ParticleEffectComponent = none;
				}

				bStruckTarget = StruckTarget(Index, fDeltaT);
				bShouldEnd = (WorldInfo.TimeSeconds > Projectiles[Index].EndTime) && !Projectiles[Index].bWaitingToDie;
				bShouldEnd = bShouldEnd || bStruckTarget;

				bShouldUpdate = Projectiles[Index].ProjectileElement.bAttachToSource || Projectiles[Index].ProjectileElement.bAttachToTarget ||
					((Projectiles[Index].ProjectileElement.UseProjectileType == eProjectileType_RangedConstant) && (!Projectiles[Index].bConstantComplete));

				bProjectileEffectsComplete = (Projectiles[ Index ].ParticleEffectComponent == none || Projectiles[ Index ].ParticleEffectComponent.HasCompleted( ));

				if (bShouldEnd)
				{
					//The projectile has reached its destination / conclusion. Begin the destruction process.
					EndProjectileInstance( Index, fDeltaT );
				}

				if (ProjectileShouldImpact(Index))
				{
					if(bShouldEnd)
					{
						DoMainImpact(Index, fDeltaT, bStruckTarget); //Impact(s) that should play when the shot "reaches the target"
					}
					else if (!Projectiles[Index].bWaitingToDie)
					{
						DoTransitImpact(Index, fDeltaT); //Impact(s) that should play while the shot is in transit
					}					
				}

				ProcessReturn( Index );

				if (!bShouldEnd || bShouldUpdate || bStruckTarget)
				{
					//The projectile is in flight or a mode that wants continued position updates after ending
					UpdateProjectileDistances( Index, fDeltaT );
				}

				// always update the trail
				UpdateProjectileTrail( Index );

				bAllProjectilesDone = bAllProjectilesDone && bProjectileEffectsComplete && Projectiles[Index].bWaitingToDie;

				// A fallback to catch bad projectile effects that are lasting too long (except for the constants)
				if (!bProjectileEffectsComplete && (WorldInfo.TimeSeconds > (Projectiles[Index].EndTime + Projectiles[Index].TrailAdjustmentTime + 10.0)) && (Projectiles[Index].ProjectileElement.UseProjectileType != eProjectileType_RangedConstant))
				{
					Projectiles[ Index ].ParticleEffectComponent.OnSystemFinished = none;
					Projectiles[ Index ].ParticleEffectComponent.DeactivateSystem( );
					// Start Issue #720
					/// HL-Docs: ref:ProjectilePerformanceDrain
					// Allow the pool to reuse this Particle System's spot in the pool.
					// Cannot return to pool directly - doing so destoys trails/smoke/effects that dissipate over time.
					//WorldInfo.MyEmitterPool.OnParticleSystemFinished(Projectiles[ Index ].ParticleEffectComponent);
					DelayedReturnToPoolPSC(Projectiles[ Index ].ParticleEffectComponent);
					// End Issue #720
					Projectiles[ Index ].ParticleEffectComponent = none;
					//`RedScreen("Projectile " $ Index  $ " vfx for weapon " $ FireAction.SourceItemGameState.GetMyTemplateName() $ " still hasn't completed after 10 seconds past expected completion time");
				}

				//DebugParamsOut( Index );
			}
			//Adding Recoil from firing Chang You 2015-6-14
			else if(!Projectiles[Index].bRecoilFromFiring)
			{
				//start moving the aim to the missed position to simulate recoil
				if(WorldInfo.TimeSeconds >= Projectiles[Index].StartTime - 0.1f)
				{
					//if the first shot is too early, we need to readjust all the following shots to a later time.
					if(bFirstShotInVolley)
					{
						timeDifferenceForRecoil = Projectiles[Index].StartTime - WorldInfo.TimeSeconds;
						for( i = 0; i < Projectiles.Length; ++i )
						{
							Projectiles[i].StartTime += 0.1f - Max(timeDifferenceForRecoil, 0.0f);
						}
						bFirstShotInVolley = false;
					}
					RecoilFromFiringProjectile(Index);
					Projectiles[Index].bRecoilFromFiring = true;
				}
				bAllProjectilesDone = false;
			}
			else if( WorldInfo.TimeSeconds >= Projectiles[Index].StartTime )
			{
				bAllProjectilesDone = false;
				FireProjectileInstance(Index);
				--Index; // reprocess this projectile to do all the updates so that lifetime accumulators and timers are in reasonable sync
			}
			else
			{
				//If there are unfired projectiles...
				bAllProjectilesDone = false;
			}
		}

		if( bSetupVolley && bAllProjectilesDone )
		{		
			for( Index = 0; Index < Projectiles.Length; ++Index )
			{
				Projectiles[ Index ].SourceAttachActor.Destroy( );
				Projectiles[ Index ].TargetAttachActor.Destroy( );
			}
			Destroy( );
		}
	}

Begin:
}

// Start Issue #720
/// HL-Docs: ref:ProjectilePerformanceDrain
private static function DelayedReturnToPoolPSC (ParticleSystemComponent PSC)
{
	local float Delay;
	local int i;

	i = class'CHHelpers'.default.ProjectileParticleSystemExpirationOverrides.Find('ParticleSystemPathName', PathName(PSC.Template));

	if (i != INDEX_NONE)
	{
		Delay = class'CHHelpers'.default.ProjectileParticleSystemExpirationOverrides[i].ExpiryTime;
	}
	else if (class'CHHelpers'.default.ProjectileParticleSystemExpirationDefaultOverride >= 5)
	{
		Delay = class'CHHelpers'.default.ProjectileParticleSystemExpirationDefaultOverride;
	}
	else
	{
		// The default is 1 minute
		Delay = 60;
	}

	class'CHEmitterPoolDelayedReturner'.static.GetSingleton().AddCountdown(PSC, Delay);
}

// This is a very extreme backup handler - we should never need to do this,
// since the PSC reference is always nulled out after calling DelayedReturnToPoolPSC
private static function CancelDelayedReturnToPoolPSC (ParticleSystemComponent PSC)
{
	local bool bRemoved;
	
	bRemoved = class'CHEmitterPoolDelayedReturner'.static.GetSingleton().TryRemoveCountdown(PSC);

	if (bRemoved)
	{
		`RedScreen("CHL:" @ GetFuncName() @ "was successfull - this should never happen!" @ `showvar(PathName(PSC.Template)) @ GetScriptTrace());
		`RedScreen(class'CHEmitterPoolDelayedReturner'.default.strInformCHL);
	}
}
// End Issue #720

DefaultProperties
{
	TickGroup=TG_PostUpdateWork; //so that we can calculate attachment based locations *after* animations have been run.
}
