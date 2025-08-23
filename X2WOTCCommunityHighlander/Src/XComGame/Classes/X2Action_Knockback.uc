//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Knockback extends X2Action;

var float OverrideRagdollFinishTimerSec;

var private Vector Destination;
var private XComGameState_Unit NewUnitState;
var private Vector PhysicsImpulse;
var private bool bReachedDestination;
var private RB_ConstraintActorSpawnable ConstraintActor;
var private Vector ImpulseDirection;
var private StateObjectReference DmgObjectRef;
var private CustomAnimParams AnimParams;
var private AnimNodeSequence KnockBackAnim;
var private Vector ShouldFaceVec;
var private bool bNeedsPhysicsFixup;
var private bool bDied;
var private float CloseEnoughDistance;
var private X2Action_Death DeathAction;
var private XComGameStateContext_Ability	AbilityContext;
var private X2AbilityTemplate               AbilityTemplate;
var private Actor							DamageDealer;
var			bool OnlyRecover;
var private bool StayInPlace;

// Variable for Issue #1463
var name CustomKnockbackAnimationName;

function Init()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;	
	local TTile UnitTileLocation;
	local float KnockbackDistance;	
	local XComGameState_Unit OldUnitState;

	super.Init();

	History = `XCOMHISTORY;

	NewUnitState = XComGameState_Unit(Metadata.StateObject_NewState);
	OldUnitState = XComGameState_Unit(Metadata.StateObject_OldState);

	WorldData = `XWORLD;
	NewUnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
	bDied = !NewUnitState.IsAlive();
	Destination = WorldData.GetPositionFromTileCoordinates(UnitTileLocation);
	Destination.Z = UnitPawn.GetDesiredZForLocation(Destination);

	KnockbackDistance = VSize2D(Destination - UnitPawn.Location);
	bNeedsPhysicsFixup = VSize2D(Destination - UnitPawn.Location) > 192.0f || (Destination.Z - UnitPawn.Location.Z > 192.0f);
	PhysicsImpulse = Normal(Destination - UnitPawn.Location);
	PhysicsImpulse.Z = 0.0f;
	ShouldFaceVec = -PhysicsImpulse;

	PhysicsImpulse *= KnockbackDistance * 1.5f;
	PhysicsImpulse += Vect(0, 0, 1) * 400.0f;

	StayInPlace = NewUnitState.TileLocation == OldUnitState.TileLocation;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	if (AbilityContext != none)
	{
		DamageDealer = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID).GetVisualizer();
		AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		`assert(AbilityTemplate != none);

		if( StayInPlace )
		{
			ShouldFaceVec = DamageDealer.Location - UnitPawn.Location;
			ShouldFaceVec.Z = 0.0f;
		}
	}

	DeathAction = X2Action_Death(VisualizationMgr.GetNodeOfType(VisualizationMgr.VisualizationTree, class'X2Action_Death', Metadata.VisualizeActor));	
	if(DeathAction != none )
	{
		DeathAction.Init(); // This fixes all the none access errors when accessing any DeathAction functions.
	}
}

function bool CheckInterrupted()
{
	return false;
}

function ResumeFromInterrupt(int HistoryIndex)
{
	super.ResumeFromInterrupt(HistoryIndex);
}

function StartRagdoll()
{
	UnitPawn.StartRagDoll(false, , , false);
}

/// HL-Docs: ref:PlayKnockback
// Start Issue #1463
function Name ComputeAnimationToPlay()
{
	local float fDot;
	local vector UnitRight;
	local float fDotRight;
	local vector WorldUp;
	local Name AnimName;
	local string AnimString;
	local XComGameState_Ability AbilityState;
	local bool ShouldUseMeleeKnockback;
	local X2Effect_Persistent PersistentEffect; 
	local Vector vHitDir;
	local bool bDoOverrideAnim;
	local XComGameState_Unit OverrideOldUnitState;
	local string OverrideAnimEffectString;
	local XComGameState_Item SourceItemGameState;
	local XGWeapon WeaponVisualizer;
	local XComWeapon WeaponData;

	if (CustomKnockbackAnimationName != 'None' && UnitPawn.GetAnimTreeController().CanPlayAnimation(CustomKnockbackAnimationName))
	{
		return CustomKnockbackAnimationName;
	}
	
	WorldUp.X = 0.0f;
	WorldUp.Y = 0.0f;
	WorldUp.Z = 1.0f;

	OverrideOldUnitState = XComGameState_Unit(Metadata.StateObject_OldState);
	bDoOverrideAnim = class'X2StatusEffects'.static.GetHighestEffectOnUnit(OverrideOldUnitState, PersistentEffect, true);

	OverrideAnimEffectString = "";
	if(bDoOverrideAnim)
	{
		// Allow new animations to play
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		OverrideAnimEffectString = string(PersistentEffect.EffectName);
	}
	
	if (AbilityTemplate != none && AbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Cursor'))
	{
		//Damage from position-based abilities should have their damage direction based on the target location
		`assert( AbilityContext.InputContext.TargetLocations.Length > 0 );
		vHitDir = Unit.GetPawn().Location - AbilityContext.InputContext.TargetLocations[0];
	}
	else if (DamageDealer != none)
	{
		vHitDir = Unit.GetPawn().Location - DamageDealer.Location;
	}
	else
	{
		vHitDir = -Vector(Unit.GetPawn().Rotation);
	}

	vHitDir = Normal(vHitDir);

	fDot = vHitDir dot vector(Unit.GetPawn().Rotation);
	UnitRight = Vector(Unit.GetPawn().Rotation) cross WorldUp;
	fDotRight = vHitDir dot UnitRight;

	// Default knockback
	AnimName = 'HL_MeleeKnockback';

	if(!StayInPlace)
	{
		if(fDot < 0.5f) //There are no "shot from the back" anims, so skip the anim selection process for those
		{
			if(abs(fDot) >= abs(fDotRight))
			{
				AnimString = "HL_"$OverrideAnimEffectString$"Knockback";
			}
			else
			{
				if(fDotRight > 0)
				{
					AnimString = "HL_"$OverrideAnimEffectString$"KnockbackRight";
				}
				else
				{
					AnimString = "HL_"$OverrideAnimEffectString$"KnockbackLeft";
				}
			}
		}

		// Fallback to typical situation, where the unit is facing us
		if(!Unit.GetPawn().GetAnimTreeController().CanPlayAnimation(name(AnimString)))
		{
			AnimString = "HL_Knockback";
		}
	}

	AbilityState = AbilityContext != none ? XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID)) : none;
	ShouldUseMeleeKnockback = (AbilityState != none) && AbilityState.GetMyTemplate().ShouldPlayMeleeDeath();

	if (AbilityContext != none)
	{
		SourceItemGameState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
		if( SourceItemGameState != None )
		{
			WeaponVisualizer = XGWeapon(SourceItemGameState.GetVisualizer());
			if( WeaponVisualizer != None )
			{
				WeaponData = WeaponVisualizer.GetEntity();
			}
		}
	}
	
	if( (WeaponData != None && WeaponData.bOverrideMeleeDeath == true) || UnitPawn.GetAnimTreeController().CanPlayAnimation('HL_MeleeKnockback') == false )
	{
		ShouldUseMeleeKnockback = false;
	}
	
	if( ShouldUseMeleeKnockback )
	{
		AnimString = "HL_MeleeKnockback";
	}
	
	if(AnimString != "")
	{
		AnimName = name(AnimString);
	}

	return AnimName;
}
// End Issue #1463

