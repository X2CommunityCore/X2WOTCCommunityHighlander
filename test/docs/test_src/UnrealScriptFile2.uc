class UnrealScriptFile2 extends Object;

/// HL-Docs: ref:FeatureFile1
/// ... or even in another file!

/// HL-Docs: whatevenisthis:123
/// Pointless item without feature

/// HL-Docs: ref:FeatureFile1; ref:DupeFeature
/// Duplicate key

/// HL-Docs: feature:FeatWithoutRest
/// Item with feature but without rest

/// HL-Docs: ref:Bugfixes
/// Bugfix without issue

/// HL-Docs: feature:DupeFeature; issue:4; tags:
/// First def of duplicate definition

/// HL-Docs: feature:DupeFeature; issue:4; tags:
/// Second def of duplicate definition

/// HL-Docs: feature:DupeFeature; issue:4; tags:
/// Third def of duplicate definition

/// HL-Docs: feature:BadSyntaxOne; issue:5; tags:
/// What if HL-Docs appears within?
/// HL-Docs: feature:BadSyntaxToo; issue:6; tags:
/// This should be part of BadSyntaxOne, BadSyntaxToo should not exist

/// HL-Docs: feature:FeatWithBadTag; issue:7; tags:noncooltag
/// Item with bad tag

/// HL-Docs: feature:Bugfixes; issue:8; tags:
/// Try to redefine Bugfixes

/// HL-Docs: ref:DoesNotExist
/// ref for non-existing feature

function Abc()
{
	/// HL-Docs: feature:IffyInclude; issue:9; tags:
	/// Some random includes...
	/// HL-Include:
	local int CorrectlyIndented;
local string WeWantToStripTheIndentation;
	local int ButCantDoThatInTheLineAbove;
	local int AlsoAbruptlyEndFileWithoutClosing;
}