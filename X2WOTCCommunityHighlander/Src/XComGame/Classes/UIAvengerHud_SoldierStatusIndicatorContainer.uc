//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIAvengerHUD_SoldierStatusIndicatorContainer.uc
//  AUTHORS: Brit Steiner
//
//  PURPOSE: Container for avenger hud floating indicator arrows, used to point at 3D space or at 2D elements. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIAvengerHUD_SoldierStatusIndicatorContainer extends UIPanel;

struct TUIStatusIndicator
{
	var XComUnitPawn kPawn;
	var UIPanel Icon;
	structdefaultproperties
	{
	}
};

var array<TUIStatusIndicator> FloatingIcons;

//=====================================================================
// 		GENERAL FUNCTIONS:
//=====================================================================

simulated function OnInit()
{
	super.OnInit();
	Movie.Pres.SubscribeToUIUpdate(Update);
	UpdateData();
}

simulated function UpdateData()
{
	local int i;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit, BondUnit;
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;
	local XComGameState_HeadquartersXCom HQState;
	local array<int> UsedSoldierIDs;
	//start issue #85: variables required to check the trait template of what we've been given
	local X2EventListenerTemplateManager EventTemplateManager;
	local X2TraitTemplate TraitTemplate;
	//end issue #85
	
	//Destroy old data
	ClearIndicators();
	UsedSoldierIDs.Length = 0;
	
	//Need to get the latest state here, else you may have old data in the list upon refreshing at OnReceiveFocus, such as 
	//still showing dismissed soldiers. 
	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	History = `XCOMHISTORY;
	for( i = 0; i < HQState.Crew.Length; i++ )
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(HQState.Crew[i].ObjectID));

		if (Unit.HasSoldierBondAvailable(BondmateRef, BondData) && UsedSoldierIDs.Find(Unit.ObjectID) == INDEX_NONE)
		{
			// First check to see if the unit has any available bondmates
			if (IsUnitAvailableForBond(Unit, BondData.BondLevel))
			{
				// Make sure the bond unit is alive and not captured and, if this is for bond level > 1, are available for staffing
				BondUnit = XComGameState_Unit(History.GetGameStateForObjectID(BondmateRef.ObjectID));
				if (IsUnitAvailableForBond(BondUnit, BondData.BondLevel))
				{
					// Then make sure that neither of the units is currently training for a bond
					if (!HQState.HasBondSoldiersProjectForUnit(Unit.GetReference()) && !HQState.HasBondSoldiersProjectForUnit(BondmateRef))
					{
						AddStatusIndicator(Unit, CreateBondIcon(Unit));
						UsedSoldierIDs.AddItem(Unit.ObjectID);
					}
				}
			}
			else if(Unit.AlertTraits.Length > 0)
			{
			//start issue #85: init variables here to check for trait template
			EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();
			TraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(Unit.AlertTraits[0]));
			//while it's an array, we go with the base game's assumption of having only one trait to worry about when it changes				
				
			if(!TraitTemplate.bPositiveTrait)
				AddStatusIndicator(Unit, CreateTraitIcon(Unit, false));
				
			if(TraitTemplate.bPositiveTrait)
				AddStatusIndicator(Unit, CreateTraitIcon(Unit, true));
			//end issue #85
			}
				//removed extraneous check for positive traits since we handle it up above
		}
	}
}

simulated function bool IsUnitAvailableForBond(XComGameState_Unit Unit, int BondLevel)
{
	return (Unit.IsAlive() && Unit.IsSoldier() && !Unit.bCaptured && (BondLevel == 0 || Unit.IsActive()));
}

// Adds a new arrow pointing at an XComUnitPawn, or updates it if it already exists
simulated function AddStatusIndicator(XComGameState_Unit Unit, UIPanel Icon)
{
	local TUIStatusIndicator StatusIndicator;
	local XComUnitPawn kPawn;

	kPawn = `GAME.GetGeoscape().m_kBase.m_kCrewMgr.GetPawnForUnit(Unit.GetReference());
	if( kPawn == none )
	{
		`log( "Failing to add a UI bond indicator to track a unit, because the XComUnitPawn reference is none.");
		Icon.Remove();
		return;
	}
	StatusIndicator.kPawn = kPawn;
	StatusIndicator.Icon = Icon; 

	FloatingIcons.AddItem(StatusIndicator);
}

simulated function RemoveStatusIndicator(TUIStatusIndicator StatusIndicator)
{
	StatusIndicator.Icon.Remove();
	FloatingIcons.RemoveItem(StatusIndicator);
}

simulated function ClearIndicators()
{
	local int i; 

	//Walk backwards because we are manipulating contents of the array. 
	for( i = FloatingIcons.length-1; i > -1; i--)
	{
		RemoveStatusIndicator(FloatingIcons[i]);
	}
}
simulated function Show()
{
	super.Show();
	UpdateData();
}

simulated function RemoveStatusIndicatorByUnit(XComGameState_Unit Unit)
{
	local int index;
	local XComUnitPawn kPawn;

	kPawn = `GAME.GetGeoscape().m_kBase.m_kCrewMgr.GetPawnForUnit(Unit.GetReference());

	if( kPawn == none )
	{
		`log( "Failing to remove a bond indicator to track an XComUnitPawn, because the XComUnitPawn reference is none.");
		return;
	}

	index = FloatingIcons.Find('kPawn', kPawn);

	if( index != -1 )
	{
		FloatingIcons[index].Icon.Remove();
		FloatingIcons.Remove(index, 1);
	}
	else
	{
		`log( "Attempting to delete a bond indicator that is not found in the floating icons array. id: " $ string(kPawn.Name));
	}
}

simulated function Update()
{
	UpdateTargetedArrows();
}

simulated function UpdateTargetedArrows()
{
	local TUIStatusIndicator StatusIndicator;
	local vector        targetLocation;
	local vector2D      v2ScreenCoords;

	// Leave if Flash side isn't up.
	if( !bIsInited )
		return;

	if( !IsVisible() )
		return;

	//return if no update is needed
	if( FloatingIcons.length == 0 )
	{
		return;
	}

	foreach FloatingIcons(StatusIndicator)
	{
		targetLocation = StatusIndicator.kPawn.GetHeadLocation();

		if (StatusIndicator.kPawn == none)
			RemoveStatusIndicator(StatusIndicator); 

		if( class'UIUtilities'.static.IsOnscreen((targetLocation), v2ScreenCoords) )
		{
			v2ScreenCoords = Movie.ConvertNormalizedScreenCoordsToUICoords(v2ScreenCoords.X, v2ScreenCoords.Y, true, 0);

			StatusIndicator.Icon.SetPosition(v2ScreenCoords.x - StatusIndicator.Icon.width / 2, v2ScreenCoords.y - StatusIndicator.Icon.height - 10);
			StatusIndicator.Icon.Show();
		}
		else
		{
			StatusIndicator.Icon.Hide();
		}
	}
}

event Destroyed()
{
	Movie.Pres.UnsubscribeToUIUpdate(Update);
	super.Destroyed();
}

function UIBondIcon CreateBondIcon(XComGameState_Unit Unit)
{
	local UIBondIcon BondIcon;
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;

	Unit.HasSoldierBondAvailable(BondmateRef, BondData);

	BondIcon = Spawn(class'UIBondIcon', self);
	BondIcon.InitBondIcon(Name(BondIcon.Name $"_"$string(Unit.GetReference().ObjectID)), BondData.BondLevel, OnClickBondIcon, BondData.Bondmate);
	BondIcon.SetSize(class'UIBondIcon'.default.width, class'UIBondIcon'.default.height);
	if(BondData.BondLevel < 1 )
		BondIcon.AnimateCohesion(true);
	else
		BondIcon.AnimateBond(true);

	return BondIcon;
}

function OnClickBondIcon(UIBondIcon Icon)
{
	local int UntiID; 
	local XComGameState_Unit Unit;
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;
	
	UntiID = int(GetRightMost(string(Icon.MCName)));
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UntiID));

	if( Unit == none ) return; 

	Unit.HasSoldierBondAvailable(BondmateRef, BondData);

	if( BondmateRef.ObjectID != 0 )
		XComHQPresentationLayer(Movie.Pres).UISoldierBondAlert(Unit.GetReference(), BondmateRef);
}


