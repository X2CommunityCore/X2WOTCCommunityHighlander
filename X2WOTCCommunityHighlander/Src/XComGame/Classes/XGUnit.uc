class XGUnit extends XGUnitNativeBase
	implements(X2VisualizationMgrObserverInterface)
	dependson(XGGameData, XComGameState_BaseObject)
	config(GameCore);

const RECENT_VOICE_TIME = 10.0f;

// FLAGS
var bool                m_bSuppressing;
var bool                m_bSuppressingArea;
var bool				m_bHideUIUnitFlag;
// TO CLEAN UP------------------------------------
var privatewrite bool   m_bCanOpenWindowsAndDoors;
var XComAlienPod        m_kPod;

var int                 m_iCriticalWoundCounter;

var repnotify XGPlayer	   m_kPlayer;
var repnotify Actor        m_kReplicatedOwner;

var Rotator PreDeathRotation;

// Config values
var private const config string SelectionBoxMeshName;
var private const config string SelectionBoxAllyMaterialName;
var private const config string SelectionBoxEnemyMaterialName;

// UI ----------------------------------------------------------
var privatewrite repnotify EDiscState m_eDiscState;
var privatewrite StaticMeshComponent  m_kDiscMesh;
var privatewrite StaticMeshComponent  m_kSelectionBoxMesh;
var privatewrite MaterialInterface		m_kSelectionBoxMeshAllyMaterial;
var privatewrite MaterialInterface		m_kSelectionBoxMeshEnemyMaterial;
var privatewrite bool                   m_bShowMouseOverDisc;
// --------------------------------------------------------------

// CONSTANT COMBAT-----------------------------------------------
var XGUnit              m_kForceConstantCombatTarget;
// --------------------------------------------------------------

var array<Name>                 m_arrRecentSpeech;
var float                       m_fElapsedRecentSpeech;
var config array<name>          m_CivilianVoiceOverWhitelist;
var float                       m_fTimeSinceLastUnitSpeak;


// ------------------------------------------------------------------

// Panic data
var ForceFeedbackWaveform       m_kPanicFF;
var ForceFeedbackWaveform       m_arrPanicFF[2];
var privatewrite repnotify bool m_bPushStatePanicking;
var privatewrite bool           m_bGotoStateInactiveFromStatePanicked;
var bool                        m_bActivateAfterPanickedComplete;       // in the rare event this unit replicates to clients as Active unit before the panic completes it needs to activate itself upon panic completion. -tsmith 
var privatewrite bool           m_bPanicMoveFinished;
var privatewrite bool           m_bServerPanicMoveFinished;
var bool                        bForcePanicMove;                        // Set when taking Flame damage - forces a unit to choose to mMaterialInstanceTimeVaryingove when panicking
var int                         m_iUnitLoadoutID;                       // used to map this instanced unit to the loadout it was created from. -tsmith 
var XGUnit                      m_kDamageDealer;                        // keep track of last attacker for critical woundings.
var bool                        m_bDeathExplosionDone;
var bool                        m_bClickActivated;                      //  was the unit activated through user input mouse click?
var bool                        m_bSkipTrackMovement;                   //  allow camera manager to not track the unit for short distance moves (mouse movement only)

//== Cursor resources ==
var MaterialInstanceTimeVarying	    Cursor_UnitSelectEnterFB_MaterialInterface;
var MaterialInstanceTimeVarying		Cursor_UnitSelectExitFB_MaterialInterface;
var MaterialInstanceTimeVarying		Cursor_UnitSelectIdle_MITV;
var MaterialInterface				Cursor_UnitSelectTargeted_MIC;
var MaterialInterface				UnitCursor_UnitSelect_Gold;
var MaterialInstanceConstant		UnitCursor_UnitSelect_Green;
var MaterialInterface				UnitCursor_UnitSelect_Orange;
var MaterialInterface				UnitCursor_UnitSelect_Purple;
var MaterialInstanceTimeVarying		UnitCursor_UnitSelect_RED;
var MaterialInterface				UnitCursor_UnitCursor_Flying;
var MaterialInstanceConstant		UnitCursor_FlyingEffectMaterial;
//==

var TAppearance                 m_SavedAppearance;
var EUnitPawn_OpenCloseState    m_ePawnOpenCloseState;

var bool                        m_bStrangleLoopStarted;
var localized string            m_strUnitStunned;
var localized string            m_strNewAbilityAlienDevice;
var localized string            m_strHoverNoLand;
var localized string            m_strHoverLanded;
var localized string            m_strHoverNoLandAI;
var localized string            m_strHoverLandedAI;
var localized string            m_strReloading;
var localized string            m_strRift;
var localized string            m_sExplosiveDamageDisplay;
var localized string            m_sCriticalHitDamageDisplay;

struct ReplicateWeaponSwapData
{
	var XGWeapon    m_kSwitchFromWeapon;
	var XGWeapon    m_kSwitchToWeapon;
};

var repnotify  ReplicateWeaponSwapData   m_kReplicateWeaponSwapData;

/** only used in multiplayer, 'fixes' some bugs where units run of the map, this allows us to force kill them */
var transient bool m_bMPForceDeathOnMassiveTakeDamage;

var transient bool m_bDisableTickForDeadUnit;

struct ReplicateActivatePerkData
{
	var string          m_ePerkType;
	var XGUnit          m_kPrimaryTarget;
	var XGUnit          m_arrAdditionalTargets[16];     //  @TODO remove
};

var privatewrite repnotify repretry ReplicateActivatePerkData   m_kReplicateActivatePerkData;
var privatewrite repnotify  string							    m_eReplicateDeactivatePerkType;

var bool m_bSubsystem;
var EIdleTurretState IdleTurretState;


var transient Actor TempFOWViewer;


replication
{
	if(bNetOwner && bNetInitial && Role == ROLE_Authority)
		m_kReplicatedOwner;

	if( bNetDirty && Role == ROLE_Authority )
		m_eDiscState, 			    		
		m_kPlayer, 
		m_kForceConstantCombatTarget,
		m_bSuppressing,
		m_bSuppressingArea,							
		m_iCriticalWoundCounter,
		m_bCanOpenWindowsAndDoors,		
		m_bPushStatePanicking,
		m_bGotoStateInactiveFromStatePanicked,
		m_bServerPanicMoveFinished,		
		m_bDeathExplosionDone,		
		m_kReplicateActivatePerkData,
		m_eReplicateDeactivatePerkType;

	if(!bNetOwner && Role == ROLE_Authority)
		m_kReplicateWeaponSwapData;
}



/*
 *  We sample on the server prior to the beginning of each turn
 *  a sequence of random numbers to be used for synchronization
 *  between client / server for things such as damage, crit chance,
 *  etc. This requires the client to buffer the data and parse
 *  the correct RandomSample locally that'd line up with the latest
 *  one from the server. if there is a desync the game should 
 *  be at worst returning "0" for random
 * 
 */

/*
 *  NETWORK: SHARED
 * 
 */

/*
simulated function PrintSampleData(RandomSample sRandData)
{
	local int Iindex;
	local string msg;

	for(Iindex = 0; Iindex < ERandomSample_MAX; Iindex++)
	{
		msg $= String(sRandData.sampleData[Iindex]) $ " | ";
	}

	`log("PrintSampleData:"@ msg);	
}

/*  
 *  AddRandomSampleToBuffer: Adds latest known sample on XGUnit regardless
 *  of authority to the array and culls sample history older than 1 sample ago
 */
simulated function AddRandomSampleToBuffer()
{
	if (WorldInfo.NetMode == NM_StandAlone || Role < ROLE_Authority)
	{
		m_bufferRandomSamples.AddItem(m_randomSample);
		//PrintSampleData(m_randomSample);
		while(m_bufferRandomSamples.Length > 2) // we store previous turn's sample in buffer at most..
		{
		//	`log("Culling sample used for turn:"@m_bufferRandomSamples[0].m_turnSample);
			m_bufferRandomSamples.RemoveItem(m_bufferRandomSamples[0]);
		}
	}
}

/*
 *  Return a number between 0 and maxRand using Random Sample Data
 */
simulated function int GetSyncRand(int randType, float maxRand)
{
	return Round(float(GetRandomSample(randType)) * maxRand / 100.0); 
}

