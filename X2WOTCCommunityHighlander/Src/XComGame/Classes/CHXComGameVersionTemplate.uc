//---------------------------------------------------------------------------------------
//  FILE:    CHXComGameVersionTemplate.uc
//  AUTHOR:  X2CommunityCore
//  PURPOSE: Version information for the Community Highlander XComGame replacement. 
//
//  Issue #1
// 
//  This is implemented as a template to allow mods to detect whether the Community Highlander 
//  is installed. It's a template to avoid needing to compile against any
//  new sources to get mods to build (which would then crash the game if it tried
//  to access a function //  or variable that wasn't installed anyway). Can be queried by:
//
//  1) Query the StrategyElementTemplateManager for a template named 'CHXComGameVersion'. If you get back
//     a non-none result the XcomGame replacement is installed (or someone is lying and added the template without
//     the actual XComGame replacement...)
//  2) If you need more fine-grained info, such as the particular version, then once you get back a non-none
//     result you can cast it to class 'CHXComGameVersionTemplate' to get the version number through the API below.
//
//  Don't directly look up the template and cast it without checking if you got a non-none result or the game will
//  probably crash when the replacement XComGame isn't present.
//
//  Supports major, minor, and build versions, but build is currently unimplemented.
//---------------------------------------------------------------------------------------
class CHXComGameVersionTemplate extends X2StrategyElementTemplate;

var int MajorVersion;
var int MinorVersion;
var int PatchVersion;

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
// Allows for approx. 2 digits of major, 4 digits of minor versions and 9,999 builds before overflowing.
//
// Optional params take individual components of the version
//
// Note: build number currently disabled and is always 0.
function int GetVersionNumber()
{
    return (default.MajorVersion * 100000000) + (default.MinorVersion * 10000) + (default.PatchVersion);
}

defaultproperties
{
    MajorVersion = 1;
    MinorVersion = 11;
    PatchVersion = 1;
}

