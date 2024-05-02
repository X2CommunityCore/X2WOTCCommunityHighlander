//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Ability_DefaultBondmateAbilities
//  AUTHOR:  David Burchanowski -- 8/31/2016
//  PURPOSE: Provide abilities that are meant to be activated in response to bondmate actions
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2Ability_DefaultBondmateAbilities extends X2Ability
	config(GameCore);

var localized string BondmateAimAdjustName;
var localized string BondmateAimAdjustDesc;
var localized string DefendBondmateAimAdjustName;
var localized string AssistBondmateAimAdjustName;
var localized string AssistBondmateCritAdjustName;
var localized string FreeActionFlyoverText;

var localized string BondmateBleedoutName;
var localized string BondmateBleedoutDesc;

var const config int BONDMATE_WILL_BONUS_LEVEL1;
var const config int BONDMATE_WILL_BONUS_LEVEL2;
var const config int BONDMATE_WILL_BONUS_LEVEL3;

var const config int FreeActionChance;
var const config int FreeActionChanceInBuddyZone;

var const config array<int> ReturnFireChance;
var const config int ReturnFireCohesionAmount;

var const config int CovertOperatorsBondLevel;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	// The Bond Lv.1
	//Templates.AddItem(CreateBondmateResistantWillAbility());
	Templates.AddItem(CreateBondmateCovertOperatorsAbility());

	// Teamwork Lv.1
	Templates.AddItem(CreateBondmateInspireAbility('BondmateTeamwork',
												   "img:///UILibrary_XPACK_Common.UIPerk_bond_teamwork",
												   1,
												   2,
												   1));


	// Teamwork Lv.3
	Templates.AddItem(CreateBondmateInspireAbility('BondmateTeamwork_Improved',
												   "img:///UILibrary_XPACK_Common.UIPerk_bond_teamwork2",
												   3,
												   3,
												   2));


	// Spotter Lv.1
	Templates.AddItem(CreateBondmateSpotterAbility('BondmateSpotter_Aim',
												   "img:///UILibrary_XPACK_Common.UIPerk_bond_spotter",
												   2,
												   3,
												   EAR_AnyAdjacency,
												   10,
												   0));

	Templates.AddItem(CreateBondmateSpotterAbility('BondmateSpotter_Aim_Adjacency',
												   "img:///UILibrary_XPACK_Common.UIPerk_bond_spotter",
												   2,
												   3,
												   EAR_RequireAdjacency,
												   10,
												   0));

	//// Spotter Lv.2
	//Templates.AddItem(CreateBondmateSpotterAbility('BondmateSpotter_Crit',
	//											   "img:///UILibrary_XPACK_Common.UIPerk_bond_spotter2",
	//											   2,
	//											   3,
	//											   EAR_AnyAdjacency,
	//											   0,
	//											   10));

	//Templates.AddItem(CreateBondmateSpotterAbility('BondmateSpotter_Crit_Adjacency',
	//											   "",
	//											   2,
	//											   3,
	//											   EAR_RequireAdjacency,
	//											   0,
	//											   10));

	// Stand By Me Lv.2
	Templates.AddItem(CreateBondmateSolaceAbility());
	Templates.AddItem(CreateBondmatePurePassive('BondmateSolacePassive',
												"img:///UILibrary_XPACK_Common.UIPerk_bond_standbyme",
												2,
												3));

	//// Brother's Keeper Lv.2
	//Templates.AddItem(CreateBondmatePurePassive('BondmateReturnFire_Passive',
	//											"img:///UILibrary_XPACK_Common.UIPerk_bond_brotherskeeper",
	//											2,
	//											2));

	//Templates.AddItem(CreateBondmateReturnFireAbility('BondmateReturnFire',
	//												  2,
	//												  2,
	//												  EAR_DisallowAdjacency,
	//												  25));
	//Templates.AddItem(CreateBondmateReturnFireAbility('BondmateReturnFire_Adjacency',
	//												  2,
	//												  2,
	//												  EAR_RequireAdjacency,
	//												  35));

	//// Brother's Keeper Lv.3
	//Templates.AddItem(CreateBondmatePurePassive('BondmateReturnFire_Improved_Passive',
	//											"img:///UILibrary_XPACK_Common.UIPerk_bond_brotherskeeper2",
	//											3,
	//											3));

	//Templates.AddItem(CreateBondmateReturnFireAbility('BondmateReturnFire_Improved', 
	//												  3, 
	//												  3, 
	//												  EAR_DisallowAdjacency, 
	//												  50));
	//Templates.AddItem(CreateBondmateReturnFireAbility('BondmateReturnFire_Improved_Adjacency', 
	//												  3, 
	//												  3, 
	//												  EAR_RequireAdjacency, 
	//												  70));

	//// Dual Strike Lv.3
	Templates.AddItem(BondmateDualStrike()); 
	Templates.AddItem(BondmateDualStrikeFollowup());

	return Templates;
}

