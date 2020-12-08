class CHHelpers extends Object config(Game);

//issue #188 - creating a struct and usable array for modders
struct TeamRequest
{
	var ETeam Team; //eTeam_One and eTeam_Two should be the only ones here.
};

var config array<TeamRequest> ModAddedTeams;
//end issue #188

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

// Start issue #602
var config array<name> ClassesAllowPsiPCS;
// End issue #602

// Variable for Issue #724
var config array<name> ValidReserveAPForUnitFlag;

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

delegate EHLDelegateReturn ShouldDisplayMultiSlotItemInStrategyDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XComUnitPawn UnitPawn, optional XComGameState CheckGameState);
delegate EHLDelegateReturn ShouldDisplayMultiSlotItemInTacticalDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XGUnit UnitVisualizer, optional XComGameState CheckGameState);
// End Issue #885

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
/// ```unrealscript
/// EventID: OverrideUnitFocusUI
/// EventData: XComLWTuple {
///     Data: [
///       inout bool bVisible,
///       inout int currentFocus,
///       inout int maxFoxus,
///       inout string color,
///       inout string iconPath,
///       inout string tooltipText,
///       inout string focusLabel
///     ]
/// }
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

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
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
/// This feature allows mods to allow items equipped in multi-item inventory slots to be visible on soldiers' bodies. 
/// The vanilla behavior is that only the first item in the Utility Slot is visible on the soldier's body,
/// and only in Tactical, but not in the Armory.
/// Using this feature it's possible to show all items in all multi-slots, including Highlander-templated slots.
///
/// There are two delegates:
///
/// ```unrealscript
/// // Used to decide whether the specified item should be visible on specified unit in the Armory, Squad Select and Post Mission Sequence.
/// delegate EHLDelegateReturn ShouldDisplayMultiSlotItemInStrategyDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XComUnitPawn UnitPawn, optional XComGameState CheckGameState);
/// // Same as above, but for Tactical.
/// delegate EHLDelegateReturn ShouldDisplayMultiSlotItemInTacticalDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XGUnit UnitVisualizer, optional XComGameState CheckGameState);
/// ```
///
/// ## How to use
///
/// Delegates must be added to the `CHHelpers` ClassDefaultObject. Normally this is done in `OnPostTemplatesCreated`
/// via `AddShouldDisplayMultiSlotItemInStrategyCallback` and `AddShouldDisplayMultiSlotItemInTacticalCallback`.
///
/// **Warning:** Delegates must be bound to the ClassDefaultObject of your class, otherwise the game will hard crash 
/// due to a garbage collection failure when transitioning between layers. Implementing your methods in a class 
/// that `extends X2DownloadableContentInfo` will automatically handle this for you.
///
/// Both delegates have the `out int bDisplayItem` argument. Set it to any value above zero to display the item on the soldier's body.
/// Set to 0 to keep the item hidden. Highlander-templated slots also need to have `NeedsPresEquip=true` to display in Tactical, 
/// and `ShowOnCinematicPawns=true` to display in the Armory and Squad Select.
///
/// Both delegates should return `EHLDR_NoInterrupt` to allow subsequent delegates to run and potentially override the value you have
/// assigned to `bDisplayItem`, or `EHLDR_InterruptDelegates` to not allow any subsequent delegates to run. A priority can be supplied
/// to the `AddShouldDisplay...` functions, where a higher-priority callback runs earlier.
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
///
/// ## Example
///
/// Here's a simple example of a delegate pair that will display all items equipped in the Utility Slot in both Tactical and Strategy.
/// This needs to go in a class that extends `X2DownloadableContentInfo`.
/// ```unrealscript
/// static event OnPostTemplatesCreated()
/// {
/// 	local CHHelpers CHHelpersObj;
/// 
/// 	CHHelpersObj = class'CHHelpers'.static.GetCDO();
/// 	if (CHHelpersObj != none)
/// 	{
/// 		CHHelpersObj.AddShouldDisplayMultiSlotItemInStrategyCallback(ShouldDisplayMultiSlotItemInStrategyDelegate, 50);
/// 		CHHelpersObj.AddShouldDisplayMultiSlotItemInTacticalCallback(ShouldDisplayMultiSlotItemInTacticalDelegate, 50);
/// 	}
/// }
/// 
/// static private function EHLDelegateReturn ShouldDisplayMultiSlotItemInStrategyDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XComUnitPawn UnitPawn, optional XComGameState CheckGameState)
/// {
/// 	ShouldDisplayUtilitySlotItem(ItemState, bDisplayItem);
/// 	// Return this to allow following Delegates to override the output of this delegate.
/// 	return EHLDR_NoInterrupt;
/// }
/// 
/// static private function bool ShouldDisplayMultiSlotItemInTacticalDelegate(XComGameState_Unit UnitState, XComGameState_Item ItemState, out int bDisplayItem, XGUnit UnitVisualizer, optional XComGameState CheckGameState);
/// {
/// 	return ShouldDisplayUtilitySlotItem(ItemState, bDisplayItem);
/// 	return EHLDR_NoInterrupt;
/// }
/// 
/// static private function ShouldDisplayUtilitySlotItem(XComGameState_Item ItemState, out int bDisplayItem)
/// {
/// 	local X2EquipmentTemplate EqTemplate;
/// 
/// 	if (ItemState.InventorySlot == eInvSlot_Utility)
/// 	{
/// 		EqTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());
/// 		if (EqTemplate != none && EqTemplate.iItemSize > 0)
/// 		{
/// 			bDisplayItem = 1;
/// 		}
/// 	}
/// }
/// ```