// Use this function using ERandomSample enum
// to index into the latest sample array to get the latest
// "Random Number" synchronised with the server
simulated function int GetRandomSample(int WantedData)
{
	local int iIndex;

	if (Role == Role_Authority && WorldInfo.NetMode != NM_Standalone)
	{
		// on a dedicated/listen, use latest data as we have
		// use latest sample data
		return m_randomSample.sampleData[WantedData];
	}

	for (iIndex = 0; iIndex < m_bufferRandomSamples.Length; iIndex++)
	{
		if (m_bufferRandomSamples[iIndex].m_turnSample == `BATTLE.m_iTurn)
			return m_bufferRandomSamples[iIndex].sampleData[WantedData];
	}

	`log("GetLatestRandomSample: could not find latest random sample!\nWas looking for sample #" $ `BATTLE.m_iTurn); 
	return 0;
}
*/
/*
 *  NETWORK: SERVER ONLY
 * 
 */

/*
 *  GenerateRandomSample: Call this for each xgunit on beginning of turn
 *  NOTE: all samples must be known by all players so no direct replication to owning client
 */
/*function GenerateRandomSample()
{
	local int iIndex;

	m_randomSample.m_turnSample = `BATTLE.m_iTurn;

	for (iIndex = 0; iIndex < ERandomSample_MAX; iIndex++)
	{
		m_randomSample.sampleData[iIndex] = `SYNC_RAND(100); 
		//`log("Generated: m_randomSample.sampleData[" $ GetEnum(enum'ERandomSample', iIndex) $ "]:"@m_randomSample.sampleData[iIndex]);
	}
	
	bForceNetUpdate = true;

	AddRandomSampleToBuffer(); // only applicable on SP, MP this is handled by repnotify
}*/

/*
 *  END SHINANIGANS
 * 
 */

delegate fnPtr(XGUnit kUnit);

function SubsystemInit(XComGameState_Unit kUnitState)
{
	if (kUnitState.m_bSubsystem)
	{
		m_bSubsystem = true;
		AttachPawnToOwnerMesh();
	}
}

function AttachPawnToOwnerMesh( )
{
	local XGUnit kOwnerUnit;
	local name SocketName;
	local SkeletalMeshComponent OwnerMesh, PawnMesh;
	local XComGameState_Unit kUnitState;
	if (m_kPawn != None)
	{
		kUnitState = GetVisualizedGameState();
		SocketName = kUnitState.GetComponentSocket();
		if (SocketName != '')
		{
			kOwnerUnit = XGUnit(`XCOMHISTORY.GetVisualizer(kUnitState.OwningObjectId));
			OwnerMesh = kOwnerUnit.GetPawn().Mesh;
			PawnMesh = m_kPawn.Mesh;
			if (OwnerMesh != None)
			{
				OwnerMesh.AttachComponentToSocket(PawnMesh, SocketName);
			}
		}
		else
		{
			m_kPawn.HideMainPawnMesh(); // Temporary- while using duplicate ACV assets for treads and cannon, hide the component acvs.
		}
		// Hiding all ACV subsystem meshes for now since the ACV isn't quite set up properly yet.
		m_kPawn.HideMainPawnMesh(); // Temporary- while using duplicate ACV assets for treads and cannon, hide the component acvs.
	}
}

simulated function ApplyToSubsystems( delegate<fnPtr> FunctionPtr )
{
	local XGUnit kSubsystem;
	local XComGameState_Unit UnitState;
	local int ComponentID;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	UnitState = GetVisualizedGameState();
	foreach UnitState.ComponentObjectIds(ComponentID)
	{
		kSubsystem = XGUnit(History.GetVisualizer(ComponentID));
		if (kSubsystem != None && kSubsystem != self)
		{
			FunctionPtr(kSubsystem);
		}
	}
}

// for subsystems.  And turret bases.
function SyncLocation( XGUnit kUnit=self )
{
	local X2Actor_TurretBase TurretBaseActor;
	local vector BaseLocation;
	local Rotator BaseRotation;
	local XComUnitPawn kPawn;
	kPawn = kUnit.GetPawn();
	if( kUnit != self )
	{
		kPawn.SetLocation(GetLocation());
		kPawn.SetRotation(kPawn.Rotation);
	}
	kUnit.ApplyToSubsystems(SyncLocation);
	if( IsTurret() )
	{
		kPawn.ReattachMesh(); // Update mesh before pulling socket info.
		kPawn.Mesh.GetSocketWorldLocationAndRotation('turret_base', BaseLocation, BaseRotation);
		foreach ChildActors(class'X2Actor_TurretBase', TurretBaseActor)
		{
			TurretBaseActor.UpdateLocationAndRotation(BaseLocation, BaseRotation);
		}
	}
}
//------------------------------------------------------------------------------------------------

simulated event ReplicatedEvent(name VarName)
{
	if(VarName == 'm_eDiscState')
	{
		RefreshUnitDisc();
	}
	else if(VarName == 'm_kReplicatedOwner')
	{
	}
	else if(VarName == 'm_kPlayer')
	{
		m_kPlayerNativeBase = m_kPlayer;
	}
	else if(VarName == 'm_bPushStatePanicking')
	{
		`log(self $ "::" $ GetStateName() $ "::" $ GetFuncName() @ SafeGetCharacterFullName() @ VarName $ "=" $ m_bPushStatePanicking, true, 'XCom_Net');
		if(m_bPushStatePanicking && !IsInState('Panicking'))
		{
			GotoState('Panicking');
		}
	}
	else if(VarName == 'm_kReplicateWeaponSwapData')
	{
		//`log(self $ "::" $ GetFuncName() @ VarName @ "SwitchFromWeapon=" $ m_kReplicateWeaponSwapData.m_kSwitchFromWeapon $ ", SwitchToWeapon=" $ m_kReplicateWeaponSwapData.m_kSwitchToWeapon $ ", ActiveWeapon=" $ GetInventory().GetActiveWeapon(), true, 'XCom_Net);
		if(GetInventory().GetActiveWeapon() != m_kReplicateWeaponSwapData.m_kSwitchToWeapon)
		{
			CycleWeapons();
		}
	}

	super.ReplicatedEvent(VarName);
}

simulated function bool IsInitialReplicationComplete()
{
	local bool bIsInitialReplicationComplete;

	bIsInitialReplicationComplete = m_kPlayer != none && super.IsInitialReplicationComplete();
	
	return bIsInitialReplicationComplete;
}

function bool DestroyOnBadLocation()
{
	local Vector vActualPos, vTargetPos;

	vTargetPos = Location;
	vActualPos = m_kPawn.Location;
	vTargetPos.Z = 0;
	vActualPos.Z = 0;
	// Ensure this unit got spawned where we wanted it to. (Fix for origin spawn.)
	if ( VSizeSq(vActualPos - vTargetPos) > Square(`METERSTOUNITS(0.5f)) )
	{
		Uninit();
		return true;
	}

	return false;
}

function bool Init( XGPlayer kPlayer, XGSquad kSquad, XComGameState_Unit UnitState, optional bool bDestroyOnBadLocation = false, optional bool bSnapToGround=true, optional const XComGameState_Unit ReanimatedFromUnit = None)
{
	local Vector NewWorldSpaceOffset;
	local XComUnitPawn PawnArchetype;
	local XComHumanPawn HumanPawn;
	local CharacterPoolManager CharacterPoolMgr;

	super.Init(kPlayer, kSquad, UnitState, bDestroyOnBadLocation);	

	m_kReplicatedOwner = Owner;

//	AddStatModifiers( UnitState.aStats );
	// Shields by default are set to zero hp.
//	m_aCurrentStats[eStat_ShieldHP] = 0;

	m_kPlayer = kPlayer;

	m_bCanOpenWindowsAndDoors = true;//m_kCharacter.m_bCanOpenWindowsAndDoors;  jbouscher - REFACTORING CHARACTERS

	PawnArchetype = UnitState.GetPawnArchetype(, ReanimatedFromUnit);
		
	if(UnitState.UnitSize > 1)
	{
		NewWorldSpaceOffset.X = class'XComWorldData'.const.WORLD_HalfStepSize * (UnitState.UnitSize - 1);
		NewWorldSpaceOffset.Y = class'XComWorldData'.const.WORLD_HalfStepSize * (UnitState.UnitSize - 1);
		SetWorldSpaceOffset(NewWorldSpaceOffset);
	}

	if( PawnArchetype == None )
	{
		`RedScreen("Character Template '" $ UnitState.GetMyTemplateName() $ "' does not have a valid PawnArchetype specified: " $ UnitState.GetMyTemplate().GetPawnArchetypeString(UnitState));
	}

	SpawnPawn(PawnArchetype, bSnapToGround);

	if (m_kPawn == none)
		return false;

	HumanPawn = XComHumanPawn(m_kPawn);
	if(HumanPawn != none)
	{
		// This is a last chance check whether the body parts selected for this character are available / valid and replace them if not.
		CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
		CharacterPoolMgr.FixAppearanceOfInvalidAttributes(UnitState.kAppearance);

		HumanPawn.SetAppearance(UnitState.kAppearance);
	}

	SubsystemInit(UnitState);

	if (bDestroyOnBadLocation)
	{
		if (DestroyOnBadLocation())
			return false;
	}
 
	kSquad.AddUnit( self );

	InitBehavior();	

	// Initialize Zombie Chryssalid egg - can be destroyed by fire or explosions.
	/*  jbouscher - REFACTORING CHARACTERS
	if (m_kCharacter.m_kChar.iType == 'Zombie')
	{
		m_bHasChryssalidEgg = true;
	}
	*/

	SetDiscState(eDS_None);
	if (IdleStateMachine == none)
	{
		//SpawnIdleStateMachine(UnitState);
		IdleStateMachine = Spawn(class'XComIdleAnimationStateMachine', self);
		IdleStateMachine.Initialize(self);
	}
	else
	{
		IdleStateMachine.Resume();
	}

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	return true;
}

//------------------------------------------------------------------------------------------------
/**
 * Called when all presentation layers have been initialized
 */
simulated function NotifyPresentationLayersInitialized()
{
	super.NotifyPresentationLayersInitialized();
}

simulated function PlayerController GetOwningPlayerController()
{
	return m_kPlayer.m_kPlayerController;
}

simulated function ApplyLoadoutFromGameState(XComGameState_Unit UnitState, XComGameState FullGameState)
{
	local StateObjectReference ItemReference;
	local XComGameState_Item ItemState;
	local XGInventoryItem kItemToEquip, kItem;
	local XGInventory kInventory;
	local XComWeapon ItemWeapon;
	local bool bMultipleItems;
	// Variables for Issue #188
	local XGWeapon /*HeavyWeaponVisualizer,*/ ItemVis;
	local array<EInventorySlot> PresEquipSlots;
	local array<CHItemSlot> SlotTemplates;
	local CHItemSlot SlotIter;
	local EInventorySlot Slot;

	// Variable for Issue #885
	local array<EInventorySlot> PresEquipMultiSlots;

	kInventory = GetInventory();
	if( kInventory == none )
	{
		kInventory = Spawn(class'XGInventory', Owner);
		SetInventory(kInventory);
		kInventory.PostInit();
	}

	foreach UnitState.InventoryItems(ItemReference)
	{
		ItemState = None;
		if (FullGameState != None)
			ItemState = XComGameState_Item(FullGameState.GetGameStateForObjectID(ItemReference.ObjectID));

		if ( ItemState == None)
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemReference.ObjectID)); //If a None is passed in, get all their items from the history

		if( ItemState != none && ItemState.ObjectID > 0 ) //ApplyLoadoutFromGameState can be called with a game state that does not contain all a unit's items. Ignore these.
		{
			kItem = XGInventoryItem(ItemState.GetVisualizer());	
			if(kItem == none)
			{
				class'XGItem'.static.CreateVisualizer(ItemState);
				kItem = XGInventoryItem(ItemState.GetVisualizer());
			}

			if( kItem != none && (kItem.m_kOwner == none || kItem.m_kEntity == none) )
			{
				kItem.m_kOwner = self;
				kItem.m_kEntity = kItem.CreateEntity(ItemState);

				ItemWeapon = XComWeapon(kItem.m_kEntity);
				if( ItemWeapon != none )
				{
					ItemWeapon.m_kPawn = m_kPawn;
				}
			}

			if( kItem != none && kItem.m_kEntity != none )
			{
				bMultipleItems = ItemState.ItemLocation == eSlot_RearBackPack;
				kInventory.AddItem(kItem, ItemState.ItemLocation, bMultipleItems);
			}
		}
	}

	ItemState = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon);
	if (ItemState != none)
	{
		kInventory.m_kPrimaryWeapon = XGWeapon(ItemState.GetVisualizer());
	}
	ItemState = UnitState.GetItemInSlot(eInvSlot_SecondaryWeapon);
	if (ItemState != none)
	{
		kInventory.m_kSecondaryWeapon = XGWeapon(ItemState.GetVisualizer());
		kInventory.m_kSecondaryWeapon.m_eSlot = kInventory.m_kSecondaryWeapon.m_eReserveLocation;
		kInventory.PresEquip(kInventory.m_kSecondaryWeapon, true);
	}

	// Issue #118 Start, squash Heavy+Tertiary to Septenary into a single loop
	PresEquipSlots.AddItem(eInvSlot_HeavyWeapon);
	PresEquipSlots.AddItem(eInvSlot_TertiaryWeapon);
	PresEquipSlots.AddItem(eInvSlot_QuaternaryWeapon);
	PresEquipSlots.AddItem(eInvSlot_QuinaryWeapon);
	PresEquipSlots.AddItem(eInvSlot_SenaryWeapon);
	PresEquipSlots.AddItem(eInvSlot_SeptenaryWeapon);

	SlotTemplates = class'CHItemSlot'.static.GetAllSlotTemplates();
	foreach SlotTemplates(SlotIter)
	{
		if (SlotIter.NeedsPresEquip)
		{
			// Start Issue #885
			if (SlotIter.IsMultiItemSlot)
			{
				PresEquipMultiSlots.AddItem(SlotIter.InvSlot);
			}// End Issue #885
			else
			{
				PresEquipSlots.AddItem(SlotIter.InvSlot);
			}
		}
	}
	foreach PresEquipSlots(Slot)
	{
		ItemState = UnitState.GetItemInSlot(Slot);
		if (ItemState != none)
		{
			ItemVis = XGWeapon(ItemState.GetVisualizer());
			kInventory.PresEquip(ItemVis, true);
		}
	}
	// Issue #118 End
	
	// Issue #885 Start
	PresEquipMultiSlots.AddItem(eInvSlot_Utility);
	PresEquipMultiSlotItems(UnitState, FullGameState, kInventory, PresEquipMultiSlots);
	// Issue #885 End

	if (kInventory.m_kPrimaryWeapon != none)
		kItemToEquip = kInventory.m_kPrimaryWeapon;
	else if (kInventory.m_kSecondaryWeapon != none)
		kItemToEquip = kInventory.m_kSecondaryWeapon;
	
	if (kItemToEquip != none)
	{
		kInventory.EquipItem( kItemToEquip, true, true );
	}
}

// Issue #885 Start
simulated private function PresEquipMultiSlotItems(XComGameState_Unit UnitState, XComGameState FullGameState, XGInventory kInventory, array<EInventorySlot> PresEquipMultiSlots)
{
	local array<XComGameState_Item> ItemStates;
	local XComGameState_Item        ItemState;
	local CHHelpers                 CHHelpersObj;
	local XGWeapon                  ItemVis;
	local EInventorySlot            PresEquipMultiSlot;

	CHHelpersObj = class'CHHelpers'.static.GetCDO();
	if (CHHelpersObj == none)
	{
		return;
	}

	foreach PresEquipMultiSlots(PresEquipMultiSlot)
	{
		ItemStates = UnitState.GetAllItemsInSlot(PresEquipMultiSlot,,, true);
		foreach ItemStates(ItemState)
		{
			if (CHHelpersObj.ShouldDisplayMultiSlotItemInTactical(UnitState, ItemState, PresEquipMultiSlot, self, FullGameState))
			{
				ItemVis = XGWeapon(ItemState.GetVisualizer());
				kInventory.PresEquip(ItemVis, true);
			}
		}
	}
}
// Issue #885 End

//-------------------------------------------------------------------
// Swap between any equippable weapons on this unit
simulated function bool SwapEquip()
{
	local XGWeapon kSwitchFromWeapon;
	local XGWeapon kSwitchToWeapon;

	if( GetInventory().GetActiveWeapon() == GetInventory().m_kPrimaryWeapon )
	{
		if( GetInventory().m_kSecondaryWeapon != none )
		{
			if( true )
			{
				kSwitchFromWeapon = GetInventory().m_kPrimaryWeapon;
				kSwitchToWeapon = GetInventory().m_kSecondaryWeapon;
				Equip( GetInventory().m_kSecondaryWeapon );
			}
		}
	}
	else if( GetInventory().GetActiveWeapon() == GetInventory().m_kSecondaryWeapon )
	{
		if( GetInventory().m_kPrimaryWeapon != none )
		{
			if( true )
			{
				kSwitchFromWeapon = GetInventory().m_kSecondaryWeapon;
				kSwitchToWeapon = GetInventory().m_kPrimaryWeapon;
				Equip( GetInventory().m_kPrimaryWeapon);
			}
		}
	}

	// can a unit ever have a none active weapon? we arent check none-ness of it because that seems to be possible. -tsmith 
	if(Role == ROLE_Authority && kSwitchToWeapon != none)
	{
		m_kReplicateWeaponSwapData.m_kSwitchFromWeapon = kSwitchFromWeapon;
		m_kReplicateWeaponSwapData.m_kSwitchToWeapon = kSwitchToWeapon;
		return true;
	}
	else
	{
		return false;
	}
}

simulated function bool CycleWeapons()
{
	return false;
}

reliable server function ServerCycleWeapons()
{
	CycleWeapons();
}

simulated function EquipWeaponUI( XGWeapon newWeapon )
{
	if(newWeapon == none)
	{
		if(m_kPlayer.m_kPlayerController != none)
		{
			m_kPlayer.m_kPlayerController.ClientFailedSwitchWeapon();
		}
		return;
	}

	Equip(newWeapon);
	if(Role == ROLE_Authority)
	{
		m_kReplicateWeaponSwapData.m_kSwitchFromWeapon = GetInventory().GetActiveWeapon();
		m_kReplicateWeaponSwapData.m_kSwitchToWeapon = newWeapon;
	}
	else
	{
		ServerEquip(newWeapon);
	}
}

simulated function ConstantCombatSuppress(bool bSuppress, XGUnit kTarget)
{
	m_bSuppressing = bSuppress && kTarget != none;

	if (m_bSuppressing)
	{
		m_kForceConstantCombatTarget = kTarget;
		kTarget.m_kConstantCombatUnitTargetingMe = self;
	}
	else 
	{
		if( m_kForceConstantCombatTarget != none )
		{
			m_kForceConstantCombatTarget.m_kConstantCombatUnitTargetingMe = none;
			//RAM - Constant Combat 
			//`CONSTANTCOMBAT.SchedulePeek(m_kForceConstantCombatTarget, 0, self); // Tell the old suppressed unit to immediately peek
		}
		m_kForceConstantCombatTarget = none;
	}
}

simulated function ConstantCombatSuppressArea(bool bSuppressArea)
{
	m_bSuppressingArea = bSuppressArea;
}

//------------------------------------------------------------------------------------------------
function bool IsValidCoverType( XComCoverPoint kCover, bool bIgnoreFlight=false )
{
	// TODO@gameplay: This function was really weird before, this should be functionally
	// equivalent, and simpler
	return (`IS_VALID_COVER(kCover)) ? CanUseCover(bIgnoreFlight) : false;
}
//------------------------------------------------------------------------------------------------
function float GetMaxPathDistance()
{
	local XComGameState_Unit Unit;
	Unit = GetVisualizedGameState();
	return `METERSTOUNITS(Unit.GetCurrentStat(eStat_Mobility) * class'X2CharacterTemplateManager'.default.StandardActionsPerTurn);
}
//------------------------------------------------------------------------------------------------
function bool IsFlightPoint(XComCoverPoint kCover)
{
	// AI-generated flight points have no cover, with Z value == grid index.
	return kCover.Flags == 0 && kCover.X == 0 && kCover.Y == 0 && kCover.Z > 0;
}
//------------------------------------------------------------------------------------------------
simulated function bool IsAboveFloorTile( Vector vLoc, int iMinTiles=1)
{
	local TTile kFloorTile, kTile;

	`XWORLD.GetFloorTileForPosition(vLoc, kFloorTile, true);
	kTile = `XWORLD.GetTileCoordinatesFromPosition(vLoc);
	if (kTile.Z - kFloorTile.Z > iMinTiles)
		return true;
	return false;
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
delegate bool CoverValidator( vector vCoverLoc );
//------------------------------------------------------------------------------------------------
function bool DefaultCoverValidator( vector vCoverLoc )
{
	return true;
}

//------------------------------------------------------------------------------------------------
function bool GetBestDestination(out vector Destination, delegate<CoverValidator> dCoverValid=DefaultCoverValidator)
{
	local vector CoverLocation;
	local float ClosestDistanceSquared;
	local float DistanceSquared;
	
	// since the cover locations are a member, manually call the cache update function to ensure they are correct
	m_kReachableTilesCache.UpdateTileCacheIfNeeded();

	ClosestDistanceSquared = -1;

	// iterate over all destinations, grabbing the closest valid one
	foreach m_kReachableTilesCache.CoverDestinations(CoverLocation)
	{
		if(dCoverValid(CoverLocation))
		{
			DistanceSquared = VSizeSq(CoverLocation - GetLocation());
			if(DistanceSquared < ClosestDistanceSquared || ClosestDistanceSquared < 0)
			{
				ClosestDistanceSquared = DistanceSquared;
				Destination = CoverLocation;
			}
		}
	}

	`ASSERT(DestinationIsReachable(Destination));
	return ClosestDistanceSquared > 0;
}
//------------------------------------------------------------------------------------------------
simulated function bool DestinationIsReachable(vector vLocation)
{
	local XComWorldData WorldData;
	local TTile Tile;

	WorldData = `XWORLD;
	Tile = WorldData.GetTileCoordinatesFromPosition(vLocation);
	return m_kReachableTilesCache.IsTileReachable(Tile);
}

//------------------------------------------------------------------------------------------------
// Return a random valid point away from a 'danger point', i.e. for running away from grenades & flamethrowers.
function vector GetRunAwayDestinationFromPoint( vector vDangerPoint, float fMinDist )
{
	local Vector vDir, vDest;
	local float fMaxDist;

	fMaxDist = GetMaxPathDistance();
	if (m_eTeam==eTeam_Neutral)
		fMaxDist *= 0.3f;
	vDir = GetLocation() - vDangerPoint; // direction away from grenade.
	vDest = m_kPlayer.GetRandomValidPoint(self, GetLocation(), fMaxDist, fMinDist, vDir);
	return vDest;
}

//------------------------------------------------------------------------------------------------
function vector RunForCover( vector vDangerLoc, delegate<CoverValidator> dCoverValid=DefaultCoverValidator, int iMinDist=128 )
{
	local Vector vCover;
	local TTile DangerTile, CoverTile;
	local XComWorldData XWorld;	

	if (GetBestDestination(vCover, dCoverValid))
	{
		XWorld = `XWORLD;
		DangerTile = XWorld.GetTileCoordinatesFromPosition(vDangerLoc);
		CoverTile = XWorld.GetTileCoordinatesFromPosition(vCover);

		if (DangerTile != CoverTile)
		{
			// The unit is not already in the tile for cover
			MoveToLocation(vCover);
		}
	}
	else
	{
		`Log("XGUnit::RunForCover() ERROR - No cover found!  Selecting random point away from danger");
		vCover = GetRunAwayDestinationFromPoint( vDangerLoc, `METERSTOUNITS(3));
		MoveToLocation(vCover);
	}

	return vCover;
}

//------------------------------------------------------------------------------------------------
function bool MoveToLocation(Vector vLoc, optional XComGameState_Unit VisualizeUnitState)
{
	local array<TTile> Path;
	local TTile Tile;
	local XComGameState_Unit UnitState;

	if (m_kBehavior!= None)
	{
		m_kBehavior.m_vDebugDestination = vLoc;
		if (XGAIBehavior_Civilian(m_kBehavior) != none)
		{
			XGAIBehavior_Civilian(m_kBehavior).m_iMoveTimeStart = WorldInfo.TimeSeconds;
		}
	}

	Tile = `XWorld.GetTileCoordinatesFromPosition(vLoc);
	m_kReachableTilesCache.BuildPathToTile(Tile, Path);
	if( Path.Length == 0 ) //If the tile cache couldn't make a path, try a direct A*
	{
		if (VisualizeUnitState == none)
			UnitState = GetVisualizedGameState();
		else
			UnitState = VisualizeUnitState;
		class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, Tile, Path);
	}

	if(Path.Length == 0)
	{
		`LOG("XGUnit::MoveToLocation Failed to find a path to destination! "$Location@"to"@vLoc);
		return false;
	}

	// MILLER - We no longer need to spawn move actions.  Use PerformPath instead.
	XComTacticalController(GetALocalPlayerController()).GameStateMoveUnitSingle(self, Path);

	return true;
}

// This function causes the unit to disappear and is considered removed from the battlefield
function ExitLevel()
{
	SetVisible(false);
	
	HideCoverIcon();

	// causes the unit to not be included as a valid target, selectable, or constant combat
	DEPRECATED_m_bOffTheBattlefield = true; 
}

function InitBehavior()
{
	m_kPlayer.InitBehavior(self, GetVisualizedGameState());
}

function DestroyBehavior()
{
	if (m_kBehavior != none)
	{
		m_kBehavior.Destroy();
		m_kBehavior = none;
	}
}

function Uninit()
{
	GotoState('UninitComplete');

	// cleanup things that are replicated here -tsmith 
	if (m_kPawn != None)
	{
		if (m_kPawn.Controller != none)
		m_kPawn.Controller.Destroy();

		`XWORLD.UnregisterActor(m_kPawn);

		m_kPawn.Destroy();
		m_kPawn = None;
	}

	if (m_kBehavior != none)
	{
		m_kBehavior.Destroy();
		m_kBehavior = none;
	}	
	if (IdleStateMachine != none)
	{
		IdleStateMachine.Destroy();
		IdleStateMachine = none;
	}
}

simulated event Destroyed()
{
	if( IdleStateMachine != none )
	{
		IdleStateMachine.Destroy();
		IdleStateMachine = none;
	}	
}

function SpawnPawn(XComUnitPawn PawnArchetype, optional bool bSnapToGround=true, optional bool bLoaded=false)
{
	local Vector vRotDir;
	
	`assert(PawnArchetype != none);

	// NOTE: This can fail "because of collision at the spawn location" 
	// NOTE: the Owner that is passed is overwritten inside m_kPawn::SpawnDefaultController so dont rely on the pawn's owner to be our owner. -tsmith 
	m_kPawn = Spawn( PawnArchetype.Class, owner,,Location,Rotation, PawnArchetype, true, m_eTeam );	
	m_kPawn.ObjectID = ObjectID;
	SetBase(m_kPawn);
	m_kPawn.SetWorldSpaceOffset(WorldSpaceOffset);

	// If we spawned something, make sure it's an XComUnitPawn
	if (m_kPawn != none)
	{
		m_kPawn.SpawnDefaultController();
		m_kPawn.SetGameUnit(self);
		m_kPawn.HealthMax = GetUnitMaxHP();
		m_kPawn.Health = m_kPawn.HealthMax;

		if (bSnapToGround)
		{
			SnapToGround();
		}

		vRotDir = vector(m_kPawn.Rotation);
		vRotDir.Z = 0;
		m_kPawn.FocalPoint = m_kPawn.Location + vRotDir*128;
		m_kPawn.SetPhysics(PHYS_None);
		m_kPawn.SetVisibleToTeams( m_kPlayer.m_eTeam );
				
		`XWORLD.RegisterActor(m_kPawn, self.GetSightRadius() );
	}
}

simulated function bool SnapToGround(optional float Distance = 1024.0f) //The param is ignored, and simply used to match the signature of the base class method
{
	local vector vHitLoc;
	local bool bSnapped;

	vHitLoc = m_kPawn.Location;
	vHitLoc.Z = GetDesiredZForLocation(m_kPawn.Location);
	
	bSnapped = true;

	m_kPawn.bCollideWorld = false;
	m_kPawn.SetLocation(vHitLoc);
	m_kPawn.bCollideWorld = true;

	m_kPawn.fFootIKTimeLeft = 10.0f;	

	return bSnapped;
}

simulated function bool IsAlien_CheckByCharType()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
	if (UnitState != none)
	{
		return UnitState.IsAlien();
	}
	
	return false;
}

//------------------------------------------------------------------------------------------------
// Originally set up for Alien Pods. 
// kSubObject is another collision object that may get hit in the trace, which will return true if hit.  
// For the pods this is a loot object.
// Expanded for use in testing visibility of artifacts.
simulated function bool CanSeeActor( actor kObject, float fHeight=0, optional actor kSubObject=None )
{
	if (kObject == none)
		return false;

	return false;
}

//------------------------------------------------------------------------------------------------
simulated function int GetFloor()
{
	return GetPawn().GetCurrentFloor();
}

function bool IsInLowCover()
{
	local int i;
	local XComCoverPoint CoverHandle;

	CoverHandle = GetCoverPoint();

	if (CanUseCover() && `IS_VALID_COVER(CoverHandle))
	{
		for (i = 0; i < `COVER_DIR_COUNT(); i++)
		{
			if (`IS_LOW_COVER(CoverHandle,`IDX_TO_DIR(i)))
				return true;
		}
	}

	return false;
}

simulated function UpdateInteractClaim()
{
	PRES().GetActionIconMgr().UpdateInteractIcons();
}

//------------------------------------------------------------------------------------------------
simulated function bool ShouldCrouchForCover()
{
	return m_eCoverState == eCS_LowFront || m_eCoverState == eCS_LowBack;
}
//------------------------------------------------------------------------------------------------

simulated function ShowMouseOverDisc( optional bool bShow = true )
{
	if( m_bShowMouseOverDisc != bShow )
	{
		m_bShowMouseOverDisc = bShow;
		RefreshUnitDisc();
	}
}

simulated function ShowSelectionBox(optional bool bShow = true, optional bool bEnemy = false)
{
	local Vector MeshTranslation;
	MeshTranslation.Z = -Location.Z + `XWORLD.GetFloorZForPosition(Location) + class'XComPathingPawn'.default.PathHeightOffset;

	m_kSelectionBoxMesh.SetHidden(!bShow);
	m_kSelectionBoxMesh.SetTranslation(MeshTranslation);
	m_kSelectionBoxMesh.SetMaterial(0, bEnemy ? m_kSelectionBoxMeshEnemyMaterial : m_kSelectionBoxMeshAllyMaterial);
}

simulated function SetDiscState( EDiscState eState )
{
	if( m_eDiscState != eState )
	{
		// When a unit is selected hide the mouse over disc. This logic is here and not
		// in RefreshUnitDisc because once a unit has been selected it is ok to mouse
		// over it and get the mouse over disc again.
		if( eState == eDS_Good )
			m_bShowMouseOverDisc = false;

		//`log("Disc State for Unit " @ self @ " Dist State: " @ eState);

		m_eDiscState = eState;
		RefreshUnitDisc();
	}
}

simulated function RefreshUnitDisc()
{
	local vector MeshScale;
	local XComGameState_Unit UnitState;

	if( PRES().USE_UNIT_RING 
		|| PRES().ScreenStack.DebugHardHide
		|| PRES().m_bIsDebugHideSelectedUnitDisc 
		|| `BATTLE.m_kLevel.IsCinematic()
		|| m_bHideUIUnitFlag)
	{
		m_kDiscMesh.SetHidden(true);
		return;
	}

	if( IsVisible() )
	{
		if( PRES().Get2DMovie().DebugHardHide )
		{
			HideUnitDisc();
		}
		else if ( m_bShowMouseOverDisc )
		{
			m_kDiscMesh.SetHidden(true);
		}
		else
		{
			if (m_eDiscState == eDS_None)
			{
				HideUnitDisc();
			}
			else if (m_eDiscState == eDS_Good)
			{
				m_kDiscMesh.SetHidden(false);
				Cursor_UnitSelectEnterFB_MaterialInterface.Restart();
				m_kDiscMesh.SetMaterial(0, Cursor_UnitSelectEnterFB_MaterialInterface);
			}
			else if (m_eDiscState == eDS_Ready)
			{
				HideUnitDisc();
				m_kDiscMesh.SetMaterial(1, MaterialInterface'UnitCursor.Materials.MInst_UnitSelect_DarkBlue' );
			}
			else if (m_eDiscState == eDS_Red)
			{
				m_kDiscMesh.SetHidden(false);
				m_kDiscMesh.SetMaterial(0, UnitCursor_UnitSelect_RED );
			}
			else if (m_eDiscState == eDS_ReactionAlien)
			{
				m_kDiscMesh.SetHidden(false);
				m_kDiscMesh.SetMaterial(0, UnitCursor_UnitSelect_Orange );
			}
			else if (m_eDiscState == eDS_ReactionHuman)
			{
				m_kDiscMesh.SetHidden(false);
				m_kDiscMesh.SetMaterial(0, UnitCursor_UnitSelect_Gold );
			}
			else if ( m_eDiscState == eDS_AttackTarget)
			{
				m_kDiscMesh.SetHidden(false);
				m_kDiscMesh.SetMaterial(0, Cursor_UnitSelectTargeted_MIC);
			}
			else // if (m_eDiscState == eDS_Bad)
			{
				HideUnitDisc();
			}

			if (m_kPawn.CollisionComponent != none)
			{
				m_kDiscMesh.SetTranslation(vect(0,0,-1) * (m_kPawn.CollisionComponent.Bounds.BoxExtent.Z - class'XComPathingPawn'.default.PathHeightOffset + 1));
			}

			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
			if(UnitState != none)
			{
				MeshScale.X = UnitState.UnitSize;
				MeshScale.Y = UnitState.UnitSize;
				MeshScale.Z = 1.0f;
				m_kDiscMesh.SetScale3D(MeshScale);
			}

			m_kDiscMesh.SetAbsolute(false, true, false); // don't rotate the mesh with the unit, keep it oriented to the grid
		}
	}
}

simulated private function HideUnitDisc()
{
	local MaterialInterface DiscMaterial;

	DiscMaterial = m_kDiscMesh.GetMaterial(0);
	if( DiscMaterial == Cursor_UnitSelectEnterFB_MaterialInterface ||
		DiscMaterial == Cursor_UnitSelectIdle_MITV )
	{
		// Play the disc exit animation
		// There should only ever be one unit playing this animation
		Cursor_UnitSelectExitFB_MaterialInterface.Restart();
		m_kDiscMesh.SetMaterial(0, Cursor_UnitSelectExitFB_MaterialInterface);
	}
	else
	{
		m_kDiscMesh.SetHidden(true); // don't animate out, just hide
	}
}

function bool IsRecentPlayedSpeech(Name nCharSpeech)
{
	local Name speech;

	foreach m_arrRecentSpeech(speech)
	{
		if (speech == nCharSpeech)
		{
			return true;
		}
	}

	return false;
}

function UnitSpeakMultiKill()
{
	UnitSpeak('MultipleTargetsKilled');
}

function UnitSpeakKill()
{
	UnitSpeak('TargetKilled');
}

function UnitSpeakMissed()
{
	UnitSpeak('TargetMissed');
}
simulated function DelayStunSpeech()
{
	UnitSpeak( 'StunnedAlien' );
}
simulated function DelayStunFailSpeech()
{
	UnitSpeak( 'AlienNotStunned' );
}
simulated function DelayPromotionSound()
{
	PlaySound( SoundCue(DynamicLoadObject("SoundFX.SoldierPromotedCue", class'SoundCue')), true );
}

simulated function DelayKillSting()
{
	PlaySound( SoundCue(DynamicLoadObject("SoundAmbience.DeathStingCue", class'SoundCue')), true );
}

function DelaySpeechFlanked()
{
	UnitSpeak('SoldierFlanked');
}

function DelaySpeechRocketScatter()
{
	UnitSpeak( 'RocketScatter' );
}

function DelaySpeechDoubleTap()
{
	//UnitSpeak( eCharSpeech_DoubleTap );
}

function DelaySpeechExplosion()
{
	UnitSpeak('Explosion');
}

function DelayRocketFire()
{
	UnitSpeak('FireRocket');
}

function DelayAlienHiddenMovementSounds()
{
	UnitSpeak('HiddenMovement');
	UnitSpeak('HiddenMovementVox');
}

function DelayLowAmmo()
{
	UnitSpeak('LowAmmo');
}

function DelayNoAmmo()
{
	UnitSpeak('AmmoOut');
}

function private bool AllowEnableSoldierSpeech(Name nCharSpeech)
{
	local bool InTutorial;

	InTutorial = `REPLAY.bInTutorial;

	// since we don't have matching voice banks for non-english languages, don't play any soldier speech in the tutorial
	if( InTutorial && GetLanguage() != "INT" )
		return false;

	if (GetTeam() == eTeam_Resistance)
	{
		if (nCharSpeech == 'DeathScream')
		{
			return true;
		}

		// disable Resistance fighters speak for anything except Death
		return false;
	}

	// These guys always need to play regardless of UI option (They aren't speech)
	if (nCharSpeech == 'TakingDamage' || nCharSpeech == 'DeathScream' || nCharSpeech == 'PanickedBreathing')
		return true;

	if( InTutorial && GetTeam() == eTeam_XCom) // disable all other xcom soldier barks in the tutorial for the XCom team in english
		return false;

	return `XPROFILESETTINGS.Data.m_bEnableSoldierSpeech;
}

function UnitSpeak(Name nCharSpeech, bool bDeadUnitSound = false)
{
	local int iIndex;
	local bool bCivilianSpeechAllowed;
	local XComGameState_Unit GameStateUnit;
	local name nPersonalitySpeech;
	local name nHushedSpeech;

	if ((!bDeadUnitSound && !IsAliveAndWell()) || m_kPawn == none)
		return;


	GameStateUnit = GetVisualizedGameState();
	if (GameStateUnit.IsPanicked())
	{
		if (!(nCharSpeech == 'PanickedBreathing' || nCharSpeech == 'PanicScream' || nCharSpeech == 'Panic' /*|| nCharSpeech == 'TakingDamage'*/ || nCharSpeech == 'CriticallyWounded' || nCharSpeech == 'DeathScream'))
		{
			// Only allowed to play panicked sounds if panicked
			return;
		}
	}

	if (GameStateUnit.IsMindControlled())
	{
		if (!(nCharSpeech == 'SoldierControlled'))
		{
			// Only allowed to play panicked sounds if panicked
			return;
		}
	}

	// don't play if this is actually just a mimic beacon hologram unit
	// In the future this should be handled on the pawn
	if( (GameStateUnit.GetMyTemplateName() == 'MimicBeacon') ||
		(GameStateUnit.GhostSourceUnit.ObjectID > 0) )
	{
		return;
	}

	// don't play this voice if the unit recently spewed it
	if (IsRecentPlayedSpeech(nCharSpeech))
		return;

	// check if the user doesn't want any soldier speech
	if (!AllowEnableSoldierSpeech(nCharSpeech))
		return;

	// some narrative moment is playing or preparing to play
	if (`PRES.m_kNarrativeUIMgr.AnyActiveConversations())
		return;

	// alien types dont speak other than hidden movement (can happen to mind controlled units)
	if (IsAlien_CheckByCharType() && nCharSpeech != 'HiddenMovement' && nCharSpeech != 'HiddenMovementVox' && nCharSpeech != 'PanicScream')
		return;

	// civilians are only allowed to say VO cues that are whitelisted
	if (IsCivilian())
	{
		bCivilianSpeechAllowed = false;

		for (iIndex = 0; iIndex < m_CivilianVoiceOverWhitelist.Length; iIndex++)
		{
			if ( m_CivilianVoiceOverWhitelist[ iIndex ] == nCharSpeech )
			{
				bCivilianSpeechAllowed = true;
				break;
			}
		}

		if ( !bCivilianSpeechAllowed )
			return;
	}


	// mark that we played this voice
	if (nCharSpeech != 'TakingDamage' && nCharSpeech != 'TargetKilled' && nCharSpeech != 'TakingFire' && nCharSpeech != 'HiddenMovement' && nCharSpeech != 'HiddenMovementVox')
	{
		m_arrRecentSpeech.AddItem(nCharSpeech);
	}

	nHushedSpeech = MaybeUseHushedSpeechInstead(nCharSpeech);
	nPersonalitySpeech = MaybeAddPersonalityToSpeech(nCharSpeech);

	if (nHushedSpeech != '')
		m_kPawn.UnitSpeak(nHushedSpeech);
	else if (nPersonalitySpeech != '')
		m_kPawn.UnitSpeak(nPersonalitySpeech);
	else
		m_kPawn.UnitSpeak(nCharSpeech);

	m_fTimeSinceLastUnitSpeak = 0.0f;
}

function name MaybeUseHushedSpeechInstead(Name nCharSpeech)
{
	local XComGameState_Unit GameStateUnit;

	GameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	if ( GameStateUnit.IsConcealed() )
	{
		switch ( nCharSpeech )
		{
			case 'dashing':          return 'dashing_w';
			case 'moving':           return 'moving_w';
			case 'overwatch':        return 'overwatch_w';
			case 'orderconfirm':     return 'orderconfirm_w';
			case 'objectivesighted': return 'objectivesighted_w';
			case 'civiliansighted':  return 'civiliansighted_w';
			case 'vipsighted':       return 'vipsighted_w';
		}
	}

	return '';
}

function name MaybeAddPersonalityToSpeech(Name nCharSpeech)
{
	local XComGameState_Unit GameStateUnit;
	local name nPersonality;
	// Variables for Issue #317
	local int Pidx, Sidx, Variant;

	GameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));

	/// HL-Docs: ref:Bugfixes; issue:215
	/// Units are now allowed to have personality speech (affected by personality) even below "Veteran" rank
	if ( GameStateUnit == none /*|| !GameStateUnit.IsVeteran()*/ ) // Issue #215
	{
		return '';
	}

	nPersonality = GameStateUnit.GetPersonalityTemplate().DataName;
	// Start Issue #317
	/// HL-Docs: feature:PersonalitySpeech; issue:317; tags:tactical,customization
	/// The soldier speech system allows soldiers to use different voicelines
	/// in some situations based on their attitude. For example, an "Intense" soldier 
	/// will voice react differently to killing an enemy than a "Twitchy" one.
	///
	/// This behavior was hardcoded in the base game. Highlander replaces the original implementation
	/// with the `PersonalitySpeech` config array that takes values from `XComGame.ini` config file.
	/// This potentailly allows mods to replace the original personality speech patterns,
	/// as well as add new patterns for new attitudes, if a mod manages to add any.
	/// 
	/// Example entry for the "By The Book" attitude:
	///```ini
	///[XComGame.CHHelpers]
	///+PersonalitySpeech=( Personality="Personality_ByTheBook", \\
	/// CharSpeeches = ( \\
	///  (CharSpeech="Moving", PersonalityVariant=("Moving_BY_THE_BOOK")), \\
	///  (CharSpeech="TargetKilled", PersonalityVariant=("TargetKilled_BY_THE_BOOK")), \\
	///  (CharSpeech="Panic", PersonalityVariant=("Panic_BY_THE_BOOK")), \\
	///  (CharSpeech="SoldierVIP", PersonalityVariant=("SoldierVIP_BY_THE_BOOK")), \\
	///  (CharSpeech="UsefulVIP", PersonalityVariant=("UsefulVIP_BY_THE_BOOK")), \\
	///  (CharSpeech="GenericVIP", PersonalityVariant=("GenericVIP_BY_THE_BOOK")), \\
	///  (CharSpeech="HostileVIP", PersonalityVariant=("HostileVIP_BY_THE_BOOK")), \\
	///  (CharSpeech="LootCaptured", PersonalityVariant=("LootCaptured_BY_THE_BOOK")), \\
	///  (CharSpeech="HackWorkstation", PersonalityVariant=("HackWorkstation_BY_THE_BOOK")), \\
	///  (CharSpeech="LootSpotted", PersonalityVariant=("LootSpotted_BY_THE_BOOK")), \\
	///  (CharSpeech="TargetEliminated", PersonalityVariant=("TargetEliminated_BY_THE_BOOK")), \\
	///  (CharSpeech="PickingUpBody", PersonalityVariant=("PickingUpBody_BY_THE_BOOK")) \\
	/// ))
	///```
	/// Note: only one `PersonalitySpeech` entry per attitude will be taken into account, any others will be ignored.
	/// If your mod wants to replace the original speech personality config with your own, 
	/// you should copy the original entry to their own config exactly as it appears in the Highlander, 
	/// and replace the `+` at the start of the entry with a `-`, which will remove the entry when your mod is loaded.
	/// Then you can specify your own config entry for that attitude below.
	Pidx=class'CHHelpers'.default.PersonalitySpeech.Find('Personality', nPersonality);
	if (Pidx != INDEX_NONE)
	{
		Sidx=class'CHHelpers'.default.PersonalitySpeech[Pidx].CharSpeeches.Find('CharSpeech', nCharSpeech);
		if (Sidx != INDEX_NONE)
		{
			Variant=Rand(class'CHHelpers'.default.PersonalitySpeech[Pidx].CharSpeeches[Sidx].PersonalityVariant.Length);
			return class'CHHelpers'.default.PersonalitySpeech[Pidx].CharSpeeches[Sidx].PersonalityVariant[Variant];
		}
	}
	/*
	switch ( nPersonality )
	{
		case 'Personality_ByTheBook':
			switch ( nCharSpeech )
			{
				case 'Moving':           return 'Moving_BY_THE_BOOK';
				case 'TargetKilled':     return 'TargetKilled_BY_THE_BOOK';
				case 'Panic':            return 'Panic_BY_THE_BOOK';
				case 'SoldierVIP':       return 'SoldierVIP_BY_THE_BOOK';
				case 'UsefulVIP':        return 'UsefulVIP_BY_THE_BOOK';
				case 'GenericVIP':       return 'GenericVIP_BY_THE_BOOK';
				case 'HostileVIP':       return 'HostileVIP_BY_THE_BOOK';
				case 'LootCaptured':     return 'LootCaptured_BY_THE_BOOK';
				case 'HackWorkstation':  return 'HackWorkstation_BY_THE_BOOK';
				case 'LootSpotted':      return 'LootSpotted_BY_THE_BOOK';
				case 'TargetEliminated': return 'TargetEliminated_BY_THE_BOOK';
				case 'PickingUpBody':    return 'PickingUpBody_BY_THE_BOOK';
			}
			break;
		case 'Personality_LaidBack':
			switch ( nCharSpeech )
			{
				case 'Moving':           return 'Moving_LAID_BACK';
				case 'TargetKilled':     return 'TargetKilled_LAID_BACK';
				case 'Panic':            return 'Panic_LAID_BACK';
				case 'SoldierVIP':       return 'SoldierVIP_LAID_BACK';
				case 'UsefulVIP':        return 'UsefulVIP_LAID_BACK';
				case 'GenericVIP':       return 'GenericVIP_LAID_BACK';
				case 'HostileVIP':       return 'HostileVIP_LAID_BACK';
				case 'LootCaptured':     return 'LootCaptured_LAID_BACK';
				case 'HackWorkstation':  return 'HackWorkstation_LAID_BACK';
				case 'LootSpotted':      return 'LootSpotted_LAID_BACK';
				case 'TargetEliminated': return 'TargetEliminated_LAID_BACK';
				case 'PickingUpBody':    return 'PickingUpBody_LAID_BACK';
			}
			break;
		case 'Personality_Twitchy':
			switch ( nCharSpeech )
			{
				case 'Moving':           return 'Moving_TWITCHY';
				case 'TargetKilled':     return 'TargetKilled_TWITCHY';
				case 'Panic':            return 'Panic_TWITCHY';
				case 'SoldierVIP':       return 'SoldierVIP_TWITCHY';
				case 'UsefulVIP':        return 'UsefulVIP_TWITCHY';
				case 'GenericVIP':       return 'GenericVIP_TWITCHY';
				case 'HostileVIP':       return 'HostileVIP_TWITCHY';
				case 'LootCaptured':     return 'LootCaptured_TWITCHY';
				case 'HackWorkstation':  return 'HackWorkstation_TWITCHY';
				case 'LootSpotted':      return 'LootSpotted_TWITCHY';
				case 'TargetEliminated': return 'TargetEliminated_TWITCHY';
				case 'PickingUpBody':    return 'PickingUpBody_TWITCHY';
			}
			break;
		case 'Personality_HappyGoLucky':
			switch ( nCharSpeech )
			{
				case 'Moving':           return 'Moving_HAPPY_GO_LUCKY';
				case 'TargetKilled':     return 'TargetKilled_HAPPY_GO_LUCKY';
				case 'Panic':            return 'Panic_HAPPY_GO_LUCKY';
				case 'SoldierVIP':       return 'SoldierVIP_HAPPY_GO_LUCKY';
				case 'UsefulVIP':        return 'UsefulVIP_HAPPY_GO_LUCKY';
				case 'GenericVIP':       return 'GenericVIP_HAPPY_GO_LUCKY';
				case 'HostileVIP':       return 'HostileVIP_HAPPY_GO_LUCKY';
				case 'LootCaptured':     return 'LootCaptured_HAPPY_GO_LUCKY';
				case 'HackWorkstation':  return 'HackWorkstation_HAPPY_GO_LUCKY';
				case 'LootSpotted':      return 'LootSpotted_HAPPY_GO_LUCKY';
				case 'TargetEliminated': return 'TargetEliminated_HAPPY_GO_LUCKY';
				case 'PickingUpBody':    return 'PickingUpBody_HAPPY_GO_LUCKY';
			}
			break;
		case 'Personality_HardLuck':
			switch ( nCharSpeech )
			{
				case 'Moving':           return 'Moving_HARD_LUCK';
				case 'TargetKilled':     return 'TargetKilled_HARD_LUCK';
				case 'Panic':            return 'Panic_HARD_LUCK';
				case 'SoldierVIP':       return 'SoldierVIP_HARD_LUCK';
				case 'UsefulVIP':        return 'UsefulVIP_HARD_LUCK';
				case 'GenericVIP':       return 'GenericVIP_HARD_LUCK';
				case 'HostileVIP':       return 'HostileVIP_HARD_LUCK';
				case 'LootCaptured':     return 'LootCaptured_HARD_LUCK';
				case 'HackWorkstation':  return 'HackWorkstation_HARD_LUCK';
				case 'LootSpotted':      return 'LootSpotted_HARD_LUCK';
				case 'TargetEliminated': return 'TargetEliminated_HARD_LUCK';
				case 'PickingUpBody':    return 'PickingUpBody_HARD_LUCK';
			}
			break;
		case 'Personality_Intense':
			switch ( nCharSpeech )
			{
				case 'Moving':           return 'Moving_INTENSE';
				case 'TargetKilled':     return 'TargetKilled_INTENSE';
				case 'Panic':            return 'Panic_INTENSE';
				case 'SoldierVIP':       return 'SoldierVIP_INTENSE';
				case 'UsefulVIP':        return 'UsefulVIP_INTENSE';
				case 'GenericVIP':       return 'GenericVIP_INTENSE';
				case 'HostileVIP':       return 'HostileVIP_INTENSE';
				case 'LootCaptured':     return 'LootCaptured_INTENSE';
				case 'HackWorkstation':  return 'HackWorkstation_INTENSE';
				case 'LootSpotted':      return 'LootSpotted_INTENSE';
				case 'TargetEliminated': return 'TargetEliminated_INTENSE';
				case 'PickingUpBody':    return 'PickingUpBody_INTENSE';
			}
			break;
	}
	*/
	// End Issue #317

	return '';
}