static function X2AbilityTemplate CreateBondmatePurePassive(name TemplateName,
															string TemplateIconImage,
															int MinBondLevel,
															int MaxBondLevel)
{
	local X2AbilityTemplate Template;
	local X2Condition_Bondmate BondmateCondition;

	Template = PurePassive(TemplateName, TemplateIconImage, , 'eAbilitySource_Commander', TemplateIconImage != "");

	BondmateCondition = new class'X2Condition_Bondmate';
	BondmateCondition.MinBondLevel = MinBondLevel;
	BondmateCondition.MaxBondLevel = MaxBondLevel;
	BondmateCondition.bSkipCheckWithSource = true;
	Template.AbilityShooterConditions.AddItem(BondmateCondition);

	return Template;
}

static function X2AbilityTemplate CreateBondmateResistantWillAbility()
{
	local X2AbilityTemplate Template;

	Template = CreateBondmatePurePassive('BondmateResistantWill', "img:///UILibrary_PerkIcons.UIPerk_standard", 1, 3);

	// the actual will loss reduction happens in XComGameStateContext_WillRoll and is configured via SoldierBondWillReductionMultiplier

	return Template;
}

static function X2AbilityTemplate CreateBondmateCovertOperatorsAbility()
{
	local X2AbilityTemplate Template;

	Template = CreateBondmatePurePassive('BondmateCovertOperators', "img:///UILibrary_PerkIcons.UIPerk_standard", default.CovertOperatorsBondLevel, 3);

	// This is only for display purposes on the Bond Confirm Screen. Only has an effect in Strategy.

	return Template;
}

static function X2AbilityTemplate CreateBondmateSolaceAbility()
{
	local X2AbilityTemplate Template;
	local X2Condition_Bondmate BondmateCondition;

//BEGIN AUTOGENERATED CODE: Template Overrides 'BondmateSolaceCleanse'
	Template = class'X2Ability_PsiOperativeAbilitySet'.static.SolaceCleanse('BondmateSolaceCleanse', "img:///UILibrary_XPACK_Common.UIPerk_bond_thebond", 1.5);
//END AUTOGENERATED CODE: Template Overrides 'BondmateSolaceCleanse'

	Template.AbilitySourceName = 'eAbilitySource_Commander';                                       // color of the icon

	BondmateCondition = new class'X2Condition_Bondmate';
	BondmateCondition.MinBondLevel = 2;
	BondmateCondition.MaxBondLevel = 3;
	BondmateCondition.RequiresAdjacency = EAR_RequireAdjacency;
	Template.AbilityTargetConditions.AddItem(BondmateCondition);

	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}

