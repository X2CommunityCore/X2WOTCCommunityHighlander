//---------------------------------------------------------------------------------------
//  FILE:    X2CharacterTemplate.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
// TEMPORARY RRA OVERRIDE UNTIL POTENTIAL CHL RELEASE OF OnGetPawnArchetypeString
//---------------------------------------------------------------------------------------
class X2CharacterTemplate extends X2DataTemplate config(GameData_CharacterStats)
	native(core)
	dependson(X2TacticalGameRulesetDataStructures, X2StrategyGameRulesetDataStructures, XGNarrative);

// This is the name of the character group this template belongs to.  For each character group, the first time a unit of that group is seen by XCom will be 
// treated as a big reveal, and the group will also be used as the classification mechanic for the Shadow Chamber to identify unique enemy types.  
// Templates which do not specify a group will not have big reveals and will not appear in the Shadow Chamber display.
var config Name        CharacterGroupName;

var config float CharacterBaseStats[ECharStatType.EnumCount]<BoundEnum=ECharStatType>;
var config array<SoldierClassStatType> RandomizedBaseStats; // Allows for randomized starting stats, will overwrite values from CharacterBaseStats.
var int UnitSize;
var int UnitHeight;
var float KillContribution;
var config float XpKillscore;
var config int DirectXpAmount;
var int MPPointValue;
var class<XGAIBehavior> BehaviorClass;
var float VisionArcDegrees;	        // The limit, in degrees, of this unit's vision

var array<name> Abilities;
var LootCarrier Loot;
var LootCarrier TimedLoot;
var LootCarrier VultureLoot;
var name        DefaultLoadout;
var name        RequiredLoadout;
var array<AttachedComponent> SubsystemComponents;
var config array<name> HackRewards;                 //  Names of HackRewardTemplates that are available for this unit
var config Vector AvengerOffset;                    //  Used for offseting cosmetic pawns from their owning pawn in the avenger

// Any requirements to be met before this character template is permitted to spawn using normal spawning rules.
var StrategyRequirement SpawnRequirements;

// The maximum number of characters of this type that can spawn into the same spawning group (pod).
var config int MaxCharactersPerGroup;

// The list of Characters (specified by template name) which can ever be selected as followers when this Character
// is selected as a Pod Leader.
var config array<Name> SupportedFollowers;
	
// Traversal flags
var(X2CharacterTemplate) bool bCanUse_eTraversal_Normal;
var(X2CharacterTemplate) bool bCanUse_eTraversal_ClimbOver;
var(X2CharacterTemplate) bool bCanUse_eTraversal_ClimbOnto;
var(X2CharacterTemplate) bool bCanUse_eTraversal_ClimbLadder;
var(X2CharacterTemplate) bool bCanUse_eTraversal_DropDown;
var(X2CharacterTemplate) bool bCanUse_eTraversal_Grapple;
var(X2CharacterTemplate) bool bCanUse_eTraversal_Landing;
var(X2CharacterTemplate) bool bCanUse_eTraversal_BreakWindow;
var(X2CharacterTemplate) bool bCanUse_eTraversal_KickDoor;
var(X2CharacterTemplate) bool bCanUse_eTraversal_JumpUp;
var(X2CharacterTemplate) bool bCanUse_eTraversal_WallClimb;
var(X2CharacterTemplate) bool bCanUse_eTraversal_Phasing;
var(X2CharacterTemplate) bool bCanUse_eTraversal_BreakWall;
var(X2CharacterTemplate) bool bCanUse_eTraversal_Launch;
var(X2CharacterTemplate) bool bCanUse_eTraversal_Flying;
var(X2CharacterTemplate) bool bCanUse_eTraversal_Land;
var int  MaxFlightPitchDegrees;             // when flying up/down, how far is the unit allowed to pitch into the flight path?
var float SoloMoveSpeedModifier;	        // Play rate of the run animations when the character moves alone.

