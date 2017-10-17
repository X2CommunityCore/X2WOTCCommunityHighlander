//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPersonnel_TrainingCenter
//  AUTHOR:  Joe Weinhoffer
//  PURPOSE: Provides custom behavior for personnel selection screen when
//           selecting soldiers to train abilities from the Training Center facility.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIPersonnel_TrainingCenter extends UIPersonnel;

simulated function UpdateList()
{
	local XComGameState_Unit Unit;
	local UIPersonnel_ListItem UnitItem;
	local int i;

	super.UpdateList();
		
	// Disable any soldiers who are not eligible for ability training (Rookies and Faction Heroes)
	for (i = 0; i < m_kList.itemCount; ++i)
	{
		UnitItem = UIPersonnel_ListItem(m_kList.GetItem(i));
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitItem.UnitRef.ObjectID));

		if (Unit.GetRank() == 0 || 
			(!Unit.GetSoldierClassTemplate().bAllowAWCAbilities && !Unit.IsResistanceHero()) ||
			Unit.IsOnCovertAction())
		{
			UnitItem.SetDisabled(true);
		}
	}
}

// bsg-jrebar (4/19/17): Add nav help for A button if on armory
simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	if(HQState.IsObjectiveCompleted('T0_M2_WelcomeToArmory'))
	{
		NavHelp.AddBackButton(OnCancel);
		NavHelp.AddSelectNavHelp();

		// Don't allow jumping to the geoscape from the armory in the tutorial or when coming from squad select
		if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') != eObjectiveState_InProgress
			&& !`SCREENSTACK.IsInStack(class'UISquadSelect'))
			NavHelp.AddGeoscapeButton();

		if( `ISCONTROLLERACTIVE )
		{
			NavHelp.AddLeftHelp(m_strToggleSort, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);	
		}
	}
	else if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddLeftHelp(m_strToggleSort, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
	}
}
// bsg-jrebar (4/19/17): end

defaultproperties
{
	m_eListType = eUIPersonnel_Soldiers;
}