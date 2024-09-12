class X2Effect_Brutal extends X2Effect;

var localized string WillChangeMessage;
var int WillMod;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local int CurrentWill;

	TargetUnit = XComGameState_Unit(kNewTargetState);
	if (TargetUnit != none)
	{
		/// HL-Docs: ref:Bugfixes; issue:1389
		/// Make `X2Effect_Brutal` use unit's current Will instead of base Will so it can properly reduce and display it.
		// Single line for Issue #1389 - use GetCurrentStat() instead of GetBaseStat() to reduce will.
		CurrentWill = TargetUnit.GetCurrentStat(eStat_Will);
		if (CurrentWill + WillMod <= 0)
			TargetUnit.SetCurrentStat(eStat_Will, 1);
		else
			TargetUnit.SetCurrentStat(eStat_Will, CurrentWill + WillMod);
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local XComGameState_Unit OldUnit, NewUnit;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int WillChange;
	local string Msg;

	OldUnit = XComGameState_Unit(ActionMetadata.StateObject_OldState);
	NewUnit = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if (OldUnit != none && NewUnit != None)
	{
		// Single line for Issue #1389 - use GetCurrentStat() instead of GetBaseStat() to display will loss.
		WillChange = NewUnit.GetCurrentStat(eStat_Will) - OldUnit.GetCurrentStat(eStat_Will);
		if (WillChange != 0)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			Msg = Repl(default.WillChangeMessage, "<WillChange/>", WillChange);
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Msg, '', eColor_Bad);
		}
	}
}