simulated event SetVisible(bool bVisible)
{
	m_kPawn.SetVisible(bVisible);
	super.SetVisible(bVisible);
}

simulated function UpdateLookAt()
{
	
}

function SetSquad( XGSquad kSquad )
{
	m_kSquad = kSquad;
}

simulated function XGSquad GetSquad()
{
	return XGSquad(m_kSquad);
}

simulated function XGPlayer GetPlayer()
{
	return m_kPlayer;
}

simulated function ETeam GetTeam()
{
	return GetPlayer().m_eTeam;
}

simulated function bool IsEnemy( XGUnit kUnit )
{
	return GetPlayer().IsEnemy( kUnit.GetPlayer() );
}

simulated function bool CheckUnitDelegate_IsMindMergeWhiplashDying(XGUnit kUnit)
{
	if (kUnit.IsMindMergeWhiplashDying())
		return true;
	else
		return false;
}

// MHU - We'll need some way to track delayed mindmerge death processing.
//       1. We're still alive
//       2. actionqueue contains mindmerge waiting for death.
simulated function bool IsMindMergeWhiplashDying()
{
	if(Role != ROLE_Authority)
	{
		return  IsAliveAndWell();
	}
}

simulated function bool IsMoving()
{
	return false;
}

simulated function bool IsHunkeredDown()
{
	return GetVisualizedGameState().IsHunkeredDown();
}

