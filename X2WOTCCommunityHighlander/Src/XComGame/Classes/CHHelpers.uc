class CHHelpers extends Object config(Game);

//issue #188 - creating a struct and a usable array for modders
struct TeamRequest
{
	var ETeam Team; //eTeam_One and eTeam_Two should be the only ones here.
};
var config array<TeamRequest> ModAddedTeams;
//end issue #188

// Start Issue #93
struct UpgradeSlotHelper
{
	var name TemplateName; // Name of the non-X2WeaponTemplate to be assigned slots (X2WeaponTemplates have NumUpgradeSlots on the template)
	var int NumUpgradeSlots; // The number of slots to assign
};
var config array<UpgradeSlotHelper> NonWeaponUpgradeSlots; // Issue #93 - configure upgrade slots for templates
// End Issue #93

var config int SPAWN_EXTRA_TILE; // Issue #18 - Add extra ini config
var config int MAX_TACTICAL_AUTOSAVES; // Issue #53 - make configurable, only use if over 0

// Start Issue #41 
// allow chosen to ragdoll, and to collide via config.
// will have performance impacts as the physics will not turn off.
var config bool ENABLE_CHOSEN_RAGDOLL;
var config bool ENABLE_RAGDOLL_COLLISION;
// End Issue #41

// Start Issue #44
// Set to true to prevent Multi-part missions escaping the Will loss cap that is defined in most will rolls
var config bool MULTIPART_MISSION_WILL_LOSS_CAP;
// End Issue #44

//start issue #82
//allow factions to be filtered at game start so we don't have broken base game factions
var config array<name> EXCLUDED_FACTIONS;
//end issue #82

//start issue #85
//variable for controlling whether the game is allowed to track whether a unit has ever gotten a trait before
//this is kept disabled for balance reasons
var config bool CHECK_CURED_TRAITS;
//end issue #85

// Start Issue #80
// List of classes to exclude from rolling awc abilities
// These classes have bAllowAWCAbilities set to true just to participate in the ComInt / AP system
var config array<name> ClassesExcludedFromAWCRoll;
// End Issue #80

// Start Issue #123
// List of AbilityTemplateNames that have associated XComPerkContent
var config array<name> AbilityTemplatePerksToLoad;
// End Issue #123

// start issue #113
// list of classes to exclude from being considered "needed" by XComGameState_HeadquartersResistance
// these are for classes which are meant to be rarely acquired via rookie level up, though others may also be here for their own reasons
var config array<name> ClassesExcludedFromResHQ;
//end issue #113

// Start Issue #186
// This is a performance improvement, so we want the default setting to actually change the game behavior
// This change shouldn't break anything, but the logic is so tightly interfaced with native code I want to provide
// an easy opt-out in case it breaks anything, especially in combination with mods that relied on quirky behavior.
// If it turns out that this setting has any noticable effects with Materials, that should be considered a separate issue
// and fixed before touching this again.
var config bool UPDATE_MATERIALS_CONSTANTLY;
// End Issue #186

// Start Issue #155
// In the base game, XComGameState_Unit doesn't care about sliders all that much. However, the fix to
// handle sliders correctly has one problem -- mods may add part types for a specific armor and assign
// it a DLC Name. If those parts are the only valid ones, but the roll fails, we have invisible parts.
// Hence, we allow DLCNames to be specified here that are excluded by the chance roll and are always
// valid, effectively making them "vanilla" parts (parts without a DLCName)
var config array<name> CosmeticDLCNamesUnaffectedByRoll;
// End Issue #155

// start issue #251
// in the base game, all units default to the clerk underlays if they can use underlays on the Avenger
// we can have the game use custom underlay cosmetics instead, but the base game doesn't properly assign the starting
// underlay cosmetics to normal soldiers. So we use a config array to whitelist character templates that should be using custom underlay cosmetics
var config array<name> CustomUnderlayCharTemplates;
//end issue #251


// Start Issue #171
var config bool GrenadeRespectUniqueRule;
var config bool AmmoSlotBypassUniqueRule;
// End Issue #171

// Start Issue #219
// Object names of head contents that don't allow Hair/Props/Helmets/Beards
/// HL-Docs: ref:ModAddedHeads
var config(Content) array<name> HeadSuppressesHair;
var config(Content) array<name> HeadSuppressesLowerFaceProp;
var config(Content) array<name> HeadSuppressesUpperFaceProp;
var config(Content) array<name> HeadSuppressesHelmet;
var config(Content) array<name> HeadSuppressesBeard;
// End Issue #219


// Issue #153
var config bool bDontUnequipCovertOps; // true skips unequipping soldiers on covert actions even if ambush risk is 0
// End Issue #153

// Start Issue #310
var config bool bDontUnequipWhenWounded; // true skips unequipping soldiers after mission when being wounded
// End Issue #310

// Start Issue #356
/// HL-Docs: feature:TintMaterialConfigs; issue:356; tags:customization,pawns
/// When determining which values to pass to the material using which parameter
/// names, the game matches against a hardcoded list of material names. As a
/// result, mods need to confusingly name their modified materials exactly
/// the same as base-game materials. This change moves these hardcoded names to
/// config lists:
/// HL-Include:
var config(Content) array<name> HairMaterial;
var config(Content) array<name> SkinMaterial;
var config(Content) array<name> ArmorMaterial;
var config(Content) array<name> WepAsArmorMaterial;
var config(Content) array<name> EyeMaterial;
var config(Content) array<name> FlagMaterial;
/// You can add your own materials by creating the following lines in `XComContent.ini`:
///
/// ```ini
/// [XComGame.CHHelpers]
/// +EyeMaterial="MyCustomEyesCustomizable_TC"
/// ```
// End Issue #356

// Start Issue #465
var config bool PreserveProxyUnitData;
// End Issue #465
// Start Issue #317
/// HL-Docs: ref:PersonalitySpeech
struct CharSpeachLookup
{
	var name CharSpeech;
	var array <name> PersonalityVariant;
};

struct PersonalitySpeechLookup
{
	var name Personality;
	var array <CharSpeachLookup> CharSpeeches;
};

var config array <PersonalitySpeechLookup> PersonalitySpeech;
// End Issue #317

// Start Issue #476
var config array<name> RequiresTargetingActivation;
// End Issue #476

// Start Issue #485
var config array<name> AdditionalAmbushRiskTemplates;
// End Issue #485

// Start Issue #322
var config bool UseNewPersonnelStatusBehavior;
// End Issue #322

// Start Issue #543
var config bool bSkipCampaignIntroMovies;
// End Issue #543

// Start Issue #510
//
// Sound range for "yelling" to alert enemy units.
var config int NoiseAlertSoundRange;

// Additional action point types supported by the `eBTCV_ActionPoints`
// stat in AI behavior tree conditions. This is required to allow mods
// to utilize custom action point types for reflex actions and actually
// have units use those action points after scampering.
var config array<name> AdditionalAIBTActionPointTypes;
// End Issue #510

// variable for issue #620
var config bool bConsiderAlliesforSoundAlerts;

// Variable for Issue #724
var config array<name> ValidReserveAPForUnitFlag;

// Start Issue #855
/// HL-Docs: feature:PlaceEvacZoneAbilityName; issue:855; tags:tactical
/// Config variable (of type name) that allows mods to override the name of
/// the ability used for placing/throwing evac zones in tactical missions.
/// This is because the base game hard codes the ability name used for the
/// controller's R3 button, which is bad if a mod (like LWOTC) replaces
/// PlaceEvacZone with a different ability.
///
/// Note that this variable only affects the input system. If you want to
/// replace the ability itself, you will still need to do the hard work of
/// creating the new ability, giving it to soldiers, handling evac zone
/// destruction, etc.
var config name PlaceEvacZoneAbilityName;
// End Issue #855

// Variable for Issue #854
var config float CameraRotationAngle;

// Variable for Issue #917
var config bool bDisableBetaStrikePostMissionHealing;

// Variable for Issue #1081
var config bool bShowAllTraitAcquiredPopups;

// Start Issue #669
//
/// HL-Docs: feature:GrenadesRequiringUnitsOnTargetedTiles; issue:669; tags:tactical
/// An array of grenade template names for which only units actually on
/// painted tiles should be affected by that grenade. Main example is
/// smoke, since only units on smoked tiles should get the effect.
var config array<name> GrenadesRequiringUnitsOnTargetedTiles;

/// HL-Docs: feature:DisableExtraLOSCheckForSmoke; issue:669; tags:tactical
/// When true, this option fixes smoke so that it applies to all tiles that
/// are highlighted in targeting (as per the Reliable Smoke mod).
var config bool DisableExtraLOSCheckForSmoke;

/// HL-Docs: feature:DisableExtraLOSCheckForPoison; issue:669; tags:tactical
/// When true, this option fixes poison so that clouds of it apply to all
/// tiles that are highlighted in targeting.
var config bool DisableExtraLOSCheckForPoison;
// End Issue #669

// Variable for Issue #1191
var config bool bForceEuroDateStrings;

// Start Issue #720
/// HL-Docs: ref:ProjectilePerformanceDrain
struct ProjectileParticleSystemExpirationOverride
{
	var string ParticleSystemPathName;
	var float ExpiryTime;
};
var config array<ProjectileParticleSystemExpirationOverride> ProjectileParticleSystemExpirationOverrides;

// Intended for debugging and personal configuration - not covered by BC!
var config float ProjectileParticleSystemExpirationDefaultOverride;
// End Issue #720

// Variable for Issue #817 - put the string here, as UIOptionsPCScreen is native and cannot have new variables.
var localized string m_strFramerateSmoothingDisabledReason;

// Variable for Issue #1245 - enables the triggering of the DrawDebugLabels CHL event
var config bool bDrawDebugLabels;

// Variable for Issue #599 - 0-100 chance of using a character pool character when CP is in Mixed mode.
var config int iMixedCharacterPoolChance;

