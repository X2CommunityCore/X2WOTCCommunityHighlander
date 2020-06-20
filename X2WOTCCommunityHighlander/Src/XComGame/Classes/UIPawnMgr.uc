class UIPawnMgr extends Actor;

struct CosmeticInfo
{
	var XComUnitPawn ArchetypePawn;
	var XComUnitPawn Pawn;
};

// Start Issue #885
struct MultiSlotWeaponsPawnInfo
{
	var array<Actor>   MultiSlotWeapons;
	var EInventorySlot InventorySlot;
};
// End Issue #885

struct PawnInfo
{
	var int PawnRef;
	var array<Actor> Referrers;
	var XComUnitPawn Pawn;
	var array<CosmeticInfo> Cosmetics;
	var array<Actor> Weapons;
	var bool bPawnRemoved;
	var vector Location;
	var Rotator Rotation;
	var bool bForceMenuState;
	var XComGameState_Unit Unit;
	var delegate<OnPawnCreated_PM> Callback;

	// Added variable for Issue #885
	var array<MultiSlotWeaponsPawnInfo> MultiSlotWeaponsPawnInfos;
};

var array<PawnInfo> Pawns;
var array<PawnInfo> CinematicPawns;
var array<PawnInfo> PhotoboothPawns;

var array<XComGameState_Unit> PawnsReadyToCreate;

var XComGameState CheckGameState;

delegate bool VariableNameTest(Name VarName);
delegate AsyncPackageLoadComplete(XComGameState_Unit Unit);
delegate OnPawnCreated_PM(XComUnitPawn Pawn);

simulated function XComUnitPawn CreatePawn(Actor referrer, XComGameState_Unit UnitState, Vector UseLocation, Rotator UseRotation, optional bool bForceMenuState)
{
	return UnitState.CreatePawn(referrer, UseLocation, UseRotation, bForceMenuState);
}

simulated function LoadPawnPackagesAsync(XComGameState_Unit UnitState, delegate<AsyncPackageLoadComplete> Callback)
{
	UnitState.LoadPawnPackagesAsync(none, vect(0, 0, 0), rot(0, 0, 0), Callback);
}

//this is the MP squad loadout we're checking for the units to spawn
simulated function SetCheckGameState(XComGameState MPGameState)
{
	CheckGameState = MPGameState;
}

function bool DefaultVariablePredicate(Name VarName)
{	
	return true;
}

function int GetPawnVariablesStartingWith(name VariableName, out array<name> VariableNames)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	WorldInfo.MyKismetVariableMgr.GetVariableStartingWith(VariableName, OutVariables);

	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			VariableNames.AddItem(SeqVarPawn.VarName);
		}
	}

	return VariableNames.Length;
}

function bool HasPawnVariable(name VariableName)
{
	local array<SequenceVariable> OutVariables;
	WorldInfo.MyKismetVariableMgr.GetVariable(VariableName, OutVariables);
	return (OutVariables.Length > 0);
}

function SetPawnVariable(XComUnitPawn UnitPawn, name VariableName)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	if (VariableName == '')
		return;

	WorldInfo.MyKismetVariableMgr.GetVariable(VariableName, OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(None);
			SeqVarPawn.SetObjectValue(UnitPawn);
		}
	}
}

function ClearPawnVariable(name VariableName)
{
	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;

	if (VariableName == '')
		return;

	WorldInfo.MyKismetVariableMgr.GetVariable(VariableName, OutVariables);
	foreach OutVariables(SeqVar)
	{
		SeqVarPawn = SeqVar_Object(SeqVar);
		if(SeqVarPawn != none)
		{
			SeqVarPawn.SetObjectValue(None);
		}
	}
}

