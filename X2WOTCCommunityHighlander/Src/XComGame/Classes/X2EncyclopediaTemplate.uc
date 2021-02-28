//---------------------------------------------------------------------------------------
//  FILE:    X2EncyclopediaTemplate.uc
//  AUTHOR:  Dan Kaplan - 10/1/2015
//  PURPOSE: Template defining an Encyclopedia entry in X-Com 2.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2EncyclopediaTemplate extends X2DataTemplate
	native(Core)
	config(Encyclopedia);

var config Name					ListCategory;		// Internal name of the category to which this header/entry belong to
var private localized string	ListTitle;			// Player facing name of this entry/header.
var config string				ListImagePath;		// The URL to the image that should be displayed as part of the list entry if this is a header.

var private localized string    DescriptionTitle;   // Player facing description title that appears when selected.
var private localized string    DescriptionEntry;   // Player facing description body that appears when selected.
var config string				DescriptionImagePath;		// The URL to the image that should be displayed as part of the list entry if this is a header.

var config bool					bCategoryHeader;	// If true, this entry functions as a category header; if false, this entry functions as a regular entry.
var config int					SortingPriority;	// The priority of this entry relative to others in the same category (lower priority sorts higher in the list).
var config StrategyRequirement  Requirements;		// Requirements to show up in the archive



function string GetListTitle()
{
	return ListTitle;
}

function string GetDescriptionTitle()
{
	return DescriptionTitle;
}

function string GetDescriptionEntry()
{
	return `XEXPAND.ExpandString(DescriptionEntry);
}

defaultproperties
{
}