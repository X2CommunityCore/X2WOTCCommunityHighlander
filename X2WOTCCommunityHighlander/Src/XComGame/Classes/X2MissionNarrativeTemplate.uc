//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MissionNarrativeTemplate.uc
//  AUTHOR:  David Burchanowski  --  1/29/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MissionNarrativeTemplate extends X2DataTemplate
	native(Core)
	dependson(XComKeybindingData);

var string MissionType; // Type of mission this narrative should be used for
var name QuestItemTemplateName; // Allows you to make item specific narrative variations. If blank, will be used as the default narrative.
var privatewrite localized array<string> ObjectiveTextPools; // List of text lines to display in the objectives hud for this template.
var array<string> NarrativeMoments; // List of narrative moments for this template.

var privatewrite localized array<string> ConsoleObjectiveTextPools; // Console override text lines.
var private localized string CouldNotFindTextMessage;
var private localized string NoItemMessage;

struct native KeyBindingMap
{
	var string markUp;
	var TacticalBindableCommands command;
};

var private array<KeyBindingMap> KeyBindingMarkups;

function string GetObjectiveText(int TextLine)
{
	local XComTacticalMissionManager MissionManager;
	local X2QuestItemTemplate QuestItemTemplate;
	local name ActiveQuestItem;
	local string QuestItemText;
	local string ObjText;
	local KeyBindingMap BindingMap;
	local byte KeyNotFound;
	local PlayerInput PlayerIn;
	local XComKeybindingData KeyBindData;

	if(TextLine < 0 || TextLine >= ObjectiveTextPools.Length)
	{
		return "Error: Invalid text line requested.";
	}

	MissionManager = `TACTICALMISSIONMGR;

	// attempt to find the descriptive label for the current mission "quest" item
	ActiveQuestItem = MissionManager.GetQuestItemTemplateForMissionType(MissionType);
	QuestItemTemplate = X2QuestItemTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ActiveQuestItem));

	if (ConsoleObjectiveTextPools[TextLine] == "" || 
		`XPROFILESETTINGS == none ? true : !`ISCONTROLLERACTIVE)
	{
		ObjText = ObjectiveTextPools[TextLine];
	}
	else
	{
		ObjText = ConsoleObjectiveTextPools[TextLine];
	}	
	while( InStr(ObjText, "%QUESTITEM%") != INDEX_NONE )
	{
		if (QuestItemTemplate == none)
		{
			if(ActiveQuestItem != '')
			{
				`Redscreen("Could not find template for ActiveQuestItem '" $ string(ActiveQuestItem) $ "' in mission " $ MissionManager.ActiveMission.sType);
				QuestItemText = NoItemMessage $ ": " $ string(ActiveQuestItem);
			}
			else
			{
				`Redscreen("No ActiveQuestItem defined in mission type" $ MissionManager.ActiveMission.sType);
				QuestItemText = NoItemMessage;
			}
		}
		else
		{
			QuestItemText = QuestItemTemplate.GetItemFriendlyName();
		}
		ObjText = Repl(ObjectiveTextPools[TextLine], "%QUESTITEM%", QuestItemText, false);
		ObjText = Repl(ObjText, "%QUESTITEM%", QuestItemText, false);
	}

	if(InStr(ObjText, "%KEY:") != INDEX_NONE)
	{
		PlayerIn = XComPlayerController(`PRES.Owner).PlayerInput;
		KeyBindData = `PRES.m_kKeybindingData;
		KeyNotFound = 0;

		foreach KeyBindingMarkups(BindingMap)
		{			
			ObjText = class'UIUtilities_Input'.static.FindAbilityKey(ObjText, BindingMap.markUp, BindingMap.command, KeyNotFound, KeyBindData, PlayerIn);
		}

		if (KeyNotFound > 0)
		{
			`Redscreen("Failed to find key binding localized for mission narrative text:\n"$ObjectiveTextPools[TextLine]);
		}
	}
	ObjText = class'UIUtilities_Input'.static.InsertGamepadIcons(ObjText);
			
	return ObjText;
}

DefaultProperties
{
	KeyBindingMarkups[0] = ( markUp = "%KEY:RMB%", command = eTBC_Path )
	KeyBindingMarkups[1] = ( markUp = "%KEY:ENTER%", command = eTBC_EnterShotHUD_Confirm )
	KeyBindingMarkups[2] = ( markUp = "%KEY:TAB%", command = eTBC_NextUnit )
	KeyBindingMarkups[3] = ( markUp = "%KEY:Q%", command = eTBC_CamRotateLeft )
	KeyBindingMarkups[4] = ( markUp = "%KEY:E%", command = eTBC_CamRotateRight )
	KeyBindingMarkups[5] = ( markUp = "%KEY:P%", command = eTBC_CommandAbility1 )
}