//---------------------------------------------------------------------------------------
//  FILE:    X2EventListener_DefaultWillEvents.uc
//  AUTHOR:  David Burchanowski
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameStateContext_WillRoll extends XComGameStateContext
	config(GameCore)
	native(Core);

enum WillEventRoll_StatType
{
	WillEventRollStat_None,
	WillEventRollStat_PercentageHealthLost,
	WillEventRollStat_SquadmateRank,
	WillEventRollStat_MaxWill,
	WillEventRollStat_BondLevel,
	WillEventRollStat_Flat
};

struct native WillEventRollData_PanicWeight
{
	var name PanicAbilityName;
	var float Weight; // 0.0-1.0

	structdefaultproperties
	{
		Weight = 1
	}
};

// This structure provides a simple uniform mechanism for doing rolls to lose will
struct native WillEventRollData
{
	var EMentalState MinimumTiredState;  // this will data will not be applied to units that are less fatigued than this state
	var float WillEventActivationChance;  // if all other conditions are met, this is the chance that this will event should actually modify will/roll on panic
	var name WillEventActivationType;	// if non-none, will events of this type are restricted to only happening once per unit per mission

	// values for determining how much will to lose
	var float WillLossChance;    // chance to lose will.  
	var bool FlatWillLossChance; // if true, will do a straight roll against WillLossChance, if false rolls against WillLossChance - eStat_Will

	// calculated will loss is the value of the chosen WillLossStat *  WillLossStatMultiplier.
	// the final will loss is max(<calculated will loss>, MinimumWillLoss)
	var WillEventRoll_StatType WillLossStat;
	var float WillLossStatMultiplier;
	var int MinimumWillLoss;

	var float MaxWillPercentageLostPerMission; // if > 0, will will only be lost up to this percentage of the unit's max will
	var bool CanZeroOutWill; // if false, will always leave at least 1 will remaining

	// When a unit loses will, a roll will be made against PanicChance. If the roll passes,
	// one of the abilities in PanicWeights will be selected.
	var float PanicChance; // 0.0-1.0f, will be further reduced by a unit's will
	var array<WillEventRollData_PanicWeight> PanicWeights;

	structdefaultproperties
	{
		MinimumTiredState = eMentalState_Ready
		WillEventActivationChance = 1.0
	}
};

// text that appears above soldier's head when he loses will from a will event
var localized const string LostWillFlyover;
var localized const string LostWillWorldMessage;
var localized const string DefaultLossSource;
var localized const string PanicTestCaption;
var localized const string PanicResultFlyover;
var localized const string PanicResultWorldMessage;
var localized const string ResistedText;

// Percentage of will to lose per bond level when checking WillEventRollStat_BondLevel
var protected const config array<float>      BondLevelWillLoss;

// the reduction in will loss when this soldier is on a mission with his bondmate
var protected const config float SoldierBondWillReductionMultiplier;

// If a soldier does a "normal" panic ability more than once, reroll using the values in this table
var protected const config array<WillEventRollData_PanicWeight> MultiplePanicAltWeights;

// It's possible to do multiple rolls per context, so keep track of the running total here.
var privatewrite int RunningWillLossTotal;

// the type of will event being conducted
var privatewrite name WillEventType;

// It's possible to get multiple panic results from different rolls, so just use the most recent one
var privatewrite name PanicAbilityName;

// The unit we are performing the roll on.
var privatewrite XComGameState_Unit SourceUnit;
// The target id our source unit is rolling against.  
var privatewrite int TargetUnitID;

// Localized friendly name of the roll source. Ex. "Fear of Missing Shots"
var protectedwrite string RollSourceFriendly;
var protectedwrite name RollSource;

// If true, will show flyovers and world messages 
var protectedwrite bool ShowMessages;

// If the target unit is affected by any of these Effects, skip the panic roll
var protected const config array<name>      SkipPanicTestWhenAfflictedByEffects;

//////////////////////////////////////////////////////////////////////////////////

