//---------------------------------------------------------------------------------------
//  FILE:	CHXComGameVersionTemplate.uc
//  AUTHOR:  X2CommunityCore
//  PURPOSE: Version information for the Community Highlander XComGame replacement. 
//
//  Issue #1
// 
//  This is implemented as a template for legacy reasons. The new approach does not rely on templates at all.
//
//  Supports major, minor, and build versions, but build is currently unimplemented.
//---------------------------------------------------------------------------------------
/// HL-Docs: feature:ComponentVersions; issue:765; tags:
/// Both the Highlander and mods using it may be interested in whether replacements for
/// base game packages ("components") are installed, and if, which version.
/// This can be used to
///
/// * Behave differently depending on whether a HL feature is available
/// * Provide more targeted error messages when a certain HL version is required
///
/// For example, if you are interested in whether version 1.19.0 of the Highlander is
/// correctly enabled, you can use the following:
///
/// ```unrealscript
/// if (class'CHXComGameVersionTemplate' != none
/// 	&& (class'CHXComGameVersionTemplate'.default.MajorVersion > 1
/// 		|| (class'CHXComGameVersionTemplate'.default.MajorVersion == 1
/// 			&& class'CHXComGameVersionTemplate'.default.MinorVersion >= 19)
/// 		)
/// 	)
/// {
/// 	// Installed, do thing A	
/// }
/// else
/// {
///     // Not installed or wrong version, do thing B   
/// }
/// ```
///
/// For other classes, see *Source code references* below.
///
/// Note that you can employ feature-based detection if the feature
/// can be distinguished by the presence of a certain function or property.
/// For example, [`OverrideUnitFocusUI`](../tactical/OverrideUnitFocusUI.md) can be detected with
/// the following trick:
///
/// ```unrealscript
/// if (Function'XComGame.CHHelpers.GetFocusTuple' != none)
/// {
/// 	// Feature present
/// }
/// else
/// {
/// 	// Feature absent
/// }
/// ```
class CHXComGameVersionTemplate extends X2StrategyElementTemplate;

var int MajorVersion;
var int MinorVersion;
var int PatchVersion;

var string Commit;

// The following functions are deprecated

// "Short" version number (minus the patch)
function String GetShortVersionString()
{
	return default.MajorVersion $ "." $ default.MinorVersion;
}

// Version number in string format.
function String GetVersionString()
{
	return default.MajorVersion $ "." $ default.MinorVersion $ "." $ default.PatchVersion;
}

// Version number in comparable numeric format. Number in decimal is MMmmmmPPPP where:O
// "M" is major version
// "m" is minor version
// "P" is patch number
//
// Allows for approx. 2 digits of major, 4 digits of minor versions and 9,999 patches before overflowing.
//
// Optional params take individual components of the version
function int GetVersionNumber()
{
	return (MajorVersion * 100000000) + (MinorVersion * 10000) + (PatchVersion);
}

// AUTO-CODEGEN: Version-Info
defaultproperties
{
	MajorVersion = 1;
	MinorVersion = 22;
	PatchVersion = 3;
	Commit = "";
}

