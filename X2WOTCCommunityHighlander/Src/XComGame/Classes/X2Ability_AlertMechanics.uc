//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_AlertMechanics.uc
//  AUTHOR:  Ryan McFall  --  1/11/2014
//  PURPOSE: Defines the abilities that form the concealment / alertness mechanics in 
//  X-Com 2. Presently these abilities are only available to the AI.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_AlertMechanics extends X2Ability 
	config(GameCore);

var localized string CallingReinforcementsFriendlyName;
var localized string CallingReinforcementsFriendlyDesc;

var array<name> AlertAbilitySet;

/// <summary>
/// Creates the set of abilities that implement the concealment / alertness mechanic
/// </summary>
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(AddDetectMovingUnitAbility());
	Templates.AddItem(AddRedAlertAbility());
	Templates.AddItem(AddYellowAlertAbility());
	Templates.AddItem(AddYellAbility());
	Templates.AddItem(AddCommLinkAbility());
	Templates.AddItem(AddCallReinforcementsAbility());

	return Templates;
}

static function AddRedAlertEffects(out X2AbilityTemplate Template, bool bApplyToMultiTargets=false)
{
	local X2Effect_RedAlert                 RedAlertStatus;
	local X2Effect_PersistentStatChangeRestoreDefault		SightIncrease;

	RedAlertStatus = new class 'X2Effect_RedAlert';
	RedAlertStatus.BuildPersistentEffect(1,true,true /*Remove on Source Death*/,,eGameRule_PlayerTurnBegin);

	SightIncrease = new class'X2Effect_PersistentStatChangeRestoreDefault';
	SightIncrease.BuildPersistentEffect(1,true,true,,eGameRule_PlayerTurnBegin);
	SightIncrease.AddPersistentStatChange(eStat_SightRadius);
	SightIncrease.AddPersistentStatChange(eStat_DetectionRadius);

	if (bApplyToMultiTargets)
	{
		Template.AddMultiTargetEffect(RedAlertStatus);
		Template.AddMultiTargetEffect(SightIncrease);
	}
	else
	{
		Template.AddShooterEffect(RedAlertStatus);
		Template.AddShooterEffect(SightIncrease);
	}
}

static function AddYellowAlertEffects(out X2AbilityTemplate Template)
{
	local X2Effect_YellowAlert              YellowAlertStatus;
	local X2Effect_PersistentStatChangeRestoreDefault		SightIncrease;

	YellowAlertStatus = new class 'X2Effect_YellowAlert';
	YellowAlertStatus.BuildPersistentEffect(1,true,true /*Remove on Source Death*/,,eGameRule_PlayerTurnBegin);
	Template.AddShooterEffect(YellowAlertStatus);

	SightIncrease = new class'X2Effect_PersistentStatChangeRestoreDefault';
	SightIncrease.BuildPersistentEffect(1,true,true,,eGameRule_PlayerTurnBegin);
	SightIncrease.AddPersistentStatChange(eStat_SightRadius); 
	SightIncrease.AddPersistentStatChange(eStat_DetectionRadius);
	Template.AddShooterEffect(SightIncrease);
}

//******** EvaluateStimuli **********
static function X2AbilityTemplate AddDetectMovingUnitAbility()
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2Condition_UnitProperty          ShooterPropertyCondition;	
	local X2Condition_UnitProperty          TargetUnitPropertyCondition;	
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2Condition_UnitAlertStatus       AlertStatusCondition;
	local X2AbilityToHitCalc_SeeMovement    ChanceToActivate;	
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_Placeholder		UseTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DetectMovingUnit');
	
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	//Can't evaluate stimuli while dead
	ShooterPropertyCondition = new class'X2Condition_UnitProperty';	
	ShooterPropertyCondition.ExcludeDead = true;                    	
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);

	//Can't evaluate unless the unit is at a certain alert level
	AlertStatusCondition = new class'X2Condition_UnitAlertStatus';	
	AlertStatusCondition.RequiredAlertStatusMaximum = 1;
	Template.AbilityShooterConditions.AddItem(AlertStatusCondition);

	//No triggering on dead, or friendlies
	TargetUnitPropertyCondition = new class'X2Condition_UnitProperty';	
	TargetUnitPropertyCondition.ExcludeDead = true;                    	
	TargetUnitPropertyCondition.ExcludeFriendlyToSource = true;	
	Template.AbilityTargetConditions.AddItem(TargetUnitPropertyCondition);

	//Require 'basic' visibility. This means in LOS and in range.
	TargetVisibilityCondition = new class'X2Condition_Visibility';	
	TargetVisibilityCondition.bRequireBasicVisibility = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	//Use a custom chance to hit
	ChanceToActivate = new class'X2AbilityToHitCalc_SeeMovement';
	Template.AbilityToHitCalc = ChanceToActivate;

	//Effect on a successful test is adding the red alert persistent effect to the unit
	AddRedAlertEffects(Template);

	//Single target ability
	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	//System triggered
	UseTrigger = new class'X2AbilityTrigger_Placeholder';
	Template.AbilityTriggers.AddItem(UseTrigger);
	
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = NewAlertState_BuildGameState;
	Template.BuildVisualizationFn = RedAlertState_BuildVisualization;

	return Template;	
}

