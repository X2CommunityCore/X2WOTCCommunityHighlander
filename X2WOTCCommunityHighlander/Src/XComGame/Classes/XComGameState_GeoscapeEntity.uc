//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_GeoscapeEntity.uc
//  AUTHOR:  Dan Kaplan  --  10/21/2014
//  PURPOSE: This object represents the base instance data for all entities which exist 
//           on the X-Com 2 strategy game map.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_GeoscapeEntity extends XComGameState_BaseObject 
	native(Core)
	abstract
	dependson(XComGameStateContext_HeadquartersOrder,UIDialogueBox)
	config(GameBoard);

// Map vars
var() Vector                  Location;
var() Rotator				  Rotation;
var() StateObjectReference    Region;
var() StateObjectReference	  Continent;
var() bool					  bNeedsLocationUpdate;

var() config TRect			  TooltipBounds;

var transient name VisualizerClassName;

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

// Called after location is updated due to map generation
function HandleUpdateLocation()
{
}

//#############################################################################################
//----------------   LOCATION HANDLING   ------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function Vector GetLocation()
{
	return Location;
}

//---------------------------------------------------------------------------------------
// Used for the mission pin on the world map
function Vector2D Get2DLocation()
{
	local Vector2D v2Loc;

	v2Loc.x = Location.x;
	v2Loc.y = Location.y;

	return v2Loc;
}

//---------------------------------------------------------------------------------------
// Used for the display of the mission pin or 3D mesh on the world map
function Rotator GetRotation()
{
	return Rotation;
}

//---------------------------------------------------------------------------------------
// Get the region state object in which this Entity resides
function XComGameState_WorldRegion GetWorldRegion()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(Region.ObjectID));
}

//---------------------------------------------------------------------------------------
// Get the continent state object in which this Entity resides
function XComGameState_Continent GetContinent()
{
	return XComGameState_Continent(`XCOMHISTORY.GetGameStateForObjectID(Continent.ObjectID));
}

function bool ResistanceActive()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	return (!ResistanceHQ.bInactive);
}

//---------------------------------------------------------------------------------------

// Whether or not this entity requires the Avenger to perform the investigation in order to be activated.
function bool RequiresAvenger()
{
	return false;
}

// Whether or not this entity requires a Squad to be present on board the Skyranger in order to be activated.
function bool RequiresSquad()
{
	return false;
}

// Can the Avenger scan at this entity
function bool CanBeScanned()
{
	return false;
}

// Does this entity's map item create a tooltip which needs to be bounds checked
function bool HasTooltipBounds()
{
	return false;
}

// Handle squad selection for this entity
function SelectSquad();

//---------------------------------------------------------------------------------------

// Handle GameState changes that occur when some polled condition is achieved (usually elapsed timer).
function UpdateGameBoard();

// Handle updating movement of the entity over time
function UpdateMovement(float fDeltaT);

// Handle updating rotation of the entity over time
function UpdateRotation(float fDeltaT);

// Handle GameState changes that occur when this entity is reached by the Skyranger/Avenger.  
function DestinationReached();

// Returns true iff this Entity can currently be interacted with to select a pending destination for an Airship
protected function bool CanInteract()
{
	return true;
}

// Returns true if the Skyranger is considered "busy" (ex. waiting on a POI to complete) with this entity.
protected function bool CurrentlyInteracting()
{
	return false;
}

// Returns the display string asking the user if they want to interrupt the current activity that is being performed.
// Must be defined for any entity for whom CurrentlyInteracting can ever return true.
protected function string GetInterruptionPopupQueryText()
{
	// should never hit this without it being implemented by the appropriate Entity subclass
	`assert(false);

	return "";
}

protected function OnInterruptionPopup()
{
	// Can be subclassed for event triggers or other logic
}

// Hook to allow subclasses an opportunity to respond to their interaction being interrupted by the user choosing to 
// move the Avenger/Skyranger to a new location.
protected function HandleInterruption();

static function XComGameState_GeoscapeEntity GetCurrentEntityInteraction()
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity EntityState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', EntityState)
	{
		if( EntityState.CurrentlyInteracting() )
		{
			return EntityState;
		}
	}

	return None;
}

