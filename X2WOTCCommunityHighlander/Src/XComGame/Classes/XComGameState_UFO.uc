//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_UFO.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for a UFO
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_UFO extends XComGameState_Airship native(Core);

var() TDateTime						SpawnTime; // The time this UFO appeared on the map
var() TDateTime						InterceptionTime; // The time this UFO will begin its attack on the Avenger
var() TDateTime						NextVisibilityTime; // The next time this UFO will become visible
var() bool							bChasingAvenger; // If the UFO is currently chasing XCOM
var() bool							bDoesInterceptionSucceed; // The UFO chasing XCOM will result in an Avenger Defense mission
var() bool							bIsVisible; // Is the UFO currently shown on the map
var() bool							bNeedsUFOInboundPopup;
var() bool							bChaseActivated;
var() bool							bGoldenPath; // Spawned by Golden Path mission

var() config int					MinDisplaySpeed; // Min speed used for UFO Inbound popup
var() config int					MaxDisplaySpeed; // Max speed used for UFO Inbound popup

var() config int					MinInvisibleHours; // Min hours the UFO will remain visible at a time
var() config int					MaxInvisibleHours; // Maximum hours the UFO will remain visible at a time
var() config int					MinVisibleHours; // Min hours the UFO will remain visible at a time
var() config int					MaxVisibleHours; // Maximum hours the UFO will remain visible at a time

var() config float					MaxHuntingDistance; // Maximum radial distance the UFO will hunt the Avenger from (0.0-1.0)

var() config int					MinNonInterceptDays; // For a non-intercepting UFO, the minimum days after which it will attack the player
var() config int					MaxNonInterceptDays; // For a non-intercepting UFO, the maximum days before which it will attack the player
var() config int					MaxInterceptMissionsToWait; // For an intercepting UFO, the maximum number of missions to pass before attacking

var() config int					DefaultInterceptionChance; // Default chance this UFO will intercept the Avenger
var() config int					DefaultInterceptionChanceGoldenPath; // Default interception chance if this UFO was spawned from a Golden Path mission
var() config array<int>				AfterFirstInterceptionChance; // Interception chance after initial interception based on difficulty

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function PostCreateInit(XComGameState NewGameState, bool bGoldenPathSpawn)
{
	SetInterceptionChance(NewGameState, bGoldenPathSpawn);
	SetLocationHuntXCom();
	SetVisible();
	
	`XEVENTMGR.TriggerEvent('UFOSpawned', , , NewGameState);
}

//---------------------------------------------------------------------------------------
// Set whether or not this UFO will succeed in its interception attempt
function SetInterceptionChance(XComGameState NewGameState, bool bGoldenPathSpawn)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int IntChance;
	
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	bGoldenPath = bGoldenPathSpawn;

	if (!AlienHQ.bHasPlayerBeenIntercepted)
	{
		IntChance = bGoldenPathSpawn ? DefaultInterceptionChanceGoldenPath : DefaultInterceptionChance;
	}
	else
	{
		IntChance = `ScaleStrategyArrayInt(AfterFirstInterceptionChance);
	}

	bDoesInterceptionSucceed = class'X2StrategyGameRulesetDataStructures'.static.Roll(IntChance);

	// If the UFO intercepts the player, flag Alien HQ so any subsequent UFO spawns will use the correct percentages
	if (bDoesInterceptionSucceed)
	{
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		AlienHQ.bHasPlayerBeenIntercepted = true;
	}
	else if (!AlienHQ.bHasPlayerAvoidedUFO) // If the player avoids interception, let AlienHQ know. Used for spawning Landed UFO supply raids.
	{
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		AlienHQ.bHasPlayerAvoidedUFO = true;
	}
	
	SetInterceptionTime();
}

//---------------------------------------------------------------------------------------
// Sets the time when this UFO will attempt to intercept the Avenger
function SetInterceptionTime()
{
	local XComGameState_MissionCalendar CalendarState;
	local int HoursUntilIntercept;

	SpawnTime = GetCurrentTime();

	if (bDoesInterceptionSucceed)
	{
		CalendarState = XComGameState_MissionCalendar(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
		InterceptionTime = CalendarState.GetBestNewMissionDateBetweenMissions(MaxInterceptMissionsToWait);
	}
	else
	{
		HoursUntilIntercept = (MinNonInterceptDays * 24) + `SYNC_RAND((MaxNonInterceptDays * 24) - (MinNonInterceptDays * 24) + 1);
		InterceptionTime = GetCurrentTime();
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(InterceptionTime, HoursUntilIntercept);
	}
}

//---------------------------------------------------------------------------------------
function SetLocationToRandomRegionInXComContinent()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Continent ContinentState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	ContinentState = XComHQ.GetContinent();
	if (ContinentState == none)
	{
		ContinentState = class'UIUtilities_Strategy'.static.GetRandomContinent();
	}
	
	Continent = ContinentState.GetReference();
	Region = ContinentState.Regions[`SYNC_RAND(ContinentState.Regions.Length)];
	Location = ContinentState.GetRandomLocationInContinent();
	Location.Z = FlightHeight; // Set default UFO height as flying
}

function SetLocationToRandomPointInXComRegion()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	RegionState = XComHQ.GetWorldRegion();
	if (RegionState == None)
	{
		SetLocationToRandomRegionInXComContinent();
	}
	else
	{
		Continent = RegionState.GetContinent().GetReference();
		Region = RegionState.GetReference();
		Location = RegionState.GetRandomLocationInRegion(true);
		Location.Z = FlightHeight;
	}
}