// Variable for Issue #579 - makes UIUnitFlagManager use ability's minimum damage rather than maximum damage for the preview.
var config bool bUseMinDamageForUnitFlagPreview;

// Variable for Issue #1228 - disables Aim Assist.
var config bool bDisableAimAssist;

// Start Issue #1325 - Grants control over what happens to a unit when they start an interruption.
var config bool EnableImprovedInterruptionLogic;
var config bool InterruptionsGiveActionPoints;
var config bool InterruptionsResetUntouchable;
var config bool InterruptionsResetGotFreeFireAction;
var config bool InterruptionsHandleMovementUnitValues;
var config bool InterruptionsCleanupBeginTurnUnitValues;
var config bool InterruptionsUpdateTurnStartLocation;
var config bool InterruptionsResetPanicTestsPerformedThisTurn;
var config bool InterruptionsTriggerGroupTurnBegunEvent;
// End Issue #1325

// Variables for Issue #1400 - forces 24h clock regardless of locale
var config bool bForce24hClock;
var config bool bForce24hclockLeadingZero;

// Start Issue #1578 - Variables to adjust Geoscape behaviour when flying
var config bool bUseSourceTimeZoneWhenFlying;
var config bool bUseDestinationTimeZoneWhenFlying;
var config bool bForceUTCAtAllTimes;
var config bool bShowEventQueueWhileFlying;

// Variable for Issue #1398 - Number of seconds to wait after a unit is killed before playing the 'OnSquadMemberDead' voiceline
var config float fSquadMemberDeadVoicelineDelay;

// Start Issue #1453 - Variables to disable automatic photobooth photos
var config bool bDisableAutomaticMissionPhoto;
var config bool bDisableAutomaticMemorialPhoto;
var config bool bDisableAutomaticPromotionPhoto;
var config bool bDisableAutomaticBondPhoto;
var config bool bManualPhotoTakenOnLastMission;
// End Issue #1453

// Variable for Issue #1559 - enables AI units to path out of hazards that block their normal movement cache.
var config bool bEnableAIHazardEscape;

// Begin Issue #1540
var config bool PREVIEW_ARMOR_MITIGATION;
// End Issue #1540

// Start Issue #1591 
/// HL-Docs: feature:ImprovedHitImmunityLogic-BypassStasisSustain; issue:1591; tags:tactical
/// This feature provides improved CanAbilityHit, IsImmuneToDamage and ProvidesDamageImmunity
/// functions which pass in optional ability names and contexts, in order to allow mods to have 
/// more granular control over when certain abilities are able to hit and damage.
/// Three arrays are also provided for direct configuration of abilities which can bypass stasis and/or sustain. To use:
/// 1. Add attacking abilities which can bypass Stasis, applied by any ability, to AbilitiesToBypassStasis
/// 2. Add attacking abilities which can bypass Sustain, but not stasis from any source to AbilitiesToBypassSustain
/// 3. Add defensive 'sustain-like' abilities to AbilitiesConsideredAsSustain
var config bool bEnableImprovedCanHitAndImmunityLogic;
var config array<name> AbilitiesToBypassStasis;        
var config array<name> AbilitiesToBypassSustain;      
var config array<name> AbilitiesConsideredAsSustain; 
// End Issue #1591

// Start Issue #885
enum EHLDelegateReturn
{
	EHLDR_NoInterrupt,       // All subsequent delegates will be processed.
	EHLDR_InterruptDelegates // Any subsequent delegates listeners will not be processed.
};

struct ShouldDisplayMultiSlotItemInStrategyStruct
{
	var delegate<ShouldDisplayMultiSlotItemInStrategyDelegate> ShouldDisplayMultiSlotItemInStrategyFn;
	var int Priority;

	structdefaultproperties
	{
		Priority = 50
	}
};
struct ShouldDisplayMultiSlotItemInTacticalStruct
{
	var delegate<ShouldDisplayMultiSlotItemInTacticalDelegate> ShouldDisplayMultiSlotItemInTacticalFn;
	var int Priority;

	structdefaultproperties
	{
		Priority = 50
	}
};
var protectedwrite array<ShouldDisplayMultiSlotItemInStrategyStruct> ShouldDisplayMultiSlotItemInStrategyCallbacks;
var protectedwrite array<ShouldDisplayMultiSlotItemInTacticalStruct> ShouldDisplayMultiSlotItemInTacticalCallbacks;
// End Issue #885

// Start Issue #851
struct OverrideHasHeightAdvantageStruct
{
	var delegate<OverrideHasHeightAdvantageDelegate> OverrideHasHeightAdvantageFn;
	var int Priority;

	structdefaultproperties
	{
		Priority = 50
	}
};
var protectedwrite array<OverrideHasHeightAdvantageStruct> OverrideHasHeightAdvantageCallbacks;
// End Issue #851

// Start Issue #1565
struct OverrideCoverLevelStruct
{
	var delegate<OverrideCoverLevelDelegate> OverrideCoverLevelFn;
	var int Priority;

	structdefaultproperties
	{
		Priority = 50
	}
};
var protectedwrite array<OverrideCoverLevelStruct> OverrideCoverLevelCallbacks;
// End Issue #1565

// Start Issue #1540
struct AdjustArmorMitigationStruct
{
    var delegate<AdjustArmorMitigationDelegate> AdjustArmorMitigationFn;
    var int Priority;
    
    structdefaultproperties
    {
        Priority = 50
    }
};
var protectedwrite array<AdjustArmorMitigationStruct> AdjustArmorMitigationCallbacks;
// End Issue #1540

// Start Issue #1542
struct OverrideDefenseBypassStruct
{
    var delegate<OverrideDefenseBypassDelegate> OverrideDefenseBypassFn;
    var int Priority;
    
    structdefaultproperties
    {
        Priority = 50
    }
};
var protectedwrite array<OverrideDefenseBypassStruct> OverrideDefenseBypassCallbacks;
// End Issue #1542

// Start Issue #1138
struct PrioritizeRightClickMeleeStruct
{
	var delegate<PrioritizeRightClickMeleeDelegate> PrioritizeRightClickMeleeFn;
	var int Priority;

	structdefaultproperties
	{
		Priority = 50
	}
};
var protectedwrite array<PrioritizeRightClickMeleeStruct> PrioritizeRightClickMeleeCallbacks;
// End Issue #1138

delegate EHLDelegateReturn ShouldDisplayMultiSlotItemInStrategyDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XComUnitPawn UnitPawn, optional XComGameState CheckGameState); // Issue #885
delegate EHLDelegateReturn ShouldDisplayMultiSlotItemInTacticalDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XGUnit UnitVisualizer, optional XComGameState CheckGameState); // Issue #885
delegate EHLDelegateReturn OverrideHasHeightAdvantageDelegate(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, out int bHasHeightAdvantage); // Issue #851
delegate EHLDelegateReturn PrioritizeRightClickMeleeDelegate(XComGameState_Unit UnitState, out XComGameState_Ability PrioritizedMeleeAbility, optional XComGameState_BaseObject TargetObject); // Issue #1138

delegate EHLDelegateReturn OverrideCoverLevelDelegate(XComGameState_Unit Attacker, XComGameState_Unit Target, out GameRulesCache_VisibilityInfo VisInfo, Object EventSource); // Issue #1565

delegate EHLDelegateReturn AdjustArmorMitigationDelegate(int WeaponDamage, out int ArmorMitigation, out int ArmorPiercing, out int MinMitigation, out int ArmorShred, EffectAppliedData ApplyEffectParams, X2Effect_ApplyWeaponDamage Source, optional bool ForMinDamagePreview, optional XComGameState NewGameState); // Issue #1540

delegate EHLDelegateReturn OverrideDefenseBypassDelegate(array<name> AppliedDamageTypes, out int bIgnoreArmor, out int bIgnoreShields, EffectAppliedData ApplyEffectParams, X2Effect_ApplyWeaponDamage Source, optional XComGameState NewGameState); // Issue #1542

