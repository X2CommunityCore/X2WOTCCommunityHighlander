//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadUnitInfoItem.uc
//  AUTHOR:  Todd Smith  --  6/29/2015
//  PURPOSE: Displays minimal info about a unit of a squad. 
//           Optionally can have button added to edit the unit.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class UIMPShell_SquadUnitInfoItem extends UIPanel
	dependson(X2MPData_Native);

var localized string m_strAddUnitText;
var localized string m_strEditButtonText;
var localized string m_strDeleteButtonText;
var localized string m_strDismissButtonText;
var localized string m_strAddCustomUnitButtonText;
var localized string m_strAddPresetUnitButtonText;
var localized string m_strBlankFirstName;
var localized string m_strBlankLastName;
var localized string m_strBlankNickName;

var string m_HeadshotString;

var XComGameState m_kEditSquad;
var XComGameState_Unit m_kEditUnit;

var X2MPShellManager m_kMPShellManager;
var delegate<OnUnitDirtied> m_dOnUnitDirtied;

delegate OnUnitDirtied(XComGameState_Unit kDirtyUnit);

function InitSquadUnitInfoItem(X2MPShellManager ShellManager, XComGameState EditSquad, optional XComGameState_Unit EditUnit, optional delegate<OnUnitDirtied> dUnitDirtied, optional name InitName, optional name InitLibID)
{
	InitPanel(InitName, InitLibID);

	m_kMPShellManager = ShellManager;
	m_dOnUnitDirtied = dUnitDirtied;

	SetSquad(EditSquad);
	SetUnit(EditUnit);
}

function StateObjectReference GetUnitRef()
{
	return m_kEditUnit.GetReference();
}

function SetSquad(XComGameState kEditSquad)
{
	m_kEditSquad = kEditSquad;
}

function SetUnit(XComGameState_Unit kEditUnit)
{
	m_kEditUnit = kEditUnit;

	UpdateData();
}

simulated function OnInit()
{
	super.OnInit();

	UpdateData();
}

function OnCharacterTemplateAccept(X2MPCharacterTemplate kSelectedTemplate)
{
	`log(self $ "::" $ GetFuncName() @ "Character=" $ kSelectedTemplate.DisplayName,, 'uixcom_mp');
	`SCREENSTACK.PopFirstInstanceOfClass(class'UIMPShell_CharacterTemplateSelector');
	m_kEditUnit = m_kMPShellManager.AddNewUnitToLoadout(kSelectedTemplate, m_kEditSquad);
	if(m_dOnUnitDirtied != none)
	{
		m_dOnUnitDirtied(m_kEditUnit);
	}
//	UIMPShell_UnitEditor(`SCREENSTACK.Push(Spawn(class'UIMPShell_UnitEditor', self))).InitUnitEditorScreen(m_kEditSquad, m_kEditUnit);
}

function OnCharacterTemplateCancel()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	`SCREENSTACK.PopFirstInstanceOfClass(class'UIMPShell_CharacterTemplateSelector');
}

function OnClickedEditUnitButton(UIButton kButton)
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	// @TODO UI: callbacks for the unit editor closed so that we can know if the unit is actually dirtied.
	if(m_dOnUnitDirtied != none)
	{
		m_dOnUnitDirtied(m_kEditUnit);
	}
//	UIMPShell_UnitEditor(`SCREENSTACK.Push(Spawn(class'UIMPShell_UnitEditor', self))).InitUnitEditorScreen(m_kEditSquad, m_kEditUnit);
}

function OnClickedDeleteUnitButton(UIButton kButton)
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(m_kEditUnit != none)
	{
		m_kEditSquad.RemoveStateObject(m_kEditUnit.ObjectID);
	}
	SetUnit(none);
//	SetEditMode(eMPSSquadUnitInfoEditMode_EditNew);
	if(m_dOnUnitDirtied != none)
	{
		m_dOnUnitDirtied(none);
	}
}


simulated function UpdateData(optional int Index = -1, optional bool bDisableEditAndRemove)
{
	local string RankStr;
	local string nickname;

	if(m_kEditUnit != none)
	{
		Show();
		if(m_kEditUnit.IsSoldier())
		{
			RankStr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(m_kEditUnit.GetMPCharacterTemplate().SoldierClassTemplateName).DisplayName;

			setUnitInfo(m_kEditUnit.GetMPCharacterTemplate().SelectorImagePath,
					class'X2MPData_Shell'.default.m_strPoints, 
					string(m_kEditUnit.GetUnitPointValue()), 
					class'UIUtilities_Text'.static.GetColoredText(m_kEditUnit.GetMPName(eNameType_Full), eUIState_Normal, 18),
					class'UIUtilities_Text'.static.GetColoredText(Caps(RankStr), eUIState_Normal, 22),
					class'UIUtilities_Text'.static.GetColoredText(m_kEditUnit.IsChampionClass() ? "" : Caps(m_kEditUnit.GetMPCharacterTemplate().DisplayName), eUIState_Header, 26),
					m_kEditUnit.GetMPCharacterTemplate().IconImage, 
					m_kEditUnit.GetSoldierRank() > 0 ? class'UIUtilities_Image'.static.GetRankIcon(m_kEditUnit.GetSoldierRank(), m_kEditUnit.GetSoldierClassTemplateName()) : "", "", "");
		}
		else
		{
			RankStr = m_kEditUnit.IsAdvent() ? class'UIMPSquadSelect_ListItem'.default.m_strAdvent : class'UIMPSquadSelect_ListItem'.default.m_strAlien;
			nickname = m_kEditUnit.GetNickName(true);

			if(nickname == "")
				nickname = ""; // text does not update if it is an empty string

			setUnitInfo(m_kEditUnit.GetMPCharacterTemplate().SelectorImagePath,
					class'X2MPData_Shell'.default.m_strPoints, 
					string(m_kEditUnit.GetUnitPointValue()), 
					class'UIUtilities_Text'.static.GetColoredText(nickname, eUIState_Normal, 18), 
					class'UIUtilities_Text'.static.GetColoredText(Caps(RankStr), eUIState_Normal, 22), 
					class'UIUtilities_Text'.static.GetColoredText(Caps(m_kEditUnit.GetMPCharacterTemplate().DisplayName), eUIState_Header, 26), 
					m_kEditUnit.GetMPCharacterTemplate().IconImage, "", "", "");
		}
	}
	else
	{
		Hide();
	}
}

function SetUnitInfo(string soldierImage, string pointsLabel, string pointsValue, string firstName, string lastName, string nickName, string classIcon, string rankIcon, string loadoutLabel, string loadoutValue)
{
	Movie.ActionScriptVoid(MCPath $ ".setUnitInfo");
}


defaultproperties
{
	LibID = "MultiplayerSoldierItem";
}