//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_DarkEvent.uc
//  AUTHOR:  Mark Nauta
//         
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_DarkEvent extends XComGameState_BaseObject
	dependson(X2StrategyGameRulesetDataStructures)
	config(GameData);

var() protected name                   m_TemplateName;
var() protected X2DarkEventTemplate    m_Template;

var int								   Weight;
var int								   TimesPlayed;
var int								   TimesSucceeded;
var bool							   bSecretEvent;
var bool							   bChosenActionEvent;
var StateObjectReference			   ChosenRef;
var TDateTime						   StartDateTime;
var TDateTime						   EndDateTime;
var float							   TimeRemaining;
var StrategyCost					   RevealCost;

// Issue #596
/// HL-Docs: feature:TemporarilyBlockDarkEventActivation; issue:597; tags:strategy
/// While this flag is turned on, the dark event cannot activate/complete (transition from preparing to active)
/// and will simply "wait" until this flag is turned off. Another possible way of looking at it 
/// is that the DE is postponed indefinitely while this flag is active but only if the EndDateTime was reached.
/// HL-Include:
var bool							   bTemporarilyBlockActivation;
///

var localized string				   SecretTitle;
var localized string				   SecretSummary;
var localized string				   SecretPreMissionText;

var config string					   SecretImagePath;
var config array<int>				   StartingIntelCost;
var config array<int>				   IntelCostIncrease;

// #######################################################################################
// -------------------- INITIALIZATION ---------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

