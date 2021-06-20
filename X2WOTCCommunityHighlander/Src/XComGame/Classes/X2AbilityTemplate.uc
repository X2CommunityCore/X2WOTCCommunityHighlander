//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTemplate.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityTemplate extends X2DataTemplate
	implements(UIQueryInterfaceAbility)
	dependson(X2Camera)
	native(Core)
	editinlinenew;

enum EAbilityHostility
{
	eHostility_Offensive,
	eHostility_Defensive,
	eHostility_Neutral,
	eHostility_Movement,
};

enum EConcealmentRule           //  Checked after the ability is activated to determine if the unit can remain concealed.
{
	eConceal_NonOffensive,      //  Always retain Concealment if the Hostility != Offensive (default behavior)
	eConceal_Always,            //  Always retain Concealment, period
	eConceal_Never,             //  Never retain Concealment, period
	eConceal_KillShot,          //  Retain concealment when killing a single (primary) target
	eConceal_Miss,              //  Retain concealment when the ability misses
	eConceal_MissOrKillShot,    //  Retain concealment when the ability misses or when killing a single (primary) target
	eConceal_AlwaysEvenWithObjective,	//	Always retain Concealment, even if the target is an objective
};

enum ECameraFramingType
{
	eCameraFraming_Never,
	eCameraFraming_Always,
	eCameraFraming_IfNotNeutral
};

struct native UIAbilityStatMarkup
{
	var int StatModifier;
	var bool bForceShow;					// If true, this markup will display even if the modifier is 0
	var localized string StatLabel;		// The user-friendly label associated with this modifier
	var ECharStatType StatType;			// The stat type of this markup (if applicable)
	var delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;	// A function to check if the stat should be displayed or not
};

var editinlineuse X2AbilityCharges					AbilityCharges;                 //  Used for configuring the number of charges a unit gets for this ability at tactical start.
var editinlineuse array<X2AbilityCost>				AbilityCosts;
var editinlineuse X2AbilityCooldown					AbilityCooldown;
var editinlineuse X2AbilityToHitCalc				AbilityToHitCalc;
var editinlineuse X2AbilityToHitCalc				AbilityToHitOwnerOnMissCalc;    // If !none, a miss on the main target will apply this chance to hit on the target's owner.
var editinlineuse array<X2Condition>				AbilityShooterConditions;
var editinlineuse array<X2Condition>				AbilityTargetConditions;
var editinlineuse array<X2Condition>				AbilityMultiTargetConditions;   //  if conditions are set here, multi targets use these to filter instead of AbilityTargetConditions

// Start Issue #68 - remove protectedwrite to allow modification
var editinlineuse array<X2Effect>	AbilityTargetEffects;           //  effects which apply to the main target only
var editinlineuse array<X2Effect>	AbilityMultiTargetEffects;      //  effects which apply to the multi targets only
var editinlineuse array<X2Effect>	AbilityShooterEffects;          //  effects which always apply to the shooter, regardless of targets
// End Issue #68

var editinlineuse array<X2AbilityTrigger>			AbilityTriggers;
var float											TriggerChance;					// The chance that this ability will be fired when the trigger conditions are met
var bool											bUseThrownGrenadeEffects;
var bool											bUseLaunchedGrenadeEffects;
var bool											bAllowFreeFireWeaponUpgrade;        //  if true, this ability will process the free fire weapon upgrade to spare an action point cost
var bool											bAllowAmmoEffects;                  //  if true, equipped ammo will apply its effects to the target
var bool											bAllowBonusWeaponEffects;           //  if true, the ability's weapon's bonus effects will be added to the target (in TypicalAbility_BuildGameState)
var editinline StrategyRequirement					Requirements;         // The strategy requirements that must be met in order for this ability to be used in a tactical mission

var name                     FinalizeAbilityName;               // certain abilities (such as hack) work as a two step process. Specify the finalizing ability here.
var name                     CancelAbilityName;					// certain abilities (such as hack) work as a two step process. Specify the cancellation ability here.
var array<name>              AdditionalAbilities;               //  when a unit is granted this ability, it will be granted all of these abilities as well
var array<name>				 PrerequisiteAbilities;				//  if this ability is a modifier on another ability, its listed here. purely informational, mainly for Psi Op ability training.
var array<name>              OverrideAbilities;                 //  if set, will replace the first matched ability if it would otherwise be given to a unit
var array<name>				 AssociatedPassives;				//  Set of PurePassive abilities that the unit could have that would modify the behavior of this ability when the unit has them

var editinlineuse array<AbilityEventListener> AbilityEventListeners;

var EAbilityHostility       Hostility;
var bool                    bAllowedByDefault;                  //  if true, this ability will be enabled by default. Otherwise the ability will have to be enabled before it is usable
var bool                    bUniqueSource;                      //  the ability may only be attached to a unit from one source (see GatherUnitAbilitiesForInit on how that works)
var array<name>             PostActivationEvents;               //  trigger these events after AbilityActivated is triggered (only when not interrupted) EventData=ability state, EventSource=owner unit state
var bool                    bRecordValidTiles;                  //  TypicalAbility_BuildGameState will record the multi target GetValidTilesForLocation in the result context's RelevantEffectTiles
var bool				    bIsPassive;							//  Flag to identify this as a PurePassive ability later on
var bool					bCrossClassEligible;				//  Flag for soldier abilities eligible for AWC talent or training roulette
var EConcealmentRule        ConcealmentRule;
var int                     SuperConcealmentLoss;               //  Increases chance to lose concealment (only when super concealed). Only applies to player input abilities.
var bool                    bSilentAbility;                     //  Don't trigger sound when this ability is activated, regardless of ammo/damage rules.
var bool                    bCannotTeleport;                    // For pathing abilities, prevents ability to use teleport traversals.
var bool					bPreventsTargetTeleport;			// If set, this ability prevents the target from teleporting away.
var bool                    bTickPerActionEffects;              // If true, this ability will tick per action effects when activated
var bool                    bCheckCollision;                    //  Limit affected area because of coliision.
var bool                    bAffectNeighboringTiles;            //  If need to do calculation to figure out what tiles are secondary tile
var bool                    bFragileDamageOnly;                 //  Damage fragile only objects.

