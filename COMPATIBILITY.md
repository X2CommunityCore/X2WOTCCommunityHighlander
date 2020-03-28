# Community Highlander Compatibility Policy

## Behavioral changes

All Highlander changes can potentially cause a change in observable Highlander behavior.
Ideally, these changes are opt-in, either through config flags or events/hooks that
retain default behavior if not implemented by mods. However, bugfixes are exempt from
this policy, which can cause incompatibility:

* The most prominent example being the [`ArmorEquipRollDLCPartChance`](https://x2communitycore.github.io/X2WOTCCommunityHighlander/misc/ArmorEquipRollDLCPartChance/) change,
which can cause soldiers without torsos. We "fixed" it by offering an opt-out.
* The [`ScreenStackSubClasses`](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/pull/796/commits/61477511aad97b9da8aa989b4be8fddb85b50d22) change,
which can cause a change in behavior of the UI system. It was deemed worth it because it fixes a far greater amount of bugs.

Such changes must explicitly be documented with the `compatibility` tag.

## Naming conflicts

Event or function names can potentially conflict with names chosen by mods. It is recommended that HL events or names
use a prefix if a conflict is likely (CH_) and otherwise restrict name choice to variations of existing names (for example a function
`DoXWhenY` that gets an event trigger may trigger the event `OverrideDoXWhenY`).

## Compile-time-only changes

Sometimes we change functions or properties to remove the `private` or `protected` visibility modifier.
This isn't strictly necessary to do in the Highlander, as this can simply be done with local `Src(Orig)` sources,
and the UnrealScript runtime seemingly doesn't enforce visibility modifiers at all.

(Note: `private`/`final` functions cause static dispatch to be inserted by the compiler and cannot be overridden,
while-non-private/final functions can be overridden and their calls use virtual dispatch. This means that changing
a function to `public` in local sources and compiling against that causes newly compiled scripts to use virtual dispatch
and call the overridden function, but existing call sites (the original `XComGame` class) use static dispatch.)

## Runtime-observable changes

### Type changes

Changing the type signature of a function or a property (including removal) is a breaking change and causes a crash.
One exception is the addition of optional arguments; existing function calls (though not overrides in subclasses) are unaffected.

**Unresolved Question:** Does this extend to private functions or properties? Does it matter whether they are base-game provided or CHL-added?

For example, for [#434](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/pull/436/files#diff-3fd330f5f74f0a5f020891eb078df6b7R895),
an **existing** private function signature was changed to accomodate the event trigger added to the function:

```diff
-private function int CalculateRiskChanceToOccurModifiers(int ChanceToOccur, bool bChosenIncreaseRisks, bool bDarkEventRisk)
+private function int CalculateRiskChanceToOccurModifiers(CovertActionRisk ActionRisk, bool bChosenIncreaseRisks, bool bDarkEventRisk)
```

For [#825](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/pull/826#discussion_r399667325), it is debated whether
the helper function **added by the same PR** should be `private` or not:

```diff
-simulated function bool TriggerOnOverrideHitEffects(
+simulated private function bool TriggerOnOverrideHitEffects(
```

There are two competing arguments:

1) People can *always* deprivatize functions locally and call them, and that's the suggested and preferred approach to many visibility
issues. Having any visibility modifiers gives us a false impression of the changes we can safely make.
2) We have in the past [explicitly deprivatized](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues?q=is%3Aissue+label%3Ade-private%2Fconst) items in the HL. A very specific and not well-known hack in the Unreal Virtual machine is not covered by our backwards compatibility guarantee and only
precludes changes with evidence to break things.
