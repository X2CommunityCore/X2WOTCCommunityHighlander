class XComAutosaveMgr extends Actor
	config(Game)
	dependson(XComOnlineEventMgr);

const MAX_TACTICAL_AUTOSAVES = 3;

var private bool    m_bWasIronman;
var delegate<XComOnlineEventMgr.WriteSaveGameComplete> SaveGameCompleteCallback;

function Init()
{
}

function bool WasIronman()
{
	return m_bWasIronman;
}

function DoAutosave(delegate<XComOnlineEventMgr.WriteSaveGameComplete> AutoSaveCompleteCallback = none, optional bool bDebugSave, optional bool bPreMissionSave, optional bool bPostMissionSave, optional int PartialHistoryLength = -1)
{
	local array<OnlineSaveGame> arrGames;
	local array<SaveGameHeader> arrTacticalSaves;
	local SaveGameHeader CurrentHeader;
	local OnlineSaveGame kGame;
	local OnlineSaveGameDataMapping kData;
	local XComOnlineEventMgr EventMgr;
	local int iSaveSlot;
	local bool bIsIronman, bIsTactical;
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Analytics AnalyticsState;
	local int MissionNum;

	local int iMaxSaves; // Variable for Issue #53

	History = `XCOMHISTORY;

	//See if we are in a campaign, and if we are, if ironman is enabled
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
	{
		bIsIronman = CampaignSettingsStateObject.bIronmanEnabled;
	}

	AlienHQ = XComGameState_HeadquartersAlien( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersAlien', true ) );
	
	if (AutosaveEnabled(bIsIronman) && ((AlienHQ == none) || !AlienHQ.bAlienFullGameVictory))
	{
		EventMgr = `ONLINEEVENTMGR;

		iSaveSlot = -1;
		if (!EventMgr.GetSaveGames(arrGames))  //  Assumes manager's cache is up to date.
		{
			`log("GetSaveGames FAILED! aborting autosave",,'XCom_Online');
			if (AutoSaveCompleteCallback != none)
				AutoSaveCompleteCallback(false);
			return;
		}
		`log("GetSaveGames returned" @ arrGames.Length @ "saves",,'XCom_Online');
		EventMgr.SortSavedGameListByTimestamp(arrGames);
		m_bWasIronman = bIsIronman;

		bIsTactical = (XComTacticalGRI(WorldInfo.GRI) != none);

		// when we perform the post mission debug save, we need to clear all of the debug tactical saves from the previous mission 
		// except the first and the last
		if( bPostMissionSave )
		{
			AnalyticsState = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
			MissionNum = AnalyticsState.GetFloatValue("BATTLES_WON") + AnalyticsState.GetFloatValue("BATTLES_LOST") - 1;

			foreach arrGames(kGame)
			{
				foreach kGame.SaveGames(kData)
				{
					if( kData.SaveGameHeader.bDebugSave &&
						kData.SaveGameHeader.bIsTacticalSave &&
 					    kData.SaveGameHeader.CampaignStartTime == CampaignSettingsStateObject.StartTime &&
					    kData.SaveGameHeader.Mission == MissionNum )
					{
						arrTacticalSaves.AddItem(kData.SaveGameHeader);
						break;
					}
				}
			}

			// if there are more than 2 debug saves, remove all the extras
			if( arrTacticalSaves.Length > 2 )
			{
				arrTacticalSaves.Sort(SortTacticalSaves);

				// remove first and last from the list to delete
				arrTacticalSaves.Remove(0, 1);
				arrTacticalSaves.Remove(arrTacticalSaves.Length - 1, 1);

				arrTacticalSaves.Sort(SortReverseSaveIDOrder);

				foreach arrTacticalSaves(CurrentHeader)
				{
					EventMgr.DeleteSaveGame(CurrentHeader.SaveID);
				}

				iSaveSlot = -1;
			}
		}



		if( bDebugSave )
		{
			iSaveSlot = GetNextSaveID();
		}
		else
		{
			if( bIsIronman )
			{
				//  IRONMAN save.
				//  Only allowed to use the existing save file.
				iSaveSlot = GetSaveIDForCampaign( CampaignSettingsStateObject );
			}
			else if( !bIsTactical )
			{
				`log("===Strategy autosave===", , 'XCom_Online');
				//  Strategy save.
				//  Find the existing (non tactical) autosave for this game. We assume there is a campaign settings state object if we got in here...
				foreach arrGames(kGame)
				{
					`log("Checking save" @ kGame.Filename @ kGame.FriendlyName, , 'XCom_Online');
					foreach kGame.SaveGames(kData)
					{
						`log("Checking inner data" @ kData.SaveGameHeader.CampaignStartTime @ kData.SaveGameHeader.bIsAutosave, , 'XCom_Online');
						if( !kData.SaveGameHeader.bDebugSave && 
						   !kData.SaveGameHeader.bIsTacticalSave && 
						   kData.SaveGameHeader.bIsAutosave &&
						   kData.SaveGameHeader.CampaignStartTime == CampaignSettingsStateObject.StartTime )
						{
							iSaveSlot = kData.SaveGameHeader.SaveID;
							`log("Matched! save slot" @ iSaveSlot, , 'XCom_Online');
							break;
						}
					}
					if( iSaveSlot >= 0 )
					{
						`log("Using save slot" @ iSaveSlot, , 'XCom_Online');
						break;
					}
				}

			}
			else
			{
				//  Tactical save at this point.
				//  Build a list of all the tactical autosaves at this point.
				`log("===Tactical autosave===", , 'XCom_Online');
				arrTacticalSaves.Length = 0;
				foreach arrGames(kGame)
				{
					foreach kGame.SaveGames(kData)
					{
						if( !kData.SaveGameHeader.bDebugSave &&
						   kData.SaveGameHeader.bIsTacticalSave && 
						   kData.SaveGameHeader.bIsAutosave && 
						   kData.SaveGameHeader.CampaignStartTime == CampaignSettingsStateObject.StartTime &&
						   (kData.SaveGameHeader.bIsIronman == bIsIronman) )
						{
							`log("Found tactical autosave" @ kData.SaveGameHeader.SaveID, , 'XCom_Online');
							arrTacticalSaves.AddItem(kData.SaveGameHeader);
							break;
						}
					}
				}

				// Start Issue #53 - use config saves if set
				iMaxSaves = class'CHHelpers'.default.MAX_TACTICAL_AUTOSAVES > 0
					? class'CHHelpers'.default.MAX_TACTICAL_AUTOSAVES
					: MAX_TACTICAL_AUTOSAVES;

				if( arrTacticalSaves.Length < iMaxSaves )
				// End Issue #53
				{
					iSaveSlot = GetNextSaveID();
					`log("Less than the max number of tactial autosaves, using new save slot" @ iSaveSlot, , 'XCom_Online');
				}
				else
				{
					//The list of saves we are iterating is sorted, so we pick the last				
					iSaveSlot = arrTacticalSaves[arrTacticalSaves.Length - 1].SaveID;
					`log("Picking the last (oldest) tactical autosave to overwrite" @ iSaveSlot, , 'XCom_Online');
				}
			}
		}
	

		if (iSaveSlot < 0)      //  Could be our first save of the game.
			iSaveSlot = GetNextSaveID();

		`assert(iSaveSlot >= 0);

		`log("Saving game in slot" @ iSaveSlot,,'XCom_Online');
		if( AutoSaveCompleteCallback != None )
		{
			SaveGameCompleteCallback = AutoSaveCompleteCallback;
		}
		EventMgr.SaveGame(iSaveSlot, true, false, OnSaveGameComplete, bDebugSave, bPreMissionSave, bPostMissionSave, PartialHistoryLength);
		EventMgr.SaveProfileSettings();
	}
	else
	{
		// Autosave disabled
		if (AutoSaveCompleteCallback != none)
			AutoSaveCompleteCallback(false);
	}
}

private function int SortTacticalSaves(SaveGameHeader HeaderA, SaveGameHeader HeaderB)
{
	if( HeaderA.Turn == HeaderB.Turn )
		return (HeaderB.Action - HeaderA.Action);
	else
		return (HeaderB.Turn - HeaderA.Turn);
}

private function int SortReverseSaveIDOrder(SaveGameHeader HeaderA, SaveGameHeader HeaderB)
{
	return (HeaderA.SaveID - HeaderB.SaveID);
}

function int GetSaveIDForCampaign( optional XComGameState_CampaignSettings Campaign )
{
	local array<OnlineSaveGame> arrGames;
	local OnlineSaveGame kGame;
	local OnlineSaveGameDataMapping kData;

	if (Campaign == none)
	{
		Campaign = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));

		if (Campaign == none) // still missing??
			return -1;
	}

	`ONLINEEVENTMGR.GetSaveGames( arrGames );

	foreach arrGames(kGame)
	{
		foreach kGame.SaveGames(kData)
		{
			if( kData.SaveGameHeader.CampaignStartTime == Campaign.StartTime )
			{
				return kData.SaveGameHeader.SaveID;
			}
		}
	}

	return -1;
}

function DoQuickload()
{
	local array<OnlineSaveGame> arrGames;
	local OnlineSaveGame kGame;
	local OnlineSaveGameDataMapping kData;
	local XComOnlineEventMgr EventMgr;
	local int iSaveSlot;
	local XComPlayerController PC;	
	local string MissingDLC;
	local TDialogueBoxData DialogData;
	local XComPresentationLayerBase PresBase;

	if(SavingEnabled() && !(class'Engine'.static.GetEngine()).IsMultiPlayerGame())
	{
		EventMgr = `ONLINEEVENTMGR;

		iSaveSlot = -1;
		EventMgr.GetSaveGames(arrGames);  //  Assumes manager's cache is up to date.		

		//  Find an existing quick save
		foreach arrGames(kGame)
		{
			foreach kGame.SaveGames(kData)
			{
				if (!`ONLINEEVENTMGR.CheckSaveVersionRequirements(kData.SaveGameHeader.SaveID))
				{
					continue;
				}

				if(kData.SaveGameHeader.bIsQuicksave)
				{
					iSaveSlot = kData.SaveGameHeader.SaveID;
					break;
				}			
			}

			if(iSaveSlot >= 0)
				break;
		}

		//Pause before we load as loading will nuke the history and we don't want any actors to get upset
		PC = XComPlayerController(GetALocalPlayerController());

		//Found one, load it
		if(iSaveSlot > -1)
		{
			PC.SetPause(true);
			if(!EventMgr.CheckSaveDLCRequirements(iSaveSlot, MissingDLC))
			{
				DialogData.eType = eDialog_Warning;
				DialogData.strTitle = class'UILoadGame'.default.m_sMissingDLCTitle;
				DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
				DialogData.strText = class'UILoadGame'.default.m_sMissingDLCText $ "\n" $ MissingDLC;
				DialogData.fnCallback = DownloadableContentInfoAccept;

				PresBase = XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres;
				PresBase.UIRaiseDialog(DialogData);
			}
			else
			{
				EventMgr.LoadGame(iSaveSlot, ReadSaveGameComplete);
			}
		}
	}
}

simulated private function DownloadableContentInfoAccept(Name eAction)
{
	local XComPlayerController PC;

	PC = XComPlayerController(GetALocalPlayerController());
	PC.SetPause(false);
}

simulated private function ReadSaveGameComplete(bool bWasSuccessful)
{

}

function DoQuicksave(delegate<XComOnlineEventMgr.WriteSaveGameComplete> QuicksaveCompleteCallback = none)
{
	local array<OnlineSaveGame> arrGames;
	local OnlineSaveGame kGame;
	local OnlineSaveGameDataMapping kData;
	local XComOnlineEventMgr EventMgr;
	local int iSaveSlot;
	local bool bIsIronman;
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	History = `XCOMHISTORY;

	//See if we are in a campaign, and if we are, if ironman is enabled
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
	{
		bIsIronman = CampaignSettingsStateObject.bIronmanEnabled;
	}
	
	if(SavingEnabled() && !bIsIronman && !(class'Engine'.static.GetEngine()).IsMultiPlayerGame()) //Ironman sessions cannot quick save
	{
		EventMgr = `ONLINEEVENTMGR;

		iSaveSlot = -1;
		EventMgr.GetSaveGames(arrGames);  //  Assumes manager's cache is up to date.
		m_bWasIronman = bIsIronman;

		// Find an existing quicksave
		foreach arrGames(kGame)
		{
			foreach kGame.SaveGames(kData)
			{
				if (kData.SaveGameHeader.bIsQuicksave)
				{	
					iSaveSlot = kData.SaveGameHeader.SaveID;
					break;
				}
				if (iSaveSlot >= 0)
					break;
			}
		}
		
	
		if (iSaveSlot < 0)      //  Could be our first quicksave
			iSaveSlot = GetNextSaveID();

		`assert(iSaveSlot >= 0);

		if( QuicksaveCompleteCallback != None )
		{
			SaveGameCompleteCallback = QuicksaveCompleteCallback;
		}
		EventMgr.SaveGame(iSaveSlot, false, !bIsIronman, OnSaveGameComplete);
		EventMgr.SaveProfileSettings();
	}
	else
	{
		// Saving disabled
		if (QuicksaveCompleteCallback != none)
			QuicksaveCompleteCallback(false);
	}
}

function int GetNextSaveID()
{
	local int iSaveSlot;

	iSaveSlot = `ONLINEEVENTMGR.GetNextSaveID();

	`log("GetNextSaveID returning " $ iSaveSlot);

	return iSaveSlot;
}

function bool AutosaveEnabled(bool bIsIronman)
{
	return (bIsIronman || `XPROFILESETTINGS.Data.m_bAutoSave) && SavingEnabled();
}

function bool SavingEnabled()
{
	return XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres.AllowSaving();
}

function OnSaveGameComplete(bool bWasSuccessful)
{
	if( SaveGameCompleteCallback != None )
	{
		SaveGameCompleteCallback(bWasSuccessful);
		SaveGameCompleteCallback = None;
	}
}