static function X2AbilityTemplate AddRedAlertAbility()
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2Condition_UnitProperty          ShooterPropertyCondition;	
	local X2Condition_UnitProperty          TargetUnitPropertyCondition;		
	local X2Condition_UnitAlertStatus       AlertStatusCondition;
	local X2AbilityToHitCalc_DeadEye        ChanceToActivate;	
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_Placeholder		UseTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RedAlert');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	//Can't evaluate stimuli while dead
	ShooterPropertyCondition = new class'X2Condition_UnitProperty';	
	ShooterPropertyCondition.ExcludeDead = true;                    	
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);

	//Can't evaluate unless the unit is at a certain alert level
	AlertStatusCondition = new class'X2Condition_UnitAlertStatus';	
	AlertStatusCondition.RequiredAlertStatusMaximum = 1;
	Template.AbilityShooterConditions.AddItem(AlertStatusCondition);

	//This ability is manually triggered, and can trigger on dead units as well as friendlies.
	TargetUnitPropertyCondition = new class'X2Condition_UnitProperty';	
	TargetUnitPropertyCondition.ExcludeDead = false;                    	
	TargetUnitPropertyCondition.ExcludeFriendlyToSource = false;	
	Template.AbilityTargetConditions.AddItem(TargetUnitPropertyCondition);

	//100% chance to hit
	ChanceToActivate = new class'X2AbilityToHitCalc_DeadEye';
	Template.AbilityToHitCalc = ChanceToActivate;

	//Effect on a successful test is adding the red alert persistent effect to the unit
	AddRedAlertEffects(Template);

	//Single target ability
	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	//System triggered
	UseTrigger = new class'X2AbilityTrigger_Placeholder';
	Template.AbilityTriggers.AddItem(UseTrigger);

	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = NewAlertState_BuildGameState;
	Template.BuildVisualizationFn = RedAlertState_BuildVisualization;
	Template.AssociatedPlayTiming = SPT_AfterSequential;

	return Template;	
}

static function X2AbilityTemplate AddYellowAlertAbility()
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2Condition_UnitProperty          ShooterPropertyCondition;	
	//local X2Condition_UnitProperty          TargetUnitPropertyCondition;		
	//local X2Condition_UnitAlertStatus       AlertStatusCondition;
	local X2AbilityToHitCalc_DeadEye        ChanceToActivate;	
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityTrigger_Placeholder		UseTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'YellowAlert');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	//Can't evaluate stimuli while dead
	ShooterPropertyCondition = new class'X2Condition_UnitProperty';	
	ShooterPropertyCondition.ExcludeDead = true;                    	
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);

	// Update - can go to yellow alert from green or from red.
	////Can't evaluate unless the unit is at a certain alert level
	//AlertStatusCondition = new class'X2Condition_UnitAlertStatus';	
	//AlertStatusCondition.RequiredAlertStatusMaximum = 0;
	//Template.AbilityShooterConditions.AddItem(AlertStatusCondition);

	//This ability is manually triggered by hearing explosions or grenades.
	//TargetUnitPropertyCondition = new class'X2Condition_UnitProperty';	
	//TargetUnitPropertyCondition.ExcludeDead = false;                    	
	//TargetUnitPropertyCondition.ExcludeFriendlyToSource = false;	
	//Template.AbilityTargetConditions.AddItem(TargetUnitPropertyCondition);

	//100% chance to hit
	ChanceToActivate = new class'X2AbilityToHitCalc_DeadEye';
	Template.AbilityToHitCalc = ChanceToActivate;

	//Effect on a successful test is adding the yellow alert persistent effect to the unit
	AddYellowAlertEffects(Template);

	//Single target ability
	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	//System triggered
	UseTrigger = new class'X2AbilityTrigger_Placeholder';
	Template.AbilityTriggers.AddItem(UseTrigger);

	Template.FrameAbilityCameraType = eCameraFraming_Never;

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = NewAlertState_BuildGameState;
	Template.BuildVisualizationFn = YellowAlertState_BuildVisualization;
	Template.AssociatedPlayTiming = SPT_AfterSequential;

	return Template;	
}