static function X2AbilityTemplate CreateBondmateInspireAbility(name TemplateName,
															   string TemplateIconImage,
															   int MinBondLevel,
															   int MaxBondLevel,
															   int Charges)
{
	local X2AbilityTemplate				Template;
	local X2AbilityCost_ActionPoints	ActionPointCost;
	local X2Effect_GrantActionPoints	ActionPointEffect;
	local X2Effect_Persistent			ActionPointPersistEffect;
	local X2Condition_Bondmate			BondmateCondition;
	local X2AbilityCost_Charges			ChargeCost;
	local X2Condition_UnitProperty      TargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	// Icon Properties
	Template.DisplayTargetHitChance = true;
	Template.AbilitySourceName = 'eAbilitySource_Commander';                                       // color of the icon
	Template.IconImage = TemplateIconImage;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.Hostility = eHostility_Defensive;
	Template.bLimitTargetIcons = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	BondmateCondition = new class'X2Condition_Bondmate';
	BondmateCondition.MinBondLevel = MinBondLevel;
	BondmateCondition.MaxBondLevel = MaxBondLevel;
	BondmateCondition.RequiresAdjacency = EAR_AnyAdjacency;
	Template.AbilityShooterConditions.AddItem(BondmateCondition);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	TargetCondition = new class'X2Condition_UnitProperty';
	TargetCondition.ExcludeHostileToSource = true;
	TargetCondition.ExcludeFriendlyToSource = false;
	TargetCondition.RequireSquadmates = true;
	TargetCondition.FailOnNonUnits = true;
	TargetCondition.ExcludeDead = true;
	TargetCondition.ExcludeRobotic = true;
	TargetCondition.ExcludeUnableToAct = true;
	TargetCondition.ExcludePanicked = true;
	Template.AbilityTargetConditions.AddItem(TargetCondition);
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	ActionPointEffect = new class'X2Effect_GrantActionPoints';
	ActionPointEffect.NumActionPoints = 1;
	ActionPointEffect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	ActionPointEffect.bSelectUnit = true;
	Template.AddTargetEffect(ActionPointEffect);

	// A persistent effect for the effects code to attach a duration to
	ActionPointPersistEffect = new class'X2Effect_Persistent';
	ActionPointPersistEffect.EffectName = TemplateName;
	ActionPointPersistEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
	ActionPointPersistEffect.bRemoveWhenTargetDies = true;
	Template.AddTargetEffect(ActionPointPersistEffect);

	Template.AbilityTargetStyle = default.BondmateTarget;

	Template.ActivationSpeech = 'Inspire';
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.bShowActivation = true;
	Template.CustomFireAnim = 'HL_Teamwork';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Psionic_FireAtUnit";

	Template.AbilityCharges = new class'X2AbilityCharges';
	Template.AbilityCharges.InitialCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	ChargeCost.bAlsoExpendChargesOnSharedBondmateAbility = true;
	Template.AbilityCosts.AddItem(ChargeCost);

	return Template;
}

static function X2AbilityTemplate CreateBondmateSpotterAbility(name TemplateName,
	                                                           string TemplateIconImage,
															   int MinBondLevel,
															   int MaxBondLevel,
															   AdjacencyRequirement RequiresAdjacency,
															   float AimBonus,
															   float Critbonus)
{
	local X2AbilityTemplate Template;
	local X2Condition_Bondmate BondmateCondition;
	local X2Effect_ToHitModifier Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.IconImage = TemplateIconImage;
	Template.AbilitySourceName = 'eAbilitySource_Commander';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	BondmateCondition = new class'X2Condition_Bondmate';
	BondmateCondition.MinBondLevel = MinBondLevel;
	BondmateCondition.MaxBondLevel = MaxBondLevel;
	BondmateCondition.bSkipCheckWithSource = true;
	BondmateCondition.RequiresAdjacency = RequiresAdjacency;
	Template.AbilityShooterConditions.AddItem(BondmateCondition);

	Effect = new class'X2Effect_ToHitModifier';
	Effect.DuplicateResponse = eDupe_Allow;
	Effect.BuildPersistentEffect(1, true, false);
	Effect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, RequiresAdjacency == EAR_AnyAdjacency, , Template.AbilitySourceName);
	if( AimBonus > 0 )
	{
		Effect.AddEffectHitModifier(eHit_Success, AimBonus, Template.LocFriendlyName);
	}
	if( Critbonus > 0 )
	{
		Effect.AddEffectHitModifier(eHit_Crit, Critbonus, Template.LocFriendlyName);
	}

	BondmateCondition = new class'X2Condition_BondmateAggro';
	BondmateCondition.MinBondLevel = MinBondLevel;
	BondmateCondition.MaxBondLevel = MaxBondLevel;
	BondmateCondition.RequiresAdjacency = RequiresAdjacency;
	Effect.ToHitConditions.AddItem(BondmateCondition);
	Template.AddTargetEffect(Effect);

	Template.bDontDisplayInAbilitySummary = (RequiresAdjacency == EAR_AnyAdjacency);

	return Template;
}