// On attempted selection, if the Skyranger is considered "busy" (ex. waiting on a POI to complete), display a popup 
// to allow user to choose whether to change activities to the new selection.
final function bool DisplayInterruptionPopup()
{
	local XComGameState_GeoscapeEntity EntityState;
	local TDialogueBoxData DialogData;

	EntityState = GetCurrentEntityInteraction();

	if( EntityState != None && EntityState.ObjectID != self.ObjectID)
	{
		// display the popup
		BeginInteraction(); // pauses the Geoscape

		EntityState.OnInterruptionPopup();

		DialogData.strText = EntityState.GetInterruptionPopupQueryText();
		DialogData.eType = eDialog_Normal;
		DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
		DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
		DialogData.fnCallback = InterruptionPopupCallback;
		`HQPRES.UIRaiseDialog( DialogData );

		return true;
	}

	return false;
}

simulated public function InterruptionPopupCallback(Name eAction)
{
	local XComGameState_GeoscapeEntity EntityState;

	if (eAction == 'eUIAction_Accept')
	{
		// Give the entity being interrupted an opportunity to cleanup state
		EntityState = GetCurrentEntityInteraction();
		`assert(EntityState != none);
		EntityState.HandleInterruption();

		// Attempt to select this entity again, now that the previous interaction has been canceled.
		InteractionComplete(true);
		AttemptSelection();
	}
	else if(eAction == 'eUIAction_Cancel')
	{
		InteractionComplete(false);
	}
}



// On attempted selection, if an additional prompt is required before action, displays that prompt and returns true; 
// otherwise returns false.
protected function bool DisplaySelectionPrompt()
{
	return false;
}

// Attempt to select this Entity as the next Point Of Travel for the Avenger/Skyranger - but first check to see 
// if there is some other interaction that would be interrupted by doing so.
function AttemptSelectionCheckInterruption()
{
	if( CanInteract() && !DisplayInterruptionPopup() )
	{
		AttemptSelection();
	}
}

// Attempt to select this Entity as the next Point Of Travel for the Avenger/Skyranger - but first display any upfront 
// selection prompts.
final function AttemptSelection()
{
	if( CanInteract() && !DisplaySelectionPrompt() )
	{
		ConfirmSelection();
	}
}

// Set this Entity as the next Point Of Travel for the Avenger/Skyranger.
function ConfirmSelection()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_GeoscapeEntity ThisEntity;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// handle selection, updating pending destination
	ThisEntity = self;
	XComHQ.SetPendingPointOfTravel(ThisEntity);
}


function BeginInteraction()
{
	local XGGeoscape Geoscape;
	local UIStrategyMap UIMap;

	Geoscape = `GAME.GetGeoscape();
	UIMap = `HQPRES.StrategyMap2D;

	Geoscape.Pause();
	UIMap.Hide();
}

function InteractionComplete(bool RTB)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGGeoscape Geoscape;
	local UIStrategyMap UIMap;

	Geoscape = `GAME.GetGeoscape();
	UIMap = `HQPRES.StrategyMap2D;

	Geoscape.Resume();
	if( Geoscape.IsScanning() )
	{
		UIMap.ToggleScan();
	}
	UIMap.Show();

	if( RTB )
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		// Start Issue #927
		/// HL-Docs: ref:Bugfixes; issue:927
		/// When cancelling out of squad select or mission launch, the selected map
		/// item will now return back to the mission rather than the Avenger (affects
		/// controller users).
		//
		// The CHL change here is to pass the RTB value through, thus ensuring it's
		// taken into account when deciding whether to overwrite LastSelectedMapItem.
		XComHQ.SetPendingPointOfTravel(XComHQ,, RTB);
		// End Issue #927
	}
}