var int						ChosenActivationIncreasePerUse;		// the increase to the current Chosen's activation value every time this ability is used
var int						LostSpawnIncreasePerUse;			// the increase to the Lost Spawn value every time this ability is used

var int						AbilityPointCost;					// New faction classes unlock abilities with ability points
var eInventorySlot          DefaultSourceItemSlot;              //  For abilities that require an item but are not sourced from one, specifies a default slot to use.

var name					AbilityRevealEvent;					// If non-none, this ability will be concealed until this event is triggered (and ShouldRevealFn returns true if specified)
var array<name>				ChosenReinforcementGroupName;		// if this is an ability on a Chosen, when that chosen tries to summon a group, they will use this group EncounterID
var name					ChosenTraitType;					// If this is a chosen trait ability, this specifies the general type ('Survivability', 'Summoning', 'Immunity', 'Offensive')
var array<name>				ChosenExcludeTraits;				// If this is a chosen trait ability, this specifies other traits that are not compatible with this trait
var int						ChosenTraitForceLevelGate;			// If this is a chosen trait ability, this specifies the force level when the trait can be acquired

//HUD specific items
var localized string		LocFriendlyName;                    // The localized, UI facing name the ability will have
var localized string		LocHelpText;                        // The localized, UI facing description that shows up in the Shot HUD
var localized string		LocLongDescription;
var localized string		LocPromotionPopupText;
var localized string		LocFlyOverText;
var localized string		LocMissMessage;
var localized string		LocHitMessage;
var localized string		LocFriendlyNameWhenConcealed;       // used by the shot HUD when the ability owner is concealed
var localized string		LocLongDescriptionWhenConcealed;    // long description used when ability owner is concealed (ability tooltip)
var localized string		LocDefaultSoldierClass;				// used in passive effects in indicate the soldier class for AWC abilities
var localized string		LocDefaultPrimaryWeapon;			// used in passive effects to indicate the primary weapon for AWC abilities
var localized string		LocDefaultSecondaryWeapon;			// used in passive effects to indicate the secondary weapon for AWC abilities

var(UI) EAbilityIconBehavior        eAbilityIconBehaviorHUD;            // when should this ability appear in the HUD?
var(UI) array<name>                 HideIfAvailable;                    // if icon behavior is eAbilityIconBehavior_HideIfOtherAvailable, these are the abilities that makes it hide
var(UI) array<name>                 HideErrors;                         // if icon behavior is eAbilityIconBehavior_HideSpecificErrors, these are the ones to hide
var(UI) bool                        DisplayTargetHitChance;             // Indicates this ability's hit chance should be used in the UI as the hit chance on enemies where appropriate.
var(UI) bool                        bUseAmmoAsChargesForHUD;            // The ability's weapon's ammo will be displayed as the number of charges available for the ability
var(UI) int                         iAmmoAsChargesDivisor;              // Divide the ammo amount by this number to come up with the correct number of charges to be displayed
var(UI) string                      IconImage;                          // This string identifies which icon the ability will use in the ability container. Can be empty if bAbilityVisibleInHUD is FALSE
var(UI) string                      AbilityIconColor;                   // background color override for the icon, specified in the RGB hex format "FFFFFF"
var		bool                        bHideOnClassUnlock;                 // Prevents this ability from showing up in the popup that appears when a soldier gains a new class
var		int 	                    ShotHUDPriority;                    // This number is used to sort the icons position in the Ability Container in Tactical HUD. 0 shows up leftmost. 
var(UI) bool					    bDisplayInUITooltip;				// Will only appear in UI info tooltips if this is true 
var(UI) bool					    bDisplayInUITacticalText;			// Will only appear in UI tactical text tooltip if this is true 
var(UI) bool						bNoConfirmationWithHotKey;			// True if activation via hotkey should skip the confirmation UI
var(UI) bool                        bLimitTargetIcons;                  // Will cause the UI to display only valid target icons when this ability is selected.
var(UI) bool                        bBypassAbilityConfirm;              // Will force the ability to trigger automatically without requiring the user to click the confirm button.
var(UI) Name			            AbilitySourceName;                  // Indicates the source of this ability (used to color the icon)
var(UI) string                      AbilityConfirmSound;                // Sound to play when choosing to activate the ability in the shot HUD (UI confirmation sound)
var(UI) bool						bDontDisplayInAbilitySummary;		// If true, this ability template will never be displayed as part of an ability summary
var(UI) int                         DefaultKeyBinding;                  // Number as found in UIUtilities_Input for the default keyboard binding
var array<UIAbilityStatMarkup>		UIStatMarkups;						//  Values to display in the UI to modify soldier stats
var(UI) bool						bCommanderAbility;
var bool							bFriendlyFireWarning;				// If true, the ability wants to display a friendly fire warning if it is hostile (see X2TargetingMethod)
var bool							bFriendlyFireWarningRobotsOnly;		// bFriendlyFireWarning must also be true, but only a robot target will generate a warning

