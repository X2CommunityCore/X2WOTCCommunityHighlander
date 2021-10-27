// INTERNAL CHL CLASS!
// Not covered by BC and should NOT be used/referenced by mods.
// First implemented for Issue #720
class CHEmitterPoolDelayedReturner extends Actor config(Dummy);

// Marked as config so that we can assign to it directly without grabbing the CDO
var private config string SingletonPath;

struct CHEPDR_Countdown
{
	var ParticleSystemComponent PSC;
	var float TimeLeft;

	var string TemplatePath;
};

var private array<CHEPDR_Countdown> CurrentPending;

`define LocalReportBadCall(msg) `RedScreen(Class.Name $ "::" $ GetFuncName() $ ":" @ `msg @ GetScriptTrace())
`define LocalReportDanger(msg) `RedScreen(Class.Name $ "::" $ GetFuncName() $ ":" @ `msg)

// Swap the defines if you want a build with more log spam
`define LocalTrace(msg)
//`define LocalTrace(msg) `log(`msg,, Class.Name)

var const string strInformCHL;

////////////////////
/// External API ///
////////////////////

static function CHEmitterPoolDelayedReturner GetSingleton ()
{
	local CHEmitterPoolDelayedReturner Instance;

	if (default.SingletonPath != "")
	{
		Instance = CHEmitterPoolDelayedReturner(FindObject(default.SingletonPath, class'CHEmitterPoolDelayedReturner'));
	}

	if (Instance == none)
	{
		// Log any instantiation, to make sure it happens once per layer(/map) load
		`log("Instantiating singleton." @ GetScriptTrace(),, default.Class.Name);

		Instance = class'WorldInfo'.static.GetWorldInfo().Spawn(class'CHEmitterPoolDelayedReturner');
		default.SingletonPath = PathName(Instance);
	}

	return Instance;
}

function AddCountdown (ParticleSystemComponent PSC, float TimeUntilReturn)
{
	local CHEPDR_Countdown Countdown;

	if (FindCountdown(PSC) != INDEX_NONE)
	{
		`LocalReportBadCall("Adding a countdown for" @ PathName(PSC.Template) @ "but there is already a countdown for this PSC. Refusing to return this PSC!");
		`RedScreen(strInformCHL);

		// This should never happen, so cancel the existing countdown as it's likely going to break something
		TryRemoveCountdown(PSC);
		return;
	}

	if (WorldInfo.MyEmitterPool.ActiveComponents.Find(PSC) == INDEX_NONE)
	{
		`LocalReportBadCall("Adding a countdown for" @ PathName(PSC.Template) @ "but it's not in MyEmitterPool.ActiveComponents. Refusing to return this PSC!");
		`RedScreen(strInformCHL);
		return;
	}

	if (PSC.OnSystemFinished != none)
	{
		`LocalReportBadCall("Adding a countdown for" @ PathName(PSC.Template) @ "but OnSystemFinished != none. Refusing to return this PSC!");
		`RedScreen(strInformCHL);
		return;
	}

	Countdown.PSC = PSC;
	Countdown.TimeLeft = TimeUntilReturn;
	Countdown.TemplatePath = PathName(PSC.Template);

	PSC.OnSystemFinished = OnParticleSystemFinished;
	CurrentPending.AddItem(Countdown);

	`LocalTrace("Added countdown" @ `showvar(TimeUntilReturn) @ `showvar(PathName(PSC.Template)),, Class.Name);
	//ScriptTrace();
}

// Remove the countdown if it exists, otherwise do nothing
function bool TryRemoveCountdown (ParticleSystemComponent PSC)
{
	local int i;

	i = FindCountdown(PSC);

	if (i != INDEX_NONE)
	{
		CurrentPending.Remove(i, 1);
		return true;
	}

	return false;
}

//////////////////////
/// Internal logic ///
//////////////////////

private function OnParticleSystemFinished (ParticleSystemComponent PSC)
{
	local int i;

	i = FindCountdown(PSC);

	if (i == INDEX_NONE) return;

	if (!VerifyReturnValid(i))
	{
		`LocalReportDanger("Failed validation!" @ strInformCHL);

		// Something went wrong - cancel the countdown for this PSC.
		// This will likely allow the pool to leak, but it's better than breaking random visuals
		CurrentPending.Remove(i, 1);

		return;
	}

	CurrentPending[i].PSC.OnSystemFinished = none;
	
	`LocalTrace("Returning to pool due to OnParticleSystemFinished" @ `showvar(PathName(CurrentPending[i].PSC.Template)));
	WorldInfo.MyEmitterPool.OnParticleSystemFinished(CurrentPending[i].PSC);

	CurrentPending.Remove(i, 1);
}

private function int FindCountdown (ParticleSystemComponent PSC)
{
	return CurrentPending.Find('PSC', PSC);
}

event Tick (float DeltaTime)
{
	local bool bInformCHL;
	local int i;

	for (i = CurrentPending.Length - 1; i >= 0; i--)
	{
		CurrentPending[i].TimeLeft -= DeltaTime;

		if (CurrentPending[i].TimeLeft < 0)
		{
			// This check should never be needed, but guard against potential crashes
			// (null pointer dereference in native code) just to be safe
			if (CurrentPending[i].PSC != none)
			{
				if (VerifyReturnValid(i))
				{
					CurrentPending[i].PSC.OnSystemFinished = none;

					`LocalTrace("Returning to pool" @ `showvar(PathName(CurrentPending[i].PSC.Template)));
					WorldInfo.MyEmitterPool.OnParticleSystemFinished(CurrentPending[i].PSC);
				}
				else
				{
					bInformCHL = true;
				}
			}
			else
			{
				`LocalReportDanger("Attempted to return a PSC but it was none (template was "@ CurrentPending[i].TemplatePath @").");
				bInformCHL = true;
			}
			
			CurrentPending.Remove(i, 1);
		}
	}

	if (bInformCHL)
	{
		`RedScreen(strInformCHL);
	}
}

private function bool VerifyReturnValid (int i)
{
	if (WorldInfo.MyEmitterPool.ActiveComponents.Find(CurrentPending[i].PSC) == INDEX_NONE)
	{
		`LocalReportDanger("Returning to pool" @ PathName(CurrentPending[i].PSC) @ "but it's not in MyEmitterPool.ActiveComponents!");
		return false;
	}

	if (PathName(CurrentPending[i].PSC.Template) != CurrentPending[i].TemplatePath)
	{
		`LocalReportDanger("Returning to pool" @ PathName(CurrentPending[i].PSC) @ "but the template does not match. Initial template:" @ CurrentPending[i].TemplatePath);
		return false;
	}

	return true;
}

defaultproperties
{
	strInformCHL = "Please inform the CHL team and provide your mod list and a description of the last couple minutes of your gameplay"
}