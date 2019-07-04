//---------------------------------------------------------------------------------------
//  FILE:    XComSoldierHeader.uc
//  AUTHOR:  Joey Martinez/jmartinez989
//  PURPOSE: An object to use to display a set of soldier stats on UISoldierHeader
//
// This object's only purpose is to store a set of XComSoldierHeaderElement objects so that
// the set can be displayed on the UISoldierHeader. This object will be passed off to an event
// listener so that the stats can be ordered and modified in the desired way. It will also have
// a referrence to the unit in question so the desired stats to be displayed can be pulled.

class XComSoldierHeader extends Object;

var XComGameState_Unit Unit;

// The items below are needed for calculating stat bonuses. The event that uses this
// object will likely be doing calculations similar to the one done in UISoldierHeader
// and will need these.
var StateObjectReference NewItem;
var StateObjectReference ReplacedItem;
var XComGameState NewCheckGameState;

// Used in calculating bonus stats.
var array<Name> EquipmentExcludedFromStatBoosts;

var array<XComSoldierHeaderElement> Elements;