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
};

var private array<CHEPDR_Countdown> CurrentPending;

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

	Countdown.PSC = PSC;
	Countdown.TimeLeft = TimeUntilReturn;

	CurrentPending.AddItem(Countdown);

	//`log("Added countdown" @ `showvar(TimeUntilReturn) @ `showvar(PathName(PSC.Template)),, Class.Name);
}

//////////////////////
/// Internal logic ///
//////////////////////

event Tick (float DeltaTime)
{
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
				//`log("Returning to pool" @ `showvar(PathName(CurrentPending[i].PSC.Template)),, Class.Name);
				WorldInfo.MyEmitterPool.OnParticleSystemFinished(CurrentPending[i].PSC);
			}
			else
			{
				`Redscreen(Class.Name @ "attempted to return a PSC but it was none. This is not dangerous but can be indicative of other problems. Please inform the CHL team and provide your mod list and a description of the last couple minutes of your gameplay");
			}
			
			CurrentPending.Remove(i, 1);
		}
	}
}
