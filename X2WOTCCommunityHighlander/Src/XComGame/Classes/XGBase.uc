//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGBase extends Actor config(GameData);

var config string BaseMapName;
var config string BaseCapMapName;

var LevelStreaming AvengerCap_Level;
var LevelStreaming SkyAndLight_Level;
var LevelStreaming Avenger_Level;
var LevelStreaming Terrain_Level;
var LevelStreaming PostMissionSequence_Level;
var LevelStreaming PreMissionSequence_Level;

var MaterialInstanceConstant FacilityPreviewMaterial;
var float FacilityPreviewTransition;

var string CurrentLightEnvironment;
var string CurrentTerrainMap;

struct AuxLevels
{
	var array<LevelStreaming> Levels;
};

struct PreviewRequest
{
	var int MapIndex;
	var name TemplateName;
	var bool bVisible;
};

var PreviewRequest DelayedPreviewRequest;

struct QueuedRoomSwapInfo
{
	var int RoomIndex;
	var Vector RoomOffset;
	var string RoomToRemove;
	var name RoomBeingAdded;
};

var array<QueuedRoomSwapInfo>     m_queuedRoomSwaps;

var array<LevelStreaming>     m_arrLvlStreaming;
var array<LevelStreaming>     m_arrLvlStreaming_Anim;
var array<AuxLevels>          m_arrLvlStreaming_AuxMaps;
var array<LevelStreaming>     m_arrLvlStreaming_Lighting;
var array<LevelStreaming>     m_arrLvlStreaming_FlyIn;

var config array<LandingSiteLighting> GenericTimeOfDayMaps; // for fallback
var config array<LandingSiteLighting> BiomeTimeOfDayMaps; // biome specific time of day maps
var config array<BiomeTerrain> BiomeTerrainMaps;

var config string UnderConstructionMap;

var XGBaseCrewMgr m_kCrewMgr;
var XGBaseAmbientVOMgr m_kAmbientVOMgr;

var bool AvengerRoomsVisible;
var array<name> ArrBuildPreviewNames;

