//---------------------------------------------------------------------------------------
//  FILE:    X2PathTargetPathingPath.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Specialized pathing pawn for activated path targeting.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2PathTargetPathingPawn extends XComPathingPawn;

// disable the built in pathing melee targeting.
simulated /* protected */ function bool CanUnitMeleeFromMove(XComGameState_BaseObject TargetObject, out XComGameState_Ability MeleeAbility)
{
	return false;
}

// don't update objective tiles
function UpdateObjectiveTiles(XComGameState_Unit InActiveUnitState);

defaultproperties
{
	AllowSelectionOfActiveUnitTile=true
}