//Visualization parameters
var(Animations) name    CustomFireAnim;
var(Animations) name	CustomFireKillAnim;
var(Animations) name	CustomMovingFireAnim;
var(Animations) name	CustomMovingFireKillAnim;
var(Animations) name	CustomMovingTurnLeftFireAnim;
var(Animations) name	CustomMovingTurnLeftFireKillAnim;
var(Animations) name	CustomMovingTurnRightFireAnim;
var(Animations) name	CustomMovingTurnRightFireKillAnim;
var(Animations) name    CustomSelfFireAnim;

var(Visualization) SequencePlayTiming	AssociatedPlayTiming;				// If not SPT_None, and no MergeVisualizationFn is defined, this ability will automatically merge into the visualization tree using the standard timing system specified
var(Visualization) bool                 bShowActivation;                    // If true, ability will automatically show its name over the activating unit's head when used.
var(Visualization) bool                 bShowPostActivation;                // If true, ability will automatically show its name over the activating unit's head after the end of the actions and the camera has panned back.
var(Visualization) bool                 bSkipFireAction;                    // If true, ability will not exit cover/fire/enter cover when activated.
var(Visualization) bool					bSkipExitCoverWhenFiring;			// If true, ability will not exit cover when firing is activated.
var(Visualization) bool					bSkipPerkActivationActions;			// If true, ability will not automatically include perk actions when activated (but will still do the perk duration ending action).
var(Visualization) bool					bSkipPerkActivationActionsSync;		// If true, ability will not automatically activate perks when loading/synching.
var(Visualization) bool                 bSkipMoveStop;                      // If true, typical abilities with embedded moves will not play a stop anim before the fire anim. This should be used for custom moving attacks et cetera
var(Visualization) bool					bOverrideMeleeDeath;				// If true it will play a normal death instead of melee death (only effects melee weapons)
var(Visualization) bool                 bOverrideVisualResult;              // Use the below value if this is true
var(Visualization) EAbilityHitResult    OverrideVisualResult;               // Use this value when checking IsVisualHit instead of the context's actual result
var(Visualization) bool					bHideWeaponDuringFire;				//  identify ability as a thrown weapon that should be hidden since it's replaced by a projectile during the fire process
var(Visualization) bool					bHideAmmoWeaponDuringFire;			//
var(Visualization) bool					bIsASuppressionEffect;				//	used to identify suppression type abilities that should use the modified spread during unified projectile processing
var(Visualization) bool					bOverrideAim;
var(Visualization) bool					bUseSourceLocationZToAim;			//  if set, the unit will aim the attack at the same height as the weapon instead at the target location, must set bOverrideAim to use.
var(Visualization) bool                 bOverrideWeapon;                    //  if OverrideAbility is set, the weapon from that ability will be used unless this field is set true.
var(Visualization) bool                 bStationaryWeapon;                  //  if the ability uses a cosmetic attached weapon (e.g. gremlin), don't move it to the target when the ability activates
var(Visualization) class<X2Action_Fire> ActionFireClass;
var(Visualization) bool					bForceProjectileTouchEvents;		// If the ability doesn't do damage but wants the projectile to break windows.

var(Speech) name  ActivationSpeech;					//  TypicalAbility_BuildVisualization will automatically use these
var(Speech) name  SourceHitSpeech;				    //  TypicalAbility_BuildVisualization will automatically use these
var(Speech) name  TargetHitSpeech;					//  TypicalAbility_BuildVisualization will automatically use these
var(Speech) name  SourceMissSpeech;					//  TypicalAbility_BuildVisualization will automatically use these
var(Speech) name  TargetMissSpeech;					//  TypicalAbility_BuildVisualization will automatically use these
var(Speech) name  TargetKilledByAlienSpeech;        //  X2Action_EnterCover:RespondToShotSpeak uses this if the activating unit is on the alien team and killed a single unit
var(Speech) name  TargetKilledByXComSpeech;         //  X2Action_EnterCover:RespondToShotSpeak uses this if the activating unit is on the xcom team and killed a single unit
var(Speech) name  MultiTargetsKilledByAlienSpeech;  //  X2Action_EnterCover:RespondToShotSpeak uses this if the activating unit is on the alien team and killed multiple units
var(Speech) name  MultiTargetsKilledByXComSpeech;   //  X2Action_EnterCover:RespondToShotSpeak uses this if the activating unit is on the xcom team and killed multiple units
var(Speech) name  TargetWingedSpeech;               //  X2Action_EnterCover:RespondToShotSpeak uses this when the target is grazed
var(Speech) name  TargetArmorHitSpeech;             //  X2Action_EnterCover:RespondToShotSpeak uses this when the target has armor that mitigated some of the damage
var(Speech) name  TargetMissedSpeech;               //  X2Action_EnterCover:RespondToShotSpeak uses this when the target is missed

//  Targeting stuff
var editinlineuse X2AbilityTargetStyle       AbilityTargetStyle;
var editinlineuse X2AbilityMultiTargetStyle  AbilityMultiTargetStyle;
var editinlineuse X2AbilityPassiveAOEStyle	 AbilityPassiveAOEStyle;
var bool					                 bAllowUnderhandAnim;		//	if the ability uses a grenade path, should it also use an underhand anim on short paths?


var class<X2TargetingMethod>    TargetingMethod;						// UI interaction class. Specifies how the target is actually selected by the user
var class<X2TargetingMethod>	SecondaryTargetingMethod;			// Same as Targeting Method, but this gets used if we want a separate target method after we select/confirm an ability.

var(Targeting) bool				SkipRenderOfAOETargetingTiles;			// Modifier to UI interaction class
var(Targeting) bool				SkipRenderOfTargetingTemplate;			// Modifier to UI interaction class

var(Targeting) string                      MeleePuckMeshPath;           // Path of the static mesh to use as the end of path puck when targeting this ability. Only applies to Melee