//------------------------------------------------------
//------------------------------------------------------
function Init()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local Object ThisObj;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	ArrBuildPreviewNames.AddItem('OfficerTrainingSchool');
	ArrBuildPreviewNames.AddItem('AdvancedWarfareCenter');
	ArrBuildPreviewNames.AddItem('Laboratory');
	ArrBuildPreviewNames.AddItem('PowerRelay');
	ArrBuildPreviewNames.AddItem('ProvingGround');
	ArrBuildPreviewNames.AddItem('PsiChamber');
	ArrBuildPreviewNames.AddItem('ResistanceComms');
	ArrBuildPreviewNames.AddItem('ShadowChamber');
	ArrBuildPreviewNames.AddItem('UFODefense');
	ArrBuildPreviewNames.AddItem('Workshop');
	ArrBuildPreviewNames.AddItem('ResistanceRing');
	ArrBuildPreviewNames.AddItem('RecoveryCenter');

	m_arrLvlStreaming.Add( XComHQ.Rooms.Length );
	m_arrLvlStreaming_Lighting.Add(XComHQ.Rooms.Length);
	m_arrLvlStreaming_FlyIn.Add(XComHQ.Rooms.Length);
	m_arrLvlStreaming_Anim.Add(XComHQ.Rooms.Length);
	m_arrLvlStreaming_AuxMaps.Add(XComHQ.Rooms.Length);

	m_kCrewMgr = Spawn( class'XGBaseCrewMgr', Owner );
	m_kCrewMgr.Init();

	m_kAmbientVOMgr = Spawn( class'XGBaseAmbientVOMgr', Owner );
	m_kAmbientVOMgr.Init();

	CurrentLightEnvironment = GetTimeOfDayMap();

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'UpgradeCompleted', OnUpgradeCompleted, ELD_OnStateSubmitted, , );

	`HQPC.ClientFlushLevelStreaming();
	StreamInAvenger();
}

function EventListenerReturn OnUpgradeCompleted(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{	
	local XComGameState_FacilityXCom XComFacility;

	XComFacility = XComGameState_FacilityXCom(EventSource);	
	UpdateFacilityUpgradeVisibilty(XComFacility.GetRoom().MapIndex);
	
	return ELR_NoInterrupt;
}

private simulated function array<XComLevelActor> GetLevelActorsWithTag(name TagName)
{
	local XComLevelActor TheActor;
	local array<XComLevelActor> ActorsWithTag;

	foreach WorldInfo.AllActors(class'XComLevelActor', TheActor)
	{
		if (TheActor != none && TheActor.Tag == TagName)
		{
			ActorsWithTag.AddItem(TheActor);
		}
	}

	return ActorsWithTag;
}

simulated function array<XComLevelActor> GetLevelActorsWithLayer(name LayerName)
{
	local XComLevelActor TheActor;
	local array<XComLevelActor> ActorsWithLayer;

	foreach WorldInfo.AllActors(class'XComLevelActor', TheActor)
	{
		if( TheActor != none && TheActor.Layer ==LayerName)
		{
			ActorsWithLayer.AddItem(TheActor);
		}
	}

	return ActorsWithLayer;
}

private function DoSetFacilityBuildPreviewVisibility(int MapIndex, name TemplateName, bool bVisible)
{
	local XComLevelActor TheActor;
	local array<XComLevelActor> PreviewActors;
	local int BuildPreviewIdx;
	local MaterialInterface Mat;
	local MaterialInstanceConstant PreviewMIC;

	// First get all of the build preview actors which currently exist
	PreviewActors = GetLevelActorsWithTag('FacilityBuildPreview_Plane');

	foreach PreviewActors(TheActor)
	{
		// Iterate through the build preview actors until we find the one which lives in this specific level (room)
		if (InStr(PathName(TheActor), PathName(m_arrLvlStreaming[MapIndex].LoadedLevel)) != INDEX_NONE)
		{
			break;
		}
	}

	if (TheActor == none)
	{
		`Redscreen("Found no FacilityBuildPreview_Plane actor. Build preview not displayed.");
		return;
	}

	BuildPreviewIdx = ArrBuildPreviewNames.Find(TemplateName);
	if (BuildPreviewIdx < 0)
	{
		return;
	}

	Mat = TheActor.StaticMeshComponent.GetMaterial(0);
	PreviewMIC = MaterialInstanceConstant(Mat);
	if (PreviewMIC != none)
	{
		// If this is not a child MIC, make it one. This is done so that the material updates below don't stomp
		// on each other between units.
		if (InStr(PreviewMIC.Name, "MaterialInstanceConstant") == INDEX_NONE)
		{
			PreviewMIC = new(TheActor) class'MaterialInstanceConstant';
			PreviewMIC.SetParent(TheActor.StaticMeshComponent.GetMaterial(0));
			TheActor.StaticMeshComponent.SetMaterial(0, PreviewMIC);
		}
		
		PreviewMIC.SetScalarParameterValue('FacilityPreviewIndex', BuildPreviewIdx);

		if (bVisible)
		{
			PreviewMIC.SetScalarParameterValue('Transition', 1);
		}
		else
		{
			FacilityPreviewMaterial = PreviewMIC;
			GotoState('FadeOutFacilityPreview');
		}
	}	
}

function SetFacilityBuildPreviewVisibility(int MapIndex, name TemplateName, bool bVisible)
{
	// if the user selects view room from the UIAlert and the avenger rooms aren't loaded then LevelLoaded can be none (its still loading)
	if (m_arrLvlStreaming[MapIndex].LoadedLevel == none)
	{
		// so set these and in the OnLoaded delegate we will display the preview effect
		DelayedPreviewRequest.MapIndex = MapIndex;
		DelayedPreviewRequest.TemplateName = TemplateName;
		DelayedPreviewRequest.bVisible = bVisible;
	}
	else
	{
		DoSetFacilityBuildPreviewVisibility(MapIndex, TemplateName, bVisible);
	}
}

state Idle
{
};

