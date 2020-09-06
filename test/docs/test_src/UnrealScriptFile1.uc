class UnrealScriptFile1 extends Object;

/// HL-Docs: ref:FeatureFile1
/// Also, we test if the ref can come before the feature in the same file...  
var int Abc;

/// HL-Docs: feature:FeatureFile1; issue:1; tags:strategy,cooltag
/// Feature 1 is a standard feature making use of most doc tool features.
/// Let's test including code:
/// HL-Include:
var string Def;
/// Done

/// HL-Docs: ref:FeatureFile1
/// ... or after...  
var int Ghi;

function int IPromiseThisIsARandomNumber()
{
	/// HL-Docs: feature:IncorrectIndentation; issue:2; tags:tactical
/// The indentation here is a bit wrong, but the script can recover	
		/// ... probably...  
	/// ...hopefully!
	return 4;
}

/// HL-Docs: ref:Bugfixes; issue:3
/// An ordinary bugfix. This file intentionally ends without a newline.

/// HL-Docs: feature:TestEvent; issue:10; tags:
/// ```event
/// EventID: NameOfTheEvent,
/// EventData: [in enum[EMyEnum] Enum1, inout class[class<Actor>] SomeClass, out bool bResult, inout array<string> Labels],
/// EventSource: XComHQPresentationLayer (Pres),
/// NewGameState: no
/// ```