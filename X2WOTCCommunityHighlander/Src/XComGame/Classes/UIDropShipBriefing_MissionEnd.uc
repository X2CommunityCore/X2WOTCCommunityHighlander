//-----------------------------------------------------------
//
//-----------------------------------------------------------
class UIDropShipBriefing_MissionEnd extends UIDropShipBriefingBase;

var int TipCycle;
var UIButton LaunchButton;
var UIList LeftList;
var UIList RightList;

var localized string m_strPressKeyToContinue;
var localized string m_strConsolePressKeyToContinue;
var localized string m_strSuccessfulShotPercentage;
var localized string m_strAverageDamagePerAttack;
var localized string m_strAverageEnemiesKilledPerTurn;
var localized string m_strAverageCoverBonus;
var localized string m_strDealtMostDamage;
var localized string m_strTookMostShots;
var localized string m_strMostUnderFire;
var localized string m_strMovedFurthest;
var localized string m_strLoadingText;
var localized string m_strNewRecord;

var const localized array<string> PostMissionNarrativeNeutralizeSuccess;
var const localized array<string> PostMissionNarrativeNeutralizeFailed;
var const localized array<string> PostMissionNarrativeSabotageSuccess;
var const localized array<string> PostMissionNarrativeSabotageFailed;
var const localized array<string> PostMissionNarrativeRescueSuccess;
var const localized array<string> PostMissionNarrativeRescueFailed;
var const localized array<string> PostMissionNarrativeRetaliationSuccess;
var const localized array<string> PostMissionNarrativeRetaliationFailed;
var const localized array<string> PostMissionNarrativeSwarmSuccess;
var const localized array<string> PostMissionNarrativeSwarmFailed;
var const localized array<string> PostMissionNarrativeGenericSuccess;
var const localized array<string> PostMissionNarrativeGenericFailed;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local string MissionResult;
	local X2MissionTemplate MissionTemplate;
	local XComGameState_BattleData BattleData;
	local GeneratedMissionData GeneratedMission;
	local XComGameState_CampaignSettings SettingsState;
	local Texture2D PosterTexture;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	GeneratedMission = class'UIUtilities_Strategy'.static.GetXComHQ().GetGeneratedMissionData(BattleData.m_iMissionID);
	MissionTemplate = class'X2MissionTemplateManager'.static.GetMissionTemplateManager().FindMissionTemplate(GeneratedMission.Mission.MissionName);

	super.InitScreen(InitController, InitMovie, InitName);

	LeftList = Spawn(class'UIList', self);
	LeftList.bAnimateOnInit = false;
	LeftList.InitList('leftListMC');

	RightList = Spawn(class'UIList', self);
	RightList.bAnimateOnInit = false;
	RightList.InitList('rightListMC');

	LaunchButton = Spawn(class'UIButton', self).InitButton('launchButtonMC');
	LaunchButton.bIsVisible = false;
	LaunchButton.DisableNavigation();
	
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));	

	if( BattleData.bLocalPlayerWon && !BattleData.bMissionAborted )
	{
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(class'UIMissionSummary'.default.m_strMissionComplete, eUIState_Good);
	}
	else if( BattleData.bMissionAborted )
	{
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(class'UIMissionSummary'.default.m_strMissionAbandoned, eUIState_Bad);
	}
	else if( !BattleData.bLocalPlayerWon )
	{
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(class'UIMissionSummary'.default.m_strMissionFailed, eUIState_Bad);
	}

	PosterTexture = `XENGINE.m_kPhotoManager.GetLatestPoster(SettingsState.GameIndex);

	MC.BeginFunctionOp("updatePostBriefing");
	MC.QueueString(BattleData.m_strOpName);
	MC.QueueString(MissionTemplate.PostMissionType);
	MC.QueueString(MissionResult);
	MC.QueueString(GetTip(eTip_Strategy));
	MC.QueueString(m_strLoadingText);
	if (PosterTexture != none)
		MC.QueueString("img:///"$PathName(PosterTexture));
	MC.EndOp();

	PopulateBattleStatistics();
	SetTimer(1.0f, true, nameof(Update));
	MC.SetNum("_xscale", 172);
	MC.SetNum("_yscale", 172);
	Show();

	PlayPostMissionNarrative();
}

simulated function PopulateBattleStatistics()
{
	local name ItemID;
	local string Label, Value;
	local UIPanel ItemContainer;
	local XComGameStateHistory History;
	local XComGameState_Analytics Analytics;
	local XComGameState_Unit UnitState;
	local UnitAnalyticEntry AnalyticEntry;
	local float TurnCount, UnitKills, TotalShots, TotalHits, TotalDamage, TotalAttacks, CoverCount, CoverTotal;
	local float ShotPercent, AvgDamage, AvgKills, AvgCover;
	local float RecordShotPercent, RecordAvgDamage, RecordAvgKills, RecordAvgCover;
	local XComGameState_BattleData BattleData;
	local bool bMissionSuccess, bIsFirstMission, bShowStats;

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
	bMissionSuccess = BattleData.bLocalPlayerWon && !BattleData.bMissionAborted; 
	bShowStats = true; // bMissionSuccess; // for how Jake wants to play with them on all the time and see how much it makes sense to disable them on failure
	bIsFirstMission = BattleData.m_bIsFirstMission;

	Analytics = XComGameState_Analytics( History.GetSingleGameStateObjectForClass( class'XComGameState_Analytics' ) );

	RecordShotPercent = Analytics.GetFloatValue( "RECORD_SHOTS" );
	RecordAvgDamage = Analytics.GetFloatValue( "RECORD_AVERAGE_DAMAGE" );
	RecordAvgKills = Analytics.GetFloatValue( "RECORD_AVERAGE_KILLS" );
	RecordAvgCover = Analytics.GetFloatValue( "RECORD_AVERAGE_COVER" );

	// Left List:
	LeftList.ClearItems();
	ItemID = 'PostStatLeftRowItem';
	ItemContainer = LeftList.ItemContainer;

	Value = "--";
	Label = m_strSuccessfulShotPercentage;
	if (bShowStats)
	{
		TotalShots = Analytics.GetTacticalFloatValue( "ACC_UNIT_SHOTS_TAKEN" );
		TotalHits = Analytics.GetTacticalFloatValue( "ACC_UNIT_SUCCESS_SHOTS" );
		if (TotalShots > 0)
		{
			ShotPercent = TotalHits / TotalShots;
			Value = class'UIUtilities'.static.FormatPercentage( ShotPercent * 100.0f, 2 );
			if ((ShotPercent > RecordShotPercent) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ m_strNewRecord;
		}
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Value = "--";
	Label = m_strAverageDamagePerAttack;
	if (bShowStats)
	{
		TotalDamage = Analytics.GetTacticalFloatValue( "ACC_UNIT_DEALT_DAMAGE" );
		TotalAttacks = Analytics.GetTacticalFloatValue( "ACC_UNIT_ATTACKS" );
		if (TotalAttacks > 0)
		{
			AvgDamage = TotalDamage / TotalAttacks;
			Value = class'UIUtilities'.static.FormatFloat( AvgDamage, 2 );
			if ((AvgDamage > RecordAvgDamage) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ m_strNewRecord;
		}
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Value = "--";
	Label = m_strAverageEnemiesKilledPerTurn;
	if (bShowStats)
	{
		TurnCount = Analytics.GetTacticalFloatValue( "TURN_COUNT" );
		UnitKills = Analytics.GetTacticalFloatValue( "ACC_UNIT_KILLS" );
		if (TurnCount > 0)
		{
			AvgKills = UnitKills / TurnCount;
			Value = class'UIUtilities'.static.FormatFloat( AvgKills, 2 );
			if ((AvgKills > RecordAvgKills) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ m_strNewRecord;
		}
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	Value = "--";
	Label = m_strAverageCoverBonus;
	if (bShowStats)
	{
		CoverCount = Analytics.GetTacticalFloatValue( "ACC_UNIT_COVER_COUNT" );
		CoverTotal = Analytics.GetTacticalFloatValue( "ACC_UNIT_COVER_TOTAL" );
		if (CoverCount > 0)
		{
			AvgCover = CoverTotal / CoverCount;
			Value = class'UIUtilities'.static.FormatPercentage( AvgCover * 20.0f, 2 );
			if ((AvgCover > RecordAvgCover) && !bIsFirstMission && bMissionSuccess)
				Value = Value $ " " $ m_strNewRecord;
		}
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value);

	// Right List:
	RightList.ClearItems();
	ItemID = 'PostStatRightRowItem';
	ItemContainer = RightList.ItemContainer;

	Label = m_strDealtMostDamage;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( "ACC_UNIT_DEALT_DAMAGE" );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick );
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = m_strTookMostShots;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( "ACC_UNIT_ATTACKS" );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick );
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = m_strMostUnderFire;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( "ACC_UNIT_ABILITIES_RECIEVED" );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick );
	}
	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);

	Label = m_strMovedFurthest;
	Value = "--";

	AnalyticEntry = Analytics.GetLargestTacticalAnalyticForMetric( "ACC_UNIT_MOVEMENT" );
	if (bShowStats && AnalyticEntry.ObjectID > 0)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( AnalyticEntry.ObjectID ) );
		Value = UnitState.GetName( eNameType_FullNick );
	}

	Spawn(class'UIDropShipBriefing_ListItem', ItemContainer).InitListItem(ItemID, Label, Value, true);
}

function PlayPostMissionNarrative()
{
	local XComGameState_BattleData BattleData;
	local XComNarrativeMoment DropshipNarrative;
	local GeneratedMissionData GeneratedMission;
	local string NarrativeToPlay;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	GeneratedMission = class'UIUtilities_Strategy'.static.GetXComHQ().GetGeneratedMissionData(BattleData.m_iMissionID);
	
	switch(GeneratedMission.Mission.MissionName)
	{
	case 'NeutralizeFieldCommander':
		if (BattleData.bLocalPlayerWon)
			NarrativeToPlay = PostMissionNarrativeNeutralizeSuccess[`SYNC_RAND(PostMissionNarrativeNeutralizeSuccess.Length)];
		else
			NarrativeToPlay = PostMissionNarrativeNeutralizeFailed[`SYNC_RAND(PostMissionNarrativeNeutralizeFailed.Length)];
		break;
	case 'SabotageTransmitter':
		if (BattleData.bLocalPlayerWon)
			NarrativeToPlay = PostMissionNarrativeSabotageSuccess[`SYNC_RAND(PostMissionNarrativeSabotageSuccess.Length)];
		else
			NarrativeToPlay = PostMissionNarrativeSabotageFailed[`SYNC_RAND(PostMissionNarrativeSabotageFailed.Length)];
		break;
	case 'CompoundRescueOperative':
		if (BattleData.bLocalPlayerWon)
			NarrativeToPlay = PostMissionNarrativeRescueSuccess[`SYNC_RAND(PostMissionNarrativeRescueSuccess.Length)];
		else
			NarrativeToPlay = PostMissionNarrativeRescueFailed[`SYNC_RAND(PostMissionNarrativeRescueFailed.Length)];
		break;
	case 'Terror':
		if (BattleData.bLocalPlayerWon)
			NarrativeToPlay = PostMissionNarrativeRetaliationSuccess[`SYNC_RAND(PostMissionNarrativeRetaliationSuccess.Length)];
		else
			NarrativeToPlay = PostMissionNarrativeRetaliationFailed[`SYNC_RAND(PostMissionNarrativeRetaliationFailed.Length)];
		break;
	case 'SwarmDefense':
		if (BattleData.bLocalPlayerWon)
			NarrativeToPlay = PostMissionNarrativeSwarmSuccess[`SYNC_RAND(PostMissionNarrativeSwarmSuccess.Length)];
		else
			NarrativeToPlay = PostMissionNarrativeSwarmFailed[`SYNC_RAND(PostMissionNarrativeSwarmFailed.Length)];
		break;
	default:
		if (BattleData.bLocalPlayerWon)
			NarrativeToPlay = PostMissionNarrativeGenericSuccess[`SYNC_RAND(PostMissionNarrativeGenericSuccess.Length)];
		else
			NarrativeToPlay = PostMissionNarrativeGenericFailed[`SYNC_RAND(PostMissionNarrativeGenericFailed.Length)];
		break;
	}
	
	DropshipNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(NarrativeToPlay));
	if (DropshipNarrative != None)
	{
		PC.Pres.UINarrative(DropshipNarrative);
	}
}

simulated function Update()
{
	local string FinalLaunchStr;
	local string CurrentLanguage;
	local int VerticalTextOffset;
	if (PC.bSeamlessTravelDestinationLoaded)
	{
		LaunchButton.bIsVisible = true;
		if( `ISCONTROLLERACTIVE )
		{
			CurrentLanguage = GetLanguage();

			if(CurrentLanguage == "KOR")
				VerticalTextOffset = -19;

			else if(CurrentLanguage == "CHT")
				VerticalTextOffset = -17;

			else if(CurrentLanguage == "CHN")
				VerticalTextOffset = -20;

			else
				VerticalTextOffset = -14;
			FinalLaunchStr = Repl(m_strConsolePressKeyToContinue, "%A", class 'UIUtilities_Input'.static.HTML(class 'UIUtilities_Input'.static.GetAdvanceButtonIcon(),24, VerticalTextOffset));
			MC.FunctionString("updateLaunch", FinalLaunchStr);
		}
		else
		{
			MC.FunctionString("updateLaunch", m_strPressKeyToContinue);
		}
		SetTimer(0.0f);
	}
	else
	{
		TipCycle = (TipCycle + 1) % 10;
		if (TipCycle == 0)
		{
			MC.FunctionString("updateTip", GetTip(eTip_Strategy));
		}
	}
}

DefaultProperties
{
	Package   = "/ package/gfxDropshipBriefing/DropshipBriefing";
	LibID = "DropshipPostMission";
}