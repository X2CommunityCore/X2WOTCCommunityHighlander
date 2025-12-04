class XComEnvLightingManager extends Object
	native(Core)
	config(Maps);

// Environment mood - ominous, etc.
enum EMood
{
	eMood_Normal,
	eMood_Max
};

// Specify weather condition
enum EWeatherType
{
	eWeatherType_Clear,
	eWeatherType_Rain,
	eWeatherType_Snow,
	eWeatherType_Max
};

// Control what types of lights get enabled for a given environment. Can be extended to support other things like Chaos-only, Inclement Weather, etc.
enum EEnvLightingSetting
{
	eEnvLighting_Day,
	eEnvLighting_Night,
	eEnvLighting_Max
};

struct native EnvironmentLightingDefinition
{
	// The map that contains the environment lighting matching this description
	var config string	                MapName;
	var ETimeofDay		                eTimeOfDay;
	var EMood			                eMood;
	var EWeatherType	                eWeatherCondition;
	var array<EEnvLightingSetting>      eEnvLighting;
	var array<string>                   arrPlotTypes;
	var array<string>                   arrPlotMaps;
	var array<string>                   arrBiomeTypes;
	var array<string>					arrMissionTypes;
};

var config privatewrite array<EnvironmentLightingDefinition> arrEnvironmentLightingDefs;
var string currentMapName;
var int    currentMapIdx;
var bool   ForceNoLoad;

var string strPlotType;
var string strPlotMap;
var string strBiomeType;
var ETimeOfDay MatchTimeOfDay;

var bool bBlockingLoadParcels;
var bool bEnvMapVisible;

native function SetForceNoLoad(bool bForceNoLoad);

function Init(XComGameState_BattleData BattleData)
{
	local int nRandomMapIdx;
	local float randVal;
	local array<EnvironmentLightingDefinition> arrMatchingEnvLightingDefs;	
	local string strMissionType;
	local UITacticalQuickLaunch UITQL;
	local bool bIsTQL;

	if( ForceNoLoad )
		return;

	// Not sure if there is a better to do this. 
	// There is the flag BattleData.bIsTacticalQuickLaunch, but it doesn't get set until sometime after this function
	bIsTQL = false;
	foreach `XWORLDINFO.AllActors(class'UITacticalQuickLaunch', UITQL)
	{
		bIsTQL = true;
		continue;
	}

	if (currentMapName == "" || !bIsTQL)
	{
		strPlotType = `PARCELMGR.PlotType.strType;
		strPlotMap = BattleData.MapData.PlotMapName;
		strBiomeType = BattleData.MapData.Biome;
		strMissionType = BattleData.MapData.ActiveMission.sType;

		MatchTimeOfDay = eTimeOfDay_None;
		if( BattleData.m_strLocation != "" )
		{
			MatchTimeOfDay = class'X2StrategyGameRulesetDataStructures'.static.GetTimeOfDay(BattleData.LocalTime);
		}

		arrMatchingEnvLightingDefs = GetMatchingEnvLightingDefs(strPlotType, strPlotMap, strBiomeType, strMissionType, MatchTimeOfDay, BattleData.bRainIfPossible);
	
		if (arrMatchingEnvLightingDefs.Length > 0)
		{
			randVal = `SYNC_RAND_TYPED(arrMatchingEnvLightingDefs.Length);
			nRandomMapIdx = randVal;
			currentMapName = arrMatchingEnvLightingDefs[nRandomMapIdx].MapName;
			nRandomMapIdx = GetMapIndexByName(currentMapName);
		}
		else
		{
			randVal = `SYNC_RAND_TYPED(arrEnvironmentLightingDefs.Length);
			nRandomMapIdx = randVal;
			currentMapName = arrEnvironmentLightingDefs[nRandomMapIdx].MapName;
		}

		`log( "Map roll: " @ randVal @ " idx: " @ nRandomMapIdx @ " name: " @ arrEnvironmentLightingDefs[nRandomMapIdx].MapName, , 'XCom_ParcelOutput' );
	}
	else
	{
		nRandomMapIdx = GetMapIndexByName(currentMapName);

		if (BattleData.bRainIfPossible)
		{
			// more hackery...
			strPlotType = BattleData.PlotType;
			strPlotMap = BattleData.MapData.PlotMapName;
			strBiomeType = BattleData.MapData.Biome;
			strMissionType = BattleData.MapData.ActiveMission.sType;
			MatchTimeOfDay = arrEnvironmentLightingDefs[nRandomMapIdx].eEnvLighting[0] == eEnvLighting_Night ? eTimeOfDay_Night : eTimeOfDay_None;

			arrMatchingEnvLightingDefs = GetMatchingEnvLightingDefs(strPlotType, strPlotMap, strBiomeType, strMissionType, MatchTimeOfDay, true);

			// If a rain map is selected, it will be the only thing returned. But Shanty and Psi Gate don't have rain maps, so use what was already chosen
			if (arrMatchingEnvLightingDefs.Length == 1)
			{
				`MAPS.RemoveStreamingMapByName(currentMapName);
				currentMapName = arrMatchingEnvLightingDefs[0].MapName;
				nRandomMapIdx = GetMapIndexByName(currentMapName);
			}
		}

		`log( "Map choice: " @ nRandomMapIdx @ " name: " @ arrEnvironmentLightingDefs[nRandomMapIdx].MapName, , 'XCom_ParcelOutput' );
	}

	if( currentMapName != "" )
	{
		`log( "Chose " @ arrEnvironmentLightingDefs[nRandomMapIdx].MapName @ " for TimeOfDay: " @ arrEnvironmentLightingDefs[nRandomMapIdx].eTimeOfDay	@ " Mood: " @ arrEnvironmentLightingDefs[nRandomMapIdx].eMood @ " WeatherCondition: " @ arrEnvironmentLightingDefs[nRandomMapIdx].eWeatherCondition, , 'XCom_ParcelOutput' );
		/*currentMapName = arrEnvironmentLightingDefs[nRandomMapIdx].MapName;*/
		`MAPS.AddStreamingMap(currentMapName,,,bBlockingLoadParcels,,,OnEnvMapVisible);
		`MAPS.AddStreamingMap("Wind",,,bBlockingLoadParcels);

		// We are starting to stream in the map
		bEnvMapVisible = false;

		if( BattleData != none )
		{
			BattleData.MapData.EnvironmentLightingMapName = currentMapName;
		}

		currentMapIdx = nRandomMapIdx;

		OnFinishedLoading();
	}
	else
	{
		`log( "Unable to select Environment Lighting map", , 'XCom_ParcelOutput' );
	}
}

simulated function OnEnvMapVisible(name LevelPackageName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	local XComWeatherControl WeatherActor;

	foreach `XWORLDINFO.AllActors(class'XComWeatherControl', WeatherActor )
	{
		WeatherActor.Init();
	}

	bEnvMapVisible = true;
}

