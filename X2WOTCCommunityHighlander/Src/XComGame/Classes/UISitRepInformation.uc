//---------------------------------------------------------------------------------------
//  FILE:    UISitRepInformation.uc
//  AUTHOR:  Joe Weinhoffer --  9/6/2016
//  PURPOSE: Screen for displaying information about a specific mission's sitreps.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UISitRepInformation extends UIX2SimpleScreen;

var public localized String m_strTitle;
var public localized String m_strBaseDifficultyLabel;
var public localized String m_strTotalDifficultyLabel;
var public localized String m_strDetailsLabel;
var public localized String m_strAdjustmentLabel;
var public localized String m_strDarkEventsLabel;

var StateObjectReference MissionRef;
var GeneratedMissionData MissionData;

//-------------- UI LAYOUT --------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	MissionData = XCOMHQ().GetGeneratedMissionData(MissionRef.ObjectID);
	if (MissionData.SitReps.Length == 0)
	{
		`Redscreen("SitRepInformation screen could not find any SITREP data for the mission! @jweinhoffer");
	}

	BuildScreen();
}

function BuildScreen()
{
	local XComGameState_MissionSite MissionSite;
	
	MissionSite = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionRef.ObjectID));

	MC.BeginFunctionOp("SetTitleData");
	MC.QueueString(m_strTitle);
	MC.QueueString(MissionData.BattleOpName);
	MC.QueueString(m_strBaseDifficultyLabel);
	MC.QueueNumber(MissionSite.GetMissionDifficulty());
	MC.QueueString(m_strDetailsLabel);
	MC.QueueString(m_strAdjustmentLabel);
	MC.QueueNumber(MissionSite.GetMissionDifficulty(true));
	MC.EndOp();

	MC.BeginFunctionOp("SetDifficultyTotal");
	MC.QueueString(MissionSite.GetMissionDifficultyLabel(true));
	MC.QueueString(m_strTotalDifficultyLabel);
	MC.QueueString(string(MissionSite.GetMissionDifficulty()));
	MC.QueueNumber(MissionSite.GetMissionDifficulty(true));
	MC.EndOp();

	UpdateSitRepData();
	UpdateDarkEventList();

	RefreshNav();

	MC.FunctionVoid("AnimateIn");
}

function UpdateSitRepData()
{
	local X2SitRepTemplateManager SitRepManager;
	local X2SitRepEffectTemplateManager SitRepEffectManager;
	local X2SitRepTemplate SitRepTemplate;
	local X2SitRepEffectTemplate SitRepEffectTemplate;
	local name SitRepName;
	local int idx, AdjustmentRow;
		
	SitRepManager = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();
	SitRepEffectManager = class'X2SitRepEffectTemplateManager'.static.GetSitRepEffectTemplateManager();
	AdjustmentRow = 0;
	
	foreach MissionData.SitReps(SitRepName)
	{
		SitRepTemplate = SitRepManager.FindSitRepTemplate(SitRepName);
		if (SitRepTemplate != none)
		{
			
			MC.BeginFunctionOp("SetSitRepRow");
			MC.QueueNumber(0);
			MC.QueueString(SitRepTemplate.GetFriendlyName());
			MC.QueueString(SitRepTemplate.GetDescriptionExpanded()); // Issue #566
			MC.QueueString("");
			MC.EndOp();

			for (idx = 0; idx < SitRepTemplate.DisplayEffects.Length; idx++)
			{
				SitRepEffectTemplate = SitRepEffectManager.FindSitRepEffectTemplate(SitRepTemplate.DisplayEffects[idx]);

				MC.BeginFunctionOp("SetAdjustmentRow");
				MC.QueueNumber(AdjustmentRow);
				MC.QueueString(SitRepEffectTemplate.GetFriendlyName());
				MC.QueueString(SitRepEffectTemplate.GetDescriptionExpanded()); // Issue #566
				MC.QueueString(string(SitRepEffectTemplate.DifficultyModifier));
				MC.EndOp();

				AdjustmentRow++;
			}
		}
	}
}

function UpdateDarkEventList()
{
	local XComGameState_ObjectivesList ObjectiveListState;
	local string DarkEventsList;

	ObjectiveListState = XComGameState_ObjectivesList(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_ObjectivesList'));
	DarkEventsList = ObjectiveListState.GetActiveDarkEventsString();

	if(DarkEventsList != "")
	{
		MC.BeginFunctionOp("SetDarkEventData");
		MC.QueueString(m_strDarkEventsLabel);
		MC.QueueString(DarkEventsList);
		MC.EndOp();
	}
}

simulated function RefreshNav()
{
	local UINavigationHelp NavHelp;
	
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();
	
	// Carry On
	NavHelp.AddBackButton(OnContinueClicked);
}

simulated function CloseScreen()
{	
	super.CloseScreen();

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnContinueClicked()
{
	CloseScreen();
}


//-------------- GAME DATA HOOKUP --------------------------------------------------------

defaultproperties
{
	Package = "/ package/gfxXPACK_SitRep/XPACK_SitRep";
	bConsumeMouseEvents = true;
}