static function X2AbilityTemplate AddYellAbility()
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2Condition_UnitProperty          ShooterPropertyCondition;	
	local X2Condition_UnitProperty          TargetUnitPropertyCondition;	
	local X2Condition_UnitAlertStatus       AlertStatusCondition;
	local X2AbilityToHitCalc_DeadEye        ChanceToActivate;	
	local X2AbilityTarget_Self				SingleTarget;
	local X2AbilityMultiTarget_Radius		MultiTarget;
	//local X2AbilityCooldown_Global          GlobalCooldown;

	//Trigger conditions
	local X2AbilityTrigger_PlayerInput		InputTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Yell');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Disabled global cooldown to allow Civilians to yell as much as they want.
	//GlobalCooldown = new class'X2AbilityCooldown_Global';
	//GlobalCooldown.iNumTurns = 0;
	//Template.AbilityCooldown = GlobalCooldown;

	//Can't yell while dead
	ShooterPropertyCondition = new class'X2Condition_UnitProperty';	
	ShooterPropertyCondition.ExcludeDead = true;                    	
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);

	Template.AddShooterEffectExclusions();

	//Can't evaluate unless the unit is already in red alert.
	AlertStatusCondition = new class'X2Condition_UnitAlertStatus';	
	AlertStatusCondition.RequiredAlertStatusMinimum = 1;
	Template.AbilityShooterConditions.AddItem(AlertStatusCondition);

	//This ability is manually triggered, and can trigger on friendlies only.
	TargetUnitPropertyCondition = new class'X2Condition_UnitProperty';	
	TargetUnitPropertyCondition.ExcludeDead = true;                    	
	TargetUnitPropertyCondition.ExcludeFriendlyToSource = false;	
	TargetUnitPropertyCondition.ExcludeHostileToSource = true;
	Template.AbilityTargetConditions.AddItem(TargetUnitPropertyCondition);

	// Only affects units that are not already in red alert.
	//AlertStatusCondition = new class'X2Condition_UnitAlertStatus';	
	//AlertStatusCondition.RequiredAlertStatusMaximum = 1;
	//Template.AbilityTargetConditions.AddItem(AlertStatusCondition);

	//100% chance to hit
	ChanceToActivate = new class'X2AbilityToHitCalc_DeadEye';
	Template.AbilityToHitCalc = ChanceToActivate;

	//Effect on a successful test is adding the red alert persistent effect to the unit
	AddRedAlertEffects(Template, true);

	//Trigger on player input.
	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	SingleTarget = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = SingleTarget;

	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = 27;
	MultiTarget.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.Hostility = eHostility_Defensive;

	Template.BuildNewGameStateFn = Yell_BuildGameState;
	Template.BuildVisualizationFn = Yell_BuildVisualization;

	return Template;	
}

