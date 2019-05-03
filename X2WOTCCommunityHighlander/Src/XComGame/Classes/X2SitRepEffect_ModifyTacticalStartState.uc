//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_ModifyTacticalStartState
//  AUTHOR:  statusNone
//           
//  Class created to give SITREPs access to the Tactical XCGS StartState
//
//---------------------------------------------------------------------------------------
// File added to the CHL (this is a non-base game class). Issue #450
//---------------------------------------------------------------------------------------

class X2SitRepEffect_ModifyTacticalStartState extends X2SitRepEffectTemplate;

var Delegate<ModifyTacticalStartStateDelegate> ModifyTacticalStartStateFn;

delegate ModifyTacticalStartStateDelegate(XComGameState StartState);

function bool ValidateTemplate(out string strError)
{
	if (ModifyTacticalStartStateFn == none)
	{
		strError = "ModifyTacticalStartStateFn not set";
		return false;
	}

	return true;
}