//Camera settings
var(Camera) string                      CinescriptCameraType;           // Type of camera to play when this ability is visualized. See defaultcameras.ini
var(Camera) ECameraPriority				CameraPriority;					// Override for the priority of the camera used to frame this ability

// note: don't check the following two things directly, you should normally check XComGameStateContext_Ability::ShouldFrameAbility()
var(Camera) bool                        bUsesFiringCamera;              // Used by the UI / targeting code to know whether the targeting camera should be popped from the camera stack, or left on for the firing camera to use
var(Camera) ECameraFramingType          FrameAbilityCameraType;         // Indicates how this ability will use a frame ability camera to look at the source of the ability when it is used
var(Camera) bool                        bFrameEvenWhenUnitIsHidden;     // Indicates whether this ability will use a frame ability camera to look at the source of the ability when it is used if the unit is not visible (i.e. in fog)

var name						TwoTurnAttackAbility;				    // Name of attack ability if this is a two-turn attack - used for AI.

var delegate<BuildNewGameStateDelegate> BuildNewGameStateFn;						// This method converts an input context into a game state
var delegate<BuildInterruptGameStateDelegate> BuildInterruptGameStateFn;			// Responsible for creating 'interrupted' and 'resumed' game states if an ability can be interrupted
var delegate<BuildVisualizationDelegate> BuildVisualizationFn;						// This method converts a game state into a set of visualization tracks
var delegate<BuildVisualizationSyncDelegate> BuildAppliedVisualizationSyncFn;		// This method converts a game load state into a set of visualization tracks
var delegate<BuildVisualizationSyncDelegate> BuildAffectedVisualizationSyncFn;		// This method converts a game load state into a set of visualization tracks
var delegate<OnSoldierAbilityPurchased> SoldierAbilityPurchasedFn;
var delegate<OnVisualizationTrackInserted> OnVisualizationTrackInsertedFn;			// DEPRECATED. Not removed to preserve compatibility.
var delegate<ModifyActivatedAbilityContext> ModifyNewContextFn;
var delegate<DamagePreviewDelegate> DamagePreviewFn;
var delegate<GetBonusWeaponAmmo> GetBonusWeaponAmmoFn;
var delegate<MergeVisualizationDelegate> MergeVisualizationFn;
var delegate<AlternateFriendlyNameDelegate> AlternateFriendlyNameFn;
var delegate<ShouldRevealChosenTraitDelegate> ShouldRevealChosenTraitFn;
var delegate<OverrideAbilityAvailability> OverrideAbilityAvailabilityFn;

var() name						MP_PerkOverride;					// The name of the SP ability this MP ability overrides and should use the perks from

delegate XComGameState BuildNewGameStateDelegate(XComGameStateContext Context);
delegate XComGameState BuildInterruptGameStateDelegate(XComGameStateContext Context, int InterruptStep, EInterruptionStatus InterruptionStatus);
delegate BuildVisualizationDelegate(XComGameState VisualizeGameState);
delegate BuildVisualizationSyncDelegate(name EffectName, XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata);
delegate OnSoldierAbilityPurchased(XComGameState NewGameState, XComGameState_Unit UnitState);
delegate OnVisualizationTrackInserted(XComGameStateContext_Ability Context, int OuterIndex, int InnerIndex);
delegate ModifyActivatedAbilityContext(XComGameStateContext Context);
delegate bool DamagePreviewDelegate(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield);
delegate int GetBonusWeaponAmmo(XComGameState_Unit UnitState, XComGameState_Item ItemState);
delegate MergeVisualizationDelegate(X2Action BuildTree, out X2Action VisualizationTree);
delegate bool AlternateFriendlyNameDelegate(out string AlternateName, XComGameState_Ability AbilityState, StateObjectReference TargetRef);
delegate bool ShouldRevealChosenTraitDelegate(Object EventData, Object EventSource, XComGameState GameState, Object CallbackData);
delegate OverrideAbilityAvailability(out AvailableAction Action, XComGameState_Ability AbilityState, XComGameState_Unit OwnerState);

function InitAbilityForUnit(XComGameState_Ability AbilityState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	if (AbilityCharges != none)
		AbilityState.iCharges = AbilityCharges.GetInitialCharges(AbilityState, UnitState);
}

function XComGameState_Ability CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Ability Ability;	

	// Begin Issue #763
	/// HL-Docs: ref:CustomTargetStyles
	if (AllTargetStylesNative())
	{
		Ability = XComGameState_Ability(NewGameState.CreateNewStateObject(class'XComGameState_Ability', self));
	}
	else
	{
		Ability = XComGameState_Ability(NewGameState.CreateNewStateObject(class'XComGameState_Ability_CH', self));
	}
	// End Issue #763

	return Ability;
}

// Start Issue #763
simulated private function bool AllTargetStylesNative()
{
	// The AbilityPassiveAOEStyle is never required by native code, so we don't have to check it here.
	return (AbilityTargetStyle == none || CH_ClassIsNative(AbilityTargetStyle.Class))
		&& (AbilityMultiTargetStyle == none || CH_ClassIsNative(AbilityMultiTargetStyle.Class));
}
// End Issue #763

function AddTargetEffect(X2Effect Effect)
{
	SetEffectName(Effect);
	AbilityTargetEffects.AddItem(Effect);
}

function AddMultiTargetEffect(X2Effect Effect)
{
	SetEffectName(Effect);
	AbilityMultiTargetEffects.AddItem(Effect);
}

function AddShooterEffect(X2Effect Effect)
{
	SetEffectName(Effect);
	AbilityShooterEffects.AddItem(Effect);
}

private function SetEffectName(X2Effect Effect)
{
	if (Effect.IsA('X2Effect_Persistent'))
	{
		if (X2Effect_Persistent(Effect).EffectName == '')
			X2Effect_Persistent(Effect).EffectName = DataName;
	}	
}