// Start Issue #123
simulated static function RebuildPerkContentCache() {
	local XComContentManager		Content;
	local name						AbilityTemplateName;

	Content = `CONTENT;
	Content.BuildPerkPackageCache();
	foreach default.AbilityTemplatePerksToLoad(AbilityTemplateName) {
		Content.CachePerkContent(AbilityTemplateName);
	}
}
// End Issue #123

//start issue #188 - functions for checking the config array
static function bool TeamOneRequired()
{
	local TeamRequest CheckedRequest;
	
	foreach default.ModAddedTeams(CheckedRequest)
	{
		if(CheckedRequest.Team == eTeam_One){
			return true;
		}
	}
	
	return false;
}

static function bool TeamTwoRequired()
{
	local TeamRequest CheckedRequest;
	
	foreach default.ModAddedTeams(CheckedRequest)
	{
		if(CheckedRequest.Team == eTeam_Two){
			return true;
		}
	}
	
	return false;
}

static function XGAIPlayer GetTeamOnePlayer()
{
	local XComGameState_Player PlayerState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.TeamFlag == eTeam_One)
		{
			break;
		}
	}

	return PlayerState.TeamFlag == eTeam_One ? XGAIPlayer(PlayerState.GetVisualizer()) : none;

}

static function XGAIPlayer GetTeamTwoPlayer()
{
	local XComGameState_Player PlayerState;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.TeamFlag == eTeam_Two)
		{
			break;
		}
	}

	return PlayerState.TeamFlag == eTeam_Two ? XGAIPlayer(PlayerState.GetVisualizer()) : none;

}
//end issue #188

//start issue #155
static function array<name> GetAcceptablePartPacks()
{
	local int Index;
	local XComOnlineProfileSettings ProfileSettings;
	local X2BodyPartTemplateManager PartTemplateManager;
	local int PartPackIndex;
	local array<name> PartPackNames, DLCNames;
	local bool bHasSetting;

	ProfileSettings = `XPROFILESETTINGS;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartPackNames = PartTemplateManager.GetPartPackNames();
		
	DLCNames.Length = 0;
	DLCNames.AddItem(''); //this represents vanilla or otherwise unassigned parts
	for(PartPackIndex = 0; PartPackIndex < PartPackNames.Length; ++PartPackIndex)
	{
		bHasSetting = false;
		if (default.CosmeticDLCNamesUnaffectedByRoll.Find(PartPackNames[PartPackIndex]) != INDEX_NONE)
		{
			bHasSetting = true;
			DLCNames.AddItem(PartPackNames[PartPackIndex]);
		}
		else
		{
			for(Index = 0; Index < ProfileSettings.Data.PartPackPresets.Length; ++Index)
			{
				if(ProfileSettings.Data.PartPackPresets[Index].PartPackName == PartPackNames[PartPackIndex])
				{
					bHasSetting = true;
					if (`SYNC_FRAND_STATIC() <= ProfileSettings.Data.PartPackPresets[Index].ChanceToSelect &&
						ProfileSettings.Data.PartPackPresets[Index].ChanceToSelect > 0.02f) //0.02 so sliders being set to the minimum actually do something
					{
						DLCNames.AddItem(ProfileSettings.Data.PartPackPresets[Index].PartPackName);
						break;
					}
				}
			}
		}

		//Handle the case where a setting has not been specified in the options menu
		if(!bHasSetting && `SYNC_FRAND_STATIC() <= class'XGCharacterGenerator'.default.DLCPartPackDefaultChance)
		{
			DLCNames.AddItem(PartPackNames[PartPackIndex]);
		}
	}

	return DLCNames;
}
//end issue #155

// Issue #235 start
static function GroupItemStatsByLabel(out array<UISummary_ItemStat> InArray)
{
	local int i, j, iValue, jValue;

	for (i = 0; i < InArray.Length; i++)
	{
		for (j = i+1; j < InArray.Length; j++)
		{
			if (InArray[i].Label == InArray[j].Label)
			{
				iValue = int(InArray[i].Value);
				jValue = int(InArray[j].Value);

				if (string(iValue) != InArray[i].Value || string(jValue) != InArray[j].Value) // The values are not string representations of ints. Ignore this one.
				{
					continue;
				}

				InArray[i].Value = string(iValue + jValue);
				InArray.Remove(j, 1);
				j--; // Important! Removing an entry in the array shifts all other entries down one. Don't skip an entry by accident.
			}
		}

		// We actually DO want to show any stats that total 0, so the player doesn't think their modifications got ignored
		//if (InArray[i].Value == 0)
		//{
			//InArray.Remove(i, 1);
			//i--; // Important! Removing an entry in the array shifts all other entries down one. Don't skip an entry by accident.
		//}
	}
}
// Issue #235 end

// Start Issue #257
/// HL-Docs: feature:OverrideUnitFocusUI; issue:257; tags:tactical,compatibility
/// This focus change allows mods to change the focus UI that the vanilla game uses
/// to display Templar Focus. This effectively creates different types of Focus, even
/// though the game does not know about this. For example, you can create a custom
/// soldier class with its own type of focus, tracked with a `UnitValue`.
/// This imposes a few limitations on the system:
///
/// * A given unit only ever has a single "type" of focus. The rules for different focus
///   types are expected to be so different from one another to make any conflicts
///   a painful experience for modders and players.
///   In particular, it means that this function should NOT be used to make any changes
///   to the Templar Focus, as tempting as it may be.
/// * This also includes an Effect of the name `TemplarFocus` or an Effect Class of the type
///   `XComGameState_Effect_TemplarFocus`.
///
/// In order to add your custom focus types, there are two changes in XComGame you can use:
///
/// * A new event hook for `UIUnitFlag` and `UITacticalHUD_SoldierInfo`: Documentation for that
///   particular hook is directly below.
/// * A change in `X2AbilityCost_Focus`: You may subclass that particular class and override all
///   functions declared there (`CanAfford`, `ApplyCost`, `PreviewFocusCost`). This can be used to
///   preview a cost for custom skills that consume focus. Again, make sure to not mix and match
///   custom subclasses with the base class for any abilities.
///
/// ```event
/// EventID: OverrideUnitFocusUI,
/// EventData: [
///     inout bool bVisible,
///     inout int currentFocus,
///     inout int maxFoxus,
///     inout string color,
///     inout string iconPath,
///     inout string tooltipText,
///     inout string focusLabel
/// ],
/// EventSource: XComGameState_Unit (SourceUnit),
/// NewGameState: none
/// ```
///
/// Note that if `bVisible == false`, the rest will be ignored and will not have valid data in it.
///
/// ## Compatibility
///
/// If you override `UIUnitFlag`, your code may undo the HL's changes that
/// support this feature in the UI. See the tracking issue for code samples.

// Static helper function used from UIUnitFlag and UITacticalHUD_SoldierInfo
// to build a tuple used for mod-communication.
static function XComLWTuple GetFocusTuple(XComGameState_Unit UnitState)
{
	local XComLWTuple Tup;

	Tup = BuildDefaultTuple(UnitState);

	`XEVENTMGR.TriggerEvent('OverrideUnitFocusUI', Tup, UnitState, none);

	return Tup;
}

static function XComLWTuple BuildDefaultTuple(XComGameState_Unit UnitState)
{
	local XComGameState_Effect_TemplarFocus FocusState;
	local XComLWTuple Tup;

	Tup = new class'XComLWTuple';
	Tup.Id = 'OverrideUnitFocusUI';
	Tup.Data.Add(7);
	Tup.Data[0].kind = XComLWTVBool;
	Tup.Data[1].kind = XComLWTVInt;
	Tup.Data[2].kind = XComLWTVInt;
	Tup.Data[3].kind = XComLWTVString;
	Tup.Data[4].kind = XComLWTVString;
	Tup.Data[5].kind = XComLWTVString;
	Tup.Data[6].kind = XComLWTVString;

	FocusState = UnitState.GetTemplarFocusEffectState();
	if (FocusState == none || !UnitState.IsFriendlyToLocalPlayer())
	{
		Tup.Data[0].b = false;
		return Tup;
	}
	else
	{
		Tup.Data[0].b = true;
	}

	Tup.Data[1].i = FocusState.FocusLevel;
	Tup.Data[2].i = FocusState.GetMaxFocus(UnitState);
	Tup.Data[3].s = "0x" $ class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;
	Tup.Data[4].s = "";
	Tup.Data[5].s = `XEXPAND.ExpandString(class'UITacticalHUD_SoldierInfo'.default.FocusLevelDescriptions[FocusState.FocusLevel]);
	Tup.Data[6].s = class'UITacticalHUD_SoldierInfo'.default.FocusLevelLabel;

	return Tup;
}
// End Issue #257

// Start Issue #388
static function UpdateTransitionMap()
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;
	local string OverrideMapName;

	// Issue #212 use CHDLCHookManager
	DLCInfos = `DLCHOOKMGR.GetDLCInfos('LoadingScreenOverrideTransitionMap');
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		DLCInfos[i].LoadingScreenOverrideTransitionMap(OverrideMapName);
	}
	if (Len(OverrideMapName) > 0)
	{
		`MAPS.SetTransitionMap(OverrideMapName);
	}
}
// End Issue #388

// Start Issue #476
static function bool TargetingClassRequiresActivation(X2TargetingMethod TargetingMethod)
{
	local int i;

	for (i = 0; i < default.RequiresTargetingActivation.Length; i++)
	{
		if (TargetingMethod.IsA(default.RequiresTargetingActivation[i]))
		{
			return true;
		}
	}

	return false;
}
// End Issue #476

// Start Issue #485
static function array<name> GetAmbushRiskTemplateNames()
{
	local array<name> TemplateNames;

	TemplateNames = default.AdditionalAmbushRiskTemplates;
	TemplateNames.AddItem('CovertActionRisk_Ambush');

	return TemplateNames;
}
// End Issue #485

// start issue #619
static function array<XComGameState_Player> GetEnemyPlayers( XGPlayer AIPlayer)
{
    local array<XComGameState_Player> EnemyPlayers;
    local XComGameState_Player PlayerStateObject, EnemyStateObject, StateObject;
 
    if (AIPlayer == none)
        return EnemyPlayers;
 
    PlayerStateObject = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(AIPlayer.ObjectID));
 
    foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', StateObject)
    {
        if (StateObject.ObjectID == PlayerStateObject.ObjectID)
            continue;
        //Ignore civilians, this check is for checking actual enemies to the unit
        if (StateObject.GetTeam() == ETeam_Neutral)
            continue;
        EnemyStateObject = StateObject;
        if (PlayerStateObject.IsEnemyPlayer(EnemyStateObject))
 
        if (EnemyStateObject != none)
        {
            EnemyPlayers.AddItem(EnemyStateObject);
        }  
    }
    return EnemyPlayers;
}
// end issue #619