// "destructor" 
function RemoveEntity(XComGameState NewGameState)
{
	`assert(false);
}

//---------------------------------------------------------------------------------------
// UI display information
//---------------------------------------------------------------------------------------

function RemoveMapPin(XComGameState NewGameState)
{
	local UIStrategyMapItem MapItem; 
	local XComGameState_GeoscapeEntity ThisEntity;

	// display faded out popup hint of what is being acquired
	ThisEntity = self;
	MapItem = `HQPRES.StrategyMap2D.GetMapItem(ThisEntity, NewGameState);

	// set the mission pin UI item to be cleaned up in the near future
	//MapItem.FadeOut();
	Remove3DUI();
	MapItem.Remove();

}

function Remove3DUI()
{
	local UIStrategyMapItem3D kItem;

	foreach `XWORLDINFO.AllActors(class'UIStrategyMapItem3D', kItem)
	{
		if(kItem.GeoscapeEntityRef == self.GetReference())
		{
			kItem.Destroy();
		}
	}
}

function bool ShouldBeVisible()
{
	return true;
}

function bool ShowFadedPin()
{
	return false;
}

// UI Map Pin construction data

// The name of the widget
final function string GetUIWidgetName()
{
	return "GeoscapeEntity_" $ ObjectID;
}

event name GetUIClassName()
{
	local class<UIStrategyMapItem> UIMapItemClass;
	UIMapItemClass = GetUIClass();
	if (UIMapItemClass != none)
	{
		VisualizerClassName = UIMapItemClass.Name;
	}
	else
	{
		VisualizerClassName = 'NoVisualizerClass';
	}
	return VisualizerClassName;
}

// The Unreal Script class of the widget
function class<UIStrategyMapItem> GetUIClass();

// The Unreal Script class of an animated 3D map item
function class<UIStrategyMapItemAnim3D> GetMapItemAnim3DClass()
{
	return class'UIStrategyMapItemAnim3D';
}

// The flash library class of control that should be created
function string GetUIWidgetFlashLibraryName()
{
	return "";
}

// The Pin Image that should be displayed for this Entity's UI Widget
function string GetUIPinImagePath()
{
	return "";
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	return none;
}

// The skeletal mesh for this entity's 3D UI
function SkeletalMesh GetSkeletalMesh()
{
	return none;
}

function AnimSet GetAnimSet()
{
	return none;
}

function AnimTree GetAnimTree()
{
	return none;
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
	MeshRotation.Yaw = 0;

	return MeshRotation;
}

function bool AboutToExpire()
{
	return false;
}

function Vector2D GetClosestWrappedCoordinate(Vector2D v2Start, Vector2D v2End)
{
	local Vector2D v2LeftWrap, v2RightWrap;
	local float OrigDist, LeftDist, RightDist;

	// Get the wrapped coords
	v2LeftWrap = v2End;
	v2LeftWrap.X -= 1.0;
	v2RightWrap = v2End;
	v2RightWrap.X += 1.0;

	// Get distances
	OrigDist = V2DSize(v2End - v2Start);
	LeftDist = V2DSize(v2LeftWrap - v2Start);
	RightDist = V2DSize(v2RightWrap - v2Start);

	if(OrigDist <= LeftDist && OrigDist <= RightDist)
	{
		return v2End;
	}
	else if(LeftDist <= RightDist)
	{
		return v2LeftWrap;
	}
	else
	{
		return v2RightWrap;
	}
}

//---------------------------------------------------------------------------------------

static function TDateTime GetCurrentTime()
{
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;
	local TDateTime CurrentTime;

	History = `XCOMHISTORY;
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	CurrentTime = TimeState.CurrentTime;

	if(`STRATEGYRULES != none)
	{
		if(class'X2StrategyGameRulesetDataStructures'.static.LessThan(TimeState.CurrentTime, `STRATEGYRULES.GameTime))
		{
			CurrentTime = `STRATEGYRULES.GameTime;
		}
	}

	return CurrentTime;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}