state FadeOutFacilityPreview
{
	event BeginState(Name PreviousStateName)
	{
		`assert(FacilityPreviewMaterial != none);
		FacilityPreviewTransition = 1;
		FacilityPreviewMaterial.SetScalarParameterValue('Transition', FacilityPreviewTransition);
	}

	simulated event Tick( float fDeltaT )
	{
		FacilityPreviewTransition -= (fDeltaT * `HQINTERPTIME);
		FacilityPreviewTransition = FClamp(FacilityPreviewTransition, 0, 1);

		FacilityPreviewMaterial.SetScalarParameterValue('Transition', FacilityPreviewTransition);
		if (FacilityPreviewTransition == 0)
		{
			FacilityPreviewMaterial = none;
			FacilityPreviewTransition = 0;
			GotoState('Idle');
		}
	}
};

private function UpdateFacilityUpgradeVisibilty(int RoomIdx)
{
	local XComGameState_FacilityXCom Facility;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local name UpgradeName;
	local string PreUpgradeName;
	local XComGameState_HeadquartersRoom RoomState;

	// Issue #775 (single line)
	/// HL-Docs: ref:Bugfixes; issue:775
	/// Applying facility upgrades before the facility map is loaded no longer crashes the game.
	if (m_arrLvlStreaming[RoomIdx] == none) return;

	RoomState = GetRoom(RoomIdx);
	Facility = RoomState.GetFacility();

	if (Facility == none)
		return;

	foreach Facility.GetMyTemplate().Upgrades(UpgradeName)
	{
		UpgradeTemplate = X2FacilityUpgradeTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(UpgradeName));
		if (UpgradeTemplate != none)
		{
			PreUpgradeName = "Pre_"$UpgradeTemplate.DataName;
			if (Facility.HasUpgrade(UpgradeTemplate.DataName))
			{
				if (UpgradeTemplate.PreviousMapName != "") // If a specific previous upgrade is defined, use that instead of PreUpgradeName
					class'Helpers'.static.SetOnAllActorsInLevelWithTag(m_arrLvlStreaming[RoomIdx], name(UpgradeTemplate.PreviousMapName), true, TRUE);
				else
					class'Helpers'.static.SetOnAllActorsInLevelWithTag(m_arrLvlStreaming[RoomIdx], name(PreUpgradeName), true, TRUE);
				
				class'Helpers'.static.SetOnAllActorsInLevelWithTag(m_arrLvlStreaming[RoomIdx], UpgradeTemplate.DataName, false, TRUE);
			}
			else
			{
				class'Helpers'.static.SetOnAllActorsInLevelWithTag(m_arrLvlStreaming[RoomIdx], UpgradeTemplate.DataName, true, TRUE);
				
				if (UpgradeTemplate.PreviousMapName == "") // PreviousMapName indicates a chain of upgrades, so only show the PreUpgradeName if it is a simple swap
					class'Helpers'.static.SetOnAllActorsInLevelWithTag(m_arrLvlStreaming[RoomIdx], name(PreUpgradeName), false, TRUE);
			}
		}
	}
}

//------------------------------------------------------
function XComGameState_HeadquartersRoom GetRoom(int Index)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Room = XComHQ.GetRoom(Index);

	return Room;
}

static function Vector GetRoomLocation(Actor UseActorForIterator, int Index)
{
	local XComHQ_RoomLocation RoomLoc;
	local string tagtofind;

	tagtofind = ""$Index;

	foreach UseActorForIterator.AllActors(class'XComHQ_RoomLocation', RoomLoc)
	{
		if (RoomLoc.RoomName == name(tagtofind))
			return RoomLoc.Location;
	}

	return vect(0,0,0);
}

static function string GetAnimMapname(XComGameState_HeadquartersRoom Room)
{
	local XComGameState_FacilityXCom Facility;	

	if(Room.HasFacility())
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Room.Facility.ObjectID));
		if(Facility != none)
		{
			return Facility.GetMyTemplate().AnimMapName;
		}
	}

	return "";
}