static function array<EnvironmentLightingDefinition> GetMatchingEnvLightingDefs(string PlotType, 
																				string PlotMap, 
																				string BiomeType, 
																				string MissionType,
																				optional ETimeOfDay TimeOfDay = eTimeOfDay_None,
																				optional bool bOnlyRain = false)
{
	local array<EnvironmentLightingDefinition> arrPlotTypeMatchingEnvLightingDefs;
	local array<EnvironmentLightingDefinition> arrPlotMapMatchingEnvLightingDefs;
	local array<EnvironmentLightingDefinition> arrMissionTypeMatchingEnvLightingDefs;
	local array<EnvironmentLightingDefinition> arrExactMatchingEnvLightingDefs;
	local array<EnvironmentLightingDefinition> arrModifiedForRainEnvLightingDefs;
	local EnvironmentLightingDefinition LightingDef;

	//Get an initial list of possible lighting defs from the plot type
	foreach default.arrEnvironmentLightingDefs(LightingDef)
	{
		if(PlotMap != "" && LightingDef.arrPlotMaps.Find(PlotMap) != INDEX_NONE)
		{
			arrPlotMapMatchingEnvLightingDefs.AddItem(LightingDef);
		}
		
		if( LightingDef.arrPlotTypes.Find(PlotType) != INDEX_NONE )
		{
			arrPlotTypeMatchingEnvLightingDefs.AddItem(LightingDef);
		}

		if (LightingDef.arrMissionTypes.Find(MissionType) != INDEX_NONE)
		{
			arrMissionTypeMatchingEnvLightingDefs.AddItem(LightingDef);
		}
	}

	// if mission specific environments were provided, use those as overrides for the plot type definitions
	// (currently only supporting Psi Gate missions)
	if (arrMissionTypeMatchingEnvLightingDefs.Length > 0)
	{
		arrPlotTypeMatchingEnvLightingDefs = arrMissionTypeMatchingEnvLightingDefs;
	}
	// if plot map specific environments were provided, use those as overrides for the plot type definitions
	else if(arrPlotMapMatchingEnvLightingDefs.Length > 0)
	{
		arrPlotTypeMatchingEnvLightingDefs = arrPlotMapMatchingEnvLightingDefs;
	}

	if(arrPlotTypeMatchingEnvLightingDefs.Length == 0)
	{
		//Fall back on the first lighting def in the list if there are none for this plot type
		arrPlotTypeMatchingEnvLightingDefs.AddItem(default.arrEnvironmentLightingDefs[0]);
	}
		
	//Narrow the selection down further by requiring biome and time of day to be correct
	foreach arrPlotTypeMatchingEnvLightingDefs(LightingDef)
	{
			// Time of day and weather matching
		if ((TimeOfDay == eTimeOfDay_None || LightingDef.eTimeOfDay == TimeOfDay || (bOnlyRain && TimeOfDay != eTimeOfDay_Night && LightingDef.eWeatherCondition == eWeatherType_Rain))
			// Biome matching
			&& (BiomeType == "" || LightingDef.arrBiomeTypes.Length == 0 || LightingDef.arrBiomeTypes.Find(BiomeType) != INDEX_NONE))
		{
			arrExactMatchingEnvLightingDefs.AddItem(LightingDef);
		}
	}

	if(arrExactMatchingEnvLightingDefs.Length > 0)
	{
		// further filtering for precipitation
		if ((bOnlyRain && TimeOfDay != eTimeOfDay_Night)			// Raining and not a night map
			&& (PlotType != "Shanty" && PlotType != "Facility"))	// Plot type requirement
		{
			foreach arrExactMatchingEnvLightingDefs(LightingDef)
			{
				// eWeatherType_Rain is also specified for snow defs
				if (LightingDef.eWeatherCondition == eWeatherType_Rain)
				{
					arrModifiedForRainEnvLightingDefs.AddItem(LightingDef);
					return arrModifiedForRainEnvLightingDefs;
				}
			}
		}

		return arrExactMatchingEnvLightingDefs;
	}
	
	return arrPlotTypeMatchingEnvLightingDefs;	
}

