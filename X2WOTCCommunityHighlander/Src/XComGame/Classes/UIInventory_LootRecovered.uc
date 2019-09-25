
class UIInventory_LootRecovered extends UIInventory;

var array<StateObjectReference> UnlockedTechs;
var UIInventory_VIPRecovered VIPPanel;

var localized string m_strNoLoot;
var localized string m_strObjectiveItemsRecovered;
var localized string m_strLootRecovered;
var localized string m_strArtifactRecovered;
var localized string m_strArtifactRecoveredEvac;
var localized string m_strArtifactRecoveredSweep;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState_MissionSite Mission;

	super.InitScreen(InitController, InitMovie, InitName);
	
	SetInventoryLayout();
	PopulateData();

	Mission = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
	if(Mission.HasRewardVIP())
	{
		VIPPanel = Spawn(class'UIInventory_VIPRecovered', self).InitVIPRecovered();
		VIPPanel.SetPosition(1300, 772); // position is based on guided out panel in Inventory.fla
	}

	`XCOMGRI.DoRemoteEvent('CIN_HideArmoryStaff'); //Hide the staff in the armory so that they don't overlap with the soldiers

	ContinueAfterActionMatinee();
	`XCOMGRI.DoRemoteEvent('LootRecovered');
}

simulated function BuildScreen()
{
	super.BuildScreen();
	
	// Transition instantly to from UIAfterAction to UIInventory_LootRecovered
	if( bIsIn3D ) class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, 0);
}

function ContinueAfterActionMatinee()
{
	local XComLevelActor AvengerSunShade;	

	//Turn back on the sunshade object that prevents the directional light from affecting the avenger side view
	foreach AllActors(class'XComLevelActor', AvengerSunShade)
	{
		if(AvengerSunShade.Tag == 'AvengerSunShade')
		{
			AvengerSunShade.StaticMeshComponent.bCastHiddenShadow = true;
			AvengerSunShade.ReattachComponent(AvengerSunShade.StaticMeshComponent);
			break;
		}
	}
}

simulated function PopulateData()
{
	local int i;
	local name TemplateName;
	local X2ItemTemplate ItemTemplate;
	local X2EquipmentTemplate EquipmentTemplate;
	local UIInventory_ListItem ListItem;
	local XComGameState_Item ItemState;
	local XComGameState_BattleData BattleData;
	local array<StateObjectReference> PrevUnlockedTechs, PrevUnlockedShadowProjects, UnlockedShadowProjects;
	local array<XComGameState_Item> ObjectiveItems;
	local array<XComGameState_Item> Artifacts;
	local array<XComGameState_Item> Loot, AutoLoot;
	local XComGameState_Tech TechState;
	local XComNarrativeMoment LootRecoveredNarrative;
	local array<StateObjectReference> LootList;
	local XComGameState NewGameState;
	local UIInventory_HeaderListItem HeaderListItem;

	super.PopulateData();

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// First try to unpack any item caches which were recovered
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Loot Recovered: Open Cache Items");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	if (XComHQ.UnpackCacheItems(NewGameState))
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);	
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true); // Refresh XComHQ
	LootList = XComHQ.LootRecovered;

	for(i = 0; i < LootList.Length; i++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(LootList[i].ObjectID));

		if(ItemState != none)
		{
			ItemTemplate = ItemState.GetMyTemplate();

			if(!ItemTemplate.HideInLootRecovered)
			{
				TemplateName = ItemState.GetMyTemplateName();
				EquipmentTemplate = X2EquipmentTemplate(ItemTemplate);
				
				if ((ItemTemplate.ItemCat == 'goldenpath' || ItemTemplate.ItemCat == 'quest') && EquipmentTemplate == none) // Add non-equipment GP items to the Objective section
					ObjectiveItems.AddItem(ItemState);
				else if(ItemTemplate.IsObjectiveItemFn != none && ItemTemplate.IsObjectiveItemFn())
				{
					ObjectiveItems.AddItem(ItemState);
				}
				else if(BattleData.CarriedOutLootBucket.Find(TemplateName) != INDEX_NONE)
					Loot.AddItem(ItemState);
				else if(BattleData.AutoLootBucket.Find(TemplateName) != INDEX_NONE)
					AutoLoot.AddItem(ItemState);
				else
					Artifacts.AddItem(ItemState);
			}

			if (ItemState.GetMyTemplate().ItemRecoveredAsLootNarrative != "")
			{
				if (ItemState.GetMyTemplate().ItemRecoveredAsLootNarrativeReqsNotMet != "" && !XComHQ.MeetsAllStrategyRequirements(ItemState.GetMyTemplate().Requirements))
					LootRecoveredNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(ItemState.GetMyTemplate().ItemRecoveredAsLootNarrativeReqsNotMet));
				else
					LootRecoveredNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(ItemState.GetMyTemplate().ItemRecoveredAsLootNarrative));

				XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
				if (LootRecoveredNarrative != None && XComHQ.CanPlayLootNarrativeMoment(LootRecoveredNarrative))
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Played Loot Narrative List");
					XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.UpdatePlayedLootNarrativeMoments(LootRecoveredNarrative);
					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

					`HQPRES.UINarrative(LootRecoveredNarrative);
				}
			}

			if (ItemState.GetMyTemplate().ItemRecoveredAsLootEventToTrigger != '')
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Loot Recovered Event");
				`XEVENTMGR.TriggerEvent(ItemState.GetMyTemplate().ItemRecoveredAsLootEventToTrigger, , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}

	if(ObjectiveItems.Length > 0)
	{
		HeaderListItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
		HeaderListItem.InitHeaderItem(class'UIUtilities_Image'.const.LootIcon_Objectives, m_strObjectiveItemsRecovered);
		HeaderListItem.DisableNavigation();
		
		for(i = 0; i < ObjectiveItems.Length; ++i)
			AddLootItem(ObjectiveItems[i]);
	}

	if(Loot.Length > 0)
	{
		HeaderListItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
		HeaderListItem.InitHeaderItem(class'UIUtilities_Image'.const.LootIcon_Loot, m_strLootRecovered);
		HeaderListItem.DisableNavigation();
		for(i = 0; i < Loot.Length; ++i)
			AddLootItem(Loot[i]);
	}

	for(i = 0; i < AutoLoot.Length; i++)
	{
		Artifacts.AddItem(AutoLoot[i]);
	}

	if(Artifacts.Length > 0)
	{
		HeaderListItem = Spawn(class'UIInventory_HeaderListItem', List.ItemContainer);
		HeaderListItem.InitHeaderItem(class'UIUtilities_Image'.const.LootIcon_Artifacts, m_strArtifactRecovered, BattleData.AllTacticalObjectivesCompleted() ? m_strArtifactRecoveredSweep : m_strArtifactRecoveredEvac);
		HeaderListItem.DisableNavigation();
		for(i = 0; i < Artifacts.Length; ++i)
			AddLootItem(Artifacts[i]);
	}

	SetCategory(List.ItemCount == 0 ? m_strNoLoot : "");

	if(List.ItemCount > 0)
	{
		i = 0;
		while(i < List.ItemCount)
		{

			ListItem = UIInventory_ListItem(List.GetItem(i));
			if (ListItem != none && ListItem.bIsNavigable)
			{
				List.SetSelectedItem(ListItem);
				PopulateItemCard(ListItem.ItemTemplate, ListItem.ItemRef);
				break;
			}
			i++;
		}
	}
	
	// Store available upgrades before adding new loot
	PrevUnlockedTechs = XComHQ.GetAvailableTechsForResearch();
	PrevUnlockedShadowProjects = XComHQ.GetAvailableTechsForResearch(true);

	class'XComGameStateContext_StrategyGameRule'.static.AddLootToInventory();

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("LootMenu_LootPickup");

	// Get newly available available upgrades now that we added new loot
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	UnlockedTechs = XComHQ.GetAvailableTechsForResearch();
	UnlockedShadowProjects = XComHQ.GetAvailableTechsForResearch(true);

	// Removed previously available techs from UnlockedTechs array to get new techs generated by the loot recovered
	for(i = 0; i < PrevUnlockedTechs.Length; ++i)
	{
		UnlockedTechs.RemoveItem(PrevUnlockedTechs[i]);
	}

	// Removed previously available shadow projects from the array to get new shadow projects generated by the loot recovered
	for(i = 0; i < PrevUnlockedShadowProjects.Length; ++i)
	{
		UnlockedShadowProjects.RemoveItem(PrevUnlockedShadowProjects[i]);
	}

	for(i = 0; i < UnlockedShadowProjects.Length; ++i)
	{
		UnlockedTechs.AddItem(UnlockedShadowProjects[i]);
	}

	for(i = 0; i < UnlockedTechs.Length; ++i)
	{
		TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(UnlockedTechs[i].ObjectID));

		if(TechState != None && TechState.TimesResearched > 0)
		{
			UnlockedTechs.Remove(i, 1);
			i--;
		}
	}
}

