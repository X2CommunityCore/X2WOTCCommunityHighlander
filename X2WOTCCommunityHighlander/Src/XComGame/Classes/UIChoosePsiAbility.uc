//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChoosePsiAbility.uc
//  AUTHOR:  Joe Weinhoffer
//  PURPOSE: Screen that allows the player to select the next Psi Ability they wish to train.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIChoosePsiAbility extends UISimpleCommodityScreen;

var array<SoldierAbilityInfo> m_arrAbilities;

var int AbilitiesPerBranch;
var int MaxAbilitiesDisplayed;

var StateObjectReference m_UnitRef; // set in XComHQPresentationLayer
var StateObjectReference m_StaffSlotRef; // set in XComHQPresentationLayer

var public localized String m_strPaused;
var public localized String m_strResume;

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}

	if (CanAffordItem(iSelectedItem))
	{
		if (OnAbilitySelected(iSelectedItem))
			Movie.Stack.Pop(self);
		//UpdateData();
	}
	else
	{
		PlayNegativeSound(); // bsg-jrebar (4/20/17): New PlayNegativeSound Function in Parent Class
	}
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	ItemCard.Hide();
	Navigator.SetSelected(List);
	List.SetSelectedIndex(0);
}

simulated function PopulateData()
{
	local Commodity Template;
	local int i;

	List.ClearItems();
	List.bSelectFirstAvailable = false;

	for (i = 0; i < arrItems.Length; i++)
	{
		Template = arrItems[i];
		if (i < m_arrRefs.Length)
		{
			Spawn(class'UIInventory_ClassListItem', List.itemContainer).InitInventoryListCommodity(Template, m_arrRefs[i], GetButtonString(i), m_eStyle, , 125, true);
		}
		else
		{
			Spawn(class'UIInventory_ClassListItem', List.itemContainer).InitInventoryListCommodity(Template, , GetButtonString(i), m_eStyle, , 125, true);
		}
	}
}

simulated function PopulateResearchCard(optional Commodity ItemCommodity, optional StateObjectReference ItemRef)
{
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function GetItems()
{
	arrItems = ConvertAbilitiesToCommodities();
}

simulated function array<Commodity> ConvertAbilitiesToCommodities()
{
	local X2AbilityTemplate AbilityTemplate;
	local int iAbility;
	local array<Commodity> arrCommodoties;
	local Commodity AbilityComm;
	local bool bPausedProject;

	m_arrAbilities.Remove(0, m_arrAbilities.Length);
	m_arrAbilities = GetAbilities();
	m_arrAbilities.Sort(SortAbilitiesByRank);

	for (iAbility = 0; iAbility < m_arrAbilities.Length; iAbility++)
	{
		AbilityTemplate = m_arrAbilities[iAbility].AbilityTemplate;
		
		if (AbilityTemplate != none)
		{
			bPausedProject = XComHQ.HasPausedPsiAbilityTrainingProject(m_UnitRef, m_arrAbilities[iAbility]);
		
			AbilityComm.Title = AbilityTemplate.LocFriendlyName;
			if (bPausedProject)
			{
				AbilityComm.Title = AbilityComm.Title @ m_strPaused;
			}
			AbilityComm.Image = AbilityTemplate.IconImage;
			AbilityComm.Desc = AbilityTemplate.GetMyLongDescription(, XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_UnitRef.ObjectID)));
			AbilityComm.OrderHours = GetAbilityOrderDays(iAbility);

			arrCommodoties.AddItem(AbilityComm);
		}
	}

	return arrCommodoties;
}

simulated function int GetAbilityOrderDays(int iAbility)
{
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;
	local XComGameState_Unit Unit;
	local int RankDifference;
	local int TrainingRateModifier;

	PsiProject = XComHQ.GetPausedPsiAbilityTrainingProject(m_UnitRef, m_arrAbilities[iAbility]);

	if (PsiProject != None)
	{
		return PsiProject.GetProjectedNumHoursRemaining();
	}
	else
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_UnitRef.ObjectID));
		RankDifference = Max(m_arrAbilities[iAbility].iRank - Unit.GetRank(), 0);
		TrainingRateModifier = XComHQ.PsiTrainingRate / XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour;
		return (XComHQ.GetPsiTrainingDays() + Round(XComHQ.GetPsiTrainingScalar() * float(RankDifference))) * (24 / TrainingRateModifier);
	}
}

simulated function String GetButtonString(int ItemIndex)
{
	if (XComHQ.HasPausedPsiAbilityTrainingProject(m_UnitRef, m_arrAbilities[ItemIndex]))
	{
		return m_strResume;
	}
	else
	{
		return m_strBuy;
	}
}

//-----------------------------------------------------------------------------