function float GetCurrentHuntDistance()
{
	local float PercentTimeLeftToIntercept, HuntDistance;
	local int HoursLeftUntilIntercept, TotalLifetime;

	HoursLeftUntilIntercept = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(InterceptionTime, GetCurrentTime());
	TotalLifetime = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(InterceptionTime, SpawnTime);

	PercentTimeLeftToIntercept = (1.0 * HoursLeftUntilIntercept) / TotalLifetime;
	HuntDistance = MaxHuntingDistance * PercentTimeLeftToIntercept;

	return HuntDistance;
}

function SetLocationHuntXCom()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;
	local Vector2D HuntLocation;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		
	// Set the new hunt location as somewhere near XCom within the hunt radius
	RegionState = XComHQ.GetWorldRegion();
	if (RegionState == None)
	{
		SetLocationToRandomRegionInXComContinent();
	}
	else
	{
		Continent = RegionState.GetContinent().GetReference();
		Region = RegionState.GetReference();
	}

	HuntLocation = class'X2StrategyGameRulesetDataStructures'.static.AdjustLocationByRadius(XComHQ.Get2DLocation(), GetCurrentHuntDistance());
	Location.X = HuntLocation.X;
	Location.Y = HuntLocation.Y;
	Location.Z = FlightHeight;
}

//#############################################################################################
//----------------   SHOW/HIDE   --------------------------------------------------------------
//#############################################################################################

function SetVisible()
{
	local int VisibleHours;

	// Set as visible, and calculate when next to become invisible
	NextVisibilityTime = GetCurrentTime();
	VisibleHours = default.MinVisibleHours + `SYNC_RAND(default.MaxVisibleHours - default.MinVisibleHours + 1);
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(NextVisibilityTime, VisibleHours);	

	// If the UFO will not turn invisible before its scheduled interception time, do not become visible now
	// since it will automatically appear when it intercepts
	if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(NextVisibilityTime, InterceptionTime))
	{
		bIsVisible = true;
	}	
}

function SetInvisible()
{
	local int InvisibleHours;

	// Set as invisible, and calculate when next to become visible
	NextVisibilityTime = GetCurrentTime();
	InvisibleHours = default.MinInvisibleHours + `SYNC_RAND(default.MaxInvisibleHours - default.MinInvisibleHours + 1);
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(NextVisibilityTime, InvisibleHours);
	bIsVisible = false;
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_UFO_Stop_All");
}

//#############################################################################################
//----------------   INTERCEPTION INFO  -------------------------------------------------------
//#############################################################################################

function int GetDistanceToAvenger()
{
	local XComGameState_HeadquartersXCom XComHQ;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	return `EARTH.ConvertEarthCoordsToMiles(VSize2D(GetLocation() - XComHQ.GetLocation()));
}

function int GetInterceptionSpeed()
{
	return (default.MinDisplaySpeed + `SYNC_RAND(default.MaxDisplaySpeed - default.MinDisplaySpeed + 1));
}

function string GetTimeToIntercept()
{	
	local int Miles, MPH, Hours, Minutes, Seconds;

	Miles = GetDistanceToAvenger();
	MPH = GetInterceptionSpeed();
	
	Hours = Miles / MPH;
	Minutes = (Miles * 60 / MPH) - (Hours * 60);
	Seconds = (Miles * 3600 / MPH) - (Hours * 3600) - (Minutes * 60);	
		
	return (FormatIntValueString(Hours) $ ":" $ FormatIntValueString(Minutes) $ ":" $ FormatIntValueString(Seconds));
}

private function string FormatIntValueString(int Value)
{
	if (Value < 10)
	{
		return ("0" $ Value);
	}

	return ("" $ Value);
}

//#############################################################################################
//----------------   FLIGHT STATES   ----------------------------------------------------------
//#############################################################################################

