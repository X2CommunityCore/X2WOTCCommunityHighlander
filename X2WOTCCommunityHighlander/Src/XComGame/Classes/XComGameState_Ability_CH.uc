/// HL-Docs: feature:CustomTargetStyles; issue:763; tags:tactical,compatibility
/// Target styles are responsible for the initial target selection for tactical abilities.
/// The `AbilityTargetStyle` builds an initial target list (or none, for cursor-targeted abilities).
/// The `AbilityMultiTargetStyle` adds other targets to every target built by the `AbilityTargetStyle`
/// or the cursor target.
///
/// Even though the results are cached, this code is extremely performance-critical:
/// Every time a game state is added to the History, all cached results are invalidated.
/// Whenever the AI evaluates a unit, the player selects a unit, or a reaction ability checks for
/// valid targets, this code is run for every ability on the unit!
///
/// As a result, all of this code is native: The target styles themselves are native, and their functions
/// are called by the native `GatherAbilityTargets` function. This native code simply cannot see UnrealScript
/// implementations of target styles, so custom target styles are essentially ignored.
///
/// We can override `GatherAbilityTargets` in a subclass with the slower UnrealScript implementation
/// that Firaxis helpfully provided in a comment. Doing this with all abilities would seriously
/// degrade performance, so we use [CH_ClassIsNative](../misc/ClassIsNative.md) to check if any
/// target styles are non-native, and if so use a custom `XComGameState_Ability` subclass when instanciating
/// the game state object for an ability template.
///
/// TL;DR Custom, scripted ability target/multi-target styles magically start working.
///
/// ## Compatibility
///
/// In order to selectively override the `XComGameState_Ability` class, we modify
/// `X2AbilityTemplate:CreateInstanceFromTemplate`. If your mod overrides `CreateInstanceFromTemplate` in a subclass
/// of `X2AbilityTemplate`, the Highlander will not be able to apply this enhancement to that ability. On the other
/// hand, if you override `CreateInstanceFromTemplate` precisely to instantiate your own ability state object with
/// `GatherAbilityTargets` de-nativized for a custom target style, your abilities will keep working the same way.

class XComGameState_Ability_CH extends XComGameState_Ability;

simulated function name GatherAbilityTargets(out array<AvailableTarget> Targets, optional XComGameState_Unit OverrideOwnerState)
{
	return CHGatherAbilityTargetsScript(Targets, OverrideOwnerState);
}