static function X2AbilityTemplate AddCommLinkAbility()
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2Condition_UnitProperty          ShooterPropertyCondition;	
	local X2Condition_UnitProperty          TargetUnitPropertyCondition;	
	local X2Condition_UnitAlertStatus       AlertStatusCondition;
	local X2AbilityToHitCalc_DeadEye        ChanceToActivate;	
	local X2AbilityTarget_Self				SingleTarget;
	local X2AbilityMultiTarget_AllAllies	MultiTarget;

	//Trigger conditions
	local X2AbilityTrigger_PlayerInput		InputTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CommLink');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	//Can't use CommLink while dead
	ShooterPropertyCondition = new class'X2Condition_UnitProperty';	
	ShooterPropertyCondition.ExcludeDead = true;                    	
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);

	Template.AddShooterEffectExclusions();

	//Can't evaluate unless the unit is already in red alert.
	AlertStatusCondition = new class'X2Condition_UnitAlertStatus';	
	AlertStatusCondition.RequiredAlertStatusMinimum = 1;
	Template.AbilityShooterConditions.AddItem(AlertStatusCondition);

	//This ability is manually triggered, and can trigger on friendlies only.
	TargetUnitPropertyCondition = new class'X2Condition_UnitProperty';	
	TargetUnitPropertyCondition.ExcludeDead = true;                    	
	TargetUnitPropertyCondition.ExcludeFriendlyToSource = false;	
	TargetUnitPropertyCondition.ExcludeHostileToSource = true;
	Template.AbilityTargetConditions.AddItem(TargetUnitPropertyCondition);

	// Can't set targets already in red alert to red alert.
	//AlertStatusCondition = new class'X2Condition_UnitAlertStatus';	
	//AlertStatusCondition.RequiredAlertStatusMaximum = 1;
	//Template.AbilityTargetConditions.AddItem(AlertStatusCondition);

	//100% chance to hit
	ChanceToActivate = new class'X2AbilityToHitCalc_DeadEye';
	Template.AbilityToHitCalc = ChanceToActivate;

	//Effect on a successful test is adding the red alert persistent effect to the unit
	AddRedAlertEffects(Template);

	//Trigger on player input.
	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	SingleTarget = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = SingleTarget;

	MultiTarget = new class'X2AbilityMultiTarget_AllAllies';
	Template.AbilityMultiTargetStyle = MultiTarget;

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = Yell_BuildGameState;
	Template.BuildVisualizationFn = Yell_BuildVisualization;
	Template.CinescriptCameraType = "GenericAccentCam";

	return Template;	
}

static function X2AbilityTemplate AddCallReinforcementsAbility()
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2Condition_UnitProperty          ShooterPropertyCondition;	
	local X2Condition_UnitAlertStatus       AlertStatusCondition;
	local X2Effect_Persistent               CallToHQEffect;
	local X2AbilityToHitCalc_DeadEye        ChanceToActivate;	
	local X2AbilityTarget_Self				SingleTarget;
	local X2AbilityCooldown_Global          Cooldown;

	//Trigger conditions
	local X2AbilityTrigger_PlayerInput		InputTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CallReinforcements');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Add cooldown.
	Cooldown = new class'X2AbilityCooldown_Global';
	Cooldown.iNumTurns = 8;
	Template.AbilityCooldown = Cooldown;

	//Can't use CommLink while dead
	ShooterPropertyCondition = new class'X2Condition_UnitProperty';	
	ShooterPropertyCondition.ExcludeDead = true;                    	
	Template.AbilityShooterConditions.AddItem(ShooterPropertyCondition);

	Template.AddShooterEffectExclusions();

	//Can't evaluate unless the unit is already in red alert.
	AlertStatusCondition = new class'X2Condition_UnitAlertStatus';	
	AlertStatusCondition.RequiredAlertStatusMinimum = 1;
	Template.AbilityShooterConditions.AddItem(AlertStatusCondition);

	//100% chance to hit
	ChanceToActivate = new class'X2AbilityToHitCalc_DeadEye';
	Template.AbilityToHitCalc = ChanceToActivate;

	//Effect on a successful test is adding the call reinforcements effect to the unit
	CallToHQEffect = new class 'X2Effect_Persistent';
	CallToHQEffect.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	CallToHQEffect.ApplyOnTick.AddItem(new class 'X2Effect_CallReinforcements');
	CallToHQEffect.SetDisplayInfo(ePerkBuff_Bonus, default.CallingReinforcementsFriendlyName, default.CallingReinforcementsFriendlyDesc, "", true);
	CallToHQEffect.EffectRemovedVisualizationFn = EffectRemovedByDeathVisualization;
	Template.AddShooterEffect(CallToHQEffect);

	//Trigger on player input.
	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	SingleTarget = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = SingleTarget;

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.Hostility = eHostility_Neutral;

	Template.BuildNewGameStateFn = CallReinforcements_BuildGameState;
	Template.BuildVisualizationFn = Yell_BuildVisualization;

	return Template;	
}

