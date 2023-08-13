//---------------------------------------------------------------------------------------
//  FILE:    UICovertActionStaffSlot.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICovertActionStaffSlot extends UICovertActionSlot
	dependson(UIPersonnel, XComGameState_CovertAction);

var StateObjectReference StaffSlotRef;
var StateObjectReference RewardRef;
var bool bOptional; // Is this slot optional?
var bool bFame; // Does this slot require a famous soldier?
var int StaffIndex;
var Texture2D StaffPicture;
var DynamicPropertySet DisplayPropertySet;
var StateObjectReference UnitRef;

var StaffUnitInfo m_PendingStaff; // used when reassigning staff

var localized string m_strRequiredSlot;
var localized string m_strOptionalSlot;
var localized string m_strFamous;
var localized string m_strSoldierReward;
var localized string m_strClearSoldier; 
var localized string m_strAddSoldier;
var localized string m_strAddEngineer;
var localized string m_strAddScientist;
var localized string m_strNoUnitAvailable;
var localized string m_strEditLoadout;
var localized string m_strGainedXP;
var localized string m_strGainedCohesion;
var localized string m_strSoldierKilled;

//-----------------------------------------------------------------------------
function UICovertActionSlot InitStaffSlot(UICovertActionSlotContainer OwningContainer, StateObjectReference Action, int _MCIndex, int _SlotIndex, delegate<OnSlotUpdated> onSlotUpdatedDel)
{
	local XComGameState_CovertAction ActionState;
	local CovertActionStaffSlot StaffSlot;

	ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(Action.ObjectID));
	StaffSlot = ActionState.StaffSlots[_SlotIndex];

	StaffSlotRef = StaffSlot.StaffSlotRef;
	RewardRef = StaffSlot.RewardRef;
	bOptional = StaffSlot.bOptional;
	bFame = StaffSlot.bFame;
	StaffIndex = _SlotIndex;

	super.InitStaffSlot(OwningContainer, Action, _MCIndex, _SlotIndex, onSlotUpdatedDel);
	
	return self;
}

