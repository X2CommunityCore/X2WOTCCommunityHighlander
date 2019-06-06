//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SwapTeams extends X2Action;

// a reference to the unit that swapped teams
var private XComGameState_Unit GameStateUnit;

function Init()
{
	super.Init();
	
	GameStateUnit = XComGameState_Unit(Metadata.StateObject_NewState);
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function UpdateUnitForSwap()
	{
		local XComGameStateHistory History;
		local XGUnit VisUnit;
		local XGPlayer VisPlayer;
		local XComWorldData WorldData;
		local XComGameState_Player PlayerState; //The player in control of this unit
		local ETeam	ControlledUnitTeam; // The team of the player in control

		if( GameStateUnit == none )
		{
			`Redscreen("X2Action_SwapTeams: No unit provided to swap! Talk to David B., or fix this if you broke it!");
			return;
		}

		History = `XCOMHISTORY;

		VisUnit = XGUnit(History.GetVisualizer(GameStateUnit.ObjectID));
		VisPlayer = XGPlayer(History.GetVisualizer(GameStateUnit.ControllingPlayer.ObjectID));
		
		// remove any previously attached range indicators from the unit. These are usually put on
		// non-xcom civilians and should be removed before they switch teams
		VisUnit.GetPawn().DetachRangeIndicator();
		
		VisUnit.m_kPlayer = VisPlayer;
		VisUnit.m_kPlayerNativeBase = VisPlayer;
		VisUnit.SetTeamType(Unit.GetTeam());
		VisUnit.InitBehavior();

		VisUnit.IdleStateMachine.CheckForStanceUpdate();

		// Mark the FOW texture map as dirty to force an update
		WorldData = `XWORLD.GetWorldData();
		WorldData.bFOWTextureBufferIsDirty = true;

		// Changing the glow material on cover depending on who's in control of this unit.
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(GameStateUnit.ControllingPlayer.ObjectID));
		ControlledUnitTeam = PlayerState.GetTeam();
		UnitPawn.ChangeAuxMaterialOnTeamChange(ControlledUnitTeam);
	}

Begin:
	
	UpdateUnitForSwap();

	CompleteAction();
}

