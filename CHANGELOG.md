# Change Log
All notable changes to Vanilla 'War Of The Chosen' Behaviour will be documented in this file.



## Strategy

### Mod/DLC Hooks

### Event Hooks

### Modding Exposures

### Configuration

### Improvements

### Fixes



## Tactical

### Mod/DLC Hooks

- Trigger an event for RetainConcealmentOnActivation (#2)

### Event Hooks

- Allow to use the Reaper UI without being super concealed. New events `TacticalHUD_RealizeConcealmentStatus` and `TacticalHUD_UpdateReaperHUD` (#6)

### Configuration

### Modding Exposures
- Deprivatise variables to protected in XComIdleAnimationStateMachine to allow
  for subclassing overrides (#15)

### Improvements

### Fixes



## Miscellaneous

### Mod/DLC Hooks

### Event Hooks

### Modding Exposures

### Improvements

- Create a mod friendly way to manipulate loot tables (#8)
- Allow to specify EventListenerDeferral Priority for EventListeners registered X2EventListenerTemplates. Also allow to remove registered Listeners. (#4)

### Fixes
