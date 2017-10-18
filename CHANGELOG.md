# Change Log
All notable changes to Vanilla 'War Of The Chosen' Behaviour will be documented in this file.



## Strategy

### Mod/DLC Hooks

### Event Hooks

### Modding Exposures

### Configuration

### Improvements

### Fixes
- Fix an issue in base game where strategy X2EventListenerTemplates only
  register on tactical->strategy transfer, not when loading directly into
  strategy (#3)
- Fix GetCrossClassAbilities collecting abilities that are already in that
  particular Unit Class's skill tree (#30)


## Tactical

### Mod/DLC Hooks
- Allow Mods/DLC to modify spawn locations for player units (#18)
- Trigger an event for RetainConcealmentOnActivation (#2)

### Event Hooks

- `OnProjectileFireSound` and `OnProjectileDeathSound` in X2UnifiedProjectile that allow to override the default projectile sounds. (#10)
- Add `WillRollContext` for modifying Will Rolls in
  XComGameStateContext_WillRoll (#13)
- Allow to use the Reaper UI without being super concealed. New events
  `TacticalHUD_RealizeConcealmentStatus` and `TacticalHUD_UpdateReaperHUD` (#6)

### Configuration
- Added ability to modify default spawn size (#18)
- Added ability to modify number of tactical auto-saves kept (#53)
- Added ability to prevent ragdolls from ever turning off their physics, plus
  enable Chosen ragdolling (#41)

### Modding Exposures
- Deprivatise variables to protected in XComIdleAnimationStateMachine to allow
  for subclassing overrides (#15)
- Remove protectedwrite on X2AbilityTemplate effects arrays: AbilityTarget,
  AbilityMultiTarget, and AbilityShooter Effects (#68)

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

### Modding Exposures

### Improvements
- Create a mod friendly way to manipulate loot tables (#8)
- Allow to specify EventListenerDeferral Priority for EventListeners registered
  X2EventListenerTemplates. Also allow to remove registered Listeners. (#4)
- Allow enemies with assigned names to have them appear as their name, rather
  than a generic label. (#52)
- Check a soldiers 'NeedsSecondaryWeapon' in UIArmory_Loadout, rather than
  hardcoding based on Rookie Rank (#55)

### Fixes
- Fix Chosen Assassin receiving weaknesses that are exclusive to the
  Shadowstep Strength in the narrative mission, instead Shadowstep is forced
  ahead of awarding the remaining traits, so the trait roll takes the strength
  into account (#51)
- Enable ForceCountry in CharacterPoolManager - was ignored despite being
  an argument in the CreateCharacter function (#70)