// Start Issue #885
/// HL-Docs: feature:DisplayMultiSlotItems; issue:885; tags:pawns
/// This feature allows mods to make items equipped in multi-item inventory slots visible on soldiers' bodies. 
/// The vanilla behavior is that only the first item in the Utility Slot is visible on the soldier's body,
/// and only in Tactical, but not in the Armory.
///
/// With this feature it's possible to conditionally show all items in all multi-slots, including Highlander-templated slots.
/// Highlander-templated slots, in addition to this feature, also need to have `NeedsPresEquip = true` to display in Tactical, 
/// and `ShowOnCinematicPawns = true` to display in the Armory and Squad Select.
///
/// # How to use
///
/// Implement the following code in your `X2DownloadableContentInfo` class:
///
/// ```unrealscript
/// static event OnPostTemplatesCreated()
/// {
/// 	local CHHelpers CHHelpersObj;
/// 
/// 	CHHelpersObj = class'CHHelpers'.static.GetCDO();
/// 	CHHelpersObj.AddShouldDisplayMultiSlotItemInStrategyCallback(ShouldDisplayMultiSlotItemInStrategy);
/// 	CHHelpersObj.AddShouldDisplayMultiSlotItemInTacticalCallback(ShouldDisplayMultiSlotItemInTactical);
/// }
///
/// // To avoid crashes associated with garbage collection failure when transitioning between Tactical and Strategy,
/// // these functions must be bound to the ClassDefaultObject of your class. Having these functions in a class that 
/// // `extends X2DownloadableContentInfo` is the easiest way to ensure that.
///
/// // Determines whether the specified item should be visible on specified unit in the Armory, Squad Select and Post Mission Sequence.
/// static private function EHLDelegateReturn ShouldDisplayMultiSlotItemInStrategy(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XComUnitPawn UnitPawn, optional XComGameState CheckGameState)
/// {
/// 	// Optionally modify bDisplayItem here. If `bDisplayItem` is `1`, the item will be visible.
/// 	// If `bDisplayItem` is `0` it will not be visible.
/// 
/// 	// Return EHLDR_NoInterrupt or EHLDR_InterruptDelegates depending on 
/// 	// if you want to allow other delegates to run after yours
/// 	// and potentially modify bHasHeightAdvantage further.
/// 	return EHLDR_NoInterrupt;
/// }
///
/// // Determines whether the specified item should be visible on specified unit in Tactical.
/// static private function bool ShouldDisplayMultiSlotItemInTactical(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XGUnit UnitVisualizer, optional XComGameState CheckGameState)
/// {
/// 	// Optionally modify bDisplayItem here.
/// 	return EHLDR_NoInterrupt;
/// }
/// ```
///
/// You can get the template name of the item in question from the provided ItemState by doing `ItemState.GetMyTemplateName()`, 
/// and access its Inventory Slot as `ItemState.InventorySlot`.
///
/// Both delegates may or may not provide you with an XComGameState that can be used to access accompanying state objects, for example:
///
/// ```unrealscript
/// if (CheckGameState != none)
/// {
/// 	MyState = CheckGameState.GetGameStateForObjectID(ObjectID);
/// }
/// 
/// if (MyState == none)
/// {
/// 	MyState = `XCOMHISTORY.GetGameStateForObjectID(ObjectID);
/// }
///
/// // Alternatively, for items in a unit's inventory:
/// ItemState = UnitState.GetItemGameState(ItemRef, CheckGameState);
/// ItemState = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState);
/// ItemStates = UnitState.GetAllItemsInSlot(eInvSlot_Utility, CheckGameState);
/// ```
/// This is mostly relevant for multiplayer, as the pre-game setup doesn't have a History.

/// HL-Docs: ref:DisplayMultiSlotItems
/// # Delegate Priority
/// When adding a delegate, you can optionally specify Priority. 
///```unrealscript
///CHHelpersObj.AddShouldDisplayMultiSlotItemInStrategyCallback(ShouldDisplayMultiSlotItemInStrategy, 45);
///```
/// Delegates with higher Priority value are executed first. 
/// Delegates with the same Priority are executed in the order they were added to CHHelpers,
/// which would normally is the same as [DLCRunOrder](../misc/DLCRunOrder.md).
/// The "Add...Callback functions return `true` if the delegate was successfully registered.
// Strategy Layer
simulated function bool AddShouldDisplayMultiSlotItemInStrategyCallback(delegate<ShouldDisplayMultiSlotItemInStrategyDelegate> ShouldDisplayMultiSlotItemInStrategyFn, optional int Priority = 50)
{
	local ShouldDisplayMultiSlotItemInStrategyStruct NewShouldDisplayMultiSlotItemInStrategyCallback;
	local int i, PriorityIndex;
	local bool bPriorityIndexFound;

	if (ShouldDisplayMultiSlotItemInStrategyFn == none)
	{
		return false;
	}
	// Cycle through the array of callbacks backwards
	for (i = ShouldDisplayMultiSlotItemInStrategyCallbacks.Length - 1; i >= 0; i--)
	{
		// Do not allow registering the same delegate more than once.
		if (ShouldDisplayMultiSlotItemInStrategyCallbacks[i].ShouldDisplayMultiSlotItemInStrategyFn == ShouldDisplayMultiSlotItemInStrategyFn)
		{
			return false;
		}

		// Record the array index of the callback whose priority is higher or equal to the priority of the new callback,
		// so that the new callback can be inserted right after it.
		if (ShouldDisplayMultiSlotItemInStrategyCallbacks[i].Priority >= Priority && !bPriorityIndexFound)
		{
			PriorityIndex = i + 1; // +1 so that InsertItem puts the new callback *after* this one. 

			//	Need to assign the priority index only once so that highest priority delegates do not fall through to become 2nd last member of the array.
			//	Keep cycling through the array so that the previous check for duplicate delegates can run for every currently registered delegate.
			bPriorityIndexFound = true;
		}
	}

	NewShouldDisplayMultiSlotItemInStrategyCallback.Priority = Priority;
	NewShouldDisplayMultiSlotItemInStrategyCallback.ShouldDisplayMultiSlotItemInStrategyFn = ShouldDisplayMultiSlotItemInStrategyFn;
	ShouldDisplayMultiSlotItemInStrategyCallbacks.InsertItem(PriorityIndex, NewShouldDisplayMultiSlotItemInStrategyCallback);

	return true;
}

/// HL-Docs: ref:DisplayMultiSlotItems
/// # Removing Delegates
/// If necessary, it's possible to remove a delegate.
///```unrealscript
///CHHelpersObj.RemoveShouldDisplayMultiSlotItemInStrategyCallback(ShouldDisplayMultiSlotItemInStrategy);
///CHHelpersObj.RemoveShouldDisplayMultiSlotItemInTacticalCallback(ShouldDisplayMultiSlotItemInTactical);
///```
/// `Remove...Callback` functions will return `true` if the Callback was successfully deleted, return false otherwise.
simulated function bool RemoveShouldDisplayMultiSlotItemInStrategyCallback(delegate<ShouldDisplayMultiSlotItemInStrategyDelegate> ShouldDisplayMultiSlotItemInStrategyFn)
{
	local int i;

	for (i = ShouldDisplayMultiSlotItemInStrategyCallbacks.Length - 1; i >= 0; i--)
	{
		if (ShouldDisplayMultiSlotItemInStrategyCallbacks[i].ShouldDisplayMultiSlotItemInStrategyFn == ShouldDisplayMultiSlotItemInStrategyFn)
		{
			ShouldDisplayMultiSlotItemInStrategyCallbacks.Remove(i, 1);
			return true;
		}
	}
	return false;
}

// Called from XComUnitPawn to determine whether a visualizer for this item should be created to make the item visible on the cosmetic pawn in the Armory and Squad Select.
simulated function bool ShouldDisplayMultiSlotItemInStrategy(XComGameState_Unit UnitState, XComGameState_Item ItemState, EInventorySlot InventorySlot, XComUnitPawn UnitPawn, optional XComGameState CheckGameState)
{
	local int i, bDisplayItem;
	local delegate<ShouldDisplayMultiSlotItemInStrategyDelegate> ShouldDisplayMultiSlotItemInStrategyFn;

	for (i = 0; i < ShouldDisplayMultiSlotItemInStrategyCallbacks.Length; i++)
	{	
		ShouldDisplayMultiSlotItemInStrategyFn = ShouldDisplayMultiSlotItemInStrategyCallbacks[i].ShouldDisplayMultiSlotItemInStrategyFn;

		if (ShouldDisplayMultiSlotItemInStrategyFn(UnitState, ItemState, bDisplayItem, UnitPawn, CheckGameState) == EHLDR_InterruptDelegates)
		{
			break;
		}
	}
	return bDisplayItem > 0;
}

// Tactical Layer
simulated function bool AddShouldDisplayMultiSlotItemInTacticalCallback(delegate<ShouldDisplayMultiSlotItemInTacticalDelegate> ShouldDisplayMultiSlotItemInTacticalFn, optional int Priority = 50)
{
	local ShouldDisplayMultiSlotItemInTacticalStruct NewShouldDisplayMultiSlotItemInTacticalCallback;
	local int i, PriorityIndex;
	local bool bPriorityIndexFound;

	for (i = ShouldDisplayMultiSlotItemInTacticalCallbacks.Length - 1; i >= 0; i--)
	{
		if (ShouldDisplayMultiSlotItemInTacticalCallbacks[i].ShouldDisplayMultiSlotItemInTacticalFn == ShouldDisplayMultiSlotItemInTacticalFn)
		{
			return false;
		}

		if (ShouldDisplayMultiSlotItemInTacticalCallbacks[i].Priority >= Priority && !bPriorityIndexFound)
		{
			PriorityIndex = i + 1;
			bPriorityIndexFound = true;
		}
	}

	NewShouldDisplayMultiSlotItemInTacticalCallback.Priority = Priority;
	NewShouldDisplayMultiSlotItemInTacticalCallback.ShouldDisplayMultiSlotItemInTacticalFn = ShouldDisplayMultiSlotItemInTacticalFn;
	ShouldDisplayMultiSlotItemInTacticalCallbacks.InsertItem(PriorityIndex, NewShouldDisplayMultiSlotItemInTacticalCallback);

	return true;
}

simulated function bool RemoveShouldDisplayMultiSlotItemInTacticalCallback(delegate<ShouldDisplayMultiSlotItemInTacticalDelegate> ShouldDisplayMultiSlotItemInTacticalFn)
{
	local int i;

	for (i = ShouldDisplayMultiSlotItemInTacticalCallbacks.Length - 1; i >= 0; i--)
	{
		if (ShouldDisplayMultiSlotItemInTacticalCallbacks[i].ShouldDisplayMultiSlotItemInTacticalFn == ShouldDisplayMultiSlotItemInTacticalFn)
		{
			ShouldDisplayMultiSlotItemInTacticalCallbacks.Remove(i, 1);
			return true;
		}
	}
	return false;
}