var bool bIsTooBigForArmory;
var bool bCanBeCriticallyWounded;
var bool bCanBeCarried;                     // true if this unit can be carried when incapacitated
var bool bCanBeRevived;					    // true if this unit can be revived by Revival Protocol ability
var bool bCanBeTerrorist;                   // Is it applicable to use this unit on a terror mission? (eu/ew carryover)
var bool bDiesWhenCaptured;				    // true if unit dies instead of going MIA
var bool bAppearanceDefinesPawn;			// If true, the appearance information assembles a unit pawn. True for soldiers & civilians, false for Aliens & Advent (they're are all one piece)
var bool bIsAfraidOfFire;					// will panic when set on fire - only applies to flamethrower
var bool bIsAlien;							// used by targeting 
var bool bIsHumanoid;						// Added late for targeting. Only ExludeNonHumanoidAliens uses it. 2 Aliens specify humanoid, Spectre and Codex
var bool bIsAdvent;							// used by targeting 
var bool bIsCivilian;						// used by targeting
var bool bDisplayUIUnitFlag;				// used by UnitFlag
var bool bNeverSelectable;					// used by TacticalController
var bool bIsHostileCivilian;				// used by spawning
var bool bIsPsionic;						// used by targeting 
var bool bIsRobotic;						// used by targeting 
var bool bIsSoldier;						// used by targeting 
var bool bIsCosmetic;						// true if this unit is visual only, and has no effect on game play or has a separate game state for game play ( such as the gremlin )
var bool bIsTurret;							// true iff this character is a turret
var bool bIsChosen;							// true iff this character activates as a chosen unit
var bool bCanTakeCover;						// by default should be true, but certain large units, like mecs and andromedons, etc, don't take cover, so set to false.
var bool bIsExalt;							// used by targeting; deprecated - (eu/ew carryover)
var bool bIsEliteExalt;						// used by targeting; deprecated - (eu/ew carryover)
var bool bSkipDefaultAbilities;	            // Will not add the default ability set (Move, Dash, Fire, Hunker Down).
var bool bDoesNotScamper;			        // Unit will not scamper when encountering the enemy.
var bool bDoesAlwaysFly;                    //TODO dslonneger: this needs to be removed/updated when the the X2 flying system is overhauled
	 										//Units that always fly will not be snapped to the ground while alive
var bool bAllowSpawnInFire;				    // If true, this unit can spawn in fire-occupied tiles
var bool bAllowSpawnInPoison;				// If true, this unit can spawn in poison-occupied tiles
var bool bAllowSpawnFromATT;				// If true, this unit can be spawned from an Advent Troop Transport
var bool bFacesAwayFromPod;				    // If true, this unit will face away from the pod instead of towards it
var bool bLockdownPodIdleUntilReveal;		// If true, this unit will not be able to do anything between the pod idle and the reveal (won't turn to face)
var bool bWeakAgainstTechLikeRobot;		    // If true, this unit can be hit by tech (i.e. bluescreen rounds, emp, etc) like a robotic unit
var bool bUsesWillSystem;                   // If true, this unit gains and loses will and can acquire phobias    

var bool bIsMeleeOnly;					    //true if this unit has no ranged attacks. Used primarily for flank checks
    
var bool bUsePoolSoldiers;                  //Character pool - Which pool category this character falls under
var bool bUsePoolVIPs;                      //"
var bool bUsePoolDarkVIPs;                  //"
    
var bool bIsScientist;						// used for staffing
var bool bIsEngineer;						// used for staffing
var bool bStaffingAllowed;					// used for staffing gameplay
var bool bAppearInBase;						// used for the unit visually appearing as a filler unit in the base
var bool bWearArmorInBase;					// if this unit should wear their full armor around the base instead of an underlay
var array<name> AppearInStaffSlots;			// if bAppearInBase is true, the character will still be allowed to appear in staff slots in this list
    
