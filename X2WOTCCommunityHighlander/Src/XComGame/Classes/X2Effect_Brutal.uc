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
		CurrentWill = TargetUnit.GetBaseStat(eStat_Will);
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
		WillChange = NewUnit.GetBaseStat(eStat_Will) - OldUnit.GetBaseStat(eStat_Will);
		if (WillChange != 0)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			Msg = Repl(default.WillChangeMessage, "<WillChange/>", WillChange);
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Msg, '', eColor_Bad);
		}
	}
}