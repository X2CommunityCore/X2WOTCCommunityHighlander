//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Death extends X2Action;

var float							TimeToRagdoll;                  //Indicates the time at which the kinematic death should switch from animation to ragdoll
var Actor							DamageDealer;
var float							StartedDeathTime;
var class<DamageType>				m_kDamageType;
var CustomAnimParams				AnimParams;
var XComGameStateContext_Ability	AbilityContext;
var X2AbilityTemplate               AbilityTemplate;
var name                            AnimationName;
var bool	                        bDoOverrideAnim;
var XComGameState_Unit              OverrideOldUnitState;
var string	                        OverrideAnimEffectString;
var vector							vHitDir; //Direction the hit came from
var XComGameState_Item				SourceItemGameState;
var XGWeapon						WeaponVisualizer;
var XComWeapon						WeaponData;
var vector							Destination; //destination location after death
var protected XComGameState_Unit		NewUnitState;
var bool							bForceMeleeDeath;

var protected bool                  bWaitUntilNotified; // Allows overriding death actions to wait for notifications

// Issue #488
var name							CustomDeathAnimationName;

function Init()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local TTile UnitTileLocation;	

	super.Init();

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	if (AbilityContext != none)
	{
		SourceItemGameState = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
		if( SourceItemGameState != None )
		{
			WeaponVisualizer = XGWeapon(SourceItemGameState.GetVisualizer());
			if( WeaponVisualizer != None )
			{
				WeaponData = WeaponVisualizer.GetEntity();
			}
		}

		DamageDealer = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID).GetVisualizer();
		AbilityTemplate =  class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		`assert(AbilityTemplate != none);
	}

	//Figure out where we will land ( if death was not already processed by knockback )
	NewUnitState = XComGameState_Unit(Metadata.StateObject_NewState);
	WorldData = `XWORLD;
	NewUnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
	Destination = WorldData.GetPositionFromTileCoordinates(UnitTileLocation);
}

