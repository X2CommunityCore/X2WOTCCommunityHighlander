# Change Log

*This change log is deprecated; it contains historical changes that have not been documented using the new [documentation tool and site](https://x2communitycore.github.io/X2WOTCCommunityHighlander/).  
No new changes should be added here. Documented features should be removed from this list. Conversely, this is a list of features to document.*

## Strategy

### Mod/DLC Hooks
- `GetDLCEventInfo` allows mods to add their own events for the Geoscape Event
  List (#112)

### Event Hooks
- Triggers the event `OnArmoryMainMenuUpdate` that allows adding elements into
  the ArmoryList (#47)
- Triggers the event `PostMissionUpdateSoldierHealing` that allows excluding soldiers from starting healing projects (#140)
- Triggers the event `UpdateResources` that allows mods to show resources in the ResourceHeader (#174)
- Triggers the event `OverridePsiOpTraining` that allows mods to override unit eligibility for Psi Op slots (#159)
- Triggers the event `OverrideItemIsModified` to prevent items with custom modifications from being stacked / removed
- Triggers the events `UnitRandomizedStats` and `RewardUnitGenerated` for unit initialization logic (#185)
- Triggers the events `OverrideUIArmoryScale`, `OverrideUIVIPScale`, and `OverrideCharCustomizationScale` for strategy unit scaling (#229)
- Triggers the event `RegionOutpostBuildStart` to add a strategy reward similar to the 'Resistance Network' resistance order, but for Radio Relays instead of Network Contacts. (#279)
- Triggers the event `GeoscapeFlightModeUpdate` to allow mods to respond to geoscape mode change (#358)
- Triggers the event `NumCovertActionsToAdd` to allow mods to modfiy number of Covert Actions (#373)
- Triggers the event `CompleteRespecSoldier` when a training center soldier respec was completed. (#339)
- Triggers the events `UIArmory_WeaponUpgrade_SlotsUpdated` and `UIArmory_WeaponUpgrade_NavHelpUpdated`
  in `UIArmory_WeaponUpgrade` (#417)
- Triggers the event `CovertActionRisk_AlterChanceModifier` when calculated covert action risks. (#434)
- Triggers the event `AllowDarkEventRisk` during XComGameState_CovertAction::EnableDarkEventRisk to allow alterations of standard logic (#434)
- Triggers the event `AllowDarkEventRisk` during XComGameState_CovertAction::CreateRisks to allow alterations of standard logic (#692)
- Triggers the event `CovertAction_ShouldBeVisible` on XComGameState_CovertAction::ShouldBeVisible call (#438)
- Triggers the event `CovertAction_CanInteract` on XComGameState_CovertAction::CanInteract call (#438)
- Triggers the event `CovertAction_ActionSelectedOverride` on XComGameState_CovertAction::DisplaySelectionPrompt call (#438)
- Triggers the event `CovertAction_PreventGiveRewards` on XComGameState_CovertAction::GiveRewards call (#438)
- Triggers the event `CovertAction_RemoveEntity_ShouldEmptySlots` on XComGameState_CovertAction::RemoveEntity call (#438)
- Triggers the event `CovertAction_ModifyNarrativeParamTag` on XComGameState_CovertAction::GetNarrative call (#438)
- Triggers the event `ShouldCleanupCovertAction` to allow mod control over Covert Action deletion. (#435)
- Triggers the event `BlackMarketGoodsReset` when the Black Market goods are reset (#473)
- Triggers the event `OverrideCurrentDoom` to allow mods to override doom amount for doom updates (#550)
- Triggers the event `PreEndOfMonth` to notify mods that the game is about to start its end-of-month processing (#539)
- Triggers the event `ProcessNegativeIncome` to allow mods to do their own processing when XCOM's income at the
  end of the month is negative (#539)
- Triggers the event `OverrideDisplayNegativeIncome` to allow mods to override whether negative monthly income is
  displayed as a negative value or as zero (latter is default behavior) (#539)
- Triggers the event `OverrideSupplyDrop` to allow mods to override the amount of supplies awarded at month end (#539)
- Triggers the event `OverrideSupplyLossStrings` to allow mods to override the text that is displayed for supplies
  lost in the monthly resistance report (#539)
- Triggers the event `PostEndOfMonth` to notify mods that end-of-month processing has come to an end (#539)
- Triggers the event `OverrideNoCaEventMinMonths` to allow mods to force the UI to display no CA nag during first month
- Triggers the event `CustomizeStatusStringsSeparate` in XComGameState_Unit::GetStatusStringsSeparate (#322)
- Triggers the event `OverridePersonnelStatus` in UIUtilities_Strategy::GetPersonnelStatusStringParts. This
  allows listeners the opportunity to override the status, its time remaining and its colour. (#322)
- Triggers the event `OverridePersonnelStatusTime` in a number of places to allow listeners to change the way
  unit status times (like how long is left on a covert action) are displayed. For example, a listener could
  display a time in hours rather than days, perhaps based on how many hours are left. (#322)
- Triggers the event `OverrideMissionSiteIconImage` to allow mods to override the image shown for mission site icons (#537)
- Triggers the event `StrategyMapMissionSiteSelected` to allow mods to provide mission launch screens for
  missions that have custom mission sources (#537)
- Triggers the event `OverrideMissionSiteTooltip` to allow mods to override the tooltip displayed for a
  mission site icon (#537)
- Triggers the event `OverrideScanSiteTooltip` to allow mods to override the tooltip displayed for a
  scan site icon (#537)
- Triggers the event `MissionIconSetMissionSite` to allow mods to customize a mission site's icon in
  other ways than just the tooltip and image (#537)
- Triggers the event `MissionIconSetScanSite` to allow mods to customize a scan site's icon in other
  ways than just the tooltip and image (#537)
- Triggers the event `SoldierListItem_ShouldDisplayMentalStatus` to allow mods to enable/disable display of mental status
  based on additional logic (#651)
- Triggers the event `CovertActionStarted` to allow mods to react to it in a flexible manner
  (instead of hooking into UI mess) (#584)
- Triggers the event `CovertActionAllowEngineerPopup` to allow mods to forbid the popup (#584)
- Triggers the event `CovertActionAllowCheckForProjectOverlap` to allow mods to forbid the "de-bunching" logic
  on CA start (#584)
- Triggers the event `AllowActionToSpawnRandomly` to allow mods to prevent certain CAs from being randomly spawned (#594)
- Triggers the event `OverrideScienceScore` to allow mods to override the XCOM HQ science score, for
  example to add their own bonuses or to remove scientists that are engaged in other activities.
- Triggers the event `CovertAction_AllowResActivityRecord` to allow mods to enable/disable "covert action completed"
  record for the monthly resistance report (#696)
- Triggers the event `OverrideAddChosenTacticalTagsToMission` to allow mods to override chosen spawning (#722)

### Modding Exposures
- Allows mods to add custom items to the Avenger Shortcuts (#163)
- Remove `private` from `X2AIBTBehaviorTree.Behaviors` so that mods can change the behavior trees without
  overwriting all the necessary entries (#410)
- Removed `protectedwrite` from `AcquiredTraits`, `PendingTraits`, and `CuredTraits` in `XComGameState_Unit`, allowing Traits to be modified by external sources (#681)

### Configuration
- Allow disabling of Factions being initialized on startup by
  `XComGameState_HeadquartersResistance`, as it can break if it collect custom
  factions and then assigns Chosen to them instead of the base game factions.
  (#82)
- bDontUnequipCovertOps prevents soldiers gear gets stripped when sending on covert op with no ambush risk (#153)
- bDontUnequipWhenWounded prevents soldiers gear gets stripped when getting wounded (#310)
- AdditionalAmbushRiskTemplates array represents risk templates that the game will consider at risk to ambush (#485)
- bSkipCampaignIntroMovies skips the intro movies on campaign start (#543)

### Improvements
- Allow `UIStrategyMap` to display custom Faction HQ icons (#76)
- Allow customization of auto-equipment removal behavior in 'UISquadSelect' (#134)
- Class mods adding an eight rank will now interact better with classes with seven ranks (#1)
- Allow `XComGameState_WorldRegion::DestinationReached` to use any XCGS_GeoscapeEntity class (#443)
- Add AmbushMissionSource name property to XComGameState_CovertAction; mods can now specify the ambush mission on creation of Action GameState (#485)

### Fixes
- Fix an issue in base game where strategy X2EventListenerTemplates only
  register on tactical->strategy transfer, not when loading directly into
  strategy (#3)
- Fix GetCrossClassAbilities collecting abilities that are already in that
  particular Unit Class's skill tree (#30, #62)
- Fix Loadout utility items when unit has an item equipped in the Ammo Pocket (#99)
- Fix units unequipping items they shouldn't, resulting in duplicate Paired Weapons (#189)
- Fix all Covert Actions from being removed when generating covert actions (#435)
- Make units with a status of `eStatus_CovertAction` unavailable for missions
  in `XComGameState_Unit.CanGoOnMission()` (#665)

## Tactical

### Mod/DLC Hooks
- Allow Mods/DLC to modify spawn locations for player units (#18)
- Trigger an event for RetainConcealmentOnActivation (#2)
- Allow Mods/DLC to modify encounters after creation (#136)
- Allow Mods/DLC to modify encounters generated as reinforcements (#278)
- Allow Mods/DLC to alter mission data after SitRep creation (#157)
- Add an array of `OverrideFinalHitChance` function delegates to `X2AbilityToHitCalc`
  that mods can add functions to in order to override the default logic for handling
  hits, grazes and crits (#555)
- Adds `OnLoadedSavedGameToTactical` to DLCInfo that serves like the strategy counterpart `OnLoadedSavedGameToStrategy`
- Allow Mods/DLC to utilize multiplayer teams in singleplayer (#188)

### Event Hooks

- `OnProjectileFireSound` and `OnProjectileDeathSound` in X2UnifiedProjectile
  that allow to override the default projectile sounds. (#10)
- Add `WillRollContext` for modifying Will Rolls in
  XComGameStateContext_WillRoll (#13)
- Allow to use the Reaper UI without being super concealed. New events
  `TacticalHUD_RealizeConcealmentStatus` and `TacticalHUD_UpdateReaperHUD` (#6)
- Trigger `CleanupTacticalMission` for end of mission recovery. (#96)
- Allow override of bleedout chances on event basis with
  `OverrideBleedoutChance`. (#91)
- `OnGetItemRange` override an item's range (#119)
- `PreAcquiredHackReward` for overriding Hack Rewards (#120)
- `ModifyEnvironmentDamage` to modify environment damage (#200)
- `OverrideKilledByExplosion` to allow mods to override the
  "was killed by explosion" flag (#202)
- Allow mods to have character templates to use custom base underlays instead of default 
  clerk underlays on the Avenger (#251)
- `OverrideVictoriousPlayer` to allow override whether a mission was successful or not (#266)
- `OverrideItemSoundRange` to allow overriding an item's sound range (#363)
- `OverrideHackingScreenType` and `HackIn2D` to allow hacking using a 2D movie and using
  the Skulljack / ADVENT screen arbitrarily (#330)
- `PostMissionObjectivesSpawned` to allow for map manipulation before units are spawned  (#405)
- Allow mods to override the number of objectives spawned for a mission via the new event
  `OverrideObjectiveSpawnCount`, which is triggered as the objective spawns are being
  selected by `XComTacticalMissionManager`. (#463)
- `OverrideReinforcementsAlert` allows mods to force the display of the reinforcements
  alert panel and also change its text and color (#449)
- 'DrawDebugLabels' allows mods to draw their own debug information on the canvas used by
  `XComTacticalController.DrawDebugLabels()` (#490)
- `OverrideBodyRecovery` allows mods to determine whether incapacitated soldiers are recovered
  at the end of a mission (which is only supported by full sweep missions with corpse retrieval
  in the base game) (#571)
- `OverrideLootRecovery` allows mods to determine whether loot is automatically recovered
  at the end of a mission (which is only supported by full sweep missions with corpse retrieval
  in the base game) (#571)

### Configuration
- Added ability to modify default spawn size (#18)
- Added ability to modify number of tactical auto-saves kept (#53)
- Added ability to prevent ragdolls from ever turning off their physics, plus
  enable Chosen ragdolling (#41)
- Added ability to prevent multi-part missions counting as separate missions
  for will loss purposes (#44)
- Added option to mitigate all weapon damage using armor instead of always taking at
  least 1 damage (#321)

### Modding Exposures
- Deprivatise variables to protected in XComIdleAnimationStateMachine to allow
  for subclassing overrides (#15)
- Remove protectedwrite on X2AbilityTemplate effects arrays: AbilityTarget,
  AbilityMultiTarget, and AbilityShooter Effects (#68)
- Deprivatise/const config variables in XComTacticalMissionManager (#101)
- Deprivatise XComAlienPawn.Voice to allow changes by mods (#275)
- Deprivatise/const config variables in XComParcelManager (#404)
- Gives SitReps access to the Tactical StartState in order to widen sitrep capabilities (#450)
- Deprivatise variables in X2TargetingMethod_EvacZone so that it can be effectively subclassed (#165)

### Improvements
- Make suppression work with weapons that don't have suppression specific
  animations set on them (#45)
- Make suppression work with units that don't have a suppression specific
  idle animation animation set on them (#74)
- Register tactical event listeners in TQL (#406)
- Allow mods to decide which team(s) are granted an ability via X2SitRepEffect_GrantAbilities and better document that class (#445)
- Allow X2AbilityToHitCalc_StatCheck to check for hit chance modifiers (#467)
- Allow aliens and other teams to properly register non-XCOM unit locations to adjust their positions accordingly (#619)

### Fixes
- `MindControlLost` fires whenever a unit stops being mind controlled or hacked. The event
  passes the affected unit state as both event data and event source (#643)

## Miscellaneous

### Mod/DLC Hooks
- `UpdateAnimations` added to allow adding CustomAnimsets to UnitPawns (#24)
- `DLCAppendSockets` added to allow appending sockets to UnitPawns (#21)
- `CanAddItemToInventory` added to allow configuring whether or not a unit can
  equip a particular item as an extension to the standand rules (#50)
- `CanAddItemToInventory_CH_Improved` added as a backwards compatible extension
  to other CanAddItem... helpers, allowing access to the ItemState (#114)
- `GetLocalizedCategory`added to allow inject custom weapon category localizations (#125)
- `UpdateUIOnDifficultyChange` added to allow modders to modify the UI on the
  difficulty selection (UIShellDifficulty) (#148)
- `MatineeGetPawnFromSaveData` added to allow manipulation of the shell screen matinee (#240)
- `UpdateWeaponAttachments` added to allow manipulation weapon attachments at runtime (#239)
- `WeaponInitialized` added to conditionally change the weapon archetype on initialization (#245)
- `UpdateWeaponMaterial` added to conditionally change the weapon materials(#246)
- `OnPreCreateTemplates` allows mods to modify properties of X2DataSet(s) before they are invoked (#412)
- `UpdateTransitionMap` allows overriding the transition map -- dropship interior by default (#388)
- `UseAlternateMissionIntroDefinition` allows overriding the mission intro (#395)
- `UnitPawnPostInitAnimTree` allows Allows patching the animtree template before its initialized.(#455)
- `AbilityTagExpandHandler_CH` expands vanilla AbilityTagExpandHandler to allow reflection

### Event Hooks
- `AddConversation` added to allow mods to change narrative behavior before they are played (#204)
- `OverrideRandomizeAppearance` added to allow mods to block updating appearance when switching armors (#299)

### Configuration
- Able to list classes as excluded from AWC Skill Rolling, so they can still
  take part in the Combat Intelligence / AP System, without getting randomised
  skills (#80)
- Able to list classes to be excluded from being 'needed', which means they are
  rarely meant to be acquired via Rookie level up and instead trained (#113)

### Modding Exposures
- Renable the ability to add positive traits in codebase, as well as additional
  filtering and behaviour on the various Trait Functions on `XComGameState_Unit`
  (#85)
- Allow mods to register custom OnInput UI handlers (#198, #501)
- Unprotect `X2DataSet::bShouldCreateDifficultyVariants` to allow mods to force templates from other packages to use difficulty variants (#413)
- Allow mods to manipulate X2GameRuleset::EventObserverClasses, eg. on CDOs (#481)
- Uprivate `XComTacticalMissionManager::CacheMissionManagerCards` to allow mods to use manager's decks (#528)
- Unprotect `X2ItemTemplateManager::Loadouts` so they can be changed Programmatically (#698)
- Unprotect `XComGameState_EvacZone::CenterLocation` & `XComGameState_EvacZone::Team` (#702)

### Improvements
- Allow enemies with assigned names to have them appear as their name, rather
  than a generic label. (#52)
- Change UIUtilities_Colors.GetColorForFaction to use Faction template color as
  a backup (#72)
- Prevent items from stacking if they have ComponentObjects attached to them,
  useful for mods to create uniques out of stackable items. (#104)
- Allow to define mutually exclusive abilities (#128) like `Template.PrerequisiteAbilities.AddItem('NOT_SomeAbility');`
- Rebuild PerkContentCache during OnPostTemplatesCreated to improve handling for
  PerkContent attachments to Units (#123)
- Check DLCInfo for `CanAddItemToInventory` no matter what, rather than short
  circuiting if DisabledReason != "" (#127)
- Major Overhaul of InventorySlot handling so modders can suggest extra
  inventory slots (#118, #137)
- Fix UIOptionsPCScreen so part pack sliders actually get shown as intended
  (#150)
- Fix XGCharacterGenerator so it's actually possible to disable part packs for
  new soldiers (#154)
- Improve performance by removing unnecessary calls to UpdateAllMeshMaterials (#186)
- Adds ability to have weapon upgrades modify damage, and properly accounts for
  any damage upgrades in the UI. (#237)
- Changes to "Legacy Operations" squad loadout and ability selections are now always applied for the first mission. Note any non-AWC-eligble abilities added need to exist in the Soldier Classes ability tree (#307)
- For "Legacy Operations" changes to squad members' Soldier Class, and changes to the Soldier Classes themselves, are taken into account for pre-existing operations.
  Particularly important for Central and Shen, whose custom Soldier Classes ability tree contain only the abilities granted by their squad progression (#307)
- Better Photobooth support for custom Soldier Classes and Spark-like units,
  no broken duo poses for units that can't play them (#309)
- Additional Photobooth particle system enums for mods (#359)
- Tweaks to "Resistance Archives" random Legacy Operations UI. Restarts show the correct locked difficulty, and a crash condition on backing out of a restart fixed. (#307)
- Added CovertAction as its own EventSource on Event 'CovertActionCompleted' (#383)
- "Arms" no longer always hide forearm decos, but obey the archetype flag as the left/right arms do. (#350)
- Arms and left/right arm customization dropdowns remain selectable even if they only have one entry
  iff both arms and seperate left/right arms are available. (#350)
- Allow mods to check whether VIP units left a mission successfully via the `bRemovedFromPlay`
  flag on `XComGameState_Unit`. This behavior is gated behind the new `CHHelpers.PreserveProxyUnitData`
  config variable. (#465)
- Adds CustomDeathAnimationName property to X2Action_Death that allows overriding the default death animations (#488)
- Added Inventory Slots `eInvSlot_Wings` and `eInvSlot_ExtraBackpack`. (#678)

### Fixes
- Fixes UIPanels animating in with a huge delay when they are direct child panels of
  UIScreen (#341)
- Appearances now update correctly when a part change differs only by material override (#354)
- All relevant body parts are now correctly validated when the torso is changed. (#350)
