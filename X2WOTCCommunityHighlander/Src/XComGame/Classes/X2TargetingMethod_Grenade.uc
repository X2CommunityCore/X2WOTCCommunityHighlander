//---------------------------------------------------------------------------------------
//  FILE:    X2TargetingMethod_Grenade.uc
//  AUTHOR:  David Burchanowski  --  8/04/2014
//  PURPOSE: Targeting method for throwing grenades and other such bouncy objects
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_Grenade extends X2TargetingMethod
	native(Core);

var protected XCom3DCursor Cursor;
var protected XComPrecomputedPath GrenadePath;
var protected transient XComEmitter ExplosionEmitter;
var protected bool bRestrictToSquadsightRange;
var protected XComGameState_Player AssociatedPlayerState;

var bool SnapToTile;

function Init(AvailableAction InAction, int NewTargetIndex)
{
	local XComGameStateHistory History;
	local XComWeapon WeaponEntity;
	local PrecomputedPathData WeaponPrecomputedPathData;
	local float TargetingRange;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityTemplate AbilityTemplate;

	super.Init(InAction, NewTargetIndex);

	History = `XCOMHISTORY;

	AssociatedPlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
	`assert(AssociatedPlayerState != none);

	// determine our targeting range
	AbilityTemplate = Ability.GetMyTemplate();
	TargetingRange = Ability.GetAbilityCursorRangeMeters();

	// lock the cursor to that range
	Cursor = `Cursor;
	Cursor.m_fMaxChainedDistance = `METERSTOUNITS(TargetingRange);

	// set the cursor location to itself to make sure the chain distance updates
	Cursor.CursorSetLocation(Cursor.GetCursorFeetLocation(), false, true); 

	CursorTarget = X2AbilityTarget_Cursor(Ability.GetMyTemplate().AbilityTargetStyle);
	if (CursorTarget != none)
		bRestrictToSquadsightRange = CursorTarget.bRestrictToSquadsightRange;

	GetGrenadeWeaponInfo(WeaponEntity, WeaponPrecomputedPathData);
	// Tutorial Band-aid #2 - Should look at a proper fix for this
	if (WeaponEntity.m_kPawn == none)
	{
		WeaponEntity.m_kPawn = FiringUnit.GetPawn();
	}

	if (UseGrenadePath())
	{
		GrenadePath = `PRECOMPUTEDPATH;
		GrenadePath.ClearOverrideTargetLocation(); // Clear this flag in case the grenade target location was locked.
		GrenadePath.ActivatePath(WeaponEntity, FiringUnit.GetTeam(), WeaponPrecomputedPathData);
		if( X2TargetingMethod_MECMicroMissile(self) != none )
		{
			//Explicit firing socket name for the Micro Missile, which is defaulted to gun_fire
			GrenadePath.SetFiringFromSocketPosition(name("gun_fire"));
		}
	}	

	if (!AbilityTemplate.SkipRenderOfTargetingTemplate)
	{
		// setup the blast emitter
		ExplosionEmitter = `BATTLE.spawn(class'XComEmitter');
		if(AbilityIsOffensive)
		{
			ExplosionEmitter.SetTemplate(ParticleSystem(DynamicLoadObject("UI_Range.Particles.BlastRadius_Shpere", class'ParticleSystem')));
		}
		else
		{
			ExplosionEmitter.SetTemplate(ParticleSystem(DynamicLoadObject("UI_Range.Particles.BlastRadius_Shpere_Neutral", class'ParticleSystem')));
		}
		
		ExplosionEmitter.LifeSpan = 60 * 60 * 24 * 7; // never die (or at least take a week to do so)
	}
}

function GetGrenadeWeaponInfo(out XComWeapon WeaponEntity, out PrecomputedPathData WeaponPrecomputedPathData)
{
	local XComGameState_Item WeaponItem;
	local X2WeaponTemplate WeaponTemplate;
	local XGWeapon WeaponVisualizer;

	WeaponItem = Ability.GetSourceWeapon();
	WeaponTemplate = X2WeaponTemplate(WeaponItem.GetMyTemplate());
	WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());

	// Tutorial Band-aid fix for missing visualizer due to cheat GiveItem
	if (WeaponVisualizer == none)
	{
		class'XGItem'.static.CreateVisualizer(WeaponItem);
		WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());
		WeaponEntity = XComWeapon(WeaponVisualizer.CreateEntity(WeaponItem));

		if (WeaponEntity != none)
		{
			WeaponEntity.m_kPawn = FiringUnit.GetPawn();
		}
	}
	else
	{
		WeaponEntity = WeaponVisualizer.GetEntity();
	}

	WeaponPrecomputedPathData = WeaponTemplate.WeaponPrecomputedPathData;
}

function Canceled()
{
	super.Canceled();

	// unlock the 3d cursor
	Cursor.m_fMaxChainedDistance = -1;

	// clean up the ui
	ExplosionEmitter.Destroy();
	if (UseGrenadePath())
	{
		GrenadePath.ClearPathGraphics();
	}	
	ClearTargetedActors();
}

function Committed()
{
	Canceled();
}

simulated protected function Vector GetSplashRadiusCenter( bool SkipTileSnap = false )
{
	local vector Center;
	local TTile SnapTile;

	if (UseGrenadePath())
		Center = GrenadePath.GetEndPosition();
	else
		Center = Cursor.GetCursorFeetLocation();

	if (SnapToTile && !SkipTileSnap)
	{
		SnapTile = `XWORLD.GetTileCoordinatesFromPosition( Center );
		
		// keep moving down until we find a floor tile.
		while ((SnapTile.Z >= 0) && !`XWORLD.GetFloorPositionForTile( SnapTile, Center ))
		{
			--SnapTile.Z;
		}
	}

	return Center;
}