function UITraitIcon CreateTraitIcon(XComGameState_Unit Unit, bool bPositive)
{
	local UITraitIcon TraitIcon;

	TraitIcon = Spawn(class'UITraitIcon', self);
	TraitIcon.InitTraitIcon(Name(TraitIcon.Name $"_"$string(Unit.GetReference().ObjectID)), bPositive, OnClickTraitIcon);
	TraitIcon.SetSize(class'UITraitIcon'.default.width, class'UITraitIcon'.default.height);
	TraitIcon.AnimateTrait(true);

	return TraitIcon;
}

function OnClickTraitIcon(UITraitIcon Icon)
{
	local int UntiID;
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;
	//start issue #85: variables required to check the trait template of what we've been given
	local X2EventListenerTemplateManager EventTemplateManager;
	local X2TraitTemplate TraitTemplate;
	//end issue #85
	
	UntiID = int(GetRightMost(string(Icon.MCName)));
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UntiID));

	if(Unit == none) return;

	//start issue #85: init variables here to check for trait template. If Positive, we cancel this callback.
	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();
	TraitTemplate = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(Unit.AlertTraits[0]));
	//while it's an array, we go with the base game's assumption of having only one trait to worry about when it changes				
			
	if(TraitTemplate.bPositiveTrait)
		return; 
	//end issue #85
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Trait Display Cleanup");
	Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
	XComHQPresentationLayer(Movie.Pres).UINegativeTraitAlert(NewGameState, Unit, Unit.AlertTraits[0]);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//=====================================================================
//		DEFAULTS:
//=====================================================================

defaultproperties
{
	bAnimateOnInit = false;
}