var bool bBlocksPathingWhenDead;			// If true, units cannot path into or through the tile(s) this unit is on when dead.
var bool bCanTickEffectsEveryAction;		// If true, persistent effects will be allowed to honor the bCanTickEveryAction flag
var bool bManualCooldownTick;				// If true, ability cooldowns will not automatically decrease at the start of this unit's turn
    
var bool bHideInShadowChamber;				// If true, do not display this enemy in pre-mission Shadow Chamber lists
var bool bDontClearRemovedFromPlay;			// Used for strategy state units, should not change their bRemovedFromPlay status when entering tactical
var bool bDontUseOTSTargetingCamera;		// If true, standard attacks made against this target will use a top-down midpoint camera instead of the usual OTS camera while targeting

var bool bIsResistanceHero;					// Used for XPack, if the unit is a resistance faction hero class
var bool bImmueToFalling;					// Specific identifier for character types that shouldn't fall as flying traversal is no longer correct

var int InitiativePriority;					// This value used to indicate the order in which units should act relative to each other when on the same team.  
											// Currently only affects the ordering of AIGroups based on the total priority of all contained units.

var(X2CharacterTemplate) array<string> strPawnArchetypes;
var localized string strCharacterName;
var localized array<string> strCharacterBackgroundMale;
var localized array<string> strCharacterBackgroundFemale;
var localized string strCharacterHealingPaused;             // Unique string to display if the character's healing project is paused
var localized string strForcedFirstName;                    // Certain characters have set names
var localized string strForcedLastName;                     // Certain characters have set names
var localized string strForcedNickName;                     // Certain characters have set names
var localized string strCustomizeDesc;                      // Certain characters need unique strings to describe their customization options
var localized string strAcquiredText;                       // Certain characters need to display additional information in their unit acquired pop-up
var(X2CharacterTemplate) config array<string> strMatineePackages;                // names of the packages that contains this character's cinematic matinees
var(X2CharacterTemplate) string strTargetingMatineePrefix;                       // prefix of the character specific targeting matinees for this character
var(X2CharacterTemplate) string strIntroMatineeSlotPrefix;                       // prefix of the matinee groups this character can fill in mission intros
var(X2CharacterTemplate) string strLoadingMatineeSlotPrefix;                     // prefix of the matinee groups this character can fill in the loading interior
var(X2CharacterTemplate) string strHackIconImage;           // The path to the icon for the hacking UI
var(X2CharacterTemplate) string strTargetIconImage;         // The path to the icon for the targeting UI

// if this delegate is specified, it will be called to determine the appropriate reveal to play.
// otherwise, the default is to use RevealMatineePrefix, and if that is blank, the matinee package name
var delegate<GetRevealMatineePrefix> GetRevealMatineePrefixFn;
var(X2CharacterTemplate) string RevealMatineePrefix;
var(X2CharacterTemplate) bool bRevealMatineeAlwaysValid;
var(X2CharacterTemplate) bool bDisableRevealLookAtCamera;
var(X2CharacterTemplate) bool bDisableRevealForceVisible;	// Usually during the X2Action_RevealAIBegin the unit is forced visible, when true this make it not visible
var(X2CharacterTemplate) bool bNeverShowFirstSighted;	// when true, this unit type will never display a first sighted visualization sequence