static function X2AbilityTemplate CreateBondmateReturnFireAbility(name TemplateName, 
																  int MinBondLevel, 
																  int MaxBondLevel, 
																  AdjacencyRequirement RequiresAdjacency, 
																  float TriggerChance)
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventTrigger;
	local X2Condition_Bondmate BondmateCondition;

	Template = class'X2Ability_WeaponCommon'.static.Add_StandardShot(TemplateName, true);

	Template.AbilitySourceName = 'eAbilitySource_Commander';

	BondmateCondition = new class'X2Condition_Bondmate';
	BondmateCondition.MinBondLevel = MinBondLevel;
	BondmateCondition.MaxBondLevel = MaxBondLevel;
	BondmateCondition.bSkipCheckWithSource = true;
	BondmateCondition.RequiresAdjacency = RequiresAdjacency;
	Template.AbilityShooterConditions.AddItem(BondmateCondition);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	// doesn't cost anything to return fire
	Template.AbilityCosts.Length = 0;
	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;
	Template.bShowActivation = true;
	Template.CinescriptCameraType = ""; // disable fancy cameras, otherwise the player can't see what is happening

	// check for activation when a unit is targeted by an offensive ability
	Template.AbilityTriggers.Length = 0;
	EventTrigger = new class'X2AbilityTrigger_EventListener';
	EventTrigger.ListenerData.EventID = 'AbilityActivated';
	if( RequiresAdjacency == EAR_RequireAdjacency )
	{
		EventTrigger.ListenerData.EventFn = CheckForReturnFire_Adjacency;
	}
	else
	{
		EventTrigger.ListenerData.EventFn = CheckForReturnFire_NonAdjacency;
	}
	EventTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Template.AbilityTriggers.AddItem(EventTrigger);

	Template.TriggerChance = TriggerChance;

	// Increase the cohesion of the bondmates
	Template.AddShooterEffect(class'X2Effect_IncreaseBondmateCohesion'.static.CreateIncreaseBondmateCohesionEffect(default.ReturnFireCohesionAmount));

	//BEGIN AUTOGENERATED CODE: Template Overrides 'BondmateReturnFire'
	//BEGIN AUTOGENERATED CODE: Template Overrides 'BondmateReturnFire_Adjacency'
	//BEGIN AUTOGENERATED CODE: Template Overrides 'BondmateReturnFire_Improved'
	//BEGIN AUTOGENERATED CODE: Template Overrides 'BondmateReturnFire_Improved_Adjacency'	
	Template.bFrameEvenWhenUnitIsHidden = true;	
	//END AUTOGENERATED CODE: Template Overrides 'BondmateReturnFire_Improved_Adjacency'
	//END AUTOGENERATED CODE: Template Overrides 'BondmateReturnFire_Improved'
	//END AUTOGENERATED CODE: Template Overrides 'BondmateReturnFire_Adjacency'
	//END AUTOGENERATED CODE: Template Overrides 'BondmateReturnFire'

	return Template;
}

static function EventListenerReturn CheckForReturnFire_Adjacency(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	return CheckForReturnFire(EventData, EventSource, GameState, Event, CallbackData, true);
}

static function EventListenerReturn CheckForReturnFire_NonAdjacency(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	return CheckForReturnFire(EventData, EventSource, GameState, Event, CallbackData, false);
}

static function EventListenerReturn CheckForReturnFire(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData, bool bRequiresAdjacency)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState, BondmateAbilityState;
	local X2AbilityTemplate AbilityTemplate, BondmateAbilityTemplate;
	local XComGameState_Unit TargetUnit, BondmateUnit;
	local StateObjectReference BondmateRef;
	local SoldierBond BondData;
	local TTile SourceTile, TargetTile;
	local bool bAdjacent;
	local int RandRoll;

	AbilityState = XComGameState_Ability(EventData);
	`assert(AbilityState != none);

	// Only react to hostile actions. The unit has to actually be attacking our bondmate
	AbilityTemplate = AbilityState.GetMyTemplate();
	`assert(AbilityTemplate != none);

	if(AbilityTemplate.Hostility != eHostility_Offensive)
	{
		return ELR_NoInterrupt;
	}

	// Ignore any interruption contexts. We only want to respond with an attack after the original attack
	// has fully resolved.
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	`assert(AbilityContext != none);
	if (!AbilityContext.bFirstEventInChain || AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
	{
		return ELR_NoInterrupt;
	}

	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if(TargetUnit == none)
	{
		return ELR_NoInterrupt;
	}

	// We don't have a soldier bond, so there is nobody to stick up for us
	if(!TargetUnit.HasSoldierBond(BondmateRef, BondData))
	{
		return ELR_NoInterrupt;
	}

	BondmateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));
	if( BondmateUnit == none )
	{
		return ELR_NoInterrupt;
	}

	// Make sure this is the event listener that we registered
	BondmateAbilityState = XComGameState_Ability(CallbackData);
	if(BondmateRef.ObjectID != BondmateAbilityState.OwnerStateObject.ObjectID)
	{
		return ELR_NoInterrupt;
	}

	BondmateAbilityTemplate = BondmateAbilityState.GetMyTemplate();
	if( BondmateAbilityTemplate == None )
	{
		return ELR_NoInterrupt;
	}

	// determine adjacency
	TargetUnit.GetKeystoneVisibilityLocation(SourceTile);
	BondmateUnit.GetKeystoneVisibilityLocation(TargetTile);

	bAdjacent = ((abs(SourceTile.X - TargetTile.X) + abs(SourceTile.Y - TargetTile.Y) + abs(SourceTile.Z - TargetTile.Z)) == 1);
	if( bRequiresAdjacency != bAdjacent )
	{
		return ELR_NoInterrupt;
	}

	RandRoll = `SYNC_RAND_STATIC(100);
	if( RandRoll > BondmateAbilityTemplate.TriggerChance )
	{
		return ELR_NoInterrupt;
	}

	// have the bondmate return fire on the attacker
	class'XComGameStateContext_Ability'.static.ActivateAbilityByTemplateName(BondmateRef, 
																			 BondmateAbilityState.GetMyTemplateName(),
																			 AbilityContext.InputContext.SourceObject);

	return ELR_NoInterrupt;
}