static function string GetMapname(XComGameState_HeadquartersRoom Room)
{
	local XComGameState_FacilityXCom Facility;
	local string MapName;

	if(Room.UnderConstruction || Room.ClearingRoom)
	{
		return default.UnderConstructionMap;
	}

	if(Room.HasFacility())
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Room.Facility.ObjectID));

		if(Facility != none)
		{
			MapName = Facility.GetMyTemplate().MapName;

			if(MapName != "")
			{
				return MapName;
			}
		}
		return "Debug_Blue";
	}

	if(Room.HasSpecialFeature())
	{
		if(Room.bSpecialRoomFeatureCleared)
		{
			return Room.SpecialFeatureClearedMapName;
		}
		else
		{
			return Room.SpecialFeatureUnclearedMapName;
		}
	}
	else
	{
		return "AVG_ER_A";
	}
}

static function string GetFlyInMapName(XComGameState_FacilityXCom Facility)
{
	return Facility.GetMyTemplate().FlyInMapName;
}

static function name GetFlyInRemoteEventName(XComGameState_FacilityXCom Facility)
{
	return Facility.GetMyTemplate().FlyInRemoteEvent;
}

function SetAvengerCapVisibility(bool bVisible)
{
	local DirectionalLight	DLight;
	`MAPS.SetStreamingLevelVisible(AvengerCap_Level, bVisible);

	foreach AllActors(class'DirectionalLight', DLight)
	{
		if (DLight != none)
		{
			DLight.LightComponent.CastDynamicShadows = bVisible;
			DLight.ReattachComponent(DLight.LightComponent);
		}
	}
}

function SetPostMissionSequenceVisibility(bool bVisible)
{	
	`MAPS.SetStreamingLevelVisible(PostMissionSequence_Level, bVisible);
	`XENGINE.SetEnableAllLightsInLevel(PostMissionSequence_Level.LoadedLevel, bVisible);
}

function SetPreMissionSequenceVisibility(bool bVisible)
{
	`MAPS.SetStreamingLevelVisible(PreMissionSequence_Level, bVisible);
	`XENGINE.SetEnableAllLightsInLevel(PreMissionSequence_Level.LoadedLevel, bVisible);
}

simulated function OnEnvMapUpdated(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	WorldInfo.MyLocalEnvMapManager.ResetCaptures();
}

function SetAvengerVisibility(bool bVisible)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersRoom RoomState, NewRoomState;
	local XComGameState_FacilityXCom AvengerFacility;
	local Vector vLoc;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Streamed in Rooms");

	if(Avenger_Level != none && Terrain_Level != none)
	{
		if(bVisible && GetTimeOfDayMap() != CurrentLightEnvironment)
		{
			SkyAndLight_Level = none;
			`MAPS.RemoveStreamingMapByName(CurrentLightEnvironment);
			CurrentLightEnvironment = GetTimeOfDayMap();
			SkyAndLight_Level = `MAPS.AddStreamingMap(CurrentLightEnvironment, vLoc, , true);
		}
		else
		{
			`MAPS.SetStreamingLevelVisible(SkyAndLight_Level, bVisible);
		}

		if(bVisible && GetBiomeTerrainMap() != CurrentTerrainMap)
		{
			`MAPS.RemoveStreamingMapByName(CurrentTerrainMap);
			CurrentTerrainMap = GetBiomeTerrainMap();
			Terrain_Level = `MAPS.AddStreamingMap(CurrentTerrainMap, vLoc, , true);
		}
		else
		{
			`MAPS.SetStreamingLevelVisible(Terrain_Level, bVisible);
		}

		`MAPS.SetStreamingLevelVisible(Avenger_Level, bVisible);

		for(idx = 0; idx < m_arrLvlStreaming.Length; idx++)
		{
			RoomState = GetRoom(idx);

			if(m_arrLvlStreaming[idx] != none)
			{
				`MAPS.SetStreamingLevelVisible(m_arrLvlStreaming[idx], bVisible);
			}

			if(m_arrLvlStreaming_Lighting[idx] != none)
			{
				`MAPS.SetStreamingLevelVisible(m_arrLvlStreaming_Lighting[idx], bVisible);
			}

			if(m_arrLvlStreaming_Anim[idx] != none)
			{
				`MAPS.SetStreamingLevelVisible(m_arrLvlStreaming_Anim[idx], bVisible);
			}

			if(RoomState.Facility.ObjectID > 0)
			{
				AvengerFacility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(RoomState.Facility.ObjectID));
				if(AvengerFacility != none)
				{	
					SetAuxMapsVisibility(idx, AvengerFacility.GetMyTemplate().AuxMaps);
				}
			}
			
			if(RoomState.UpdateRoomMap && bVisible)
			{
				NewRoomState = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', RoomState.ObjectID));
				NewRoomState.UpdateRoomMap = false;

				QueueRoomSwap(idx);
			}
	
			UpdateFacilityUpgradeVisibilty(idx);
		}
	}

	/*
	if (bVisible && AvengerRoomsVisible != bVisible)
	{
		m_kCrewMgr.RepopulateBaseRoomsWithCrew();
	}
	*/

	AvengerRoomsVisible = bVisible;

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	if(bVisible)
	{
		PlayFacilityFlyIns();
	}
}

function PlayFacilityFlyIns()
{
	local array<int> FlyInsIndices;
	local XComGameState_FacilityXCom Facility;
	local string MapName;
	local name RemoteEventName;
	local int idx;

	FlyInsIndices = GetFlyInLevelStreaming();

	if(FlyInsIndices.Length > 0)
	{
		for(idx = 0; idx < FlyInsIndices.Length; idx++)
		{
			Facility = GetRoom(FlyInsIndices[idx]).GetFacility();
			MapName = GetFlyInMapName(Facility);

			if(MapName != "")
			{
				if(`MAPS.IsLevelLoaded(name(MapName), true))
				{
					RemoteEventName = GetFlyInRemoteEventName(Facility);

					if(RemoteEventName != '')
					{
						`XCOMGRI.DoRemoteEvent(RemoteEventName);
						HandleFlyInCinematic(Facility);
					}
				}
				else
				{
					SetTimer(0.3f, false, nameof(PlayFacilityFlyIns));
					break;
				}
			}
		}
	}
}

function HandleFlyInCinematic(XComGameState_FacilityXCom Facility)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersRoom Room;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Handle FlyIn Cinematic");
	Facility = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', Facility.ObjectID));
	Facility.bPlayFlyIn = false;
	Room = Facility.GetRoom();
	Room = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
	Room.UpdateRoomMap = true;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function array<int> GetFlyInLevelStreaming()
{
	local array<int> FlyInsIndices;
	local int idx;

	for(idx = 0; idx < m_arrLvlStreaming_FlyIn.Length; idx++)
	{
		if(m_arrLvlStreaming_FlyIn[idx] != none)
		{
			FlyInsIndices.AddItem(idx);
		}
	}

	return FlyInsIndices;
}

//####################################################################################
// 
//####################################################################################

static function string GetTimeOfDayMap()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local ETimeOfDay TimeOfDayValue;
	local string CurrentBiome;
	local TDateTime GameTime;
	local array<string> MatchingMaps;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	GameTime = `STRATEGYRULES.GameTime;
	class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(XComHQ.Get2DLocation(), GameTime);
	TimeOfDayValue = class'X2StrategyGameRulesetDataStructures'.static.GetTimeOfDay(GameTime);
	CurrentBiome = class'X2StrategyGameRulesetDataStructures'.static.GetBiome(XComHQ.Get2DLocation());

	// First try biome specific
	for(idx = 0; idx < default.BiomeTimeOfDayMaps.Length; idx++)
	{
		if(default.BiomeTimeOfDayMaps[idx].eTimeOfDay == TimeOfDayValue && default.BiomeTimeOfDayMaps[idx].arrBiomeTypes.Find(CurrentBiome) != INDEX_NONE)
		{
			MatchingMaps.AddItem(default.BiomeTimeOfDayMaps[idx].MapName);
		}
	}

	if(MatchingMaps.Length > 0)
	{
		return MatchingMaps[`SYNC_RAND_STATIC(MatchingMaps.Length)];
	}

	// Fallback to generic if we have to
	for(idx = 0; idx < default.GenericTimeOfDayMaps.Length; idx++)
	{
		if(default.GenericTimeOfDayMaps[idx].eTimeOfDay == TimeOfDayValue)
		{
			return default.GenericTimeOfDayMaps[idx].MapName;
		}
	}

	// Should not reach this case
	return default.GenericTimeOfDayMaps[0].MapName;
}

static function string GetBiomeTerrainMap(optional bool bForceReRoll = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local string CurrentBiome;
	local int Index;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(!bForceReRoll && XComHQ.LandingSiteMap != "")
	{
		return XComHQ.LandingSiteMap;
	}

	CurrentBiome = class'X2StrategyGameRulesetDataStructures'.static.GetBiome(XComHQ.Get2DLocation());
	Index = default.BiomeTerrainMaps.Find('BiomeType', CurrentBiome);

	if(Index != INDEX_NONE)
	{
		return default.BiomeTerrainMaps[Index].arrMapNames[`SYNC_RAND_STATIC(default.BiomeTerrainMaps[Index].arrMapNames.Length)];
	}

	// Should not reach this case
	return default.BiomeTerrainMaps[0].arrMapNames[0];
}

private function StreamInAuxMaps(int Idx, XComGameState_HeadquartersRoom Room, out const Vector vLoc, bool bImmediate)
{
	local XComGameState_FacilityXCom Facility;
	local AuxMapInfo MapInfo;

	if (Room != none && Room.HasFacility())
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Room.Facility.ObjectID));
		if (Facility != none)
		{
			foreach Facility.GetMyTemplate().AuxMaps(MapInfo)
			{
				m_arrLvlStreaming_AuxMaps[Idx].Levels.AddItem(`MAPS.AddStreamingMap(MapInfo.MapName, vLoc, , bImmediate, true, MapInfo.InitiallyVisible));
			}
		}
	}
}

private function bool AreAuxMapsLoaded(int Idx)
{
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local LevelStreaming Level;
	local int MapIdx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Room = XComHQ.GetRoom(Idx);

	if (Room != none && Room.HasFacility())
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Room.Facility.ObjectID));
		if (Facility != none)
		{
			if (Facility.GetMyTemplate().AuxMaps.Length == m_arrLvlStreaming_AuxMaps[idx].Levels.Length)
			{
				for (MapIdx = 0; MapIdx < Facility.GetMyTemplate().AuxMaps.Length; ++MapIdx)
				{
					Level = m_arrLvlStreaming_AuxMaps[idx].Levels[MapIdx];

					if(Level != none)
					{
						if (Facility.GetMyTemplate().AuxMaps[MapIdx].InitiallyVisible)
						{
							if (!Level.bIsVisible)
							{
								return false;
							}
						}
						else
						{
							if (Level.bShouldBeLoaded && Level.bHasLoadRequestPending)
							{
								return false;
							}
						}
					}
				}
			}
		}
	}

	return true;
}

private function SetAuxMapsVisibility(int Idx, array<AuxMapInfo> AuxMapInfo)
{
	local LevelStreaming Level;
	local int AuxMapInfoIndex;

	AuxMapInfoIndex = 0;
	foreach m_arrLvlStreaming_AuxMaps[Idx].Levels(Level)
	{
		if (Level != none)
		{
			`MAPS.SetStreamingLevelVisible(Level, AuxMapInfo[AuxMapInfoIndex].InitiallyVisible);
		}

		++AuxMapInfoIndex;
	}
}

function StreamInAvenger()
{
	local vector vLoc;

	Avenger_Level = `MAPS.AddStreamingMap(BaseMapName, vLoc, , true, , , OnAvengerMapVisible);
	AvengerCap_Level = `MAPS.AddStreamingMap(BaseCapMapName, vLoc, , true);
	CurrentLightEnvironment = GetTimeOfDayMap();
	SkyAndLight_Level = `MAPS.AddStreamingMap(CurrentLightEnvironment, vLoc, , true);

	LoadPostMissionMap();
	LoadPreMissionMap();

	CurrentTerrainMap = GetBiomeTerrainMap();
	Terrain_Level = `MAPS.AddStreamingMap(CurrentTerrainMap, vLoc, , true, , , OnEnvMapVisible);

	SendAvengerInfoKismetEvent();
}

simulated function OnEnvMapVisible(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	local XComWeatherControl WeatherActor;

	foreach `XWORLDINFO.AllActors(class'XComWeatherControl', WeatherActor )
	{
		WeatherActor.Init();
	}
}

simulated function OnAvengerMapVisible(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	local XComLevelVolume LevelVolume;

	foreach `XWORLDINFO.AllActors(class'XComLevelVolume', LevelVolume)
	{
		WorldInfo.SetupNonTacticalWorldVolumeInfo(LevelVolume);
	}
}

function bool MinimumAvengerStreamedInAndVisible()
{
	local int idx;

	if (Avenger_Level != none)
	{
		if (Avenger_Level.bIsVisible && AvengerCap_Level.bIsVisible && SkyAndLight_Level.bIsVisible && Terrain_Level.bIsVisible)
		{
			for(idx = 0; idx < m_arrLvlStreaming.Length; idx++ )
			{
				if (m_arrLvlStreaming[idx] != none)
				{
					if (m_arrLvlStreaming[idx].bIsVisible == false)
					{
						return false;
					}
				}

				if (m_arrLvlStreaming_Lighting[idx] != none)
				{
					if (m_arrLvlStreaming_Lighting[idx].bIsVisible == false)
					{
						return false;
					}
				}	

				if (m_arrLvlStreaming_Anim[idx] != none)
				{
					if (m_arrLvlStreaming_Anim[idx].bIsVisible == false)
					{
						return false;
					}
				}	

				if (!AreAuxMapsLoaded(idx))
				{
					return false;
				}
			}

			return true;
		}
	}

	return false;
}

function SendAvengerInfoKismetEvent()
{
	local int i;
	local array<SequenceObject> Events;

	WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_SetAvengerData', TRUE, Events);
	for (i = 0; i < Events.Length; i++)
	{
		SeqEvent_OnStrategyRoomEntered(Events[i]).CheckActivate(WorldInfo, None);
	}
}

function StreamInBaseRooms(bool bImmediate=true)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int idx;
	local XComGameStateHistory History;	

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for (idx = 0; idx < XComHQ.Rooms.Length; idx++)
	{
		//RAM - We want to load in all the rooms at once, the loads should block ( or else the player will see them come in one at a time )
		StreamInRoom(idx, bImmediate);
	}
}

function UnstreamRooms()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int idx;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	m_kCrewMgr.RemoveBaseCrew();

	for (idx = 0; idx < XComHQ.Rooms.Length; idx++)
	{
		RemoveRoom(idx);
	}
	
}