var bool bSetGenderAlways; //This flag indicates that this character should always get a gender assigned, use on characters where bAppearanceDefinesPawn is FALSE but they want a gender anyways
var bool bForceAppearance; //Indicates that this character should use ForceAppearance to set its appearance
var bool bHasFullDefaultAppearance; // This character's default appearance should be used when creating the unit (not just by the character generator)
var bool bHasCharacterExclusiveAppearance; // This character should only pull customization options specifically marked for it when filtering by character
var config TAppearance ForceAppearance; //If bForceAppearance and bAppearanceDefinesPawn are true, this structure can be used to force this character type to use a certain appearance
var config TAppearance DefaultAppearance; //Use to force a set of default appearance settings for this character. For instance - setting their armor tint to a specific value
var class<UICustomize> UICustomizationMenuClass; // UI menu class for customizing this soldier
var class<UICustomize> UICustomizationInfoClass; // UI info class for customizing this soldier
var class<UICustomize> UICustomizationPropsClass; // UI props class for customizing this soldier
var class<UICustomize> UICustomizationHeadClass; // UI props class for customizing this soldier
var class<UICustomize> UICustomizationBodyClass; // UI props class for customizing this soldier
var class<UICustomize> UICustomizationWeaponClass; // UI props class for customizing this soldier
var class<XComCharacterCustomization> CustomizationManagerClass; // Customization manager for this soldier class
var class<XGCharacterGenerator> CharacterGeneratorClass;   // customize the class used for character generation stuff (random appearances, names, et cetera)
var name                        DefaultSoldierClass;   // specific soldier class to set on creation
var name						PhotoboothPersonality; // if this character uses a different personality than the default in the photobooth


var string strBehaviorTree;   	                // By default all AI behavior trees use "GenericAIRoot".
var string strPanicBT;							// Behavior Tree for AI panicking units.  Soldier panic tree now defined in X2Effect_Panicked.

var string strScamperBT;                        // Behavior Tree for scampering units.
var int	ScamperActionPoints;					// Action Points for scampering.  Default = 1.
var float AIMinSpreadDist;                      // Distance (meters) to prefer being away from other teammates. (Destinations within this range get their scores devalued with multiplier below)
												// defaults to class'XGAIBehavior'.DEFAULT_AI_MIN_SPREAD_DISTANCE when unset.
var float AISpreadMultiplier;                   // Multiplier value to apply to locations within above spread distance.  Should be in range (0..1).
												// defaults to class'XGAIBehavior'.DEFAULT_AI_SPREAD_WEIGHT_MULTIPLIER when unset.

var array<int> SkillLevelThresholds;                        // Used to determine non-soldier leveling

var array<XComNarrativeMoment> SightedNarrativeMoments;	    // Add to array in order of conversation
var array<name>				SightedEvents;				    // These events are triggered upon any sighting
var name						DeathEvent;					// This event is triggered when a unit of this character type is killed
var delegate<OnRevealEvent>	OnRevealEventFn;			    // This event triggers when the character is revealed on a mission

var(X2CharacterTemplate) string SpeakerPortrait; // Portrait that shows in a comm link if spoken by this character

var(X2CharacterTemplate) string HQIdleAnim;
var(X2CharacterTemplate) string HQOffscreenAnim;
var(X2CharacterTemplate) string HQOnscreenAnimPrefix;
var(X2CharacterTemplate) Vector HQOnscreenOffset;

var name ReactionFireDeathAnim;	//The animation to play when killed by reaction fire.

var delegate<OnStatAssignmentComplete> OnStatAssignmentCompleteFn;
var delegate<OnEndTacticalPlay> OnEndTacticalPlayFn;
var bool bIgnoreEndTacticalHealthMod; // Do not adjust health at the end of tactical missions
var bool bIgnoreEndTacticalRestoreArmor; // Do not restore armor at the end of tactical missions
var delegate<OnCosmeticUnitCreated> OnCosmeticUnitCreatedFn;
var delegate<GetPawnName> GetPawnNameFn;
var name AcquiredPhobiaTemplate; // Template of the phobia that this unit can inflict on XCom. e.g. "FearOfVipers" for vipers.

var array<name> ImmuneTypes;
var bool CanFlankUnits;

var(X2CharacterTemplate) bool bAllowRushCam; // should usually be turned off for very large units, as the camera will be too close
var(X2CharacterTemplate) bool bDisablePodRevealMovementChecks; // for stationary aliens, forces no checks for pod reveal matinees moving into walls