simulated function XComGameState NewAlertState_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability EvaluateStimuliAbilityState;	
	local XComGameState_BaseObject AlertedUnitState_OriginalState;
	local XComGameState_BaseObject AlertedUnitState_NewState;	
	local XComGameState_AIUnitData AIUnitData_NewState;
	local XComGameState_Unit kUnitGameState;
	local int kAIObjID;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(Context);	
	EvaluateStimuliAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));
	AbilityTemplate = EvaluateStimuliAbilityState.GetMyTemplate();

	//Build the new game state and context
	NewGameState = History.CreateNewGameState(true, Context);	

	AlertedUnitState_NewState = NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID);
	AbilityTemplate.ApplyCost(AbilityContext, EvaluateStimuliAbilityState, AlertedUnitState_NewState, none, NewGameState);

	if(AbilityContext.IsResultContextHit())
	{
		//Apply the effects ( raise the unit's alert level )		
		AlertedUnitState_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);							
		ApplyEffectsToTarget(
			AbilityContext, 
			AlertedUnitState_OriginalState, 
			AlertedUnitState_OriginalState, 
			EvaluateStimuliAbilityState, 
			AlertedUnitState_NewState,
			NewGameState, 
			AbilityContext.ResultContext.HitResult,
			AbilityContext.ResultContext.ArmorMitigation,
			AbilityContext.ResultContext.StatContestResult,
			AbilityTemplate.AbilityShooterEffects, 
			AbilityContext.ResultContext.ShooterEffectResults,
			AbilityTemplate.DataName,
			TELT_AbilityShooterEffects);

		kUnitGameState  = XComGameState_Unit(AlertedUnitState_NewState);
		
		// Update AIPlayerData with info about regroup tile.
		kAIObjID = XGAIPlayer(`BATTLE.GetAIPlayer()).GetAIUnitDataID(AbilityContext.InputContext.SourceObject.ObjectID);
		if (kAIObjID <= 0)
		{
			AIUnitData_NewState = XComGameState_AIUnitData(NewGameState.CreateNewStateObject(class'XComGameState_AIUnitData'));
			AIUnitData_NewState.Init(AbilityContext.InputContext.SourceObject.ObjectID);
		}
		else
		{
			AIUnitData_NewState = XComGameState_AIUnitData(NewGameState.ModifyStateObject(class'XComGameState_AIUnitData', kAIObjID));
		}
		AIUnitData_NewState.m_kRegroupTile = kUnitGameState.TileLocation; // Keep track of last green alert location.  
	}

	NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);

	//Return the game state we have created
	return NewGameState;
}

simulated function YellowAlertState_BuildVisualization(XComGameState VisualizeGameState)
{
	NewAlertState_BuildVisualization(VisualizeGameState, eAL_Yellow);
}

simulated function RedAlertState_BuildVisualization(XComGameState VisualizeGameState)
{
	NewAlertState_BuildVisualization(VisualizeGameState, eAL_Red);
}

simulated function NewAlertState_BuildVisualization(XComGameState VisualizeGameState, EAlertLevel iAlertLevel)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Unit TargetUnitState;
	local XComGameStateContext_Ability AbilityContext;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;
	local X2Action_MoveTurn         MoveTurnAction;
	local X2Action_AlertUnit		AlertUnitAction;
	local X2Action_ConcealmentLost	ConcealmentLost;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());	

	//The ability source unit performs an alert unit action, the rest are concealment being lost
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{		
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(UnitState.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);

		if( UnitState.ObjectID == AbilityContext.InputContext.SourceObject.ObjectID )
		{
			AlertUnitAction = X2Action_AlertUnit(class'X2Action_AlertUnit'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));	
			AlertUnitAction.m_eAlertLevel = iAlertLevel;
			AlertUnitAction.m_eCause = EAlertCause(AbilityContext.ResultContext.iCustomAbilityData); // receiving cause var.
			AlertUnitAction.SetShouldCauseTimeDilationIfInterrupting(false);
			
			//If we are detecting a moving unit, then turn to face them
			if( AbilityContext.InputContext.AbilityTemplateName == 'DetectMovingUnit' )
			{
				TargetUnitState = XComGameState_Unit( History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID) );

				if( TargetUnitState != none )
				{
					ActionMetadata = EmptyTrack;
					ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
					ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(UnitState.ObjectID);
					ActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);

					MoveTurnAction = X2Action_MoveTurn( class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext) );				
					MoveTurnAction.m_vFacePoint = `XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
					MoveTurnAction.SetShouldCauseTimeDilationIfInterrupting(false);
				}
			}
		}
		else
		{
			ConcealmentLost = X2Action_ConcealmentLost(class'X2Action_ConcealmentLost'.static.AddToVisualizationTree(ActionMetadata, AbilityContext));
			ConcealmentLost.SetShouldCauseTimeDilationIfInterrupting(false);
		}
	}
}


