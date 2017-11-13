# Change Log
All notable changes to Vanilla 'War Of The Chosen' Behaviour will be documented in this file.



## Strategy

### Mod/DLC Hooks

### Event Hooks
- Triggers the event `OnArmoryMainMenuUpdate` that allows adding elements into
  the ArmoryList (#47)

### Modding Exposures

### Configuration
- Allow disabling of Factions being initialized on startup by
  `XComGameState_HeadquartersResistance`, as it can break if it collect custom
  factions and then assigns Chosen to them instead of the base game factions.
  (#82)

### Improvements
- Allow `UIStrategyMap` to display custom Faction HQ icons (#76)

### Fixes
- Fix an issue in base game where strategy X2EventListenerTemplates only
  register on tactical->strategy transfer, not when loading directly into
  strategy (#3)
- Fix GetCrossClassAbilities collecting abilities that are already in that
  particular Unit Class's skill tree (#30, #62)
- Fix Loadout utility items when unit has an item equipped in the Ammo Pocket (#99)


## Tactical

### Mod/DLC Hooks
- Allow Mods/DLC to modify spawn locations for player units (#18)
- Trigger an event for RetainConcealmentOnActivation (#2)

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
  

### Configuration
- Added ability to modify default spawn size (#18)
- Added ability to modify number of tactical auto-saves kept (#53)
- Added ability to prevent ragdolls from ever turning off their physics, plus
  enable Chosen ragdolling (#41)
- Added ability to customise both Burning and Poison bypassing shields when
  applied to targets (#89)

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
- `DLCAppendSockets` added to allow appending sockets to UnitPawns (#21)
- `CanAddItemToInventory` added to allow configuring whether or not a unit can
  equip a particular item as an extension to the standand rules (#50)

### Event Hooks

### Configuration
- Able to list classes as excluded from AWC Skill Rolling, so they can still
  take part in the Combat Intelligence / AP System, without getting randomised
  skills (#80)

### Modding Exposures
- Renable the ability to add positive traits in codebase, as well as additional
  filtering and behaviour on the various Trait Functions on `XComGameState_Unit`
  (#85)

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

### Fixes
- Fix Chosen Assassin receiving weaknesses that are exclusive to the
  Shadowstep Strength in the narrative mission, instead Shadowstep is forced
  ahead of awarding the remaining traits, so the trait roll takes the strength
  into account (#51)
- Enable ForceCountry in CharacterPoolManager - was ignored despite being
  an argument in the CreateCharacter function (#70)
- Fixes game terminating SoundCue narrative moments after three seconds because
  it assumes they didn't play at all. (#66)