var private transient TAppearance FilterAppearance;
var string strAutoRunNonAIBT; // for turrets, or any BTs that should get auto-kicked-off at start of the (non-ai) turn.
var int AIOrderPriority; // default 0. Lower numbers get priority in turn order.

var float ChallengePowerLevel; // In Challenge mode, power level assigned to this unit if they are in your squad

var( X2CharacterTemplate ) Array<AnimSet> AdditionalAnimSets;
var( X2CharacterTemplate ) Array<AnimSet> AdditionalAnimSetsFemale;

var config string strSkirmishImage;

// some characters need to do different reveal matinees based on their current state.
// this delegate allows characters to specify that matinee prefix
delegate string GetRevealMatineePrefix(XComGameState_Unit UnitState);

// to modify game states after the character has been revealed
delegate OnRevealEvent(XComGameState_Unit UnitState);

// some characters need to have modified stats after they are created
delegate OnStatAssignmentComplete(XComGameState_Unit UnitState);

// to handle any special stuff after a cosmetic unit has been created in tactical - this should be placed on the "owning" unit template, not the cosmetic unit template
delegate OnCosmeticUnitCreated(XComGameState_Unit CosmeticUnit, XComGameState_Unit OwnerUnit, XComGameState_Item SourceItem, XComGameState StartGameState);

// some characters do not use the standard M/F soldier pawn when in the strategy layer
delegate name GetPawnName(optional EGender Gender);

// modify stats and game states when tactical play ends, such as health mods
delegate OnEndTacticalPlay(XComGameState_Unit UnitState);

function XComGameState_Unit CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(NewGameState.CreateNewStateObject(class'XComGameState_Unit', self));

	return Unit;
}


private function bool FilterPawnWithGender(X2BodyPartTemplate Template)
{
	local bool bValidTemplate;

	bValidTemplate = Template.CharacterTemplate == DataName; //Verify that it fits this character type
	bValidTemplate = bValidTemplate && FilterAppearance.iGender == int(Template.Gender); //Verify gender

	return bValidTemplate;
}

private function bool FilterPawnWithGenderAndGhost(X2BodyPartTemplate Template)
{
	local bool bValidTemplate;

	bValidTemplate = Template.CharacterTemplate == DataName; //Verify that it fits this character type
	bValidTemplate = bValidTemplate && FilterAppearance.iGender == int(Template.Gender); //Verify gender
	bValidTemplate = bValidTemplate && FilterAppearance.bGhostPawn == Template.bGhostPawn; // Jwats: Verify it is a ghost pawn

	return bValidTemplate;
}

