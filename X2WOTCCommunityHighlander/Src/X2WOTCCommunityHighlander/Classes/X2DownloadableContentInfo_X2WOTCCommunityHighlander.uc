//---------------------------------------------------------------------------------------
//  FILE:   X2DownloadableContentInfo_X2CommunityHighlander.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_X2WOTCCommunityHighlander extends X2DownloadableContentInfo config(Game) dependson(X2WOTCCH_Components);

/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	local array<CHLComponent> Comps;
	local int i;
	local CHLComponentStatus WorstStatus;

	`log("Companion script package loaded", , 'X2WOTCCommunityHighlander');

	Comps = class'X2WOTCCH_Components'.static.GetComponentInfo();
	WorstStatus = class'X2WOTCCH_Components'.static.FindHighestErrorLevel(Comps);

	`log("Components:", , 'X2WOTCCommunityHighlander');
	for (i = 0; i < Comps.Length; i++)
	{
		`log("  " $ Comps[i].DisplayName @ "--" @ Comps[i].DisplayVersion, , 'X2WOTCCommunityHighlander');
	}

	if (WorstStatus == eCHLCS_RequiredNotFound)
	{
		`log("Required packages were not loaded. Please consult" @ class'X2WOTCCH_UIScreenListener_ShellSplash'.default.HelpLink @ "for further information", , 'X2WOTCCommunityHighlander');
	}

	// We don't want to crash when not loaded.
	if (class'CHHelpers' != none)
	{
		// Begin Issue #123
		class'CHHelpers'.static.RebuildPerkContentCache();
		// End Issue #123
	}
}

// Because 1.19.0 broke TLP weapons/Chosen weapons attachments without a retroactive way to fix it,
// we offer a console command to be used in strategy that calls OnAcquiredFn on all weapons in XCOM HQ.
// User instructions: In strategy, remove the nickname from all TLP/Chosen weapons and unequip them to
// XCom HQ (replace their weapons with generic infinite weapons). Then, run the console command
// `CHLSimulateReacquireHQWeapons` to give those weapons their missing upgrades.
// This console command may not affect: Weapons in soldiers' inventories, weapons with nicknames.
exec function CHLSimulateReacquireHQWeapons()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local StateObjectReference ItemRef;
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;

	History = `XCOMHISTORY;
	XComHQ = `XCOMHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("CHL: Simulate re-acquiring of weapons upon user request");

	foreach XComHQ.Inventory(ItemRef)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
		ItemTemplate = ItemState.GetMyTemplate();
		// Relevant functions for TLP weapons require no installed upgrades, while Chosen weapons require no
		// modifications -- but weapons with 0 upgrade slots are not considered modified even with installed upgrades
		// As a result, we explicitly check for number of upgrades, but still want to tell the user to revert name changes
		// to the weapon.
		if (X2WeaponTemplate(ItemTemplate) != none && ItemState.GetMyWeaponUpgradeCount() == 0 && ItemTemplate.OnAcquiredFn != none && !ItemTemplate.HideInInventory)
		{
			ItemState = XComGameState_Item(NewGameState.ModifyStateObject(class'XComGameState_Item', ItemRef.ObjectID));
			ItemTemplate.OnAcquiredFn(NewGameState, ItemState);
		}
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

exec function CHLDumpRunOrderInternals()
{
	CHOnlineEventMgr(`ONLINEEVENTMGR).DumpInternals();
}