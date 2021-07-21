/// HL-Docs: feature:CHProfiler; issue:1044; tags:
/// While you can profile the game's and mods' UnrealScript code with the
/// [Gameplay Profiler](https://www.reddit.com/r/xcom2mods/wiki/index/profiling),
/// the profiles lack semantic information. The CHProfiler facilitates recording
/// and dumping **additional** performance information, usually requiring user
/// configuration to do so (console commands, config).
///
/// ## Ability Profiling
///
/// Sometimes, the gameplay profiler may yield performance issues in ability target
/// collection and condition checking. It's often hard to figure out which ability
/// in particular is at fault, since all native conditions are usually invisible
/// in the gameplay profiler and many abilities share conditions.
///
/// The ability profiler records the time it takes for an ability to collect
/// targets and check conditions. The currently used timer has a **millisecond**
/// resolution due to a missing higher-resolution timer, so it may only be
/// useful to identify egregious issues.
///
/// The console command `CHLBeginAbilityProfiling` begins event collection,
/// while `CHLEndAbilityProfiling` ends it and prints the collected data
/// to the log and console.
/// The resulting string conforms to the following grammar:
///
/// ```abnf
/// <string> ::= <part> | (<part> ";" <string>) | E
/// <part> ::= <name> ":" <numlist>
/// <numlist> ::= <number> | (<number> "," <numlist>)
/// <number> ::= [0-9]+
/// <name> ::= ([A-Z] | [a-z] | [0-9] | "_")+
/// ```
///
/// i.e. a semicolon-separated list of AbilityName, colon, comma-separated numbers sequences.
/// Every time the game calls `UpdateAbilityAvailability`, it measures the time it took the call.
/// Every number in the output corresponds to one call.
///
/// You can then analyze the results with an external tool, for example by [visualizing them
/// using matplotlib](https://gist.github.com/robojumper/1ee2de9bd38377b9c57e6ff684075780):
///
/// ![matplotlib ability profile](https://i.imgur.com/VHWJAqs.png)
///
/// **The exact output format and the clock resolution are subject to change.**
class CHProfiler extends Object;

struct AbilityProfile
{
	var name AbilityName;
	var array<int> EventsMillis;
};

var private array<AbilityProfile> Abilities;

var privatewrite bool bAbilityProfileEnabled;

private static function CHProfiler GetCDO()
{
	// This is hot code, so use an optimized function here
	return CHProfiler(FindObject("XComGame.Default__CHProfiler", class'CHProfiler'));
}

static function AddAbilityEvent(name AbilityName, int Millis)
{
	local int idx;
	local CHProfiler Prof;

	Prof = static.GetCDO();
	idx = Prof.Abilities.Find('AbilityName', AbilityName);
	if (idx == INDEX_NONE)
	{
		idx = Prof.Abilities.Length;
		Prof.Abilities.Add(1);
		Prof.Abilities[idx].AbilityName = AbilityName;
	}
	Prof.Abilities[idx].EventsMillis.AddItem(Millis);
}

static function ClearAbilityProfile()
{
	local CHProfiler Prof;
	Prof = static.GetCDO();
	Prof.Abilities.Length = 0;
}

static function SetAbilityProfiling(bool bEnabled)
{
	local CHProfiler Prof;
	Prof = static.GetCDO();
	Prof.bAbilityProfileEnabled = bEnabled;
}

static function DumpAbilityProfile()
{
	local CHProfiler Prof;
	local string DataString;
	local int idx, eidx;

	Prof = static.GetCDO();
	DataString = "";
	
	for (idx = 0; idx < Prof.Abilities.Length; idx++)
	{
		DataString $= Prof.Abilities[idx].AbilityName;
		DataString $= ":";

		for (eidx = 0; eidx < Prof.Abilities[idx].EventsMillis.Length; eidx++)
		{
			DataString $= Prof.Abilities[idx].EventsMillis[eidx];

			if (eidx != Prof.Abilities[idx].EventsMillis.Length - 1)
			{
				DataString $= ",";
			}
		}

		if (idx != Prof.Abilities.Length - 1)
		{
			DataString $= ";";
		}
	}
	class'X2TacticalGameRuleset'.static.ReleaseScriptLog(DataString);
}