function ResetPostMissionMap()
{
	//This is necessary to prevent the post mission map needing to restore itself back to its starting state. Instead we just unload it and call it back up
	`MAPS.RemoveStreamingMapByName("CIN_PostMission1");
	SetTimer(1.0f, false, nameof(LoadPostMissionMap));
}

function LoadPostMissionMap()
{
	local vector vLoc;

	PostMissionSequence_Level = `MAPS.AddStreamingMap("CIN_PostMission1", vLoc, , true, , , OnPostMissionLevelLoadCompleted);
}

function OnPostMissionLevelLoadCompleted(Name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	SetPostMissionSequenceVisibility(false);
}

function ResetPreMissionMap()
{
	//This is necessary to prevent the post mission map needing to restore itself back to its starting state. Instead we just unload it and call it back up
	`MAPS.RemoveStreamingMapByName("CIN_PreMission");
	SetTimer(1.0f, false, nameof(LoadPreMissionMap));
}

function LoadPreMissionMap()
{
	local vector vLoc;

	PreMissionSequence_Level = `MAPS.AddStreamingMap("CIN_PreMission", vLoc, , true, , , OnPreMissionLevelLoadCompleted);
}

function OnPreMissionLevelLoadCompleted(Name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	SetPreMissionSequenceVisibility(false);
}

