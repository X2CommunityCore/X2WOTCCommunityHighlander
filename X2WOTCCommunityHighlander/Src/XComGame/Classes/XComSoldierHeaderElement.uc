//---------------------------------------------------------------------------------------
//  FILE:    XComSoldierHeaderElement.uc
//  AUTHOR:  Joey Martinez/jmartinez989
//  PURPOSE: An object to represent a stat that will be displayed in UISoldierHeader.
//
// This object is simply a way to store data about a soldier's particular stat that will
// be displayed in the UISoldierHeader panel in when viewing soldiers in the armory. The
// label will be the name of the state in question and the value will be how much of that
// stat the soldier has. This will also store state on whether or not to show the max
// value of the stat along with the current and also gives the option determine whether
// label and value should be shown in a colored text in the header panel. This class is
// not meant to be used alone and will be used in the class XComSoldierHeader where that
// object will have an array of XComSoldierHeaderElement objects.

class XComSoldierHeaderElement extends Object;

var bool bShouldShowMax;

var bool bShouldColorLabel;

var bool bShouldColorValue;

var string ElementLabel;

var string ElementValue;

var string ElementValueBonus;

// See class X2TacticalGameRulesetDataStructures for possible values of this enum.
var ECharStatType ElementType;

// See classes UI_Definitions and UIUtilities_Colors to see what values can be used
// for these variable types.
var eUIState ValueColor;

var eUIState LabelColor;