simulated state Executing
{
	simulated event BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);

		//`SHAPEMGR.DrawSphere(Destination, vect(5, 5, 80), MakeLinearColor(1, 0, 0, 1), true);

		Unit.BeginUpdatingVisibility();
	}

	simulated event EndState(name NextStateName)
	{
		super.EndState(NextStateName);
		if( ConstraintActor != None )
		{
			ConstraintActor.Destroy();
		}

		Unit.EndUpdatingVisibility();
	}

	function DelayedNotify()
	{
		// VISUALIZATION REWRITE - MESSAGE
	}

	function MaybeNotifyEnvironmentDamage()
	{
		local XComGameState_EnvironmentDamage EnvironmentDamage;		
		local TTile CurrentTile;

		CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);
		
		foreach StateChangeContext.AssociatedState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamage)
		{
			if(EnvironmentDamage.HitLocationTile == CurrentTile)
			{			
				DmgObjectRef = EnvironmentDamage.GetReference();				
				SetTimer(0.3f, false, nameof(DelayedNotify)); //Add a small delay since the is tile based 
			}
		}
	}

	function CopyPose()
	{
		AnimParams.AnimName = 'Pose';
		AnimParams.Looping = true;
		AnimParams.BlendTime = 0.0f;
		AnimParams.HasPoseOverride = true;
		AnimParams.Pose = UnitPawn.Mesh.LocalAtoms;
		UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
	}