simulated function int GetOffense()
{
	return GetVisualizedGameState().GetCurrentStat(eStat_Offense);
}

simulated function int GetDefense()
{
	return GetVisualizedGameState().GetCurrentStat(eStat_Defense);
}

function UpdateEquipment()
{
	local XGInventory kInventory;
	local XGWeapon kWeapon;
	local int i;

	kInventory = GetInventory();
	if (kInventory != none)
	{
		for( i = 0; i < eSlot_Max; i++ )
		{
			kWeapon = XGWeapon(kInventory.GetItem( ELocation(i) ));

			if( kWeapon == none )
				continue;

		}
	}
}

simulated function BeginTurn( optional bool bLoadedFromCheckpoint = false )
{
	
}

function EndTurn()
{
	
}

//------------------------------------------------------------------------------------------------
simulated function bool CanMove()
{
	return true;
}

//------------------------------------------------------------------------------------------------
simulated function UpdateCiviliansInRange()
{
	
}

//------------------------------------------------------------------------------------------------
// MHU - Helper function to determine enemies in squad sight.
simulated function DetermineEnemiesInSquadSight( out array<XGUnitNativeBase> arrEnemies, Vector vLocation, bool bRequireLineOfSight, bool bSkipRoboticUnits=false, bool bSkipNonRoboticUnits=false )
{
	
}

//------------------------------------------------------------------------------------------------
simulated function XComPresentationLayer PRES()
{
	return `PRES;
}

//------------------------------------------------------------------------------------------------

simulated event int GetUnitFlightFuel()
{
	return 0;//m_aCurrentStats[eStat_FlightFuel];
}

simulated function SetInventory( XGInventory kInventory)
{
	if (kInventory != none)
	{
		m_kInventory = kInventory;
		m_kInventory.m_kOwner = self;

		// MHU - HP/Stats not updated here. Please ensure LoadoutChanged_UpdateModifiers() is called soon.
	}
}

simulated function XGInventory GetInventory()
{
	return XGInventory(m_kInventory);
}

//------------------------------------------------------------------------------------------------

function OnDeath( class<DamageType> DamageType, XGUnit kDamageDealer )
{
	local int i;
	local XGUnit SurvivingUnit;
	local XGPlayer PlayerToNotify;	
	local bool kIsRobotic;

	UnitSpeak('DeathScream', true);

	// Notify all players of the death
	for (i=0; i < `BATTLE.m_iNumPlayers; ++i)
	{
		PlayerToNotify = `BATTLE.m_arrPlayers[i];
		PlayerToNotify.OnUnitKilled(self, kDamageDealer);
	}

	if (m_bInCover)
		HideCoverIcon();

	SetDiscState(eDS_Hidden); //Hide the unit disc	

	if(!PRES().USE_UNIT_RING)
		m_kDiscMesh.SetHidden(true);

	m_bStunned = false;

	m_bIsFlying = false;

	if( !IsActiveUnit() )
		GotoState( 'Dead' );

	if( m_kForceConstantCombatTarget != none )
	{
		m_kForceConstantCombatTarget.m_kConstantCombatUnitTargetingMe = none;
	}

	if( m_kConstantCombatUnitTargetingMe != none )
	{
		m_kConstantCombatUnitTargetingMe.ConstantCombatSuppress(false,none);
		m_kConstantCombatUnitTargetingMe = none;
	}

	//RAM - Constant Combat

	SurvivingUnit = GetSquad().GetNextGoodMember();
	kIsRobotic = IsRobotic();

	if (SurvivingUnit != none && !kIsRobotic && !IsAlien_CheckByCharType())
		SurvivingUnit.UnitSpeak( 'SquadMemberDead' );
}

//-------------------------------------------------------------------------------------
//---------------------------------- DEBUGGING ----------------------------------------
//-------------------------------------------------------------------------------------
simulated function DrawSpawningDebug(Canvas InCanvas, bool ShowDetailedData)
{
	local Vector vScreenPos, WorldLocation;
	local SimpleShapeManager ShapeManager;
	local XComGameState_Unit GameStateUnit;

	if (m_kPawn != None)
	{
		WorldLocation = GetUnitFlagLocation() + vect(0,0,-1) * ( m_kPawn.CylinderComponent.CollisionHeight );
	}
	else
	{
		WorldLocation = GetUnitFlagLocation();
	}

	// draw a small sphere at the unit's location in world
	ShapeManager = `SHAPEMGR;

	ShapeManager.DrawSphere( WorldLocation, vect(64,64,64), MakeLinearColor(1,0,0,1));

	if( ShowDetailedData )
	{
		GameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));

		vScreenPos = InCanvas.Project(WorldLocation);
		InCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
		InCanvas.DrawText( "{" $ GameStateUnit.ObjectID $ "}" @ self @ "[" $ GameStateUnit.GetMyTemplateName() $ "]" @ int(GameStateUnit.GetXpKillscore()));
	}
}

