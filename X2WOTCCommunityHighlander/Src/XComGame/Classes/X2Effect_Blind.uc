//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_Blind extends X2Effect_PersistentStatChange config(GameCore);

var localized string BlindName, BlindDesc, BlindAddedFlyover, BlindAddedString, BlindRemovedFlyover, BlindRemovedString;
var config string BlindStatusIcon;

static function X2Effect_Blind CreateBlindEffect(int NumTurnsBlinded, float SightRadiusPostMultMod)
{
	local X2Effect_Blind Effect;

	Effect = new class'X2Effect_Blind';
	Effect.BuildPersistentEffect(NumTurnsBlinded, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Penalty, default.BlindName, default.BlindDesc, default.BlindStatusIcon);
	Effect.AddPersistentStatChange(eStat_SightRadius, SightRadiusPostMultMod, MODOP_PostMultiplication);
	Effect.EffectName = class'X2AbilityTemplateManager'.default.BlindedName;

	if (class'X2StatusEffects'.default.BlindedParticle_Name != "")
	{
		Effect.VFXTemplateName = class'X2StatusEffects'.default.BlindedParticle_Name;
		Effect.VFXSocket = class'X2StatusEffects'.default.BlindedSocket_Name;
		Effect.VFXSocketsArrayName = class'X2StatusEffects'.default.BlindedSocketsArray_Name;
	}

	return Effect;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_UpdateFOW FOWUpdate;

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);

	if( (EffectApplyResult == 'AA_Success') &&
		(XComGameState_Unit(ActionMetadata.StateObject_NewState) != none) )
	{
		class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.BlindAddedFlyover, '', eColor_Bad, default.StatusIcon);
		class'X2StatusEffects'.static.AddEffectMessageToTrack(ActionMetadata,
															  default.BlindAddedString,
															  VisualizeGameState.GetContext(),
															  class'UIEventNoticesTactical'.default.BlindedTitle,
															  default.StatusIcon,
															  eUIState_Bad);
		class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());

		FOWUpdate = X2Action_UpdateFOW( class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext() , false, ActionMetadata.LastActionAdded) );
		FOWUpdate.ForceUpdate = true;
	}
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_UpdateFOW FOWUpdate;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);

	if( (EffectApplyResult == 'AA_Success') &&
		(XComGameState_Unit(ActionMetadata.StateObject_NewState) != none) )
	{
		class'X2StatusEffects'.static.AddEffectSoundAndFlyOverToTrack(ActionMetadata, VisualizeGameState.GetContext(), default.BlindRemovedFlyover, '', eColor_Good, default.StatusIcon);
		class'X2StatusEffects'.static.AddEffectMessageToTrack(ActionMetadata,
															  default.BlindRemovedString,
															  VisualizeGameState.GetContext(),
															  class'UIEventNoticesTactical'.default.BlindedTitle,
															  default.StatusIcon,
															  eUIState_Good);
		class'X2StatusEffects'.static.UpdateUnitFlag(ActionMetadata, VisualizeGameState.GetContext());

		FOWUpdate = X2Action_UpdateFOW( class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext() , false, ActionMetadata.LastActionAdded) );
		FOWUpdate.ForceUpdate = true;
	}
}

DefaultProperties
{
	bIsImpairing=true
	DuplicateResponse=eDupe_Refresh
}