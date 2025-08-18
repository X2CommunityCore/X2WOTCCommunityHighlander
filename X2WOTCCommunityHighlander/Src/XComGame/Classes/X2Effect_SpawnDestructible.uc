class X2Effect_SpawnDestructible extends X2Effect_Persistent
	native(Core);

var() string DestructibleArchetype;
var() bool bDestroyOnRemoval;	//	destroy the destructible actor when the effect is removed
var Texture2D TargetingIcon;
var bool bTargetableBySpawnedTeamOnly;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SourceUnit;
	local XComGameState_Destructible DestructibleState;

	SourceUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(SourceUnit != none);

	DestructibleState = class'XComDestructibleActor'.static.SpawnDynamicGameStateDestructible( DestructibleArchetype, 
							ApplyEffectParameters.AbilityInputContext.TargetLocations[0], SourceUnit.GetTeam(), NewGameState );

	DestructibleState.OnlyAllowTargetWithEnemiesInTheBlastRadius = false;
	DestructibleState.bTargetableBySpawnedTeamOnly = bTargetableBySpawnedTeamOnly;

	NewEffectState.CreatedObjectReference = DestructibleState.GetReference();
	NewEffectState.ApplyEffectParameters.ItemStateObjectRef = DestructibleState.GetReference();
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XComDestructibleActor DestructibleInstance;
	local XComGameState_Destructible DestructibleState;
	local ParticleSystemComponent PSC;

	super.AddX2ActionsForVisualization( VisualizeGameState, ActionMetadata, EffectApplyResult );

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Destructible', DestructibleState)
	{
		break;
	}
	`assert(DestructibleState != none);

	DestructibleInstance = XComDestructibleActor( DestructibleState.FindOrCreateVisualizer( ) );

	DestructibleInstance.SetPrimitiveHidden(true);

	// these effects aren't hidden when hiding the destructible. hide them directly.
	foreach DestructibleInstance.m_arrRemovePSCOnDeath(PSC)
	{
		if (PSC != none && PSC.bIsActive)
			PSC.SetHidden(true);
	}

	`XCOMHISTORY.SetVisualizer(DestructibleState.ObjectID, DestructibleInstance);
	DestructibleInstance.SetObjectIDFromState(DestructibleState);
	if( TargetingIcon != None )
	{
		DestructibleInstance.TargetingIcon = TargetingIcon;
	}
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Destructible DestructibleState;
	local XComDestructibleActor Actor;
	local XComGameState_EnvironmentDamage NewDamageEvent;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	if (bDestroyOnRemoval)
	{
		DestructibleState = XComGameState_Destructible(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
		if (DestructibleState == none)
			DestructibleState = XComGameState_Destructible(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
		if (DestructibleState == none)
			return;

		Actor = XComDestructibleActor(DestructibleState.GetVisualizer());
		NewDamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));
		NewDamageEvent.DEBUG_SourceCodeLocation = "UC: X2Effect_SpawnDestructible:OnEffectRemoved()";
		NewDamageEvent.HitLocation = Actor.Location;
		NewDamageEvent.DamageSource.ObjectID = ApplyEffectParameters.SourceStateObjectRef.ObjectID;
		NewDamageEvent.DestroyedActors.AddItem(Actor.GetActorId());
		NewDamageEvent.DamageTiles.AddItem(DestructibleState.TileLocation);

		DestructibleState.ForceDestroyed(NewGameState, NewDamageEvent);
	}
}

DefaultProperties
{
	bDestroyOnRemoval = false
}