//This is overwritten in the research archives. 
simulated function array<SoldierAbilityInfo> GetAbilities()
{
	local X2AbilityTemplate AbilityTemplate;	
	local SCATProgression ProgressAbility;
	local array<SoldierAbilityInfo> SoldierAbilities;
	local SoldierAbilityInfo SoldierAbility;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersProjectPsiTraining AbilityProject;
	local array<name> AddedAbilityNames;
	local name AbilityName;
	local int iName;
	local bool bAddAbility;
	local name PreReqAbilityName;  // Issue #924

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_UnitRef.ObjectID));

	// First check to see if the PsiOp has a paused ability training project
	AbilityProject = XComHQ.GetPsiTrainingProject(m_UnitRef);
	if (AbilityProject != none && AbilityProject.bForcePaused)
	{
		// Only add the paused ability to the list as a choice to resume
		AbilityName = Unit.GetAbilityName(AbilityProject.iAbilityRank, AbilityProject.iAbilityBranch);
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);

		SoldierAbility.AbilityTemplate = AbilityTemplate;
		SoldierAbility.iRank = AbilityProject.iAbilityRank;
		SoldierAbility.iBranch = AbilityProject.iAbilityBranch;

		SoldierAbilities.AddItem(SoldierAbility);
		AddedAbilityNames.AddItem(AbilityName);
	}
	else
	{
		// Otherwise generate a list of ability choices
		foreach Unit.PsiAbilities(ProgressAbility)
		{
			if (SoldierAbilities.Length >= MaxAbilitiesDisplayed)
				break;

			bAddAbility = false;
			AbilityName = Unit.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);
			if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName) && AddedAbilityNames.Find(AbilityName) == INDEX_NONE)
			{
				AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
				if (AbilityTemplate != none)
				{
					bAddAbility = true;

					// Check to make sure that soldier has any prereq abilites required, and if not then add the prereq ability instead
					if (AbilityTemplate.PrerequisiteAbilities.Length > 0)
					{
						for (iName = 0; iName < AbilityTemplate.PrerequisiteAbilities.Length; iName++)
						{
							// Start Issue #924
							/// HL-Docs: ref:Bugfixes; issue:924
							/// Prevent the psi ability training screen from showing duplicate abilities
							PreReqAbilityName = AbilityTemplate.PrerequisiteAbilities[iName];
							if (!Unit.HasSoldierAbility(PreReqAbilityName)) // if the soldier does not have the prereq ability, replace it
							{
								AbilityName = PreReqAbilityName;
								// End Issue #924
								AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
								ProgressAbility = Unit.GetSCATProgressionForAbility(AbilityName);

								if (AddedAbilityNames.Find(AbilityName) != INDEX_NONE)
								{
									// If the prereq ability was already added to the list, don't add it again
									bAddAbility = false;
								}

								break;
							}
						}
					}
				}

				if (bAddAbility)
				{
					SoldierAbility.AbilityTemplate = AbilityTemplate;
					SoldierAbility.iRank = ProgressAbility.iRank;
					SoldierAbility.iBranch = ProgressAbility.iBranch;

					SoldierAbilities.AddItem(SoldierAbility);
					AddedAbilityNames.AddItem(AbilityName);
				}
			}
		}
	}

	return SoldierAbilities;
}

function int SortAbilitiesByRank(SoldierAbilityInfo AbilityA, SoldierAbilityInfo AbilityB)
{
	if (AbilityA.iRank < AbilityB.iRank)
	{
		return 1;
	}
	else if (AbilityA.iRank > AbilityB.iBranch)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function bool OnAbilitySelected(int iOption)
{
	local XComGameState NewGameState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectPsiTraining TrainPsiOpProject;
	local StaffUnitInfo UnitInfo;
	
	StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(m_StaffSlotRef.ObjectID));

	if (StaffSlotState != none)
	{
		UnitInfo.UnitRef = m_UnitRef;
		StaffSlotState.FillSlot(UnitInfo);
						
		// If a paused project already exists for this ability, resume it
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Staffing Train Psi Operative Slot");
		TrainPsiOpProject = XComHQ.GetPausedPsiAbilityTrainingProject(m_UnitRef, m_arrAbilities[iOption]);
		if (TrainPsiOpProject != None)
		{
			TrainPsiOpProject = XComGameState_HeadquartersProjectPsiTraining(NewGameState.ModifyStateObject(TrainPsiOpProject.Class, TrainPsiOpProject.ObjectID));
			TrainPsiOpProject.bForcePaused = false;
		}
		else
		{
			// Otherwise start a new psi ability training project
			TrainPsiOpProject = XComGameState_HeadquartersProjectPsiTraining(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectPsiTraining'));
			TrainPsiOpProject.iAbilityRank = m_arrAbilities[iOption].iRank; // These need to be set first so project PointsToComplete can be calculated correctly
			TrainPsiOpProject.iAbilityBranch = m_arrAbilities[iOption].iBranch;
			TrainPsiOpProject.SetProjectFocus(UnitInfo.UnitRef, NewGameState, StaffSlotState.Facility);

			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.AddItem(TrainPsiOpProject.GetReference());
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");

		FacilityState = XComHQ.GetFacilityByName('PsiChamber');
		if (FacilityState.GetNumEmptyStaffSlots() > 0)
		{
			StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

			if ((StaffSlotState.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
				(StaffSlotState.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
			{
				`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlotState.GetMyTemplate());
			}
		}

		XComHQ.HandlePowerOrStaffingChange();

		RefreshFacility();
	}

	return true;
}

simulated function RefreshFacility()
{
	local UIScreen QueueScreen;

	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_PsiLab');
	if (QueueScreen != None)
		UIFacility_PsiLab(QueueScreen).RealizeFacility();
}

//----------------------------------------------------------------
simulated function OnCancelButton(UIButton kButton) { OnCancel(); }
simulated function OnCancel()
{
	CloseScreen();
}

//==============================================================================

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

defaultproperties
{
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;
	bSelectFirstAvailable = false;
	//bConsumeMouseEvents = true;

	DisplayTag = "UIDisplay_Academy"
	CameraTag = "UIDisplay_Academy"

	AbilitiesPerBranch=2
	MaxAbilitiesDisplayed=3
}