// Called from XGUnit to determine if this item should be PRES-equipped.
// Item in the first slot of the Utility Slot may be displayed regardless of this delegate's decision.
simulated function bool ShouldDisplayMultiSlotItemInTactical(XComGameState_Unit UnitState, XComGameState_Item ItemState, EInventorySlot InventorySlot, XGUnit UnitVisualizer, optional XComGameState CheckGameState)
{
	local int i, bDisplayItem;
	local delegate<ShouldDisplayMultiSlotItemInTacticalDelegate> ShouldDisplayMultiSlotItemInTacticalFn;

	for (i = 0; i < ShouldDisplayMultiSlotItemInTacticalCallbacks.Length; i++)
	{	
		ShouldDisplayMultiSlotItemInTacticalFn = ShouldDisplayMultiSlotItemInTacticalCallbacks[i].ShouldDisplayMultiSlotItemInTacticalFn;

		if (ShouldDisplayMultiSlotItemInTacticalFn(UnitState, ItemState, bDisplayItem, UnitVisualizer, CheckGameState) == EHLDR_InterruptDelegates)
		{
			break;
		}
	}
	return bDisplayItem > 0;
}

static function CHHelpers GetCDO()
{
	// This is hot code, so use an optimized function here
	return CHHelpers(FindObject("XComGame.Default__CHHelpers", class'CHHelpers'));
}
// End Issue #885

// Start Issue #851
/// HL-Docs: ref:HasHeightAdvantageOverride
/// # Delegate Priority
/// You can optionally specify callback Priority. 
///```unrealscript
///CHHelpersObj.AddOverrideHasHeightAdvantageCallback(OverrideHasHeightAdvantage, 45);
///```
/// Delegates with higher Priority value are executed first. 
/// Delegates with the same Priority are executed in the order they were added to CHHelpers,
/// which would normally be the same as [DLCRunOrder](../misc/DLCRunOrder.md).
/// This function will return `true` if the delegate was successfully registered.
simulated function bool AddOverrideHasHeightAdvantageCallback(delegate<OverrideHasHeightAdvantageDelegate> OverrideHasHeightAdvantageFn, optional int Priority = 50)
{
	local OverrideHasHeightAdvantageStruct NewOverrideHasHeightAdvantageCallback;
	local int i, PriorityIndex;
	local bool bPriorityIndexFound;

	if (OverrideHasHeightAdvantageFn == none)
	{
		return false;
	}
	// Cycle through the array of callbacks backwards
	for (i = OverrideHasHeightAdvantageCallbacks.Length - 1; i >= 0; i--)
	{
		// Do not allow registering the same delegate more than once.
		if (OverrideHasHeightAdvantageCallbacks[i].OverrideHasHeightAdvantageFn == OverrideHasHeightAdvantageFn)
		{
			return false;
		}

		// Record the array index of the callback whose priority is higher or equal to the priority of the new callback,
		// so that the new callback can be inserted right after it.
		if (OverrideHasHeightAdvantageCallbacks[i].Priority >= Priority && !bPriorityIndexFound)
		{
			PriorityIndex = i + 1; // +1 so that InsertItem puts the new callback *after* this one. 

			//	Keep cycling through the array so that the previous check for duplicate delegates can run for every currently registered delegate.
			bPriorityIndexFound = true;
		}
	}

	NewOverrideHasHeightAdvantageCallback.Priority = Priority;
	NewOverrideHasHeightAdvantageCallback.OverrideHasHeightAdvantageFn = OverrideHasHeightAdvantageFn;
	OverrideHasHeightAdvantageCallbacks.InsertItem(PriorityIndex, NewOverrideHasHeightAdvantageCallback);

	return true;
}

/// HL-Docs: ref:HasHeightAdvantageOverride
/// # Removing Delegates
/// If necessary, it's possible to remove a delegate.
///```unrealscript
///CHHelpersObj.RemoveOverrideHasHeightAdvantageCallback(OverrideHasHeightAdvantage);
///```
/// The function will return `true` if the Callback was successfully deleted, return false otherwise.
simulated function bool RemoveOverrideHasHeightAdvantageCallback(delegate<OverrideHasHeightAdvantageDelegate> OverrideHasHeightAdvantageFn)
{
	local int i;

	for (i = OverrideHasHeightAdvantageCallbacks.Length - 1; i >= 0; i--)
	{
		if (OverrideHasHeightAdvantageCallbacks[i].OverrideHasHeightAdvantageFn == OverrideHasHeightAdvantageFn)
		{
			OverrideHasHeightAdvantageCallbacks.Remove(i, 1);
			return true;
		}
	}
	return false;
}

// Called by XComGameState_Unit::HasHeightAdvantageOver()
// This is an internal CHL API. It is not intended for use by mods and is not covered by Backwards Compatibility policy.
simulated function TriggerOverrideHasHeightAdvantage(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, out int bHasHeightAdvantage)
{
	local delegate<OverrideHasHeightAdvantageDelegate> OverrideHasHeightAdvantageFn;
	local int i;

	for (i = 0; i < OverrideHasHeightAdvantageCallbacks.Length; i++)
	{	
		OverrideHasHeightAdvantageFn = OverrideHasHeightAdvantageCallbacks[i].OverrideHasHeightAdvantageFn;

		if (OverrideHasHeightAdvantageFn(Attacker, TargetUnit, bHasHeightAdvantage) == EHLDR_InterruptDelegates)
		{
			break;
		}
	}
}
// End Issue #851

// Start Issue #1565
/// HL-Docs: feature:CoverLevelOverride; issue:1565; tags:tactical
/// This feature allows mods to override which cover level a unit has against an attack by 
/// another unit on a case-by-case basis, gaining various tactical benefits.
///
/// Normally this override would have been implemented as an event, but events in To Hit Chance Calculation logic can cause issues, 
/// see [GetHitChanceEvents](../tactical/GetHitChanceEvents.md), so the delegates system is used instead.
///
/// This feature applies to X2Effect_HuntersInstinctDamage, X2AbilityToHitCalc_StandardAim, and all descendants thereof.
/// It does not apply to hit calcs if:
///
/// - It is a descendant class which overrides GetHitChance without supporting this feature
/// - The attack is not subject to cover (bIndirectFire, bMeleeAttack)
/// - It *does* apply if bIgnoreCoverBonus is true, *but* does not override its behavior
///
/// It does not apply to Hunter's Instinct if:
///
/// - It is a descendant class which overrides GetAttackingDamageModifier without supporting this feature
/// - The effect would not be affected by cover level (e.g. it's a melee attack and thus ineligible for Hunter's Instinct)
///
/// **NOTE:** While this feature allows the delegate to affect other visibility data, the 
/// results of changing it are not fully understood by the developer. Use with caution!
///
/// ## How to use
///
/// Implement the following code in your mod's `X2DownloadableContentInfo` class:
/// ```unrealscript
/// static event OnPostTemplatesCreated()
/// {
/// 	local CHHelpers CHHelpersObj;
/// 
/// 	CHHelpersObj = class'CHHelpers'.static.GetCDO();
/// 	if (CHHelpersObj != none)
/// 	{
/// 		CHHelpersObj.AddOverrideHasHeightAdvantageCallback(OverrideHasHeightAdvantage);
/// 	}
/// }
///
/// // To avoid crashes associated with garbage collection failure when transitioning between Tactical and Strategy,
/// // this function must be bound to the ClassDefaultObject of your class. Having this function in a class that 
/// // `extends X2DownloadableContentInfo` is the easiest way to ensure that.
/// static private function EHLDelegateReturn OverrideHasHeightAdvantage(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, out GamesRuleCache_VisibilityInfo VisInfo, Object EventSource)
/// {
/// 	// Optionally modify `VisInfo.TargetCover` here. 
/// 	// This is an enum containing the target's cover level against the attacker.
///		
/// 	// Return EHLDR_NoInterrupt or EHLDR_InterruptDelegates depending on 
/// 	// if you want to allow other delegates to run after yours
/// 	// and potentially modify VisInfo further.
/// 	return EHLDR_NoInterrupt;
///}
/// ```
///
/// # Delegate Priority
/// You can optionally specify callback Priority. 
///```unrealscript
///CHHelpersObj.AddOverrideCoverLevelCallback(OverrideCoverLevel, 45);
///```
/// Delegates with higher Priority value are executed first. 
/// Delegates with the same Priority are executed in the order they were added to CHHelpers,
/// which would normally be the same as [DLCRunOrder](../misc/DLCRunOrder.md).
/// This function will return `true` if the delegate was successfully registered.
simulated function bool AddOverrideCoverLevelCallback(delegate<OverrideCoverLevelDelegate> OverrideCoverLevelFn, optional int Priority = 50)
{
	local OverrideCoverLevelStruct NewOverrideCoverLevelCallback;
	local int i, PriorityIndex;
	local bool bPriorityIndexFound;

	if (OverrideCoverLevelFn == none)
	{
		return false;
	}
	// Cycle through the array of callbacks backwards
	for (i = OverrideCoverLevelCallbacks.Length - 1; i >= 0; i--)
	{
		// Do not allow registering the same delegate more than once.
		if (OverrideCoverLevelCallbacks[i].OverrideCoverLevelFn == OverrideCoverLevelFn)
		{
			return false;
		}

		// Record the array index of the callback whose priority is higher or equal to the priority of the new callback,
		// so that the new callback can be inserted right after it.
		if (OverrideCoverLevelCallbacks[i].Priority >= Priority && !bPriorityIndexFound)
		{
			PriorityIndex = i + 1; // +1 so that InsertItem puts the new callback *after* this one. 

			//	Keep cycling through the array so that the previous check for duplicate delegates can run for every currently registered delegate.
			bPriorityIndexFound = true;
		}
	}

	NewOverrideCoverLevelCallback.Priority = Priority;
	NewOverrideCoverLevelCallback.OverrideCoverLevelFn = OverrideCoverLevelFn;
	OverrideCoverLevelCallbacks.InsertItem(PriorityIndex, NewOverrideCoverLevelCallback);

	return true;
}