simulated function DrawDebugLabel(Canvas kCanvas)
{	
	local SimpleShapeManager ShapeManager;
	local Vector vScreenPos, WorldLocation, VisDirection;
	local int numActions, i, iAlertLevel;
	local ECoverState CoverState;
	local string strOutput;
	local XComGameState_Unit kGameStateUnit;
	local array<StateObjectReference> arrVisEnemies;
	local StateObjectReference kRef;
	local XComGameState_AIUnitData kAIUnitData;
	local int iDataID;
	local XComTacticalCheatManager CheatManager;
	local float HeightAdjustment;

	CheatManager = `CHEATMGR;

	if( CheatManager == None )
	{
		return;
	}

	kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	if (kGameStateUnit == none)
	{
		return; // don't have a unit (yet).  History may not be ready during save/load if we get in here too soon.
	}
	
	HeightAdjustment = 0;
	if (m_kPawn != None)
	{
		HeightAdjustment = m_kPawn.CylinderComponent.CollisionHeight;
	}
	if( kGameStateUnit.GetMyTemplate().bIsCosmetic )
	{
		HeightAdjustment -= 192;
	}
	WorldLocation = GetUnitFlagLocation() + vect(0, 0, -1) * (HeightAdjustment);

	vScreenPos = kCanvas.Project(WorldLocation);

	if( CheatManager.bShowAIVisRange && kGameStateUnit.GetMyTemplate().VisionArcDegrees < 360 )
	{
		VisDirection = WorldLocation + Vector(kGameStateUnit.MoveOrientation) * kGameStateUnit.GetVisibilityRadius() * class'XComWorldData'.const.WORLD_StepSize;
		ShapeManager = `SHAPEMGR;
		ShapeManager.DrawCone( WorldLocation, VisDirection, kGameStateUnit.GetMyTemplate().VisionArcDegrees * 2, MakeLinearColor(1,0,0,1));

		// todo: draw vis tiles
	}

	kCanvas.SetPos(vScreenPos.X, vScreenPos.Y);
	kCanvas.SetDrawColor(255,255,255);
	if (CheatManager != None && CheatManager.bDebugConcealment)
	{
		if (m_eTeam == eTeam_XCom || m_eTeam == eTeam_Resistance)
		{
			// Display spotted status. 
			strOutput = (m_bSpotted?"Spotted":"unspotted");
			kCanvas.DrawText("Visualizer Status:"@strOutput);
			kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
			if (kGameStateUnit != None)
			{
				strOutput = (kGameStateUnit.m_bSpotted?"Spotted":"unspotted")@(kGameStateUnit.IsConcealed()?"Concealed,":"unconcealed,");
				kCanvas.DrawText("GameState Status:"@strOutput);
			}
		}
		else if (m_eTeam == eTeam_Alien || m_eTeam == eTeam_TheLost )
		{
			// Display spotted status. 
			kCanvas.DrawText("Visualizer Status: "@`ShowVar(GetAlertLevel()));
			kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
			if (kGameStateUnit != None)
			{
				iAlertLevel = kGameStateUnit.GetCurrentStat(eStat_AlertLevel);
				kCanvas.DrawText("GameState Status: Alert level ="@iAlertLevel);
				kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));

				kCanvas.DrawText("Visible enemy ids:");
				kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
				class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(ObjectID, arrVisEnemies);
				if (arrVisEnemies.Length == 0)
				{
					kCanvas.DrawText("No visible enemies found!");
					kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
				}
				else
				{
					foreach arrVisEnemies(kRef)
					{
						kCanvas.DrawText("#"@kRef.ObjectID);
						kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
					}
				}
				
				if( m_kBehavior != None )
				{
					iDataID = m_kBehavior.m_kPlayer.GetAIUnitDataID(ObjectID);
					if ( iDataID > 0 )
					{
						kAIUnitData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(iDataID));
						kAIUnitData.GetAbsoluteKnowledgeUnitList(arrVisEnemies, , false);
						kCanvas.DrawText("Absolute Knowledge:");
						kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
						if (arrVisEnemies.Length == 0)
						{
							kCanvas.DrawText("No absolute alert data found!");
							kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
						}
						else
						{
							foreach arrVisEnemies(kRef)
							{
								kCanvas.DrawText("#"@kRef.ObjectID);
								kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
							}
						}
					}
				}
			}
		}
	}

	if (m_eTeam != eTeam_XCom)
	{
		if( m_kBehavior != None )
		{
			m_kBehavior.DrawDebugLabel(kCanvas, vScreenPos);
		}

		if (CheatManager.bShowMaterials)
		{
			if (m_kPawn != None)
			{
				for (i=0; i<m_kPawn.Mesh.SkeletalMesh.Materials.Length; i++)
				{
					kCanvas.DrawText("Material["$i$"]="$m_kPawn.Mesh.SkeletalMesh.Materials[i].Name@"Parent="$MaterialInstanceConstant(m_kPawn.Mesh.SkeletalMesh.Materials[i]).Parent.Name);
					kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
				}
			}
		}

		if (CheatManager.bAITextSkipBase)
		{
			return;
		}
	}
	else
	{
		if (CheatManager.bShowMaterials)
		{
			if (m_kPawn != None)
			{
				for (i=0; i<m_kPawn.Mesh.SkeletalMesh.Materials.Length; i++)
				{
					kCanvas.DrawText("Material["$i$"]="$m_kPawn.Mesh.SkeletalMesh.Materials[i].Name@"Parent="$MaterialInstanceConstant(m_kPawn.Mesh.SkeletalMesh.Materials[i]).Parent.Name);
					kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
				}
			}
		}

	}

	if (IsAlive())
	{
		if (Owner != none && XComTacticalController(Owner).GetActiveUnit() == self)
		{
			kCanvas.SetDrawColor(0,255,0);
		}
		else
		{
			kCanvas.SetDrawColor(255,255,255);
		}
	}
	else 
	{
		kCanvas.SetDrawColor(225,200,200);
	}

	// in multiplayer on the clients numActions will be 0 because clients dont have the regular action queue. -tsmith 
	if (CheatManager.bShowActions)
	{
		if(WorldInfo.NetMode != NM_Client)
		{
			strOutput = kGameStateUnit.IsConcealed()?"[ C ]":"";
			if(IsTurret())
			{
				strOutput = strOutput@ "TurretState="$string(kGameStateUnit.IdleTurretState);
			}
			kCanvas.DrawText(Name@ObjectID@SafeGetCharacterLastName()@strOutput);
		}
		else
		{
			kCanvas.DrawText(Name@ObjectID@SafeGetCharacterLastName());
		}
		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
	}

	if (CheatManager.bShowNamesOnly)
	{
		return;
	}

	kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
	if (CheatManager.bShowShieldHP)
	{
		if (GetShieldHP() > 0)
		{
			kCanvas.DrawText("ShieldHP="@GetShieldHP());
			kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		}
	}

	if (CheatManager.bShowActions)
	{
		numActions = 0; // <---- pmiller put this in just to make sure it all works
		for (i = 0; i < numActions; i ++)
		{
			kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		}

		kCanvas.DrawText("HP="$GetUnitHP()$" Cover="$m_bInCover@"PC="$m_iPanicCounter);
		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
				
		if (m_kPawn != none)
		{
			kCanvas.DrawText("Location  :"@m_kPawn.Location@"Rotation:"@m_kPawn.Rotation);
			kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
			kCanvas.DrawText("FocalPoint:"@m_kPawn.FocalPoint@" TargetLoc:"@m_kPawn.TargetLoc);
		}
		else
			kCanvas.DrawText("Location: Unknown - invalid pawn");
		
		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText("State:"@GetStateName());
		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		if (m_kPawn != none)
		{
			kCanvas.DrawText("Physics:"@m_kPawn.Physics);
			kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
			kCanvas.DrawText("IndoorInfo:"@m_kPawn.IndoorInfo.GetLowestFloorNumber());
		}
		else
			kCanvas.DrawText("Physics: Unknown - invalid pawn");
	}

	m_kPawn.GetAnimTreeController().DrawDebugLabels(kCanvas, vScreenPos);

	if( IdleStateMachine != none )
	{
		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText("     Idle State  :" @ IdleStateMachine.GetStateName() );
		CoverState = ECoverState(m_eCoverState);
		strOutput = "" $ CoverState;
		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText("     Cover State :" @ strOutput);
	}	

	if (CheatManager.bShowModifiers)
	{
		DrawDebugModifiers(kCanvas, vScreenPos);
	}
}

simulated function DrawDebugModifiers(Canvas kCanvas, out Vector vScreenPos)
{
	/*
	local string data;
	local name nameData;
	local XGAbility_Targeted kTargetedAbility;
	local int iCounter;
	local TAbility kTAbility;

	kCanvas.SetDrawColor(0,255,255);

	kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
	
	kCanvas.DrawText("Current HP: " $ m_aCurrentStats[eStat_HP] $ 
					 ", MaxHP = Char("$ GetCharMaxStat(eStat_HP) $
					 ") + Armor(" $ m_aInventoryStats[eStat_HP] $")");

	kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
	kCanvas.DrawText("FlightFuel: " $ m_aCurrentStats[eStat_FlightFuel] $
					 ", MaxFlightFuel = Char("$ GetCharMaxStat(eStat_FlightFuel) $
					 ") + Armor(" $ m_aInventoryStats[eStat_FlightFuel] $")");

	kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
//	kCanvas.DrawText("Moves: "$ GetMoves() $ "/" $ m_kCharacter.m_iMaxMoves);       jbouscher - REFACTORING CHARACTERS

	kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
//	kCanvas.DrawText("Abilities: "$ GetUseAbilityCounter() $ "/" $ m_kCharacter.m_iMaxUseAbilities);        jbouscher - REFACTORING CHARACTERS
	kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
	if (GetUseAbilityCounter() == 0)
	{
		kCanvas.DrawText("-"@m_eUsedAbility);
	}
	else
	{	
		kCanvas.DrawText("- not used up yet");
	}

	if (m_iNumAbilities > 0)
	{
		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText("=== Abilities Information ===");	
		for (iCounter = 0; iCounter < m_iNumAbilities; iCounter++)
		{
			if (m_aAbilities[iCounter] != none)
			{
				kTAbility = `GAMECORE.m_kAbilities.GetTAbility(m_aAbilities[iCounter].GetType());

				kTargetedAbility = XGAbility_Targeted(m_aAbilities[iCounter]);
				if (kTargetedAbility != none &&
					kTargetedAbility.GetPrimaryTarget() != none)
					nameData = kTargetedAbility.GetPrimaryTarget().Name;
				else
					nameData = '';

				kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
				kCanvas.DrawText(iCounter@":" @ kTAbility.strName @ nameData);
			}
		}
	}

	if (m_kActionQueue != none)
	{
		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText("=== ActionQueue Information ===");	

		iCounter = 1;
		foreach m_kActionQueue.m_arrActionLogging (data)
		{
			kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
			kCanvas.DrawText(iCounter@":" @ data);
			iCounter++;
		}
	}
	*/
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
/** kEnemy, if NONE, tests against all visible enemies.  Otherwise tests only the one.
 Currently this function only tests direction of cover to direction of enemies- no actual traces done here (yet). **/
function bool IsCoverExposed(XComCoverPoint kTestCover, XGUnit kEnemy=none, optional out float fDot,  bool bDrawLines=false, bool bIgnoreOutOfRangeCover=true)
{
	//@TODO - rmcfall - replace all calls with visibility mgr / X2TacticalVisibilityHelpers calls
}

//------------------------------------------------------------------------------------------------
simulated function XGInventoryItem GetAlienGrenade()
{
	return GetInventory().FindGrenade();
}
//------------------------------------------------------------------------------------------------
// Returns true if the unit is an AI unit, still dormant within an unactivated pod.
simulated function bool IsDormant(bool bFalseIfActivating=false)
{
	//if (m_kBehavior != none)
	//{
	//	return m_kBehavior.IsDormant(bFalseIfActivating);
	//}
	return false;
}
//------------------------------------------------------------------------------------------------
simulated function bool IsAliveHealthyAndActive(bool bFalseIfActivating=false)
{
	return IsAliveAndWell() && !IsDormant(bFalseIfActivating) && !m_bStunned && !IsPanicked();
}
//------------------------------------------------------------------------------------------------

simulated function bool IsInVisibleAlienPod()
{
	if (IsDormant() && IsVisible())
	{
		return true;
	}
	return false;
}

