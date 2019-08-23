///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_SpawnUnitFromAvenger.uc
//  AUTHOR:  David Burchanowski  --  11/05/2014
//  PURPOSE: Spawns a unit from the avenger reserves
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_SpawnUnitFromAvenger extends SequenceAction;

var XComGameState_Unit SpawnedUnit;

event Activated()
{	
	SpawnedUnit = SpawnUnitFromAvenger();

	OutputLinks[0].bHasImpulse = SpawnedUnit != none;
	OutputLinks[1].bHasImpulse = SpawnedUnit == none;
}

static function XComGameState_Unit SpawnUnitFromAvenger()
{
	local XComGameStateHistory History;
	local XComGameState_Unit StrategyUnit;

	History = `XCOMHISTORY;

	if(History.FindStartStateIndex() > 1) // this is a strategy game
	{
		// try to get a unit from the strategy game
		StrategyUnit = ChooseStrategyUnit(History);

		// and add it to the board
		return AddStrategyUnitToBoard(StrategyUnit, History);
	}
	else
	{
		// this is a debug game of some kind, so we need to make a new fake unit
		return CreateDebugUnit(History);
	}
}

// Scans the strategy game and chooses a unit to place on the game board
private static function XComGameState_Unit ChooseStrategyUnit(XComGameStateHistory History)
{
	local array<StateObjectReference> UnitsInPlay;
	local XComGameState_Unit UnitInPlay;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState StrategyState;
	local int LastStrategyStateIndex;
	local XComGameState_Unit StrategyUnit;

	LastStrategyStateIndex = History.FindStartStateIndex() - 1;
	if(LastStrategyStateIndex > 0)
	{
		// build a list of all units currently on the board, we will exclude them from consideration. Add non-xcom units as well
		// in case they are mind controlled or otherwise under the control of the enemy team
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitInPlay)
		{
			UnitsInPlay.AddItem(UnitInPlay.GetReference());
		}

		// grab the archived strategy state from the history and the headquarters object
		StrategyState = History.GetGameStateFromHistory(LastStrategyStateIndex, eReturnType_Copy, false);
		foreach StrategyState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		{
			break;
		}

		if(XComHQ == none)
		{
			`Redscreen("SeqAct_SpawnUnitFromAvenger: Could not find an XComGameState_HeadquartersXCom state in the archive!");
		}

		// and find a unit in the strategy state that is not on the board
		foreach StrategyState.IterateByClassType(class'XComGameState_Unit', StrategyUnit)
		{
			// only living soldier units please
			if (StrategyUnit.IsDead() || !StrategyUnit.IsSoldier() 	|| StrategyUnit.IsTraining() || StrategyUnit.IsOnCovertAction())
			{
				continue;
			}

			// only if we have already recruited this soldier
			if(XComHQ != none && XComHQ.Crew.Find('ObjectID', StrategyUnit.ObjectID) == INDEX_NONE)
			{
				continue;
			}

			// only if not already on the board
			if(UnitsInPlay.Find('ObjectID', StrategyUnit.ObjectID) != INDEX_NONE)
			{
				continue;
			}

			return StrategyUnit;
		}
	}

	return none;
}

// chooses a location for the unit to spawn in the spawn zone
private static function bool ChooseSpawnLocation(out Vector SpawnLocation)
{
	local XComParcelManager ParcelManager;
	local XComGroupSpawn SoldierSpawn;
	local array<Vector> FloorPoints;

	// attempt to find a place in the spawn zone for this unit to spawn in
	ParcelManager = `PARCELMGR;
	SoldierSpawn = ParcelManager.SoldierSpawn;

	if(SoldierSpawn == none) // check for test maps, just grab any spawn
	{
		foreach `XComGRI.AllActors(class'XComGroupSpawn', SoldierSpawn)
		{
			break;
		}
	}

	SoldierSpawn.GetValidFloorLocations(FloorPoints);
	if(FloorPoints.Length == 0)
	{
		return false;
	}
	else
	{
		SpawnLocation = FloorPoints[0];
		return true;
	}
}