/// HL-Docs: ref:CoverLevelOverride
/// # Removing Delegates
/// If necessary, it's possible to remove a delegate.
///```unrealscript
///CHHelpersObj.RemoveOverrideCoverLevelCallback(OverrideCoverLevel);
///```
/// The function will return `true` if the Callback was successfully deleted, return false otherwise.
simulated function bool RemoveOverrideCoverLevelCallback(delegate<OverrideCoverLevelDelegate> OverrideCoverLevelFn)
{
	local int i;

	for (i = OverrideCoverLevelCallbacks.Length - 1; i >= 0; i--)
	{
		if (OverrideCoverLevelCallbacks[i].OverrideCoverLevelFn == OverrideCoverLevelFn)
		{
			OverrideCoverLevelCallbacks.Remove(i, 1);
			return true;
		}
	}
	return false;
}

// Should be called by anything that wants to know a unit's cover level.
simulated function TriggerOverrideCoverLevel(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, out GameRulesCache_VisibilityInfo VisInfo, Object EventSource)
{
	local delegate<OverrideCoverLevelDelegate> OverrideCoverLevelFn;
	local int i;

	for (i = 0; i < OverrideCoverLevelCallbacks.Length; i++)
	{	
		OverrideCoverLevelFn = OverrideCoverLevelCallbacks[i].OverrideCoverLevelFn;

		if (OverrideCoverLevelFn(Attacker, TargetUnit, VisInfo, EventSource) == EHLDR_InterruptDelegates)
		{
			break;
		}
	}
}
// End Issue #1565

// Start Issue #1138
/// HL-Docs: ref:PrioritizeRightClickMelee
/// # Delegate Priority
/// You can optionally specify callback Priority. The default Priority is 50.
///```unrealscript
///CHHelpersObj.AddPrioritizeRightClickMeleeCallback(PrioritizeRightClickMelee, 45);
///```
/// Delegates with higher Priority value are executed first. 
/// Delegates with the same Priority are executed in the order they were added to CHHelpers,
/// which would normally be the same as [DLCRunOrder](../misc/DLCRunOrder.md).
/// This function will return `true` if the delegate was successfully registered.
simulated final function bool AddPrioritizeRightClickMeleeCallback(delegate<PrioritizeRightClickMeleeDelegate> PrioritizeRightClickMeleeFn, optional int Priority = 50)
{
	local PrioritizeRightClickMeleeStruct NewPrioritizeRightClickMeleeCallback;
	local int i, PriorityIndex;
	local bool bPriorityIndexFound;

	if (PrioritizeRightClickMeleeFn == none)
	{
		return false;
	}
	// Cycle through the array of callbacks backwards
	for (i = PrioritizeRightClickMeleeCallbacks.Length - 1; i >= 0; i--)
	{
		// Do not allow registering the same delegate more than once.
		if (PrioritizeRightClickMeleeCallbacks[i].PrioritizeRightClickMeleeFn == PrioritizeRightClickMeleeFn)
		{
			return false;
		}

		// Record the array index of the callback whose priority is higher or equal to the priority of the new callback,
		// so that the new callback can be inserted right after it.
		if (PrioritizeRightClickMeleeCallbacks[i].Priority >= Priority && !bPriorityIndexFound)
		{
			PriorityIndex = i + 1; // +1 so that InsertItem puts the new callback *after* this one. 

			//	Keep cycling through the array so that the previous check for duplicate delegates can run for every currently registered delegate.
			bPriorityIndexFound = true;
		}
	}

	NewPrioritizeRightClickMeleeCallback.Priority = Priority;
	NewPrioritizeRightClickMeleeCallback.PrioritizeRightClickMeleeFn = PrioritizeRightClickMeleeFn;
	PrioritizeRightClickMeleeCallbacks.InsertItem(PriorityIndex, NewPrioritizeRightClickMeleeCallback);

	return true;
}

/// HL-Docs: ref:PrioritizeRightClickMelee
/// # Removing Delegates
/// If necessary, use this function to remove a delegate.
///```unrealscript
///CHHelpersObj.RemovePrioritizeRightClickMeleeCallback(PrioritizeRightClickMelee);
///```
/// The function will return `true` if the Callback was successfully deleted, return `false` otherwise.
simulated final function bool RemovePrioritizeRightClickMeleeCallback(delegate<PrioritizeRightClickMeleeDelegate> PrioritizeRightClickMeleeFn)
{
	local int i;

	for (i = PrioritizeRightClickMeleeCallbacks.Length - 1; i >= 0; i--)
	{
		if (PrioritizeRightClickMeleeCallbacks[i].PrioritizeRightClickMeleeFn == PrioritizeRightClickMeleeFn)
		{
			PrioritizeRightClickMeleeCallbacks.Remove(i, 1);
			return true;
		}
	}
	return false;
}

// Called by X2AbilityTrigger_EndOfMove::GetAvailableEndOfMoveAbilityForUnit()
// This is an internal CHL API. It is not intended for use by mods and is not covered by Backwards Compatibility policy.
simulated final function TriggerPrioritizeRightClickMelee(XComGameState_Unit UnitState, out XComGameState_Ability PrioritizedMeleeAbility, optional XComGameState_BaseObject TargetObject)
{
	local delegate<PrioritizeRightClickMeleeDelegate> PrioritizeRightClickMeleeFn;
	local int i;

	for (i = 0; i < PrioritizeRightClickMeleeCallbacks.Length; i++)
	{	
		PrioritizeRightClickMeleeFn = PrioritizeRightClickMeleeCallbacks[i].PrioritizeRightClickMeleeFn;

		if (PrioritizeRightClickMeleeFn(UnitState, PrioritizedMeleeAbility, TargetObject) == EHLDR_InterruptDelegates)
		{
			break;
		}
	}
}
// End Issue #1138

// Start Issue #855
static function name GetPlaceEvacZoneAbilityName()
{
	return default.PlaceEvacZoneAbilityName != '' ? default.PlaceEvacZoneAbilityName : 'PlaceEvacZone';
}
// End Issue #855

// Start Issue #815
static final function SplitSoldierClassAbilityTypeArray(const out array<SoldierClassAbilityType> EligibleAbilities, out array<name> AbilityNames, out array<int> ApplyToWeaponSlots, out array<name> UtilityCats)
{
	local SoldierClassAbilityType AbilityType;

	AbilityNames.Length = 0;
	ApplyToWeaponSlots.Length = 0;
	UtilityCats.Length = 0;

	foreach EligibleAbilities(AbilityType)
	{
		AbilityNames.AddItem(AbilityType.AbilityName);
		ApplyToWeaponSlots.AddItem(AbilityType.ApplyToWeaponSlot);
		UtilityCats.AddItem(AbilityType.UtilityCat);
	}
}

static final function array<SoldierClassAbilityType> RebuildSoldierClassAbilityTypeArray(const out array<name> AbilityNames, const out array<int> ApplyToWeaponSlots, const out array<name> UtilityCats)
{
	local array<SoldierClassAbilityType> AbilityTypes;
	local SoldierClassAbilityType AbilityType;
	local int i;

	if (AbilityNames.Length != ApplyToWeaponSlots.Length || 
		AbilityNames.Length != UtilityCats.Length || 
		ApplyToWeaponSlots.Length != UtilityCats.Length)
	{
		`Redscreen("CHL Warning: CHHelpers::RebuildSoldierClassAbilityTypeArray was given arrays of different lengts as arguments, THIS WILL CAUSE BUGS");
		`Redscreen("AbilityNames:" @ AbilityNames.Length @ ", ApplyToWeaponSlots:" @ ApplyToWeaponSlots.Length @ ", UtilityCats:" @ UtilityCats.Length);
		`Redscreen("Make sure that the arrays have the same number of members before calling this function.");
		`Redscreen(GetScriptTrace());
	}

	i = 0;
	while (i < AbilityNames.Length && i < ApplyToWeaponSlots.Length && i < UtilityCats.Length)
	{
		AbilityType.AbilityName = AbilityNames[i];
		AbilityType.ApplyToWeaponSlot = EInventorySlot(ApplyToWeaponSlots[i]);
		AbilityType.UtilityCat = UtilityCats[i];

		AbilityTypes.AddItem(AbilityType);
		i++;
	}

	return AbilityTypes;
}
// End Issue #815

