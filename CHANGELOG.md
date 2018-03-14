# Change Log
All notable changes to Vanilla 'War Of The Chosen' Behaviour will be documented in this file.



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

### Modding Exposures
- Allows mods to add custom items to the Avenger Shortcuts (#163)

### Configuration
- Allow disabling of Factions being initialized on startup by
  `XComGameState_HeadquartersResistance`, as it can break if it collect custom
  factions and then assigns Chosen to them instead of the base game factions.
  (#82)

### Improvements
- Allow `UIStrategyMap` to display custom Faction HQ icons (#76)
- Allow customization of auto-equipment removal behavior in 'UISquadSelect' (#134)

### Fixes
- Fix an issue in base game where strategy X2EventListenerTemplates only
  register on tactical->strategy transfer, not when loading directly into
  strategy (#3)
- Fix GetCrossClassAbilities collecting abilities that are already in that
  particular Unit Class's skill tree (#30, #62)
- Fix Loadout utility items when unit has an item equipped in the Ammo Pocket (#99)
- Fix units unequipping items they shouldn't, resulting in duplicate Paired Weapons (#189)


## Tactical

### Mod/DLC Hooks
- Allow Mods/DLC to modify spawn locations for player units (#18)
- Trigger an event for RetainConcealmentOnActivation (#2)
- Allow Mods/DLC to modify encounters after creation (#136)
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

### Configuration
- Added ability to modify default spawn size (#18)
- Added ability to modify number of tactical auto-saves kept (#53)
- Added ability to prevent ragdolls from ever turning off their physics, plus
  enable Chosen ragdolling (#41)
- Added ability to customise both Burning and Poison bypassing shields when
  applied to targets (#89)
- Added ability to prevent multi-part missions counting as separate missions
  for will loss purposes (#44)

### Modding Exposures
- Deprivatise variables to protected in XComIdleAnimationStateMachine to allow
  for subclassing overrides (#15)
- Remove protectedwrite on X2AbilityTemplate effects arrays: AbilityTarget,
  AbilityMultiTarget, and AbilityShooter Effects (#68)
- Deprivatise/const config variables in XComTacticalMissionManager (#101)

### Improvements
- Make suppression work with weapons that don't have suppression specific
  animations set on them (#45)
- Make suppression work with units that don't have a suppression specific
  idle animation animation set on them (#74)

### Fixes
- Ensure Gremlins use the walk/run animation based on the alert status of their
  owner, rather than the standard behaviour of always deferring to walk speed
  (#33)
- Fix Reaper's Banish Ability Visualisation not properly visualising
  subsequent shots (#20)
- Fix Initiative-Interrupting abilities giving Reinforcements a full turn
  of action points after scamper (#36)



## Miscellaneous

### Mod/DLC Hooks
- `UpdateAnimations` added to allow adding CustomAnimsets to UnitPawns (#24)
- `UpdateMaterial`added to allow manipulate pawn materials (#169)
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

### Event Hooks
- Triggers the events `SoldierClassIcon`, `SoldierClassDisplayName`,
  `SoldierClassSummary` that allow replacement of the class icon/display
  name/summary dynamically e.g. depending on UnitState or Soldier Loadout,
  and adds accessor functions for those to XComGameState_Unit. (#106)
- `GetPCSImageTuple` added to allow customising PCS Image string (#110)
- Triggers the event `OverrideHasHeavyWeapon` that allows to override the result of `XComGameState_Unit.HasHeavyWeapon` (#172)
- `OverrideItemMinEquipped` added to allow mods to override the min number of equipped items in a slot (#171)

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

### Fixes
- Fix Chosen Assassin receiving weaknesses that are exclusive to the
  Shadowstep Strength in the narrative mission, instead Shadowstep is forced
  ahead of awarding the remaining traits, so the trait roll takes the strength
  into account (#51)
- Enable ForceCountry in CharacterPoolManager - was ignored despite being
  an argument in the CreateCharacter function (#70)
- Fixes game terminating SoundCue narrative moments after three seconds because
  it assumes they didn't play at all. (#66)
