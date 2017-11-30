//---------------------------------------------------------------------------------------
//  FILE:    X2HackRewardTemplateManager.uc
//  AUTHOR:  Dan Kaplan - 11/11/2014
//  PURPOSE: Template manager for Hack Rewards in X-Com 2.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2HackRewardTemplateManager extends X2DataTemplateManager
	native(Core) config(GameCore);

var const name HackAbilityEventName;

native static function X2HackRewardTemplateManager GetHackRewardTemplateManager();

function bool AddHackRewardTemplate(X2HackRewardTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2HackRewardTemplate FindHackRewardTemplate(Name DataName)
{
	local X2DataTemplate HackRewardTemplate;

	HackRewardTemplate = FindDataTemplate(DataName);

	if( HackRewardTemplate != None )
	{
		return X2HackRewardTemplate(HackRewardTemplate);
	}

	return None;
}

static function array<name> SelectHackRewards(array<name> PossibleHackRewards)
{
	local X2HackRewardTemplateManager TemplateMan;
	local X2HackRewardTemplate Template;
	local array<X2HackRewardTemplate> TempTemplates;
	local array<name> FinalTemplates;
	local array<int> Scores;
	local int i, j, Score;

	//  Only one reward per MinHackSuccess value is allowed, for any template marked as bRandomReward.
	//  Search through all possible rewards, group the ones with the same score, and pick one at random.

	TemplateMan = static.GetHackRewardTemplateManager();
	for (i = 0; i < PossibleHackRewards.Length; ++i)
	{
		TempTemplates.Length = 0;
		Template = TemplateMan.FindHackRewardTemplate(PossibleHackRewards[i]);
		if (Template == none)
			continue;

		if (!Template.bRandomReward)
		{
			FinalTemplates.AddItem(Template.DataName);
			continue;
		}

		if (Scores.Find(Template.MinHackSuccess) != INDEX_NONE)
			continue;

		Score = Template.MinHackSuccess;
		Scores.AddItem(Score);
		TempTemplates.AddItem(Template);
		for (j = i + 1; j < PossibleHackRewards.Length; ++j)
		{
			Template = TemplateMan.FindHackRewardTemplate(PossibleHackRewards[j]);
			if (Template == none || !Template.bRandomReward || Template.MinHackSuccess != Score)
				continue;

			TempTemplates.AddItem(Template);
		}
		if (TempTemplates.Length == 1)
			FinalTemplates.AddItem(TempTemplates[0].DataName);
		else
			FinalTemplates.AddItem(TempTemplates[`SYNC_RAND_STATIC(TempTemplates.Length)].DataName);
	}

	return FinalTemplates;
}

static function bool AcquireHackRewards(
	UIHackingScreen HackingScreen,
	XComGameState_Unit Hacker, 
	XComGameState_BaseObject HackTarget, 
	int RolledHackScore, 
	XComGameState NewGameState, 
	Name HackAbilityTemplateName,
	out int UserSelectedReward,
	optional int HackingScreen_SelectedHackRewardOption,
	optional float HackingScreen_HackChance)
{
	local X2HackRewardTemplateManager TemplateMan;
	local X2HackRewardTemplate Template, FeedbackTemplate;
	local array<X2HackRewardTemplate> Templates;
	local name TemplateName;
	local int i;
	local bool HackWasASuccess;
	local array<Name> PossibleHackRewards;
	local bool AttemptedBestHack;
	local XComGameState_Unit HackTargetUnit;
	local int SelectedHackRewardOption;
	local float HackChance;

	HackWasASuccess = false;
	UserSelectedReward = 0;
	TemplateMan = static.GetHackRewardTemplateManager();

	PossibleHackRewards = Hackable(HackTarget).GetHackRewards(HackAbilityTemplateName);

	// Add check for Hacking screen being none
	// pass the needed values for a none screen
	if( HackingScreen == none )
	{
		SelectedHackRewardOption = HackingScreen_SelectedHackRewardOption;
	}
	else
	{
		SelectedHackRewardOption = HackingScreen.SelectedHackRewardOption;
	}

	if( SelectedHackRewardOption == PossibleHackRewards.Length - 1 ) //Assumption: best hack is last
		AttemptedBestHack = true;
	else
		AttemptedBestHack = false;

	//  Move all rewards that were actually earned into the Templates.
	for(i = 0; i < PossibleHackRewards.Length; ++i)
	{
		if( i == 0 || i == SelectedHackRewardOption)
		{
			TemplateName = PossibleHackRewards[i];
			Template = TemplateMan.FindHackRewardTemplate(TemplateName);
			`assert( Template != none );

			if( HackingScreen == none )
			{
				HackChance = HackingScreen_HackChance;
			}
			else
			{
				HackChance = HackingScreen.GetHackChance(i);
			}

			if( i == 0 && Template.bBadThing )
			{
				FeedbackTemplate = Template;
			}
			else if( RolledHackScore < HackChance )
			{
				Templates.AddItem(Template);

				if (i == SelectedHackRewardOption)
					UserSelectedReward = SelectedHackRewardOption;
			}
		}
	}

	// award feedback if nothing else was selected
	if( Templates.Length == 0 && FeedbackTemplate != None )
	{
		Templates.AddItem(FeedbackTemplate);
	}

	//  Now we have all rewards that were not replaced by something better. Award those.
	foreach Templates(Template)
	{
		Template.OnHackRewardAcquired(Hacker, HackTarget, NewGameState);

		HackWasASuccess = HackWasASuccess || !Template.bResultsInHackFailure;
	}

	// Achievement: Hack a Sectopod
	if (`XENGINE.IsSinglePlayerGame() && !(`ONLINEEVENTMGR.bIsChallengeModeGame))
	{
	if (HackTarget != none)
	{
		HackTargetUnit = XComGameState_Unit(HackTarget);
		if( HackTargetUnit != None && HackTargetUnit.GetMyTemplate().CharacterGroupName == 'Sectopod' )
		{
			if (HackWasASuccess)
			{
				`ONLINEEVENTMGR.UnlockAchievement(AT_Hacker);
			}
		}
	}

	// Achievement: Earning the best hack reward
	if (HackWasASuccess && (UserSelectedReward != 0) && AttemptedBestHack)
	{
		`ONLINEEVENTMGR.UnlockAchievement(AT_HackGain3Rewards);
	}
	}

	return HackWasASuccess;
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2HackReward'
	HackAbilityEventName="HackTrigger"
}