/// HL-Docs: ref:Bugfixes; issue:1417
/// This helper function uses a more robust check to ensure the geoscape is ready for alerts.
/// This replaces functions that only check for the presence of a UIAlert screen, which can
/// result in popups in places such as Squad Select or the Black Market screen if the campaign date lines up with flight time.
static function bool GeoscapeReadyForUpdate()
{
	local UIStrategyMap StrategyMap;

	StrategyMap = `HQPRES.StrategyMap2D;

	return
		StrategyMap != none &&
		StrategyMap.m_eUIState != eSMS_Flight &&
		StrategyMap.Movie.Pres.ScreenStack.GetCurrentScreen() == StrategyMap;
}

// Begin Issue #1540
/// HL-Docs: feature:AdjustArmorMitigation; issue:1540; tags:tactical
/// This feature allows mods to override the amount of armor mitigation,
/// armor piercing, minimum/mandatory armor mitigation, and/or armor shredding
/// for an attack on a case-by-case basis.
///
/// Normally this override would have been implemented as an event, but the implementing dev heard that events in To Hit Chance Calculation logic can cause issues, 
/// (see [GetHitChanceEvents](../tactical/GetHitChanceEvents.md)), and resorted to delegates in an attempt to resolve a crash he was unable to explain at the time.
///
/// This feature does not apply if the attack ignores armor (e.g. bIgnoreArmor is set to
/// true). Additionally, it only applies to attacks using `X2Effect_ApplyWeaponDamage`,
/// or a subclass which has not overridden its `GetDamagePreview()` and `CalculateDamageAmount`
/// functions (except if they have included support for this feature).
///
/// ## Delegate structure
///
/// - int WeaponDamage: Full damage dealt by the attack before mitigation, to help determine the results.
/// - out int ArmorMitigation: Amount of armor mitigation available to reduce the attack. When first invoked, this is equal to the target's armor, but may be modified by other delegates running before yours.
/// - out int ArmorPiercing: Amount of armor piercing available to reduce mitigation. When first invoked, this is equal to the attack's armor piercing, but may be modified by other delegates running before yours.
/// - out int MinMitigation: Minimum threshold below which mitigation cannot be reduced. When first invoked, this is 0 (per vanilla behavior), but may be modified by other delegates running before yours. Negative values are currently permitted, but will result in undefined behavior.
/// - out int ArmorShred: Amount of armor shredding inflicted by the attack. After all delegates have run, this value is capped to never exceed the target's remaining armor. Negative values are permitted, but will result in undefined behavior.
/// - EffectAppliedData ApplyEffectParams: Effect context containing information such as the parent ability, source and target units, etc., to help determine the results.
/// - X2Effect_ApplyWeaponDamage Source: The effect itself, to help determine the results. *Do not* attempt to modify it or invoke functions which would have side effects.
/// - optional bool ForMinDamagePreview: If invoked by a damage preview, specifies whether `WeaponDamage` contains the minimum or maximum damage for the attack in the previewed hit context.
/// - optional XComGameState NewGameState: The new game state after the attack resolves. If no game state was provided, then the delegate has been invoked by a damage preview (check ForMinDamagePreview to determine which one).
///
/// ## How to use (for end users)
///
/// Implement the following code in your mod's `X2DownloadableContentInfo` class:
/// ```unrealscript
/// static event OnPostTemplatesCreated()
/// {
/// 	local CHHelpers CHHelpersObj;
/// 
/// 	CHHelpersObj = class'CHHelpers'.static.GetCDO();
/// 	if (CHHelpersObj != none)
/// 	{
/// 		CHHelpersObj.AddAdjustArmorMitigationCallback(AdjustArmorMitigation);
/// 	}
/// }
///
/// // To avoid crashes associated with garbage collection failure when transitioning between Tactical and Strategy,
/// // this function must be bound to the ClassDefaultObject of your class. Having this function in a class that 
/// // `extends X2DownloadableContentInfo` is the easiest way to ensure that.
/// static private function EHLDelegateReturn AdjustArmorMitigation(int WeaponDamage, out int ArmorMitigation, out int ArmorPiercing, out int MinMitigation, out int ArmorShred, EffectAppliedData ApplyEffectParams, X2Effect_ApplyWeaponDamage Source, optional bool ForMinDamagePreview, optional XComGameState NewGameState)
/// {
/// 	// Detect whether it's a damage preview (and if so, which kind). 
///     // Then optionally modify any of ArmorMitigation, ArmorPiercing,
///		// MinMitigation, and ArmorShred.
///		
/// 	// Return EHLDR_NoInterrupt or EHLDR_InterruptDelegates depending on 
/// 	// if you want to allow other delegates to run after yours
/// 	// and potentially modify mitigation values further.
/// 	return EHLDR_NoInterrupt;
/// }
/// ```
///
/// ## How to use (for effect/UI devs)
/// 
/// ### Damage Previews
///
/// After all damage has been calculated for the hit context being previewed,
/// invoke `class'CHHelpers'.static.GetCDO().TriggerAdjustArmorMitigation(WeaponDamage, ArmorMitigation, ArmorPiercing, MinMitigation, ArmorShred, ApplyEffectParams, Source, ForMinDamagePreview)`.
///
/// You will need to make separate calls for minimum and maximum damage, using 
/// **separate** variables for `ArmorMitigation`, `ArmorPiercing`, `MinMitigation`, and `ArmorShred`.
/// Set `ForMinDamagePreview` according to whether it is the minimum or maximum damage.
///
/// If previewing multiple hit contexts (e.g. normal and critical hits),
/// make sure to pass *total* damage for that hit context into `WeaponDamage` for correct results.
/// For instance, previewing minimum damage for a 3-5 (+2) weapon should be done with
/// a `WeaponDamage` of 5 (i.e. 3+2), **not** 2.
///
/// If you are not also providing overrides for all UIs that might use your damage preview,
/// then please store the delegate results in your WeaponDamageValue structs,
/// so that downstream UIs will be aware of them and be able to correctly preview them:
///
/// - ArmorMitigation --> WeaponDamageValue.Spread
/// - ArmorPiercing --> WeaponDamageValue.Pierce
/// - MinMitigation --> WeaponDamageValue.PlusOne
///
/// (ArmorShred is not covered in the above list, because you should already have been storing shredding since before this feature was created.)
///
/// ### Damage Calculations
///
/// After all damage has been calculated for the attack, invoke `class'CHHelpers'.static.GetCDO().TriggerAdjustArmorMitigation(WeaponDamage, ArmorMitigation, ArmorPiercing, MinMitigation, ArmorShred, ApplyEffectParams, Source, ForMinDamagePreview, NewGameState)`.
///
/// The value of `ForMinDamagePreview` does not matter, as the delegates should ignore it
/// whenever a `NewGameState` is provided. However, the Highlander implementation passes 
/// `false`, so it is recommended that you do the same for consistency.
///
/// # Delegate Priority
/// You can optionally specify callback Priority. 
///```unrealscript
///CHHelpersObj.AddAdjustArmorMitigationCallback(AdjustArmorMitigation, 45);
///```
/// Delegates with higher Priority value are executed first. 
/// Delegates with the same Priority are executed in the order they were added to CHHelpers,
/// which would normally be the same as [DLCRunOrder](../misc/DLCRunOrder.md).
/// This function will return `true` if the delegate was successfully registered.
simulated function bool AddAdjustArmorMitigationCallback(delegate<AdjustArmorMitigationDelegate> AdjustArmorMitigationFn, optional int Priority = 50)
{
    local AdjustArmorMitigationStruct NewAdjustArmorMitigationCallback;
    local int i, PriorityIndex;
    local bool bPriorityIndexFound;

    if (AdjustArmorMitigationFn == none)
    {
        return false;
    }

    //Cycle through the array of callbacks backwards
    for (i = AdjustArmorMitigationCallbacks.Length - 1; i >= 0; i--)
    {
        // Do not allow registering the same delegate more than once.
        if (AdjustArmorMitigationCallbacks[i].AdjustArmorMitigationFn == AdjustArmorMitigationFn)
        {
            return false;
        }

        // Record the array index of the callback whose priority is higher or equal to the priority of the new callback,
        // so that the new callback can be inserted right after it.
        if (AdjustArmorMitigationCallbacks[i].Priority >= Priority && !bPriorityIndexFound)
        {
            PriorityIndex = i + 1; // +1 so that InsertItem puts the new callback *after* this one.

            // Keep cycling through the array so that the previous check for duplicate delegates can run for every currently registered delegate.
            bPriorityIndexFound = true;
        }
    }

    NewAdjustArmorMitigationCallback.Priority = Priority;
    NewAdjustArmorMitigationCallback.AdjustArmorMitigationFn = AdjustArmorMitigationFn;
    AdjustArmorMitigationCallbacks.InsertItem(PriorityIndex, NewAdjustArmorMitigationCallback);

    return true;
}

simulated function bool RemoveAdjustArmorMitigationCallback(delegate<AdjustArmorMitigationDelegate> AdjustArmorMitigationFn)
{
    local int i;

    for (i = AdjustArmorMitigationCallbacks.Length - 1; i >= 0; i--)
    {
        if (AdjustArmorMitigationCallbacks[i].AdjustArmorMitigationFn == AdjustArmorMitigationFn)
        {
            AdjustArmorMitigationCallbacks.Remove(i, 1);
            return true;
        }
    }
    return false;
}

// Internal helper function to trigger an AdjustArmorMitigation event.
simulated function TriggerAdjustArmorMitigation(int WeaponDamage, out int ArmorMitigation, out int ArmorPiercing, out int MinMitigation, out int ArmorShred, EffectAppliedData ApplyEffectParams, X2Effect_ApplyWeaponDamage Source, optional bool ForMinDamagePreview, optional XComGameState NewGameState)
{
	local delegate<AdjustArmorMitigationDelegate> AdjustArmorMitigationFn;
	local int i;

	for (i = 0; i < AdjustArmorMitigationCallbacks.Length; i++)
	{
		AdjustArmorMitigationFn = AdjustArmorMitigationCallbacks[i].AdjustArmorMitigationFn;

		if (AdjustArmorMitigationFn(WeaponDamage, ArmorMitigation, ArmorPiercing, MinMitigation, ArmorShred, ApplyEffectParams, Source, ForMinDamagePreview, NewGameState) == EHLDR_InterruptDelegates)
		{
			break;
		}
	}	
}

// Helper function to calculate mitigated damage for ShotHUD.
// Only exists because I'm not sure what happens if I pass a literal to an out parameter.
static simulated function CalculateMitigatedDamagePreviewHUD(StateObjectReference Target, WeaponDamageValue MinDamageValue, WeaponDamageValue MaxDamageValue, int AllowsShield, out int MinDamage, out int MaxDamage)
{
	local int Dummy1, Dummy2;
	Dummy1 = 0;
	Dummy2 = 0;
	CalculateMitigatedDamagePreview(Target, MinDamageValue, MaxDamageValue, AllowsShield, MinDamage, MaxDamage, Dummy1, Dummy2);
}

// Helper function to calculate mitigated damage for ShotWings/ShotHUD.
// Quick reminder: Spread holds mitigation, PlusOne holds minimum mitigation. 
static simulated function CalculateMitigatedDamagePreview(StateObjectReference Target, WeaponDamageValue MinDamageValue, WeaponDamageValue MaxDamageValue, int AllowsShield, out int MinDamage, out int MaxDamage, out int NetMitigationMin, out int NetMitigationMax)
{
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnit;
	local int TargetShields;
	local int MandatoryDamage;
	local int GuaranteedDamageMin, GuaranteedDamageMax;
	
	History = `XCOMHISTORY;

	if (MinDamageValue.Spread == 0 && MaxDamageValue.Spread == 0 || Target.ObjectId == 0)
	{
		return;
	}

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectId(Target.ObjectID));
	if (TargetUnit == none)
	{
		return;
	}

	if (!class'X2Effect_ApplyWeaponDamage'.default.NO_MINIMUM_DAMAGE) // Account for issue #321
	{
		MandatoryDamage = 1;
	}
	else
	{
		MandatoryDamage = 0;
	}
	GuaranteedDamageMin = MandatoryDamage;
	GuaranteedDamageMax = MandatoryDamage;

	// If shields are applicable and not subject to mitigation,
	// then we are never guaranteed HP damage, but always
	// guaranteed shield damage so let's preview that.
	if (AllowsShield > 0 && !class'X2Effect_ApplyWeaponDamage'.default.ARMOR_BEFORE_SHIELD) // From issue #743
	{
		TargetShields = TargetUnit.GetCurrentStat(eStat_ShieldHP);
	}
	if (TargetShields > MandatoryDamage)
	{
		GuaranteedDamageMin = min(MinDamage, TargetShields);
		GuaranteedDamageMax = min(MaxDamage, TargetShields);
	}
	
	// This is a bit condensed from the real damage calculator, so to summarize:
	// 1. Subtract piercing from mitigation.
	// 2. Don't let mitigation drop below the minimum mitigation.
	// 3. Now subtract mitigation from damage.
	// 4. Make sure damage is *at least* the guaranteed damage for this attack.
	MinDamage = max(MinDamage - max(MinDamageValue.Spread - MinDamageValue.Pierce, MinDamageValue.PlusOne), min(GuaranteedDamageMin, MinDamage));
	MaxDamage = max(MaxDamage - max(MaxDamageValue.Spread - MaxDamageValue.Pierce, MaxDamageValue.PlusOne), min(GuaranteedDamageMax, MaxDamage));

	// Net mitigation for ShotWings: How much damage did the armor actually prevent?
	NetMitigationMin = MinDamage - MinDamageValue.Damage;
	NetMitigationMax = MaxDamage - MaxDamageValue.Damage;
}
// End Issue #1540

// Begin Issue #1542
/// HL-Docs: feature:OverrideDefenseBypass; issue:1542; tags:tactical
/// This feature allows mods to override the amount of armor mitigation,
/// armor piercing, or minimum/mandatory armor mitigation for an attack
/// on a case-by-case basis.
///
/// Normally this override would have been implemented as an event, but the implementing dev heard that events in To Hit Chance Calculation logic can cause issues, 
/// (see [GetHitChanceEvents](../tactical/GetHitChanceEvents.md)), and resorted to delegates in an attempt to resolve a crash he was unable to explain at the time.
///
/// This feature only applies to attacks using `X2Effect_ApplyWeaponDamage`,
/// or a subclass which has not overridden its `GetDamagePreview()` and `CalculateDamageAmount`
/// functions (except if they have included support for this feature).
///
/// ## Delegate structure
///
/// - array<name> AppliedDamageTypes: All damage types applied to the attack, to help determine the results.
/// - out int bIgnoreArmor: Boolean value specifying whether the attack should ignore armor. Defaults to the corresponding value on the damage effect.
/// - out int bIgnoreShields: Boolean value specifying whether the attack should ignore ablative HP. Defaults to the corresponding value calculated by the damage effect.
/// - EffectAppliedData ApplyEffectParams: Effect context containing information such as the parent ability, source and target units, etc., to help determine the results.
/// - X2Effect_ApplyWeaponDamage Source: The effect itself, to help determine the results. *Do not* attempt to modify it or invoke functions which would have side effects.
/// - optional XComGameState NewGameState: The new game state after the attack resolves. If no game state was provided, then the delegate has been invoked by a damage preview.
///
/// ## How to use
///
/// Implement the following code in your mod's `X2DownloadableContentInfo` class:
/// ```unrealscript
/// static event OnPostTemplatesCreated()
/// {
/// 	local CHHelpers CHHelpersObj;
/// 
/// 	CHHelpersObj = class'CHHelpers'.static.GetCDO();
/// 	if (CHHelpersObj != none)
/// 	{
/// 		CHHelpersObj.AddOverrideDefenseBypassCallback(OverrideDefenseBypass);
/// 	}
/// }
///
/// // To avoid crashes associated with garbage collection failure when transitioning between Tactical and Strategy,
/// // this function must be bound to the ClassDefaultObject of your class. Having this function in a class that 
/// // `extends X2DownloadableContentInfo` is the easiest way to ensure that.
/// static private function EHLDelegateReturn OverrideDefenseBypass(array<name> AppliedDamageTypes, out int bIgnoreArmor, out int bIgnoreShields, EffectAppliedData ApplyEffectParams, X2Effect_ApplyWeaponDamage Source, optional XComGameState NewGameState)
/// {
/// 	// Detect whether it's a damage preview. (... If you even care.)
///     // Then optionally modify either or both of bIgnoreArmor and bIgnoreShields.
///		
/// 	// Return EHLDR_NoInterrupt or EHLDR_InterruptDelegates depending on 
/// 	// if you want to allow other delegates to run after yours
/// 	// and potentially modify defense bypass further.
/// 	return EHLDR_NoInterrupt;
/// }
/// ```
///
/// # Delegate Priority
/// You can optionally specify callback Priority. 
///```unrealscript
///CHHelpersObj.AddOverrideDefenseBypassCallback(OverrideDefenseBypass, 45);
///```
/// Delegates with higher Priority value are executed first. 
/// Delegates with the same Priority are executed in the order they were added to CHHelpers,
/// which would normally be the same as [DLCRunOrder](../misc/DLCRunOrder.md).
/// This function will return `true` if the delegate was successfully registered.
simulated function bool AddOverrideDefenseBypassCallback(delegate<OverrideDefenseBypassDelegate> OverrideDefenseBypassFn, optional int Priority = 50)
{
    local OverrideDefenseBypassStruct NewOverrideDefenseBypassCallback;
    local int i, PriorityIndex;
    local bool bPriorityIndexFound;

    if (OverrideDefenseBypassFn == none)
    {
        return false;
    }

    //Cycle through the array of callbacks backwards
    for (i = OverrideDefenseBypassCallbacks.Length - 1; i >= 0; i--)
    {
        // Do not allow registering the same delegate more than once.
        if (OverrideDefenseBypassCallbacks[i].OverrideDefenseBypassFn == OverrideDefenseBypassFn)
        {
            return false;
        }

        // Record the array index of the callback whose priority is higher or equal to the priority of the new callback,
        // so that the new callback can be inserted right after it.
        if (OverrideDefenseBypassCallbacks[i].Priority >= Priority && !bPriorityIndexFound)
        {
            PriorityIndex = i + 1; // +1 so that InsertItem puts the new callback *after* this one.

            // Keep cycling through the array so that the previous check for duplicate delegates can run for every currently registered delegate.
            bPriorityIndexFound = true;
        }
    }

    NewOverrideDefenseBypassCallback.Priority = Priority;
    NewOverrideDefenseBypassCallback.OverrideDefenseBypassFn = OverrideDefenseBypassFn;
    OverrideDefenseBypassCallbacks.InsertItem(PriorityIndex, NewOverrideDefenseBypassCallback);

    return true;
}

/// HL-Docs: ref:OverrideDefenseBypass
/// # Removing Delegates
/// If necessary, it's possible to remove a delegate.
///```unrealscript
///CHHelpersObj.RemoveOverrideDefenseBypassCallback(OverrideDefenseBypass);
///```
/// The function will return `true` if the Callback was successfully deleted, return false otherwise.
simulated function bool RemoveOverrideDefenseBypassCallback(delegate<OverrideDefenseBypassDelegate> OverrideDefenseBypassFn)
{
    local int i;

    for (i = OverrideDefenseBypassCallbacks.Length - 1; i >= 0; i--)
    {
        if (OverrideDefenseBypassCallbacks[i].OverrideDefenseBypassFn == OverrideDefenseBypassFn)
        {
            OverrideDefenseBypassCallbacks.Remove(i, 1);
            return true;
        }
    }
    return false;
}

// Internal helper function to trigger an OverrideDefenseBypass event.
simulated function TriggerOverrideDefenseBypass(array<name> AppliedDamageTypes, out int bIgnoreArmor, out int bIgnoreShields, EffectAppliedData ApplyEffectParams, X2Effect_ApplyWeaponDamage Source, optional XComGameState NewGameState)
{
	local delegate<OverrideDefenseBypassDelegate> OverrideDefenseBypassFn;
	local int i;

	for (i = 0; i < OverrideDefenseBypassCallbacks.Length; i++)
	{
		OverrideDefenseBypassFn = OverrideDefenseBypassCallbacks[i].OverrideDefenseBypassFn;

		if (OverrideDefenseBypassFn(AppliedDamageTypes, bIgnoreArmor, bIgnoreShields, ApplyEffectParams, Source, NewGameState) == EHLDR_InterruptDelegates)
		{
			break;
		}
	}
}
// End Issue #1542