//-------------------------------------------------------------------------------------
simulated function DebugShowOrientation()
{
	local int i;
	local XComCoverPoint kCoverPointHandle;
	local Vector arrColor;
	local Vector vDir;//, tempVector;

	// MHU - Shows unit direction facing
	if (XComTacticalCheatManager(GetALocalPlayerController().CheatManager) != none && 
		XComTacticalCheatManager(GetALocalPlayerController().CheatManager).bShowOrientation)
	{
		vDir = Vector(m_kPawn.Rotation);

		`SHAPEMGR.DrawLine(GetLocation(), GetLocation()+ vDir * 200.0f, 6, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));

		//tempVector.X = vDir.X;
		//tempVector.Y = 0;
		//tempVector.Z = 0;
		//`SHAPEMGR.DrawLine(GetLocation(), GetLocation()+ tempVector * 100.0f, 6, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));

		//tempVector.X = 0;
		//tempVector.Y = vDir.Y;
		//tempVector.Z = 0;
		//`SHAPEMGR.DrawLine(GetLocation(), GetLocation()+ tempVector * 100.0f, 6, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));

		//tempVector.X = 0;
		//tempVector.Y = 0;
		//tempVector.Z = vDir.Z;
		//`SHAPEMGR.DrawLine(GetLocation(), GetLocation()+ tempVector * 100.0f, 6, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));

		// MHU - FocalPoint rendering...
		`SHAPEMGR.DrawLine(GetLocation(), m_kPawn.FocalPoint, 6, MakeLinearColor(1.0f, 0.5f, 0.5f, 1.0f));

		kCoverPointHandle = GetCoverPoint();
		for (i = 0; i < `COVER_DIR_COUNT; i++)
		{		
			if (`IS_VALID_COVER(kCoverPointHandle) && `HAS_COVER_IN_DIR(kCoverPointHandle, `IDX_TO_DIR(i)))
			{
				arrColor = Vect(1,0,0);
				`SHAPEMGR.DrawLine(GetShieldLocation(i) + Vect(0, 0, 10), GetShieldLocation(i) + Vect(0, 0, 10) + GetCoverDirection(i) * 100.0f, 6, MakeLinearColor(arrColor.x, arrColor.y, arrColor.z, 1.0f));
				`SHAPEMGR.DrawSphere(GetShieldLocation(i) + Vect(0, 0, 10), vect(10, 10, 10), MakeLinearColor(arrColor.x, arrColor.y, arrColor.z, 1.0f), false);
			}
		}
	}
}

function DrawFlankingMarkers(XComCoverPoint Point, XGUnit Unit)
{
	//local XGUnit kUnit;
	//local Vector Start;
	//local Vector End;

	//if (Unit.IsCriticallyWounded())
	//	return;

	//Start = Point.CoverLocation + Vect(0.0f, 0.0f, 64.0f);
	//End = Start + Point.CoverLocation * 256.0f;

	//`SHAPEMGR.DrawLine(Start, End, 3, MakeLinearColor(0.0f, 1.0f, 0.2f, 0.8f));
	//`SHAPEMGR.DrawCone(Start, End, Unit.FlankingAngle * DegToRad, MakeLinearColor(0.0f, 1.0f, 0.2f, 0.3f), 0.01f);

	//if (Unit.GetNumFlankers() > 0)
	//{
	//	foreach Unit.m_arrFlankingUnits(kUnit)
	//	{
	//		End = kUnit.GetPawn().Location + Vect(0.0f, 0.0f, 64.0f);
	//		`SHAPEMGR.DrawLine(Start, End, 3, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f));
	//		`SHAPEMGR.DrawCone(End, End + Normal(Start - End) * 10.0f, 32.0f * DegToRad, MakeLinearColor(1.0f, 0.0f, 0.0f, 1.0f), 0.01f);
	//	}
	//}
}

function DrawFlankingCursor(XGUnit Enemy)
{
	local Vector Start;
	local Vector End;
	local LinearColor FlankingColor;
	local XCom3DCursor Cursor;
	local XCom3DCursor TempCursor;

	if (Enemy.IsInCover())
	{
		foreach DynamicActors(class'XCom3DCursor', TempCursor) 
		{
			Cursor = TempCursor;
		}

		if (Cursor != none)
		{
			Start = Enemy.GetShieldLocation() + Vect(0.0f, 0.0f, 64.0f);
			End = Cursor.Location;

			if (Enemy.IsFlankedByLoc(End))
				FlankingColor = MakeLinearColor(1.0f, 0.0f, 0.0f, 0.8f);
			else
				FlankingColor = MakeLinearColor(0.0f, 1.0f, 0.0f, 0.8f);

			`SHAPEMGR.DrawLine(Start, End, 3, FlankingColor);
		}
		
	}
}

function DisplayHeightDifferences()
{
	local TTile kTile;
	local vector vStart, vEnd;
	local CylinderComponent CylinderComp;

	CylinderComp = CylinderComponent(m_kPawn.CollisionComponent);

	if (CylinderComp != none)
	{
		vStart = m_kPawn.Location;
		vStart.Z = vStart.Z - CylinderComp.CollisionHeight - 5.0f;

		`XWORLD.GetFloorTileForPosition(m_kPawn.Location, kTile, true);
		vEnd = `XWORLD.GetPositionFromTileCoordinates(kTile);
		vEnd.X = vStart.X;
		vEnd.Y = vStart.Y;
		
		`SHAPEMGR.DrawLine(vStart, vEnd, 20, MakeLinearColor(0.4f, 0.95f, 1.0f, 0.2f));
	}
}

simulated function DebugVisibilityForSelf(Canvas kCanvas, Vector vScreenPos)
{
	/*
	local XGSquad kEnemySquad;
	local XGUnit kEnemy;
	local int i, j;
	local int arrFlagVisInfo[EUnitVisibilityInformation_CoverPoint.EnumCount];
	local Actor kHitActor;

	local XGUnitVisibilityInformation kEnemyVisInfo;

	// Check against enemies...
	kEnemySquad = `BATTLE.GetEnemySquad( GetPlayer() );
	for( i = 0; i < kEnemySquad.GetNumMembers(); i++ )
	{
		kEnemy = kEnemySquad.GetMemberAt(i);

		if (!kEnemy.IsAlert())
			continue;

		kHitActor = none;
		ProcessVisibilityWithVisInfo(   kEnemy,
										arrFlagVisInfo,
										kHitActor);

		kEnemyVisInfo.kUnit = kEnemy;
		for (j = 0; j < eUVICP_MAX; j++)
		{
			kEnemyVisInfo.kVis[j] = arrFlagVisInfo[j];
		}

		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText(" " @ kEnemyVisInfo.kUnit.Name @ class'XGGameData'.static.DrawVisInfo(kEnemyVisInfo)@"  HitActor:"@kHitActor);
	}
	*/
}

simulated function DebugCoverActors(Canvas kCanvas, XComTacticalCheatManager kCheatManager)
{
	local Vector vScreenPos;
	local Actor kActor;

	if	(kCheatManager.bDebugCoverActors &&
		!GetPlayer().IsA('XGAIPlayer_Civilian'))
	{
		vScreenPos = kCanvas.Project(Location);

		if (IsAlert())
			kCanvas.SetDrawColor(255,255,255);
		else
			kCanvas.SetDrawColor(125,125,125);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText(self.Name@" # of CoverActors:"@m_aCoverActors.length);

		foreach m_aCoverActors(kActor)
		{  
			kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
			
			if (XComDestructibleActor(kActor) != none)
			{
				kCanvas.DrawText(kActor@"DestructibleActor"@XComDestructibleActor(kActor).Health);
			}
			else if (XComFracLevelActor(kActor) != none)
			{
				kCanvas.DrawText(kActor@"FracLevelActor");
			}
			else if (XComLevelActor(kActor) != none)
			{
				kCanvas.DrawText(kActor@"XComLevelActor");
			}
			else if (XComUnitPawn(kActor) != none)
			{
				kCanvas.DrawText(kActor@"XComUnitPawn"@XComUnitPawn(kActor).Health);		
			}
			else
				kCanvas.DrawText(kActor@"Unknown");		

		}
	}
}

simulated function DebugTimeDilation(Canvas kCanvas, XComTacticalCheatManager kCheatManager)
{
	local Vector vScreenPos;
	local XComUnitPawn kPawn;

	if	(kCheatManager.bDebugTimeDilation &&
		!GetPlayer().IsA('XGAIPlayer_Civilian'))
	{
		kPawn = XComUnitPawn(m_kPawn);
		if (kPawn != none)
		{
			vScreenPos = kCanvas.Project(Location);

			kCanvas.SetDrawColor(255,255,255);
			kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
			kCanvas.DrawText(self.Name@"DilationState:"@string(kPawn.m_eTimeDilationState)@"TimeDilation:"@kPawn.CustomTimeDilation);
		}
	}
}

simulated function DebugCCState(Canvas kCanvas, XComTacticalCheatManager kCheatManager)
{
	local Vector vScreenPos;

	if	(kCheatManager.bDebugCCState &&
		!GetPlayer().IsA('XGAIPlayer_Civilian'))
	{
		vScreenPos = kCanvas.Project(Location);

		if (IsAlert())
			kCanvas.SetDrawColor(255,255,255);
		else
			kCanvas.SetDrawColor(125,125,125);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText(self.Name);				
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("  CC_State:"@IdleStateMachine.GetStateName());
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);/*
		kCanvas.DrawText("  CC_DesiredCoverIndex:"@IdleStateMachine.DesiredCoverIndex);
		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("  CC_DesiredPeek:"@IdleStateMachine.DesiredPeekSide);*/
	}
}

simulated function DebugVisibility(Canvas kCanvas, XComTacticalCheatManager kCheatManager)
{
	
}

simulated function DebugAnims(Canvas kCanvas, XComTacticalCheatManager kCheatManager)
{
	local bool bSingleUnitDebugging;
	local Vector vScreenPos;

	bSingleUnitDebugging = kCheatManager.m_DebugAnims_TargetName == self.Name;

	if (m_kPawn != none &&
		kCheatManager.bDebugAnims &&
		(kCheatManager.m_DebugAnims_TargetName == '' || bSingleUnitDebugging))
	{
		vScreenPos = kCanvas.Project(Location);
		kCanvas.SetDrawColor(255,255,255);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText(self.Name);

		if (IsMine())
			kCanvas.SetDrawColor(150,255,150);
		else
			kCanvas.SetDrawColor(255,150,150);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Location:"@m_kPawn.Location@"Rotation:"@m_kPawn.Rotation);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("MeshZOffset:"@m_kPawn.Mesh.Translation.Z);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("LOD_TickRate:"@m_kPawn.LOD_TickRate);

		kCanvas.SetPos(vScreenPos.X, vScreenPos.Y += 15.0f);
		kCanvas.DrawText("Time Dilation:"@m_kPawn.CustomTimeDilation);

		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText("State:"@GetStateName());

		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText("Physics:"@m_kPawn.Physics@"PhysWeight:"@m_kPawn.Mesh.PhysicsWeight@"Motor:"@XComUnitPawn(m_kPawn).fPhysicsMotorForce);

		kCanvas.SetPos(vScreenPos.X, (vScreenPos.Y += 15.0f));
		kCanvas.DrawText("AimOffset: X:"@m_kPawn.AimOffset.X@"Y:"@m_kPawn.AimOffset.Y);

		kCanvas.SetDrawColor(255,255,255);

		m_kPawn.GetAnimTreeController().DebugAnims(kCanvas, kCheatManager.bDisplayAnims, IdleStateMachine, vScreenPos);

		DebugWeaponAnims(kCanvas, kCheatManager.bDisplayAnims, vScreenPos);
	}
}

function TerminateActions()
{
	
}

//  Return value is modified damage amount based on any absorption the unit has.
function int AbsorbDamage(const int IncomingDamage, XGUnit kDamageCauser, XGWeapon kWeapon)
{
	return IncomingDamage;
}

simulated function bool HasAction( int iActionID )
{
	/*if( m_kCurrAction != none ) {
		return m_kCurrAction.m_iID == iActionID;
	}*/

	return false;
}

//simulated final function bool IsActionOfClassInQueue(class<XGAction> kActionClass, optional out XGAction kAction)
//{
//	return m_kNetExecActionQueue.IsActionOfClassInQueue(kActionClass, kAction);
//}

simulated function bool IsActiveUnit()
{
	return IsInState( 'Active', true );
}

simulated function bool IsPerformingAction()
{
	return false;
}

simulated function bool IsUnitBusy()
{
	// Need to handle the case where we are idle
	// even if m_kCurrAction is empty.

	return false;
	//return !m_kCurrAction.IsA( 'XGAction_Idle' ) && !m_kCurrAction.IsA( 'XGAction_Wait' );
}

simulated function bool IsIdle()
{
	return false;
}

//@TODO - pmiller - delete this function
simulated function bool IsNetworkIdle(bool bCountPathActionsAsIdle)
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated function OnMoveComplete()
{
	if( m_kBehavior != none)
	{
		m_kBehavior.OnMoveComplete();
	}
}
//------------------------------------------------------------------------------------------------
// Overridden in states
simulated function Activate();

simulated function Deactivate();

function OnChangedIndoorOutdoor( bool bWentInside )
{
	if( IsActiveUnit() )
	{

	}
}

// Get the building (if any) that this unit is inside of
simulated function XComBuildingVolume GetBuilding()
{
	return m_kPawn.IndoorInfo.CurrentBuildingVolume;
}

//------------------------------------------------------------------------------------------------
simulated function bool HasBombardAbility()
{
	/*  jbouscher - REFACTORING CHARACTERS
	local int iType;
	iType = GetCharacter().m_kChar.iType;
	if ( iType == 'FloaterHeavy'
		|| iType == 'MutonElite'
		|| iType == 'Cyberdisc' 
		|| iType == 'Sectopod'
		)
		return true;
	*/
	return false;
}
//------------------------------------------------------------------------------------------------
simulated function OnCyberdiscTransformComplete()
{
	
	
	
}

//--------------------------------------------------------------------------------
// A unit in this state is not the "Active" unit, but can still perform actions
auto simulated state Inactive
{
	simulated function Activate()
	{
		GotoState( 'Active' );
	}

	simulated event BeginState( name nmPrev )
	{
		RemoveRanges();
	}

	simulated event EndState( name nmNext )
	{
	}

	// Unit is about to perform an action
	simulated event ContinuedState()
	{
	}

	// Unit is performing action
	simulated event PausedState()
	{
	}

Begin:

	if(Role < ROLE_Authority && m_bActivateAfterPanickedComplete)
	{
		m_bActivateAfterPanickedComplete = false;
		Activate();
	}
}

//--------------------------------------------------------------------------------
// MHU - A unit in this state is ready to be destroyed and guaranteed not to trigger
//       other calls.
simulated state UninitComplete
{
	simulated function Activate()
	{
	}

	simulated event BeginState( name nmPrev )
	{
	}

	simulated event EndState( name nmNext )
	{
	}

	simulated event ContinuedState()
	{
	}

	simulated event PausedState()
	{
	}

	simulated event Tick( float fDeltaT )
	{
	}
}

simulated function BeginPulseController()
{
//	m_kPanicFF = m_arrPanicFF[0];
//	XComTacticalController(Owner).ClientPlayForceFeedbackWaveform(m_kPanicFF);
}
simulated function EndPulseController()
{
//	XComTacticalController(Owner).ClientStopForceFeedbackWaveform(m_kPanicFF);
}

simulated function BeginPanicEffects()
{
	// talk to me if you add code to this function as we need to be careful what gets replicated to non-owning players -tsmith 
	UnitSpeak( 'PanickedBreathing' );
}
//------------------------------------------------------------------------------------------------
simulated function EndPanicEffects()
{
	
}

simulated function float GetHealthPct()
{
	return (GetUnitHP() / float( GetUnitMaxHP()) );
}
//------------------------------------------------------------------------------------------------
simulated function CheckForLowHealthEffects()
{
	local float fCurrentHealthPct;

	if( !IsActiveUnit() || !IsMine() )
		return;

	fCurrentHealthPct = GetUnitHP() / float( GetUnitMaxHP() );

	// Below a certain percentage, we notify the player of low health by pulsing the controller
	if( fCurrentHealthPct*100 <= `GAMECORE.HP_PULSE_PCT )
	{
		BeginPulseController();
	}
}
//------------------------------------------------------------------------------------------------
simulated function EndLowHealthEffects()
{
	EndPulseController();
}

//------------------------------------------------------------------------------------------------
// dirty solution begin -tsmith 
//--------------------------------------------------------------------------------
// Entering this state signifies that this XGUnit is the unit currently being controlled by the Player
simulated state Active
{
	simulated function Activate()
	{
		UpdateInteractClaim();
	}

	simulated function Deactivate()
	{
		`LogSkipTurn(self $ "::" $ GetStateName() $ "::" $ GetFuncName() @ SafeGetCharacterFullName());

		// testing the contents of the action queues seperately so as to not break existing code that maybe relied on these action not being in the Qs -tsmith 10.11.2012
		if( IsDead())
		{
			GotoState( 'Dead' );
		}
		else
		{
			GotoState( 'Inactive' );
		}
	}

	simulated event BeginState( name nmPrev )
	{				
		// No path actions for AI units
		/*if (!IsAI() || XComTacticalCheatManager(GetALocalPlayerController().CheatManager).bAllowSelectAll )
		{
					
		}*/
		
		// Check panic levels
		//  @TODO gameplay / jbouscher - this panic check is bad - do we need to fix it?
		//if (IsActiveUnit() 
		//	&& m_iPanicCounter > 0
		//	&& CanPanic())
		//{
		//	// RUMBLE CONTROLLER
		//	BeginPanicEffects();
		//}

		CheckForLowHealthEffects();

		SetDiscState( eDS_Good);
	}

	simulated event EndState( name nmNext )
	{
		EndPanicEffects();

		EndLowHealthEffects();

		SetDiscState( eDS_None );

		if( Role == ROLE_Authority )
		{			
			// MHU - if we're shutting down, don't add an idle action.
			if (nmNext != 'UninitComplete' &&
				!IsCriticallyWounded()) // MILLER - Don't add idle actions to crit wounded units
			{
				`LogSkipTurn(self $ "::" $ GetFuncName() @ `ShowVar(nmNext));
			}
		}
	}

Begin:

	UpdateAbilitiesUI();	
}
// clean solution end -tsmith
// HACK: end - fix for first unit not being active after the intro cinematic that issues MoveToLocation orders. -tsmith 

//--------------------------------------------------------------------------------
// This unit is currently panicking (firing weapon, running around randomly)
simulated state Panicking
{
	simulated event BeginState( name nmPrev )
	{
		`Log("BeginState Panicking from"@nmPrev@self);
		if(Role == ROLE_Authority)
		{
			if (!IsCivilian())
			{
				m_bServerPanicMoveFinished = false;
				bForceNetUpdate = true;
			}

			m_bPushStatePanicking = true;
			m_bGotoStateInactiveFromStatePanicked = false;
		}

		SetDiscState( eDS_Red );
		if(XComTacticalController(GetALocalPlayerController()).GetPres() != none)
		{
			XComTacticalController(GetALocalPlayerController()).GetPres().HUDHide();
			XComTacticalController(GetALocalPlayerController()).GetPres().PHUDPanicking( self );
		}
	}

	simulated event EndState( name nmPrev )
	{
		`Log("EndState Panicking to"@nmPrev);
		if(Owner != none && XComTacticalController(GetALocalPlayerController()).GetPres() != none && GetPlayer() == `BATTLE.m_kActivePlayer)
		{
			XComTacticalController(GetALocalPlayerController()).GetPres().HUDShow();
		}
		SetDiscState( eDS_None );
		EndPanicEffects();
		m_bPushStatePanicking = false;
	}

	function vector GetRandomTargetLocation( vector vNearestEnemy )
	{
		// For now return a random point within 5 meters of our target.
		return m_kPlayer.GetRandomValidPoint(self, vNearestEnemy, `METERSTOUNITS(6) );
	}

	// Panic options: Run, Take cover, or fire randomly.
	function ChoosePanicOption()
	{
	}
Begin:

	//`CAMERAMGR.AddDyingUnit(self);          //  gives the best priority
	//while (`CAMERAMGR.WaitForCamera())
	//	Sleep(0.1f);

	
	Sleep(2.5f);

	if (!IsCivilian())
	{
		Sleep(0.5f);

		m_bPanicMoveFinished = false;
		if(Role == ROLE_Authority)
		{
			m_bServerPanicMoveFinished = false;
			bForceNetUpdate = true;			
		}

		// Select from one of the valid panic actions: run, hide (take cover), or shoot.
		ChoosePanicOption();

		Sleep(0.1f);

		// Wait for move to  finish.  Also wait for any newly revealed pods from this move to finish revealing.
		if(Role == ROLE_Authority)
		{
			while (IsMoving() || !IsIdle())
				Sleep( 0.0f );

			m_bPanicMoveFinished = true;
			m_bServerPanicMoveFinished = true;
			bForceNetUpdate = true;
		}
		else
		{
			while(!m_bServerPanicMoveFinished)
				Sleep(0.0f);

			m_bPanicMoveFinished = true;
		}

		//while( `PRES.CAMIsBusy() )
		//	Sleep( 0.0f );
	}
	//`CAMERAMGR.RemoveDyingUnit(self);

	GotoState( 'Panicked' );
}

function DecrementPanicCounter();

//--------------------------------------------------------------------------------
// This unit has just panicked, now they are in a "cooling down" period where they are inaccessible for a short time
simulated state Panicked
{
	simulated event BeginState( name nmPrev )
	{
		`Log("BeginState Panicked from"@nmPrev@self);
	}

	simulated event EndState( name nmNext )
	{
		`Log("EndState Panicked to"@nmNext);
//		RemoveStatModifiers(m_aPanicModifier);
		SetDiscState( eDS_None );
		EndPanicEffects();

		// NOTE: if there are state transitions from panicked to any other state you MUST add a similar flag 
		// so that clients will switch states appropriately. follow the pattern for m_bGotoStateInactiveFromStatePanicked -tsmith 
		if(nmNext == 'Inactive')
		{
			m_bGotoStateInactiveFromStatePanicked = true;
		}
	}

	function DecrementPanicCounter()
	{
		if (m_iPanicCounter != -1)
		{
			m_iPanicCounter -= 1;
		}
		if( m_iPanicCounter == 0 )
		{
			GotoState('Inactive');
		}
	}

	simulated function Activate()
	{
		XComTacticalController(Owner).GetCursor().MoveToUnit( GetPawn() );
		SetDiscState( eDS_Red );
		XComTacticalController(Owner).GetCursor().SetHidden( true );
		BeginPanicEffects();
	}

	simulated function Deactivate()
	{
		SetDiscState( eDS_None );
		EndPanicEffects();
	}

Begin:
	if (GetPlayer().GetActiveUnit() == self)
	{
		if (!GetPlayer().m_kPlayerController.Visualizer_SelectNextUnit())
		{
			GetPlayer().CheckForEndTurn(self);
		}
	}
	if(Role < ROLE_Authority)
	{
		while(!m_bGotoStateInactiveFromStatePanicked)
		{
			Sleep(0.0f);
		}
		GotoState('Inactive');
	}

}

simulated function UnregisterAsViewer()
{
	`XWORLD.UnregisterActor(m_kPawn);
}

simulated function BeginUpdatingVisibility()
{
	`XWORLD.BeginFOWViewerUpdates(m_kPawn);
}

simulated function EndUpdatingVisibility()
{
	`XWORLD.EndFOWViewerUpdates(m_kPawn);
}

simulated function ForceVisibilityUpdate()
{
	`XWORLD.ForceFOWViewerUpdate(m_kPawn);
}

simulated function 	DelayedDisableTick()
{
	m_bDisableTickForDeadUnit = true;
}

//--------------------------------------------------------------------------------
// This unit is dead
simulated state Dead
{
	event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
	{
		super.OnActiveUnitChanged(NewActiveUnit);

		// we may have loot, update the sparkles in case this is the first
		// unit of the next turn
		UpdateLootSparkles();
	}

	simulated event BeginState( name nmPrev )
	{
		m_eDiscState = eDS_None;
		ShowMouseOverDisc(false);
		if(!PRES().USE_UNIT_RING)
			m_kDiscMesh.SetHidden(true);

		// make sure the collision cylinder is on. Even though he's dead, we need to be able to touch
		// him for things like the 3D cursor giving flyovers
		XComUnitPawn(m_kPawn).PopCollisionCylinderEnable();;

		// switching this from force destroy to clear so the abilities wait to finish executing before cleaning up.
		// this was part of a fix for bug # 1577. if it causes any side effects then we will have to find a different solution -tsmith 7.25.2011
		//ForceDestroyAbilities();
		
		if( WorldInfo.NetMode == NM_Standalone )
		{
			if( m_kBehavior != none )
			{
				m_kBehavior.Destroy();
				m_kBehavior = none;
			}

			SetTimer(1.5, false, 'DelayedDisableTick');
		}
	}

	// OnTakeDamage, for undead
	function int OnTakeDamage( int iDamage, class<DamageType> DamageType, XGUnit kDamageDealer, vector HitLocation, vector Momentum, optional Actor DamageCauser )
	{		
		// No reason to take more damage if already dead.
		return iDamage;
	}



	simulated event EndState( name nmPrev )
	{ 
		//  if we aren't dead any more, we have probably been revived... so start ticking again
		m_bDisableTickForDeadUnit = false; //SetTickIsDisabled(false);
	}

	simulated function Activate();
	simulated function Deactivate();
	simulated function SetDiscState( EDiscState eState );
	simulated function ShowMouseOverDisc( optional bool bShow = true ); 
	simulated function ShowSelectionBox( optional bool bShow = true, optional bool bEnemy = false );
	protected function ExecuteNextAction();

}


//+++++++++++++++++++++++++++ HELPER FUNCTIONS +++++++++++++++++++++++++++++++++
simulated function DropWeapon()
{
	local XGWeapon	kWeapon;
	local Vector    vLoc;
	local Rotator   rRot;
	local XComWeapon kXComWeapon;

	// Lose the weapon we're holding here.  Drop it or launch it.
	kWeapon = GetInventory().GetActiveWeapon();

	if (kWeapon != none && GetPawn().m_bDropWeaponOnDeath )
	{   	
		kXComWeapon = XComWeapon(kWeapon.m_kEntity);
		m_kPawn.Mesh.GetSocketWorldLocationAndRotation(kXComWeapon.DefaultSocket, vLoc, rRot);
		m_kPawn.Mesh.DetachComponent(kXComWeapon.Mesh);
		kXComWeapon.SetBase(None);
		kWeapon.m_kEntity.AttachComponent(kXComWeapon.Mesh);
		SkeletalMeshComponent(kXComWeapon.Mesh).SetPhysicsAsset(SkeletalMeshComponent(kXComWeapon.Mesh).PhysicsAsset, true);
		//GetInventory().DropItem( kWeapon );
		//GetInventory().UnequipItem();
		kWeapon.m_kEntity.CollisionComponent = kXComWeapon.Mesh;
		SkeletalMeshComponent(kXComWeapon.Mesh).PhysicsWeight=1.0f;
		SkeletalMeshComponent(kXComWeapon.Mesh).ForceSkelUpdate();
		SkeletalMeshComponent(kXComWeapon.Mesh).UpdateRBBonesFromSpaceBases(TRUE, TRUE);
		SkeletalMeshComponent(kXComWeapon.Mesh).bSyncActorLocationToRootRigidBody=true;

		kXComWeapon.Mesh.WakeRigidBody();
		kWeapon.m_kEntity.SetPhysics(PHYS_RigidBody /*PHYS_None*/);
		kWeapon.m_kEntity.SetHidden(false);
		kWeapon.m_kEntity.SetLocation(vLoc);
		kWeapon.m_kEntity.SetRotation(rRot);

		SkeletalMeshComponent(kXComWeapon.Mesh).SetRBPosition(vLoc);
		SkeletalMeshComponent(kXComWeapon.Mesh).SetRBRotation(rRot);
		SkeletalMeshComponent(kXComWeapon.Mesh).SetRBLinearVelocity(vect(0,0,0), false);
		SkeletalMeshComponent(kXComWeapon.Mesh).SetRBAngularVelocity(vect(0,0,0), false);
	}
}

//------------------------------------------------------------------------------------------------
simulated function bool InAscent()
{
	return m_bInAscent;
}

// TODO: which of these needs to be simulated. -tsmith 
//------------------------------------------------------------------------------------------------
simulated function SetIsFlying(bool bFlying)
{
	m_bIsFlying = bFlying;
	if (!m_bIsFlying)
	{
		UnitSpeak( 'JetPackOff' );
	}
	else
	{
		UnitSpeak( 'JetpackMove' );
	}

}

//------------------------------------------------------------------------------------------------
simulated function SetInAscent(bool bInAscent)
{
	m_bInAscent = bInAscent;
}

simulated function bool IsAttemptingToHover(XCom3DCursor kCursor)
{	
	//local float fTraceDistanceBelowUnit;
	//local bool bResult;
	//local Vector PathDestination;
	//local float FloorZ;
	//local bool bDestinationHasFloor;

	//fTraceDistanceBelowUnit = class'XCom3DCursor'.const.CURSOR_FLOOR_HEIGHT;
	//PathDestination = m_kPathingPawn.GetPathDestinationLimitedByCost();	
	//FloorZ = `XWORLD.GetFloorZForPosition(PathDestination);
	//bDestinationHasFloor = FloorZ != PathDestination.Z;
	//bResult =   (!bDestinationHasFloor || ((PathDestination.Z - FloorZ) > fTraceDistanceBelowUnit)) && IsFlying();

	//return bResult;
	
	return false;
}


simulated function bool CanSatisfyHoverRequirements()
{
	local bool bResult;

	bResult = false;
	if (GetUnitFlightFuel() >= 1 + class'XGTacticalGameCore'.const.JETPACK_FUEL_HOVER_COST)
	{
		bResult = true;
	}

	return bResult;
}

//------------------------------------------------------------------------------------------------

simulated function Equip( XGWeapon kWeapon )
{
	local ELocation iSlotFrom;

	iSlotFrom = kWeapon.m_eSlot;

	XComTacticalController(GetALocalPlayerController()).PerformEquip(self, iSlotFrom);
}

reliable server function ServerEquip( XGWeapon kWeapon )
{
	Equip(kWeapon);
}

//------------------------------------------------------------------------------------------------
function Panic( int iTurnsToPanic, bool bUsingPsiPanicAbility=false )
{
	IdleStateMachine.CheckForStanceUpdate();
}
//------------------------------------------------------------------------------------------------
function Unpanic()
{
	// Unpanic the unit
	`Log("Called function Unpanic",,'GameCore');
	m_iPanicCounter = 0;
	if (IsPanicked())
		GotoState('Inactive');
}

//------------------------------------------------------------------------------------------------

/**
 * Called when the local player controller's m_eTeam variable has replicated.
 */
simulated function OnLocalPlayerTeamTypeReceived(ETeam eLocalPlayerTeam)
{
	super.OnLocalPlayerTeamTypeReceived(eLocalPlayerTeam);
	SetVisibleToTeams(m_eTeamVisibilityFlags);
}

simulated function vector AdjustSourceForMiss(vector vStart, vector vDirection, optional float fProjectileExtent=50)
{
	//local vector TileVector;
	local vector vNewStart, vTarget;
	local vector vHitLoc, vHitNorm, vExtent, vTempEnd, vTempStart, vRevHitLoc, vRevHitNorm;
	local TraceHitInfo HitInfo;
	local Actor  TracedActor, ReverseActor;

	vTarget = vStart + (vDirection * 1000);
	vNewStart = vStart;
	vTempStart = vStart;
	vTempEnd = vTarget;

	// function Actor Trace(out Vector   HitLocation, out Vector HitNormal, Vector TraceEnd, optional Vector TraceStart, optional bool bTraceActors, optional Vector Extent, optional out TraceHitInfo HitInfo, optional int ExtraTraceFlags);
	vExtent = vect(1,1,1) * fProjectileExtent; // Use a small sphere for impact detection
	TracedActor = Trace( vHitLoc, vHitNorm, vTempEnd, vTempStart, true, vExtent, HitInfo );

	if (TracedActor != none) 
	{
		if (TracedActor.class != class'WorldInfo') 
		{ // Hit something in the way - could be the intended target
			if (VSizeSq(vHitLoc - vStart) < 40000) // 40,000 = 200 squared
			{ // Attempt to fire through this object instead of exploding on it!
				// TODO: Determine if it should interact with the projectile, before bypassing it
				// Work backwards to find the "exit-point" on the blocking actor
				vTempEnd = vStart;
				vTempStart = vTarget;
				vNewStart = vHitLoc;
				// function TraceActors (class<Actor> BaseClass, out Actor Actor, out Object.Vector HitLoc, out Object.Vector HitNorm, Object.Vector End, optional Object.Vector Start, optional Object.Vector Extent, optional out TraceHitInfo HitInfo, optional int ExtraTraceFlags)
				foreach TraceActors( TracedActor.class, ReverseActor, vRevHitLoc, vRevHitNorm, vTempEnd, vTempStart, vExtent, HitInfo)
				{
					if (TracedActor == ReverseActor)
					{
						vNewStart = vRevHitLoc + (vDirection * fProjectileExtent); // Exit-point for the projectile + 10 units
						//DrawDebugLine( vNewStart, vTarget, 0, 128, 0, true ); // Green
						break;
					}
				}
				//DrawDebugLine( vStart, vRevHitLoc, 149, 121, 232, true ); // Purple
				//DrawDebugLine( vRevHitLoc, vNewStart, 255, 255, 0, true ); // Yellow
			}
			else
			{ // Splatter like mad!
				//DrawDebugLine( vStart, vHitLoc, 149, 121, 232, true ); // Purple
				//DrawDebugLine( vHitLoc, vTarget, 183, 57, 61, true ); // Red
			}
		}
		else
		{ // Hit BSP
			//DrawDebugLine( vStart, vTarget, 255, 128, 0, true ); // Orange
		}
	} 
	else
	{ // Didn't hit the intended actor, but also didn't hit anything else
		//DrawDebugLine( vStart, vTarget, 120, 140, 232, true ); // Blue
	}

	return vNewStart;
}

simulated function vector AdjustTargetForMiss(XGUnit kTarget, optional float MissScalar = 1.0f, bool bUseSyncRand = false)
{
	local float MissRadius;
	//local float MissX;
	local vector MissVector;
	local vector StartAim;
	local float fSign;	
	local Rotator RotateBy90Degrees;

	// IF( We are shooting at a unit, and that unit has a collision cylinder )
	if ( kTarget.GetPawn() != none)
	{
		if (kTarget.GetPawn().CylinderComponent != none)
		{
			StartAim = GetPawn().GetWeaponStartTraceLocation();

			MissRadius = kTarget.GetPawn().CylinderComponent.CollisionRadius;
			MissRadius*= MissScalar;
			MissRadius = FMax(kTarget.GetPawn().CylinderComponent.CollisionRadius, MissRadius);
			
			if (bUseSyncRand)
			{
				if (`SYNC_RAND(100) > 50) 
					fSign  = 1.0f;
				else fSign = -1.0f;
			}
			else
			{
				if (Rand(100) > 50) // Constant Combat, do not SYNC_RAND
					fSign  = 1.0f;
				else fSign = -1.0f;
			}

			MissVector = Normal(StartAim - kTarget.GetPawn().GetHeadshotLocation());
			RotateBy90Degrees = rotator(MissVector);
			RotateBy90Degrees.Yaw += 16384 * fSign; //yaw by +90 or -90 randomly			
			MissVector = vector(RotateBy90Degrees);
			MissVector.X *= fSign*MissRadius;
			MissVector.Y *= fSign*MissRadius;
			
			if (bUseSyncRand)
			{
				MissVector.X += fSign*(MissRadius + `SYNC_RAND(MissRadius)); // Constant Combat, do not SYNC_RAND
				MissVector.Y += fSign*(MissRadius + `SYNC_RAND(MissRadius)); // Constant Combat, do not SYNC_RAND
				MissVector.Z = (MissRadius + `SYNC_RAND(MissRadius));        // Constant Combat, do not SYNC_RAND
			}
			else
			{
				MissVector.X += fSign*(MissRadius + Rand(MissRadius)); // Constant Combat, do not SYNC_RAND
				MissVector.Y += fSign*(MissRadius + Rand(MissRadius)); // Constant Combat, do not SYNC_RAND
				MissVector.Z = (MissRadius + Rand(MissRadius));        // Constant Combat, do not SYNC_RAND
			}

			MissVector.Z -= 116 + `SYNC_RAND(32);

			//DrawDebugLine(StartAim, kTarget.GetPawn().GetHeadshotLocation() + MissVector, 255, 255, 0, true);
			return kTarget.GetPawn().GetHeadshotLocation() + MissVector;// * (MissRadius);
		}
		else
		{
			return kTarget.GetPawn().Location + vect(32,32,32);
		}
	}
}