function AddAbilityEventListener(name EventID, delegate<X2TacticalGameRulesetDataStructures.AbilityEventDelegate> EventFn, optional EventListenerDeferral Deferral = ELD_Immediate, optional AbilityEventFilter Filter = eFilter_Unit)
{
	local AbilityEventListener Listener;

	Listener.EventID = EventID;
	Listener.EventFn = EventFn;
	Listener.Deferral = Deferral;
	Listener.Filter = Filter;
	AbilityEventListeners.AddItem(Listener);
}

simulated function AddShooterEffectExclusions(optional array<name> SkipExclusions)
{
	local X2Condition_UnitEffects UnitEffects;

	UnitEffects = GetShooterEffectExclusions(SkipExclusions);
	if (UnitEffects.ExcludeEffects.Length > 0)
		AbilityShooterConditions.AddItem(UnitEffects);
}

simulated function X2Condition_UnitEffects GetShooterEffectExclusions(optional array<name> SkipExclusions)
{
	local X2Condition_UnitEffects UnitEffects;

	UnitEffects = new class'X2Condition_UnitEffects';
	
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.DisorientedName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.DisorientedName, 'AA_UnitIsDisoriented');
	
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2StatusEffects'.default.BurningName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2StatusEffects'.default.BurningName, 'AA_UnitIsBurning');
	
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2Ability_CarryUnit'.default.CarryUnitEffectName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_CarryingUnit');

	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.BoundName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BoundName, 'AA_UnitIsBound');

	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.ConfusedName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.ConfusedName, 'AA_UnitIsConfused');

	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2Effect_PersistentVoidConduit'.default.EffectName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2Effect_PersistentVoidConduit'.default.EffectName, 'AA_UnitIsBound');

	//Typically, stunned units cannot act because the stun removes their action points. That doesn't handle free actions, though.
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.StunnedName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.StunnedName, 'AA_UnitIsStunned');
	//Typically, dazed units cannot act because the stun removes their action points. That doesn't handle free actions, though.
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.DazedName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.DazedName, 'AA_UnitIsStunned');

	if( SkipExclusions.Length == 0 || SkipExclusions.Find('Freeze') == INDEX_NONE )
		UnitEffects.AddExcludeEffect('Freeze', 'AA_UnitIsFrozen');
	
	return UnitEffects;
}

simulated function name CanAfford(XComGameState_Ability kAbility, optional XComGameState_Unit ActivatingUnit)
{
	local X2AbilityCost Cost;
	local name AvailableCode;

	if (ActivatingUnit == None)
		ActivatingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));

	foreach AbilityCosts(Cost)
	{
		AvailableCode = Cost.CanAfford(kAbility, ActivatingUnit);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
	}
	return 'AA_Success';
}

simulated function bool IsFreeCost(XComGameState_Ability kAbility)
{
	local X2AbilityCost Cost;

	foreach AbilityCosts(Cost)
	{
		if(!Cost.bFreeCost)
		{
			return false;
		}
	}

	return true;
}

simulated function bool WillEndTurn(XComGameState_Ability kAbility, XComGameState_Unit kShooter)
{
	local X2AbilityCost Cost;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local int TotalPointCost;
	local X2Effect Effect;
	local X2Effect_ReserveActionPoints ReserveEffect;

	TotalPointCost = 0;

	//	reserve action points effect always 0s out the unit's action points
	//	some targeted shots use a shooter effect, e.g. suppression
	foreach AbilityShooterEffects(Effect)
	{
		ReserveEffect = X2Effect_ReserveActionPoints(Effect);
		if (ReserveEffect != none)
			return true;
	}
	//	self target abilities use a target effect, e.g. overwatch
	if (X2AbilityTarget_Self(AbilityTargetStyle) != none)
	{
		foreach AbilityTargetEffects(Effect)
		{
			ReserveEffect = X2Effect_ReserveActionPoints(Effect);
			if (ReserveEffect != none)
				return true;
		}
	}

	foreach AbilityCosts(Cost)
	{
		ActionPointCost = X2AbilityCost_ActionPoints(Cost);
		if( ActionPointCost != None && !ActionPointCost.bFreeCost )
		{
			if( ActionPointCost.ConsumeAllPoints(kAbility, kShooter) )
			{
				return true;
			}
			else
			{
				TotalPointCost += ActionPointCost.GetPointCost(kAbility, kShooter);
			}
		}
	}

	return TotalPointCost >= kShooter.NumAllActionPoints();
}

// Returns number of action points used with this ability, also the number of points available for the shooter.
simulated function int GetTotalPointsUsed(XComGameState_Ability kAbility, XComGameState_Unit kShooter, optional out int AvailablePoints)
{
	local X2AbilityCost Cost;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local int TotalPointCost;

	TotalPointCost = 0;

	foreach AbilityCosts(Cost)
	{
		ActionPointCost = X2AbilityCost_ActionPoints(Cost);
		if (ActionPointCost != None)
		{
			TotalPointCost += ActionPointCost.GetPointCost(kAbility, kShooter);
		}
	}

	AvailablePoints = kShooter.NumAllActionPoints() + kShooter.NumAllReserveActionPoints();
	return TotalPointCost;
}

// The Revalidation flag is set to true when conditions are being rechecked after an ability has been activated, but interrupted. This
// allows conditions that do not require revalidation to be skipped
simulated native function name CheckShooterConditions(XComGameState_Ability kAbility, XComGameState_Unit kShooter, optional bool Revalidation);
simulated native function name CheckTargetConditions(XComGameState_Ability kAbility, XComGameState_Unit kShooter, XComGameState_BaseObject kTarget, optional bool Revalidation);
simulated native function name CheckMultiTargetConditions(XComGameState_Ability kAbility, XComGameState_Unit kShooter, XComGameState_BaseObject kTarget);