function FlyTo(XComGameState_GeoscapeEntity InTargetEntity, optional bool bInstantCamInterp = false)
{
	local XComGameState NewGameState;
	local XComGameState_UFO NewUFOState;
	local Vector2D Destination;
	local Vector2D RadialAdjustedTarget;

	`assert(InTargetEntity.ObjectID > 0);

	// set new target location - course change!
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Destination Change");
	NewUFOState = XComGameState_UFO(NewGameState.ModifyStateObject(Class, ObjectID));
	
	Destination = InTargetEntity.Get2DLocation();
	if (!NewUFOState.bChasingAvenger)
	{
		RadialAdjustedTarget = class'X2StrategyGameRulesetDataStructures'.static.AdjustLocationByRadius(Destination, GetCurrentHuntDistance());
	}
	else
	{
		RadialAdjustedTarget = Destination;
	}	
	
	NewUFOState.TargetEntity.ObjectID = InTargetEntity.ObjectID;
	NewUFOState.SourceLocation = Get2DLocation();
	NewUFOState.FlightDirection = GetFlightDirection(NewUFOState.SourceLocation, GetClosestWrappedCoordinate(NewUFOState.SourceLocation, RadialAdjustedTarget));
	NewUFOState.TotalFlightDistance = GetDistance(NewUFOState.SourceLocation, GetClosestWrappedCoordinate(NewUFOState.SourceLocation, RadialAdjustedTarget));

	if (!NewUFOState.bChasingAvenger)
		NewUFOState.Velocity = vect(0.0, 0.0, 0.0);

	NewUFOState.CurrentlyInFlight = true;
	NewUFOState.Flying = true;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//#############################################################################################
//----------------   MOVEMENET & ROTATION   ---------------------------------------------------
//#############################################################################################

function UpdateMovement(float fDeltaT)
{
	if (CurrentlyInFlight && TargetEntity.ObjectID > 0)
	{
		fDeltaT *= (`GAME.GetGeoscape().m_fTimeScale / `GAME.GetGeoscape().ONE_HOUR);
		
		if (`GAME.GetGeoscape().IsScanning())
		{
			fDeltaT /= 6.0;
			if (bIsVisible)
			{
				`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_UFO_Fly_Start");
			}
		}
		else if (bIsVisible)
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_UFO_Hover_Loop");
		}

		if (LiftingOff)
		{
			UpdateMovementLiftOff(fDeltaT);
		}
		else if (Flying)
		{
			UpdateMovementFly(fDeltaT);
		}
		else
		{
			ProcessFlightComplete();
		}
	}
	else // If the UFO is not flying, pick a random point from the current region within hunt radius and fly there
	{
		FlyTo(GetWorldRegion());
	}
}

function TransitionFlightToLand()
{
	// This function exists so the geoscape scanning time isn't altered
	Flying = false;
	Landing = true; // start landing
}

function UpdateMovementFly(float fDeltaT)
{
	local Vector2D Destination;

	if (bChasingAvenger) // If chasing the avenger, update the target as XComHQ each tick
	{
		Destination = class'UIUtilities_Strategy'.static.GetXComHQ().Get2DLocation();
		SourceLocation = Get2DLocation();
		FlightDirection = GetFlightDirection(SourceLocation, Destination);
		TotalFlightDistance = GetDistance(SourceLocation, Destination);
	}

	super.UpdateMovementFly(fDeltaT);
}

function UpdateRotation(float fDeltaT)
{
	if (CurrentlyInFlight && TargetEntity.ObjectID > 0)
	{
		fDeltaT *= (`GAME.GetGeoscape().m_fTimeScale / `GAME.GetGeoscape().ONE_HOUR);
		
		if (Flying)
		{
			UpdateRotationFly(fDeltaT);
		}
	}
}

//#############################################################################################
//---------------------------   MISSIONS  -----------------------------------------------------
//#############################################################################################

function XComGameState_MissionSiteAvengerDefense CreateAvengerDefenseMission(StateObjectReference RegionRef)
{
	local XComGameState NewGameState;
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_MissionSiteAvengerDefense MissionState;
	local XComGameState_Reward RewardState;
	local array<XComGameState_Reward> MissionRewards;
	local XComGameState_WorldRegion RegionState;
	
	RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// Create Mission
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Create Avenger Defense Mission"); 
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	MissionRewards.AddItem(RewardState);

	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_AvengerDefense'));
	MissionState = XComGameState_MissionSiteAvengerDefense(NewGameState.CreateNewStateObject(class'XComGameState_MissionSiteAvengerDefense'));

	MissionState.BuildMission(MissionSource, RegionState.Get2DLocation(), RegionState.GetReference(), MissionRewards, true, false);
	MissionState.AttackingUFO = GetReference();
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	return MissionState;
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool Update(XComGameState NewGameState)
{
	local UIStrategyMap StrategyMap;
	local bool bModified;

	bModified = false;
	
	// If we are not intercepting and our visibility time is hit, toggle visibility state
	if (!bChasingAvenger && !bChaseActivated)
	{
		if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(NextVisibilityTime, GetCurrentTime()))
		{
			if (bIsVisible)
			{
				SetInvisible();
			}
			else
			{
				SetLocationHuntXCom();
				SetVisible();
			}

			bModified = true;
		}

		// Do not trigger interception while the Avenger or Skyranger are flying, or if another popup is already being presented
		StrategyMap = `HQPRES.StrategyMap2D;
		if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
		{
			// If we have hit our interception time, become visible, transport to be close to XComHQ, and start the attack
			if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(InterceptionTime, GetCurrentTime()))
			{
				SetLocationToRandomPointInXComRegion();
				bIsVisible = true;
				bNeedsUFOInboundPopup = true;
				bChasingAvenger = true;
				bChaseActivated = true;
				bModified = true;
				`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_UFO_Fly_Start");
			}
		}
	}

	return bModified;
}

//#############################################################################################
//----------------   GEOSCAPE ENTITY IMPLEMENTATION   -----------------------------------------
//#############################################################################################

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_UFO';
}

function string GetUIWidgetFlashLibraryName()
{
	return string(class'UIPanel'.default.LibID);
}

function string GetUIPinImagePath()
{
	return "";
}

function string GetUIPinLabel()
{
	return "";
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	return StaticMesh'UI_3D.Overworld.UFO_Icon';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 1.0;
	ScaleVector.Y = 1.0;
	ScaleVector.Z = 1.0;

	return ScaleVector;
}

// Rotation adjustment for the 3D UI static mesh
function Rotator GetMeshRotator()
{
	local Rotator MeshRotation;

	MeshRotation.Roll = 0;
	MeshRotation.Pitch = 0;
	MeshRotation.Yaw = 180 * DegToUnrRot; //Rotate by 180 degrees so the ship is facing the correct way when flying

	return MeshRotation;
}

protected function bool CanInteract()
{
	return false;
}

function bool ShouldBeVisible()
{
	return bIsVisible;
}

function UpdateGameBoard()
{	
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_UFO NewUFOState;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update UFO");

	NewUFOState = XComGameState_UFO(NewGameState.ModifyStateObject(class'XComGameState_UFO', ObjectID));

	if (!NewUFOState.Update(NewGameState))
	{
		NewGameState.PurgeGameStateForObjectID(NewUFOState.ObjectID);
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	if (bNeedsUFOInboundPopup)
	{
		UFOInboundPopup();
	}	
}

//---------------------------------------------------------------------------------------
simulated public function UFOInboundPopup()
{
	local XComGameState NewGameState;
	local XComGameState_UFO UFOState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle UFO Inbound Popup");
	UFOState = XComGameState_UFO(NewGameState.ModifyStateObject(class'XComGameState_UFO', self.ObjectID));
	UFOState.bNeedsUFOInboundPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`HQPRES.UIUFOInboundAlert(GetReference());

	`GAME.GetGeoscape().Pause();
}

//---------------------------------------------------------------------------------------
function RemoveEntity(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_DarkEvent DarkEventState;
	local bool SubmitLocally, bFound;

	if (NewGameState == None)
	{
		SubmitLocally = true;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Removed");
	}
	
	if(!bGoldenPath)
	{
		bFound = false;
		foreach NewGameState.IterateByClassType(class'XComGameState_DarkEvent', DarkEventState)
		{
			if(DarkEventState.GetMyTemplateName() == 'DarkEvent_HunterClass')
			{
				bFound = true;
				break;
			}
		}

		if(!bFound)
		{
			History = `XCOMHISTORY;

			foreach History.IterateByClassType(class'XComGameState_DarkEvent', DarkEventState)
			{
				if(DarkEventState.GetMyTemplateName() == 'DarkEvent_HunterClass')
				{
					bFound = true;
					DarkEventState = XComGameState_DarkEvent(NewGameState.ModifyStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
					break;
				}
			}
		}

		if(bFound)
		{
			DarkEventState.DeactivateObjectiveUI(NewGameState);
		}
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_UFO_Stop_All");
		
	// remove from the history
	NewGameState.RemoveStateObject(ObjectID);
	
	if (`HQPRES != none && `HQPRES.StrategyMap2D != none)
	{
		RemoveMapPin(NewGameState);
	}

	if (SubmitLocally)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}


//---------------------------------------------------------------------------------------
DefaultProperties
{
}