function XGAIPlayer GetAI()
{
	return XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer());
}

//------------------------------------------------------------------------------------------------
simulated function RemoveRanges()
{
	if (`BATTLE != None && m_kPlayer != none) 
	{	
		RemoveRangesOnSquad(`BATTLE.GetEnemySquad( GetPlayer() ) );
	}
	RemoveRangesOnSquad(GetSquad());
}

simulated function RemoveRangesOnSquad( XGSquad kSquad )
{
	local XGUnit kUnit;
	local int i;

	if( kSquad != none ) //Can be none for alien players that haven't had their units created yet
	{
		for( i = 0; i < kSquad.GetNumMembers(); i++ )
		{
			kUnit = kSquad.GetMemberAt( i );

			if (kUnit.GetPawn() != none)
				kUnit.GetPawn().DetachRangeIndicator();
		}
	}
}

simulated function MoveCursorToMe()
{
	XComTacticalController(Owner).GetCursor().MoveToUnit(GetPawn());
}

// Generate the safe names here, since it has access to the appearance data
simulated function GenerateSafeCharacterNames()
{
	local XGCharacterGenerator CharacterGenerator;
	local string strFirstName, strLastName;
	local int iUnderscoreLocation, iAlienNumber;
	local XComGameState_Unit kGameStateUnit;
	
	kGameStateUnit = GetVisualizedGameState();

	if (IsSoldier() || IsCivilianChar())
	{
		CharacterGenerator = `XCOMGRI.Spawn(kGameStateUnit.GetMyTemplate().CharacterGeneratorClass);
		`assert(CharacterGenerator != none);
		CharacterGenerator.GenerateName(m_SavedAppearance.iGender, m_SavedAppearance.nmFlag, strFirstName, strLastName, m_SavedAppearance.iRace);
	}
	else
	{
		//  jbouscher - REFACTORING CHARACTERS
		strFirstName = kGameStateUnit.GetMyTemplate().strCharacterName;
		strLastName = String(self);  // Get fully instanced name i.e. 'XGUnit_0'
		// Find the last underscore, and then assign the number as the last name
		iUnderscoreLocation = InStr(strLastName, "_");
		while(iUnderscoreLocation != -1 && Len(strLastName) > 0)
		{
			strLastName = Right(strLastName, Len(strLastName) - (iUnderscoreLocation+1));
			iUnderscoreLocation = InStr(strLastName, "_");
		}
		iAlienNumber = int(strLastName);
		strLastName = "" $ (iAlienNumber + 1);  // Zero-based names look funny, increase by one to get around it
	}
	//m_kCharacter.SetSafeCharacterNameStrings(strFirstName, strLastName);  jbouscher - REFACTORING CHARACTERS
}

