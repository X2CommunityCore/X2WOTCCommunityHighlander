# Change Log
All notable changes to Vanilla 'War Of The Chosen' Behaviour will be documented in this file.

## General

### Ini settings

#### Mod compatibility

In `XComGame.ini` mods can specify an array of incompatible and/or required mods. This will be used to show an warning popup if they are present. (#524)

```
[ModSafeName CHModDependency]
+IncompatibleMods=OtherModSafeName
+IgnoreIncompatibleMods=OtherModSafeName
+RequiredMods=OtherModSafeName
+IgnoreRequiredMods=OtherModSafeName
DisplayName="Fancy Mod"
```

#### DLC Run Order

In `XComGame.ini` mods can define an array of other mods which dlc hooks should run before and/or after the mods dlc hook.
LoadPriority can be RUN_STANDARD, RUN_FIRST or RUN_LAST. RunBefore and RunAfter only work within the defined LoadPriority group. Only change load priority if you really sure that its needed for you mod (#511)
```
[ModSafeName CHDLCRunOrder]
+RunBefore=OtherModSafeName
+RunAfter=OtherModSafeName
RunPriorityGroup=RUN_STANDARD
```

## Strategy

### Mod/DLC Hooks
- `GetDLCEventInfo` allows mods to add their own events for the Geoscape Event
  List (#112)
- `CanWeaponApplyUpgrade` allows mods to restrict what upgrades can be applied
  to a specific weapon (#260)
- `ModifyEarnedSoldierAbilities` allows mods to add their own abilities to soldiers,
  such as officer abilites (#409)

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
- Triggers the event `UIAvengerShortcuts_ShowCQResistanceOrders` to allow to override the presence of Resistance Orders button in `UIAvengerShortcuts` (#368)
- Triggers the event `Geoscape_ResInfoButtonVisible` to allow to override the visibility of resistance orders button in `UIStrategyMap_HUD` (#365)
- Triggers the event `NumCovertActionsToAdd` to allow mods to modfiy number of Covert Actions (#373)
- Triggers the event `CompleteRespecSoldier` when a training center soldier respec was completed. (#339)
- Triggers the events `UIArmory_WeaponUpgrade_SlotsUpdated` and `UIArmory_WeaponUpgrade_NavHelpUpdated`
  in `UIArmory_WeaponUpgrade` (#417)
- Triggers the event `GetCovertActionEvents_Settings` to allow showing all covert actions in the correct order in the event queue (#391)
- Triggers the event `CovertActionRisk_AlterChanceModifier` when calculated covert action risks. (#434)
- Triggers the event `AllowDarkEventRisk` during XComGameState_CovertAction::EnableDarkEventRisk to allow alterations of standard logic (#434)
- Triggers the event `UIStrategyPolicy_ScreenInit` at the end of UIStrategyPolicy::InitScreen (#440)
- Triggers the event `UIStrategyPolicy_ShowCovertActionsOnClose` on UIStrategyPolicy::CloseScreen call (#440)
- Triggers the event `CovertAction_ShouldBeVisible` on XComGameState_CovertAction::ShouldBeVisible call (#438)
- Triggers the event `CovertAction_CanInteract` on XComGameState_CovertAction::CanInteract call (#438)
- Triggers the event `CovertAction_ActionSelectedOverride` on XComGameState_CovertAction::DisplaySelectionPrompt call (#438)
- Triggers the event `CovertAction_PreventGiveRewards` on XComGameState_CovertAction::GiveRewards call (#438)
- Triggers the event `CovertAction_RemoveEntity_ShouldEmptySlots` on XComGameState_CovertAction::RemoveEntity call (#438)
- Triggers the event `CovertAction_ModifyNarrativeParamTag` on XComGameState_CovertAction::GetNarrative call (#438)
- Triggers the event `ShouldCleanupCovertAction` to allow mod control over Covert Action deletion. (#435)
- Triggers the event `BlackMarketGoodsReset` when the Black Market goods are reset (#473)
- Triggers the event `OverrideImageForItemAvaliable` to allow mods to override the image shown in eAlert_ItemAvailable (#491)
- Triggers the event `OverrideCurrentDoom` to allow mods to override doom amount for doom updates (#550)
- Triggers the event `PsiProjectCompleted` to notify mods when a soldier has finished training in the psi labs (#534)
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


### Modding Exposures
- Allows mods to add custom items to the Avenger Shortcuts (#163)
- UIScanButton now calls OnMouseEventDelegate (#483). Note: DO NOT call ProcessMouseEvents, just set the delegate directly
- Remove `private` from `X2AIBTBehaviorTree.Behaviors` so that mods can change the behavior trees without
  overwriting all the necessary entries (#410)

### Configuration
- Allow disabling of Factions being initialized on startup by
  `XComGameState_HeadquartersResistance`, as it can break if it collect custom
  factions and then assigns Chosen to them instead of the base game factions.
  (#82)
- Allow specifying Second Wave options for Strategy Debug Start (#197)
- bDontUnequipCovertOps prevents soldiers gear gets stripped when sending on covert op with no ambush risk (#153)
- bDontUnequipWhenWounded prevents soldiers gear gets stripped when getting wounded (#310)
- iDefaultWeaponTint allows to configure the default weappon tint for randomly generated soldiers (#397)
- AdditionalAmbushRiskTemplates array represents risk templates that the game will consider at risk to ambush (#485)
- bSkipCampaignIntroMovies skips the intro movies on campaign start (#543)

### Improvements
- Allow `UIStrategyMap` to display custom Faction HQ icons (#76)
- Allow customization of auto-equipment removal behavior in 'UISquadSelect' (#134)
- Class mods adding an eight rank will now interact better with classes with seven ranks (#1)
- Allow `XComGameState_WorldRegion::DestinationReached` to use any XCGS_GeoscapeEntity class (#443)
- Add AmbushMissionSource name property to XComGameState_CovertAction; mods can now specify the ambush mission on creation of Action GameState (#485)
- Customization localizations now picked up for Torso/Legs/Arms. If the TemplateName already
  contains the parttype name (ie Torso/Legs/Arms), then the object name in the localization file
  matches as for other parts (in particular this means Anarchy's Children localizations which already exist in the files
  are picked up automatically). Otherwise, "_Torso"/"_Legs"/"_Arms" is appended to the template name
  to create the unique object name. (#328)

### Fixes
- Fix an issue in base game where strategy X2EventListenerTemplates only
  register on tactical->strategy transfer, not when loading directly into
  strategy (#3)
- Fix GetCrossClassAbilities collecting abilities that are already in that
  particular Unit Class's skill tree (#30, #62)
- Fix Loadout utility items when unit has an item equipped in the Ammo Pocket (#99)
- Fix units unequipping items they shouldn't, resulting in duplicate Paired Weapons (#189)
- Fix all Covert Actions from being removed when generating covert actions (#435)
- Fix a pathing issue in base game with "flying" pod leaders where non-flat tiles on their
  paths prevent them from patrolling (#503)

## Tactical

### Mod/DLC Hooks
- Allow Mods/DLC to modify spawn locations for player units (#18)
- Trigger an event for RetainConcealmentOnActivation (#2)
- Allow Mods/DLC to modify encounters after creation (#136)
- Allow Mods/DLC to modify encounters generated as reinforcements (#278)
- Allow Mods/DLC to alter mission data after SitRep creation (#157)

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
- `OverrideUnitFocusUI` to allow mods to show their own "focus"
  type using the Templar focus UI (#257)
- Allow mods to have character templates to use custom base underlays instead of default 
  clerk underlays on the Avenger (#251)
- `OverrideVictoriousPlayer` to allow override whether a mission was successful or not (#266)
- `OverrideItemSoundRange` to allow overriding an item's sound range (#363)
- `OverrideHackingScreenType` and `HackIn2D` to allow hacking using a 2D movie and using
  the Skulljack / ADVENT screen arbitrarily (#330)
- `OverrideClipSize` to allow effects to modify weapon clip size (#393)
- `PostMissionObjectivesSpawned` to allow for map manipulation before units are spawned  (#405)
- 'PostAliensSpawned' to allow changes to StartState (#457)
- Allow mods to override the number of objectives spawned for a mission via the new event
  `OverrideObjectiveSpawnCount`, which is triggered as the objective spawns are being
  selected by `XComTacticalMissionManager`. (#463)
- `OverrideDisableReinforcementsFlare` allows mods to hide the reinforcements flare
  so that players don't know exactly where reinforcements will be arriving (#448)
- `OverrideReinforcementsAlert` allows mods to force the display of the reinforcements
  alert panel and also change its text and color (#449)
- `AllowInteractHack` allows mods to prevent units from being able to hack `InteractiveObject`s (#564)
- `OverrideEncounterZoneAnchorPoint` allows mods to override the anchor point used by XCOM 2
  in determining patrol zones for pods (#500)
- 'OverridePatrolBehavior' allows mods to disable the base game pod patrol logic if they
  want to handle it themselves (#507)
- 'DrawDebugLabels' allows mods to draw their own debug information on the canvas used by
  `XComTacticalController.DrawDebugLabels()` (#490)
- `OverrideAbilityIconColor` provides a tuple with the same ID as the
  event and data of the form `[bool IsObjective, string Color]` that allows
  mods to override the color of soldier abilities in the tactical HUD (#400)

### Configuration
- Added ability to modify default spawn size (#18)
- Added ability to modify number of tactical auto-saves kept (#53)
- Added ability to prevent ragdolls from ever turning off their physics, plus
  enable Chosen ragdolling (#41)
- Added ability to customise both Burning and Poison bypassing shields when
  applied to targets (#89)
- Added ability to prevent multi-part missions counting as separate missions
  for will loss purposes (#44)
- Added option to mitigate all weapon damage using armor instead of always taking at
  least 1 damage (#321)
- Able to mark custom targeting methods as `RequiresTargetingActivation` for controller input (#476)

### Modding Exposures
- Deprivatise variables to protected in XComIdleAnimationStateMachine to allow
  for subclassing overrides (#15)
- Remove protectedwrite on X2AbilityTemplate effects arrays: AbilityTarget,
  AbilityMultiTarget, and AbilityShooter Effects (#68)
- Deprivatise/const config variables in XComTacticalMissionManager (#101)
- Deprivatise XComAlienPawn.Voice to allow changes by mods (#275)
- Deprivatise/const config variables in XComParcelManager (#404)
- Gives SitReps access to the Tactical StartState in order to widen sitrep capabilities (#450)

### Improvements
- Make suppression work with weapons that don't have suppression specific
  animations set on them (#45)
- Make suppression work with units that don't have a suppression specific
  idle animation animation set on them (#74)
- Gremlins (and other Cosmetic Units) are now correctly tinted and patterned (#376)
- Register tactical event listeners in TQL (#406)
- Allow mods to decide which team(s) are granted an ability via X2SitRepEffect_GrantAbilities and better document that class (#445)
- Allow X2AbilityToHitCalc_StatCheck to check for hit chance modifiers (#467)

### Fixes
- Ensure Gremlins use the walk/run animation based on the alert status of their
  owner, rather than the standard behaviour of always deferring to walk speed
  (#33)
- Fix Reaper's Banish Ability Visualisation not properly visualising
  subsequent shots (#20)
- Fix Initiative-Interrupting abilities giving Reinforcements a full turn
  of action points after scamper (#36)
- Fix some edge cases regarding idle animations and targeting (#269)
- Fix an issue causing Rapid Fire/Chain Shot/Banish/... entering cover early (#273)
- Fixed XCGS_Unit::GetStatModifiers() as XCGS_Unit::GetStatModifiersFixed(),
  X2AbilityToHitCalc_StandardAim, the only vanilla user of this method, changed to match(#313)
- Fix non-Veteran units not having personality speech (#215)
- Fix a display issue causing the weapon tooltip to show stale upgrades
  from earlier units (#303)
- Fix Cinescript CutAfterPrevious in combination with MatineeReplacements (#318)
- Allow abilities that deal damage without a source weapon to still display
  their damage with psi flyovers (Psi Bomb, mod abilities) (#326)
- Fix `X2AbilityToHitCalc_StandardAim` discarding unfavorable (for XCOM) changes
  to hit results from effects (#426)
- Allow soldiers to be carried out from multiple missions in a campaign (#557)
- Fix patrol logic when corners of a patrol zone lie outside of the map edges and
  a pod tries to patrol to any of them (#508)
- Make disorient reapply to disoriented units so that things like flashbangs can
  still remove overwatch from disoriented units (#475)


## Miscellaneous

### Mod/DLC Hooks
- `UpdateAnimations` added to allow adding CustomAnimsets to UnitPawns (#24)
- `UpdateMaterial` added to allow manipulate pawn materials (#169)
- `DLCAppendSockets` added to allow appending sockets to UnitPawns (#21)
- `CanAddItemToInventory` added to allow configuring whether or not a unit can
  equip a particular item as an extension to the standand rules (#50)
- `CanAddItemToInventory_CH_Improved` added as a backwards compatible extension
  to other CanAddItem... helpers, allowing access to the ItemState (#114)
- `GetLocalizedCategory`added to allow inject custom weapon category localizations (#125)
- `UpdateUIOnDifficultyChange` added to allow modders to modify the UI on the
  difficulty selection (UIShellDifficulty) (#148)
- `GetNumUtilitySlotsOverride` and `GetNumHeavyWeaponSlotsOverride` added to allow mods to override the numer of available slots (#171)
- `OverrideItemImage` added to conditionally change the loadout image of an item (#171)
- `MatineeGetPawnFromSaveData` added to allow manipulation of the shell screen matinee (#240)
- `UpdateWeaponAttachments` added to allow manipulation weapon attachments at runtime (#239)
- `WeaponInitialized` added to conditionally change the weapon archetype on initialization (#245)
- `UpdateWeaponMaterial` added to conditionally change the weapon materials(#246)
- `DLCAppendWeaponSockets` allows adding new sockets to weapons(#281)
- `OnPreCreateTemplates` allows mods to modify properties of X2DataSet(s) before they are invoked (#412)
- `UpdateTransitionMap` allows overriding the transition map -- dropship interior by default (#388)
- `UseAlternateMissionIntroDefinition` allows overriding the mission intro (#395)
- `UnitPawnPostInitAnimTree` allows Allows patching the animtree template before its initialized.(#455)
- `AbilityTagExpandHandler_CH` expands vanilla AbilityTagExpandHandler to allow reflection

### Event Hooks
- Triggers the events `SoldierClassIcon`, `SoldierClassDisplayName`,
  `SoldierClassSummary` that allow replacement of the class icon/display
  name/summary dynamically e.g. depending on UnitState or Soldier Loadout,
  and adds accessor functions for those to XComGameState_Unit. (#106)
- `GetPCSImageTuple` added to allow customising PCS Image string (#110)
- Triggers the event `OverrideHasHeavyWeapon` that allows to override the result of `XComGameState_Unit.HasHeavyWeapon` (#172)
- `OverrideItemMinEquipped` added to allow mods to override the min number of equipped items in a slot (#171)
- `AddConversation` added to allow mods to change narrative behavior before they are played (#204)
- `OverrideRandomizeAppearance` added to allow mods to block updating appearance when switching armors (#299)
- `XComGameState_Unit` triggers `SoldierRankName`, `SoldierShortRankName` and
  `SoldierRankIcon` events that allow listeners to override the those particular
  properties of a soldier's rank, i.e. rank name, short name and icon (#408)

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
- Allow mods to register custom OnInput UI handlers (#198)
- Able to specify new materials as counting as hair/skin/armour/weapons etc. for the purpose of
  receiving tints, patterns, tattoos etc. (#356)
- Unprotect `X2DataSet::bShouldCreateDifficultyVariants` to allow mods to force templates from other packages to use difficulty variants (#413)
- Allow mods to manipulate X2GameRuleset::EventObserverClasses, eg. on CDOs (#481)
- Uprivate `XComTacticalMissionManager::CacheMissionManagerCards` to allow mods to use manager's decks (#528)

### Improvements
- Create a mod friendly way to manipulate loot tables (#8)
- Allow to specify EventListenerDeferral Priority for EventListeners registered
  X2EventListenerTemplates. Also allow to remove registered Listeners. (#4)
- Allow enemies with assigned names to have them appear as their name, rather
  than a generic label. (#52)
- Check a soldiers 'NeedsSecondaryWeapon' in UIArmory_Loadout, rather than
  hardcoding based on Rookie Rank (#55)
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
- Alter XComGameState_Unit so it obeys part pack sliders when picking new armour
  appearances. Use `CHHelpers.CosmeticDLCNamesUnaffectedByRoll` to remove the 
  random roll from specific part names (#155)
- `eInvSlot_HeavyWeapon` is now a multi-item slot (#171)
- Improve performance by removing unnecessary calls to UpdateAllMeshMaterials (#186)
- Adds ability to have weapon upgrades modify damage, and properly accounts for
  any damage upgrades in the UI. (#237)
- Allow Human Pawns to freely switch between custom heads and base pawn heads,
  eliminating the need for head mods to include invisible heads (#219)
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

### Fixes
- Fix Chosen Assassin receiving weaknesses that are exclusive to the
  Shadowstep Strength in the narrative mission, instead Shadowstep is forced
  ahead of awarding the remaining traits, so the trait roll takes the strength
  into account (#51)
- Enable ForceCountry in CharacterPoolManager - was ignored despite being
  an argument in the CreateCharacter function (#70)
- Fixes game terminating SoundCue narrative moments after three seconds because
  it assumes they didn't play at all. (#66)
- Fixes UIPanels animating in with a huge delay when they are direct child panels of
  UIScreen (#341)
- Appearances now update correctly when a part change differs only by material override (#354)
- All relevant body parts are now correctly validated when the torso is changed. (#350)