simulated protected function DrawSplashRadius()
{
	local Vector Center;
	local float Radius;
	local LinearColor CylinderColor;

	Center = GetSplashRadiusCenter( true );

	Radius = Ability.GetAbilityRadius();
	
	/*
	if (!bValid || (m_bTargetMustBeWithinCursorRange && (fTest >= fRestrictedRange) )) {
		CylinderColor = MakeLinearColor(1, 0.2, 0.2, 0.2);
	} else if (m_iSplashHitsFriendliesCache > 0 || m_iSplashHitsFriendlyDestructibleCache > 0) {
		CylinderColor = MakeLinearColor(1, 0.81, 0.22, 0.2);
	} else {
		CylinderColor = MakeLinearColor(0.2, 0.8, 1, 0.2);
	}
	*/

	if( (ExplosionEmitter != none) && (Center != ExplosionEmitter.Location))
	{
		ExplosionEmitter.SetLocation(Center); // Set initial location of emitter
		ExplosionEmitter.SetDrawScale(Radius / 48.0f);
		ExplosionEmitter.SetRotation( rot(0,0,1) );

		if( !ExplosionEmitter.ParticleSystemComponent.bIsActive )
		{
			ExplosionEmitter.ParticleSystemComponent.ActivateSystem();			
		}

		ExplosionEmitter.ParticleSystemComponent.SetMICVectorParameter(0, Name("RadiusColor"), CylinderColor);
		ExplosionEmitter.ParticleSystemComponent.SetMICVectorParameter(1, Name("RadiusColor"), CylinderColor);
	}
}

function Update(float DeltaTime)
{
	local array<Actor> CurrentlyMarkedTargets;
	local vector NewTargetLocation;
	local array<TTile> Tiles;

	NewTargetLocation = GetSplashRadiusCenter();

	if(NewTargetLocation != CachedTargetLocation)
	{		
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForTargetsOnTiles(CurrentlyMarkedTargets, Tiles);  // Issue #669
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
		DrawAOETiles(Tiles);
	}
	DrawSplashRadius( );

	super.Update(DeltaTime);
}

// Start Issue #669
/// HL-Docs: ref:GrenadesRequiringUnitsOnTargetedTiles
// Removes any marked targets that aren't on one of the given tiles. This is
// most useful for grenades that apply an effect to the world where a target
// must be on an affected tile to get any buffs or penalties associated with
// that effect (for example smoke grenades). In certain situations, the
// targeting will highlight a unit that won't be affected by world effects
// like smoke.
function CheckForTargetsOnTiles(out array<Actor> CurrentlyMarkedTargets, array<TTile>Tiles)
{
	local Actor TargetActor;
	local XGUnit TargetUnit;
	local XComGameState_Unit kUnitState;
	local array<Actor> TargetsToRemove;

	if (class'CHHelpers'.default.GrenadesRequiringUnitsOnTargetedTiles.Find(Ability.GetSourceWeapon().GetMyTemplateName()) == INDEX_NONE)
	{
		return;
	}

	foreach CurrentlyMarkedTargets(TargetActor)
	{
		TargetUnit = XGUnit(TargetActor);
		if (TargetUnit != none )
		{
			kUnitState = TargetUnit.GetVisualizedGameState();
			if (kUnitState != none)
			{
				if (class'Helpers'.static.FindTileInList(kUnitState.TileLocation, Tiles) == INDEX_NONE)
				{
					TargetsToRemove.AddItem (TargetActor);
				}
			}
		}
	}
	foreach TargetsToRemove (TargetActor)
	{
		CurrentlyMarkedTargets.RemoveItem (TargetActor);
	}
}
// End Issue #669

function GetTargetLocations(out array<Vector> TargetLocations)
{
	TargetLocations.Length = 0;
	TargetLocations.AddItem(GetSplashRadiusCenter());
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	local TTile TestLoc;
	if (TargetLocations.Length == 1)
	{
		if (bRestrictToSquadsightRange)
		{
			TestLoc = `XWORLD.GetTileCoordinatesFromPosition(TargetLocations[0]);
			if (!class'X2TacticalVisibilityHelpers'.static.CanSquadSeeLocation(AssociatedPlayerState.ObjectID, TestLoc))
				return 'AA_NotVisible';
		}
		return 'AA_Success';
	}
	return 'AA_NoTargets';
}

function int GetTargetIndex()
{
	return 0;
}

function bool GetAdditionalTargets(out AvailableTarget AdditionalTargets)
{
	Ability.GatherAdditionalAbilityTargetsForLocation(GetSplashRadiusCenter(), AdditionalTargets);
	return true;
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	Focus = GetSplashRadiusCenter();
	return true;
}

static function bool UseGrenadePath() { return true; }

static function name GetProjectileTimingStyle()
{
	if( UseGrenadePath() )
	{
		return default.ProjectileTimingStyle;
	}

	return '';
}

static function name GetOrdnanceType()
{
	if( UseGrenadePath() )
	{
		return default.OrdnanceTypeName;
	}

	return '';
}

defaultproperties
{
	SnapToTile = true;
	ProjectileTimingStyle="Timing_Grenade"
	OrdnanceTypeName="Ordnance_Grenade"
}