/// HL-Docs: ref:DisplayMultiSlotItems
// Strategy Layer
// You can optionally specify callback Priority. Delegates with higher Priority value are executed first. Delegates with the same Priority are executed in the same order they were added to CHHelpers,
// which would normally be the same as DLCRunOrder.
// This function returns true if the delegate was successfully registered.
simulated function bool AddShouldDisplayMultiSlotItemInStrategyCallback(delegate<ShouldDisplayMultiSlotItemInStrategyDelegate> ShouldDisplayMultiSlotItemInStrategyFn, optional int Priority = 50)
{
	local ShouldDisplayMultiSlotItemInStrategyStruct NewShouldDisplayMultiSlotItemInStrategyCallback;
	local int i, PriorityIndex;
	local bool bPriorityIndexFound;

	if (ShouldDisplayMultiSlotItemInStrategyFn == none)
	{
		return false;
	}

	for (i = 0; i < ShouldDisplayMultiSlotItemInStrategyCallbacks.Length; i++)
	{
		// Do not allow registering the same delegate more than once.
		if (ShouldDisplayMultiSlotItemInStrategyCallbacks[i].ShouldDisplayMultiSlotItemInStrategyFn == ShouldDisplayMultiSlotItemInStrategyFn)
		{
			return false;
		}

		// Remember the Index of the first member of the array of callbacks whose Priority is lower than the priority of the new Callback we intend to add.
		// Thusly, Callbacks with higher Priority will be called first. Callbacks with the same priority will be called in order of their addition.
		if (Priority > ShouldDisplayMultiSlotItemInStrategyCallbacks[i].Priority && !bPriorityIndexFound)
		{
			PriorityIndex = i;

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

// Return true if the Callback was successfully deleted, return false otherwise.
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

/// HL-Docs: ref:DisplayMultiSlotItems
// Tactical Layer
simulated function bool AddShouldDisplayMultiSlotItemInTacticalCallback(delegate<ShouldDisplayMultiSlotItemInTacticalDelegate> ShouldDisplayMultiSlotItemInTacticalFn, optional int Priority = 50)
{
	local ShouldDisplayMultiSlotItemInTacticalStruct NewShouldDisplayMultiSlotItemInTacticalCallback;
	local int i, PriorityIndex;
	local bool bPriorityIndexFound;

	if (ShouldDisplayMultiSlotItemInTacticalFn != none)
	{
		return false;
	}

	for (i = 0; i < ShouldDisplayMultiSlotItemInTacticalCallbacks.Length; i++)
	{
		if (ShouldDisplayMultiSlotItemInTacticalCallbacks[i].ShouldDisplayMultiSlotItemInTacticalFn == ShouldDisplayMultiSlotItemInTacticalFn)
		{
			return false;
		}

		if (Priority > ShouldDisplayMultiSlotItemInTacticalCallbacks[i].Priority && !bPriorityIndexFound)
		{
			PriorityIndex = i;
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
	return CHHelpers(class'XComEngine'.static.GetClassDefaultObjectByName(default.Class.Name));
}
// End Issue #885
