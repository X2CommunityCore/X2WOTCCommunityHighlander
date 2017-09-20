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

### Modding Exposures
- Deprivatise variables to protected in XComIdleAnimationStateMachine to allow
  for subclassing overrides (#15)

### Improvements

### Fixes
- Ensure Gremlins use the walk/run animation based on the alert status of their
  owner, rather than the standard behaviour of always deferring to walk speed
  (#33)
- Fix Reaper's Banish Ability Visualisation not properly visualising
  subsequent shots (#20)



## Miscellaneous

### Mod/DLC Hooks
- `UpdateAnimations` added to allow adding CustomAnimsets to UnitPawns (#24)
- `DLCAppendSockets` added to allow appending sockets to UnitPawns (#21)

### Event Hooks

### Modding Exposures

### Improvements
- Create a mod friendly way to manipulate loot tables (#8)
- Allow to specify EventListenerDeferral Priority for EventListeners registered
  X2EventListenerTemplates. Also allow to remove registered Listeners. (#4)

### Fixes