//---------------------------------------------------------------------------------------
simulated function X2DarkEventTemplate GetMyTemplate()
{
	if(m_Template == none)
	{
		m_Template = X2DarkEventTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
event OnCreation(optional X2DataTemplate InitTemplate)
{
	super.OnCreation( InitTemplate );

	m_Template = X2DarkEventTemplate(InitTemplate);
	m_TemplateName = m_Template.DataName;
	Weight = m_Template.StartingWeight;
}

//---------------------------------------------------------------------------------------
static function SetUpDarkEvents(XComGameState StartState)
{
	local array<X2StrategyElementTemplate> DarkEventTemplates;
	local int idx;

	// Grab all DarkEvent Templates
	DarkEventTemplates = GetMyTemplateManager().GetAllTemplatesOfClass(class'X2DarkEventTemplate');

	// Iterate through the templates and build each DarkEvent State Object
	for(idx = 0; idx < DarkEventTemplates.Length; idx++)
	{
		StartState.CreateNewStateObject(class'XComGameState_DarkEvent', DarkEventTemplates[idx]);
	}
}

// #######################################################################################
// -------------------- DISPLAY FUNCTIONS ------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function string GetDisplayName()
{
	if(bSecretEvent)
	{
		return SecretTitle;
	}

	return GetMyTemplate().DisplayName;
}

//---------------------------------------------------------------------------------------
function string GetSummary()
{
	local XGParamTag ParamTag;
	local array<StrategyCostScalar> CostScalars;

	if(bSecretEvent)
	{
		CostScalars.Length = 0;
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		ParamTag.StrValue0 = class'UIUtilities_Strategy'.static.GetStrategyCostString(RevealCost, CostScalars);
		return `XEXPAND.ExpandString(SecretSummary);
	}

	if(GetMyTemplate().GetSummaryFn != none)
	{
		return GetMyTemplate().GetSummaryFn(GetMyTemplate().SummaryText);
	}

	return GetMyTemplate().SummaryText;
}
//---------------------------------------------------------------------------------------
function string GetCost()
{
	local array<StrategyCostScalar> CostScalars;

	if(bSecretEvent)
	{
		CostScalars.Length = 0;
		return class'UIUtilities_Strategy'.static.GetStrategyCostString(RevealCost, CostScalars);
	}

	return "";
}
//---------------------------------------------------------------------------------------
function string GetQuote()
{
	if(bSecretEvent)
	{
		return "";
	}

	return GetMyTemplate().QuoteText;
}
//---------------------------------------------------------------------------------------
function string GetQuoteAuthor()
{
	if(bSecretEvent)
	{
		return "";
	}

	return GetMyTemplate().QuoteTextAuthor;
}
//---------------------------------------------------------------------------------------
function string GetPreMissionText()
{
	if(bSecretEvent)
	{
		return SecretPreMissionText;
	}

	if(GetMyTemplate().GetPreMissionTextFn != none)
	{
		return GetMyTemplate().GetPreMissionTextFn(GetMyTemplate().PreMissionText);
	}

	return GetMyTemplate().PreMissionText;
}

//---------------------------------------------------------------------------------------
function string GetPostMissionText(bool bSuccess)
{
	if(bSuccess)
	{
		return GetMyTemplate().PostMissionSuccessText;
	}

	return GetMyTemplate().PostMissionFailureText;
}

//---------------------------------------------------------------------------------------
function string GetImage()
{
	if(bSecretEvent)
	{
		return SecretImagePath;
	}

	return GetMyTemplate().ImagePath;
}

// #######################################################################################
// -------------------- ACTIVATION/DEACTIVATION ------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function OnActivated(XComGameState NewGameState)
{
	// Reveal the Event
	bSecretEvent = false;
	RevealCost.ResourceCosts.Length = 0;
	RevealCost.ArtifactCosts.Length = 0;

	if(GetMyTemplate().OnActivatedFn != none)
	{
		GetMyTemplate().OnActivatedFn(NewGameState, self.GetReference());
	}
	RevealObjectiveUI(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_DarkEventsCompleted');
}

//---------------------------------------------------------------------------------------
function OnDeactivated(XComGameState NewGameState)
{
	// Issue #753
	//
	/// HL-Docs: feature:PreDarkEventDeactivated; issue:753; tags:strategy
	/// Notifies listeners of when a dark event has expired/been deactivated. This
	/// event fires before the dark event's deactivation code runs, so register an
	/// ELD_Immediate listener if you want access to the state before that happens,
	/// or an ELD_OnStateSubmitted listener if you want the state *after* the full
	/// deactivation.
	///
	/// ```event
	/// EventID: PreDarkEventDeactivated,
	/// EventData: XComGameState_DarkEvent (EventState),
	/// EventSource: XComGameState_DarkEvent,
	/// NewGameState: yes
	/// ```
	`XEVENTMGR.TriggerEvent('PreDarkEventDeactivated', self, self, NewGameState);
	// End Issue #753

	if(GetMyTemplate().OnDeactivatedFn != none)
	{
		GetMyTemplate().OnDeactivatedFn(NewGameState, self.GetReference());
	}
	DeactivateObjectiveUI(NewGameState);
	bChosenActionEvent = false;
	ChosenRef.ObjectID = 0;
}

//---------------------------------------------------------------------------------------
function bool CanActivate()
{
	// Event is non-repeatable and has already been activated
	if(!GetMyTemplate().bRepeatable && TimesSucceeded > 0)
	{
		return false;
	}

	// Event is repeatable but has activated its max amount of times
	if((GetMyTemplate().bRepeatable) && (GetMyTemplate().MaxSuccesses > 0) && (TimesSucceeded >= GetMyTemplate().MaxSuccesses))
	{
		return false;
	}

	// Check template specific function
	if(GetMyTemplate().CanActivateFn != none)
	{
		return GetMyTemplate().CanActivateFn(self);
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool CanComplete()
{
	if(GetMyTemplate().CanCompleteFn != none)
	{
		return GetMyTemplate().CanCompleteFn(self);
	}

	return true;
}

// #######################################################################################
// -------------------- TIMER HELPERS ----------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function StartActivationTimer(optional MinMaxDays ActivationTime)
{
	local int HoursToAdd, MinDays, MaxDays;

	StartDateTime = `STRATEGYRULES.GameTime;
	EndDateTime = StartDateTime;

	if(ActivationTime.MaxDays > 0)
	{
		MinDays = ActivationTime.MinDays;
		MaxDays = ActivationTime.MaxDays;
	}
	else
	{
		MinDays = GetMyTemplate().MinActivationDays;
		MaxDays = GetMyTemplate().MaxActivationDays;
	}

	HoursToAdd = (MinDays * 24) + `SYNC_RAND_STATIC((MaxDays * 24) - (MinDays * 24) + 1);

	class'X2StrategyGameRulesetDataStructures'.static.AddHours(EndDateTime, HoursToAdd);
	TimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(EndDateTime, StartDateTime);
}

//---------------------------------------------------------------------------------------
// Helper for Hack Rewards to modify duration
function ExtendActivationTimer(int ExtraHours)
{
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(EndDateTime, ExtraHours);
	TimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(EndDateTime, StartDateTime);
}

//---------------------------------------------------------------------------------------
// Helper for Expired GOps to modify duration
function DecreaseActivationTimer(int ExtraHours)
{
	class'X2StrategyGameRulesetDataStructures'.static.RemoveHours(EndDateTime, ExtraHours);
	TimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(EndDateTime, StartDateTime);
}

//---------------------------------------------------------------------------------------
function StartDurationTimer(optional int DurationHours = 0)
{
	local int HoursToAdd;

	StartDateTime = `STRATEGYRULES.GameTime;
	EndDateTime = StartDateTime;

	if (DurationHours > 0)
	{
		HoursToAdd = DurationHours;
	}
	else
	{
		HoursToAdd = (GetMyTemplate().MinDurationDays * 24) + `SYNC_RAND_STATIC((GetMyTemplate().MaxDurationDays * 24) - (GetMyTemplate().MinDurationDays * 24) + 1);
	}

	class'X2StrategyGameRulesetDataStructures'.static.AddHours(EndDateTime, HoursToAdd);
	TimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(EndDateTime, StartDateTime);
}

//---------------------------------------------------------------------------------------
function PauseTimer()
{
	// Update Time remaining and set end time to unreachable future
	TimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(EndDateTime, `STRATEGYRULES.GameTime);
	EndDateTime.m_iYear = 9999;
}

//---------------------------------------------------------------------------------------
function ResumeTimer()
{
	// Update the start time then calculate the end time using the time remaining
	StartDateTime = `STRATEGYRULES.GameTime;
	EndDateTime = StartDateTime;

	class'X2StrategyGameRulesetDataStructures'.static.AddTime(EndDateTime, TimeRemaining);
}

// #######################################################################################
// -------------------- REVEAL COST ------------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function SetRevealCost()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local ArtifactCost IntelCost;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	RevealCost.ResourceCosts.Length = 0;
	IntelCost.ItemTemplateName = 'Intel';
	IntelCost.Quantity = `ScaleStrategyArrayInt(default.StartingIntelCost) + (ResistanceHQ.NumMonths * `ScaleStrategyArrayInt(default.IntelCostIncrease));
	RevealCost.ResourceCosts.AddItem(IntelCost);
}

//---------------------------------------------------------------------------------------
function RevealEvent(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StrategyCostScalar> CostScalars;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	CostScalars.Length = 0;
	XComHQ.PayStrategyCost(NewGameState, RevealCost, CostScalars);

	bSecretEvent = false;
	RevealCost.ResourceCosts.Length = 0;
	RevealCost.ArtifactCosts.Length = 0;
}


// #######################################################################################
// -------------------- REVEAL OBJECTIVE UI ----------------------------------------------
// #######################################################################################

function RevealObjectiveUI(XComGameState NewGameState)
{
	local ObjectiveDisplayInfo ObjDisplayInfo;
	local XComGameStateHistory History;
	local XComGameState_ObjectivesList ObjListState;

	if( bSecretEvent )
	{
		return;
	}

	if( !GetMyTemplate().bNeverShowObjective )
	{
		History = `XCOMHISTORY;

			foreach NewGameState.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
		{
				break;
			}

		if( ObjListState == None )
		{
			foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
			{
				break;
			}

			if( ObjListState != none )
			{
				ObjListState = XComGameState_ObjectivesList(NewGameState.ModifyStateObject(class'XComGameState_ObjectivesList', ObjListState.ObjectID));
			}
			else
			{
				ObjListState = XComGameState_ObjectivesList(NewGameState.CreateNewStateObject(class'XComGameState_ObjectivesList'));
			}
		}

		ObjDisplayInfo.ShowHeader = false;
		ObjDisplayInfo.ShowCheckBox = false;
		ObjDisplayInfo.bIsDarkEvent = true;
		ObjDisplayInfo.MissionType = "DARKEVENTOBJECTIVE";

		ObjDisplayInfo.GroupID = ObjectID;
		ObjDisplayInfo.DisplayLabel = GetDisplayName();
		ObjDisplayInfo.HideInTactical = true;
		ObjDisplayInfo.GPObjective = true;
		ObjDisplayInfo.ObjectiveTemplateName = GetMyTemplateName();
		ObjListState.SetObjectiveDisplay(ObjDisplayInfo);

		class'X2StrategyGameRulesetDataStructures'.static.UpdateObjectivesUI(NewGameState);
	}
}

function DeactivateObjectiveUI(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_ObjectivesList ObjListState;

	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
	{
		break;
	}

	if( ObjListState == None )
	{
		foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
		{
			break;
		}

		if( ObjListState != none )
		{
			ObjListState = XComGameState_ObjectivesList(NewGameState.ModifyStateObject(class'XComGameState_ObjectivesList', ObjListState.ObjectID));
		}
		else
		{
			ObjListState = XComGameState_ObjectivesList(NewGameState.CreateNewStateObject(class'XComGameState_ObjectivesList'));
		}
	}

	ObjListState.HideObjectiveDisplay("DARKEVENTOBJECTIVE", GetDisplayName());
	class'X2StrategyGameRulesetDataStructures'.static.UpdateObjectivesUI(NewGameState);
}


DefaultProperties
{
}