static event bool ShouldPerformWillRoll(const out WillEventRollData RollInfo, XComGameState_Unit AffectedUnit)
{
	if( AffectedUnit == none )
	{
		return false;
	}

	// skip this test on any dead, or evacuated units
	if( AffectedUnit.IsDead() || 
	   AffectedUnit.IsInStasis() ||
	   AffectedUnit.bRemovedFromPlay )
	{
		return false;
	}

	// raw random chance to skip this activation
	if( `SYNC_FRAND_STATIC() >= RollInfo.WillEventActivationChance )
	{
		return false;
	}

	return true;
}

static function bool ShouldPerformPanicRoll(const out WillEventRollData RollInfo, XComGameState_Unit AffectedUnit)
{
	local name TestEffect;

	if( RollInfo.PanicChance <= 0.0 )
	{
		return false;
	}

	// restrict rolling on will while panicked
	if( !AffectedUnit.IsAbleToAct() )
	{
		return false;
	}

	// restrict by the units current fatigue state
	if( AffectedUnit.GetMentalState() > RollInfo.MinimumTiredState )
	{
		return false;
	}

	// restrict panic checks to once per turn
	if( AffectedUnit.PanicTestsPerformedThisTurn > 0 )
	{
		return false;
	}

	// restrict if the unit has already rolled on this event type this mission
	if( RollInfo.WillEventActivationType != '' && AffectedUnit.WillEventsActivatedThisMission.Find(RollInfo.WillEventActivationType) != INDEX_NONE )
	{
		return false;
	}

	// Avoid panic tests on units affected by certain status effects
	foreach default.SkipPanicTestWhenAfflictedByEffects(TestEffect)
	{
		if( AffectedUnit.AffectedByEffectNames.Find(TestEffect) != INDEX_NONE )
		{
			return false;
		}
	}

	// skip the roll for panic for any condition that would fail a panic ability
	if( class'X2Condition_Panic'.static.StaticCallMeetsCondition(AffectedUnit) != 'AA_Success' )
	{
		return false;
	}

	return true;
}


// "SquadmateUnit" needs to be supplied when doing rolls against squadmate rank
event DoWillRoll(WillEventRollData RollInfo, optional XComGameState_Unit SquadmateUnit)
{
	if( SquadmateUnit == None )
	{
		SquadmateUnit = SourceUnit;
	}

	TargetUnitID = SquadmateUnit.ObjectID;

	WillEventType = RollInfo.WillEventActivationType;

	CalculateWillRoll(RollInfo, SquadmateUnit, SourceUnit, RollSource, RunningWillLossTotal, PanicAbilityName);

	if( ShouldPerformPanicRoll(RollInfo, SquadmateUnit) )
	{
		// also make a panic roll
		DoPanicRoll(SquadmateUnit, RunningWillLossTotal, RollInfo.PanicChance, RollInfo.PanicWeights, false, PanicAbilityName);
	}
	else
	{
		// never show messages if there was no panic roll
		ShowMessages = false;
	}
}

static function PerformWillRollOnUnitForNewGameState(WillEventRollData RollInfo, XComGameState_Unit InSourceUnit, name InRollSource, XComGameState NewGameState)
{
	local int RunningWillLoss;
	local name PanicAbility;
	local XComGameState_Unit NewSourceUnitState;

	CalculateWillRoll(RollInfo, None, InSourceUnit, InRollSource, RunningWillLoss, PanicAbility);

	NewSourceUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', InSourceUnit.ObjectId));
	NewSourceUnitState.ModifyCurrentStat(eStat_Will, -RunningWillLoss);
	++NewSourceUnitState.PanicTestsPerformedThisTurn;

	if( RollInfo.WillEventActivationType != '' && NewSourceUnitState.WillEventsActivatedThisMission.Find(RollInfo.WillEventActivationType) == INDEX_NONE )
	{
		NewSourceUnitState.WillEventsActivatedThisMission.AddItem(RollInfo.WillEventActivationType);
	}
}

static function CalculateWillRoll(WillEventRollData RollInfo, XComGameState_Unit SquadmateUnit, XComGameState_Unit InSourceUnit, name InRollSource, out int InRunningWillLossTotal, out name InPanicAbilityName)
{
	local XComGameStateHistory History;
	local XComGameState_Unit StartOfMissionUnit;
	local bool ShouldLoseWill;
	local float CalculatedWillLoss;
	local int WillLossOverage;
	local float WillLossRemainder;
	local int CurrentWill; // current will, including the running loss total
	local int MaximumWillLossPerMission;
	local int MinimumAllowedWill;
	local SoldierBond BondData;
	local bool bBondmateOnMission;
	local StateObjectReference BondmateRef;
	local XComGameState_BattleData BattleDataState;
	local X2SitRepEffect_ModifyWillPenalties SitRepEffect;
	local float SitRepWillLossScalar;

	if( InSourceUnit.IsDead()
		|| InSourceUnit.IsIncapacitated()
		|| InSourceUnit.IsMindControlled())
	{
		return;
	}

	if( InSourceUnit.UsesWillSystem())
	{
		if(RollInfo.FlatWillLossChance)
		{
			ShouldLoseWill = class'Engine'.static.SyncFRand("DoWillRoll") < RollInfo.WillLossChance;
		}
		else
		{
			ShouldLoseWill = class'Engine'.static.SyncFRand("DoWillRoll") < RollInfo.WillLossChance - (InSourceUnit.GetCurrentStat(eStat_Will) * 0.01f);
		}
	}

	if(ShouldLoseWill) 
	{
		bBondmateOnMission = InSourceUnit.HasSoldierBond(BondmateRef, BondData) && `XCOMHQ.IsUnitInSquad(BondmateRef);

		// determine how much will we want to lose
		switch(RollInfo.WillLossStat)
		{
		case WillEventRollStat_None:
			CalculatedWillLoss = 0;
			break;
		case WillEventRollStat_PercentageHealthLost:
			CalculatedWillLoss = InSourceUnit.GetCurrentStat(eStat_HP) / InSourceUnit.GetMaxStat(eStat_HP);
			break;
		case WillEventRollStat_SquadmateRank:
			assert(SquadmateUnit != none);
			CalculatedWillLoss = SquadmateUnit.GetSoldierRank();
			break;
		case WillEventRollStat_MaxWill:
			CalculatedWillLoss = InSourceUnit.GetMaxStat(eStat_Will);
			break;
		case WillEventRollStat_BondLevel:
			if( bBondmateOnMission )
			{
				if(BondData.BondLevel < 0 || BondData.BondLevel > default.BondLevelWillLoss.Length)
				{
					`Redscreen("DoWillRoll(): " $ InSourceUnit.GetFullName() $ "has an unexpected bond level " $ BondData.BondLevel);
					BondData.BondLevel = 0;
				}
				CalculatedWillLoss = InSourceUnit.GetMaxStat(eStat_Will) * default.BondLevelWillLoss[BondData.BondLevel];
			}
			break;
		default:
			`assert(false);
		}

		// Gather sitrep granted abilities
		BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		SitRepWillLossScalar = 1.0f;
		if (BattleDataState != none)
		{
			foreach class'X2SitreptemplateManager'.static.IterateEffects(class'X2SitRepEffect_ModifyWillPenalties', SitRepEffect, BattleDataState.ActiveSitReps)
			{
				if ((SitRepEffect.WillEventNames.Length == 0) || (SitRepEffect.WillEventNames.Find(InRollSource) != INDEX_NONE))
				{
					SitRepWillLossScalar *= SitRepEffect.ModifyScalar;
				}
			}
		}

		CalculatedWillLoss = (CalculatedWillLoss * RollInfo.WillLossStatMultiplier * SitRepWillLossScalar);

		if( bBondmateOnMission )
		{
			CalculatedWillLoss *= default.SoldierBondWillReductionMultiplier;
		}

		// if we have a remainder, roll on it for an extra integer point
		WillLossRemainder = CalculatedWillLoss % 1.0f;
		if(class'Engine'.static.SyncFRand("DoWillRoll") < WillLossRemainder)
		{
			CalculatedWillLoss += 1;
		}

		// make sure we are taking at least the minimum amount
		CalculatedWillLoss = max(int(CalculatedWillLoss), RollInfo.MinimumWillLoss);

		// since the history hasn't been updated yet, add in the will loss from previous rolls
		CurrentWill = InSourceUnit.GetCurrentStat(eStat_Will) - InRunningWillLossTotal;

		// and determine if we have any lower floor on how much will we are allowed to lose in the mission.
		// by default, we can go all the way to zero
		MinimumAllowedWill = 0;
		if(!RollInfo.CanZeroOutWill)
		{
			// don't allow dropping below 1
			MinimumAllowedWill = 1;
		}

		if(RollInfo.MaxWillPercentageLostPerMission > 0)
		{
			// get the unit's will at the start of the mission
			History = `XCOMHISTORY;
			StartOfMissionUnit = XComGameState_Unit(History.GetGameStateForObjectID(InSourceUnit.ObjectID,, History.FindStartStateIndex()));
			MaximumWillLossPerMission = RollInfo.MaxWillPercentageLostPerMission * InSourceUnit.GetMaxStat(eStat_Will);
			MinimumAllowedWill = max(MinimumAllowedWill, StartOfMissionUnit.GetCurrentStat(eStat_Will) - MaximumWillLossPerMission);
		}

		// now that we know our lower floor, make sure we won't drop below the minimum
		WillLossOverage = CurrentWill - (CalculatedWillLoss + MinimumAllowedWill);
		CalculatedWillLoss -= Max(0, -WillLossOverage);

		// add in the loss for this roll to the running total
		InRunningWillLossTotal += CalculatedWillLoss;
	}
}

static function DoPanicRoll(XComGameState_Unit InSourceUnit, int InRunningWillLossTotal, float PanicChance, array<WillEventRollData_PanicWeight> PanicWeights, bool Reroll, out name InPanicAbilityName)
{
	local int CurrentWill;
	local float PanicRoll;
	local WillEventRollData_PanicWeight PanicWeight;
	local float TotalPanicWeight;

	CurrentWill = InSourceUnit.GetCurrentStat(eStat_Will) - InRunningWillLossTotal;

	PanicRoll = `SYNC_FRAND_STATIC("DoWillRoll");
	if((PanicRoll < (PanicChance - (CurrentWill * 0.01))) 
		|| CurrentWill <= 0
		|| (`CHEATMGR != none && `CHEATMGR.bAlwaysPanic))
	{
		// do a weighted pick from the available choices. Add up the total weight of all options,
		// do a random roll from [0..TotalWeight], and then start adding up the weights again.
		// when the total goes over the random number, we have our choice.
		foreach PanicWeights(PanicWeight)
		{
			TotalPanicWeight += PanicWeight.Weight;
		}

		PanicRoll = `SYNC_FRAND_STATIC("DoWillRoll") * TotalPanicWeight;

		TotalPanicWeight = 0.0f;
		foreach PanicWeights(PanicWeight)
		{
			TotalPanicWeight += PanicWeight.Weight;
			if(TotalPanicWeight >= PanicRoll)
			{
				InPanicAbilityName = PanicWeight.PanicAbilityName;

				// To favor the new panic behaviors, if we roll a normal panic and this unit has already
				// done a normal panic on this mission, reroll (but only once)
				if(!Reroll
					&& InPanicAbilityName == 'Panicked'
					&& UnitHasAlreadyUsedNormalPanicThisMission(InSourceUnit))
				{
					DoPanicRoll(InSourceUnit, InRunningWillLossTotal, PanicChance, default.MultiplePanicAltWeights, true, InPanicAbilityName);
				}

				break;
			}
		}
	}
}

// Does what it says, nativized since it can require a lot of iteration late into missions.
static native function bool UnitHasAlreadyUsedNormalPanicThisMission(XComGameState_Unit InSourceUnit);

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local X2EventManager Manager;
	local Object SelfObj;

	// Add the units to the new game state
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, self);

	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectId));
	UnitState.ModifyCurrentStat(eStat_Will, -RunningWillLossTotal);

	if( WillEventType != '' && UnitState.WillEventsActivatedThisMission.Find(WillEventType) == INDEX_NONE )
	{
		UnitState.WillEventsActivatedThisMission.AddItem(WillEventType);
	}

	// trigger an event to do our panic behavior if one was selected. We need to wait for this context
	// to complete before we can do the panic, and an event will serve that purpose just fine
	if(PanicAbilityName != '')
	{
		SelfObj = self;
		Manager = `XEVENTMGR;
		Manager.RegisterForEvent(SelfObj, 'DoPanicAbility', OnDoPanicAbility, ELD_OnStateSubmitted);
		Manager.TriggerEvent('DoPanicAbility', UnitState, self, NewGameState);
	}

	NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);

	return NewGameState;
}

function EventListenerReturn OnDoPanicAbility(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory History;
	local GameRulesCache_Unit UnitCache;
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState;
	local int i;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(EventData);
	if(EventSource != self)
	{
		return ELR_NoInterrupt;
	}

	// find the specified panic ability and activate it
	if (`TACTICALRULES.GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache))
	{
		for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
		{
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID));
			if (AbilityState.GetMyTemplateName() == PanicAbilityName)
			{
				if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success' && UnitCache.AvailableActions[i].AvailableTargets.Length > 0)
				{
					class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], 0, , , , , , , SPT_AfterSequential);
				}
				break;
			}
		}
	}

	`XEVENTMGR.UnRegisterFromEvent(EventSource, 'DoPanicAbility');
	return ELR_NoInterrupt;
}

protected function ContextBuildVisualization()
{
	local VisualizationActionMetadata ActionMetadata, EmptyMetadata;
	local X2Action_PlaySoundAndFlyover FlyoverAction;
	//local X2Action_PlayMessageBanner WorldMessageAction;
	local XComGameState_Unit UnitState;
	local XGParamTag Tag;
	local X2Action_RevealArea RevealAreaAction;
	local XComWorldData WorldData;
	local TTile TileLocation;
	local Vector WorldLocation;
	local X2Action_CameraLookAt LookAtAction;
	local X2Action_StartStopSound SoundAction;
	local X2Action_UpdateUI UIUpdateAction;
	local X2AbilityTemplate AbilityTemplate;
	local X2Action_Delay DelayAction;
	local X2Action_CentralBanner BannerAction;

	// add a flyover track for every unit in the game state. This timing of this is too late to look good
	// but since Ryan is tearing it all out there is no reason to augment the visualization system to allow
	// it to look pretty
	if(ShowMessages)
	{
		WorldData = `XWORLD;
			
		Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		Tag.StrValue0 = RollSourceFriendly;
		Tag.IntValue0 = RunningWillLossTotal;

		if( PanicAbilityName == '' )
		{
			Tag.StrValue2 = ResistedText;
		}
		else
		{
			AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(PanicAbilityName);
			Tag.StrValue2 = AbilityTemplate.LocFriendlyName;
		}

		// clear unnecessary HUD components
		UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
		UIUpdateAction.UpdateType = EUIUT_SetHUDVisibility;
		UIUpdateAction.DesiredHUDVisibility.bMessageBanner = true;

		foreach AssociatedState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			UnitState.GetKeystoneVisibilityLocation(TileLocation);
			WorldLocation = WorldData.GetPositionFromTileCoordinates(TileLocation);
				
			Tag.StrValue1 = UnitState.GetFullName();

			ActionMetadata = EmptyMetadata;
			ActionMetadata.StateObject_OldState = UnitState.GetPreviousVersion();
			ActionMetadata.StateObject_NewState = UnitState;

			Tag.StrValue0 = RollSourceFriendly;

			// new visualization flow:
			// for each affected unit:
			// 1a) Clear FOW around unit
			RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			RevealAreaAction.ScanningRadius = class'XComWorldData'.const.WORLD_StepSize * 5.0f;
			RevealAreaAction.TargetLocation = WorldLocation;
			RevealAreaAction.bDestroyViewer = false;
			RevealAreaAction.AssociatedObjectID = UnitState.ObjectID;

			// 1b) Focus camera on unit (wait until centered)
			LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			LookAtAction.LookAtLocation = WorldLocation;
			LookAtAction.BlockUntilActorOnScreen = true;
			LookAtAction.LookAtDuration = 10.0f;		// longer than we need - camera will be removed by tag below
			LookAtAction.TargetZoomAfterArrival = -0.7f;
			LookAtAction.CameraTag = 'WillTestCamera';
			LookAtAction.bRemoveTaggedCamera = false;

			// 2a) Raise Special Event overlay "Breaking Point: <RollSource>"
			BannerAction = X2Action_CentralBanner(class'X2Action_CentralBanner'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			BannerAction.BannerText = `XEXPAND.ExpandString(PanicTestCaption);
			BannerAction.BannerState = eUIState_Normal;

			// 2b) Play will loss update on UnitFlag will bar
			UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			UIUpdateAction.SpecificID = UnitState.ObjectID;
			UIUpdateAction.UpdateType = EUIUT_UnitFlag_Health;

			// 2c) Trigger Panic Event buildup audio FX
			SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			SoundAction.Sound = new class'SoundCue';
			SoundAction.Sound.AkEventOverride = AkEvent'XPACK_SoundTacticalUI.Panic_Check_Start';
			SoundAction.bIsPositional = false;
			SoundAction.vWorldPosition = WorldLocation;
			SoundAction.WaitForCompletion = true;

			// 3a) Wait 0.5s - or until SoundAction is complete
			DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			DelayAction.Duration = 2.5;
			DelayAction.bIgnoreZipMode = true;

			// 4a) Update Special Event overlay to show panic results
			BannerAction = X2Action_CentralBanner(class'X2Action_CentralBanner'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			BannerAction.BannerText = `XEXPAND.ExpandString(PanicResultFlyover);
			if( PanicAbilityName == '' )
			{
				BannerAction.BannerState = eUIState_Good;
			}
			else
			{
				BannerAction.BannerState = eUIState_Bad;
			}

			// 4b) Trigger Result flyover (ex. "Resisted", "Panicked")
			// Update 4/20 - only trigger if the result was "resisted"
			if( PanicAbilityName == '' )
			{
				FlyoverAction = X2Action_PlaySoundAndFlyover(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
				FlyoverAction.SetSoundAndFlyOverParameters(none, `XEXPAND.ExpandString(PanicResultFlyover), '', eColor_Good);
			}

			// 4c) Trigger result audio FX
			SoundAction = X2Action_StartStopSound(class'X2Action_StartStopSound'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			SoundAction.Sound = new class'SoundCue';
			if( PanicAbilityName == '' )
			{
				// good result sound
				SoundAction.Sound.AkEventOverride = AkEvent'SoundTacticalUI.TacticalUI_UnitFlagPositive';
			}
			else
			{
				// bad result sound
				SoundAction.Sound.AkEventOverride = AkEvent'SoundTacticalUI.TacticalUI_UnitFlagWarning';
			}
			SoundAction.bIsPositional = false;
			SoundAction.vWorldPosition = WorldLocation;
			SoundAction.WaitForCompletion = false;

			// 5a) complete panic behavior visualization (if applicable)
			// - for now, will just rely on the panic processing to complete the behavior visualization

			// 5a) Wait 1.5s
			DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			DelayAction.bIgnoreZipMode = true;
			if( PanicAbilityName == '' )
			{
				// if the panic was resisted, there will not be a panic visualization following this action, 
				// so we need to give the user more time to enjoy the "resisted" flyover
				DelayAction.Duration = 3.0; 
			}
			else
			{
				DelayAction.Duration = 1.5;
			}

			// 6a) Lower Special Event overlay
			BannerAction = X2Action_CentralBanner(class'X2Action_CentralBanner'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			BannerAction.BannerText = "";

			// 6b) restore FOW
			RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			RevealAreaAction.bDestroyViewer = true;
			RevealAreaAction.AssociatedObjectID = UnitState.ObjectID;

			// 6c) release camera 
			LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			LookAtAction.CameraTag = 'WillTestCamera';
			LookAtAction.bRemoveTaggedCamera = true;

			// 6d) Play world message explaining what just happened
			// Update 4/20 - no banner needed when resisting; the panic state will handle the banner when the will check is failed
			//WorldMessageAction = X2Action_PlayMessageBanner(class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
			//WorldMessageAction.AddMessageBanner(class'UIEventNoticesTactical'.default.PanicCheckTitle,
			//							   /*class'UIUtilities_Image'.const.UnitStatus_Panicked*/,
			//								UnitState.GetName(eNameType_RankFull),
			//							   `XEXPAND.ExpandString(PanicResultWorldMessage),
			//							   (PanicAbilityName == '') ? eUIState_Good : eUIState_Bad);
		}

		// restore HUD components to previous vis state
		UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded));
		UIUpdateAction.UpdateType = EUIUT_RestoreHUDVisibility;
	}
}

static event XComGameStateContext_WillRoll CreateWillRollContext(XComGameState_Unit InSourceUnit, name InRollSource, optional string InRollSourceFriendly, optional bool InShowMessages = true)
{
	local XComGameStateContext_WillRoll RollContext;

	`assert(InSourceUnit != none);
	RollContext = XComGameStateContext_WillRoll(CreateXComGameStateContext());
	RollContext.SourceUnit = InSourceUnit;
	RollContext.RollSource = InRollSource;
	RollContext.RollSourceFriendly = InRollSourceFriendly == "" ? default.DefaultLossSource : InRollSourceFriendly;
	RollContext.ShowMessages = InShowMessages;
	return RollContext;
}

event Submit()
{
	local X2TacticalGameRuleset Rules;

	if(SourceUnit.IsDead() || SourceUnit.IsIncapacitated() || SourceUnit.IsMindControlled())
	{
		return;
	}

	if(RunningWillLossTotal > 0 || PanicAbilityName != '')
	{
		Rules = `TACTICALRULES;
		if(Rules == none)
		{
			`Redscreen("Attempting to submit a will roll outside of tactical.");
			return;
		}

		if(!Rules.SubmitGameStateContext(self))
		{
			`Redscreen("Unable to submit will roll context.");
		}
	}
}

function string SummaryString()
{
	return "Will Roll: " $ SourceUnit.GetFullName() $ " lost " $ RunningWillLossTotal $ " Will";
}