simulated function string GetPawnArchetypeString(XComGameState_Unit kUnit, optional const XComGameState_Unit ReanimatedFromUnit = None)
{
	local string SelectedArchetype;
	local X2BodyPartTemplate ArmorPartTemplate;
	
	// Start Issue #1521, Allow runtime override of SelectedArchetype.
    local XComLWTuple Tuple;
	// End Issue #1521

	//If bAppearanceDefinesPawn is set to TRUE, then the pawn's base mesh is the head, and the rest of the parts of the body are customizable
	if (bAppearanceDefinesPawn)
	{
		//Supporting legacy unit configurations, where nmTorso was the pawn		
		if(!bForceAppearance && kUnit.kAppearance.nmPawn == '')
		{
			FilterAppearance = kUnit.kAppearance;
			ArmorPartTemplate = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().GetRandomUberTemplate("Pawn", self, FilterPawnWithGenderAndGhost);
		}
		else
		{	
			FilterAppearance = bForceAppearance ? ForceAppearance : kUnit.kAppearance;
			ArmorPartTemplate = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().FindUberTemplate("Pawn", FilterAppearance.nmPawn);
		}

		if(ArmorPartTemplate != none)
		{
			return ArmorPartTemplate.ArchetypeName;
		}
			
		`assert(false);
	}
	
	if (strPawnArchetypes.Length == 1) //Exactly one archetype, use that
	{
		SelectedArchetype = strPawnArchetypes[0];
	}
	else if(EGender(kUnit.kAppearance.iGender) != eGender_None) //If we have a gender, assign a pawn based on that
	{
		SelectedArchetype = strPawnArchetypes[kUnit.kAppearance.iGender - 1];
	}
	
	//If the gender selection failed, or we are genderless then randomly pick from the list
	if(SelectedArchetype == "")
	{
		SelectedArchetype = strPawnArchetypes[`SYNC_RAND(strPawnArchetypes.Length)];
	}
	
	// Start Issue #1521, Allow runtime override of SelectedArchetype (kUnit is NOT none for ELD_Immediate)
		Tuple = new class'XComLWTuple';
    Tuple.Id = 'OnGetPawnArchetypeString';
    Tuple.Data.Add(3);
    Tuple.Data[0].kind = XComLWTVString;
    Tuple.Data[0].s    = "";                 // [0] the override: listeners may supply a custom archetype string (leave empty to abstain).
		Tuple.Data[1].kind = XComLWTVString;
		Tuple.Data[1].s    = SelectedArchetype;  // [1] read-only reference: the pre-hook SelectedArchetype (reference only; do not modify).
		Tuple.Data[2].kind = XComLWTVInt;
		Tuple.Data[2].i    = 0;                  // [2] arbitration hint: integer priority for listeners to set/read (higher wins by convention).

    `XEVENTMGR.TriggerEvent(Tuple.Id, Tuple, kUnit, none); // Listeners may set [0].s (and optionally [2].i).

	// Adopt listener-supplied result only if provided (non-empty); otherwise, keep the original.
	if (Tuple.Data[0].s != "")
	{
		SelectedArchetype = Tuple.Data[0].s;
	}
	// End Issue #1521

	return SelectedArchetype;
}

// Scaling accessors
native function float GetCharacterBaseStat(ECharStatType StatType) const;


cpptext
{
public:
	virtual void PostLoad();
};

DefaultProperties
{
	VisionArcDegrees=360
	TemplateAvailability=BITFIELD_GAMEAREA_Singleplayer // Defaulting all Character Templates to Singleplayer; NOTE: Must manually add Multiplayer to characters!
	bAllowSpawnFromATT=true
	AIMinSpreadDist=-1 // default value forces use of class'XGAIBehavior'.DEFAULT_AI_MIN_SPREAD_DISTANCE when unset
	strBehaviorTree = "GenericAIRoot"
	strPanicBT = "PanickedRoot"
	strScamperBT = "GenericScamperRoot"
	ScamperActionPoints = 1
	strTargetingMatineePrefix="CIN_Soldier_FF_StartPos"

	MaxFlightPitchDegrees=89
	SoloMoveSpeedModifier=1.0f;

	bIsHostileCivilian = false;
	CanFlankUnits = true;

	KillContribution = 1.0;

	UnitSize = 1;
	UnitHeight = 2;

	bUsePoolSoldiers = false;
	bUsePoolVIPs = false;
	bUsePoolDarkVIPs = false;
	bDisplayUIUnitFlag=true;

	bAllowRushCam=true

	UICustomizationMenuClass = class'UICustomize_Menu'
	UICustomizationInfoClass = class'UICustomize_Info'
	UICustomizationPropsClass = class'UICustomize_Props'
	UICustomizationHeadClass = class'UICustomize_Head'
	UICustomizationBodyClass = class'UICustomize_Body'
	UICustomizationWeaponClass = class'UICustomize_Weapon'
	CustomizationManagerClass = class'XComCharacterCustomization'

	bShouldCreateDifficultyVariants=true

	bRevealMatineeAlwaysValid=false
	bDisableRevealLookAtCamera=false
	bDisableRevealForceVisible=false
	AIOrderPriority=0
}