// For now NewGameState is used only to add extra GameStates outside of the passed parameters, which get added to the NewGameState higher up.
simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local X2AbilityCost Cost;	
	local XComGameState_Unit UnitState, TargetUnit;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local bool bFreeFire, bFreeFireFromEffect, bPaidFreeFireFromEffect;
	local int i;
	local bool bHadActionPoints, bHadAbilityCharges;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;

	local array<name> PreviousActionPoints, PreviousReservePoints;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(AffectState);

	if (`CHEATMGR != none && `CHEATMGR.bUnlimitedAmmo && UnitState.GetTeam() == eTeam_XCom)
	{
		return;
	}

	bHadAbilityCharges = kAbility.GetCharges() > 0;

	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));

	if (UnitState != none)
	{		
		PreviousActionPoints = UnitState.ActionPoints;
		bHadActionPoints = PreviousActionPoints.Length > 0;
		PreviousReservePoints = UnitState.ReserveActionPoints;
	}
	if (AffectWeapon != none)
	{		
		if (!UnitState.bGotFreeFireAction)
		{
			WeaponUpgrades = AffectWeapon.GetMyWeaponUpgradeTemplates();
			for (i = 0; i < WeaponUpgrades.Length; ++i)
			{
				if (WeaponUpgrades[i].FreeFireCostFn != none && WeaponUpgrades[i].FreeFireCostFn(WeaponUpgrades[i], kAbility))
				{
					bFreeFire = true;
					break;
				}
			}
		}
	}
	if (!bFreeFire && !UnitState.bGotFreeFireAction)
	{
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState != none)
			{
				bFreeFire = EffectState.GetX2Effect().GrantsFreeActionPointForApplyCost(AbilityContext, UnitState, TargetUnit, NewGameState);
				if (bFreeFire)
					break;
			}
		}
	}

	// Check to see if a kill allows for a free standard action point to be returned
	bFreeFireFromEffect = false;
	if (TargetUnit != none)
	{
		foreach TargetUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState != none)
			{
				bFreeFireFromEffect = EffectState.GetX2Effect().GrantsFreeActionPoint_Target(AbilityContext, UnitState, TargetUnit, NewGameState);
				if (bFreeFireFromEffect)
				{
					break;
				}
			}
		}
	}

	bPaidFreeFireFromEffect = false;
	foreach AbilityCosts(Cost)
	{		
		if (bFreeFire || bFreeFireFromEffect)
		{
			if (Cost.IsA('X2AbilityCost_ActionPoints') && !X2AbilityCost_ActionPoints(Cost).bFreeCost)
			{
				if (bFreeFire)
				{
					UnitState.bGotFreeFireAction = true;
				}
				else if (bFreeFireFromEffect)
				{
					bPaidFreeFireFromEffect = true;
				}
				continue;
			}
			if (Cost.IsA('X2AbilityCost_ReserveActionPoints') && !X2AbilityCost_ReserveActionPoints(Cost).bFreeCost)
			{
				if (bFreeFire)
				{
					UnitState.bGotFreeFireAction = true;
				}
				else if (bFreeFireFromEffect)
				{
					bPaidFreeFireFromEffect = true;
				}
				continue;
			}
		}
		Cost.ApplyCost(AbilityContext, kAbility, AffectState, AffectWeapon, NewGameState);
	}

	//If we just got a free-fire action, show it after the visualization
	if (bFreeFire && UnitState.bGotFreeFireAction)
	{
		AbilityContext.PostBuildVisualizationFn.AddItem(kAbility.FreeFire_PostBuildVisualization);
	}
	else if (bFreeFireFromEffect && bPaidFreeFireFromEffect)
	{
		AbilityContext.PostBuildVisualizationFn.AddItem(kAbility.FreeFireGeneral_PostBuildVisualization);
	}

	if (AbilityCooldown != none)
	{
		if (`CHEATMGR == none || !`CHEATMGR.Outer.bGodMode)
		{
			AbilityCooldown.ApplyCooldown(kAbility, AffectState, AffectWeapon, NewGameState);
		}
	}

	foreach UnitState.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			if (EffectState.GetX2Effect().PostAbilityCostPaid(EffectState, AbilityContext, kAbility, UnitState, AffectWeapon, NewGameState, PreviousActionPoints, PreviousReservePoints))
				break;
		}
	}

	if (UnitState.NumAllActionPoints() == 0)
	{
		if (bHadActionPoints)
		{
			`XEVENTMGR.TriggerEvent('ExhaustedActionPoints', UnitState, UnitState, NewGameState);
		}
		else
		{
			`XEVENTMGR.TriggerEvent('NoActionPointsAvailable', UnitState, UnitState, NewGameState);
		}
	}

	if (bHadAbilityCharges && kAbility.GetCharges() <= 0)
	{
		`XEVENTMGR.TriggerEvent('ExhaustedAbilityCharges', kAbility, UnitState, NewGameState);
	}
}

function bool TargetEffectsDealDamage( XComGameState_Item SourceWeapon, XComGameState_Ability Ability )
{
	local X2Effect Effect;
	local X2GrenadeTemplate GrenadeTemplate;
	local array<X2Effect> MultiTargetEffects;

	foreach AbilityTargetEffects( Effect )
	{
		if (Effect.bAppliesDamage)
		{
			return true;
		}
	}

	if (bUseLaunchedGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate( SourceWeapon.GetLoadedAmmoTemplate( Ability ) );
		MultiTargetEffects = GrenadeTemplate.LaunchedGrenadeEffects;
	}
	else if (bUseThrownGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate( SourceWeapon.GetMyTemplate( ) );
		MultiTargetEffects = GrenadeTemplate.ThrownGrenadeEffects;
	}
	else
	{
		MultiTargetEffects = AbilityMultiTargetEffects;
	}

	foreach MultiTargetEffects( Effect )
	{
		if (Effect.bAppliesDamage)
		{
			return true;
		}
	}

	return false;
}

function bool TargetEffectsSpawnUnits()
{
	local X2Effect Effect;
	foreach AbilityTargetEffects(Effect)
	{
		if (Effect.IsA('X2Effect_CallReinforcements') || Effect.IsA('X2Effect_SpawnUnit'))
		{
			return true;
		}
	}
	return false;
}

function bool HasTrigger(name TriggerClass)
{
	local int i;

	for (i = 0; i < AbilityTriggers.Length; ++i)
	{
		if (AbilityTriggers[i].IsA(TriggerClass))
		{
			return true;
		}
	}

	return false;
}

function bool ValidateTemplate(out string strError)
{
	local int i;
	local X2AbilityTemplateManager Manager;

	if (AbilityTargetStyle == none)
	{
		strError = "missing Target Style";
		return false;
	}
	if (AbilityTriggers.Length == 0)
	{
		strError = "no Triggers";
		return false;
	}
	for (i = 0; i < AbilityTriggers.Length; ++i)
	{
		if (AbilityTriggers[i].IsA('X2AbilityTrigger_PlayerInput'))
		{
			if (BuildVisualizationFn == none)
			{
				strError = "player triggered ability has no visualization";
				return false;
			}
		}
	}
	if (BuildNewGameStateFn == none)
	{
		strError = "missing BuildNewGameStateFn";
		return false;
	}
	if (OverrideAbilities.Length > 0)
	{
		Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		for (i = 0; i < OverrideAbilities.Length; ++i)
		{
			if (Manager.FindAbilityTemplate(OverrideAbilities[i]) == none)
			{
				strError = "specified OverrideAbilities[" $ i $ "]" @ OverrideAbilities[i] @ "does not exist";
				return false;
			}
		}
	}
	if (AdditionalAbilities.Length > 0)
	{
		if (Manager == none)
			Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		for (i = 0; i < AdditionalAbilities.Length; ++i)
		{
			if (Manager.FindAbilityTemplate(AdditionalAbilities[i]) == none)
			{
				strError = "specified AdditionalAbility" @ AdditionalAbilities[i] @ "does not exist";
				return false;
			}
		}
	}
	
	if (!ValidateEffectList(AbilityShooterEffects, strError)) return false;
	if (!ValidateEffectList(AbilityTargetEffects, strError)) return false;
	if (!ValidateEffectList(AbilityMultiTargetEffects, strError)) return false;

	return true;
}

function bool ValidateEffectList(const out array<X2Effect> Effects, out string strError)
{
	local X2Effect EffectIter, LoopTestEffect;
	local name DamageType;
	local X2DamageTypeTemplate DamageTypeTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<int> EffectsIndices;
	local int EffectIndex;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach Effects(EffectIter)
	{
		foreach EffectIter.DamageTypes(DamageType)
		{
			DamageTypeTemplate = ItemTemplateManager.FindDamageTypeTemplate(DamageType);
			if (DamageTypeTemplate == none)
			{
				strError = "Effect" @ EffectIter @ "has unknown damage type" @ DamageType;
				return false;
			}
		}

		// Loop over the Effects, checking that MultiTargetStatContestInfo does not introduce a loop
		EffectsIndices.Length = 0;
		LoopTestEffect = EffectIter;
		EffectIndex = Effects.Find(LoopTestEffect);
		while ((EffectIndex != INDEX_NONE) &&
			   (LoopTestEffect.MultiTargetStatContestInfo.MaxNumberAllowed > 0))
		{
			if (EffectsIndices.Find(EffectIndex) != INDEX_NONE)
			{
				strError = "Effect" @ EffectIter @ "introduces a loop through its MultiTargetStatContestInfo";
				return false;
			}

			EffectsIndices.AddItem(EffectIndex);
			EffectIndex = LoopTestEffect.MultiTargetStatContestInfo.EffectIdxToApplyOnMaxExceeded;
			if (EffectIndex != INDEX_NONE)
			{
				LoopTestEffect = Effects[EffectIndex];
			}
		}
	}

	return true;
}

simulated function string GetExpandedDescription(XComGameState_Ability AbilityState, XComGameState_Unit StrategyUnitState, bool bUseLongDescription, XComGameState CheckGameState)
{
	local X2AbilityTag AbilityTag;
	local string RetStr, ExpandStr;
	local XComGameState_Unit UnitState;

	if (bUseLongDescription)
		ExpandStr = LocLongDescription;
	else
		ExpandStr = LocHelpText;

	if (AbilityState != none)
	{		
		if (LocLongDescriptionWhenConcealed != "")
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
			if (UnitState != none && UnitState.IsConcealed())
				ExpandStr = LocLongDescriptionWhenConcealed;
		}
	}
	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = AbilityState == None ? self : AbilityState;
	AbilityTag.StrategyParseObj = StrategyUnitState;
	AbilityTag.GameState = CheckGameState;
	RetStr = `XEXPAND.ExpandString(ExpandStr);
	AbilityTag.ParseObj = none;
	AbilityTag.StrategyParseObj = none;
	AbilityTag.GameState = none;
	return RetStr;
}