function UpdateData()
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_Reward RewardState;
	local Texture2D SoldierPicture;
	local string Label, Value, Button, SlotImage, RankImage, ClassImage, ButtonLabel2, CohesionUnitNames;
	local XComGameState_Unit Unit;
	local XComGameState_CampaignSettings SettingsState;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
		StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffSlotRef.ObjectID));
	RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
	ActionState = GetAction();
	
	eState = eUIState_Normal;

	if( RewardState != None && !ActionState.bCompleted)
	{
		Value = RewardState.GetRewardPreviewString();
		if( Value != "" && RewardState.GetMyTemplateName() != 'Reward_DecreaseRisk')
		{
			Value = class'UIUtilities_Text'.static.GetColoredText(m_strSoldierReward @ Value, eUIState_Good);
		}
	}

	Label = StaffSlotState.GetNameDisplayString();
	ButtonLabel2 = "";

	if (!StaffSlotState.IsSlotFilled())
	{
		if (bFame)
		{
			Label = m_strFamous @ Label;
		}

		if (bOptional)
		{
			Label = m_strOptionalSlot @ Label;
		}
		else
		{
			Label = m_strRequiredSlot @ Label;
		}

		if( StaffSlotState.IsEngineerSlot() )
		{
			Button = m_strAddEngineer;
		}
		else if( StaffSlotState.IsScientistSlot() )
		{
			Button = m_strAddScientist;
		}
		else
		{
			Button = m_strAddSoldier;
		}

		SlotImage = "";
		eState = eUIState_Normal;

		if( !StaffSlotState.IsUnitAvailableForThisSlot() )
		{
			Value @= "\n" $ class'UIUtilities_Text'.static.GetColoredText(m_strNoUnitAvailable, eUIState_Disabled);
			eState = eUIState_Disabled;
		}
	}
	else
	{
		eState = eUIState_Good;
		if (!ActionState.bCompleted && !ActionState.bStarted)
		{
			Button = m_strClearSoldier;
		}

		//TODO: @kderda This check should be removed once the UpdateSoldierPortraitImage callback no longer comes back through here
		UnitRef = StaffSlotState.GetAssignedStaffRef();
		SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, UnitRef.ObjectID, 128, 128);

		if( SoldierPicture == none )
		{
			//Take a picture if one isn't available - this could happen in the initial mission prior to any soldier getting their picture taken
			`HQPRES.GetPhotoboothAutoGen().AddHeadShotRequest(UnitRef, 128, 128, UpdateSoldierPortraitImage, , , true);
			`HQPRES.GetPhotoboothAutoGen().RequestPhotos();

			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(UnitRef, , true);
		}
		else
		{
			SlotImage = class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture));
		}

		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		RankImage = Unit.IsSoldier() ? Unit.GetSoldierRankIcon() : ""; // Issue #408
		// Start Issue #106
		ClassImage = Unit.IsSoldier() ? Unit.GetSoldierClassIcon() : Unit.GetMPCharacterTemplate().IconImage;
		// End Issue #106

		if( Unit.IsSoldier() && ActionState.HasAmbushRisk() && !ActionState.bStarted)
		{
			ButtonLabel2 = m_strEditLoadout;
		}

		if (ActionState.bCompleted && Unit.IsSoldier())
		{
			if (Unit.IsDead())
			{
				Value4 = Caps(m_strSoldierKilled);
			}
			else
			{
				PromoteLabel = (Unit.ShowPromoteIcon()) ? class'UISquadSelect_ListItem'.default.m_strPromote : "";
				Value4 = Caps(ActionState.GetStaffRisksAppliedString(StaffIndex)); // Value 4 is automatically red / negative!

				// Issue #810: Don't display XP and cohesion gain if rewards weren't
				// given on completion of the covert action (since XP and cohesion are
				// not granted in that case).
				/// HL-Docs: ref:CovertAction_PreventGiveRewards
				if (!Unit.bCaptured && !ActionState.RewardsNotGivenOnCompletion)
				{
					Value1 = m_strGainedXP; // Gained Experience
					CohesionUnitNames = GetCohesionRewardUnits();
					if (CohesionUnitNames != "")
					{
						ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
						ParamTag.StrValue0 = CohesionUnitNames;
						Value2 = `XEXPAND.ExpandString(m_strGainedCohesion); // Cohesion increased
						Value3 = (RewardState != none) ? RewardState.GetRewardString() : "";
					}
					else
					{
						// If there are no other soldiers on the CA for cohesion, bump the reward info to the second line
						Value2 = (RewardState != none) ? RewardState.GetRewardString() : "";
					}
				}
			}
		}
	}
	
	Update(Label, Value, Button, SlotImage, RankImage, ClassImage, ButtonLabel2);
}

function string GetCohesionRewardUnits()
{
	local XComGameState_CovertAction ActionState;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit UnitState;
	local string CohesionUnitStr;
	local int idx;

	ActionState = GetAction();
	for (idx = 0; idx < ActionState.StaffSlots.Length; idx++)
	{
		if (idx != StaffIndex)
		{
			SlotState = ActionState.GetStaffSlot(idx);
			if (SlotState.IsSlotFilled())
			{
				UnitState = SlotState.GetAssignedStaff();
				if (UnitState.IsSoldier() && UnitState.IsAlive() && !UnitState.bCaptured)
				{
					if (CohesionUnitStr != "")
					{
						CohesionUnitStr $= ", ";
					}

					CohesionUnitStr $= UnitState.GetName(eNameType_RankLast);
				}
			}
		}
	}

	return CohesionUnitStr;
}

//bsg-jneal (3.10.17): adding controller navigation support for staff slots
function bool CanEditLoadout()
{
	local XComGameState_Unit Unit;

	//only allow edit loadout when the slot allows it
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	if( Unit.IsSoldier() && GetAction().HasAmbushRisk() )
	{
		return true;
	}

	return false;
}
//bsg-jneal (3.10.17): end

simulated function UpdateSoldierPortraitImage(StateObjectReference InUnitRef)
{
	//TODO: @bsteiner make image access function 
	//TODO: @kderda Also change the UpdateData function to no longer check for the existence of the photo first when image access function is implemented.
	UpdateData();
}

function HandleClick(string ButtonName)
{
	local XComGameState_StaffSlot StaffSlotState;

	if( ButtonName == "theButton" ) //default clear / add button 
	{
		if( !GetAction().bStarted )
		{
			StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
			if( !StaffSlotState.IsSlotEmpty() )
			{
				ClearSlot();
			}
			else if( StaffSlotState.IsUnitAvailableForThisSlot() )
			{
				`SOUNDMGR.PlaySoundEvent("Play_MenuOpenSmall");
				`HQPRES.UIPersonnel_CovertAction(OnPersonnelRefSelected, StaffSlotRef);
			}
		}
	}
	else if( ButtonName == "theButton2" ) //edit loadout 
	{
		if( !GetAction().bStarted )
		{
			StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
			if( !StaffSlotState.IsSlotEmpty() )
			{
				`HQPRES.UIArmory_Loadout(StaffSlotState.GetAssignedStaffRef());
			}
		}
	}
}

function ClearSlot()
{
	local XComGameState_StaffSlot StaffSlotState;

	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
	StaffSlotState.EmptySlot();
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Remove");
	super.ClearSlot();
	
	UpdateDisplay();
}

function OnPersonnelRefSelected(StateObjectReference _UnitRef)
{
	local XComGameState_StaffSlot StaffSlotState;
	local StaffUnitInfo UnitInfo;

	UnitInfo.UnitRef = _UnitRef;
	m_PendingStaff = UnitInfo;
	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if (StaffSlotState.GetAssignedStaffRef() != UnitInfo.UnitRef) // do nothing if attempting to assign the same staffer again
	{
		if (class'UIUtilities_Strategy'.static.CanReassignStaff(UnitInfo, GetNewLocationString(StaffSlotState), ReassignStaffCallback))
			ReassignStaffCallback('eUIAction_Accept');
	}
}

function string GetNewLocationString(XComGameState_StaffSlot StaffSlotState)
{
	return GetAction().GetDisplayName();
}

function ReassignStaffCallback(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		ReassignStaff(m_PendingStaff);
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("UI_CovertOps_AddSoldier");
	}
	else
		SlotContainer.Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

function ReassignStaff(StaffUnitInfo UnitInfo)
{
	local XComGameState_StaffSlot StaffSlotState;

	StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID)); // the staff slot being filled

	if (!StaffSlotState.AssignStaffToSlot(UnitInfo))
	{
		return;
	}

	UpdateDisplay();
}

//==============================================================================
