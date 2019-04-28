class XComParcelManager extends Object
	native(Core)
	dependson(XComTacticalMissionManager)
	config(Parcels);

const SMALLEST_PARCEL_SIZE = 16;

enum EParcelEntranceType
{
	EParcelEntranceType_N1,
	EParcelEntranceType_N2,
	EParcelEntranceType_E1,
	EParcelEntranceType_E2,
	EParcelEntranceType_S1,
	EParcelEntranceType_S2,
	EParcelEntranceType_W1,
	EParcelEntranceType_W2,
};

enum EEntranceLengthType
{
	eEntranceLengthType_1,
	eEntranceLengthType_2,
	eEntranceLengthType_3,
	eEntranceLengthType_4,
	eEntranceLengthType_5,
	eEntranceLengthType_6,
};

enum EParcelFacingType
{
	EParcelFacingType_None,
	EParcelFacingType_N,
	EParcelFacingType_E,
	EParcelFacingType_S,
	EParcelFacingType_W,
};


enum EParcelSizeType
{
	eParcelSizeType_Small,  // SMALLEST_PARCEL_SIZE x SMALLEST_PARCEL_SIZE      (16x16)
	eParcelSizeType_Medium, // SMALLEST_PARCEL_SIZE x 2*SMALLEST_PARCEL_SIZE    (16x32)
	eParcelSizeType_Large,  // 2*SMALLEST_PARCEL_SIZE x 2*SMALLEST_PARCEL_SIZE  (32x32)
};

enum EParcelSpawnDensity
{
	EParcelSpawnDensity_Dispersed,
	EParcelSpawnDensity_Compact,
};

enum EPIEForceInclude
{
	eForceInclude_None,
	eForceInclude_Plot,
	eForceInclude_Parcel,
};

struct native EntranceDefinition
{
	var string strPlotType;
	var EEntranceLengthType eLength;
	var XComLevelActor kArchetype;
	var bool bIsClosed;
};

struct native WeightedPlotType
{
	var string strPlotType;
	var float fWeight;

	structdefaultproperties
	{
		fWeight=1
	}
};

struct native ParcelDefinition
{
	var string MapName;
	var array<string> arrZoneTypes;
	var array<WeightedPlotType> arrPlotTypes;
	var array<string> arrBiomeTypes;

	var EParcelSizeType eSize;

	// When this parcel is used as an objective parcel, the objective groups that spawn on it should use this density for spawning.
	var EParcelSpawnDensity ObjectiveSpawnDensity;

	var bool bHasEntranceN1; // Has N1 Entrance
	var bool bHasEntranceN2; // Has N2 Entrance
	var bool bHasEntranceE1; // Has E1 Entrance
	var bool bHasEntranceE2; // Has E2 Entrance
	var bool bHasEntranceS1; // Has S1 Entrance
	var bool bHasEntranceS2; // Has S2 Entrance
	var bool bHasEntranceW1; // Has W1 Entrance
	var bool bHasEntranceW2; // Has W2 Entrance

	var EParcelFacingType eFacing; // Which direction is the street front facing

	var int bForceEntranceCount;  // Number of entrances that must be spawnable for this def to be used

	var array<string> ObjectiveTags;  // Array of tags matched to a mission's valid/invalid tag list to cull objective parcels by mission type

	var bool bAllowNonObjectiveOverride; // Normally, ObjectiveTags.Length > 0 means this cannot be used as a normal parcel,
										 // but you can set this to true to allow it anyway.

	var array<string> arrAvailableLayers;
	var int iAlienGroupModifier; // Number that modifies the number of alien groups on Objective parcels, can be + or -.
};

struct native PCPDefinition
{
	var string strPCPType;
	var string strTurnType;
	var array<string> arrPlotTypes;
	var array<string> arrBiomeTypes;
	var string MapName;
	var int iWidth;
	var int iLength;
	var array<string> ObjectiveTags;  // Array of tags matched to a mission's valid/invalid tag list to cull objective parcels (and pcps!) by mission type
	var bool bAllowNonObjectiveOverride; // Normally, ObjectiveTags.Length > 0 means this cannot be used as a normal pcp,
										 // but you can set this to true to allow it anyway.
	
	var array<string> arrAvailableLayers;
	var bool bAdventCheckpoint;
};

// stores spawned entrance info from a generated map for loading
struct native StoredMapData_Entrance
{
	var Vector  Location;
	var Rotator Rotation;
	var string SpawnedArchetype;
};

//Stores map piece elements for the GeneratedMapData structure. Primarily parcels.
struct native StoredMapData_Parcel
{
	var Vector  Location;
	var Rotator Rotation;
	var string  MapName;
	var int     ParcelArrayIndex; //Indicates which element of arrParcels this definition corresponds to
	var int		BrandIndex;
	var array<StoredMapData_Entrance> SpawnedEntrances;

	structcpptext
	{
		FStoredMapData_Parcel()
		{
			appMemzero(this, sizeof(FStoredMapData_Parcel));
		}

		FStoredMapData_Parcel(EEventParm)
		{
			appMemzero(this, sizeof(FStoredMapData_Parcel));
		}
	}
};

//This structure stores the data necessary to reconstruct / examine the output of the
//map generation process.
struct native StoredMapData
{
	//Mission related information
	var MissionDefinition ActiveMission;          //Data relating to the primary mission for this map
	var Name ActiveMissionSchedule;
	var name ActiveQuestItemTemplate;

	//Indices into the ParcelData array
	var int ObjectiveParcelIndex;
	var Vector SoldierSpawnLocation;
	var Vector ObjectiveLocation;
	var Vector SoldierExitLocation;
	
	//Plot information
	var string PlotMapName;

	// Biome
	var string Biome;

	//Environment lighting / time of day
	var string EnvironmentLightingMapName;

	//Store the state of the layer system
	var init array<int> ActiveLayers;

	//Map pieces / parcels
	var array<StoredMapData_Parcel> ParcelData;
	var array<StoredMapData_Parcel> PlotCoverParcelData;
	var array<StoredMapData_Entrance> EntranceData;

	structdefaultproperties
	{
		ObjectiveParcelIndex = -1
	}
};

// Single entry in the backtracking generation algorithm stack.
// Keeps track of our partial solutions.
struct native ParcelBacktrackStackEntry
{
	var int CurrentParcelIndex;
	var Rotator Rotation; // Rotation to apply to this parcel to make it fit.
};

cpptext
{
	void Init();

	// helper struct allow us to sort the parcels without recomputing the priority indices
	// on every comparison
	struct FPlotSortHelper
	{
		FPlotDefinition PlotDef;
		INT PlotTypeIndex;
		INT PlotIndex;

		FPlotSortHelper()
		{
			appMemzero(this, sizeof(FPlotSortHelper));
		}

		FPlotSortHelper(EEventParm)
		{
			appMemzero(this, sizeof(FPlotSortHelper));
		}
	};

private:

#if XCOM_RETAIL
	void RemoveNonRetailPlots();
#endif

}

// Begin issue #404
var config(Plots) array<PlotDefinition> arrPlots;
var config array<ParcelDefinition> arrAllParcelDefinitions;
var config(Plots) array<EntranceDefinition> arrAllEntranceDefinitions;
var config(Plots) array<PlotTypeDefinition> arrPlotTypes;
var config(Plots) array<BiomeDefinition> arrBiomes;
var config array<string> arrParcelTypes;
var config(Plots) float MaxDegreesToSpawnExit;
var config(Plots) float MaxDistanceBetweenParcelToPlotPatrolLinks;
var config(Plots) float SoldierSpawnSlush;
// End issue #404

var privatewrite array<EntranceDefinition> arrEntranceDefinitions;

var privatewrite PlotTypeDefinition PlotType;

var int iLevelSeed;

var privatewrite array<XComParcel> arrParcels;
var XComParcel ObjectiveParcel;

var privatewrite XComPlotCoverParcelManager kPCPManager;

//Used by the editor to force certain maps to load
var EPIEForceInclude    ForceIncludeType; //Set to a value other than eForceInclude_None prior to running generate map.
var PlotDefinition      ForceIncludePlot;
var ParcelDefinition    ForceIncludeParcel;

var array<string> arrLayers;

var bool bToggleChaos;

var string ForceBiome;
var string ForceLighting;

var privatewrite XComGroupSpawn SoldierSpawn;
var privatewrite XComGroupSpawn LevelExit;

var bool bBlockingLoadParcels;

var privatewrite bool bGeneratingMap;
var privatewrite string GeneratingMapPhaseText;
var privatewrite int GeneratingMapPhase;
var bool bFinishedGeneratingMap;

//A start state object that is cached in InitParcels. Before using, always check for bReadonly to ensure that the start state it is a part of is still writable
var XComGameState_BattleData BattleDataState;

// the backtrack stack for the layout algorithm
var private array<ParcelBacktrackStackEntry> BacktrackStack;

var XComEnvLightingManager      EnvLightingManager;
var XComTacticalMissionManager  TacticalMissionManager;

var transient array<object> SwappedObjectsToClear;

// delegate hook to allow rerouting of error output to an arbitrary receiever.
delegate ParcelGenerationAssertDelegate(string FullErrorMessage);