static function X2Action AddToVisualizationTree(out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context, optional bool ReparentChildren = false, optional X2Action Parent, optional array<X2Action> AdditionalParents)
{
	local X2Action AddAction;
	local XComGameState_Unit NewGameStateUnit;
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;

	History = `XCOMHISTORY;
	NewGameStateUnit = XComGameState_Unit(History.GetGameStateForObjectID(ActionMetadata.StateObject_NewState.ObjectID));
	
	foreach NewGameStateUnit.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		EffectTemplate = EffectState.GetX2Effect();
		
		if( EffectTemplate != none )
		{
			AddAction = EffectTemplate.AddX2ActionsForVisualization_Death(ActionMetadata, Context);

			if( AddAction != none )
			{
				return AddAction;
			}
		}
	}

	return super.AddToVisualizationTree(ActionMetadata, Context, false, ActionMetadata.LastActionAdded);
}

function bool ShouldRunDeathHandler()
{
	return !XComGameState_Unit(Metadata.StateObject_NewState).IsAlive();
}

function bool ShouldPlayDamageContainerDeathEffect()
{
	return true;
}

function bool DamageContainerDeathSound()
{
	return true;
}

simulated function Name ComputeAnimationToPlay()
{
	local float fDot;
	local vector UnitRight;
	local float fDotRight;
	local vector WorldUp;
	local Name AnimName;
	local string AnimString;
	local XComGameState_Ability AbilityState;
	local bool ShouldUseMeleeDeath;
	local X2Effect_Persistent PersistentEffect; 

	// Start Issue #488
	if (CustomDeathAnimationName != 'None' && UnitPawn.GetAnimTreeController().CanPlayAnimation(CustomDeathAnimationName))
	{
		return CustomDeathAnimationName;
	}
	// End Issue #488

	WorldUp.X = 0.0f;
	WorldUp.Y = 0.0f;
	WorldUp.Z = 1.0f;

	if( AbilityContext != None && class'XComTacticalGRI'.static.GetReactionFireSequencer().IsReactionFire(AbilityContext) )
	{
		UnitPawn.bReactionFireDeath = true;
		//Most units will not specify a ReactionFireDeathAnim ( the bone springs system will turn us into a rag doll in due time )
		return NewUnitState.GetMyTemplate().ReactionFireDeathAnim;
	}

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

	// Fallback default death
	AnimString = "HL_MeleeDeath";

	if( Unit.IsTurret() )
	{
		if( Unit.GetTeam() == eTeam_Alien )
		{
			AnimString = "NO_"$OverrideAnimEffectString$"Death_Advent";
		}
		else
		{
			AnimString = "NO_"$OverrideAnimEffectString$"Death_Xcom";
		}
	}
	else
	{
		if(fDot < 0.5f) //There are no "shot from the back" anims, so skip the anim selection process for those
		{
			if(abs(fDot) >= abs(fDotRight))
			{
				AnimString = "HL_"$OverrideAnimEffectString$"Death";

				//Have a fallback ready for the "typical" death situation - where the unit is facing us. The "side" deaths below can fall back to the pure physics death
				if(!Unit.GetPawn().GetAnimTreeController().CanPlayAnimation(name(AnimString)))
				{
					AnimName = 'HL_Death';
				}
			}
			else
			{
				if(fDotRight > 0)
				{
					AnimString = "HL_"$OverrideAnimEffectString$"DeathRight";
				}
				else
				{
					AnimString = "HL_"$OverrideAnimEffectString$"DeathLeft";
				}
			}
		}
	}

	AbilityState = AbilityContext != none ? XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID)) : none;
	ShouldUseMeleeDeath = (AbilityState != none) && AbilityState.GetMyTemplate().ShouldPlayMeleeDeath();
	if( (WeaponData != None && WeaponData.bOverrideMeleeDeath == true) || UnitPawn.GetAnimTreeController().CanPlayAnimation('HL_MeleeDeath') == false )
	{
		ShouldUseMeleeDeath = false;
	}

	if( ShouldUseMeleeDeath || bForceMeleeDeath )
	{
		AnimString = "HL_MeleeDeath";
	}

	AnimName = name(AnimString); //If the pawn cannot play this animation, that is handled in UnitPawn.PlayDying

	return AnimName;
}

event int ScoreNodeForTreePlacement(X2Action PossibleParent)
{
	local int Score;

	//Extra points / tiebreaker for knock back actions since these frequently lead to death
	if (PossibleParent.Metadata.VisualizeActor == Metadata.VisualizeActor &&
		PossibleParent.IsA('X2Action_Knockback'))
	{
		Score += 2;
	}

	return Score;
}

protected function bool DoWaitUntilNotified()
{
	return bWaitUntilNotified;
}

simulated state Executing
{	

Begin:
	StopAllPreviousRunningActions(Unit);

	Unit.SetForceVisibility(eForceVisible);

	//Ensure Time Dilation is full speed
	VisualizationMgr.SetInterruptionSloMoFactor(Metadata.VisualizeActor, 1.0f);

	Unit.PreDeathRotation = UnitPawn.Rotation;

	//Death might already have been played by X2Actions_Knockback.
	if (!UnitPawn.bPlayedDeath)
	{
		Unit.OnDeath(m_kDamageType, XGUnit(DamageDealer));

		AnimationName = ComputeAnimationToPlay();

		UnitPawn.SetFinalRagdoll(true);
		UnitPawn.TearOffMomentum = vHitDir; //Use archaic Unreal values for great justice	
		UnitPawn.PlayDying(none, UnitPawn.GetHeadshotLocation(), AnimationName, Destination);
	}

	//Since we have a unit dying, update the music if necessary
	`XTACTICALSOUNDMGR.EvaluateTacticalMusicState();

	Unit.GotoState('Dead');

	if( bDoOverrideAnim )
	{
		// Turn off new animation playing
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	}

	while( DoWaitUntilNotified() && !IsTimedOut() )
	{
		Sleep(0.0f);
	}

	CompleteAction();
}

DefaultProperties
{	
	InputEventIDs.Add( "Visualizer_EffectApplied" )
	InputEventIDs.Add( "Visualizer_Knockback" )
	bDoOverrideAnim=false
	bWaitUntilNotified=false
}