function int GetMapIndexByName(string strMapName)
{
	local int idx;

	for (idx = 0; idx < arrEnvironmentLightingDefs.Length; idx++)
	{
		if(strMapName == arrEnvironmentLightingDefs[idx].MapName)
		{
			return idx;
		}
	}

	return 0;
}

function string GetCurrentMapName()
{
	return currentMapName;
}

function SetCurrentMap(XComGameState_BattleData BattleData, string MapName)
{
	local bool bMapFinishedGenerating;
	
	`MAPS.RemoveStreamingMapByName(currentMapName);
	`XWORLDINFO.ClearAmbientCubemap();
	
	currentMapName = MapName;
	
	// don't bother updating if nothing has been loaded yet
	bMapFinishedGenerating = `PARCELMGR.IsFinishedGeneratingMap();
	if(bMapFinishedGenerating)
	{
		Init(BattleData);
		`XWORLDINFO.MyLightClippingManager.BuildFromScript();
		`XWORLDINFO.MyLocalEnvMapManager.ResetCaptures();
	}
}

function OnFinishedLoading()
{
	local Light LightActor;
	local Emitter EmitterActor;

	local int idx;
	local int EnvClass;

	local EEnvLightingSetting TimeSetting;
	local EWeatherType WeatherSetting;


	for( idx=0; idx<arrEnvironmentLightingDefs[currentMapIdx].eEnvLighting.Length; idx++ )
	{
		TimeSetting = arrEnvironmentLightingDefs[currentMapIdx].eEnvLighting[idx];
		WeatherSetting = arrEnvironmentLightingDefs[currentMapIdx].eWeatherCondition;

		switch( TimeSetting )
		{
		case eEnvLighting_Day:
			EnvClass = 0;
			break;
		case eEnvLighting_Night:
			EnvClass = 3;
			break;
		}

		switch( WeatherSetting )
		{
		case eWeatherType_Rain:
			EnvClass += 1;
			break;
		case eWeatherType_Snow:
			EnvClass += 2;
			break;
		case eWeatherType_Clear:
			break;
		}

	}

	foreach `XWORLDINFO.AllActors(class'Light', LightActor )
	{
		LightActor.SetEnvLightingPreview(EEnvClassification(EnvClass));
	}

	foreach `XWORLDINFO.AllActors(class'Emitter', EmitterActor )
	{
		EmitterActor.SetEnvLightingPreview(EEnvClassification(EnvClass));
	}
}

function Reset(XComGameState_BattleData BattleData)
{
	`MAPS.RemoveStreamingMapByName(currentMapName);
	`XWORLDINFO.ClearAmbientCubemap();
	Init(BattleData);
	`XWORLDINFO.MyLocalEnvMapManager.ResetCaptures();
}

defaultproperties
{
	ForceNoLoad=false;
	bBlockingLoadParcels=true
}