event ParcelGenerationAssert(bool Condition, string ErrorMessage)
{
	local string FullErrorMessage;

	if(!Condition)
	{
		FullErrorMessage = "Error in Parcel/Mission Generation!\n";
		FullErrorMessage $= ErrorMessage $ "\n";

		FullErrorMessage $= "Using:\n";

		FullErrorMessage $= " Mission: " $ TacticalMissionManager.ActiveMission.MissionName $ "\n";
		FullErrorMessage $= " Plot Map: " $ BattleDataState.MapData.PlotMapName $ "\n";
	
		if(ObjectiveParcel != none)
		{
			FullErrorMessage $= " Objective Map:" $ ObjectiveParcel.ParcelDef.MapName $ "\n";
		}
	
		if(ParcelGenerationAssertDelegate != none)
		{
			ParcelGenerationAssertDelegate(FullErrorMessage);
		}
		else
		{
			`Redscreen(FullErrorMessage);
		}
	}
}

// Normally, evac zones are spawned by xcom as part of mission flow, however, it is also possible for the LDs to
// hand place them in the level.
function InitPlacedEvacZone()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local X2TacticalGameRuleset Rules;
	local X2Actor_EvacZone EvacZone;
	local XComGameState NewGameState;
	local XComGameState_EvacZone EvacZoneState;
	local bool SubmitState;
	local int EvacZoneCount;

	foreach `BATTLE.AllActors(class'X2Actor_EvacZone', EvacZone)
	{
		// catch more than one evac zone in the world errors
		EvacZoneCount++;
		if(EvacZoneCount > 1)
		{
			`Redscreen("More than one evac zone placed in the world, this is unsupported.");
			break;
		}

		History = `XCOMHISTORY;
		WorldData = `XWORLD;

		//Build the new game state data
		NewGameState = History.GetStartState();
		if(NewGameState == none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding placed evac zone state");
			SubmitState = true;
		}

		EvacZoneState = XComGameState_EvacZone(NewGameState.CreateNewStateObject(class'XComGameState_EvacZone'));
		EvacZoneState.SetCenterLocation(WorldData.GetTileCoordinatesFromPosition(EvacZone.Location));

		// submit if needed
		if(SubmitState)
		{
			Rules = `TACTICALRULES;
			if(Rules == none || !Rules.SubmitGameState(NewGameState))
			{
				`Redscreen("Unable to submit evac zone state!");
			}
		}

		// and init the actor
		EvacZone.InitEvacZone(EvacZoneState);
	}
}

function XComGroupSpawn SpawnLevelExit()
{
	local array<XComGroupSpawn> arrAllExits;
	local XComGroupSpawn kExit;
	local XComGameState NewState;

	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComGroupSpawn', kExit)
	{
		arrAllExits.AddItem(kExit);
	}

	ParcelGenerationAssert(arrAllExits.Length > 0, "No Exit could be spawned, no XComGroupSpawn Actors were found!");

	arrAllExits.RandomizeOrder();
	
	// sort is stable so all exits that are equally "good" will be chosen from randomly
	arrAllExits.Sort(SortLevelExits);

	assert(ScoreLevelExit(arrAllExits[0]) >= ScoreLevelExit(arrAllExits[arrAllExits.Length - 1]));

	// all of the highest score are at the front, so just pull the first one. We randomized the input.
	LevelExit = arrAllExits[0];
	LevelExit.SetVisible(true);

	LevelExit.TriggerGlobalEventClass(class'SeqEvent_OnTacticalExitCreated', LevelExit, 0);

	// save it to the history
	NewState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Level Exit Spawned");
	BattleDataState = XComGameState_BattleData(NewState.ModifyStateObject(class'XComGameState_BattleData', BattleDataState.ObjectID));
	BattleDataState.MapData.SoldierExitLocation = LevelExit.Location;
	`TACTICALRULES.SubmitGameState(NewState);

	return LevelExit;
}

private function int ScoreLevelExit(XComGroupSpawn Exit)
{
	local Vector ObjectiveToSpawn;
	local Vector ObjectivetoExit;
	local float DistanceFromObjective;
	local float Score;
	local float Cosine;

	ObjectiveToExit = Exit.Location - BattleDataState.MapData.ObjectiveLocation;
	DistanceFromObjective = VSize(ObjectiveToSpawn);

	// most important thing, are we a minimum distance away?
	if(DistanceFromObjective > TacticalMissionManager.ActiveMission.iExitFromObjectiveMinTiles)
	{
		Score += 4;
	}

	// second most important thing, are we within a certain range of angles away from the 
	// spawn to objective vector? This discourages backtracking
	ObjectiveToSpawn = SoldierSpawn.Location - BattleDataState.MapData.ObjectiveLocation;
	Cosine = Normal(ObjectiveToExit) dot Normal(ObjectiveToSpawn);
	if(Cosine > cos(MaxDegreesToSpawnExit * DegToRad))
	{
		Score += 2;
	}

	// lastly, try to stay below a certain distance
	if(DistanceFromObjective < TacticalMissionManager.ActiveMission.iExitFromObjectiveMaxTiles)
	{
		Score += 1;
	}

	return Score;
}

private function int SortLevelExits(XComGroupSpawn Exit1, XComGroupSpawn Exit2)
{
	local int ExitScore1;
	local int ExitScore2;

	ExitScore1 = ScoreLevelExit(Exit1);
	ExitScore2 = ScoreLevelExit(Exit2);

	if(ExitScore1 == ExitScore2)
	{
		return 0;
	}
	else
	{
		return ExitScore1 > ExitScore2 ? 1 : -1;
	}
}

native function CleanupLevelReferences();
native function PlotDefinition GetPlotDefinition(string strMapName, string strBiome="");
native function int GetMinimumCivilianCount();

function OutputParcelInfo(optional bool DarkLines = false)
{
	local XComParcel kParcel;
	local XComPlotCoverParcel kPCP;
	local XComWorldData WorldData;
	local BoxSphereBounds Bounds;
	local string strTemp;
	local int iRotXDegrees;
	local int iRotYDegrees;
	local int iRotZDegrees;
	local int ColorIntensity;

	ColorIntensity = DarkLines ? 25 : 255;

	WorldData = `XWORLD;
	foreach `XWORLDINFO.AllActors(class'XComParcel', kParcel)
	{
		if (kParcel.bDeleteMe == false && kParcel.bPendingDelete == false)
		{
			iRotXDegrees = (((kParcel.Rotation.Pitch%65536)/16384)*90);
			iRotYDegrees = (((kParcel.Rotation.Yaw%65536)/16384)*90);
			iRotZDegrees = (((kParcel.Rotation.Roll%65536)/16384)*90);
			
			// draw a box that shows the extend of what is contained in the parcel. Note that it is adjusted slightly to be taller and
			// slightly smaller so that adjacent boxes don't overlap.
			Bounds = kParcel.ParcelMesh.Bounds;
			Bounds.Origin.Z = 37 + WorldData.GetFloorZForPosition(Bounds.Origin); // 32 units up (half the extent), plus a bit extra to avoid ground clipping
			Bounds.BoxExtent.Z = 64;
			kParcel.DrawDebugBox(Bounds.Origin, Bounds.BoxExtent, ColorIntensity, 0, ColorIntensity, true);

			strTemp = "LevelSeed:"@`BATTLE.iLevelSeed@"\nParcel:"@kParcel.ParcelDef.MapName@" Rot:"$iRotXDegrees@","@iRotYDegrees@","@iRotZDegrees;
			`log(strTemp,,'XCom_ParcelOutput');
			kParcel.DrawDebugString(Bounds.Origin, strTemp, none, MakeColor(ColorIntensity, 0, ColorIntensity, 255));
		}
	}

	foreach `XWORLDINFO.AllActors(class'XComPlotCoverParcel', kPCP)
	{
		if (kParcel.bDeleteMe == false && kParcel.bPendingDelete == false)
		{
			iRotXDegrees = (((kPCP.Rotation.Pitch%65536)/16384)*90);
			iRotYDegrees = (((kPCP.Rotation.Yaw%65536)/16384)*90);
			iRotZDegrees = (((kPCP.Rotation.Roll%65536)/16384)*90);

			Bounds = kPCP.ParcelMesh.Bounds;
			Bounds.Origin.Z = 37 + WorldData.GetFloorZForPosition(Bounds.Origin);
			Bounds.BoxExtent.Z = 64;
			kPCP.DrawDebugBox(Bounds.Origin, Bounds.BoxExtent, ColorIntensity, ColorIntensity, 0, true);

			strTemp = "PCP:"@kPCP.strLevelName@" Rot:"$iRotXDegrees@","@iRotYDegrees@","@iRotZDegrees@"\n";
			`log(strTemp,,'XCom_ParcelOutput');
			kPCP.DrawDebugString(Bounds.Origin, strTemp, none, MakeColor(ColorIntensity, ColorIntensity, 0, 255));
		}
	}	
}

native function LinkParcelPatrolPathsToPlotPaths();
native function ClearLinksFromParcelPatrolPathsToPlotPaths();

private function CacheParcels()
{
	local XComParcel Parcel;

	arrParcels.Length = 0;

	foreach `XWORLDINFO.AllActors(class'XComParcel', Parcel)
	{
		if (Parcel.bDeleteMe == false && Parcel.bPendingDelete == false)
		{
			arrParcels.AddItem(Parcel);
		}
	}

	
	// sort the parcels. This ensures that load order doesn't change their location in
	// the array from run to run
	arrParcels.Sort(SortParcels);
}

// We need to sort the parcel actors before filling them out so that we guarantee
// that they are in a consistent order. They do not always load in the same order, and this will
// prevent the layout algorithm from coming up with the same solution when given the
// same seed
private function int SortParcels(XComParcel Parcel1, XComParcel Parcel2)
{
	if(Parcel1.Location.X == Parcel2.Location.X)
	{
		return Parcel1.Location.Y > Parcel2.Location.Y ? 1 : -1;
	}
	else
	{
		return Parcel1.Location.X > Parcel2.Location.X ? 1 : -1;
	}
}


// get the current priority list of parcel definitions from the card manager based on how recently they were seen
// by the player.
private function array<ParcelDefinition> GetRandomizedParcelDefinitions()
{
	local X2CardManager CardManager;
	local array<string> ParcelMapNames;
	local string ParcelMapName;
	local array<ParcelDefinition> Result;
	local ParcelDefinition ParcelDef;
	local int PlotTypeIndex;
	local XComMapManager MapManager;

	CardManager = class'X2CardManager'.static.GetCardManager();
	MapManager = `MAPS;

	// add cards for all parcel definitions that are of the correct plot type
	// it's possible that parcels were added since the last time the game was run, so this needs to happen every
	// time we generate a map
	foreach arrAllParcelDefinitions(ParcelDef)
	{
		PlotTypeIndex = ParcelDef.arrPlotTypes.Find('strPlotType', PlotType.strType);
		if(PlotTypeIndex != INDEX_NONE) // only need to add cards for parcels we will actually check
		{
			CardManager.AddCardToDeck('Parcels', ParcelDef.MapName, ParcelDef.arrPlotTypes[PlotTypeIndex].fWeight);
		}
	}

	// Get the current priority order of maps. Most recently seen maps will be at the end of the array
	CardManager.GetAllCardsInDeck('Parcels', ParcelMapNames);

	// and get the parcel def for each map
	foreach ParcelMapNames(ParcelMapName)
	{
		if (!MapManager.DoesMapPackageExist(ParcelMapName))
		{
			`Redscreen("ERROR: UXComParcelManager::GetRandomizedParcelDefinitions - Excluding Parcel Map: '"@ParcelMapName@"', Unable to find associated package");
			CardManager.RemoveCardFromDeck('Parcels', ParcelMapName);
			continue;
		}

		if(GetParcelDefinitionForMapname(ParcelMapName, ParcelDef))
		{
			if(ParcelDef.arrPlotTypes.Find('strPlotType', PlotType.strType) != INDEX_NONE) // could be other plot type cards from previous missions in the deck
			{
				Result.AddItem(ParcelDef);
			}
		}
	}

	// and return
	return Result;
}

private function GenerateParcelLayout()
{
	local array<ParcelDefinition> RandomizedParcelDefinitions;

	//Clear out the battle data object
	BattleDataState.MapData.ActiveLayers.Length = 0;
	BattleDataState.MapData.ParcelData.Length = 0;
	BattleDataState.MapData.PlotCoverParcelData.Length = 0;

	ComputePlotType();

	// grab all parcels on the map
	CacheParcels();

	// this needs to be initalized in case we need to inspect the pcp definitons to
	// choose an objective PCP
	kPCPManager = new class'XComPlotCoverParcelManager';
	kPCPManager.InitPlotCoverParcels(PlotType.strType, BattleDataState);

	// get a randomized array of parcel definitions. Since the layout algorithm is deterministic, we
	// randomize the input data to get a random output
	RandomizedParcelDefinitions = GetRandomizedParcelDefinitions();

	// now choose our parcels
	if(TacticalMissionManager.ActiveMission.ObjectiveSpawnsOnPCP)
	{
		ChooseObjectivePCP();
	}
	else
	{
		ChooseObjectiveParcel(RandomizedParcelDefinitions);
	}

	ChooseNonObjectiveParcels(RandomizedParcelDefinitions);

	// fill out the pcps first and start them loading
	kPCPManager.bBlockingLoadParcels = bBlockingLoadParcels;
	kPCPManager.ChoosePCPs();
	kPCPManager.InitPeripheryPCPs();
}

private function ChooseNonObjectiveParcels(array<ParcelDefinition> RandomizedParcelDefinitions)
{
	local array<XComParcel> ParcelsToLayout;
	local ParcelDefinition CurrentParcelDef;
	local XComParcel CurrentParcel;
	local Rotator Rotation;
	local int StackTop;
	local bool Finished;
	local int Index;

	// the parcel layout generation uses an exhaustive backtracking algorithm to determine the
	// parcels that will be used. It exhaustively searches the possible valid combinations until
	// a solution is found. Since the input arrays are randomized, the first solution found
	// will also be randomized.
	// See http://en.wikipedia.org/wiki/Backtracking for more info

	ParcelsToLayout = arrParcels;

	// objective parcel is filled elsewhere
	ParcelsToLayout.RemoveItem(ObjectiveParcel);
	RandomizedParcelDefinitions.RemoveItem(ObjectiveParcel.ParcelDef);

	// Whenever there are no parcels to layout, the backtracking algorithm will get into an infinite loop, so just bail early
	if (ParcelsToLayout.Length == 0)
	{
		return;
	}

	// now search for a valid solution that will fill all of the parcels
	BacktrackStack.Add(1);
	while(!Finished)
	{
		StackTop = BacktrackStack.Length - 1;

		if(BacktrackStack[StackTop].CurrentParcelIndex >= RandomizedParcelDefinitions.Length) // we need to backtrack
		{
			if(StackTop == 0)
			{
				// we can't backtrack any further, so there is no valid solution to the layout rules
				Finished = true;
			}
			else
			{
				// Backtrack. There is no parceldef we can place here that will satisfy the layout rules.
				// So try changing what has come before
				BackTrackStack.Remove(StackTop, 1);
				BackTrackStack[StackTop - 1].CurrentParcelIndex++; // advance the parcel below us, so we start trying the next partial solution
			}
		}
		else
		{
			// try the next parcel def for this parcel
			CurrentParcel = ParcelsToLayout[StackTop];
			CurrentParcelDef = RandomizedParcelDefinitions[BacktrackStack[StackTop].CurrentParcelIndex];

			if(IsParcelDefinitionValidForLayout(CurrentParcelDef, CurrentParcel, Rotation, RandomizedParcelDefinitions))
			{
				BacktrackStack[StackTop].Rotation = Rotation;

				if(BackTrackStack.Length == ParcelsToLayout.Length)
				{
					// All parcels have been successfully filled out
					Finished = true;
				}
				else
				{
					// this parcel fits here, move on to the next one
					BacktrackStack.Add(1);
				}
			}
			else
			{
				// this parcel def doesn't fit, try the next one
				BacktrackStack[StackTop].CurrentParcelIndex++;
			}
		}
	}

	if(BacktrackStack.Length == ParcelsToLayout.Length)
	{
		 // we found a valid layout
		// load the maps in the backtrack stack
		for(Index = 0; Index < ParcelsToLayout.Length; Index++)
		{
			CurrentParcelDef = RandomizedParcelDefinitions[BacktrackStack[Index].CurrentParcelIndex];
			InitParcelWithDef(ParcelsToLayout[Index], CurrentParcelDef, BacktrackStack[Index].Rotation, false );
		}
	}
	else
	{
		// no valid layout exists, this could be because the LDs are still prototyping and don't have enough parcel maps
		// to uniquely cover every parcel.
		// Just randomly fill out the parcels, without worrying about dupes.
		BacktrackStack.Length = 0;

		ParcelGenerationAssert(false, "Could not find a layout solution without duplicating parcel maps. Randomly selecting parcels...");
		foreach ParcelsToLayout(CurrentParcel)
		{
			foreach RandomizedParcelDefinitions(CurrentParcelDef)
			{
				if(IsParcelDefinitionValidForLayout(CurrentParcelDef, CurrentParcel, Rotation))
				{
					InitParcelWithDef(CurrentParcel, CurrentParcelDef, Rotation, false);
					break;
				}
			}
		}
	}

	// clean this up so it isn't stale
	BacktrackStack.Length = 0;
}

// this is only meant to be called from layout algorithm. It is not a general purpose function 
private function bool IsParcelDefinitionValidForLayout(ParcelDefinition ParcelDef, 
														XComParcel Parcel, 
														out Rotator Rotation,
														optional array<ParcelDefinition> RandomizedParcelDefinitions)
{
	local int Index;

	// check if we fit here
	if(ParcelDef.eSize != Parcel.GetSizeType())
	{
		return false;
	}

	// don't allow definitions that are locked to being objective parcels
	if(ParcelDef.ObjectiveTags.Length > 0 && !ParcelDef.bAllowNonObjectiveOverride)
	{
		return false;
	}

	// don't dupe the parcel map for the objective parcel
	if(ParcelDef.MapName == ObjectiveParcel.ParcelDef.MapName)
	{
		return false;
	}

	// now check to see if it collides with any previously placed parcel definitions
	for(Index = 0; Index < BacktrackStack.Length - 1; Index++) // length minus 1, since this parcel is on top of the stack
	{
		if(RandomizedParcelDefinitions[BacktrackStack[Index].CurrentParcelIndex].MapName == ParcelDef.MapName)
		{
			// a previous parcel has already claimed this parcel definition, let's not duplicate it
			return false;
		}
	};

	// Check general requirements. Do this last as these tests are more expensive
	if(!MeetsFacingAndEntranceRequirements(ParcelDef, Parcel, Rotation))
	{
		return false;
	}

	if(!MeetsZoningRequirements(Parcel, ParcelDef.arrZoneTypes))
	{
		return false;
	}

	if(!MeetsLayerRequirements(Parcel, ParcelDef))
	{
		return false;
	}

	return true;
}

private function ChooseObjectiveParcel(array<ParcelDefinition> RandomizedParcelDefinitions)
{
	local array<ParcelDefinition> ValidDefinitions;
	local ParcelDefinition ParcelDef;
	local int ParcelIndex;
	local XComParcel Parcel;
	local Rotator Rotation;
	local XComPlayerController PlayerController;

	// get all valid objective definitions
	GetValidParcelDefinitionsForObjective(RandomizedParcelDefinitions,
										  ValidDefinitions);

	ParcelGenerationAssert(ValidDefinitions.Length > 0, "No valid objective definitions were found"); // no parcel definition that we can use as the objective exists!
	ParcelGenerationAssert(arrParcels.Length > 0, "No parcels were found, was a plot map not loaded?"); // no parcels, did we load a map?

	//Inform the briefing screen that we have chosen the objective parcel
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComPlayerController', PlayerController)
	{
		break;
	}

	// try every combination iteratively until we find a parcel that can take a valid objective def
	foreach ValidDefinitions(ParcelDef)
	{
		for(ParcelIndex = 0; ParcelIndex < arrParcels.Length; ParcelIndex++)
		{
			Parcel = arrParcels[ParcelIndex];
			if(Parcel.CanBeObjectiveParcel
				&& Parcel.GetSizeType() == ParcelDef.eSize
				&& MeetsFacingAndEntranceRequirements(ParcelDef, Parcel, Rotation)
				&& MeetsZoningRequirements(Parcel, ParcelDef.arrZoneTypes)
				&& MeetsLayerRequirements(Parcel, ParcelDef))
			{
				ObjectiveParcel = Parcel;
				BattleDataState.MapData.ObjectiveParcelIndex = ParcelIndex;
				InitParcelWithDef(Parcel, ParcelDef, Rotation, false);				
				PlayerController.UpdateUIBriefingScreen(ParcelDef.MapName);
				return;
			}
		}
	}

	// safety fallback in case we can't find a valid place to put an objective parcel. Just put it anywhere it will
	// generally fit.
	ParcelGenerationAssert(false, "Could not find a valid objective parcel.");
	foreach ValidDefinitions(ParcelDef)
	{
		ParcelDef.bForceEntranceCount = 0; // ignore entrances
		for(ParcelIndex = 0; ParcelIndex < arrParcels.Length; ParcelIndex++)
		{
			Parcel = arrParcels[ParcelIndex];
			if(Parcel.GetSizeType() == ParcelDef.eSize
				&& MeetsFacingAndEntranceRequirements(ParcelDef, Parcel, Rotation))
			{
				ObjectiveParcel = Parcel;
				InitParcelWithDef(Parcel, ParcelDef, Rotation, false);
				PlayerController.UpdateUIBriefingScreen(ParcelDef.MapName);
				return;
			}
		}
	}
}

// Filters the provided list of parcels down to only objective parcels valid for the current mission.
native function GetValidParcelDefinitionsForObjective(array<ParcelDefinition> Definitions, out array<ParcelDefinition> ValidDefinitions);

// returns true if the given plot can be used with the given mission
native function bool IsPlotValidForMission(const out PlotDefinition PlotDef, const out MissionDefinition MissionDef) const;

// Gets all plot that are valid for the specified mission, in priority order
native function GetValidPlotsForMission(out array<PlotDefinition> ValidPlots, const out MissionDefinition Mission, optional string Biome = "");

//-------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------

private function ChooseObjectivePCP()
{
	local WorldInfo World;
	local XComPlotCoverParcel ObjectivePCP;
	local XComPlotCoverParcel PCP;
	local array<PCPDefinition> ValidPCPDefinitons;
	local PCPDefinition ObjectivePCPDefiniton;
	local int TotalValid;
	local XComPlayerController PlayerController;

	World = `XWORLDINFO;

	// pick a valid objectivePCP at random
	foreach World.AllActors(class'XComPlotCoverParcel', PCP)
	{
		if(PCP.bCanBeObjective)
		{
			TotalValid++;
			if(ObjectivePCP == none || `SYNC_RAND(TotalValid) == 0)
			{
				ObjectivePCP = PCP;
			}
		}
	}
	
	if(ObjectivePCP == none)
	{
		ParcelGenerationAssert(false, "No XComPlotCoverParcel actor on this map is marked bCanBeObjective == true.");
		foreach World.AllActors(class'XComPlotCoverParcel', ObjectivePCP)
		{
			break; // just use the first one as a fallback, better to spawn an objective somewhere than not at all
		}
	}

	BattleDataState.MapData.ObjectiveParcelIndex = -1;

	// Spawn a parcel at this location
	ObjectiveParcel = World.Spawn(class'XComParcel', World,, ObjectivePCP.Location, ObjectivePCP.Rotation);
	arrParcels.AddItem(ObjectiveParcel);

	// and fill out the objective parcel parcel def with all the information it needs to
	// load in the pcp map
	ValidPCPDefinitons = kPCPManager.GetValidObjectivePCPDefs(ObjectivePCP, TacticalMissionManager.ActiveMission);
	ParcelGenerationAssert(ValidPCPDefinitons.Length > 0, "No valid PCPDefinition found for the objective PCP actor");
	ObjectivePCPDefiniton = ValidPCPDefinitons[`SYNC_RAND(ValidPCPDefinitons.Length)];

	//Inform the briefing screen that we have chosen the objective parcel
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComPlayerController', PlayerController)
	{
		break;
	}

	PlayerController.UpdateUIBriefingScreen(ObjectivePCPDefiniton.MapName);

	ObjectiveParcel.ParcelDef.MapName = ObjectivePCPDefiniton.MapName;
	ObjectiveParcel.ParcelDef.arrAvailableLayers = ObjectivePCPDefiniton.arrAvailableLayers;
	InitParcelWithDef(ObjectiveParcel, ObjectiveParcel.ParcelDef, ObjectivePCP.Rotation, false);

	// remove the PCP actor
	ObjectivePCP.Destroy();

	// remove any linked PCP actors
	foreach ObjectivePCP.arrPCPsToBlockOnObjectiveSpawn(PCP)
	{
		PCP.Destroy();
	}
}

function ClearLayers()
{
	local XComLayerActor kLayerActor;

	foreach `XWORLDINFO.AllActors(class'XComLayerActor', kLayerActor)
	{
		kLayerActor.SetActive(false);
	}
}

function InitLayers()
{
	local XComLayerActor kLayerActor;
	local int iChanceToSpawn;
	local int LayerIndex;

	LayerIndex = 0;
	foreach `XWORLDINFO.AllActors(class'XComLayerActor', kLayerActor)
	{
		if (arrLayers.Find(string(kLayerActor.Layer)) >= 0)
		{
			if(kLayerActor.bAlwaysAppearIfLayerActive)
			{
				iChanceToSpawn = 101;
			}
			else
			{
				iChanceToSpawn = 50;
			}

			if(iChanceToSpawn > `SYNC_RAND_TYPED(100))
			{
				BattleDataState.MapData.ActiveLayers.AddItem(LayerIndex);
				kLayerActor.SetActive(true);
			}
		}

		++LayerIndex;
	}
}

function LoadLayers()
{
	local XComLayerActor kLayerActor;	
	local int LayerIndex;

	foreach `XWORLDINFO.AllActors(class'XComLayerActor', kLayerActor)
	{
		if( BattleDataState.MapData.ActiveLayers.Find(LayerIndex) >= 0 )
		{
			kLayerActor.SetActive(true);
		}

		++LayerIndex;
	}
}

function SilenceDestruction()
{
	local XComDestructibleActor kDestructible;
	local XComDestructibleActor_Action_RadialDamage kRadialDamage;
	local int idx;

	foreach `XWORLDINFO.AllActors(class'XComDestructibleActor', kDestructible)
	{
		for (idx = 0; idx < kDestructible.DamagedEvents.Length; idx++)
		{
			if (kDestructible.DamagedEvents[idx].Action.IsA(Name("XComDestructibleActor_Action_PlaySoundCue")))
			{
				if(kDestructible.DamagedEvents[idx].Action.bActivated)
				{
					kDestructible.DamagedEvents[idx].Action.Deactivate();
				}
			}
		}

		for (idx = 0; idx < kDestructible.DestroyedEvents.Length; idx++)
		{
			if (kDestructible.DestroyedEvents[idx].Action.IsA(Name("XComDestructibleActor_Action_PlaySoundCue")) ||
				kDestructible.DestroyedEvents[idx].Action.IsA(Name("XComDestructibleActor_Action_PlayEffectCue")))
			{
				if(kDestructible.DestroyedEvents[idx].Action.bActivated)
				{
					kDestructible.DestroyedEvents[idx].Action.Deactivate();
				}
			}
			if (kDestructible.DestroyedEvents[idx].Action.IsA(Name("XComDestructibleActor_Action_RadialDamage")))
			{
				if(kDestructible.DestroyedEvents[idx].Action.bActivated)
				{
					kRadialDamage = XComDestructibleActor_Action_RadialDamage(kDestructible.DestroyedEvents[idx].Action);
					kRadialDamage.EnvironmentalDamage = 0;
					kRadialDamage.UnitDamage = 0;
				}
			}
		}

		for (idx = 0; idx < kDestructible.AnnihilatedEvents.Length; idx++)
		{
			if (kDestructible.AnnihilatedEvents[idx].Action.IsA(Name("XComDestructibleActor_Action_PlaySoundCue")) ||
				kDestructible.AnnihilatedEvents[idx].Action.IsA(Name("XComDestructibleActor_Action_PlayEffectCue")))
			{
				if(kDestructible.AnnihilatedEvents[idx].Action.bActivated)
				{
					kDestructible.AnnihilatedEvents[idx].Action.Deactivate();
				}
			}
			if (kDestructible.AnnihilatedEvents[idx].Action.IsA(Name("XComDestructibleActor_Action_RadialDamage")))
			{
				if(kDestructible.AnnihilatedEvents[idx].Action.bActivated)
				{
					kRadialDamage = XComDestructibleActor_Action_RadialDamage(kDestructible.AnnihilatedEvents[idx].Action);
					kRadialDamage.EnvironmentalDamage = 0;
					kRadialDamage.UnitDamage = 0;
				}
			}
		}
	}
}

function ToggleChaos()
{
	local XComLayerActor kLayerActor;
	
	bToggleChaos = !bToggleChaos;
	foreach `XWORLDINFO.AllActors(class'XComLayerActor', kLayerActor)
	{
		if(kLayerActor.strLayer == "Chaos")
		{
			kLayerActor.SetActive(bToggleChaos);
		}
	}
}

function ScoreSoldierSpawn(XComGroupSpawn Spawn)
{
	local float SpawnDistanceSq;
	local MissionSchedule ActiveSchedule;
	local int MinSpawnDistance, IdealSpawnDistance;
	local XComGameState_BattleData LocalBattleStateData;
	local X2SitRepEffect_ModifyXComSpawn SitRepEffect;

	TacticalMissionManager.GetActiveMissionSchedule(ActiveSchedule);

	SpawnDistanceSq = VSizeSq(Spawn.Location - BattleDataState.MapData.ObjectiveLocation);

	MinSpawnDistance = ActiveSchedule.MinXComSpawnDistance;
	IdealSpawnDistance = ActiveSchedule.IdealXComSpawnDistance;

	LocalBattleStateData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (LocalBattleStateData != none)
	{
		foreach class'X2SitreptemplateManager'.static.IterateEffects(class'X2SitRepEffect_ModifyXComSpawn', SitRepEffect, LocalBattleStateData.ActiveSitReps)
		{
			SitRepEffect.ModifyLocations( IdealSpawnDistance, MinSpawnDistance );
		}
	}

	// no weight to spawn locations inside the minimum required distance
	if( SpawnDistanceSq < Square(MinSpawnDistance * class'XComWorldData'.const.WORLD_StepSize) )
	{
		Spawn.Score = 0;
	}
	else
	{
		// weight equal to inverse of abs of the diff between actual and ideal + some random slush
		Spawn.Score = (SpawnDistanceSq / (SpawnDistanceSq + Abs(SpawnDistanceSq - Square(IdealSpawnDistance * class'XComWorldData'.const.WORLD_StepSize)))) + (`SYNC_FRAND * SoldierSpawnSlush);
	}
}

function int SoldierSpawnSort(XComGroupSpawn Spawn1, XComGroupSpawn Spawn2)
{
	if(Spawn1.Score == Spawn2.Score)
	{
		return 0;
	}
	else
	{
		return Spawn1.Score > Spawn2.Score ? 1 : -1;
	}
}

// Finds all spawns that are valid for selection for this mission, and returns them sorted by suitability
function GetValidSpawns(out array<XComGroupSpawn> arrSpawns)
{
	local array<XComFalconVolume> arrFalconVolumes;
	local XComFalconVolume kFalconVolume;
	local XComGroupSpawn kSpawn;

	// look for falcon volumes (soldier spawn limiters). If found, only spawns within a falcon volume will
	// be considered
	foreach `XWORLDINFO.AllActors(class'XComFalconVolume', kFalconVolume)
	{
		arrFalconVolumes.AddItem(kFalconVolume);
	}

	// collect all spawns
	foreach `XWORLDINFO.AllActors(class'XComGroupSpawn', kSpawn)
	{
		if(arrFalconVolumes.Length == 0)
		{
			ScoreSoldierSpawn(kSpawn);
			if( kSpawn.Score > 0.0 )
			{
				arrSpawns.AddItem(kSpawn);
			}
		}
		else
		{
			// if falcon volumes exist, only accept spawns that lie within them
			foreach arrFalconVolumes(kFalconVolume)
			{
				if(kFalconVolume.ContainsPoint(kSpawn.Location))
				{
					ScoreSoldierSpawn(kSpawn);
					if( kSpawn.Score > 0.0 )
					{
						arrSpawns.AddItem(kSpawn);
					}
					break;
				}
			}
		}

		kSpawn.SetVisible(false);
	}

	// now randomize them
	arrSpawns.RandomizeOrder();

	// sort them into groups based on suitability. Since the random order is preserved for all spawns with the same
	// suitability, we can just grab the first one off the list.
	arrSpawns.Sort(SoldierSpawnSort);
}

function ChooseSoldierSpawn()
{
	local XComGroupSpawn kSpawn;
	local array<XComGroupSpawn> arrSpawns;
	local int SpawnIndex, SpawnSize;
	local float SpawnDistanceSq;
	local float FurthestSpawnDistanceSq;
	local TTile SpawnTile;
	local XComWorldData WorldData;

	// cache off the objective location for use in determining spawn ordering
	`TACTICALMISSIONMGR.GetLineOfPlayEndpoint(BattleDataState.MapData.ObjectiveLocation);
	
	GetValidSpawns(arrSpawns);

	// since these are sorted by suitability (but still random within a given suitability),
	// keep taking the spawns off the top until we find a spawn that has valid spawn locations
	SoldierSpawn = none;
	for(SpawnIndex = 0; SpawnIndex < arrSpawns.Length && SoldierSpawn == none; SpawnIndex++)
	{
		SoldierSpawn = arrSpawns[SpawnIndex];

		if(!SoldierSpawn.HasValidFloorLocations( BattleDataState.MapData.ActiveMission.SquadSpawnSizeOverride ))
		{
			// this spawn has been blocked by spawned geometry or is otherwise invalid, skip it
			SoldierSpawn = none;
		}
	}

	// safety catch in case no spawn could be found, take the furthest spawn from the objective
	if(SoldierSpawn == none)
	{
		WorldData = `XWORLD;
		SpawnSize = BattleDataState.MapData.ActiveMission.SquadSpawnSizeOverride == 0 ? 2 : BattleDataState.MapData.ActiveMission.SquadSpawnSizeOverride;

		ParcelGenerationAssert(false, "No Soldier Spawn found that obeys spawn rules, defaulting to furthest.");
		foreach `XWORLDINFO.AllActors(class'XComGroupSpawn', kSpawn)
		{
			// Skip spawn points not within the bounds of the world
			SpawnTile = WorldData.GetTileCoordinatesFromPosition( kSpawn.Location );
			if (WorldData.IsTileOutOfRange( SpawnTile ))
				continue;

			// skip spawn points too close to the max edge of the world
			SpawnTile.X += SpawnSize;
			SpawnTile.Y += SpawnSize;
			if (WorldData.IsTileOutOfRange( SpawnTile ))
				continue;

			// skip spawn points too close to the min edge of the world
			SpawnTile.X -= SpawnSize * 2;
			SpawnTile.Y -= SpawnSize * 2;
			if (WorldData.IsTileOutOfRange( SpawnTile ))
				continue;

			SpawnDistanceSq = VSizeSq2D(BattleDataState.MapData.ObjectiveLocation - kSpawn.Location);
			if(SpawnDistanceSq > FurthestSpawnDistanceSq)
			{
				FurthestSpawnDistanceSq = SpawnDistanceSq;
				SoldierSpawn = kSpawn;
			}
		}
	}

	BattleDataState.MapData.SoldierSpawnLocation = SoldierSpawn.Location;

	return;	
}

function RebuildWorldData()
{
	//local float fXY, fZ;
	//local Vector v;

	//fXY = 999999;
	//fZ = 999999;

	//Only rebuild the world data if the level volume has a non-zero volume
	if( `XWORLD.NumX > 0 )
	{
		`XWORLD.bEnableRebuildTileData = true; //World data should not be processed prior to this point during load
		`XWORLD.BuildWorldData( none );
		`XWORLD.RebuildDestructionData();	
	}
	else
	{
		class'X2TacticalGameRuleset'.static.ReleaseScriptLog( "Loading Map Phase 3: XComWorldData.NumX already set!" );
	}
}

function OnParcelLoadCompleted(Name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	LinkParcelPatrolPathsToPlotPaths();
}

// Adding light clipping and environment maps to the TQL requires world data to be rebuilt when a parcel is changed
// This function needs to be set when a parcel is selected
function OnParcelLoadCompletedAfterParcelSelection(Name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	LinkParcelPatrolPathsToPlotPaths();

	RebuildWorldData();

	// if this is the new objective parcel, then respawn objectives
	if(ObjectiveParcel != None && ObjectiveParcel.ParcelDef.MapName == string(LevelPackageName))
	{
		TacticalMissionManager.SpawnMissionObjectives();
	}

	`XWORLDINFO.MyLightClippingManager.BuildFromScript();
	`XWORLDINFO.MyLocalEnvMapManager.ResetCaptures();
}

// Alternate initialization to init with a specific parcel definition
function InitParcelWithDef(XComParcel kParcel, ParcelDefinition ParcelDef, Rotator rRot, bool bFromParcelSelection)
{
	local StoredMapData_Parcel		ParcelData;
	local XComGameState_BattleData	LocalBattleStateData;

	// mark this parcel card as used so it doesn't come up again in the near future. Don't mark objective PCPs though,
	// as they aren't in the deck and will redscreen
	if(!TacticalMissionManager.ActiveMission.ObjectiveSpawnsOnPCP || kParcel != ObjectiveParcel)
	{
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('Parcels', ParcelDef.MapName);
	}

	kParcel.ParcelDef = GetParcelDefinitionWithTransformedEntrances(ParcelDef, rRot);

	kParcel.FixupEntrances(PlotType.bUseEmptyClosedEntrances, arrEntranceDefinitions);

	// Choose OnParcelLoadCompleted function based on whether this parcel load is coming from the TQL parcel selection or not
	`MAPS.AddStreamingMap(kParcel.ParcelDef.MapName, kParcel.Location, rRot, bBlockingLoadParcels, true, true, bFromParcelSelection ? OnParcelLoadCompletedAfterParcelSelection : OnParcelLoadCompleted);

	// save main parcel data
	ParcelData.Location = kParcel.Location;
	ParcelData.Rotation = rRot;
	ParcelData.MapName = kParcel.ParcelDef.MapName;
	ParcelData.ParcelArrayIndex = arrParcels.Find(kParcel);
	ParcelData.BrandIndex = class'XComBrandManager'.static.GetRandomBrandForMap(ParcelData.MapName);
	kParcel.SaveEntrances(ParcelData);

	// add to the save data store
	LocalBattleStateData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	LocalBattleStateData.MapData.ParcelData.AddItem(ParcelData);
}

function ComputePlotType()
{
	local int idx;
	local string strMapName;
	
	arrEntranceDefinitions.Remove(0, arrEntranceDefinitions.Length);

	//First, attempt to get the plot map name from the battle data. If this fails, fall beck to using the world info
	strMapName = BattleDataState.MapData.PlotMapName;

	//RAM - deprecated - backwards compatibility support
	if( strMapName == "" )
	{
		strMapName = class'Engine'.static.GetCurrentWorldInfo().GetMapName();
	}
	for (idx=0; idx < arrPlots.Length; idx++)
	{
		if (Locs(arrPlots[idx].MapName) == Locs(strMapName))
		{
			PlotType = GetPlotTypeDefinition(arrPlots[idx].strType);
			break;
		}
	}

	// Narrow down entrances to ones with the correct plot type
	for (idx = 0; idx < arrAllEntranceDefinitions.Length; idx++)
	{
		if(arrAllEntranceDefinitions[idx].strPlotType == PlotType.strType || Len(arrAllEntranceDefinitions[idx].strPlotType) == 0)
		{
			arrEntranceDefinitions.AddItem(arrAllEntranceDefinitions[idx]);
		}
	}
}

function AssignLayerDistribution()
{
	local XComParcel kParcel;
	local string strLayerName;
	local int iSpawnChance;

	// 50% across the board until we figure out how this is controlled
	iSpawnChance = 50;

	foreach `XWORLDINFO.AllActors(class'XComParcel', kParcel)
	{
		foreach arrLayers(strLayerName)
		{
			if(`SYNC_RAND_TYPED(100) > iSpawnChance)
			{
				kParcel.arrRequiredLayers.AddItem(strLayerName);
			}
		}
	}
}

native function PlotTypeDefinition GetPlotTypeDefinition(string strType);

function BiomeDefinition GetBiomeDefinition(string strType)
{
	local int Index;	

	//If the biome has been forced, make it so	
	if(ForceBiome != "")
	{
		strType = ForceBiome;
	}

	Index = arrBiomes.Find('strType', strType);

	return (Index != INDEX_NONE) ? arrBiomes[Index] : arrBiomes[0];
}

/*function string ChooseZone(XComParcel kParcel)
{
	local int iIndex;

	if (kParcel.arrForceZoneTypes.Length > 0)
	{
		iIndex = `SYNC_RAND_TYPED(kParcel.arrForceZoneTypes.Length);
		return kParcel.arrForceZoneTypes[iIndex];
	}
	else
	{
		return "";
	}
}*/

function bool MeetsLayerRequirements(XComParcel kParcel, ParcelDefinition kParcelDef)
{
	/* dburchanowkski Disabled until we have enough parcels with layers to actually make this work
	local string strLayerName;

	// verify that the given parcel definition has all layer types that this parcel type requires
	foreach kParcel.arrRequiredLayers(strLayerName)
	{
		if(kParcelDef.arrAvailableLayers.Find(strLayerName) < 0)
		{
			return false;
		}
	}
	*/

	return true;
}
function bool MeetsZoningRequirements(XComParcel kParcel, array<string> arrZoneTypes)
{
	local int idx;
	local int i;

	if (kParcel.arrForceZoneTypes.Length == 0 || arrZoneTypes.Length == 0)
	{
		return true;
	}

	for (idx = 0; idx < arrZoneTypes.Length; idx++)
	{
		for (i = 0; i < kParcel.arrForceZoneTypes.Length; i++)
		{
			if(kParcel.arrForceZoneTypes[i] == arrZoneTypes[idx])
			{
				return true;
			}
		}
	}

	return false;
}

// Returns true if the parcel actor originally had one or more facing set, false otherwise
function FillParcelFacingArray(XComParcel kParcel, out array<EParcelFacingType> arrParcelFacings)
{
	if(kParcel.bFacingNorth)
	{
		arrParcelFacings.AddItem(EParcelFacingType_N);
	}
	if(kParcel.bFacingEast)
	{
		arrParcelFacings.AddItem(EParcelFacingType_E);
	}
	if(kParcel.bFacingSouth)
	{
		arrParcelFacings.AddItem(EParcelFacingType_S);
	}
	if(kParcel.bFacingWest)
	{
		arrParcelFacings.AddItem(EParcelFacingType_W);
	}
	if(!kParcel.bFacingNorth && !kParcel.bFacingEast && !kParcel.bFacingSouth && ! kParcel.bFacingWest)
	{
		arrParcelFacings.AddItem(EParcelFacingType_N);
		arrParcelFacings.AddItem(EParcelFacingType_E);
		arrParcelFacings.AddItem(EParcelFacingType_S);
		arrParcelFacings.AddItem(EParcelFacingType_W);
	}
}

function bool FoundMatchingFacing(ParcelDefinition ParcelDef, XComParcel kParcel, out Rotator rRot)
{
	local ParcelDefinition TransformedParcelDef;

	// Validate entrance counts
	if (ParcelDef.eFacing != EParcelFacingType_None)
	{
		if(kParcel.eFacing == EParcelFacingType_None)
		{
			// parceldefs with a facing require a parcel with a facing!
			return false;
		}

		// transform to match facing
		rRot = ComputeRotationToMatchFacing(ParcelDef.eFacing, kParcel.eFacing);
		TransformedParcelDef = GetParcelDefinitionWithTransformedEntrances(ParcelDef, rRot);

		return MeetsForceEntrancesRequirements(TransformedParcelDef, kParcel) && MeetsParcelAlignment(ParcelDef.eFacing, kParcel, rRot);
	}
	else
	{
		// no facing requirement so try all options
		ParcelDef.eFacing = EParcelFacingType_N;
		rRot = ComputeRotationToMatchFacing(ParcelDef.eFacing, kParcel.eFacing);
		TransformedParcelDef = GetParcelDefinitionWithTransformedEntrances(ParcelDef, rRot);
		if(MeetsForceEntrancesRequirements(TransformedParcelDef, kParcel) && MeetsParcelAlignment(ParcelDef.eFacing, kParcel, rRot))
		{
			return true;
		}

		ParcelDef.eFacing = EParcelFacingType_E;
		rRot = ComputeRotationToMatchFacing(ParcelDef.eFacing, kParcel.eFacing);
		TransformedParcelDef = GetParcelDefinitionWithTransformedEntrances(ParcelDef, rRot);
		if(MeetsForceEntrancesRequirements(TransformedParcelDef, kParcel) && MeetsParcelAlignment(ParcelDef.eFacing, kParcel, rRot))
		{
			return true;
		}

		ParcelDef.eFacing = EParcelFacingType_S;
		rRot = ComputeRotationToMatchFacing(ParcelDef.eFacing, kParcel.eFacing);
		TransformedParcelDef = GetParcelDefinitionWithTransformedEntrances(ParcelDef, rRot);
		if(MeetsForceEntrancesRequirements(TransformedParcelDef, kParcel) && MeetsParcelAlignment(ParcelDef.eFacing, kParcel, rRot))
		{
			return true;
		}

		ParcelDef.eFacing = EParcelFacingType_W;
		rRot = ComputeRotationToMatchFacing(ParcelDef.eFacing, kParcel.eFacing);
		TransformedParcelDef = GetParcelDefinitionWithTransformedEntrances(ParcelDef, rRot);
		if(MeetsForceEntrancesRequirements(TransformedParcelDef, kParcel) && MeetsParcelAlignment(ParcelDef.eFacing, kParcel, rRot))
		{
			return true;
		}
					
		return false;
	}	
}

function bool MeetsFacingAndEntranceRequirements(ParcelDefinition ParcelDef, XComParcel Parcel, out Rotator Rot)
{
	local array<EParcelFacingType> arrParcelFacings;
	local int Index;

	FillParcelFacingArray(Parcel, arrParcelFacings);
	
	while (arrParcelFacings.Length > 0)
	{
		Index = `SYNC_RAND_TYPED(arrParcelFacings.Length);
		Parcel.eFacing = arrParcelFacings[Index];
		if(FoundMatchingFacing(ParcelDef, Parcel, Rot))
		{
			return true;
		}
			
		arrParcelFacings.RemoveItem(arrParcelFacings[Index]);
	}

	return false;
}

function bool MeetsParcelAlignment(EParcelFacingType eSourceFacing, XComParcel kParcel, out Rotator rRot)
{
	local int iMultiplesOf90;

	if(kParcel.SizeX == kParcel.SizeY)
	{
		// square parcels always align regards of which way they are facing.
		return true;
	}

	rRot = ComputeRotationToMatchFacing(eSourceFacing, kParcel.eFacing);
	iMultiplesOf90 = abs(rRot.Yaw/16384);

	if (kParcel.Rotation.Yaw == 0)
	{
		// Only 0 and 180 rotations acceptable
		return (iMultiplesOf90 == 0 || iMultiplesOf90 == 2);
	}
	else
	{
		// Only 90 and 270 rotations acceptable
		return (iMultiplesOf90 == 1 || iMultiplesOf90 == 3);
	}
}

function bool MeetsForceEntrancesRequirements(ParcelDefinition ParcelDef, XComParcel kParcel)
{
	local int EntranceCount;

	if(ParcelDef.bHasEntranceN1 && kParcel.bHasEntranceN1) EntranceCount++;
	if(ParcelDef.bHasEntranceN2 && kParcel.bHasEntranceN2) EntranceCount++;
	if(ParcelDef.bHasEntranceS1 && kParcel.bHasEntranceS1) EntranceCount++;
	if(ParcelDef.bHasEntranceS2 && kParcel.bHasEntranceS2) EntranceCount++;

	if(ParcelDef.bHasEntranceE1 && kParcel.bHasEntranceE1) EntranceCount++;
	if(ParcelDef.bHasEntranceE2 && kParcel.bHasEntranceE2) EntranceCount++;
	if(ParcelDef.bHasEntranceW1 && kParcel.bHasEntranceW1) EntranceCount++;
	if(ParcelDef.bHasEntranceW2 && kParcel.bHasEntranceW2) EntranceCount++;

	return EntranceCount >= ParcelDef.bForceEntranceCount;
}

function Rotator ComputeRotationToMatchFacing(EParcelFacingType eSourceFacing, EParcelFacingType eTargetFacing)
{
	local int iFacingDiff;
	local Rotator rRot;

	iFacingDiff = eSourceFacing - eTargetFacing;

	rRot.Yaw = iFacingDiff*-16384;

	return rRot;

}

function ParcelDefinition GetParcelDefinitionWithTransformedEntrances(ParcelDefinition ParcelDef, Rotator r)
{
	local ParcelDefinition TransformedParcelDef;

	TransformedParcelDef = ParcelDef;

	if (r.Yaw == 16384 || r.Yaw == -49142)
	{
		TransformedParcelDef.bHasEntranceE1 = ParcelDef.bHasEntranceN1;
		TransformedParcelDef.bHasEntranceE2 = ParcelDef.bHasEntranceN2;
		TransformedParcelDef.bHasEntranceS1 = ParcelDef.bHasEntranceE1;
		TransformedParcelDef.bHasEntranceS2 = ParcelDef.bHasEntranceE2;
		TransformedParcelDef.bHasEntranceW1 = ParcelDef.bHasEntranceS1;
		TransformedParcelDef.bHasEntranceW2 = ParcelDef.bHasEntranceS2;
		TransformedParcelDef.bHasEntranceN1 = ParcelDef.bHasEntranceW1;
		TransformedParcelDef.bHasEntranceN2 = ParcelDef.bHasEntranceW2;
	}
	else if(r.Yaw == 32768 || r.Yaw == -32768)
	{
		TransformedParcelDef.bHasEntranceS1 = ParcelDef.bHasEntranceN1;
		TransformedParcelDef.bHasEntranceS2 = ParcelDef.bHasEntranceN2;
		TransformedParcelDef.bHasEntranceW1 = ParcelDef.bHasEntranceE1;
		TransformedParcelDef.bHasEntranceW2 = ParcelDef.bHasEntranceE2;
		TransformedParcelDef.bHasEntranceN1 = ParcelDef.bHasEntranceS1;
		TransformedParcelDef.bHasEntranceN2 = ParcelDef.bHasEntranceS2;
		TransformedParcelDef.bHasEntranceE1 = ParcelDef.bHasEntranceW1;
		TransformedParcelDef.bHasEntranceE2 = ParcelDef.bHasEntranceW2;
	}
	else if(r.Yaw == 49152 || r.Yaw == -16384)
	{
		TransformedParcelDef.bHasEntranceW1 = ParcelDef.bHasEntranceN1;
		TransformedParcelDef.bHasEntranceW2 = ParcelDef.bHasEntranceN2;
		TransformedParcelDef.bHasEntranceN1 = ParcelDef.bHasEntranceE1;
		TransformedParcelDef.bHasEntranceN2 = ParcelDef.bHasEntranceE2;
		TransformedParcelDef.bHasEntranceE1 = ParcelDef.bHasEntranceS1;
		TransformedParcelDef.bHasEntranceE2 = ParcelDef.bHasEntranceS2;
		TransformedParcelDef.bHasEntranceS1 = ParcelDef.bHasEntranceW1;
		TransformedParcelDef.bHasEntranceS2 = ParcelDef.bHasEntranceW2;
	}

	return TransformedParcelDef;
}

native function XComParcel GetContainingParcel( const out vector vLoc );

//====================================================
// ParcelMgr Utilities

/// <summary>
/// Searches the parcel list for a definition with a MapName that matches the argument, and assigns it into the
/// out parameter. Returns TRUE if a match was found, FALSE if not.
/// </summary>
/// <param name="MapName">The map name for the parcel to match</param>
function bool GetParcelDefinitionForMapname(string MapName, out ParcelDefinition OutParcelDefinition)
{
	local int Index;

	for( Index = 0; Index < arrAllParcelDefinitions.Length; ++Index )
	{
		if( arrAllParcelDefinitions[Index].MapName == MapName )
		{
			OutParcelDefinition = arrAllParcelDefinitions[Index];
			return true;
		}
	}

	return false;
}

/// <summary>
/// Removes any plot definitions that are not valid for use with the given mission data
/// </summary>
function RemovePlotDefinitionsThatAreInvalidForMission(out array<PlotDefinition> PlotDefinitions, MissionDefinition Mission)
{
	local array<PlotDefinition> ValidMissionPlots;
	local array<string> ValidPlotMaps;
	local PlotDefinition PlotDef;
	local int Index;

	GetValidPlotsForMission(ValidMissionPlots, Mission);
	foreach ValidMissionPlots(PlotDef)
	{
		ValidPlotMaps.AddItem(PlotDef.MapName);
	}

	for(Index = PlotDefinitions.Length - 1; Index >= 0; Index--)
	{
		PlotDef = PlotDefinitions[Index];
		if(ValidPlotMaps.Find(PlotDef.MapName) == INDEX_NONE)
		{
			PlotDefinitions.Remove(Index, 1);
		}
	}
}

/// <summary>
/// Searches the plot list for a definition with a strType that matches the argument, and fills the out parameter
/// array with the results.
/// </summary>
/// <param name="PlotType">The plot type string to match when searching for plots</param>
function GetPlotDefinitionsForPlotType(string InPlotType, string strBiome, out array<PlotDefinition> OutPlotDefinitions)
{
	local int Index;

	for( Index = 0; Index < arrPlots.Length; ++Index )
	{
		if( arrPlots[Index].strType == InPlotType &&
			(strBiome == "" || arrPlots[Index].ValidBiomes.Find(strBiome) != INDEX_NONE) )
		{
			OutPlotDefinitions.AddItem(arrPlots[Index]);
		}
	}
}

//====================================================

//This event is called by the engine when it needs to determine what maps to load for seamless travel.
event NativeGenerateMap()
{
	local XComGameStateHistory History;	
	local Actor TimerActor;

	History = `XCOMHISTORY;
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));	
	`MAPS.AddStreamingMap(BattleDataState.MapData.PlotMapName);

	TimerActor = class'WorldInfo'.static.GetWorldInfo().Spawn(class'DynamicPointInSpace');	
	TimerActor.Tag = 'Timer';
	TimerActor.SetTimer(0.1f, false, nameof(NativeGenerateMapPhase1), self);	
}

native final function bool IsStreamingComplete();

function NativeGenerateMapPhase1()
{
	local DynamicPointInSpace TimerActor;

	if(`MAPS.IsStreamingComplete() && IsStreamingComplete())
	{		
		// notify the deck manager that we have used this plot
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('Plots', BattleDataState.MapData.PlotMapName);
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('PlotTypes', GetPlotDefinition(BattleDataState.MapData.PlotMapName).strType);

		bGeneratingMap = false;
		GenerateMap(BattleDataState.iLevelSeed);
	}
	else
	{
		foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'DynamicPointInSpace', TimerActor)
		{
			if(TimerActor.Tag == 'Timer')
			{
				break;
			}
		}
				
		TimerActor.SetTimer(0.1f, false, nameof(NativeGenerateMapPhase1), self);
	}
}


function GenerateMap(int MapSeed)
{
	if( !bGeneratingMap )
	{
		iLevelSeed = MapSeed;
		class'Engine'.static.GetEngine().SetRandomSeeds(iLevelSeed);

		EnvLightingManager = `ENVLIGHTINGMGR;		
		TacticalMissionManager = `TACTICALMISSIONMGR;
		
		GenerateMapUpdatePhase1();

		if(!class'WorldInfo'.static.GetWorldInfo().IsInSeamlessTravel())
		{
			`XWORLDINFO.MyLightClippingManager.BuildFromScript();			
			`XWORLDINFO.MyLocalEnvMapManager.ResetCaptures();
		}

		bFinishedGeneratingMap = true;
	}
	else
	{
		`log("GenerateMap FAILED! Already generating a map!");
	}	
}

//Phase 1 picks the layout for the level and initiates streaming
function GenerateMapUpdatePhase1()
{
	bGeneratingMap = true;

	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleDataState != None);

	GeneratingMapPhase = 1;
	GeneratingMapPhaseText = "Generating Map Phase 1: InitParcels";

	TacticalMissionManager.bBlockingLoadParcels = bBlockingLoadParcels;
	EnvLightingManager.bBlockingLoadParcels = bBlockingLoadParcels;

	TacticalMissionManager.InitMission(BattleDataState);

	// log the map that we are about to generate, in case it goes south
	`log("Generating Map: ");
	`log(" Primary Mission Type: " $ TacticalMissionManager.ActiveMission.MissionName);
	`log(" Plot Map: " $ BattleDataState.MapData.PlotMapName);

	GenerateParcelLayout();		
	
	//If we are in the midst of seamless traveling, then we only perform the first phase. Signal that this is done
	if(class'WorldInfo'.static.GetWorldInfo().IsInSeamlessTravel())
	{		
		class'Engine'.static.GetEngine().SeamlessTravelSignalStageComplete();		
	}	
	else
	{
		GenerateMapUpdatePhase2();
	}
}

function PostLoadSetObjectiveParcel()
{
	local StoredMapData_Parcel StoredParcelData;

	if(BattleDataState.MapData.ObjectiveParcelIndex < 0)
	{
		//If the ObjectiveParcelIndex is invalid, it means that this is a PCP objective. These use a fake spawned objective parcel that was
		//created in the seamless travel map and then destroyed. Re-create it here
		StoredParcelData = BattleDataState.MapData.ParcelData[0]; //The first element is the objective parcel
		ObjectiveParcel = `XWORLDINFO.Spawn(class'XComParcel', `XWORLDINFO,, StoredParcelData.Location, StoredParcelData.Rotation);
		arrParcels.AddItem(ObjectiveParcel);
	}
	else
	{
		ObjectiveParcel = arrParcels[BattleDataState.MapData.ObjectiveParcelIndex];
	}
}

//Phase 2 waits for all parcels and streaming maps to load, then picks layers and kicks off tile rebuilding
function GenerateMapUpdatePhase2()
{	
	local BiomeDefinition BiomeDef;	
	local StoredMapData_Parcel StoredParcelData;
	local XComParcel Parcel;
		
	if (`MAPS.IsStreamingComplete() && IsStreamingComplete())
	{
		//When seamless traveling, these cached values need to be restored ( similar to what is done in the loading stages below )
		if(`XCOMGAME.m_bSeamlessTraveled)
		{
			CacheParcels();
						
			PostLoadSetObjectiveParcel();

			//Restore parcel entrances and map names
			foreach BattleDataState.MapData.ParcelData(StoredParcelData)
			{
				Parcel = arrParcels[StoredParcelData.ParcelArrayIndex];
				if(Parcel != none)
				{
					Parcel.ParcelDef.MapName = StoredParcelData.MapName;
				}

				Parcel.RestoreEntrances(StoredParcelData);
			}
		}

		EnvLightingManager.Reset(BattleDataState);		
		
		ClearLayers();
		BiomeDef = GetBiomeDefinition(BattleDataState.MapData.Biome);
		class'XComPlotSwapData'.static.AdjustParcelsForBiomeType(BiomeDef.strType, PlotType.strType, BattleDataState.MapData.ActiveMission.sType);
		class'XComBrandManager'.static.SwapBrandsForParcels(BattleDataState.MapData);
		InitLayers();

		LinkParcelPatrolPathsToPlotPaths();

		GeneratingMapPhase = 2;
		GeneratingMapPhaseText = "Generating Map Phase 2: Building World Data";

		GenerateMapUpdatePhase3();
	}
	else
	{
		//Register to repeat this method until streaming is complete
		`BATTLE.SetTimer(0.1f, false, nameof(GenerateMapUpdatePhase2), self);
	}
}

//Phase 3 is waiting for tile data to load
function GenerateMapUpdatePhase3()
{	
	if (`MAPS.IsStreamingComplete() && IsStreamingComplete()) //Wait for the environment lighting map to load
	{
		//If using seamless travel, there will be a black screen displayed while this blocking operation is performed.
		if(class'XComMapManager'.default.bUseSeamlessTravelToTactical)
		{
			RebuildWorldData(); //Synchronous world data building
		}
		else
		{
			`XWORLD.StartAsyncBuildWorldData(); //Builds world data on a worker thread
		}
		GenerateMapUpdatePhase4();
	}
	else
	{
		`BATTLE.SetTimer(0.1f, false, nameof(GenerateMapUpdatePhase3), self);
	}
}

//Phase 4 is waiting for tile data to load
function GenerateMapUpdatePhase4()
{
	//Wait for world data to finish building on the worker thread, or if we are seamless travel the world data has been build synchronously so proceed
	if(`XWORLD.AsyncBuildWorldDataComplete() || class'XComMapManager'.default.bUseSeamlessTravelToTactical)
	{
		// HACK: Skip this if in MP.
		if(class'Engine'.static.GetEngine().IsSinglePlayerGame())
		{
			// Spawn the objectives on the map.
			TacticalMissionManager.SpawnMissionObjectives();
			TacticalMissionManager.CheckForLineOfPlayAnchorOverride();

			// Issue #405
			`XEVENTMGR.TriggerEvent('PostMissionObjectivesSpawned');
		}

		// this needs to happen after the tile rebuild so we can verify there are valid locations at the
		// selected spawn
		ChooseSoldierSpawn();
		InitPlacedEvacZone();

		// check if we want to spawn a vip with the XCom squad
		TacticalMissionManager.SpawnVIPWithXComSquad();

		GeneratingMapPhase = 0;
		GeneratingMapPhaseText = "";
		bGeneratingMap = false;

		BattleDataState = none;
	}
	else
	{
		`BATTLE.SetTimer(0.1f, false, nameof(GenerateMapUpdatePhase4), self);
	}
}

function LoadMap(XComGameState_BattleData BattleData)
{
	if( !bGeneratingMap )
	{
		BattleDataState = BattleData;

		EnvLightingManager = `ENVLIGHTINGMGR;
		TacticalMissionManager = `TACTICALMISSIONMGR;

		bBlockingLoadParcels = true;
		
		LoadMapUpdatePhase1();		
	}
	else
	{
		`log("GenerateMap FAILED! Already generating a map!");
		class'X2TacticalGameRuleset'.static.ReleaseScriptLog( "GenerateMap FAILED! Already generating a map!" );
	}	
}

//Phase 1 picks the layout for the level and initiates streaming
function LoadMapUpdatePhase1()
{
	local LevelStreaming MissionLevel;
	local XComParcel Parcel;
	local StoredMapData_Parcel StoredParcelData;
	local string MissionMapName;

	bGeneratingMap = true;

	GeneratingMapPhase = 1;
	GeneratingMapPhaseText = "Loading Map Phase 1: Stream Parcels";

	class'X2TacticalGameRuleset'.static.ReleaseScriptLog( GeneratingMapPhaseText );

	TacticalMissionManager.bBlockingLoadParcels = bBlockingLoadParcels;
	EnvLightingManager.bBlockingLoadParcels = bBlockingLoadParcels;

	TacticalMissionManager.GetMissionDefinitionForType(BattleDataState.MapData.ActiveMission.sType, TacticalMissionManager.ActiveMission);
	TacticalMissionManager.SetActiveMissionScheduleIndex(BattleDataState.MapData.ActiveMissionSchedule);
	TacticalMissionManager.MissionQuestItemTemplate = BattleDataState.MapData.ActiveQuestItemTemplate;

	foreach BattleDataState.MapData.ActiveMission.MapNames(MissionMapName)
	{
		MissionLevel = `MAPS.AddStreamingMap(MissionMapName, vect(0,0,0), rot(0,0,0), bBlockingLoadParcels, true);
		MissionLevel.bForceNoDupe = true;
	}

	CacheParcels();

	foreach BattleDataState.MapData.ParcelData(StoredParcelData)
	{
		`MAPS.AddStreamingMap(StoredParcelData.MapName, 
													 StoredParcelData.Location, 
													 StoredParcelData.Rotation, 
													 bBlockingLoadParcels, true);

		Parcel = arrParcels[StoredParcelData.ParcelArrayIndex];
		if( Parcel != none )
		{
			Parcel.ParcelDef.MapName = StoredParcelData.MapName;
		}

		Parcel.RestoreEntrances(StoredParcelData);
	}

	foreach BattleDataState.MapData.PlotCoverParcelData(StoredParcelData)
	{
		`MAPS.AddStreamingMap(StoredParcelData.MapName, 
													 StoredParcelData.Location, 
													 StoredParcelData.Rotation, 
													 bBlockingLoadParcels, true);
	}

	class'XComPlotCoverParcelManager'.static.RelinkPCPDebugData(BattleDataState);
	
	LoadMapUpdatePhase2();
}

//Phase 2 waits for all parcels and streaming maps to load, then picks layers and kicks off tile rebuilding
function LoadMapUpdatePhase2()
{	
	local BiomeDefinition BiomeDef;
	local PlotDefinition PlotDef;
	local XComGroupSpawn Spawn;
	local string LightingMapName;

	if (`MAPS.IsStreamingComplete() && IsStreamingComplete())
	{
		if(`PARCELMGR.ForceLighting != "")
		{
			LightingMapName = `PARCELMGR.ForceLighting;
		}
		else
		{
			LightingMapName = BattleDataState.MapData.EnvironmentLightingMapName;
		}

		`MAPS.AddStreamingMap(LightingMapName, , , bBlockingLoadParcels, , , `ENVLIGHTINGMGR.OnEnvMapVisible);
		EnvLightingManager.currentMapName = LightingMapName;
		EnvLightingManager.currentMapIdx = EnvLightingManager.GetMapIndexByName(LightingMapName);
		EnvLightingManager.OnFinishedLoading();

		`MAPS.AddStreamingMap("Wind",,,bBlockingLoadParcels);

		ClearLayers();
		BiomeDef = GetBiomeDefinition(BattleDataState.MapData.Biome);
		PlotDef = GetPlotDefinition(BattleDataState.MapData.PlotMapName);
		PlotType = GetPlotTypeDefinition(PlotDef.strType);
		class'XComPlotSwapData'.static.AdjustParcelsForBiomeType(BiomeDef.strType, PlotType.strType, BattleDataState.MapData.ActiveMission.sType);
		class'XComBrandManager'.static.SwapBrandsForParcels(BattleDataState.MapData);
		LoadLayers();

		LinkParcelPatrolPathsToPlotPaths();

		CacheParcels();

		PostLoadSetObjectiveParcel();		

		foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComGroupSpawn', Spawn)
		{
			// note: the spawn and exit can be the same group actor
			if(SoldierSpawn == none && VSizeSq(Spawn.Location - BattleDataState.MapData.SoldierSpawnLocation) < 1) // compare distance in case of slight precision loss
			{
				SoldierSpawn = Spawn;
			}
			
			if(LevelExit == none && VSizeSq(Spawn.Location - BattleDataState.MapData.SoldierExitLocation) < 1)
			{
				LevelExit = Spawn;
			}

			Spawn.SetHidden(Spawn != LevelExit);
		}

		GeneratingMapPhase = 2;
		GeneratingMapPhaseText = "Loading Map Phase 2: Layer Selection";

		class'X2TacticalGameRuleset'.static.ReleaseScriptLog( GeneratingMapPhaseText );

		LoadMapUpdatePhase3();
	}
	else
	{
		//Register to repeat this method until streaming is complete
		`BATTLE.SetTimer(0.1f, false, nameof(LoadMapUpdatePhase2), self);
	}
}

//Phase 3 is waiting for tile data to load
function LoadMapUpdatePhase3()
{
	if (`MAPS.IsStreamingComplete() && IsStreamingComplete())
	{
		class'X2TacticalGameRuleset'.static.ReleaseScriptLog( "Loading Map Phase 3: Building World Data" );

		RebuildWorldData();

		GeneratingMapPhase = 0;
		GeneratingMapPhaseText = "";
		bGeneratingMap = false;

		BattleDataState = none;
	}
	else
	{
		//Register to repeat this method until streaming is complete
		`BATTLE.SetTimer(0.1f, false, nameof(LoadMapUpdatePhase3), self);
	}
}

function bool IsGeneratingMap()
{
	return bGeneratingMap;
}

function string GetGenerateMapPhaseText()
{
	if( IsGeneratingMap() )
	{
		return GeneratingMapPhaseText;
	}

	return "";
}

function int GetGenerateMapPhase()
{
	return GeneratingMapPhase;
}

function bool IsFinishedGeneratingMap()
{
	return bFinishedGeneratingMap;
}

function ResetIsFinishedGeneratingMap()
{
	bFinishedGeneratingMap = false;
}

function DebugSoldierSpawns()
{
	local XGBattle Battle;
	local array<XComFalconVolume> FalconVolumes;
	local XComFalconVolume FalconVolume;
	local XComGroupSpawn GroupSpawn;
	local string GroupSpawnDebugText;
	local int MinimumSpawnDistance;
	local int IdealSpawnDistance;
	local Color TextColor;
	local float SoldierSpawnScore;
	local float SpawnScore;
	local bool IsOutsideFalconVolumes;
	local MissionSchedule ActiveSchedule;
	local XComGameState_BattleData LocalBattleStateData;
	local int SchMinSpawnDistance, SchIdealSpawnDistance;
	local X2SitRepEffect_ModifyXComSpawn SitRepEffect;

	Battle = `BATTLE;

	if(SoldierSpawn != none)
	{
		SoldierSpawnScore = SoldierSpawn.Score;
	}

	// collect the falcon volumes on the map and visualize them
	foreach Battle.AllActors(class'XComFalconVolume', FalconVolume)
	{
		FalconVolumes.AddItem(FalconVolume);
		Battle.DrawDebugBox(FalconVolume.BrushComponent.Bounds.Origin, FalconVolume.BrushComponent.Bounds.BoxExtent, 255, 255, 255, true);
	}

	// add debug strings above each of the group spawns with info about their scoring
	foreach Battle.AllActors(class'XComGroupSpawn', GroupSpawn)
	{
		if(GroupSpawn == SoldierSpawn)
		{
			GroupSpawnDebugText = "SelectedSpawn";
		}
		else
		{
			GroupSpawnDebugText = "Spawn";
		}

		if(!GroupSpawn.HasValidFloorLocations())
		{
			GroupSpawnDebugText $= ", Not enough valid floor locations";
		}

		// check for being outside of falcon volume spawn limiters
		IsOutsideFalconVolumes = true;
		foreach FalconVolumes(FalconVolume)
		{
			if(FalconVolume.ContainsPoint(GroupSpawn.Location))
			{
				IsOutsideFalconVolumes = false;
				break;
			}
		}

		if(IsOutsideFalconVolumes)
		{
			GroupSpawnDebugText $= ", Outside Falcon Volumes";
		}

		SpawnScore = GroupSpawn.Score;
		GroupSpawnDebugText $= ", Score: " $ string(SpawnScore);

		// determine the text color
		if(SoldierSpawn == GroupSpawn) // this is the selected soldier spawn
		{
			TextColor.R = 255;
			TextColor.G = 255;
			TextColor.B = 255;
			TextColor.A = 255;
		}
		else if(IsOutsideFalconVolumes || SoldierSpawnScore != SpawnScore)
		{
			TextColor.R = 255;
			TextColor.G = 128;
			TextColor.B = 128;
			TextColor.A = 255;
		}
		else // this could have been a soldier spawn, but was not selected
		{
			TextColor.R = 128;
			TextColor.G = 255;
			TextColor.B = 128;
			TextColor.A = 255;
		}

		Battle.DrawDebugString(vect(0, 0, 64), GroupSpawnDebugText, GroupSpawn, TextColor);
		Battle.DrawDebugBox(GroupSpawn.StaticMesh.Bounds.Origin, GroupSpawn.StaticMesh.Bounds.BoxExtent, TextColor.R, TextColor.G, TextColor.B, true);
	}

	// add discs to show the minimum and maximum spawn distances from the objective parcel
	TacticalMissionManager.GetActiveMissionSchedule(ActiveSchedule);

	SchMinSpawnDistance = ActiveSchedule.MinXComSpawnDistance;
	SchIdealSpawnDistance = ActiveSchedule.IdealXComSpawnDistance;

	LocalBattleStateData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (LocalBattleStateData != none)
	{
		foreach class'X2SitreptemplateManager'.static.IterateEffects(class'X2SitRepEffect_ModifyXComSpawn', SitRepEffect, LocalBattleStateData.ActiveSitReps)
		{
			SitRepEffect.ModifyLocations( SchIdealSpawnDistance, SchMinSpawnDistance );
		}
	}

	MinimumSpawnDistance = SchMinSpawnDistance * class'XComWorldData'.const.WORLD_StepSize;
	Battle.DrawDebugCylinder(BattleDataState.MapData.ObjectiveLocation, BattleDataState.MapData.ObjectiveLocation + vect(0, 0, 256), MinimumSpawnDistance, 32, 255, 128, 128, true);

	IdealSpawnDistance = SchIdealSpawnDistance * class'XComWorldData'.const.WORLD_StepSize;
	Battle.DrawDebugCylinder(BattleDataState.MapData.ObjectiveLocation, BattleDataState.MapData.ObjectiveLocation + vect(0, 0, 256), IdealSpawnDistance, 32, 128, 128, 256, true);
}

defaultproperties
{
	bBlockingLoadParcels = true
	bGeneratingMap=false
	bFinishedGeneratingMap=false
}