simulated function string GetMyHelpText(optional XComGameState_Ability AbilityState, optional XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return GetExpandedDescription(AbilityState, UnitState, false, CheckGameState);
}

simulated function string GetMyLongDescription(optional XComGameState_Ability AbilityState, optional XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return GetExpandedDescription(AbilityState, UnitState, true, CheckGameState);
}

simulated function bool HasLongDescription()
{
	return LocLongDescription != "";
}

simulated function string GetExpandedPromotionPopupText(XComGameState_Unit StrategyUnitState)
{
	local X2AbilityTag AbilityTag;
	local string RetStr;

	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = self;
	AbilityTag.StrategyParseObj = StrategyUnitState;
	RetStr = `XEXPAND.ExpandString(LocPromotionPopupText);
	AbilityTag.ParseObj = none;
	AbilityTag.StrategyParseObj = none;
	return RetStr;
}

simulated function UISummary_Ability GetUISummary_Ability(optional XComGameState_Unit UnitState)
{
	local UISummary_Ability Data; 

	Data.Name = LocFriendlyName; 
	if( Data.Name == "" ) Data.Name = "MISSING NAME:" @ string(Name); // Use the instance name, for debugging. 
	
	if( HasLongDescription() )
		Data.Description = GetMyLongDescription(, UnitState);
	else
		Data.Description = GetMyHelpText(, UnitState);
	
	if( Data.Description == "" )
		Data.Description = "MISSING BOTH LONG DESCRIPTION AND HELP TEXT.";

	Data.Icon = IconImage; 

	return Data; 
}

simulated function int GetUISummary_HackingBreakdown(out UIHackingBreakdown kBreakdown, int TargetID)
{
	return -1;
}

simulated function bool IsMelee()
{
	local X2AbilityToHitCalc_StandardAim StandardAimHitCalc;
	local bool bIsMelee;

	bIsMelee = false;
	StandardAimHitCalc = X2AbilityToHitCalc_StandardAim(AbilityToHitCalc);
	if( StandardAimHitCalc != None )
	{
		bIsMelee = StandardAimHitCalc.bMeleeAttack;
	}

	return bIsMelee;
}

simulated function bool ShouldPlayMeleeDeath()
{
	return IsMelee() && bOverrideMeleeDeath == false;
}

function SetUIStatMarkup(String InLabel,
	optional ECharStatType InStatType = eStat_Invalid,
	optional int Amount = 0,
	optional bool ForceShow = false,
	optional delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShowUIStatFn)
{
	local UIAbilityStatMarkup StatMarkup; 
	local int Index;

	// Check to see if a modification for this stat already exists in UIStatMarkups
	Index = UIStatMarkups.Find('StatType', InStatType);
	if (Index != INDEX_NONE)
	{
		UIStatMarkups.Remove(Index, 1); // Remove the old stat markup
	}

	StatMarkup.StatLabel = InLabel;
	StatMarkup.StatModifier = Amount;
	StatMarkup.StatType = InStatType;
	StatMarkup.bForceShow = ForceShow;
	StatMarkup.ShouldStatDisplayFn = ShowUIStatFn;

	UIStatMarkups.AddItem(StatMarkup);
}

function int GetUIStatMarkup(ECharStatType Stat)
{
	local delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;
	local int Index;

	for (Index = 0; Index < UIStatMarkups.Length; ++Index)
	{
		ShouldStatDisplayFn = UIStatMarkups[Index].ShouldStatDisplayFn;
		if (ShouldStatDisplayFn != None && !ShouldStatDisplayFn())
		{
			continue;
		}

		if (UIStatMarkups[Index].StatType == Stat)
		{
			return UIStatMarkups[Index].StatModifier;
		}
	}

	return 0;
}

function name GetPerkAssociationName( )
{
	if (MP_PerkOverride != '')
	{
		return MP_PerkOverride;
	}

	return DataName;
}

// check for conditions that can never be true for this unit during the coming tactical battle
simulated function bool ConditionsEverValidForUnit(XComGameState_Unit SourceUnit, bool bStrategyCheck)
{
	local X2Condition TestCondition;

	foreach AbilityShooterConditions(TestCondition)
	{
		if( !TestCondition.CanEverBeValid(SourceUnit, bStrategyCheck) )
		{
			return false;
		}
	}

	foreach AbilityTargetConditions(TestCondition)
	{
		if( !TestCondition.CanEverBeValid(SourceUnit, bStrategyCheck) )
		{
			return false;
		}
	}

	return true;
}

DefaultProperties
{
	ShotHUDPriority = -1;	
	bNoConfirmationWithHotKey = false;
	iAmmoAsChargesDivisor = 1
	Hostility = eHostility_Offensive
	CameraPriority = eCameraPriority_CharacterMovementAndFraming //Default to movement type priority
	bFriendlyFireWarning = true;

	TargetingMethod = class'X2TargetingMethod_TopDown'
	bDisplayInUITooltip = true
	bDisplayInUITacticalText = true
	FrameAbilityCameraType=eCameraFraming_IfNotNeutral
	bFrameEvenWhenUnitIsHidden=false
	DefaultKeyBinding = -1;

	bAllowedByDefault = true

	ActionFireClass=class'X2Action_Fire'

	TargetKilledByAlienSpeech="EngagingHostiles"
	TargetKilledByXComSpeech="TargetKilled" 
	MultiTargetsKilledByAlienSpeech="EngagingHostiles"
	MultiTargetsKilledByXComSpeech="MultipleTargetsKilled"
	TargetWingedSpeech="TargetWinged"
	TargetArmorHitSpeech="TargetArmorHit"
	TargetMissedSpeech="TargetMissed"

	bSkipPerkActivationActionsSync=true
	SuperConcealmentLoss = -1;
	ChosenActivationIncreasePerUse = -1;
	LostSpawnIncreasePerUse = -1;

	AbilityPointCost = 10;
	TriggerChance=100
}