Begin:	
	if (!bDied && `TUTORIAL != none) //Legacy save / tutorial support
	{
		CompleteAction();
	}

	if( !OnlyRecover )
	{
		UnitPawn.SetRotation(rotator(ShouldFaceVec)); //Ensure the target is ready to animate for their attack

		//Have the character attempt to play an animation to 'seed' the rag doll. If that cannot be done, just go to rag doll immediately	
		UnitPawn.DyingImpulse = PhysicsImpulse; //Need to impart an initial velocity
		UnitPawn.SetFinalRagdoll(bDied);

		if( DeathAction != none )
		{
			Unit.SetForceVisibility(eForceVisible);

			AnimParams.AnimName = DeathAction.ComputeAnimationToPlay();

			if( bDied )
			{
				DeathAction.vHitDir = Normal(Destination - UnitPawn.Location); //For projectile-aligned death effects

				Unit.OnDeath(none, XGUnit(DamageDealer));

				if( OverrideRagdollFinishTimerSec >= 0 )
				{
					UnitPawn.RagdollFinishTimer = OverrideRagdollFinishTimerSec;
				}

				UnitPawn.PlayDying(none, UnitPawn.GetHeadshotLocation(), AnimParams.AnimName, Destination);
			}
			else
			{
				UnitPawn.DeathRestingLocation = Destination;

				UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams); //Playing this anim will trigger a ragdoll notify
				SetTimer(0.5f, false, nameof(StartRagdoll)); //Failsafe in case the anim doesn't have the right notify for some reason
				Sleep(3.0f);
			}
		}
		/// HL-Docs: ref:PlayKnockback
		// Start Issue #1463
		else
		{
			AnimParams = default.AnimParams;
			AnimParams.AnimName = ComputeAnimationToPlay();

			UnitPawn.DeathRestingLocation = Destination;

			if(UnitPawn.GetAnimTreeController().CanPlayAnimation(AnimParams.AnimName))
			{
				UnitPawn.PlayKnockback(AnimParams.AnimName, Destination);
			}
			else
			{
				StartRagdoll();
			}

			Sleep(3.0f);
		}
		// End Issue #1463
	}

	//When units are getting up from a fall or recovering from incapacitation, they use an X2Action_Knockback.
	if(!NewUnitState.IsDead() && !NewUnitState.IsIncapacitated())
	{		
		//Reset visualizers for primary weapon, in case it was dropped
		// Start Issue #1290
		// Delete the dummy weapon that was created when unit dies and drops their weapon
		if(Unit.DummyWeapon != None)
		{
			Unit.DummyWeapon.Destroy();
		}
		// End Issue #1290

		Unit.GetInventory().GetPrimaryWeapon().Destroy(); //Aggressively get rid of the primary weapon, because dropping it can really screw things up
		Unit.ApplyLoadoutFromGameState(NewUnitState, None);

		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);

		// Copy all the bone transforms so we match his pose
		CopyPose();

		//Make a fancier transition out of ragdoll if needed 
		UnitPawn.EndRagDoll();

		// Jwats: House keeping! Make sure we a re in a good animation state.
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		UnitPawn.SetNoSkeletonUpdate(false);
		Unit.SetTimeDilation(1.0f);

		UnitPawn.EnableRMA(true, true);
		UnitPawn.EnableRMAInteractPhysics(true);
		UnitPawn.EnableFootIK(true);
		UnitPawn.bSkipIK = false;

		AnimParams = default.AnimParams;
		AnimParams.AnimName = 'HL_GetUp';
		AnimParams.BlendTime = 0.5f;
		AnimParams.DesiredEndingAtoms.Add(1);
		AnimParams.DesiredEndingAtoms[0].Translation = Destination;
		AnimParams.DesiredEndingAtoms[0].Rotation = QuatFromRotator(UnitPawn.Rotation);
		AnimParams.DesiredEndingAtoms[0].Scale = 1.0f;
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

		UnitPawn.EnableFootIK(true);
		UnitPawn.bSkipIK = false;
		UnitPawn.EnableRMA(true, true);
		UnitPawn.EnableRMAInteractPhysics(true);
		UnitPawn.LockDownFootIK(false);
		UnitPawn.fFootIKTimeLeft = 10.0f;

		Unit.IdleStateMachine.CheckForStanceUpdate();
	}

	CompleteAction();	
}

function CompleteAction()
{	
	super.CompleteAction();
}

DefaultProperties
{
	InputEventIDs.Add("Visualizer_EffectApplied")
	InputEventIDs.Add("Visualizer_AbilityHit");
	OutputEventIDs.Add("Visualizer_Knockback")
	CloseEnoughDistance = 100.0f
	OverrideRagdollFinishTimerSec=-1;
}