simulated function XComGameState Yell_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;

	local XComGameState_Unit YellerState;	
	local XComGameState_AIGroup GroupState;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(Context);	

	//Build the new game state and context
	NewGameState = TypicalAbility_BuildGameState( Context );

	YellerState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	GroupState = YellerState.GetGroupMembership();
	if( GroupState != None && GroupState.IsFallingBack() && GroupState.ShouldDoFallbackYell() )
	{
		GroupState = XComGameState_AIGroup(NewGameState.ModifyStateObject(class'XComGameState_AIGroup', GroupState.ObjectID));
		GroupState.bPlayedFallbackCallAnimation = true;
	}

	//Return the game state we have created
	return NewGameState;
}


simulated function Yell_BuildVisualization(XComGameState VisualizeGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;

	local VisualizationActionMetadata        EmptyTrack;
	local VisualizationActionMetadata        ActionMetadata;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());	

	//The ability source unit performs an alert unit action, the rest are concealment being lost
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{		
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		ActionMetadata.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(UnitState.ObjectID);
		ActionMetadata.VisualizeActor = History.GetVisualizer(UnitState.ObjectID);

		if( UnitState.ObjectID == AbilityContext.InputContext.SourceObject.ObjectID )
		{
			if( AbilityContext.InputContext.AbilityTemplateName == 'Yell' )
			{
				class'X2Action_Yell'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);	
							}
			else if (AbilityContext.InputContext.AbilityTemplateName == 'CommLink' )
			{
				class'X2Action_CommLink'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);	
							}
			else if (AbilityContext.InputContext.AbilityTemplateName == 'CallReinforcements' )
			{
				class'X2Action_PreppingCallReinforcements'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);	
							}
		}
		else if (UnitState.ControllingPlayerIsAI())
		{
			class'X2Action_AlertUnit'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);	
		}
		else
		{
			class'X2Action_ConcealmentLost'.static.AddToVisualizationTree(ActionMetadata, AbilityContext);	
		}
	}
}

simulated function XComGameState CallReinforcements_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;

	local XComGameState_Ability CallReinforcementsAbilityState;	
	local XComGameState_BaseObject Caller_OriginalState, Caller_NewState, Target_OriginalState, Target_NewState;	

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(Context);	
	CallReinforcementsAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));
	AbilityTemplate = CallReinforcementsAbilityState.GetMyTemplate();

	// Cooldown value must be updated here since we can't edit the template with ini info before the game starts.
	AbilityTemplate.AbilityCooldown.iNumTurns = `ScaleStrategyArrayInt(class'XGTacticalGameCore'.default.REINFORCEMENTS_COOLDOWN);

	// Cooldown shouldn't begin until the countdown has completed.  So for now, add the countdown to the cooldown.
	AbilityTemplate.AbilityCooldown.iNumTurns += `GAMECORE.AI_REINFORCEMENTS_DEFAULT_ARRIVAL_TIME;

	//Build the new game state and context
	NewGameState = History.CreateNewGameState(true, Context);	

	Caller_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID);							
	Caller_NewState = NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID);
	AbilityTemplate.ApplyCost(AbilityContext, CallReinforcementsAbilityState, Caller_NewState, none, NewGameState);

	//  Apply effect to AI player data
	Target_OriginalState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference);
	Target_NewState = NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.PrimaryTarget.ObjectID);

	ApplyEffectsToTarget(
		AbilityContext, 
		Target_OriginalState, 
		Caller_OriginalState, 
		CallReinforcementsAbilityState, 
		Target_NewState, 
		NewGameState, 
		AbilityContext.ResultContext.HitResult,
		AbilityContext.ResultContext.ArmorMitigation,
		AbilityContext.ResultContext.StatContestResult,
		AbilityTemplate.AbilityShooterEffects, 
		AbilityContext.ResultContext.ShooterEffectResults,
		AbilityTemplate.DataName,
		TELT_AbilityShooterEffects);

	//Return the game state we have created
	return NewGameState;
}

static function EffectRemovedByDeathVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	if( XComGameState_Unit(ActionMetadata.StateObject_NewState).IsDead() )
	{
		class'X2Action_PreppingCallReinforcementsRemoved'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
	}
}

defaultproperties
{
	AlertAbilitySet(0)="DetectMovingUnit"
	AlertAbilitySet(1)="RedAlert"
	AlertAbilitySet(2)="YellowAlert"
	AlertAbilitySet(3)="Yell"
	AlertAbilitySet(4)="CommLink"
}