simulated function AddLootItem(XComGameState_Item ItemState)
{
	Spawn(class'UIInventory_ListItem', List.ItemContainer).InitInventoryListItem(ItemState.GetMyTemplate(), ItemState.Quantity, ItemState.GetReference());
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();
	NavHelp.AddContinueButton(CloseScreen);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.Show();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.Hide();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		// OnAccept
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			CloseScreen();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			`HQPRES.UIPauseMenu( ,true );
			return true;
		//bsg-crobinson (5.11.17): Case for input and drop to its super call to add sound
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
			break;
		//bsg-crobinson (5.11.17): end
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function CloseScreen()
{
	local XComGameState NewGameState;
	local SkeletalMeshActor IterateActor;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Post Mission Loot UI Sequence Hook");
	`XEVENTMGR.TriggerEvent('PostMissionLoot', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	super.CloseScreen();

	if (VIPPanel != none)
	{
		VIPPanel.Cleanup();
	}

	if(UnlockedTechs.Length > 0)
	{
		`HQPRES.UIResearchUnlocked(UnlockedTechs);
	}	
	else
	{

		`XCOMGRI.DoRemoteEvent('CIN_UnhideArmoryStaff'); //Show the armory staff now that we are done

		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		if(XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID)).GetMissionSource().bSkipRewardsRecap ||
			!XComHQ.IsObjectiveCompleted('T0_M8_ReturnToAvengerPt2'))
		{
			`HQPRES.ExitPostMissionSequence();
			`HQPRES.UICheckForPostCovertActionAmbush();
		}
		else
		{
			`HQPRES.UIRewardsRecap();
		}

		foreach AllActors(class'SkeletalMeshActor', IterateActor)
		{
			if(IterateActor.Tag == 'AvengerSideView_Dropship')
			{
				IterateActor.SetHidden(false);
			}
		}
	}
}

simulated function Remove()
{
	super.Remove();
}

defaultproperties
{
	DisplayTag="UIBlueprint_LootRecovered"
	CameraTag="UIBlueprint_LootRecovered"
}