// Places the given strategy unit on the game board
private static function XComGameState_Unit AddStrategyUnitToBoard(XComGameState_Unit Unit, XComGameStateHistory History)
{
	local X2TacticalGameRuleset Rules;
	local Vector SpawnLocation;
	local XComGameStateContext_TacticalGameRule NewGameStateContext;
	local XComGameState NewGameState;
	local XComGameState_Player PlayerState;
	local StateObjectReference ItemReference;
	local XComGameState_Item ItemState;

	if(Unit == none)
	{
		return none;
	}

	// pick a floor point at random to spawn the unit at
	if(!ChooseSpawnLocation(SpawnLocation))
	{
		return none;
	}

	// create the history frame with the new tactical unit state
	NewGameStateContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitAdded);
	NewGameState = NewGameStateContext.ContextBuildGameState( );

	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	Unit.BeginTacticalPlay(NewGameState);   // this needs to be called explicitly since we're adding an existing state directly into tactical
	Unit.SetVisibilityLocationFromVector(SpawnLocation);
	Unit.bSpawnedFromAvenger = true;

	// assign the new unit to the human team
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(PlayerState.GetTeam() == eTeam_XCom)
		{
			Unit.SetControllingPlayer(PlayerState.GetReference());
			break;
		}
	}

	// add item states. This needs to be done so that the visualizer sync picks up the IDs and
	// creates their visualizers
	foreach Unit.InventoryItems(ItemReference)
	{
		ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemReference.ObjectID));
		ItemState.BeginTacticalPlay(NewGameState);   // this needs to be called explicitly since we're adding an existing state directly into tactical

		// add any cosmetic items that might exists
		ItemState.CreateCosmeticItemUnit(NewGameState);
	}
	
	Rules = `TACTICALRULES;

	// submit it
	XComGameStateContext_TacticalGameRule(NewGameState.GetContext()).UnitRef = Unit.GetReference();
	Rules.SubmitGameState(NewGameState);

	// make sure the visualizer has been created so self-applied abilities have a target in the world
	Unit.FindOrCreateVisualizer(NewGameState);

	// add abilities
	// Must happen after unit is submitted, or it gets confused about when the unit is in play or not 
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Reserve Unit Abilities");
	Rules.InitializeUnitAbilities(NewGameState, Unit);

	// make the unit concealed, if they have Phantom
	// (special-case code, but this is how it works when starting a game normally)
	if (Unit.FindAbility('Phantom').ObjectID > 0)
	{
		Unit.EnterConcealmentNewGameState(NewGameState);
	}

	Rules.SubmitGameState(NewGameState);

	return Unit;
}

// Creates a random unit and places it on the game board
private static function XComGameState_Unit CreateDebugUnit(XComGameStateHistory History)
{
	local X2TacticalGameRuleset Rules;
	local Vector SpawnLocation;
	local XGCharacterGenerator CharacterGenerator;
	local X2CharacterTemplate CharTemplate;
	local XComGameStateContext_TacticalGameRule NewGameStateContext;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit;
	local XComGameState_Player PlayerState;
	local TSoldier Soldier;

	// pick a floor point at random to spawn the unit at
	if(!ChooseSpawnLocation(SpawnLocation))
	{
		return none;
	}

	NewGameStateContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_UnitAdded);
	NewGameState = NewGameStateContext.ContextBuildGameState();

	// generate a debug unit
	CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Soldier');
	`assert(CharTemplate != none);
	CharacterGenerator = `XCOMGRI.Spawn(CharTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != none);

	Unit = CharTemplate.CreateInstanceFromTemplate(NewGameState);
	
	// assign the player to him
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(PlayerState.GetTeam() == eTeam_XCom)
		{
			Unit.SetControllingPlayer(PlayerState.GetReference());
			break;
		}
	}

	// give him a loadout
	Unit.ApplyInventoryLoadout(NewGameState);

	// give him abilities
	Rules = `TACTICALRULES;
	Rules.InitializeUnitAbilities(NewGameState, Unit);

	// give him an appearance
	Soldier = CharacterGenerator.CreateTSoldier();
	Unit.SetTAppearance(Soldier.kAppearance);
	Unit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
	Unit.SetCountry(Soldier.nmCountry);

	// put him on the start tile
	Unit.SetVisibilityLocationFromVector(SpawnLocation);

	// submit the new unit
	XComGameStateContext_TacticalGameRule(NewGameState.GetContext()).UnitRef = Unit.GetReference();
	Rules.SubmitGameState(NewGameState);

	// and cleanup the generator object
	CharacterGenerator.Destroy();

	return Unit;
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Spawn Unit From Avenger"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	bAutoActivateOutputLinks=false
	
	OutputLinks(0)=(LinkDesc="Success")
	OutputLinks(1)=(LinkDesc="Avenger Empty")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Spawned Unit",PropertyName=SpawnedUnit)
}