function StreamInRoom(int Index, bool bImmediate = false)
{
	local Vector vLoc;
	local string Mapname;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	vLoc = GetRoomLocation(self, Index);
	
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Room = XComHQ.GetRoom(Index);

	Mapname = GetMapname(Room);
	m_arrLvlStreaming[Index] = `MAPS.AddStreamingMap(Mapname, vLoc, , bImmediate, true, true, OnRoomLevelLoaded);

	MapName = GetAnimMapname(Room);
	if (MapName != "")
	{
		m_arrLvlStreaming_Anim[Index] =  `MAPS.AddStreamingMap(MapName, vLoc, , bImmediate, true, true, OnAnimLevelLoaded);
	}

	StreamInAuxMaps(Index, Room, vLoc, bImmediate);

	if(Room.HasFacility())
	{
		Facility = Room.GetFacility();
	
		if(Facility.bPlayFlyIn)
		{
			MapName = GetFlyInMapName(Facility);
			if(MapName != "")
			{
				m_arrLvlStreaming_FlyIn[Index] = `MAPS.AddStreamingMap(Mapname, vLoc, , bImmediate, true, true);
			}
		}
	}
}


function OnRoomLevelLoaded(Name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	local int QueuedLoadIdx;
	
	if (DelayedPreviewRequest.MapIndex != -1)
	{
		DoSetFacilityBuildPreviewVisibility(DelayedPreviewRequest.MapIndex, DelayedPreviewRequest.TemplateName, DelayedPreviewRequest.bVisible);
		DelayedPreviewRequest.MapIndex = -1;
	}
	
	QueuedLoadIdx = m_queuedRoomSwaps.Find('RoomBeingAdded', LevelPackageName);
	if (QueuedLoadIdx != INDEX_NONE)
	{
		UpdateFacilityUpgradeVisibilty(m_queuedRoomSwaps[QueuedLoadIdx].RoomIndex);
		`MAPS.RemoveStreamingMapByNameAndLocation(m_queuedRoomSwaps[QueuedLoadIdx].RoomToRemove, m_queuedRoomSwaps[QueuedLoadIdx].RoomOffset, false);
		m_queuedRoomSwaps.Remove(QueuedLoadIdx, 1);
	}
}

function OnAnimLevelLoaded(Name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	WorldInfo.MyKismetVariableMgr.RebuildVariableMap();
}

private function QueueRoomSwap(int index)
{
	local QueuedRoomSwapInfo SwapInfo;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	SwapInfo.RoomIndex = index; 
	SwapInfo.RoomOffset = GetRoomLocation(self, index);
	SwapInfo.RoomToRemove = string(m_arrLvlStreaming[index].PackageName);
	SwapInfo.RoomBeingAdded = name(GetMapname(XComHQ.GetRoom(Index)));

	m_queuedRoomSwaps.AddItem(SwapInfo);
	
	StreamInRoom(index, true);
}

function RemoveRoom(int Index)
{
	local Vector vLoc;

	vLoc = GetRoomLocation(self, Index);

	// Remove room map and lighting map
	`MAPS.RemoveStreamingMap(vLoc);
	`MAPS.RemoveStreamingMap(vLoc);
	`MAPS.RemoveStreamingMap(vLoc);
}

function UpdateFacilityProps()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for( idx = 0; idx < XComHQ.Rooms.Length; idx++ )
	{
		Facility = XComHQ.GetRoom(idx).GetFacility();
		if( Facility != none && Facility.GetMyTemplate().UpdateFacilityPropsFn != none )
		{
			Facility.GetMyTemplate().UpdateFacilityPropsFn(Facility.GetReference(), self);
		}
	}
}

DefaultProperties
{
	DelayedPreviewRequest = (MapIndex = -1);
	AvengerRoomsVisible = false;
}
