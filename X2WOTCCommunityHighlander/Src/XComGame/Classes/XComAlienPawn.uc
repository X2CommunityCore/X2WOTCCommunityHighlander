class XComAlienPawn extends XComUnitPawn;

// Issue #275, unprivate
var() /*privatewrite*/ XComCharacterVoice   Voice;

/** If true the weapon should play the weapon fragmentation effect when this character dies */
var() bool m_bShouldWeaponExplodeOnDeath;

// did the unit generated a death explosion -tsmith 
var protectedwrite bool                 m_bDeathExploded;

var const init string WeaponFragmentEffectName;

replication 
{
	if(bNetDirty && Role == ROLE_Authority)
		m_bDeathExploded;
}

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	if (Voice != none && Voice.CurrentVoiceBank == none)
	{
		Voice.StreamNextVoiceBank();
	}
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	super.PostInitAnimTree(SkelComp);
	OnPostInitAnimTree();
}

simulated function OnPostInitAnimTree()
{
	//Overridden depending on state
}



// This function is triggered from an animation's AnimNotify_Script from the Death animation.  (Also Drone's Overload anim)
function DeathExplosion()
{
	/*  jbouscher - REFACTORING CHARACTERS ... character templates should get a DeathExplosionAbility field
	local XGUnit kUnit;
	kUnit = XGUnit(GetGameUnit());

	// NOTE: if we ever add any sort of non-gameplay affecting code (graphics, ui, etc.) we will need to make 
	// this function simulated and Role check sections of code that impact gameplay such as the actual explosion damage generation.  -tsmith 

	`Log("XComAlienPawn DeathExplosion triggered!");
	// Some units explode their grenade when they die.  Pause a second, then explode. // reusing for poison explosions.
	
	if ( kUnit.GetCharacter().m_kChar.iType == 'Drone' ||
		`GAMECORE.CharacterHasProperty( kUnit.GetCharacter().m_kChar.iType, eCP_DeathExplosion ) )
	{
		m_bDeathExploded = true;
		Explode(kUnit);
	}
	*/
}

simulated event bool RestoreAnimSetsToDefault()
{
	Mesh.AnimSets.Length = 0;

	return super.RestoreAnimSetsToDefault();
}

//------------------------------------------------------------------------------------------------
// This function is triggered from an animation's AnimNotify_Script from the Death animation.
simulated function MeshSwap()
{
	`Log("XComAlienPawn MeshSwap triggered!");
}
//------------------------------------------------------------------------------------------------
reliable client function UnitSpeak( Name nEvent )
{
	if (Voice != none)
	{
		Voice.PlaySoundForEvent(nEvent, self);
	}
	else
	{
		`log(self.Name$".UnitSpeak: Missing voice on" @ self.Name,, 'DevSound');
	}
}

function SpawnWeaponSelfDestructFX()
{
	if (Weapon != none)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem(DynamicLoadObject(WeaponFragmentEffectName, class'ParticleSystem')), Weapon.Mesh.Bounds.Origin, Weapon.Mesh.Rotation);
		Weapon.Mesh.SetHidden(true);
	}
}

/** Overriden for XComAlienPawn to handle any weapon(s) that should be thrown on death */
function ThrowWeaponOnDeath()
{
	local XComWeapon kWeapon;
	kWeapon = XComWeapon(Weapon);

	if (kWeapon != none && m_bShouldWeaponExplodeOnDeath)
	{
		// (BSG:mwinfield,2012.03.16) Per Steve Jameson, when a Sectoid dies set timer func to make weapon self-destruct two seconds later
		//SetTimer(2.0f, false, 'SpawnWeaponSelfDestructFX', Self);
	}

	super.ThrowWeaponOnDeath();
}

simulated function RotateInPlace(int Dir);

function PlayHQIdleAnim(optional name OverrideAnimName, optional bool bCapture = false, optional bool bIgnoreInjuredAnim = false)
{
	local CustomAnimParams PlayAnimParams;

	if (bPhotoboothPawn) return;

	if (OverrideAnimName != '')
	{
		PlayAnimParams.AnimName = OverrideAnimName;
	}
	else
	{
		PlayAnimParams.AnimName = 'NO_IdleGunDwn'; //Ccombat idle
	}

	PlayAnimParams.Looping = true;
	PlayAnimParams.PlayRate = class'XComIdleAnimationStateMachine'.static.GetNextIdleRate();
	RestoreAnimSetsToDefault();
	AnimTreeController.PlayFullBodyDynamicAnim(PlayAnimParams);
}

simulated function UpdateMeshRenderChannels(RenderChannelContainer RenderChannels)
{
	super.UpdateMeshRenderChannels(RenderChannels);

	UpdateMeshAttachmentRenderChannels(Mesh, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kTorsoComponent, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kArmsMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kLegsMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kHelmetMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kDecoKitMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kEyeMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kTeethMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kBeardMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kUpperFacialMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kLowerFacialMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kHairMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kThighsMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kShinsMC, RenderChannels);
	UpdateMeshAttachmentRenderChannels(m_kTorsoDecoMC, RenderChannels);
}

state CharacterCustomization
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		
		bCanFly=true; // Allows the unit to use PHYS_Flying, so as not to fall through the ground when he's floating
		bCollideWorld=false; // In strategy, all character placement is faked, no collision
		SetPhysics(PHYS_Flying);
		SetUpdateSkelWhenNotRendered(true);		
	}

	simulated function OnPostInitAnimTree()
	{	
		SetTimer(0.03f, false, nameof(PlayHQIdleAnim));
	}

	simulated function RotateInPlace(int Dir)
	{
		local rotator SoldierRot;
		SoldierRot = Rotation;
		SoldierRot.Pitch = 0;
		SoldierRot.Roll = 0;
		SoldierRot.Yaw += 45.0f * class'Object'.const.DegToUnrRot * 0.33f * Dir;
		SetDesiredRotation(SoldierRot);
	}
begin:
	PlayHQIdleAnim();
}

state CharacterLoadout extends CharacterCustomization
{
	// No specialized functionality for the character loadout screens as of right now
}

defaultproperties
{
	WeaponFragmentEffectName = "FX_WP_PlasmaShared.P_Weapon_Fragmenting"
	m_bShouldWeaponExplodeOnDeath = true
}