//bHardAttach should be used if the cinematic pawn will be moving around with the cinedummy, ie. riding a lift or moving platform
simulated function XComUnitPawn RequestCinematicPawn(Actor referrer, int UnitRef, Vector UseLocation, Rotator UseRotation, optional name VariableName, optional name CineBaseTag, optional bool bCinedummyHardAttach)
{
	local XComUnitPawn Pawn;
	local SkeletalMeshActor CineDummy;
	local SkeletalMeshActor IterateActor;	
	local float ClosestCineDummyDistance; //Since the player can build certain rooms multiple times, we need to look for the closest cinedummy to use
	local float DistanceSq;
	
	if (CineBaseTag != '')
	{
		ClosestCineDummyDistance = 10000000.0f;
		foreach AllActors(class'SkeletalMeshActor', IterateActor)
		{
			if(IterateActor.Tag == CineBaseTag)
			{
				DistanceSq = VSizeSq(IterateActor.Location - UseLocation);
				if(DistanceSq < ClosestCineDummyDistance)
				{
					ClosestCineDummyDistance = DistanceSq;
					CineDummy = IterateActor;
				}
			}
		}

		UseLocation = vect(0, 0, 0); //If we are attaching to a cinedummy, don't have a local offset
		if(CineDummy == None)
		{
			if(referrer.Tag == CineBaseTag)
			{
				//Last ditch effort, in some situations the referrer can be the cinedummy, such as tentpole cinematics
				CineDummy = SkeletalMeshActor(referrer);
			}
			else
			{
				`redscreen("Could not locate cinedummy with tag:"@CineBaseTag@" This will result in incorrectly located base personnel! @acurrie");
			}
		}
	}
		
	Pawn = RequestPawnByIDInternal(referrer, UnitRef, UseLocation, UseRotation, CinematicPawns);
	Pawn.GotoState('InHQ');	
	Pawn.SetupForMatinee(CineDummy, true, true, bCinedummyHardAttach);
	if(VariableName != '')
	{
		SetPawnVariable(Pawn, VariableName);
	}
	return Pawn;
}

simulated function XComUnitPawn GetCosmeticArchetypePawn(int CosmeticSlot, int UnitRef, bool bUsePhotoboothPawns = false)
{
	local int PawnInfoIndex;

	if (bUsePhotoboothPawns)
	{
		PawnInfoIndex = PhotoboothPawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return GetCosmeticArchetypePawnInternal(PhotoboothPawns, CosmeticSlot, PawnInfoIndex);
		}
	}
	else
	{
		PawnInfoIndex = Pawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return GetCosmeticArchetypePawnInternal(Pawns, CosmeticSlot, PawnInfoIndex);
		}

		PawnInfoIndex = CinematicPawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return GetCosmeticArchetypePawnInternal(CinematicPawns, CosmeticSlot, PawnInfoIndex);
		}
	}

	return none;
}

simulated function XComUnitPawn GetCosmeticArchetypePawnInternal(out array<PawnInfo> PawnStore, int CosmeticSlot, int StoreIdx)
{
	if (CosmeticSlot >= PawnStore[StoreIdx].Cosmetics.Length)
		return none;

	return PawnStore[StoreIdx].Cosmetics[CosmeticSlot].ArchetypePawn;
}

simulated function XComUnitPawn GetCosmeticPawn(int CosmeticSlot, int UnitRef, bool bUsePhotoboothPawns = false)
{
	local int PawnInfoIndex;

	if (bUsePhotoboothPawns)
	{
		PawnInfoIndex = PhotoboothPawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return GetCosmeticPawnInternal(PhotoboothPawns, CosmeticSlot, PawnInfoIndex);
		}
	}
	else
	{
		PawnInfoIndex = Pawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return GetCosmeticPawnInternal(Pawns, CosmeticSlot, PawnInfoIndex);
		}

		PawnInfoIndex = CinematicPawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return GetCosmeticPawnInternal(CinematicPawns, CosmeticSlot, PawnInfoIndex);
		}
	}

	return none;
}

simulated function XComUnitPawn GetCosmeticPawnInternal(out array<PawnInfo> PawnStore, int CosmeticSlot, int StoreIdx)
{
	if (CosmeticSlot >= PawnStore[StoreIdx].Cosmetics.Length)
		return none;

	return PawnStore[StoreIdx].Cosmetics[CosmeticSlot].Pawn;
}

simulated function AssociateWeaponPawn(int CosmeticSlot, Actor WeaponPawn, int UnitRef,  XComUnitPawn OwningPawn, bool bUsePhotoboothPawns = false)
{
	local int PawnInfoIndex;

	if (bUsePhotoboothPawns)
	{
		PawnInfoIndex = PhotoboothPawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			AssociateWeaponPawnInternal(CosmeticSlot, WeaponPawn, PhotoboothPawns, PawnInfoIndex, OwningPawn);
			return;
		}
	}
	else
	{
		PawnInfoIndex = Pawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			AssociateWeaponPawnInternal(CosmeticSlot, WeaponPawn, Pawns, PawnInfoIndex, OwningPawn);
			return;
		}

		PawnInfoIndex = CinematicPawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			AssociateWeaponPawnInternal(CosmeticSlot, WeaponPawn, CinematicPawns, PawnInfoIndex, OwningPawn);
			return;
		}
	}

	`assert(false);
}

simulated function AssociateWeaponPawnInternal(int CosmeticSlot, Actor WeaponPawn, out array<PawnInfo> PawnStore, int StoreIdx, XComUnitPawn OwningPawn)
{
	local XGInventoryItem PreviousItem;
	`assert(StoreIdx != -1);

	if (PawnStore[StoreIdx].Weapons.Length <= CosmeticSlot)
		PawnStore[StoreIdx].Weapons.Length = CosmeticSlot + 1;

	if (PawnStore[StoreIdx].Weapons[CosmeticSlot] != WeaponPawn)
	{
		if (PawnStore[StoreIdx].Weapons[CosmeticSlot] != none)
		{
			PreviousItem = XGInventoryItem(PawnStore[StoreIdx].Weapons[CosmeticSlot]);
			OwningPawn.DetachItem(XComWeapon(PreviousItem.m_kEntity).Mesh);
			PawnStore[StoreIdx].Weapons[CosmeticSlot].Destroy();
		}
		PawnStore[StoreIdx].Weapons[CosmeticSlot] = WeaponPawn;
	}
}

simulated function XComUnitPawn AssociateCosmeticPawn(int CosmeticSlot, XComUnitPawn ArchetypePawn, int UnitRef,  XComUnitPawn OwningPawn, optional Vector UseLocation, optional Rotator UseRotation, bool bUsePhotoboothPawns = false)
{
	local int PawnInfoIndex;

	if (bUsePhotoboothPawns)
	{
		PawnInfoIndex = PhotoboothPawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return AssociateCosmeticPawnInternal(CosmeticSlot, ArchetypePawn, PhotoboothPawns, PawnInfoIndex, OwningPawn, UseLocation, UseRotation);
		}
	}
	else
	{
		PawnInfoIndex = Pawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return AssociateCosmeticPawnInternal(CosmeticSlot, ArchetypePawn, Pawns, PawnInfoIndex, OwningPawn, UseLocation, UseRotation);
		}

		PawnInfoIndex = CinematicPawns.Find('PawnRef', UnitRef);
		if (PawnInfoIndex != -1)
		{
			return AssociateCosmeticPawnInternal(CosmeticSlot, ArchetypePawn, CinematicPawns, PawnInfoIndex, OwningPawn, UseLocation, UseRotation);
		}
	}

	`assert(false);
	return none;
}

simulated function XComUnitPawn AssociateCosmeticPawnInternal(int CosmeticSlot, XComUnitPawn ArchetypePawn, out array<PawnInfo> PawnStore, int StoreIdx, XComUnitPawn OwningPawn, optional Vector UseLocation, optional Rotator UseRotation)
{
	local CosmeticInfo Cosmetic;

	`assert(StoreIdx != -1);

	if (PawnStore[StoreIdx].Cosmetics.Length <= CosmeticSlot)
		PawnStore[StoreIdx].Cosmetics.Length = CosmeticSlot + 1;

	if (PawnStore[StoreIdx].Cosmetics[CosmeticSlot].ArchetypePawn != ArchetypePawn)
	{
		if (PawnStore[StoreIdx].Cosmetics[CosmeticSlot].Pawn != none)
		{
			PawnStore[StoreIdx].Cosmetics[CosmeticSlot].Pawn.Destroy();
		}

		Cosmetic.ArchetypePawn = ArchetypePawn;
		Cosmetic.Pawn = class'Engine'.static.GetCurrentWorldInfo().Spawn( ArchetypePawn.Class, OwningPawn, , UseLocation, UseRotation, ArchetypePawn, true, eTeam_All );
		Cosmetic.Pawn.SetPhysics(PHYS_None);
		Cosmetic.Pawn.SetVisible(true);

		PawnStore[StoreIdx].Cosmetics[CosmeticSlot] = Cosmetic;
	}
	else
	{
		Cosmetic = PawnStore[StoreIdx].Cosmetics[CosmeticSlot];
	}
	return Cosmetic.Pawn;
}

// Start Issue #885
// This is an internal CHL API. It is not intended for use by mods and is not covered by Backwards Compatibility policy.
simulated function AssociateMultiSlotWeaponPawn(int MultiSlotIndex, Actor WeaponPawn, int UnitRef, XComUnitPawn OwningPawn, EInventorySlot InventorySlot, bool bUsePhotoboothPawns = false)
{
	local int StoreIndex;

	if (bUsePhotoboothPawns)
	{
		StoreIndex = PhotoboothPawns.Find('PawnRef', UnitRef);
		if (StoreIndex != -1)
		{
			AssociateMultiSlotWeaponPawnInternal(PhotoboothPawns, StoreIndex, MultiSlotIndex, WeaponPawn, OwningPawn, InventorySlot);
			return;
		}
	}
	else
	{
		StoreIndex = Pawns.Find('PawnRef', UnitRef);
		if (StoreIndex != -1)
		{
			AssociateMultiSlotWeaponPawnInternal(Pawns, StoreIndex, MultiSlotIndex, WeaponPawn, OwningPawn, InventorySlot);
			return;
		}

		StoreIndex = CinematicPawns.Find('PawnRef', UnitRef);
		if (StoreIndex != -1)
		{
			AssociateMultiSlotWeaponPawnInternal(CinematicPawns, StoreIndex, MultiSlotIndex, WeaponPawn, OwningPawn, InventorySlot);
			return;
		}
	}
}

simulated private function AssociateMultiSlotWeaponPawnInternal(out array<PawnInfo> PawnStore, int StoreIndex, int MultiSlotIndex, Actor WeaponPawn, XComUnitPawn OwningPawn, EInventorySlot InventorySlot)
{
	local MultiSlotWeaponsPawnInfo NewMultiSlotWeaponsPawnInfo;
	local XGInventoryItem          PreviousItem;
	local int i;

	// If the array of structs in PawnInfo already has a struct responsible for tracking weapons' visualizers in this Inventory Multi Slot, find it.
	i = PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos.Find('InventorySlot', InventorySlot);
	if (i == INDEX_NONE)
	{
		// If such a struct was not found, add it.
		NewMultiSlotWeaponsPawnInfo.InventorySlot = InventorySlot;
		PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos.AddItem(NewMultiSlotWeaponsPawnInfo);
		i = PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos.Length - 1;
	}

	if (PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons.Length <= MultiSlotIndex)
		PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons.Length = MultiSlotIndex + 1;

	if (PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons[MultiSlotIndex] != WeaponPawn)
	{
		if (PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons[MultiSlotIndex] != none)
		{
			PreviousItem = XGInventoryItem(PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons[MultiSlotIndex]);
			OwningPawn.DetachItem(XComWeapon(PreviousItem.m_kEntity).Mesh);
			PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons[MultiSlotIndex].Destroy();
		}
		PawnStore[StoreIndex].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons[MultiSlotIndex] = WeaponPawn;
	}
}
// End Issue #885

simulated function XComUnitPawn RequestPawnByState(Actor referrer, XComGameState_Unit UnitState, optional Vector UseLocation, optional Rotator UseRotation, optional delegate<OnPawnCreated_PM> Callback = none)
{
	return RequestPawnByStateInternal(referrer, UnitState, UseLocation, UseRotation, Pawns, Callback);
}

simulated function XComUnitPawn RequestPawnByStateInternal(Actor referrer, XComGameState_Unit UnitState, Vector UseLocation, Rotator UseRotation, out array<PawnInfo> PawnStore, delegate<OnPawnCreated_PM> Callback)
{
	local int PawnInfoIndex;
	local PawnInfo Info;

	PawnInfoIndex = PawnStore.Find('PawnRef', UnitState.ObjectID);
	if (PawnInfoIndex == -1)
	{
		Info.PawnRef = UnitState.ObjectID;
		Info.Location = UseLocation;
		Info.Rotation = UseRotation;
		Info.bForceMenuState = CheckGameState != none;
		Info.Referrers.AddItem(referrer);
		Info.Unit = UnitState;
		Info.Callback = Callback;

		if (Callback == none)
			Info.Pawn = CreatePawn(referrer, UnitState, UseLocation, UseRotation, CheckGameState != none);
		else
			LoadPawnPackagesAsync(UnitState, CreatePawnOnPackagesLoaded);
		
		PawnStore.AddItem(Info);
	}
	else if(PawnStore[PawnInfoIndex].bPawnRemoved)
	{
		PawnStore[PawnInfoIndex].Referrers.AddItem(referrer);
		PawnStore[PawnInfoIndex].Location = UseLocation;
		PawnStore[PawnInfoIndex].Rotation = UseRotation;
		PawnStore[PawnInfoIndex].bForceMenuState = CheckGameState != none;
		PawnStore[PawnInfoIndex].Callback = Callback;
		PawnStore[PawnInfoIndex].Unit = UnitState;

		if(Callback == none)
			PawnStore[PawnInfoIndex].Pawn = CreatePawn(referrer, UnitState, UseLocation, UseRotation, CheckGameState != none);
		else
			LoadPawnPackagesAsync(UnitState, CreatePawnOnPackagesLoaded);

		PawnStore[PawnInfoIndex].bPawnRemoved = false;
		Info = PawnStore[PawnInfoIndex];
	}
	else
	{
		Info = PawnStore[PawnInfoIndex];
		if (Info.Referrers.Find(referrer) == -1)
		{
			PawnStore[PawnInfoIndex].Referrers.AddItem(referrer);
		}

		if (Callback != none)
			Callback(Info.Pawn);
	}

	return Info.Pawn;
}

simulated function CreatePawnOnPackagesLoaded(XComGameState_Unit Unit)
{
	PawnsReadyToCreate.AddItem(Unit);
}

simulated function Tick(float DeltaTime)
{
	local int PawnInfoIndex;
	local delegate<OnPawnCreated_PM> Callback;
	local XComGameState_Unit Unit;
	local int i;

	for (i = 0; i < PawnsReadyToCreate.Length; ++i)
	{
		Unit = PawnsReadyToCreate[i];
		PawnInfoIndex = Pawns.Find('PawnRef', Unit.ObjectID);
		if (Unit.kAppearance == Pawns[PawnInfoIndex].Unit.kAppearance && Pawns[PawnInfoIndex].Pawn == none)
		{
			Pawns[PawnInfoIndex].Pawn = CreatePawn(Pawns[PawnInfoIndex].Referrers[0], Unit, Pawns[PawnInfoIndex].Location, Pawns[PawnInfoIndex].Rotation, Pawns[PawnInfoIndex].bForceMenuState);
			Callback = Pawns[PawnInfoIndex].Callback;
			Callback(Pawns[PawnInfoIndex].Pawn);
		}
	}

	PawnsReadyToCreate.Length = 0;

	Super.Tick(DeltaTime);
}

simulated function XComUnitPawn RequestPawnByID(Actor referrer, int UnitRef, optional Vector UseLocation, optional Rotator UseRotation)
{
	return RequestPawnByIDInternal(referrer, UnitRef, UseLocation, UseRotation, Pawns);
}

simulated function XComUnitPawn RequestPhotoboothPawnByID(Actor referrer, int UnitRef, optional Vector UseLocation, optional Rotator UseRotation, optional bool nmPawnOverride = false)
{
	return RequestPawnByIDInternal(referrer, UnitRef, UseLocation, UseRotation, PhotoboothPawns, nmPawnOverride);
}

simulated function XComUnitPawn RequestPawnByIDInternal(Actor referrer, int UnitRef, Vector UseLocation, Rotator UseRotation, out array<PawnInfo> PawnStore, optional bool nmPawnOverride = false)
{
	local XComGameState_Unit Unit;
	if(CheckGameState == none)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef));
	}
	else
	{
		Unit = XComGameState_Unit(CheckGameState.GetGameStateForObjectID(UnitRef));
	}

	if (nmPawnOverride)
	{
		//Hacky, but force the pawn to be a soldier pawn so that the unit will have the soldier personality animations
		if (!Unit.IsAlien())
		{
			if (Unit.GetMyTemplate().GetPawnNameFn != none)
			{
				Unit.kAppearance.nmPawn = Unit.GetMyTemplate().GetPawnNameFn(EGender(Unit.kAppearance.iGender));
			}
			else if (Unit.kAppearance.iGender == 1)
			{
				Unit.kAppearance.nmPawn = 'XCom_Soldier_M';
			}
			else
			{
				Unit.kAppearance.nmPawn = 'XCom_Soldier_F';
			}
		}
	}

	return RequestPawnByStateInternal(referrer, Unit, UseLocation, UseRotation, PawnStore, none);
}

simulated function ReleaseCinematicPawn(Actor referrer, int UnitRef, optional bool bForce)
{
	ReleasePawnInternal(referrer, UnitRef, CinematicPawns, bForce);
}

simulated function ReleasePawn(Actor referrer, int UnitRef, optional bool bForce)
{
	ReleasePawnInternal(referrer, UnitRef, Pawns, bForce);
}

simulated function ReleasePhotoboothPawn(Actor referrer, int UnitRef, optional bool bForce)
{
	ReleasePawnInternal(referrer, UnitRef, PhotoboothPawns, bForce);
}

simulated function DestroyPawns(int StoreIdx, out array<PawnInfo> PawnStore)
{
	local int idx;

	// Added variable for Issue #885
	local int i;

	PawnStore[StoreIdx].Pawn.Destroy();
	PawnStore[StoreIdx].Pawn = none;
	for ( idx = 0; idx < PawnStore[StoreIdx].Cosmetics.Length; ++idx )
	{
		if (PawnStore[StoreIdx].Cosmetics[idx].Pawn != none)
		{
			PawnStore[StoreIdx].Cosmetics[idx].Pawn.Destroy();
			PawnStore[StoreIdx].Cosmetics[idx].Pawn = none;

			//This is checked in various places to determine if the pawn should be re-made.
			//So, since we just Destroyed the Pawn, un-set this too.
			PawnStore[StoreIdx].Cosmetics[idx].ArchetypePawn = None;
		}
	}

	for ( idx = 0; idx < PawnStore[StoreIdx].Weapons.Length; ++idx )
	{
		if (PawnStore[StoreIdx].Weapons[idx] != none)
		{
			PawnStore[StoreIdx].Weapons[idx].Destroy();
			PawnStore[StoreIdx].Weapons[idx] = none;
		}
	}

	// Start Issue #885
	for (i = 0; i < PawnStore[StoreIdx].MultiSlotWeaponsPawnInfos.Length; i++)
	{
		for ( idx = 0; idx < PawnStore[StoreIdx].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons.Length; ++idx )
		{
			if (PawnStore[StoreIdx].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons[idx] != none)
			{
				PawnStore[StoreIdx].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons[idx].Destroy();
				PawnStore[StoreIdx].MultiSlotWeaponsPawnInfos[i].MultiSlotWeapons[idx] = none;
			}
		}
	}
	// End Issue #885
}

simulated function ReleasePawnInternal(Actor referrer, int UnitRef, out array<PawnInfo> PawnStore, optional bool bForce)
{
	local int PawnInfoIndex;

	PawnInfoIndex = PawnStore.Find('PawnRef', UnitRef);
	if (PawnInfoIndex == -1)
	{
		// red screen??
	}
	else if(bForce) // don't remove the entry from the array to preserve the Referrers
	{
		PawnStore[PawnInfoIndex].Referrers.RemoveItem(referrer);
		DestroyPawns(PawnInfoIndex, PawnStore);
		PawnStore[PawnInfoIndex].bPawnRemoved = true;
	}
	else
	{		
		PawnStore[PawnInfoIndex].Referrers.RemoveItem(referrer);
		if(PawnStore[PawnInfoIndex].Referrers.Length == 0)
		{
			DestroyPawns(PawnInfoIndex, PawnStore);
			PawnStore.Remove(PawnInfoIndex, 1);
		}
	}
}

simulated function XComGameState_Unit GetUnitState( int ObjectID )
{
	local PawnInfo Info;

	foreach Pawns(Info)
	{
		if ((Info.Unit != none) && (Info.Unit.ObjectID == ObjectID))
			return Info.Unit;
	}

	return none;
}

defaultproperties
{
}