static function X2AbilityTemplate BondmateDualStrike()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityCharges					Charges;
	local X2AbilityCost_Charges				ChargeCost;
	local X2Condition_Bondmate			BondmateCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BondmateDualStrike');

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = 1;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 0;
	ActionPointCost.bAddWeaponTypicalCost = true;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	BondmateCondition = new class'X2Condition_Bondmate';
	BondmateCondition.MinBondLevel = 3;
	BondmateCondition.MaxBondLevel = 3;
	BondmateCondition.RequiresAdjacency = EAR_AnyAdjacency;
	Template.AbilityShooterConditions.AddItem(BondmateCondition);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(new class'X2Condition_BondmateDualStrike');
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.AdditionalAbilities.AddItem('BondmateDualStrikeFollowup');
	Template.PostActivationEvents.AddItem('BondmateDualStrikeFollowup');
	
	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;
//BEGIN AUTOGENERATED CODE: Template Overrides 'BondmateDualStrike'
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.IconImage = "img:///UILibrary_XPACK_Common.UIPerk_bond_DualStrike";
//END AUTOGENERATED CODE: Template Overrides 'BondmateDualStrike'

	return Template;
}

static function X2AbilityTemplate BondmateDualStrikeFollowup()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_Ammo				AmmoCost;
	local X2AbilityToHitCalc_StandardAim    ToHitCalc;
	local X2AbilityTrigger_EventListener    Trigger;
	local X2AbilityCharges					Charges;
	local X2AbilityCost_Charges				ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BondmateDualStrikeFollowup');

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = 1;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	ChargeCost.SharedAbilityCharges.AddItem('BondmateDualStrike');
	Template.AbilityCosts.AddItem(ChargeCost);

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	ToHitCalc = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = ToHitCalc;
	Template.AbilityToHitOwnerOnMissCalc = ToHitCalc;

	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.HoloTargetEffect());
	Template.AssociatedPassives.AddItem('HoloTargeting');
	Template.AddTargetEffect(class'X2Ability_GrenadierAbilitySet'.static.ShredderDamageEffect());
	Template.bAllowAmmoEffects = true;
	Template.bAllowBonusWeaponEffects = true;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'BondmateDualStrikeFollowup';
	Trigger.ListenerData.Filter = eFilter_None;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.BondmateDualStrikeListener;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_XPACK_Common.UIPerk_bond_DualStrike";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.bShowActivation = true;

	Template.SuperConcealmentLoss = class'X2AbilityTemplateManager'.default.SuperConcealmentStandardShotLoss;
	Template.ChosenActivationIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotChosenActivationIncreasePerUse;
	Template.LostSpawnIncreasePerUse = class'X2AbilityTemplateManager'.default.StandardShotLostSpawnIncreasePerUse;

	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;
//BEGIN AUTOGENERATED CODE: Template Overrides 'BondmateDualStrikeFollowup'
	Template.bFrameEvenWhenUnitIsHidden = true;
//END AUTOGENERATED CODE: Template Overrides 'BondmateDualStrikeFollowup'
	Template.bDontDisplayInAbilitySummary = true;

	return Template;
}