// Moved functions containing `IF/`ENDIF to bottom of file, to avoid line sync issues with the script debugger
//-------------------------------------------------------------------------------------
simulated event Tick( float fDeltaT )
{	
	local bool bShowUnit;
	// MHU - During the load process of a save file, a short window exists where XGUnit could tick
	//       despite not being fully initialized with load data.
	if( m_kSquad == none )
		return;
		
	if (IsAnimal())
	{
		return;
	}

	if (m_kPawn != none)
	{
		bShowUnit = true;
		if (!IsAliveAndWell()
			&& m_kPawn.IsInside()
			&& m_kPawn.IndoorInfo.GetLowestFloorNumber() > m_kPawn.IndoorInfo.CurrentBuildingVolume.GetLastShownUpperFloor())
		{
			bShowUnit = FALSE;
		}

		m_kPawn.SetHidden(!bShowUnit);
	}

	if (m_bDisableTickForDeadUnit)
		return;

	//X-Com 2 - ensure that cinematic mode pawns are visible
	//================================================	
	if( m_bInCinematicMode )
	{
		SetVisibleToTeams(eTeam_All);
	}
	//================================================
	

	if (!IsDead())
	{
		m_fTimeSinceLastUnitSpeak += fDeltaT;

		// remove any recently played speched
		if (m_arrRecentSpeech.Length > 0)
		{
			m_fElapsedRecentSpeech += fDeltaT;
			if (m_fElapsedRecentSpeech > RECENT_VOICE_TIME)
			{
				m_fElapsedRecentSpeech = 0.0f;
				m_arrRecentSpeech.Remove(0, 1);
			}
		}

		//`SHAPEMGR.DrawSphere( Location, vect(10,10,10), MakeLinearColor(0,0,1,0.6f), false);
		//`SHAPEMGR.DrawSphere( m_kPawn.Location, vect(10,10,10), MakeLinearColor(0,1,0,0.6f), false);

		//UpdateLookAt();

`if(`notdefined(FINAL_RELEASE))
		if (m_kPawn != None)
		{
			DebugShowOrientation();
		}

		if ( GetALocalPlayerController().CheatManager != none  && XComTacticalCheatManager(GetALocalPlayerController().CheatManager).bShowFlankingMarkers)
		{
			if( IsInCover() )
			{
				DrawFlankingMarkers(GetCoverPoint(), self);

				// If we're on the other team, draw flanking lines to the cursor
				if (`BATTLE.m_kActivePlayer != GetPlayer())
				{
					DrawFlankingCursor(self);
				}
			}
		}
`endif
	}
}

//------------------------------------------------------------------------------------------------

simulated event PostBeginPlay()
{
	local MaterialInterface TempParentMaterial;

	super.PostBeginPlay();

`if (`notdefined(FINAL_RELEASE))
	// MHU - For debug rendering.
	AddHUDOverlayActor();
`endif

	m_bInCinematicMode = false;
 
	//== Dynamic load (find) all of the resources that the cursor needs

	// dupe time sensitive materials
	TempParentMaterial = MaterialInstanceTimeVarying(DynamicLoadObject("UI_3D.Unit.Unit_Select_MITV", class'MaterialInstanceTimeVarying'));
	Cursor_UnitSelectEnterFB_MaterialInterface = new class'MaterialInstanceTimeVarying'(TempParentMaterial);

	TempParentMaterial = MaterialInstanceTimeVarying(DynamicLoadObject("UI_3D.Unit.Unit_Exit_MITV", class'MaterialInstanceTimeVarying'));
	Cursor_UnitSelectExitFB_MaterialInterface = new class'MaterialInstanceTimeVarying'(TempParentMaterial);

	Cursor_UnitSelectIdle_MITV = MaterialInstanceTimeVarying(DynamicLoadObject("UI_3D.Unit.Unit_Idle_MITV", class'MaterialInstanceTimeVarying'));
	Cursor_UnitSelectTargeted_MIC = MaterialInstance(DynamicLoadObject("UI_3D.Targeting.MIC_UnitTargeting", class'MaterialInstance'));	
	UnitCursor_UnitSelect_Gold = MaterialInstance(DynamicLoadObject("UnitCursor.Materials.MInst_UnitSelect_Gold", class'MaterialInstanceConstant'));	
	UnitCursor_UnitSelect_Green = MaterialInstanceConstant(DynamicLoadObject("UnitCursor.Materials.MInst_UnitCursor02_Green", class'MaterialInstanceConstant'));
	UnitCursor_UnitSelect_Orange = MaterialInstance(DynamicLoadObject("UnitCursor.Materials.MInst_UnitSelect_Orange", class'MaterialInstanceConstant'));	
	UnitCursor_UnitSelect_RED = MaterialInstanceTimeVarying(DynamicLoadObject("UI_3D.Unit.Unit_SelectRed_MITV", class'MaterialInstanceTimeVarying'));
	UnitCursor_UnitCursor_Flying = MaterialInstance(DynamicLoadObject("UnitCursor.Materials.MInst_UnitCursor_Flying", class'MaterialInstanceConstant'));

	m_kSelectionBoxMesh.SetStaticMesh(StaticMesh(DynamicLoadObject(SelectionBoxMeshName, class'StaticMesh')));
	m_kSelectionBoxMeshAllyMaterial = Material(DynamicLoadObject(SelectionBoxAllyMaterialName, class'Material'));
	m_kSelectionBoxMeshEnemyMaterial = MaterialInstanceConstant(DynamicLoadObject(SelectionBoxEnemyMaterialName, class'MaterialInstanceConstant'));
	
	m_kDiscMesh.SetStaticMesh(StaticMesh(DynamicLoadObject("UI_3D.Unit.Unit_Select", class'StaticMesh')));

	m_kReachableTilesCache = new class'X2ReachableTilesCache';
}

/**
 * Override this function to draw to the HUD after calling AddHUDOverlayActor(). 
 * Script function called by NativePostRenderFor().
 * 
 * MHU - Added this for simpler debug msg rendering on units.
 */
simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
`if (`notdefined(FINAL_RELEASE))
	local XComTacticalCheatManager kCheatManager;

	super.PostRenderFor(kPC, kCanvas, vCameraPosition, vCameraDir);

	kCheatManager = XComTacticalCheatManager( XComTacticalController(GetALocalPlayerController()).CheatManager );

	if (kCheatManager != none)
	{
		DebugVisibility(kCanvas, kCheatManager);
		
		DebugAnims(kCanvas, kCheatManager);

		DebugCCState(kCanvas, kCheatManager);

		DebugCoverActors(kCanvas, kCheatManager);

		DebugTimeDilation(kCanvas, kCheatManager);		
	}
`endif
}


function UpdateTurretIdle( EIdleTurretState eOverride=eITS_None)
{
	if(IsTurret())
	{
		if(eOverride == eITS_None)
		{
			IdleTurretState = GetVisualizedGameState().IdleTurretState;
		}
		else
		{
			IdleTurretState = eOverride;
		}
		// Resume idle anim.
		if( !IdleStateMachine.IsDormant() )  // Don't change the idle state if it is already in a visualization, it will auto-update when its done.
		{
			IdleStateMachine.GotoState('Idle');
		}
	}
}

//=======================================================================================
//X-Com 2 Refactoring
//
//RAM - most everything in here is temporary until we can kill off all the of XG<classname>
//      types. Eventually the XComGameState_<classname> objects will replace them entirely
//
simulated static function CreateVisualizer(XComGameState FullState, XComGameState_Unit SyncUnitState, XComGameState_Player SyncPlayerState, optional const XComGameState_Unit ReanimatedFromUnit = None)
{
	local XGUnit UnitVisualizer;
	local XGPlayer PlayerVisualizer;
	local vector NewLocation;
	local int i;
	local XComGameState_Ability Ability;	
	local XComUnitPawn kPawn;
	local X2Actor_TurretBase TurretBase;
	local vector BaseLocation;
	local Rotator BaseRotation;

	NewLocation = `XWORLD.GetPositionFromTileCoordinates(SyncUnitState.TileLocation);	

	PlayerVisualizer = XGPlayer(SyncPlayerState.GetVisualizer());
	UnitVisualizer = PlayerVisualizer.SpawnUnit(SyncUnitState, PlayerVisualizer.m_kPlayerController, 
												NewLocation, SyncUnitState.MoveOrientation, PlayerVisualizer.m_kSquad, false, none, true, true, ReanimatedFromUnit);

	UnitVisualizer.SetObjectIDFromState(SyncUnitState);	
	`XCOMHISTORY.SetVisualizer(SyncUnitState.ObjectID, UnitVisualizer);

	UnitVisualizer.ApplyLoadoutFromGameState(SyncUnitState, FullState);

	// Start Issue #376
	/// HL-Docs: ref:Bugfixes; issue:376
	/// Gremlins (and other Cosmetic Units) are now correctly tinted and patterned
	if (UnitVisualizer.GetPawn().IsA('XComHumanPawn') || SyncUnitState.GetMyTemplate().bIsCosmetic) //Gives soldiers/civilians their head, hair, etc.
	{	
		UnitVisualizer.GetPawn().SetAppearance( SyncUnitState.kAppearance );		
	}
	//End Issue #376
	else if(SyncUnitState.IsTurret()) // Attach turret base mesh and initialize the turret idle state based on team.
	{
		kPawn = UnitVisualizer.GetPawn();
		TurretBase = UnitVisualizer.Spawn(class'X2Actor_TurretBase', UnitVisualizer);
		kPawn.m_TurretBaseActor = TurretBase;
		kPawn.ReattachMesh(); // Ensure Mesh is updated to current pawn location. (fixes Z offset on load.)
		kPawn.Mesh.GetSocketWorldLocationAndRotation('turret_base', BaseLocation, BaseRotation);
		TurretBase.InitTurretBaseMesh(BaseLocation, BaseRotation, kPawn.m_kTurretBaseMesh);
		TurretBase.SetHidden(false);

		if( UnitVisualizer.m_eTeam == eTeam_Alien || UnitVisualizer.m_eTeam == eTeam_TheLost )
		{
			UnitVisualizer.IdleTurretState = eITS_AI_ActiveAlerted;
		}
		else
		{
			UnitVisualizer.IdleTurretState = eITS_XCom_ActiveAlerted;
		}
	}

	UnitVisualizer.m_kReachableTilesCache.SetCacheUnit(SyncUnitState);

	// Any unit that is created with abilities already attached we should add any associated perks
	for (i = 0; i < SyncUnitState.Abilities.Length; ++i)
	{
		Ability = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SyncUnitState.Abilities[i].ObjectID));

		//Issue #295 - Add a 'none' check before accessing Ability
		if(Ability != none && Ability.GetMyTemplate() != none ) // abilities can be removed during dev between saves
		{
			UnitVisualizer.GetPawn().AppendAbilityPerks( Ability.GetMyTemplate().GetPerkAssociationName() );
		}
	}
	UnitVisualizer.GetPawn().StartPersistentPawnPerkFX( );

	if( !UnitVisualizer.IsInState('Inactive') )
	{
		UnitVisualizer.GotoState('Inactive');
	}

	UnitVisualizer.m_bForceHidden = true;
	UnitVisualizer.SetVisibleToTeams(eTeam_None);
	if( SyncUnitState.bRemovedFromPlay )
	{
		SyncUnitState.RemoveUnitFromPlay();
	}

	if(SyncUnitState.IsTurret())
	{
		if(!UnitVisualizer.IdleStateMachine.IsDormant())
		{
			UnitVisualizer.IdleStateMachine.GoDormant();
		}
	}
}

function UpdateLootSparklesEnabled(bool bHighlight, XComGameState_Unit UnitState)
{
	GetPawn().UpdateLootSparklesEnabled(bHighlight, UnitState);
}

function UpdateLootSparkles(optional bool bHighlight, optional XComGameState_Unit UnitState)
{
	GetPawn().UpdateLootSparkles(bHighlight, UnitState);
}

function bool IsFallingBack()
{
	local XComGameState_AIGroup Group;
	local XComGameState_Unit UnitState;
	UnitState = GetVisualizedGameState();
	Group = UnitState.GetGroupMembership();
	if( Group != None )
	{
		return Group.IsFallingBack();
	}
	return false;
}

/*****************************
 * Visualization Observation *
 *****************************/

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	LastStateHistoryVisualized = -1;
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	//  @TODO: perhaps unit ring logic lives here
}

event OnVisualizationIdle();

//------------------------------------------------------------------------------------------------
defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=UnitSelectComponent
		StaticMesh=none
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		CollideActors=FALSE
		BlockActors=FALSE
		BlockZeroExtent=FALSE
		BlockNonZeroExtent=FALSE
		BlockRigidBody=FALSE
		HiddenGame=TRUE
		HideDuringCinematicView=TRUE
	End Object

	//bAlwaysRelevant=true
	bAlwaysRelevant=false

	Components.Add(UnitSelectComponent)
	m_kDiscMesh=UnitSelectComponent

	Begin Object Class=StaticMeshComponent Name=SelectionBoxComponent
	StaticMesh = none
	bOwnerNoSee = FALSE
	CastShadow = FALSE
	CollideActors = FALSE
	BlockActors = FALSE
	BlockZeroExtent = FALSE
	BlockNonZeroExtent = FALSE
	BlockRigidBody = FALSE
	HiddenGame = TRUE
	AbsoluteRotation = TRUE
	HideDuringCinematicView = TRUE
	End Object

	Components.Add(SelectionBoxComponent)
	m_kSelectionBoxMesh = SelectionBoxComponent
	m_bShowMouseOverDisc=false

	m_bReplicateHidden=false

	// 150 bpm, 1 pulse per 0.4 seconds
	Begin Object Class=ForceFeedbackWaveform Name=ForceFeedbackWaveform0
		Samples(0)=(LeftAmplitude=100,RightAmplitude=100,LeftFunction=WF_Constant,RightFunction=WF_Constant,Duration=.1)
		Samples(1)=(LeftAmplitude=0,RightAmplitude=0,LeftFunction=WF_Constant,RightFunction=WF_Constant,Duration=0.3)
		bIsLooping=true
	End Object
	// 100 bpm, 1 pulse per 0.6 seconds
	Begin Object Class=ForceFeedbackWaveform Name=ForceFeedbackWaveform1
		Samples(0)=(LeftAmplitude=75,RightAmplitude=75,LeftFunction=WF_Constant,RightFunction=WF_Constant,Duration=.1)
		Samples(1)=(LeftAmplitude=0,RightAmplitude=0,LeftFunction=WF_Constant,RightFunction=WF_Constant,Duration=0.5)
		bIsLooping=true
	End Object
	m_arrPanicFF(0)=ForceFeedbackWaveform0
	m_arrPanicFF(1)=ForceFeedbackWaveform1
	m_bHasChryssalidEgg=false

	m_fElapsedRecentSpeech = 0.0f
	m_fTimeSinceLastUnitSpeak = 0.0f

	m_iUnitLoadoutID=INDEX_NONE
}
